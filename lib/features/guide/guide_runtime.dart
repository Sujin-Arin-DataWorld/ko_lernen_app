import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chaekgado_shelf.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/guide_contract.dart';
import '../../models/learner_level.dart';
import '../../models/onboarding_contract_validation.dart';
import '../../motion/transitions.dart';
import '../onboarding_v2/onboarding_journey_state.dart';
import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import '../../screens/app_shell.dart';
import '../../screens/settings_screen.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/toast.dart';
import 'guide_hub_screen.dart';
import 'guide_presentation.dart';
import 'guide_progress_service.dart';
import 'guide_scenario_category_stock.dart';
import 'guide_topic_detail_screen.dart';

abstract final class GuideRuntime {
  static final GuideProgressService progress = GuideProgressService();
}

@immutable
final class GuideDestinationOpenResult {
  const GuideDestinationOpenResult.opened() : failureReason = null;
  const GuideDestinationOpenResult.rejected(this.failureReason);

  final GuideRoutingFailureReason? failureReason;

  bool get didOpen => failureReason == null;
}

/// Resolves typed guide intents at the app boundary. Merely constructing or
/// rendering a topic never requests camera, photo, or microphone permission;
/// each destination owns its contextual permission prompt.
abstract final class GuideDestinationResolver {
  static Future<bool> open(BuildContext context, GuideTopicSpec topic) async {
    final result = await resolve(context, topic);
    return result.didOpen;
  }

  static Future<GuideDestinationOpenResult> resolve(
    BuildContext context,
    GuideTopicSpec topic,
  ) {
    return _resolve(
      context,
      destination: topic.destination,
      availability: topic.availability,
      requiredConsents: topic.requiredConsents,
    );
  }

  static Future<bool> openAction(
    BuildContext context, {
    required GuideTopicSpec topic,
    required GuideModuleActionSpec action,
  }) async {
    final result = await resolveAction(context, topic: topic, action: action);
    return result.didOpen;
  }

  static Future<GuideDestinationOpenResult> resolveAction(
    BuildContext context, {
    required GuideTopicSpec topic,
    required GuideModuleActionSpec action,
  }) {
    return _resolve(
      context,
      destination: action.destination,
      // The topic is the availability authority for all actions retained from
      // its module. Never upgrade a preview or coming-soon action at this
      // lower-level resolver boundary.
      availability: topic.availability,
      requiredConsents: action.requiredConsents,
    );
  }

  /// Opens one runtime-stocked scenario shelf. This is always a secondary
  /// Learn action and therefore carries no guide completion side effect.
  static Future<bool> openScenarioCategory(
    BuildContext context,
    ScenarioBrowseDestination destination,
  ) async {
    final result = await resolveScenarioCategory(context, destination);
    return result.didOpen;
  }

  static Future<GuideDestinationOpenResult> resolveScenarioCategory(
    BuildContext context,
    ScenarioBrowseDestination destination,
  ) {
    return _resolve(
      context,
      destination: destination,
      availability: FeatureAvailability.live,
      requiredConsents: const {},
    );
  }

