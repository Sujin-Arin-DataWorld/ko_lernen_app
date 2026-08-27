import '../../models/learner_level.dart';
import '../../services/local_data_lifetime.dart';
import 'onboarding_journey_repository.dart';
import 'onboarding_journey_state.dart';

export 'onboarding_journey_state.dart' show OnboardingRolloutMode;

enum FirstRunEntry {
  consent,
  story,
  setup,
  companion,
  confirmation,
  committing,
  gate,
  appShell,
}

class FirstRunResolution {
  const FirstRunResolution({
    required this.entry,
    required this.state,
    required this.migratedLegacyState,
  });

  final FirstRunEntry entry;
  final OnboardingJourneyState? state;
  final bool migratedLegacyState;
}

/// Read-only snapshot of the pre-V2 first-run keys.
class LegacyOnboardingSnapshot {
  const LegacyOnboardingSnapshot({
    required this.consentAccepted,
    required this.hasCompletedOnboarding,
    this.userLevel,
    this.purpose,
    this.companion,
  });

  final bool consentAccepted;
  final bool hasCompletedOnboarding;
  final LearnerLevel? userLevel;
  final OnboardingPurpose? purpose;
  final OnboardingCompanion? companion;
}

abstract interface class LegacyOnboardingStateReader {
  Future<LegacyOnboardingSnapshot> read();
}

class OnboardingPlacementSnapshot {
  const OnboardingPlacementSnapshot({
    required this.placementLevel,
    required this.browseLevel,
    this.canonicalPlacementLevel,
    this.courseGeneration,
    this.hasCourseHistory = false,
  });

  /// Placement encoded by the validated canonical course graph, even when a
  /// torn multi-key write left one of its scalar mirrors stale or absent.
  ///
  /// [placementLevel] remains the stricter transaction verification result:
  /// it is non-null only when the canonical graph and every required mirror
  /// agree. The coordinator uses this value solely to distinguish a safe
  /// same-placement mirror repair from a real course-history conflict.
  final LearnerLevel? canonicalPlacementLevel;
  final LearnerLevel? placementLevel;
  final LearnerLevel? browseLevel;

  /// Raw canonical generation captured with the placement read. `''` means
  /// the graph was absent; null is reserved for lightweight legacy gateways
  /// that cannot provide an optimistic write fence.
  final String? courseGeneration;

  /// True only for earned course history, not placement-created bypasses.
  /// Onboarding must not silently rewrite such a graph; Settings owns the
  /// explicit, warned course-restart flow.
  final bool hasCourseHistory;
}

/// All durable compatibility fields that make a companion selection complete.
///
/// Reading only the selected identity is insufficient: a process can stop
/// after that first write but before visibility and the legacy mirror are
/// updated. [matches] deliberately fails closed for that partial state.
class OnboardingCompanionCommitSnapshot {
  const OnboardingCompanionCommitSnapshot({
    required this.companion,
    required this.identityExplicitlyStored,
    required this.visible,
    required this.legacyMirror,
  });

  final OnboardingCompanion? companion;
  final bool identityExplicitlyStored;
  final bool visible;
  final OnboardingCompanion? legacyMirror;

  bool matches(OnboardingCompanion expected) =>
      identityExplicitlyStored &&
      companion == expected &&
      visible &&
      legacyMirror == expected;
}

/// Optional stronger read contract for gateways with split companion storage.
///
/// Older test and embedding gateways can continue implementing the original
/// single-field API. Production implements this capability and is therefore
/// verified against every durable companion field.
abstract interface class OnboardingCompanionCommitSnapshotReader {
  Future<OnboardingCompanionCommitSnapshot> readCompanionCommitSnapshot();
}

/// Side-effect boundary used by the durable commit journal.
///
/// Each write has a matching read so the coordinator can skip an action that
/// completed before a crash but whose journal advance did not persist.
abstract interface class OnboardingCommitGateway {
  Future<bool> hasConsent();

  Future<OnboardingPurpose?> readPurpose();

  Future<void> savePurpose(OnboardingPurpose purpose);

  Future<OnboardingPlacementSnapshot> readPlacement();

  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  });

  Future<void> synchronizeBrowseLevel(LearnerLevel level);

  Future<OnboardingCompanion?> readCompanion();

  Future<void> saveCompanion(OnboardingCompanion companion);

  Future<bool> isLegacyOnboardingComplete();

  Future<void> markLegacyOnboardingComplete();
}

