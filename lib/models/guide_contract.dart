import '../data/sori_activity_catalog.dart';
import 'learner_level.dart';
import 'onboarding_contract_validation.dart';
import 'sori_stage_progression.dart';

/// A route-independent destination resolved by the app shell at runtime.
sealed class GuideDestination {
  const GuideDestination();
}

enum SoriStageTabTarget { learn, games, hanok }

final class SoriStageTabDestination extends GuideDestination {
  const SoriStageTabDestination(this.tab);

  final SoriStageTabTarget tab;
}

enum SettingsSectionTarget {
  courseStart,
  browseLevel,
  companion,
  voiceSpeed,
  guide,
}

final class SettingsSectionDestination extends GuideDestination {
  const SettingsSectionDestination(this.section);

  final SettingsSectionTarget section;
}

enum HangulTarget { overview, cards, write }

final class HangulTargetDestination extends GuideDestination {
  const HangulTargetDestination(this.target);

  final HangulTarget target;
}

final class ScenarioBrowseDestination extends GuideDestination {
  const ScenarioBrowseDestination({required this.level, required this.shelfId});

  final LearnerLevel level;
  final String shelfId;
}

enum StudyLibrarySemanticId {
  myWords,
  captureTextbook,
  captureNotebook;

  String get stableId => name;
}

/// This semantic destination deliberately does not expose a storage or route.
/// The study-library resolver may compose multiple existing repositories.
final class StudyLibraryDestination extends GuideDestination {
  const StudyLibraryDestination(this.semanticId);

  final StudyLibrarySemanticId semanticId;
}

final class HeritageDestination extends GuideDestination {
  const HeritageDestination(this.estateId);

  final String estateId;
}

enum FeatureAvailability { live, preview, comingSoon, unavailable }

enum GuideConsentRequirement { privacyAccepted, pronunciationProcessing }

enum GuidePermissionRequirement { camera, photoLibrary, microphone }

enum GuideSurface { onboardingStory, todayChecklist, guideHub, contextualCoach }

enum GuideCompletionMode {
  acknowledged,
  destinationOpened,
  primaryActionCompleted,
}

/// Compile-time feature identities. These are not Remote Config keys.
enum GuideFeatureFlag { onboardingV2, unifiedStudyLibrary, heritageJourney }

/// Closed enum keeps analytics cardinality bounded.
enum GuideAnalyticsSurface {
  personalizedStart,
  learn,
  myBook,
  cardsAndMemory,
  gamesAndRewards,
  settings,
}

enum GuideTopicId {
  personalizedStart,
  learn,
  myBook,
  cardsAndMemory,
  gamesAndRewards,
  settings;

  String get stableId => switch (this) {
    GuideTopicId.personalizedStart => 'personalized-start',
    GuideTopicId.learn => 'learn',
    GuideTopicId.myBook => 'my-book',
    GuideTopicId.cardsAndMemory => 'cards-and-memory',
    GuideTopicId.gamesAndRewards => 'games-and-rewards',
    GuideTopicId.settings => 'settings',
  };
}

enum GuideModuleActionId {
  courseStart,
  browseLevel,
  hangulOverview,
  hangulCards,
  hangulWrite,
  learnStage,
  captureTextbook,
  studyLibrary,
  gamesStage,
  hanokStage,
  companion,
  voiceSpeed,
  guideSettings;

  String get stableId => switch (this) {
    GuideModuleActionId.courseStart => 'course-start',
    GuideModuleActionId.browseLevel => 'browse-level',
    GuideModuleActionId.hangulOverview => 'hangul-overview',
    GuideModuleActionId.hangulCards => 'hangul-cards',
    GuideModuleActionId.hangulWrite => 'hangul-write',
    GuideModuleActionId.learnStage => 'learn-stage',
    GuideModuleActionId.captureTextbook => 'capture-textbook',
    GuideModuleActionId.studyLibrary => 'study-library',
    GuideModuleActionId.gamesStage => 'games-stage',
    GuideModuleActionId.hanokStage => 'hanok-stage',
    GuideModuleActionId.companion => 'companion',
    GuideModuleActionId.voiceSpeed => 'voice-speed',
    GuideModuleActionId.guideSettings => 'guide-settings',
  };
}

/// Durable classification for explicit guide-topic activations.
///
/// This is intentionally a closed two-value contract: analytics must never
/// infer a reopen from transient widget state or attach an unbounded counter.
enum GuideTopicOpenState { firstOpen, reopen }