  static Future<GuideDestinationOpenResult> _resolve(
    BuildContext context, {
    required GuideDestination destination,
    required FeatureAvailability availability,
    required Set<GuideConsentRequirement> requiredConsents,
  }) async {
    if (availability != FeatureAvailability.live) {
      return const GuideDestinationOpenResult.rejected(
        GuideRoutingFailureReason.unavailable,
      );
    }
    if (requiredConsents.contains(GuideConsentRequirement.privacyAccepted) &&
        !Storage.consentAccepted) {
      return const GuideDestinationOpenResult.rejected(
        GuideRoutingFailureReason.consent,
      );
    }

    try {
      switch (destination) {
        case SoriStageTabDestination(:final tab):
          final index = switch (tab) {
            SoriStageTabTarget.learn => 1,
            SoriStageTabTarget.games => 2,
            SoriStageTabTarget.hanok => 3,
          };
          Navigator.of(context).popUntil((route) => route.isFirst);
          AppShell.openStageTab(index);
        case SettingsSectionDestination(:final section):
          final focus = switch (section) {
            SettingsSectionTarget.courseStart =>
              SettingsInitialFocus.courseStart,
            SettingsSectionTarget.browseLevel =>
              SettingsInitialFocus.browseLevel,
            SettingsSectionTarget.companion => SettingsInitialFocus.companion,
            SettingsSectionTarget.voiceSpeed => SettingsInitialFocus.voiceSpeed,
            SettingsSectionTarget.guide => SettingsInitialFocus.guide,
          };
          await Navigator.of(context).pushNamed('/settings', arguments: focus);
        case HangulTargetDestination():
          await Navigator.of(
            context,
          ).pushNamed('/hangul', arguments: destination);
        case ScenarioBrowseDestination():
          if (!_isValidScenarioDestination(destination)) {
            return const GuideDestinationOpenResult.rejected(
              GuideRoutingFailureReason.invalidDestination,
            );
          }
          await Navigator.of(
            context,
          ).pushNamed('/scenarios', arguments: destination);
        case StudyLibraryDestination(:final semanticId):
          switch (semanticId) {
            case StudyLibrarySemanticId.captureTextbook:
              await Navigator.of(context).pushNamed('/book');
            case StudyLibrarySemanticId.captureNotebook:
              await Navigator.of(context).pushNamed('/vocab_notebook');
            case StudyLibrarySemanticId.myWords:
              await Navigator.of(context).pushNamed('/study-library');
          }
        case HeritageDestination():
          // Heritage chapters are preview-only until a runtime consumer can
          // resolve the semantic estate id and its approved descriptor.
          return const GuideDestinationOpenResult.rejected(
            GuideRoutingFailureReason.unavailable,
          );
      }
    } catch (_) {
      return const GuideDestinationOpenResult.rejected(
        GuideRoutingFailureReason.navigation,
      );
    }
    return const GuideDestinationOpenResult.opened();
  }

  static bool _isValidScenarioDestination(
    ScenarioBrowseDestination destination,
  ) {
    final shelfId = destination.shelfId;
    final slots = kChaekgadoSlots[destination.level];
    return isStableSemanticId(shelfId) &&
        slots != null &&
        slots.any(
          (slot) => chaekgadoShelfId(destination.level, slot.slug) == shelfId,
        );
  }
}

typedef GuideTopicClosedReporter =
    Future<void> Function({
      required GuideAnalyticsSurface topic,
      required GuideEntryAnalyticsSurface entrySurface,
    });

typedef GuideTopicOpenedReporter =
    Future<void> Function({
      required GuideAnalyticsSurface topic,
      required GuideEntryAnalyticsSurface entrySurface,
      required GuideTopicOpenState openState,
    });

typedef GuideRoutingFailureReporter =
    Future<void> Function({
      required GuideAnalyticsSurface topic,
      required GuideEntryAnalyticsSurface entrySurface,
      required GuideRoutingAction action,
      required GuideRoutingFailureReason reason,
    });

typedef GuideHubOpenedReporter = Future<void> Function();

/// Stateful runtime wrapper around the passive detail UI.
///
/// A topic is not completed when this route renders. For the current
/// destination-opened contracts, only the catalog action explicitly marked as
/// the completion destination advances progress.
class GuideTopicDetailRouteScreen extends StatefulWidget {
  const GuideTopicDetailRouteScreen({
    super.key,
    required this.topic,
    required this.progressService,
    required this.entrySurface,
    this.closedReporter,
    this.routingFailureReporter,
    this.loadScenarios,
    this.scenarioBrowseLevelReader,
  });

  final GuideTopicSpec topic;
  final GuideProgressService progressService;
  final GuideEntryAnalyticsSurface entrySurface;
  final GuideTopicClosedReporter? closedReporter;
  final GuideRoutingFailureReporter? routingFailureReporter;
  final GuideScenarioLevelLoader? loadScenarios;
  final LearnerLevel Function()? scenarioBrowseLevelReader;

  @override
  State<GuideTopicDetailRouteScreen> createState() =>
      _GuideTopicDetailRouteScreenState();
}

