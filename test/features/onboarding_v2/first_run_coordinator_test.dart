import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 8, 26, 12);

  FirstRunCoordinator coordinator({
    required OnboardingJourneyRepository repository,
    required _LegacyReader legacy,
    required _CommitGateway gateway,
    _EventSink? events,
    _JourneyEventSink? journeyEvents,
    OnboardingRolloutMode rolloutMode = OnboardingRolloutMode.full,
    OnboardingRolloutMode Function()? rolloutModeReader,
  }) {
    return FirstRunCoordinator(
      repository: repository,
      legacyStateReader: legacy,
      commitGateway: gateway,
      eventSink: events ?? _EventSink(),
      journeyEventSink: journeyEvents ?? _JourneyEventSink(),
      rolloutModeReader: rolloutModeReader ?? () => rolloutMode,
      clock: () => now,
    );
  }

  test('persists the exact mandatory story page and resumes there', () async {
    final repository = _MemoryJourneyRepository();
    final legacy = _LegacyReader(
      const LegacyOnboardingSnapshot(
        consentAccepted: true,
        hasCompletedOnboarding: false,
      ),
    );
    final gateway = _CommitGateway();
    final first = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
    );

    expect((await first.resolveEntry()).entry, FirstRunEntry.story);
    await first.completeStoryPage(StoryPageId.personalCurriculum);
    await first.completeStoryPage(StoryPageId.learn);

    final relaunched = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
    );
    final resolution = await relaunched.resolveEntry();

    expect(resolution.entry, FirstRunEntry.story);
    expect(resolution.state!.storyPage, StoryPageId.saveAndReview);
    expect(resolution.state!.purposeDraft, isNull);
    expect(resolution.state!.levelDraft, isNull);
  });

  test(
    'a current journal without rollout authority restarts the full story',
    () async {
      const raw =
          '{"schemaVersion":4,"phase":"story",'
          '"storyPage":"saveAndReview"}';
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey: raw,
      });
      addTearDown(() => SharedPreferences.setMockInitialValues({}));
      final repository = SharedPreferencesOnboardingJourneyRepository();
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
      );

      final resolution = await instance.resolveEntry();

      expect(resolution.entry, FirstRunEntry.story);
      expect(resolution.state!.storyPage, StoryPageId.personalCurriculum);
      expect(resolution.state!.rolloutMode, OnboardingRolloutMode.full);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesOnboardingJourneyRepository.quarantinePreferenceKey,
        ),
        raw,
      );
    },
  );

  test(
    'privacy gate preserves fresh start marker until allowed, then sends once',
    () async {
      final repository = _MemoryJourneyRepository();
      final journeyEvents = _JourneyEventSink(allowed: false);
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
        journeyEvents: journeyEvents,
      );

      final barred = await instance.resolveEntry();

      expect(barred.state!.startEventSent, isFalse);
      expect(repository.state!.startEventSent, isFalse);
      expect(journeyEvents.startCalls, 0);

      journeyEvents.allowed = true;
      final sent = await instance.resolveEntry();
      await instance.resolveEntry();

      expect(sent.state!.startEventSent, isTrue);
      expect(repository.state!.startEventSent, isTrue);
      expect(journeyEvents.startCalls, 1);
    },
  );

  test(
    'start delivery failure remains at-most-once and never blocks entry',
    () async {
      final repository = _MemoryJourneyRepository();
      final journeyEvents = _JourneyEventSink(throwOnStart: true);
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
        journeyEvents: journeyEvents,
      );

      expect((await instance.resolveEntry()).entry, FirstRunEntry.story);
      expect((await instance.resolveEntry()).entry, FirstRunEntry.story);
      expect(repository.state!.startEventSent, isTrue);
      expect(journeyEvents.startCalls, 1);
    },
  );

  test('legal consent gate prevents creation and start telemetry', () async {
    final repository = _MemoryJourneyRepository();
    final journeyEvents = _JourneyEventSink();
    final instance = coordinator(
      repository: repository,
      legacy: _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: false,
          hasCompletedOnboarding: false,
        ),
      ),
      gateway: _CommitGateway(consent: false),
      journeyEvents: journeyEvents,
    );

    expect((await instance.resolveEntry()).entry, FirstRunEntry.consent);
    expect(repository.state, isNull);
    expect(journeyEvents.startCalls, 0);
  });

  test('latches a full rollout across a later remote mode change', () async {
    var remoteMode = OnboardingRolloutMode.full;
    final repository = _MemoryJourneyRepository();
    final legacy = _LegacyReader(
      const LegacyOnboardingSnapshot(
        consentAccepted: true,
        hasCompletedOnboarding: false,
      ),
    );
    final gateway = _CommitGateway();
    final first = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
      rolloutModeReader: () => remoteMode,
    );

    expect((await first.resolveEntry()).entry, FirstRunEntry.story);
    await first.completeStoryPage(StoryPageId.personalCurriculum);
    remoteMode = OnboardingRolloutMode.minimalSafe;

    final relaunched = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
      rolloutModeReader: () => remoteMode,
    );
    final resumed = await relaunched.resolveEntry();

    expect(resumed.entry, FirstRunEntry.story);
    expect(resumed.state!.storyPage, StoryPageId.learn);
    expect(resumed.state!.rolloutMode, OnboardingRolloutMode.full);
    expect(relaunched.usesMinimalSafeFlow, isFalse);
  });

  test('latches minimal rollout when remote enablement arrives late', () async {
    var remoteMode = OnboardingRolloutMode.minimalSafe;
    final repository = _MemoryJourneyRepository();
    final legacy = _LegacyReader(
      const LegacyOnboardingSnapshot(
        consentAccepted: true,
        hasCompletedOnboarding: false,
      ),
    );
    final gateway = _CommitGateway();
    final first = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
      rolloutModeReader: () => remoteMode,
    );

    expect((await first.resolveEntry()).entry, FirstRunEntry.setup);
    remoteMode = OnboardingRolloutMode.full;

    final relaunched = coordinator(
      repository: repository,
      legacy: legacy,
      gateway: gateway,
      rolloutModeReader: () => remoteMode,
    );
    final resumed = await relaunched.resolveEntry();

    expect(resumed.entry, FirstRunEntry.setup);
    expect(resumed.state!.rolloutMode, OnboardingRolloutMode.minimalSafe);
    expect(relaunched.usesMinimalSafeFlow, isTrue);
  });

  test('migrates legacy completed users directly to AppShell once', () async {
    final repository = _MemoryJourneyRepository();
    final events = _EventSink();
    final journeyEvents = _JourneyEventSink();
    final instance = coordinator(
      repository: repository,
      legacy: _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: true,
          userLevel: LearnerLevel.c1,
          purpose: OnboardingPurpose.peopleCulture,
          companion: OnboardingCompanion.joy,
        ),
      ),
      gateway: _CommitGateway(),
      events: events,
      journeyEvents: journeyEvents,
    );

    final first = await instance.resolveEntry();
    final second = await instance.resolveEntry();

    expect(first.entry, FirstRunEntry.appShell);
    expect(first.migratedLegacyState, isTrue);
    expect(second.migratedLegacyState, isFalse);
    expect(first.state!.phase, OnboardingPhase.complete);
    expect(first.state!.gateIntroConsumed, isTrue);
    expect(first.state!.shellEntryEventSent, isTrue);
    expect(first.state!.startEventSent, isTrue);
    await instance.recordAppShellFirstFrame();
    expect(events.calls, 0);
    expect(journeyEvents.startCalls, 0);
  });

  test(
    'minimal kill switch keeps setup and companion but skips story and media',
    () async {
      final repository = _MemoryJourneyRepository();
      final gateway = _CommitGateway();
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
        rolloutMode: OnboardingRolloutMode.minimalSafe,
      );

      expect((await instance.resolveEntry()).entry, FirstRunEntry.setup);
      await instance.savePurposeDraft(OnboardingPurpose.dailyTravel);
      await instance.saveLevelDraft(LearnerLevel.a2);
      expect(
        (await instance.continueFromSetup()).phase,
        OnboardingPhase.companion,
      );
      await instance.saveCompanionDraft(OnboardingCompanion.taego);

      final committed = await instance.commitFromCompanionMinimal();

      expect(committed.phase, OnboardingPhase.complete);
      expect(committed.gateIntroAttempted, isTrue);
      expect(committed.gateIntroConsumed, isTrue);
      expect((await instance.resolveEntry()).entry, FirstRunEntry.appShell);
      expect(gateway.purposeWrites, 1);
      expect(gateway.placementWrites, 1);
      expect(gateway.browseWrites, 1);
      expect(gateway.companionWrites, 1);
      expect(gateway.companionVisible, isTrue);
      expect(gateway.legacyCompanionMirror, OnboardingCompanion.taego);
      expect(gateway.completionWrites, 1);
    },
  );

  test(
    'legacy partial state with a level resumes at setup for confirmation',
    () async {
      final repository = _MemoryJourneyRepository();
      final journeyEvents = _JourneyEventSink();
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
            userLevel: LearnerLevel.b1,
            purpose: OnboardingPurpose.dailyTravel,
            companion: OnboardingCompanion.taego,
          ),
        ),
        gateway: _CommitGateway(),
        journeyEvents: journeyEvents,
      );

      final resolution = await instance.resolveEntry();

      expect(resolution.entry, FirstRunEntry.setup);
      expect(resolution.state!.levelDraft, LearnerLevel.b1);
      expect(resolution.state!.purposeDraft, OnboardingPurpose.dailyTravel);
      expect(resolution.state!.companionDraft, OnboardingCompanion.taego);
      expect(resolution.state!.commitStage, OnboardingCommitStage.none);
      expect(resolution.state!.startEventSent, isTrue);
      expect(journeyEvents.startCalls, 0);
    },
  );

  test(
    'legacy partial recovery prefers validated course placement over account level',
    () async {
      final repository = _MemoryJourneyRepository();
      final gateway = _CommitGateway()..placement = LearnerLevel.a1;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
            userLevel: LearnerLevel.b2,
            purpose: OnboardingPurpose.studyWork,
          ),
        ),
        gateway: gateway,
      );

      final resolution = await instance.resolveEntry();

      expect(resolution.entry, FirstRunEntry.setup);
      expect(resolution.state!.levelDraft, LearnerLevel.a1);
      expect(gateway.placementWrites, 0);
      expect(repository.state!.levelDraft, LearnerLevel.a1);
    },
  );

  test(
    'legacy partial recovery restores canonical placement when mirrors are torn',
    () async {
      final repository = _MemoryJourneyRepository();
      final gateway = _CommitGateway(hasCourseHistory: true)
        ..canonicalPlacement = LearnerLevel.a1;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
            userLevel: LearnerLevel.b2,
            purpose: OnboardingPurpose.studyWork,
          ),
        ),
        gateway: gateway,
      );

      final resolution = await instance.resolveEntry();

      expect(resolution.entry, FirstRunEntry.setup);
      expect(resolution.state!.levelDraft, LearnerLevel.a1);
      expect(gateway.placementWrites, 0);
    },
  );

  test('consent always wins over persisted onboarding progress', () async {
    final repository = _MemoryJourneyRepository(
      OnboardingJourneyState.initial(
        now,
      ).copyWith(phase: OnboardingPhase.setup, updatedAt: now),
    );
    final instance = coordinator(
      repository: repository,
      legacy: _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: false,
          hasCompletedOnboarding: false,
        ),
      ),
      gateway: _CommitGateway(consent: false),
    );

    expect((await instance.resolveEntry()).entry, FirstRunEntry.consent);
    expect(repository.state!.phase, OnboardingPhase.setup);
  });

  test(
    'setup and companion choices remain drafts until final confirmation',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.setup,
          storyPage: StoryPageId.heritageJourney,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway();
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      await instance.savePurposeDraft(OnboardingPurpose.studyWork);
      await instance.saveLevelDraft(LearnerLevel.c1);
      await instance.continueFromSetup();
      await instance.saveCompanionDraft(OnboardingCompanion.joy);
      await instance.continueFromCompanion();

      expect(repository.state!.phase, OnboardingPhase.confirmation);
      expect(gateway.purposeWrites, 0);
      expect(gateway.placementWrites, 0);
      expect(gateway.browseWrites, 0);
      expect(gateway.companionWrites, 0);
      expect(gateway.completionWrites, 0);
    },
  );

  test(
    'commit retries incomplete writes without repeating verified stages',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.confirmation,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.kContent,
          levelDraft: LearnerLevel.b2,
          companionDraft: OnboardingCompanion.joy,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway(
        throwAfterPlacementWriteOnce: true,
        throwAfterCompanionWriteOnce: true,
        throwAfterCompletionWriteOnce: true,
      );
      final events = _EventSink();
      final legacy = _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: false,
        ),
      );
      final instance = coordinator(
        repository: repository,
        legacy: legacy,
        gateway: gateway,
        events: events,
      );

      await expectLater(instance.commit(), throwsStateError);
      expect(
        repository.state!.commitStage,
        OnboardingCommitStage.motivationSaved,
      );

      await expectLater(instance.commit(), throwsStateError);
      expect(
        repository.state!.commitStage,
        OnboardingCommitStage.placementVerified,
      );

      await expectLater(instance.commit(), throwsStateError);
      expect(
        repository.state!.commitStage,
        OnboardingCommitStage.companionSaved,
      );

      final committed = await instance.commit();
      expect(committed.phase, OnboardingPhase.gate);
      expect(committed.commitStage, OnboardingCommitStage.completed);
      expect(gateway.purposeWrites, 1);
      expect(gateway.placementWrites, 1);
      expect(gateway.browseWrites, 1);
      expect(gateway.companionWrites, 2);
      expect(gateway.completionWrites, 1);

      await instance.commit();
      expect(gateway.placementWrites, 1);
      expect(gateway.companionWrites, 2);
      expect(gateway.completionWrites, 1);

      await instance.markGateAttempted();
      final relaunched = coordinator(
        repository: repository,
        legacy: legacy,
        gateway: gateway,
        events: events,
      );
      expect((await relaunched.resolveEntry()).entry, FirstRunEntry.appShell);
      expect(repository.state!.gateIntroConsumed, isTrue);

      await relaunched.recordAppShellFirstFrame();
      await relaunched.recordAppShellFirstFrame();
      expect(events.calls, 1);
    },
  );

  test(
    'course history blocks an implicit placement rewrite before committing',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.confirmation,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.taego,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway(hasCourseHistory: true)
        ..placement = LearnerLevel.b2
        ..browse = LearnerLevel.b2;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      await expectLater(
        instance.commit(),
        throwsA(isA<OnboardingPlacementHistoryConflictException>()),
      );

      expect(repository.state!.phase, OnboardingPhase.setup);
      expect(repository.state!.commitStage, OnboardingCommitStage.none);
      expect(gateway.purposeWrites, 0);
      expect(gateway.placementWrites, 0);
    },
  );

  test(
    'canonical placement matching the draft repairs torn mirrors and commits',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.confirmation,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.a1,
          companionDraft: OnboardingCompanion.taego,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway(hasCourseHistory: true)
        ..canonicalPlacement = LearnerLevel.a1
        ..browse = LearnerLevel.a1;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      final committed = await instance.commit();

      expect(committed.phase, OnboardingPhase.gate);
      expect(committed.commitStage, OnboardingCommitStage.completed);
      expect(gateway.placement, LearnerLevel.a1);
      expect(gateway.placementWrites, 1);
    },
  );

  test('a resumed conflicting commit recovers to editable setup', () async {
    final repository = _MemoryJourneyRepository(
      OnboardingJourneyState.initial(now).copyWith(
        phase: OnboardingPhase.committing,
        storyPage: StoryPageId.heritageJourney,
        purposeDraft: OnboardingPurpose.studyWork,
        levelDraft: LearnerLevel.b1,
        companionDraft: OnboardingCompanion.taego,
        commitStage: OnboardingCommitStage.motivationSaved,
        updatedAt: now,
      ),
    );
    final gateway = _CommitGateway(hasCourseHistory: true)
      ..purpose = OnboardingPurpose.studyWork
      ..placement = LearnerLevel.b2
      ..browse = LearnerLevel.b2;
    final instance = coordinator(
      repository: repository,
      legacy: _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: false,
        ),
      ),
      gateway: gateway,
    );

    await expectLater(
      instance.commit(),
      throwsA(isA<OnboardingPlacementHistoryConflictException>()),
    );

    expect(repository.state!.phase, OnboardingPhase.setup);
    expect(repository.state!.commitStage, OnboardingCommitStage.none);
    expect(gateway.placementWrites, 0);
  });

  test(
    'a resumed placement-verified journal rechecks changed course history',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.committing,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.taego,
          commitStage: OnboardingCommitStage.placementVerified,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway(hasCourseHistory: true)
        ..purpose = OnboardingPurpose.studyWork
        ..placement = LearnerLevel.b2
        ..canonicalPlacement = LearnerLevel.b2
        ..browse = LearnerLevel.b2;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      await expectLater(
        instance.commit(),
        throwsA(isA<OnboardingPlacementHistoryConflictException>()),
      );

      expect(repository.state!.phase, OnboardingPhase.setup);
      expect(repository.state!.commitStage, OnboardingCommitStage.none);
      expect(gateway.placementWrites, 0);
      expect(gateway.companionWrites, 0);
      expect(gateway.completionWrites, 0);
    },
  );

  test(
    'a resumed placement-verified journal repairs safe placement drift',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.committing,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.taego,
          commitStage: OnboardingCommitStage.placementVerified,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway()
        ..purpose = OnboardingPurpose.studyWork
        ..placement = LearnerLevel.a2
        ..browse = LearnerLevel.a2;
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      final committed = await instance.commit();

      expect(committed.phase, OnboardingPhase.gate);
      expect(gateway.placement, LearnerLevel.b1);
      expect(gateway.browse, LearnerLevel.b1);
      expect(gateway.placementWrites, 1);
      expect(gateway.browseWrites, 1);
      expect(gateway.companionWrites, 1);
      expect(gateway.completionWrites, 1);
    },
  );

  test('minimal companion conflict also recovers to editable setup', () async {
    final repository = _MemoryJourneyRepository(
      OnboardingJourneyState.initial(
        now,
        rolloutMode: OnboardingRolloutMode.minimalSafe,
      ).copyWith(
        phase: OnboardingPhase.companion,
        storyPage: StoryPageId.heritageJourney,
        purposeDraft: OnboardingPurpose.studyWork,
        levelDraft: LearnerLevel.b1,
        companionDraft: OnboardingCompanion.joy,
        updatedAt: now,
      ),
    );
    final gateway = _CommitGateway(hasCourseHistory: true)
      ..placement = LearnerLevel.b2
      ..browse = LearnerLevel.b2;
    final instance = coordinator(
      repository: repository,
      legacy: _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: false,
        ),
      ),
      gateway: gateway,
    );

    await expectLater(
      instance.commitFromCompanionMinimal(),
      throwsA(isA<OnboardingPlacementHistoryConflictException>()),
    );

    expect(repository.state!.phase, OnboardingPhase.setup);
    expect(repository.state!.commitStage, OnboardingCommitStage.none);
    expect(gateway.placementWrites, 0);
  });

  test(
    'retries a partial companion write until identity visibility and mirror match',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.confirmation,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.taego,
          updatedAt: now,
        ),
      );
      final gateway = _CommitGateway(throwAfterCompanionWriteOnce: true);
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: gateway,
      );

      await expectLater(instance.commit(), throwsStateError);
      expect(gateway.companion, OnboardingCompanion.taego);
      expect(gateway.companionIdentityExplicitlyStored, isTrue);
      expect(gateway.companionVisible, isFalse);
      expect(gateway.legacyCompanionMirror, isNull);

      final committed = await instance.commit();

      expect(committed.phase, OnboardingPhase.gate);
      expect(gateway.companionWrites, 2);
      expect(gateway.companionVisible, isTrue);
      expect(gateway.legacyCompanionMirror, OnboardingCompanion.taego);
    },
  );

  test(
    'analytics consent gates the durable completion marker without duplicates',
    () async {
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.complete,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.peopleCulture,
          levelDraft: LearnerLevel.c1,
          companionDraft: OnboardingCompanion.joy,
          commitStage: OnboardingCommitStage.completed,
          gateIntroAttempted: true,
          gateIntroConsumed: true,
          updatedAt: now,
        ),
      );
      final events = _EventSink(allowed: false);
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
        events: events,
      );

      final barred = await instance.recordAppShellFirstFrame();

      expect(barred.shellEntryEventSent, isFalse);
      expect(repository.state!.shellEntryEventSent, isFalse);
      expect(events.calls, 0);

      events.allowed = true;
      await instance.recordAppShellFirstFrame();
      await instance.recordAppShellFirstFrame();

      expect(repository.state!.shellEntryEventSent, isTrue);
      expect(events.calls, 1);
      expect(events.states.single.levelDraft, LearnerLevel.c1);
    },
  );

  test(
    'a reset after shell-state load cannot resurrect the completed journal',
    () async {
      final repository = _PausedLoadJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.complete,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.peopleCulture,
          levelDraft: LearnerLevel.c1,
          companionDraft: OnboardingCompanion.joy,
          commitStage: OnboardingCommitStage.completed,
          gateIntroAttempted: true,
          gateIntroConsumed: true,
          updatedAt: now,
        ),
      );
      final events = _EventSink();
      final instance = coordinator(
        repository: repository,
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: true,
          ),
        ),
        gateway: _CommitGateway(),
        events: events,
      );

      final pending = instance.recordAppShellFirstFrame();
      await repository.loadStarted.future;
      LocalDataLifetime.invalidate();
      await repository.clear();
      repository.releaseLoad.complete();

      await expectLater(
        pending,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(repository.state, isNull);
      expect(repository.saveCalls, 0);
      expect(events.calls, 0);
    },
  );

  test(
    'preview failure telemetry is best effort and uses closed reasons',
    () async {
      final journeyEvents = _JourneyEventSink(throwOnPreview: true);
      final instance = coordinator(
        repository: _MemoryJourneyRepository(),
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
        journeyEvents: journeyEvents,
      );

      await instance.recordCompanionPreviewFailure(
        OnboardingCompanionPreviewFailure.initialization,
      );
      journeyEvents.throwOnPreview = false;
      await instance.recordCompanionPreviewFailure(
        OnboardingCompanionPreviewFailure.playback,
      );

      expect(journeyEvents.previewFailures, [
        OnboardingCompanionPreviewFailure.initialization,
        OnboardingCompanionPreviewFailure.playback,
      ]);
    },
  );

  test(
    'minimal confirmation recovery returns to the no-media companion CTA',
    () async {
      final state =
          OnboardingJourneyState.initial(
            now,
            rolloutMode: OnboardingRolloutMode.minimalSafe,
          ).copyWith(
            phase: OnboardingPhase.confirmation,
            storyPage: StoryPageId.heritageJourney,
            purposeDraft: OnboardingPurpose.dailyTravel,
            levelDraft: LearnerLevel.a2,
            companionDraft: OnboardingCompanion.taego,
            updatedAt: now,
          );
      final instance = coordinator(
        repository: _MemoryJourneyRepository(state),
        legacy: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        gateway: _CommitGateway(),
        rolloutMode: OnboardingRolloutMode.full,
      );

      final resolution = await instance.resolveEntry();

      expect(resolution.entry, FirstRunEntry.companion);
      expect(resolution.state!.rolloutMode, OnboardingRolloutMode.minimalSafe);
    },
  );

  test(
    'all purpose, level, and companion combinations commit safely',
    () async {
      for (final purpose in OnboardingPurpose.values) {
        for (final level in LearnerLevel.values) {
          for (final companion in OnboardingCompanion.values) {
            final repository = _MemoryJourneyRepository(
              OnboardingJourneyState.initial(now).copyWith(
                phase: OnboardingPhase.confirmation,
                storyPage: StoryPageId.heritageJourney,
                purposeDraft: purpose,
                levelDraft: level,
                companionDraft: companion,
                updatedAt: now,
              ),
            );
            final gateway = _CommitGateway();
            final instance = coordinator(
              repository: repository,
              legacy: _LegacyReader(
                const LegacyOnboardingSnapshot(
                  consentAccepted: true,
                  hasCompletedOnboarding: false,
                ),
              ),
              gateway: gateway,
            );

            final committed = await instance.commit();

            expect(committed.phase, OnboardingPhase.gate);
            expect(gateway.purpose, purpose);
            expect(gateway.placement, level);
            expect(gateway.browse, level);
            expect(gateway.companion, companion);
            expect(gateway.purposeWrites, 1);
            expect(gateway.placementWrites, 1);
            expect(gateway.browseWrites, 1);
            expect(gateway.companionWrites, 1);
            expect(gateway.completionWrites, 1);
          }
        }
      }
    },
  );

  test(
    'every interrupted durable phase resolves to its exact safe entry',
    () async {
      final legacy = _LegacyReader(
        const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: false,
        ),
      );
      final expectedEntries = <OnboardingPhase, FirstRunEntry>{
        OnboardingPhase.story: FirstRunEntry.story,
        OnboardingPhase.setup: FirstRunEntry.setup,
        OnboardingPhase.companion: FirstRunEntry.companion,
        OnboardingPhase.confirmation: FirstRunEntry.confirmation,
        OnboardingPhase.committing: FirstRunEntry.committing,
        OnboardingPhase.gate: FirstRunEntry.gate,
        OnboardingPhase.complete: FirstRunEntry.appShell,
      };

      for (final entry in expectedEntries.entries) {
        final phase = entry.key;
        final state = OnboardingJourneyState.initial(now).copyWith(
          phase: phase,
          storyPage: phase == OnboardingPhase.story
              ? StoryPageId.saveAndReview
              : StoryPageId.heritageJourney,
          purposeDraft: phase == OnboardingPhase.story
              ? null
              : OnboardingPurpose.dailyTravel,
          levelDraft: phase == OnboardingPhase.story ? null : LearnerLevel.a2,
          companionDraft:
              phase == OnboardingPhase.story || phase == OnboardingPhase.setup
              ? null
              : OnboardingCompanion.taego,
          commitStage: switch (phase) {
            OnboardingPhase.committing => OnboardingCommitStage.motivationSaved,
            OnboardingPhase.gate ||
            OnboardingPhase.complete => OnboardingCommitStage.completed,
            _ => OnboardingCommitStage.none,
          },
          gateIntroAttempted: phase == OnboardingPhase.complete,
          gateIntroConsumed: phase == OnboardingPhase.complete,
          updatedAt: now,
        );
        final instance = coordinator(
          repository: _MemoryJourneyRepository(state),
          legacy: legacy,
          gateway: _CommitGateway(),
        );

        expect((await instance.resolveEntry()).entry, entry.value);
      }
    },
  );
}