/// Analytics stays outside the commit transaction. The first normal AppShell
/// frame calls this sink with no user text, answer, book, or recording data.
abstract interface class OnboardingCompletionEventSink {
  /// Whether privacy and age gates allow this one-shot marker to be consumed.
  bool get canRecordOnboardingCompleted;

  Future<void> recordOnboardingCompleted(OnboardingJourneyState state);
}

class NoopOnboardingCompletionEventSink
    implements OnboardingCompletionEventSink {
  const NoopOnboardingCompletionEventSink();

  @override
  bool get canRecordOnboardingCompleted => false;

  @override
  Future<void> recordOnboardingCompleted(OnboardingJourneyState state) async {}
}

/// Best-effort events emitted while the V2 journey is still active.
///
/// The coordinator owns the durable start marker, while this sink owns only
/// delivery. Preview failures are already reduced to a closed enum before
/// reaching the sink, so decoder errors and asset paths cannot leak.
abstract interface class OnboardingJourneyEventSink {
  bool get canRecordOnboardingStarted;

  Future<void> recordOnboardingStarted();

  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  );
}

class NoopOnboardingJourneyEventSink implements OnboardingJourneyEventSink {
  const NoopOnboardingJourneyEventSink();

  @override
  bool get canRecordOnboardingStarted => false;

  @override
  Future<void> recordOnboardingStarted() async {}

  @override
  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  ) async {}
}

class OnboardingCommitVerificationException implements Exception {
  const OnboardingCommitVerificationException(this.step);

  final String step;

  @override
  String toString() => 'Onboarding commit verification failed at $step.';
}

class OnboardingPlacementHistoryConflictException implements Exception {
  const OnboardingPlacementHistoryConflictException();

  @override
  String toString() =>
      'Existing course history requires an explicit Settings restart.';
}

/// Coordinates every durable transition in onboarding V2.
///
/// UI code asks this class for a single entry decision and never derives
/// first-run routing from `sessionCount`, `introSeen`, or a selected level.
class FirstRunCoordinator {
  factory FirstRunCoordinator({
    required OnboardingJourneyRepository repository,
    required LegacyOnboardingStateReader legacyStateReader,
    required OnboardingCommitGateway commitGateway,
    OnboardingCompletionEventSink eventSink =
        const NoopOnboardingCompletionEventSink(),
    OnboardingJourneyEventSink journeyEventSink =
        const NoopOnboardingJourneyEventSink(),
    OnboardingRolloutMode Function()? rolloutModeReader,
    DateTime Function()? clock,
  }) {
    return FirstRunCoordinator._(
      repository,
      legacyStateReader,
      commitGateway,
      eventSink,
      journeyEventSink,
      rolloutModeReader ?? () => OnboardingRolloutMode.full,
      clock ?? DateTime.now,
    );
  }

  FirstRunCoordinator._(
    this._repository,
    this._legacyStateReader,
    this._commitGateway,
    this._eventSink,
    this._journeyEventSink,
    this._rolloutModeReader,
    this._clock,
  );

  final OnboardingJourneyRepository _repository;
  final LegacyOnboardingStateReader _legacyStateReader;
  final OnboardingCommitGateway _commitGateway;
  final OnboardingCompletionEventSink _eventSink;
  final OnboardingJourneyEventSink _journeyEventSink;
  final OnboardingRolloutMode Function() _rolloutModeReader;
  final DateTime Function() _clock;
  OnboardingRolloutMode? _latchedRolloutMode;

