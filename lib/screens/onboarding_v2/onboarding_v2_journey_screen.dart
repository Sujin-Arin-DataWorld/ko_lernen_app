import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/onboarding_v2/first_run_coordinator.dart';
import '../../features/onboarding_v2/first_run_runtime.dart';
import '../../features/onboarding_v2/onboarding_journey_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../motion/transitions.dart';
import '../../services/analytics_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/character_clip.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/toast.dart';
import '../app_shell.dart';
import '../intro_gate_screen.dart';
import 'onboarding_companion_screen.dart';
import 'onboarding_setup_screen.dart';
import 'onboarding_story_screen.dart';
import 'onboarding_v2_copy.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

/// Connects the pure V2 presentation to the durable first-run coordinator.
/// No draft changes product data; only the final explicit CTA begins commit.
class OnboardingV2JourneyScreen extends StatefulWidget {
  const OnboardingV2JourneyScreen({
    super.key,
    this.firstRunCoordinator,
    this.initialResolution,
  });

  final FirstRunCoordinator? firstRunCoordinator;

  /// Splash already resolved the single authoritative first-run decision.
  /// Passing it here prevents a second repository read/migration during the
  /// same launch. Direct routes omit it and resolve normally.
  final FirstRunResolution? initialResolution;

  @override
  State<OnboardingV2JourneyScreen> createState() =>
      _OnboardingV2JourneyScreenState();
}

class _OnboardingV2JourneyScreenState extends State<OnboardingV2JourneyScreen> {
  OnboardingJourneyState? _state;
  Object? _loadError;
  bool _busy = false;
  final Stopwatch _journeyStopwatch = Stopwatch();
  final Set<OnboardingPurpose> _pendingPurposes = {};
  final Set<LearnerLevel> _pendingLevels = {};
  final Set<OnboardingCompanion> _pendingCompanions = {};
  StoryPageId? _observedStoryPage;
  Stopwatch? _storyStopwatch;
  bool _journeyDurationRecorded = false;
  bool _usedInitialResolution = false;

  FirstRunCoordinator get _coordinator =>
      widget.firstRunCoordinator ?? FirstRunRuntime.coordinator;

  @override
  void initState() {
    super.initState();
    _journeyStopwatch.start();
    unawaited(_load());
  }