/// Closed reasons why a typed guide destination did not open.
///
/// Route names, exception messages, content ids, and learner data must never
/// be substituted for these bounded values.
enum GuideRoutingFailureReason {
  unavailable,
  consent,
  invalidDestination,
  navigation,
  rollback,
}

/// Closed identity for the explicit guide action whose destination failed.
/// Runtime-stocked scenario shelves deliberately share one category bucket so
/// their semantic shelf ids never become analytics dimensions.
enum GuideRoutingAction {
  topic,
  courseStart,
  browseLevel,
  hangulOverview,
  hangulCards,
  hangulWrite,
  learnStage,
  captureTextbook,
  studyLibrary,
  gamesStage,
  hanokStage,
  companion,
  voiceSpeed,
  guideSettings,
  scenarioCategory,
}

/// One independently selectable action in a guide detail module.
///
/// Destinations stay typed all the way to the app boundary. Requirements are
/// checked only when this action is activated; rendering a module must never
/// request a permission or start a platform SDK.
final class GuideModuleActionSpec {
  const GuideModuleActionSpec({
    required this.id,
    required this.destination,
    required this.requiredConsents,
    required this.requiredPermissions,
    this.completesTopic = false,
  });

  final GuideModuleActionId id;
  final GuideDestination destination;
  final Set<GuideConsentRequirement> requiredConsents;
  final Set<GuidePermissionRequirement> requiredPermissions;

  /// True only for the destination named by the topic completion contract.
  /// Secondary actions remain useful without silently completing the topic.
  final bool completesTopic;

  ContractValidationResult validate({required GuideTopicId topicId}) {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(id.stableId)) {
      violations.add(
        ContractViolation(
          code: 'guide.invalid_module_action_id',
          field: '${topicId.stableId}.${id.stableId}',
          message: 'Module action ids must be stable semantic identifiers.',
        ),
      );
    }
    violations.addAll(
      _validateDestination(destination, '${topicId.stableId}.${id.stableId}'),
    );
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

final class GuideTopicSpec {
  const GuideTopicSpec({
    required this.id,
    required this.localizationKey,
    required this.destination,
    required this.availability,
    required this.requiredConsents,
    required this.requiredPermissions,
    required this.surfaces,
    required this.completionMode,
    required this.analyticsSurface,
    this.featureFlag,
  });

  final GuideTopicId id;
  final String localizationKey;
  final GuideDestination destination;
  final FeatureAvailability availability;

  /// Requirements are evaluated only when opening [destination]. Merely
  /// rendering onboarding or the guide must never request a permission.
  final Set<GuideConsentRequirement> requiredConsents;
  final Set<GuidePermissionRequirement> requiredPermissions;
  final Set<GuideSurface> surfaces;
  final GuideCompletionMode completionMode;
  final GuideFeatureFlag? featureFlag;
  final GuideAnalyticsSurface analyticsSurface;

  ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(id.stableId)) {
      violations.add(
        ContractViolation(
          code: 'guide.invalid_topic_id',
          field: id.stableId,
          message: 'Topic ids must be stable low-cardinality identifiers.',
        ),
      );
    }
    if (!isDartLocalizationKey(localizationKey)) {
      violations.add(
        ContractViolation(
          code: 'guide.invalid_localization_key',
          field: id.stableId,
          message: 'Localization keys must be valid generated Dart getters.',
        ),
      );
    }
    if (surfaces.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'guide.missing_surface',
          field: id.stableId,
          message: 'A guide topic must declare at least one surface.',
        ),
      );
    }
    if (availability != FeatureAvailability.live &&
        completionMode == GuideCompletionMode.primaryActionCompleted) {
      violations.add(
        ContractViolation(
          code: 'guide.non_live_requires_action',
          field: id.stableId,
          message: 'A non-live feature cannot require an unavailable action.',
        ),
      );
    }
    violations.addAll(_validateDestination(destination, id.stableId));
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

List<ContractViolation> _validateDestination(
  GuideDestination destination,
  String field,
) {
  final violations = <ContractViolation>[];
  switch (destination) {
    case ScenarioBrowseDestination(:final level, :final shelfId):
      if (!isStableSemanticId(shelfId)) {
        violations.add(
          ContractViolation(
            code: 'guide.invalid_scenario_shelf',
            field: field,
            message: 'Scenario shelf ids must be semantic identifiers.',
          ),
        );
      } else if (!shelfId.startsWith('${level.code}_')) {
        violations.add(
          ContractViolation(
            code: 'guide.scenario_shelf_level_mismatch',
            field: field,
            message: 'Scenario shelf ids must use the destination level.',
          ),
        );
      }
    case HeritageDestination(:final estateId):
      if (!isStableSemanticId(estateId)) {
        violations.add(
          ContractViolation(
            code: 'guide.invalid_estate_id',
            field: field,
            message: 'Heritage destinations require a semantic estate id.',
          ),
        );
      }
    case SoriStageTabDestination() ||
        SettingsSectionDestination() ||
        HangulTargetDestination() ||
        StudyLibraryDestination():
      break;
  }
  return violations;
}