  bool get usesMinimalSafeFlow =>
      (_latchedRolloutMode ?? _rolloutModeReader()) ==
      OnboardingRolloutMode.minimalSafe;

  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final scheduled = _tail.then((_) => action());
    _tail = scheduled.then<void>((_) {}, onError: (_, __) {});
    return scheduled;
  }

  Future<OnboardingJourneyState?> loadState() {
    return _serialized(() async {
      final state = await _repository.load();
      if (state != null) {
        _latchedRolloutMode = state.rolloutMode;
      }
      return state;
    });
  }

  Future<FirstRunResolution> resolveEntry() {
    return _serialized(_resolveEntry);
  }

  Future<FirstRunResolution> _resolveEntry() async {
    final legacy = await _legacyStateReader.read();
    final existing = await _repository.load();

    if (existing != null) {
      _latchedRolloutMode = existing.rolloutMode;
    }

    if (!legacy.consentAccepted) {
      return FirstRunResolution(
        entry: FirstRunEntry.consent,
        state: existing,
        migratedLegacyState: false,
      );
    }

    var state = existing;
    var migrated = false;
    if (state == null) {
      if (legacy.hasCompletedOnboarding) {
        migrated = true;
        state = OnboardingJourneyState.legacyCompleted(
          now: _now(),
          purpose: legacy.purpose,
          level: legacy.userLevel,
          companion: legacy.companion,
        );
      } else {
        // `kl_user_level` historically served account/library browsing and can
        // disagree with a real sequential-course graph. Prefer the validated
        // graph so a partial-onboarding repair does not default to a destructive
        // re-placement. The learner still has to confirm or change this draft.
        final existingPlacement = await _commitGateway.readPlacement();
        final restoredLevel =
            existingPlacement.placementLevel ??
            existingPlacement.canonicalPlacementLevel ??
            legacy.userLevel;
        migrated = restoredLevel != null;
        final rolloutMode = _rolloutModeReader();
        state = OnboardingJourneyState.initial(_now(), rolloutMode: rolloutMode)
            .copyWith(
              phase: restoredLevel == null
                  ? OnboardingPhase.story
                  : OnboardingPhase.setup,
              purposeDraft: legacy.purpose,
              levelDraft: restoredLevel,
              companionDraft: legacy.companion,
              // A restored course/account level means this is an existing
              // learner repairing partial state, not a true fresh V2 journey.
              startEventSent: restoredLevel != null,
              updatedAt: _now(),
            );
      }
      _latchedRolloutMode = state.rolloutMode;
      await _repository.save(state);
    }

    // The gate is consumed when playback begins, not when a decoder reports
    // completion. A process death during video must therefore resume at home.
    if (state.phase == OnboardingPhase.gate &&
        state.gateIntroAttempted &&
        !state.gateIntroConsumed) {
      state = state.copyWith(
        phase: OnboardingPhase.complete,
        gateIntroConsumed: true,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    if (state.rolloutMode == OnboardingRolloutMode.minimalSafe) {
      if (state.phase == OnboardingPhase.story) {
        state = state.copyWith(
          phase: OnboardingPhase.setup,
          storyPage: StoryPageId.heritageJourney,
          updatedAt: _now(),
        );
        await _repository.save(state);
      } else if (state.phase == OnboardingPhase.confirmation) {
        // The full-flow final CTA has not been pressed yet. Return to the
        // companion CTA instead of auto-committing an unconfirmed draft.
        state = state.copyWith(
          phase: OnboardingPhase.companion,
          commitStage: OnboardingCommitStage.none,
          updatedAt: _now(),
        );
        await _repository.save(state);
      } else if (state.phase == OnboardingPhase.gate) {
        state = state.copyWith(
          phase: OnboardingPhase.complete,
          gateIntroAttempted: true,
          gateIntroConsumed: true,
          updatedAt: _now(),
        );
        await _repository.save(state);
      }
    }

    state = await _recordOnboardingStartedIfEligible(state);

    return FirstRunResolution(
      entry: _entryFor(state.phase),
      state: state,
      migratedLegacyState: migrated,
    );
  }

  Future<OnboardingJourneyState> completeStoryPage(StoryPageId page) {
    return _serialized(() async {
      final state = await _requireState();
      if (state.phase != OnboardingPhase.story) {
        if (page == StoryPageId.heritageJourney &&
            state.phase.index > OnboardingPhase.story.index) {
          return state;
        }
        throw StateError('Story pages are not active.');
      }

      if (page.index < state.storyPage.index) {
        return state;
      }
      if (page != state.storyPage) {
        throw StateError('Story pages must be completed in order.');
      }

      final isLast = page == StoryPageId.heritageJourney;
      final next = state.copyWith(
        phase: isLast ? OnboardingPhase.setup : OnboardingPhase.story,
        storyPage: isLast ? page : StoryPageId.values[page.index + 1],
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> previousStoryPage() {
    return _serialized(() async {
      final state = await _requireState();
      if (state.phase != OnboardingPhase.story || state.storyPage.index == 0) {
        return state;
      }
      final next = state.copyWith(
        storyPage: StoryPageId.values[state.storyPage.index - 1],
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> savePurposeDraft(OnboardingPurpose purpose) {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.setup);
      if (state.purposeDraft == purpose) {
        return state;
      }
      final next = state.copyWith(purposeDraft: purpose, updatedAt: _now());
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> saveLevelDraft(LearnerLevel level) {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.setup);
      if (state.levelDraft == level) {
        return state;
      }
      final next = state.copyWith(levelDraft: level, updatedAt: _now());
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> continueFromSetup() {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.setup);
      if (!state.hasCompleteSetup) {
        throw StateError('Purpose and level are both required.');
      }
      final next = state.copyWith(
        phase: OnboardingPhase.companion,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  /// Reopens the final explanatory page without discarding setup drafts.
  ///
  /// The seven-step presentation exposes a real Back action on step six. The
  /// purpose and level remain drafts only, so returning to the story never
  /// changes course placement, mastery, rewards, or legacy completion state.
  Future<OnboardingJourneyState> returnToStoryFromSetup() {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.setup);
      final next = state.copyWith(
        phase: OnboardingPhase.story,
        storyPage: StoryPageId.heritageJourney,
        commitStage: OnboardingCommitStage.none,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> saveCompanionDraft(
    OnboardingCompanion companion,
  ) {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.companion);
      if (state.companionDraft == companion) {
        return state;
      }
      final next = state.copyWith(companionDraft: companion, updatedAt: _now());
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> continueFromCompanion() {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.companion);
      if (state.companionDraft == null) {
        throw StateError('A companion is required.');
      }
      final next = state.copyWith(
        phase: OnboardingPhase.confirmation,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> returnToSetup() {
    return _serialized(() async {
      final state = await _requireState();
      if (state.phase != OnboardingPhase.companion &&
          state.phase != OnboardingPhase.confirmation) {
        throw StateError('Setup cannot be reopened from ${state.phase.name}.');
      }
      final next = state.copyWith(
        phase: OnboardingPhase.setup,
        commitStage: OnboardingCommitStage.none,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> returnToCompanion() {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.confirmation);
      final next = state.copyWith(
        phase: OnboardingPhase.companion,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  /// Kill-switch final CTA. This keeps the same verified, idempotent commit
  /// journal while omitting confirmation media and the decorative gate.
  Future<OnboardingJourneyState> commitFromCompanionMinimal() {
    return _serialized(() async {
      final state = await _requirePhase(OnboardingPhase.companion);
      if (state.rolloutMode != OnboardingRolloutMode.minimalSafe) {
        throw StateError('The minimal-safe rollout is not active.');
      }
      if (state.companionDraft == null) {
        throw StateError('A companion is required.');
      }
      return _commit(allowMinimalCompanion: true);
    });
  }

  Future<OnboardingJourneyState> commit() {
    return _serialized(_commit);
  }

  Future<OnboardingJourneyState> _commit({
    bool allowMinimalCompanion = false,
  }) async {
    var state = await _requireState();
    if (state.phase == OnboardingPhase.gate ||
        state.phase == OnboardingPhase.complete) {
      return state;
    }
    final isMinimalCompanion =
        allowMinimalCompanion &&
        state.rolloutMode == OnboardingRolloutMode.minimalSafe &&
        state.phase == OnboardingPhase.companion;
    if (state.phase != OnboardingPhase.confirmation &&
        state.phase != OnboardingPhase.committing &&
        !isMinimalCompanion) {
      throw StateError('Onboarding is not ready to commit.');
    }
    if (!state.canCommit) {
      throw StateError('Onboarding drafts are incomplete.');
    }
    if (!await _commitGateway.hasConsent()) {
      throw StateError('Onboarding commit requires current consent.');
    }

    // Preflight before persisting `committing`, including a resumed journal
    // that had already marked placement as verified. A durable journal stage
    // is not proof that course state stayed unchanged while the app was away.
    // Earned history requires Settings' explicit restart confirmation when the
    // selected start differs; safe mirror/browse drift rewinds to the last
    // verified prerequisite and runs placement verification again.
    var placementBeforeCommit = await _commitGateway.readPlacement();
    final desiredLevel = state.levelDraft!;
    final historicalPlacement =
        placementBeforeCommit.canonicalPlacementLevel ??
        placementBeforeCommit.placementLevel;
    if (historicalPlacement != desiredLevel &&
        placementBeforeCommit.hasCourseHistory) {
      state = state.copyWith(
        phase: OnboardingPhase.setup,
        commitStage: OnboardingCommitStage.none,
        updatedAt: _now(),
      );
      await _repository.save(state);
      throw const OnboardingPlacementHistoryConflictException();
    }
    if (state.commitStage.index >=
            OnboardingCommitStage.placementVerified.index &&
        (placementBeforeCommit.placementLevel != desiredLevel ||
            placementBeforeCommit.browseLevel != desiredLevel)) {
      state = state.copyWith(
        commitStage: OnboardingCommitStage.motivationSaved,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    if (state.phase != OnboardingPhase.committing) {
      state = state.copyWith(
        phase: OnboardingPhase.committing,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    final purpose = state.purposeDraft!;
    if (state.commitStage.index < OnboardingCommitStage.motivationSaved.index) {
      if (await _commitGateway.readPurpose() != purpose) {
        await _commitGateway.savePurpose(purpose);
      }
      if (await _commitGateway.readPurpose() != purpose) {
        throw const OnboardingCommitVerificationException('purpose');
      }
      state = state.copyWith(
        commitStage: OnboardingCommitStage.motivationSaved,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    final level = state.levelDraft!;
    if (state.commitStage.index <
        OnboardingCommitStage.placementVerified.index) {
      var placement = placementBeforeCommit;
      if (placement.placementLevel != level) {
        await _commitGateway.initializePlacement(
          level,
          expectedGeneration: placement.courseGeneration,
        );
      }
      placement = await _commitGateway.readPlacement();
      if (placement.placementLevel != level) {
        throw const OnboardingCommitVerificationException('placement');
      }
      if (placement.browseLevel != level) {
        await _commitGateway.synchronizeBrowseLevel(level);
      }
      placement = await _commitGateway.readPlacement();
      if (placement.placementLevel != level || placement.browseLevel != level) {
        throw const OnboardingCommitVerificationException('browseLevel');
      }
      state = state.copyWith(
        commitStage: OnboardingCommitStage.placementVerified,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    final companion = state.companionDraft!;
    if (state.commitStage.index < OnboardingCommitStage.companionSaved.index) {
      var companionSnapshot = await _readCompanionCommitSnapshot();
      if (!companionSnapshot.matches(companion)) {
        await _commitGateway.saveCompanion(companion);
      }
      companionSnapshot = await _readCompanionCommitSnapshot();
      if (!companionSnapshot.matches(companion)) {
        throw const OnboardingCommitVerificationException('companion');
      }
      state = state.copyWith(
        commitStage: OnboardingCommitStage.companionSaved,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    if (state.commitStage.index < OnboardingCommitStage.completed.index) {
      if (!await _commitGateway.isLegacyOnboardingComplete()) {
        await _commitGateway.markLegacyOnboardingComplete();
      }
      if (!await _commitGateway.isLegacyOnboardingComplete()) {
        throw const OnboardingCommitVerificationException('completion');
      }
      final minimalSafe =
          state.rolloutMode == OnboardingRolloutMode.minimalSafe;
      state = state.copyWith(
        phase: minimalSafe ? OnboardingPhase.complete : OnboardingPhase.gate,
        commitStage: OnboardingCommitStage.completed,
        gateIntroAttempted: minimalSafe,
        gateIntroConsumed: minimalSafe,
        updatedAt: _now(),
      );
      await _repository.save(state);
    }

    return state;
  }

  Future<OnboardingJourneyState> markGateAttempted() {
    return _serialized(() async {
      final state = await _requireState();
      if (state.phase == OnboardingPhase.complete || state.gateIntroAttempted) {
        return state;
      }
      if (state.phase != OnboardingPhase.gate) {
        throw StateError('The intro gate is not active.');
      }
      final next = state.copyWith(gateIntroAttempted: true, updatedAt: _now());
      await _repository.save(next);
      return next;
    });
  }

  Future<OnboardingJourneyState> consumeGate() {
    return _serialized(() async {
      final state = await _requireState();
      if (state.phase == OnboardingPhase.complete) {
        return state;
      }
      if (state.phase != OnboardingPhase.gate) {
        throw StateError('The intro gate is not active.');
      }
      final next = state.copyWith(
        phase: OnboardingPhase.complete,
        gateIntroAttempted: true,
        gateIntroConsumed: true,
        updatedAt: _now(),
      );
      await _repository.save(next);
      return next;
    });
  }

  /// Leaves the marker untouched until analytics is permitted, then marks it
  /// before dispatch to provide durable at-most-once semantics. Analytics
  /// failure must never re-open or block onboarding.
  Future<OnboardingJourneyState> recordAppShellFirstFrame() {
    // Capture before entering the coordinator queue. A reset while this
    // callback is queued or loading must invalidate the whole operation.
    final localLifetime = LocalDataLifetime.capture();
    return _serialized(() async {
      localLifetime.assertCurrent();
      final state = await _requirePhase(OnboardingPhase.complete);
      localLifetime.assertCurrent();
      if (state.shellEntryEventSent ||
          !_eventSink.canRecordOnboardingCompleted) {
        return state;
      }
      final next = state.copyWith(shellEntryEventSent: true, updatedAt: _now());
      await _repository.save(
        next,
        assertCurrentWrite: localLifetime.assertCurrent,
      );
      localLifetime.assertCurrent();
      try {
        await _eventSink.recordOnboardingCompleted(state);
      } catch (_) {
        // Analytics is best effort. The durable at-most-once marker prevents
        // a telemetry failure from affecting navigation or causing retries.
      }
      return next;
    });
  }

  /// Reports an explicit decoder failure without exposing the decoder error
  /// or blocking the always-available confirmation CTA.
  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  ) async {
    try {
      await _journeyEventSink.recordCompanionPreviewFailure(failure);
    } catch (_) {
      // Decorative media telemetry is always best effort.
    }
  }

  /// Marks before dispatch for durable at-most-once delivery. Old-schema and
  /// legacy-user states migrate with the marker already consumed, so only a
  /// state created as a true fresh V2 journey can reach this boundary.
  Future<OnboardingJourneyState> _recordOnboardingStartedIfEligible(
    OnboardingJourneyState state,
  ) async {
    if (state.startEventSent ||
        state.phase == OnboardingPhase.complete ||
        !_journeyEventSink.canRecordOnboardingStarted) {
      return state;
    }

    final next = state.copyWith(startEventSent: true, updatedAt: _now());
    await _repository.save(next);
    try {
      await _journeyEventSink.recordOnboardingStarted();
    } catch (_) {
      // Analytics cannot delay or reopen first-run navigation. The durable
      // marker intentionally remains consumed after a delivery failure.
    }
    return next;
  }

  Future<OnboardingJourneyState> _requireState() async {
    final state = await _repository.load();
    if (state == null) {
      throw StateError('Onboarding journey has not been resolved.');
    }
    _latchedRolloutMode = state.rolloutMode;
    return state;
  }

  Future<OnboardingCompanionCommitSnapshot>
  _readCompanionCommitSnapshot() async {
    final gateway = _commitGateway;
    if (gateway case final OnboardingCompanionCommitSnapshotReader reader) {
      return reader.readCompanionCommitSnapshot();
    }

    // Compatibility for lightweight embedding/test gateways that still own a
    // single atomic companion value. Production never uses this fallback.
    final companion = await gateway.readCompanion();
    return OnboardingCompanionCommitSnapshot(
      companion: companion,
      identityExplicitlyStored: companion != null,
      visible: companion != null,
      legacyMirror: companion,
    );
  }

  Future<OnboardingJourneyState> _requirePhase(OnboardingPhase phase) async {
    final state = await _requireState();
    if (state.phase != phase) {
      throw StateError(
        'Expected onboarding phase ${phase.name}, found ${state.phase.name}.',
      );
    }
    return state;
  }

  DateTime _now() => _clock().toUtc();

  static FirstRunEntry _entryFor(OnboardingPhase phase) {
    return switch (phase) {
      OnboardingPhase.story => FirstRunEntry.story,
      OnboardingPhase.setup => FirstRunEntry.setup,
      OnboardingPhase.companion => FirstRunEntry.companion,
      OnboardingPhase.confirmation => FirstRunEntry.confirmation,
      OnboardingPhase.committing => FirstRunEntry.committing,
      OnboardingPhase.gate => FirstRunEntry.gate,
      OnboardingPhase.complete => FirstRunEntry.appShell,
    };
  }
}