class _MemoryJourneyRepository implements OnboardingJourneyRepository {
  _MemoryJourneyRepository([this.state]);

  OnboardingJourneyState? state;

  @override
  Future<void> clear() async {
    state = null;
  }

  @override
  Future<OnboardingJourneyState?> load() async => state;

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    this.state = state;
  }
}

class _PausedLoadJourneyRepository implements OnboardingJourneyRepository {
  _PausedLoadJourneyRepository(this.state);

  OnboardingJourneyState? state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<void> releaseLoad = Completer<void>();
  int saveCalls = 0;

  @override
  Future<void> clear() async => state = null;

  @override
  Future<OnboardingJourneyState?> load() async {
    final captured = state;
    loadStarted.complete();
    await releaseLoad.future;
    return captured;
  }

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    saveCalls++;
    this.state = state;
  }
}

class _LegacyReader implements LegacyOnboardingStateReader {
  _LegacyReader(this.snapshot);

  LegacyOnboardingSnapshot snapshot;

  @override
  Future<LegacyOnboardingSnapshot> read() async => snapshot;
}

class _CommitGateway
    implements
        OnboardingCommitGateway,
        OnboardingCompanionCommitSnapshotReader {
  _CommitGateway({
    this.consent = true,
    this.hasCourseHistory = false,
    this.throwAfterPlacementWriteOnce = false,
    this.throwAfterCompanionWriteOnce = false,
    this.throwAfterCompletionWriteOnce = false,
  });

  bool consent;
  bool hasCourseHistory;
  bool throwAfterPlacementWriteOnce;
  bool throwAfterCompanionWriteOnce;
  bool throwAfterCompletionWriteOnce;

  OnboardingPurpose? purpose;
  LearnerLevel? placement;
  LearnerLevel? canonicalPlacement;
  LearnerLevel? browse;
  OnboardingCompanion? companion;
  bool companionIdentityExplicitlyStored = false;
  bool companionVisible = false;
  OnboardingCompanion? legacyCompanionMirror;
  bool completed = false;

  int purposeWrites = 0;
  int placementWrites = 0;
  int browseWrites = 0;
  int companionWrites = 0;
  int completionWrites = 0;

  @override
  Future<bool> hasConsent() async => consent;

  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) async {
    placementWrites++;
    placement = level;
    if (throwAfterPlacementWriteOnce) {
      throwAfterPlacementWriteOnce = false;
      throw StateError('process stopped after placement write');
    }
  }

  @override
  Future<bool> isLegacyOnboardingComplete() async => completed;

  @override
  Future<void> markLegacyOnboardingComplete() async {
    completionWrites++;
    completed = true;
    if (throwAfterCompletionWriteOnce) {
      throwAfterCompletionWriteOnce = false;
      throw StateError('process stopped after completion write');
    }
  }

  @override
  Future<OnboardingCompanion?> readCompanion() async => companion;

  @override
  Future<OnboardingCompanionCommitSnapshot>
  readCompanionCommitSnapshot() async {
    return OnboardingCompanionCommitSnapshot(
      companion: companion,
      identityExplicitlyStored: companionIdentityExplicitlyStored,
      visible: companionVisible,
      legacyMirror: legacyCompanionMirror,
    );
  }

  @override
  Future<OnboardingPlacementSnapshot> readPlacement() async {
    return OnboardingPlacementSnapshot(
      placementLevel: placement,
      canonicalPlacementLevel: canonicalPlacement,
      browseLevel: browse,
      hasCourseHistory: hasCourseHistory,
    );
  }

  @override
  Future<OnboardingPurpose?> readPurpose() async => purpose;

  @override
  Future<void> saveCompanion(OnboardingCompanion value) async {
    companionWrites++;
    companion = value;
    companionIdentityExplicitlyStored = true;
    if (throwAfterCompanionWriteOnce) {
      throwAfterCompanionWriteOnce = false;
      throw StateError('process stopped after companion write');
    }
    companionVisible = true;
    legacyCompanionMirror = value;
  }

  @override
  Future<void> savePurpose(OnboardingPurpose value) async {
    purposeWrites++;
    purpose = value;
  }

  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) async {
    browseWrites++;
    browse = level;
  }
}

class _EventSink implements OnboardingCompletionEventSink {
  _EventSink({this.allowed = true});

  bool allowed;
  int calls = 0;
  final List<OnboardingJourneyState> states = [];

  @override
  bool get canRecordOnboardingCompleted => allowed;

  @override
  Future<void> recordOnboardingCompleted(OnboardingJourneyState state) async {
    calls++;
    states.add(state);
  }
}

class _JourneyEventSink implements OnboardingJourneyEventSink {
  _JourneyEventSink({
    this.allowed = true,
    this.throwOnStart = false,
    this.throwOnPreview = false,
  });

  bool allowed;
  bool throwOnStart;
  bool throwOnPreview;
  int startCalls = 0;
  final List<OnboardingCompanionPreviewFailure> previewFailures = [];

  @override
  bool get canRecordOnboardingStarted => allowed;

  @override
  Future<void> recordOnboardingStarted() async {
    startCalls++;
    if (throwOnStart) {
      throw StateError('analytics unavailable');
    }
  }

  @override
  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  ) async {
    previewFailures.add(failure);
    if (throwOnPreview) {
      throw StateError('analytics unavailable');
    }
  }
}