abstract final class GuideTopicCatalog {
  static const all = <GuideTopicSpec>[
    GuideTopicSpec(
      id: GuideTopicId.personalizedStart,
      localizationKey: 'guideTopicPersonalizedStart',
      destination: SettingsSectionDestination(
        SettingsSectionTarget.courseStart,
      ),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {GuideSurface.todayChecklist, GuideSurface.guideHub},
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.onboardingV2,
      analyticsSurface: GuideAnalyticsSurface.personalizedStart,
    ),
    GuideTopicSpec(
      id: GuideTopicId.learn,
      localizationKey: 'guideTopicLearn',
      destination: HangulTargetDestination(HangulTarget.overview),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {
        GuideSurface.onboardingStory,
        GuideSurface.todayChecklist,
        GuideSurface.guideHub,
        GuideSurface.contextualCoach,
      },
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.onboardingV2,
      analyticsSurface: GuideAnalyticsSurface.learn,
    ),
    GuideTopicSpec(
      id: GuideTopicId.myBook,
      localizationKey: 'guideTopicMyBook',
      destination: StudyLibraryDestination(
        StudyLibrarySemanticId.captureTextbook,
      ),
      availability: FeatureAvailability.live,
      requiredConsents: {GuideConsentRequirement.privacyAccepted},
      requiredPermissions: {GuidePermissionRequirement.camera},
      surfaces: {
        GuideSurface.onboardingStory,
        GuideSurface.todayChecklist,
        GuideSurface.guideHub,
        GuideSurface.contextualCoach,
      },
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.onboardingV2,
      analyticsSurface: GuideAnalyticsSurface.myBook,
    ),
    GuideTopicSpec(
      id: GuideTopicId.cardsAndMemory,
      localizationKey: 'guideTopicCardsAndMemory',
      destination: StudyLibraryDestination(StudyLibrarySemanticId.myWords),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {
        GuideSurface.onboardingStory,
        GuideSurface.todayChecklist,
        GuideSurface.guideHub,
      },
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.unifiedStudyLibrary,
      analyticsSurface: GuideAnalyticsSurface.cardsAndMemory,
    ),
    GuideTopicSpec(
      id: GuideTopicId.gamesAndRewards,
      localizationKey: 'guideTopicGamesAndRewards',
      destination: SoriStageTabDestination(SoriStageTabTarget.games),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {
        GuideSurface.onboardingStory,
        GuideSurface.todayChecklist,
        GuideSurface.guideHub,
        GuideSurface.contextualCoach,
      },
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.onboardingV2,
      analyticsSurface: GuideAnalyticsSurface.gamesAndRewards,
    ),
    GuideTopicSpec(
      id: GuideTopicId.settings,
      localizationKey: 'guideTopicSettings',
      destination: SettingsSectionDestination(
        SettingsSectionTarget.courseStart,
      ),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {
        GuideSurface.todayChecklist,
        GuideSurface.guideHub,
        GuideSurface.contextualCoach,
      },
      completionMode: GuideCompletionMode.destinationOpened,
      featureFlag: GuideFeatureFlag.onboardingV2,
      analyticsSurface: GuideAnalyticsSurface.settings,
    ),
  ];