class _GuideTopicDetailRouteScreenState
    extends State<GuideTopicDetailRouteScreen> {
  final Set<GuideModuleActionId> _openingActions = {};
  final Set<String> _openingScenarioShelves = {};
  LearnerLevel? _scenarioBrowseLevel;
  GuideScenarioCategorySectionStatus? _scenarioCategoryStatus;
  List<GuideScenarioCategoryStock> _scenarioCategoryStock = const [];

  @override
  void initState() {
    super.initState();
    if (widget.topic.id == GuideTopicId.learn) {
      _scenarioBrowseLevel =
          widget.scenarioBrowseLevelReader?.call() ??
          resolveGuideScenarioBrowseLevel(
            browseLevelCode: Storage.browseLevelCode,
            userLevelCode: Storage.userLevelCode,
          );
      _scenarioCategoryStatus = GuideScenarioCategorySectionStatus.loading;
      unawaited(_loadScenarioCategories());
    }
  }

  Future<void> _loadScenarioCategories() async {
    final level = _scenarioBrowseLevel;
    if (level == null) {
      return;
    }
    try {
      final stock = await GuideScenarioCategoryStockLoader.loadLevel(
        level,
        loadScenarios: widget.loadScenarios,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _scenarioCategoryStock = stock;
        _scenarioCategoryStatus = stock.isEmpty
            ? GuideScenarioCategorySectionStatus.empty
            : GuideScenarioCategorySectionStatus.ready;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _scenarioCategoryStock = const [];
        _scenarioCategoryStatus = GuideScenarioCategorySectionStatus.failed;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_reportClosed());
    super.dispose();
  }

  Future<void> _reportClosed() async {
    try {
      await (widget.closedReporter ?? Analytics.guideTopicClosed)(
        topic: widget.topic.analyticsSurface,
        entrySurface: widget.entrySurface,
      );
    } catch (_) {
      // Telemetry is best effort and must never affect route disposal.
    }
  }

  Future<void> _reportRoutingFailure({
    required GuideRoutingAction action,
    required GuideRoutingFailureReason reason,
  }) async {
    try {
      await (widget.routingFailureReporter ?? Analytics.guideRoutingFailed)(
        topic: widget.topic.analyticsSurface,
        entrySurface: widget.entrySurface,
        action: action,
        reason: reason,
      );
    } catch (_) {
      // Telemetry is best effort and must never affect guide navigation.
    }
  }

  Future<void> _rollbackCompletion({
    required bool completionPersisted,
    required GuideRoutingAction action,
  }) async {
    if (!completionPersisted) {
      return;
    }
    try {
      await widget.progressService.markTopicIncomplete(widget.topic.id);
    } catch (_) {
      unawaited(
        _reportRoutingFailure(
          action: action,
          reason: GuideRoutingFailureReason.rollback,
        ),
      );
    }
  }

  Future<void> _openAction(GuideModuleActionViewModel action) async {
    if (!_openingActions.add(action.spec.id)) {
      return;
    }
    final completesTopic =
        widget.topic.completionMode == GuideCompletionMode.destinationOpened &&
        action.spec.completesTopic;
    final routingAction = _guideRoutingAction(action.spec.id);
    var completionPersisted = false;
    var wasComplete = false;
    try {
      // Persist immediately before trusted local navigation. Stage-tab intents
      // intentionally remove this route, while pushed destinations resolve
      // only when the learner returns.
      if (completesTopic) {
        try {
          wasComplete = (await widget.progressService.load()).isComplete(
            widget.topic.id,
          );
          if (!wasComplete) {
            await widget.progressService.markTopicCompleted(widget.topic.id);
            completionPersisted = true;
          }
        } catch (_) {
          unawaited(
            _reportRoutingFailure(
              action: routingAction,
              reason: GuideRoutingFailureReason.rollback,
            ),
          );
          if (mounted) {
            soriNotice(context, AppL10n.of(context).guideFeatureNotAvailable);
          }
          return;
        }
      }
      if (!mounted) {
        await _rollbackCompletion(
          completionPersisted: completionPersisted,
          action: routingAction,
        );
        unawaited(
          _reportRoutingFailure(
            action: routingAction,
            reason: GuideRoutingFailureReason.navigation,
          ),
        );
        return;
      }
      GuideDestinationOpenResult result;
      try {
        result = await GuideDestinationResolver.resolveAction(
          context,
          topic: widget.topic,
          action: action.spec,
        );
      } catch (_) {
        result = const GuideDestinationOpenResult.rejected(
          GuideRoutingFailureReason.navigation,
        );
      }
      if (!result.didOpen) {
        await _rollbackCompletion(
          completionPersisted: completionPersisted,
          action: routingAction,
        );
        unawaited(
          _reportRoutingFailure(
            action: routingAction,
            reason: result.failureReason!,
          ),
        );
        if (mounted) {
          soriNotice(context, AppL10n.of(context).guideFeatureNotAvailable);
        }
        return;
      }
      if (completesTopic && !wasComplete) {
        unawaited(
          Analytics.guideTopicCompleted(
            topic: widget.topic.analyticsSurface,
            entrySurface: widget.entrySurface,
          ),
        );
      }
    } finally {
      _openingActions.remove(action.spec.id);
    }
  }

  Future<void> _openScenarioCategory(
    GuideScenarioCategoryViewModel category,
  ) async {
    final shelfId = category.destination.shelfId;
    if (!_openingScenarioShelves.add(shelfId)) {
      return;
    }
    try {
      GuideDestinationOpenResult result;
      try {
        result = await GuideDestinationResolver.resolveScenarioCategory(
          context,
          category.destination,
        );
      } catch (_) {
        result = const GuideDestinationOpenResult.rejected(
          GuideRoutingFailureReason.navigation,
        );
      }
      if (!result.didOpen) {
        unawaited(
          _reportRoutingFailure(
            action: GuideRoutingAction.scenarioCategory,
            reason: result.failureReason!,
          ),
        );
        if (mounted) {
          soriNotice(context, AppL10n.of(context).guideFeatureNotAvailable);
        }
      }
    } finally {
      _openingScenarioShelves.remove(shelfId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = _scenarioBrowseLevel;
    final status = _scenarioCategoryStatus;
    final scenarioCategories = level == null || status == null
        ? null
        : guideScenarioCategorySectionViewModel(
            t,
            level: level,
            status: status,
            stock: _scenarioCategoryStock,
          );
    return GuideTopicDetailScreen(
      module: guideTopicModuleViewModel(
        t,
        widget.topic,
        scenarioCategories: scenarioCategories,
      ),
      onActionRequested: (action) => unawaited(_openAction(action)),
      onScenarioCategoryRequested: (category) =>
          unawaited(_openScenarioCategory(category)),
    );
  }
}

GuideRoutingAction _guideRoutingAction(GuideModuleActionId action) =>
    switch (action) {
      GuideModuleActionId.courseStart => GuideRoutingAction.courseStart,
      GuideModuleActionId.browseLevel => GuideRoutingAction.browseLevel,
      GuideModuleActionId.hangulOverview => GuideRoutingAction.hangulOverview,
      GuideModuleActionId.hangulCards => GuideRoutingAction.hangulCards,
      GuideModuleActionId.hangulWrite => GuideRoutingAction.hangulWrite,
      GuideModuleActionId.learnStage => GuideRoutingAction.learnStage,
      GuideModuleActionId.captureTextbook => GuideRoutingAction.captureTextbook,
      GuideModuleActionId.studyLibrary => GuideRoutingAction.studyLibrary,
      GuideModuleActionId.gamesStage => GuideRoutingAction.gamesStage,
      GuideModuleActionId.hanokStage => GuideRoutingAction.hanokStage,
      GuideModuleActionId.companion => GuideRoutingAction.companion,
      GuideModuleActionId.voiceSpeed => GuideRoutingAction.voiceSpeed,
      GuideModuleActionId.guideSettings => GuideRoutingAction.guideSettings,
    };

Future<void> openGuideTopicModule(
  BuildContext context, {
  required GuideTopicSpec topic,
  required GuideProgressService progressService,
  required GuideEntryAnalyticsSurface entrySurface,
  GuideTopicOpenedReporter? openedReporter,
  GuideRoutingFailureReporter? routingFailureReporter,
}) async {
  try {
    // §B1: 가이드 상세도 플랫폼 네이티브 전환.
    final navigation = Navigator.of(context).push<void>(
      SoriTransitions.page<void>(
        (_) => GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: progressService,
          entrySurface: entrySurface,
          routingFailureReporter: routingFailureReporter,
        ),
      ),
    );
    unawaited(
      _recordGuideTopicOpened(
        topic: topic,
        progressService: progressService,
        entrySurface: entrySurface,
        reporter: openedReporter,
      ),
    );
    await navigation;
  } catch (_) {
    unawaited(
      _reportGuideRoutingFailure(
        topic: topic.analyticsSurface,
        entrySurface: entrySurface,
        action: GuideRoutingAction.topic,
        reason: GuideRoutingFailureReason.navigation,
        reporter: routingFailureReporter,
      ),
    );
  }
}

Future<void> _recordGuideTopicOpened({
  required GuideTopicSpec topic,
  required GuideProgressService progressService,
  required GuideEntryAnalyticsSurface entrySurface,
  required GuideTopicOpenedReporter? reporter,
}) async {
  try {
    final openState = await progressService.markTopicOpened(topic.id);
    await (reporter ?? Analytics.guideTopicOpened)(
      topic: topic.analyticsSurface,
      entrySurface: entrySurface,
      openState: openState,
    );
  } catch (_) {
    // Never emit an inferred first/reopen label when durable state is unknown.
  }
}

Future<void> _reportGuideRoutingFailure({
  required GuideAnalyticsSurface topic,
  required GuideEntryAnalyticsSurface entrySurface,
  required GuideRoutingAction action,
  required GuideRoutingFailureReason reason,
  required GuideRoutingFailureReporter? reporter,
}) async {
  try {
    await (reporter ?? Analytics.guideRoutingFailed)(
      topic: topic,
      entrySurface: entrySurface,
      action: action,
      reason: reason,
    );
  } catch (_) {
    // Telemetry is best effort and must never affect navigation.
  }
}

class GuideHubRouteScreen extends StatefulWidget {
  const GuideHubRouteScreen({
    super.key,
    this.progressService,
    this.hubOpenedReporter,
    this.topicOpenedReporter,
    this.routingFailureReporter,
  });

  final GuideProgressService? progressService;
  final GuideHubOpenedReporter? hubOpenedReporter;
  final GuideTopicOpenedReporter? topicOpenedReporter;
  final GuideRoutingFailureReporter? routingFailureReporter;

  @override
  State<GuideHubRouteScreen> createState() => _GuideHubRouteScreenState();
}

class _GuideHubRouteScreenState extends State<GuideHubRouteScreen> {
  GuideProgressSnapshot? _snapshot;
  Object? _error;
  final Set<GuideTopicId> _openingTopics = {};
  bool _cardActionInFlight = false;
  String? _restoredStatus;

  GuideProgressService get _service =>
      widget.progressService ?? GuideRuntime.progress;

  @override
  void initState() {
    super.initState();
    unawaited(_reportHubOpened());
    unawaited(_load());
  }

  Future<void> _reportHubOpened() async {
    try {
      await (widget.hubOpenedReporter ?? Analytics.guideHubOpened)();
    } catch (_) {
      // Telemetry is best effort and must never affect hub rendering.
    }
  }

  Future<void> _load() async {
    try {
      final snapshot = await _service.load();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _openTopic(GuideTopicSpec topic) async {
    if (!_openingTopics.add(topic.id)) {
      return;
    }
    try {
      await openGuideTopicModule(
        context,
        topic: topic,
        progressService: _service,
        entrySurface: GuideEntryAnalyticsSurface.guideHub,
        openedReporter: widget.topicOpenedReporter,
        routingFailureReporter: widget.routingFailureReporter,
      );
      if (mounted) {
        await _load();
      }
    } finally {
      _openingTopics.remove(topic.id);
    }
  }

  Future<void> _restoreTodayCard() async {
    if (_cardActionInFlight) {
      return;
    }
    _cardActionInFlight = true;
    try {
      // The restore control disappears after this action. Move focus to the
      // preceding guide action while the current tree still contains both
      // controls so keyboard and assistive-technology users keep context.
      FocusManager.instance.primaryFocus?.previousFocus();
      await _service.restoreTodayCard();
      unawaited(Analytics.guideTodayCardAction(GuideTodayCardAction.restored));
      if (mounted) {
        setState(() {
          _restoredStatus = AppL10n.of(context).guideTodayCardRestoredStatus;
        });
      }
      await _load();
    } catch (_) {
      // Keep the restore control and durable dismissal state unchanged when
      // preference storage is unavailable. This callback is intentionally
      // unawaited by the button, so failures must be contained here.
      if (mounted) {
        soriNotice(context, AppL10n.of(context).guidePreferenceWriteFailed);
      }
    } finally {
      _cardActionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final snapshot = _snapshot;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.guideHubAppBarTitle)),
        body: Center(
          child: SoriButton.filled(
            label: t.btnRetry,
            onTap: () => unawaited(_load()),
          ),
        ),
      );
    }
    if (snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.guideHubAppBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return GuideHubScreen(
      copy: guideHubCopy(t),
      topics: guideTopicViewModels(t, snapshot),
      onDestinationRequested: (topic) => unawaited(_openTopic(topic)),
      onNonLiveTopicRequested: (topic) => unawaited(_openTopic(topic)),
      footer: snapshot.isTodayCardDismissed
          ? SoriButton.outlined(
              key: const ValueKey('guide-restore-today-card'),
              label: t.guideRestoreTodayCard,
              icon: Icons.restore_rounded,
              fullWidth: true,
              onTap: () => unawaited(_restoreTodayCard()),
            )
          : _restoredStatus == null
          ? null
          : Semantics(
              key: const ValueKey('guide-today-card-restored-status'),
              liveRegion: true,
              label: _restoredStatus,
              child: ExcludeSemantics(
                child: Text(
                  _restoredStatus!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
    );
  }
}

GuideHubCopy guideHubCopy(AppL10n t) => GuideHubCopy(
  appBarTitle: t.guideHubAppBarTitle,
  eyebrow: t.guideHubEyebrow,
  title: t.guideHubTitle,
  description: t.guideHubDescription,
  completedLabel: t.guideCompletedLabel,
);

TodayGuideChecklistCopy todayGuideChecklistCopy(
  AppL10n t, {
  required int completed,
  required int total,
}) => TodayGuideChecklistCopy(
  title: t.todayGuideTitle,
  description: t.todayGuideDescription,
  progressLabel: t.todayGuideProgress(completed, total),
  completedLabel: t.guideCompletedLabel,
  openGuideLabel: t.todayGuideOpenHub,
  dismissLabel: t.todayGuideDismiss,
);

List<GuideTopicViewModel> guideTopicViewModels(
  AppL10n t,
  GuideProgressSnapshot snapshot, {
  List<GuideTopicSpec>? topics,
}) {
  return [
    for (final topic in topics ?? GuideTopicCatalog.all)
      GuideTopicViewModel(
        spec: topic,
        title: _topicTitle(t, topic.id),
        description: _topicDescription(t, topic.id),
        availabilityLabel: _availabilityLabel(t, topic.availability),
        actionLabel: _actionLabel(t, topic.availability),
        isCompleted: snapshot.isComplete(topic.id),
      ),
  ];
}

GuideTopicModuleViewModel guideTopicModuleViewModel(
  AppL10n t,
  GuideTopicSpec topic, {
  GuideScenarioCategorySectionViewModel? scenarioCategories,
}) {
  final topicViewModel = GuideTopicViewModel(
    spec: topic,
    title: _topicTitle(t, topic.id),
    description: _topicDescription(t, topic.id),
    availabilityLabel: _availabilityLabel(t, topic.availability),
    actionLabel: _actionLabel(t, topic.availability),
    // Completion is intentionally owned by the durable route wrapper. The
    // passive presentation does not infer it merely because it was rendered.
    isCompleted: false,
  );
  final stepBodies = _moduleStepBodies(t, topic.id);
  final actionSpecs = topic.availability == FeatureAvailability.live
      ? GuideModuleCatalog.byTopic[topic.id] ?? const <GuideModuleActionSpec>[]
      : const <GuideModuleActionSpec>[];
  return GuideTopicModuleViewModel(
    topic: topicViewModel,
    appBarTitle: topicViewModel.title,
    eyebrow: t.guideModuleEyebrow,
    stepsTitle: t.guideModuleStepsTitle,
    actionsTitle: t.guideModuleActionsTitle,
    passiveNotice: t.guideModulePassiveNotice,
    steps: List.unmodifiable([
      for (var index = 0; index < stepBodies.length; index++)
        GuideModuleStepViewModel(number: index + 1, body: stepBodies[index]),
    ]),
    actions: List.unmodifiable([
      for (final action in actionSpecs)
        GuideModuleActionViewModel(
          spec: action,
          label: _moduleActionLabel(t, action.id),
        ),
    ]),
    scenarioCategories: scenarioCategories,
  );
}

GuideScenarioCategorySectionViewModel guideScenarioCategorySectionViewModel(
  AppL10n t, {
  required LearnerLevel level,
  required GuideScenarioCategorySectionStatus status,
  List<GuideScenarioCategoryStock> stock = const [],
}) {
  final ready = status == GuideScenarioCategorySectionStatus.ready;
  final totalCount = ready
      ? stock.fold<int>(0, (total, category) => total + category.scenarioCount)
      : 0;
  final summary = ready
      ? t.listeningLevelDrawer(level.display, totalCount)
      : null;
  final statusLabel = switch (status) {
    GuideScenarioCategorySectionStatus.loading => t.scenariosListTitle,
    GuideScenarioCategorySectionStatus.ready => summary!,
    GuideScenarioCategorySectionStatus.empty => t.scenariosEmptyBody,
    GuideScenarioCategorySectionStatus.failed => t.scenariosLoadFailedTitle,
  };
  return GuideScenarioCategorySectionViewModel(
    status: status,
    title: t.scenariosListTitle,
    statusLabel: statusLabel,
    summary: summary,
    categories: ready
        ? List.unmodifiable([
            for (final category in stock)
              GuideScenarioCategoryViewModel(
                destination: category.destination,
                label: chaekgadoSlotLabel(t, category.imageKey),
                countLabel: t.guideScenarioCategoryCount(
                  category.scenarioCount,
                ),
              ),
          ])
        : const [],
  );
}

List<String> _moduleStepBodies(AppL10n t, GuideTopicId id) => switch (id) {
  GuideTopicId.personalizedStart => [
    t.guideModulePersonalizedStartStep1,
    t.guideModulePersonalizedStartStep2,
  ],
  GuideTopicId.learn => [
    t.guideModuleLearnStep1,
    t.guideModuleLearnStep2,
    t.guideModuleLearnStep3,
  ],
  GuideTopicId.myBook => [
    t.guideModuleMyBookStep1,
    t.guideModuleMyBookStep2,
    t.guideModuleMyBookStep3,
  ],
  GuideTopicId.cardsAndMemory => [
    t.guideModuleCardsStep1,
    t.guideModuleCardsStep2,
    t.guideModuleCardsStep3,
  ],
  GuideTopicId.gamesAndRewards => [
    t.guideModuleGamesStep1,
    t.guideModuleGamesStep2,
    t.guideModuleGamesStep3,
  ],
  GuideTopicId.settings => [
    t.guideModuleSettingsStep1,
    t.guideModuleSettingsStep2,
    t.guideModuleSettingsStep3,
  ],
};

String _moduleActionLabel(AppL10n t, GuideModuleActionId id) => switch (id) {
  GuideModuleActionId.courseStart => t.guideModuleActionCourseStart,
  GuideModuleActionId.browseLevel => t.guideModuleActionBrowseLevel,
  GuideModuleActionId.hangulOverview => t.guideModuleActionHangulOverview,
  GuideModuleActionId.hangulCards => t.guideModuleActionHangulCards,
  GuideModuleActionId.hangulWrite => t.guideModuleActionHangulWrite,
  GuideModuleActionId.learnStage => t.guideModuleActionLearnStage,
  GuideModuleActionId.captureTextbook => t.guideModuleActionCaptureTextbook,
  GuideModuleActionId.studyLibrary => t.guideModuleActionStudyLibrary,
  GuideModuleActionId.gamesStage => t.guideModuleActionGamesStage,
  GuideModuleActionId.hanokStage => t.guideModuleActionHanokStage,
  GuideModuleActionId.companion => t.guideModuleActionCompanion,
  GuideModuleActionId.voiceSpeed => t.guideModuleActionVoiceSpeed,
  GuideModuleActionId.guideSettings => t.guideModuleActionGuideSettings,
};

List<GuideTopicSpec> purposeOrderedGuideTopics(String motivation) {
  final purpose = OnboardingPurpose.fromCode(motivation);
  final priority = switch (purpose) {
    OnboardingPurpose.peopleCulture => const [
      GuideTopicId.learn,
      GuideTopicId.personalizedStart,
      GuideTopicId.gamesAndRewards,
    ],
    OnboardingPurpose.studyWork => const [
      GuideTopicId.personalizedStart,
      GuideTopicId.myBook,
      GuideTopicId.learn,
    ],
    OnboardingPurpose.kContent => const [
      GuideTopicId.learn,
      GuideTopicId.gamesAndRewards,
      GuideTopicId.personalizedStart,
    ],
    OnboardingPurpose.dailyTravel || null => const [
      GuideTopicId.personalizedStart,
      GuideTopicId.learn,
      GuideTopicId.myBook,
    ],
  };
  final prioritizedIds = priority.toSet();
  return [
    for (final id in priority)
      GuideTopicCatalog.all.firstWhere((topic) => topic.id == id),
    for (final topic in GuideTopicCatalog.all)
      if (!prioritizedIds.contains(topic.id)) topic,
  ];
}

String _topicTitle(AppL10n t, GuideTopicId id) => switch (id) {
  GuideTopicId.personalizedStart => t.guideTopicPersonalizedStartTitle,
  GuideTopicId.learn => t.guideTopicLearnTitle,
  GuideTopicId.myBook => t.guideTopicMyBookTitle,
  GuideTopicId.cardsAndMemory => t.guideTopicCardsAndMemoryTitle,
  GuideTopicId.gamesAndRewards => t.guideTopicGamesAndRewardsTitle,
  GuideTopicId.settings => t.guideTopicSettingsTitle,
};

String _topicDescription(AppL10n t, GuideTopicId id) => switch (id) {
  GuideTopicId.personalizedStart => t.guideTopicPersonalizedStartDescription,
  GuideTopicId.learn => t.guideTopicLearnDescription,
  GuideTopicId.myBook => t.guideTopicMyBookDescription,
  GuideTopicId.cardsAndMemory => t.guideTopicCardsAndMemoryDescription,
  GuideTopicId.gamesAndRewards => t.guideTopicGamesAndRewardsDescription,
  GuideTopicId.settings => t.guideTopicSettingsDescription,
};

String _availabilityLabel(AppL10n t, FeatureAvailability availability) =>
    switch (availability) {
      FeatureAvailability.live => t.guideAvailabilityLive,
      FeatureAvailability.preview => t.guideAvailabilityPreview,
      FeatureAvailability.comingSoon => t.guideAvailabilityComingSoon,
      FeatureAvailability.unavailable => t.guideAvailabilityUnavailable,
    };

String _actionLabel(AppL10n t, FeatureAvailability availability) =>
    switch (availability) {
      FeatureAvailability.live => t.guideOpenAction,
      FeatureAvailability.preview => t.guidePreviewAction,
      FeatureAvailability.comingSoon ||
      FeatureAvailability.unavailable => t.guideDetailsAction,
    };