  @override
  void dispose() {
    _recordStoryExit(OnboardingStoryExit.dropped);
    _journeyStopwatch.stop();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loadError = null);
    }
    try {
      final initialResolution = widget.initialResolution;
      final resolution = !_usedInitialResolution && initialResolution != null
          ? initialResolution
          : await _coordinator.resolveEntry();
      _usedInitialResolution = true;
      if (!mounted) {
        return;
      }
      switch (resolution.entry) {
        case FirstRunEntry.consent:
          Navigator.of(context).pushReplacementNamed('/splash');
          return;
        case FirstRunEntry.gate:
          _replace(IntroGateScreen(firstRunCoordinator: _coordinator));
          return;
        case FirstRunEntry.appShell:
          _replace(AppShell(firstRunCoordinator: _coordinator));
          return;
        case FirstRunEntry.story:
        case FirstRunEntry.setup:
        case FirstRunEntry.companion:
        case FirstRunEntry.confirmation:
        case FirstRunEntry.committing:
          final journeyState = resolution.state;
          if (journeyState == null) {
            throw StateError(
              'Onboarding entry ${resolution.entry.name} requires journey state.',
            );
          }
          _applyState(journeyState);
          if (resolution.entry == FirstRunEntry.committing) {
            unawaited(_commitAndOpenGate());
          }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
      }
    }
  }

  void _replace(Widget screen) {
    _recordStoryExit(OnboardingStoryExit.dropped);
    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.firstRun(context, (_) => screen));
  }

  void _applyState(
    OnboardingJourneyState next, {
    OnboardingStoryExit? storyExit,
  }) {
    final previous = _state;
    final leftObservedStory =
        previous?.phase == OnboardingPhase.story &&
        (next.phase != OnboardingPhase.story ||
            next.storyPage != previous?.storyPage);
    if (leftObservedStory) {
      _recordStoryExit(storyExit ?? OnboardingStoryExit.dropped);
    }
    setState(() => _state = next);
    if (next.phase == OnboardingPhase.story &&
        _observedStoryPage != next.storyPage) {
      _observedStoryPage = next.storyPage;
      _storyStopwatch = Stopwatch()..start();
      unawaited(Analytics.onboardingStoryReached(next.storyPage));
    }
  }

  void _recordStoryExit(OnboardingStoryExit exit) {
    final page = _observedStoryPage;
    final stopwatch = _storyStopwatch;
    if (page == null || stopwatch == null) {
      return;
    }
    stopwatch.stop();
    _observedStoryPage = null;
    _storyStopwatch = null;
    unawaited(
      Analytics.onboardingStoryDwell(
        page: page,
        duration: stopwatch.elapsed,
        exit: exit,
      ),
    );
  }

  void _recordJourneyDuration() {
    if (_journeyDurationRecorded) {
      return;
    }
    _journeyDurationRecorded = true;
    _journeyStopwatch.stop();
    unawaited(
      Analytics.onboardingTotalDuration(
        duration: _journeyStopwatch.elapsed,
        flow: _coordinator.usesMinimalSafeFlow
            ? OnboardingFlowVariant.minimalSafe
            : OnboardingFlowVariant.full,
      ),
    );
  }

  Future<void> _updateDraft(
    Future<OnboardingJourneyState> Function() action, {
    VoidCallback? onSaved,
    VoidCallback? onFinished,
  }) async {
    try {
      final next = await action();
      onSaved?.call();
      if (mounted) {
        _applyState(next);
      }
    } catch (_) {
      _showSaveError();
    } finally {
      onFinished?.call();
    }
  }

  Future<void> _runTransition(
    Future<OnboardingJourneyState> Function() action, {
    OnboardingStoryExit? storyExit,
  }) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final next = await action();
      if (mounted) {
        _applyState(next, storyExit: storyExit);
      }
    } catch (_) {
      _showSaveError();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _commitAndOpenGate() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final next = await _coordinator.commit();
      if (!mounted) {
        return;
      }
      _applyState(next);
      _recordJourneyDuration();
      if (next.phase == OnboardingPhase.complete) {
        _replace(AppShell(firstRunCoordinator: _coordinator));
      } else {
        _replace(IntroGateScreen(firstRunCoordinator: _coordinator));
      }
    } on OnboardingPlacementHistoryConflictException {
      _showPlacementHistoryConflict();
      await _load();
    } catch (_) {
      _showSaveError();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _commitMinimalFromCompanion() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final next = await _coordinator.commitFromCompanionMinimal();
      if (!mounted) {
        return;
      }
      _applyState(next);
      _recordJourneyDuration();
      _replace(AppShell(firstRunCoordinator: _coordinator));
    } on OnboardingPlacementHistoryConflictException {
      _showPlacementHistoryConflict();
      await _load();
    } catch (_) {
      _showSaveError();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSaveError() {
    if (!mounted) {
      return;
    }
    soriToast(context, AppL10n.of(context).loadErrorTryAgain);
  }

  void _showPlacementHistoryConflict() {
    if (!mounted) {
      return;
    }
    soriToast(context, AppL10n.of(context).onboardingV2CourseHistoryConflict);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final state = _state;
    if (_loadError != null) {
      return _LoadFailure(onRetry: _load);
    }
    if (state == null) {
      return _OnboardingLoading(message: t.onboardingV2Loading);
    }

    final copy = onboardingV2Copy(t);
    final content = switch (state.phase) {
      OnboardingPhase.story => OnboardingStoryScreen(
        copy: copy,
        pageIndex: state.storyPage.index,
        onContinue: (id) {
          final page = _storyPageForId(id);
          unawaited(
            _runTransition(
              () => _coordinator.completeStoryPage(page),
              storyExit: OnboardingStoryExit.continued,
            ),
          );
        },
        onPrevious: (_) {
          unawaited(
            _runTransition(
              _coordinator.previousStoryPage,
              storyExit: OnboardingStoryExit.previous,
            ),
          );
        },
      ),
      OnboardingPhase.setup => OnboardingSetupScreen(
        copy: copy,
        selectedPurposeId: _purposeId(state.purposeDraft),
        selectedLevelCode: state.levelDraft?.display,
        onPurposeChanged: (id) {
          final purpose = _purposeForId(id);
          if (purpose == state.purposeDraft || !_pendingPurposes.add(purpose)) {
            return;
          }
          unawaited(
            _updateDraft(
              () => _coordinator.savePurposeDraft(purpose),
              onSaved: () =>
                  unawaited(Analytics.onboardingPurposeSelectedV2(purpose)),
              onFinished: () => _pendingPurposes.remove(purpose),
            ),
          );
        },
        onLevelChanged: (code) {
          final level = LearnerLevel.fromCode(code);
          if (level == null ||
              level == state.levelDraft ||
              !_pendingLevels.add(level)) {
            return;
          }
          unawaited(
            _updateDraft(
              () => _coordinator.saveLevelDraft(level),
              onSaved: () =>
                  unawaited(Analytics.onboardingLevelSelectedV2(level)),
              onFinished: () => _pendingLevels.remove(level),
            ),
          );
        },
        onContinue: (_) {
          unawaited(_runTransition(_coordinator.continueFromSetup));
        },
        onBack: () {
          unawaited(
            _runTransition(
              _coordinator.returnToStoryFromSetup,
              storyExit: OnboardingStoryExit.previous,
            ),
          );
        },
      ),
      OnboardingPhase.companion => OnboardingCompanionScreen(
        copy: copy,
        selectedCompanionId: _companionId(state.companionDraft),
        onCompanionChanged: (id) {
          final companion = _companionForId(id);
          if (companion == state.companionDraft ||
              !_pendingCompanions.add(companion)) {
            return;
          }
          unawaited(
            _updateDraft(
              () => _coordinator.saveCompanionDraft(companion),
              onSaved: () =>
                  unawaited(Analytics.onboardingCompanionSelectedV2(companion)),
              onFinished: () => _pendingCompanions.remove(companion),
            ),
          );
        },
        onContinue: (_) {
          if (_coordinator.usesMinimalSafeFlow) {
            unawaited(_commitMinimalFromCompanion());
          } else {
            unawaited(_runTransition(_coordinator.continueFromCompanion));
          }
        },
        onBack: () => unawaited(_runTransition(_coordinator.returnToSetup)),
      ),
      OnboardingPhase.confirmation ||
      OnboardingPhase.committing => OnboardingCompanionConfirmationScreen(
        copy: copy,
        companionId: _companionId(state.companionDraft)!,
        previewBuilder: _buildCompanionPreview,
        onStart: () => unawaited(_commitAndOpenGate()),
        onChange: () =>
            unawaited(_runTransition(_coordinator.returnToCompanion)),
      ),
      OnboardingPhase.gate => _OnboardingLoading(
        message: t.onboardingV2Loading,
      ),
      OnboardingPhase.complete => AppShell(firstRunCoordinator: _coordinator),
    };

    return Stack(
      children: [
        AbsorbPointer(absorbing: _busy, child: content),
        if (_busy)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Semantics(
                container: true,
                liveRegion: true,
                label: t.onboardingV2Saving,
                child: const ExcludeSemantics(
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompanionPreview(BuildContext context, String companionId) {
    final kind = companionId == OnboardingV2Ids.companionJoy
        ? MascotKind.magpie
        : MascotKind.tiger;
    return Center(
      child: CharacterClipPlayer(
        asset: CharacterClips.chooseFor(kind),
        size: 260,
        fallbackKind: kind,
        fallbackEmotion: MascotEmotion.smile,
        loop: false,
        staticFallback: true,
        onFailure: (reason) => unawaited(
          _coordinator.recordCompanionPreviewFailure(switch (reason) {
            CharacterClipFailureReason.initialization =>
              OnboardingCompanionPreviewFailure.initialization,
            CharacterClipFailureReason.playback =>
              OnboardingCompanionPreviewFailure.playback,
          }),
        ),
      ),
    );
  }
}

class _OnboardingLoading extends StatelessWidget {
  const _OnboardingLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Semantics(
          container: true,
          liveRegion: true,
          label: message,
          child: ExcludeSemantics(child: AppLoading(message: message)),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return OnboardingV2PageShell(
      brandLatin: t.onboardingV2BrandLatin,
      brandKorean: t.onboardingV2BrandKorean,
      bodyKey: const ValueKey('onboarding-v2-load-failure-scroll'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.sync_problem_rounded,
                size: 56,
                color: SoriColors.accent,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Focus(
              debugLabel: 'onboarding-v2-load-error-heading',
              autofocus: true,
              child: Semantics(
                key: const ValueKey('onboarding-v2-load-error'),
                container: true,
                header: true,
                liveRegion: true,
                focusable: true,
                label: t.loadErrorTryAgain,
                excludeSemantics: true,
                child: Text(
                  t.loadErrorTryAgain,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).body,
                ),
              ),
            ),
          ],
        ),
      ),
      footer: SoriButton.filled(
        key: const ValueKey('onboarding-v2-load-retry'),
        label: t.btnRetry,
        fullWidth: true,
        onTap: () => unawaited(onRetry()),
      ),
    );
  }
}

StoryPageId _storyPageForId(String id) => switch (id) {
  OnboardingV2Ids.storyPersonalCurriculum => StoryPageId.personalCurriculum,
  OnboardingV2Ids.storyLearn => StoryPageId.learn,
  OnboardingV2Ids.storySaveAndReview => StoryPageId.saveAndReview,
  OnboardingV2Ids.storyGamesAndRewards => StoryPageId.gamesAndRewards,
  OnboardingV2Ids.storyHeritageJourney => StoryPageId.heritageJourney,
  _ => throw ArgumentError.value(id, 'id', 'Unknown story page'),
};

OnboardingPurpose _purposeForId(String id) => switch (id) {
  OnboardingV2Ids.purposeLifeTravel => OnboardingPurpose.dailyTravel,
  OnboardingV2Ids.purposePeopleCulture => OnboardingPurpose.peopleCulture,
  OnboardingV2Ids.purposeStudyWork => OnboardingPurpose.studyWork,
  OnboardingV2Ids.purposeKContent => OnboardingPurpose.kContent,
  _ => throw ArgumentError.value(id, 'id', 'Unknown onboarding purpose'),
};

String? _purposeId(OnboardingPurpose? purpose) => switch (purpose) {
  OnboardingPurpose.dailyTravel => OnboardingV2Ids.purposeLifeTravel,
  OnboardingPurpose.peopleCulture => OnboardingV2Ids.purposePeopleCulture,
  OnboardingPurpose.studyWork => OnboardingV2Ids.purposeStudyWork,
  OnboardingPurpose.kContent => OnboardingV2Ids.purposeKContent,
  null => null,
};

OnboardingCompanion _companionForId(String id) => switch (id) {
  OnboardingV2Ids.companionTaego => OnboardingCompanion.taego,
  OnboardingV2Ids.companionJoy => OnboardingCompanion.joy,
  _ => throw ArgumentError.value(id, 'id', 'Unknown onboarding companion'),
};

String? _companionId(OnboardingCompanion? companion) => switch (companion) {
  OnboardingCompanion.taego => OnboardingV2Ids.companionTaego,
  OnboardingCompanion.joy => OnboardingV2Ids.companionJoy,
  null => null,
};