  static ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    final ids = <String>{};
    final analyticsSurfaces = <GuideAnalyticsSurface>{};
    for (final topic in all) {
      violations.addAll(topic.validate().violations);
      if (!ids.add(topic.id.stableId)) {
        violations.add(
          ContractViolation(
            code: 'guide.duplicate_topic_id',
            field: topic.id.stableId,
            message: 'Guide topic ids must be unique.',
          ),
        );
      }
      if (!analyticsSurfaces.add(topic.analyticsSurface)) {
        violations.add(
          ContractViolation(
            code: 'guide.duplicate_analytics_surface',
            field: topic.id.stableId,
            message: 'Each guide topic needs one bounded analytics surface.',
          ),
        );
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

/// Typed actions exposed by each explanatory guide module.
///
/// Scenario shelves stay out of this static catalog. The Learn detail resolves
/// them from runtime stock as secondary actions; the completion action remains
/// the stable Hangeul overview and never guesses or falls back to a shelf.
abstract final class GuideModuleCatalog {
  static const Map<GuideTopicId, List<GuideModuleActionSpec>> byTopic = {
    GuideTopicId.personalizedStart: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.courseStart,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.courseStart,
        ),
        requiredConsents: {},
        requiredPermissions: {},
        completesTopic: true,
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.browseLevel,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.browseLevel,
        ),
        requiredConsents: {},
        requiredPermissions: {},
      ),
    ],
    GuideTopicId.learn: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.hangulOverview,
        destination: HangulTargetDestination(HangulTarget.overview),
        requiredConsents: {},
        requiredPermissions: {},
        completesTopic: true,
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.hangulCards,
        destination: HangulTargetDestination(HangulTarget.cards),
        requiredConsents: {},
        requiredPermissions: {},
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.hangulWrite,
        destination: HangulTargetDestination(HangulTarget.write),
        requiredConsents: {},
        requiredPermissions: {},
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.learnStage,
        destination: SoriStageTabDestination(SoriStageTabTarget.learn),
        requiredConsents: {},
        requiredPermissions: {},
      ),
    ],
    GuideTopicId.myBook: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.captureTextbook,
        destination: StudyLibraryDestination(
          StudyLibrarySemanticId.captureTextbook,
        ),
        requiredConsents: {GuideConsentRequirement.privacyAccepted},
        requiredPermissions: {GuidePermissionRequirement.camera},
        completesTopic: true,
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.studyLibrary,
        destination: StudyLibraryDestination(StudyLibrarySemanticId.myWords),
        requiredConsents: {},
        requiredPermissions: {},
      ),
    ],
    GuideTopicId.cardsAndMemory: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.studyLibrary,
        destination: StudyLibraryDestination(StudyLibrarySemanticId.myWords),
        requiredConsents: {},
        requiredPermissions: {},
        completesTopic: true,
      ),
    ],
    GuideTopicId.gamesAndRewards: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.gamesStage,
        destination: SoriStageTabDestination(SoriStageTabTarget.games),
        requiredConsents: {},
        requiredPermissions: {},
        completesTopic: true,
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.hanokStage,
        destination: SoriStageTabDestination(SoriStageTabTarget.hanok),
        requiredConsents: {},
        requiredPermissions: {},
      ),
    ],
    GuideTopicId.settings: [
      GuideModuleActionSpec(
        id: GuideModuleActionId.courseStart,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.courseStart,
        ),
        requiredConsents: {},
        requiredPermissions: {},
        completesTopic: true,
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.browseLevel,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.browseLevel,
        ),
        requiredConsents: {},
        requiredPermissions: {},
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.companion,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.companion,
        ),
        requiredConsents: {},
        requiredPermissions: {},
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.voiceSpeed,
        destination: SettingsSectionDestination(
          SettingsSectionTarget.voiceSpeed,
        ),
        requiredConsents: {},
        requiredPermissions: {},
      ),
      GuideModuleActionSpec(
        id: GuideModuleActionId.guideSettings,
        destination: SettingsSectionDestination(SettingsSectionTarget.guide),
        requiredConsents: {},
        requiredPermissions: {},
      ),
    ],
  };

  static ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    for (final topic in GuideTopicCatalog.all) {
      final actions = byTopic[topic.id] ?? const [];
      if (actions.isEmpty) {
        violations.add(
          ContractViolation(
            code: 'guide.module_without_actions',
            field: topic.id.stableId,
            message: 'Every guide module needs at least one typed action.',
          ),
        );
        continue;
      }
      final ids = <GuideModuleActionId>{};
      for (final action in actions) {
        violations.addAll(action.validate(topicId: topic.id).violations);
        if (!ids.add(action.id)) {
          violations.add(
            ContractViolation(
              code: 'guide.duplicate_module_action',
              field: '${topic.id.stableId}.${action.id.stableId}',
              message: 'Action ids must be unique inside a guide module.',
            ),
          );
        }
      }
      final completionActions = actions
          .where((action) => action.completesTopic)
          .toList(growable: false);
      if (topic.completionMode == GuideCompletionMode.destinationOpened &&
          completionActions.length != 1) {
        violations.add(
          ContractViolation(
            code: 'guide.invalid_destination_completion_actions',
            field: topic.id.stableId,
            message:
                'A destination-opened topic needs exactly one completion action.',
          ),
        );
      } else if (topic.completionMode ==
              GuideCompletionMode.destinationOpened &&
          _destinationSemanticKey(completionActions.single.destination) !=
              _destinationSemanticKey(topic.destination)) {
        violations.add(
          ContractViolation(
            code: 'guide.completion_destination_mismatch',
            field: topic.id.stableId,
            message:
                'The completion action must open the topic destination contract.',
          ),
        );
      }
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

String _destinationSemanticKey(GuideDestination destination) =>
    switch (destination) {
      SoriStageTabDestination(:final tab) => 'stage:${tab.name}',
      SettingsSectionDestination(:final section) => 'settings:${section.name}',
      HangulTargetDestination(:final target) => 'hangul:${target.name}',
      ScenarioBrowseDestination(:final level, :final shelfId) =>
        'scenario:${level.code}:$shelfId',
      StudyLibraryDestination(:final semanticId) =>
        'library:${semanticId.name}',
      HeritageDestination(:final estateId) => 'heritage:$estateId',
    };

enum RewardPreviewKind { xp, personalRecord, quest, stamp, bojagi, decoration }

enum RewardPreviewMutation {
  xp,
  personalRecord,
  questProgress,
  stampBook,
  inventory,
  heritageProgress,
}

/// A read-only projection of rewards already declared by an activity catalog.
final class RewardPreviewSpec {
  const RewardPreviewSpec({
    required this.activityId,
    required this.localizationKey,
    required this.possibleRewards,
    this.declaredMutations = const {},
  });

  final String activityId;
  final String localizationKey;
  final Set<RewardPreviewKind> possibleRewards;
  final Set<RewardPreviewMutation> declaredMutations;

  ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(activityId)) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.invalid_activity_id',
          field: activityId,
          message: 'Reward previews must reference a stable activity id.',
        ),
      );
    }
    if (!isDartLocalizationKey(localizationKey)) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.invalid_localization_key',
          field: activityId,
          message: 'Reward preview copy must come from localization.',
        ),
      );
    }
    if (possibleRewards.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.empty',
          field: activityId,
          message: 'A preview needs at least one catalog-declared reward.',
        ),
      );
    }
    final catalogMatches = soriActivityCatalog
        .where((activity) => activity.id == activityId)
        .toList(growable: false);
    if (catalogMatches.isEmpty) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.unknown_activity',
          field: activityId,
          message:
              'Reward previews must reference a production activity catalog entry.',
        ),
      );
    } else if (catalogMatches.length != 1) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.ambiguous_activity',
          field: activityId,
          message: 'Reward preview activity ids must resolve exactly once.',
        ),
      );
    } else {
      final activity = catalogMatches.single;
      if (activity.reward.activityId != activity.id) {
        violations.add(
          ContractViolation(
            code: 'reward_preview.invalid_catalog_contract',
            field: activityId,
            message: 'The activity and reward catalog ids must agree.',
          ),
        );
      } else {
        final catalogRewards = <RewardPreviewKind>{
          for (final item in activity.reward.items)
            if (_rewardPreviewKind(item.kind) case final kind?) kind,
        };
        if (!_sameRewardPreviewKinds(possibleRewards, catalogRewards)) {
          violations.add(
            ContractViolation(
              code: 'reward_preview.catalog_mismatch',
              field: activityId,
              message:
                  'A preview must exactly match the production catalog rewards.',
            ),
          );
        }
      }
    }
    if (declaredMutations.isNotEmpty) {
      violations.add(
        ContractViolation(
          code: 'reward_preview.mutation_forbidden',
          field: activityId,
          message: 'A reward preview must not mutate learner state.',
        ),
      );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}

RewardPreviewKind? _rewardPreviewKind(SoriRewardKind kind) => switch (kind) {
  SoriRewardKind.none => null,
  SoriRewardKind.xp => RewardPreviewKind.xp,
  SoriRewardKind.stamp => RewardPreviewKind.stamp,
  SoriRewardKind.questProgress => RewardPreviewKind.quest,
  SoriRewardKind.hanokProgress ||
  SoriRewardKind.gyeLantern => RewardPreviewKind.decoration,
  SoriRewardKind.bojagi => RewardPreviewKind.bojagi,
  SoriRewardKind.personalBest => RewardPreviewKind.personalRecord,
};

bool _sameRewardPreviewKinds(
  Set<RewardPreviewKind> declared,
  Set<RewardPreviewKind> catalog,
) => declared.length == catalog.length && declared.containsAll(catalog);
