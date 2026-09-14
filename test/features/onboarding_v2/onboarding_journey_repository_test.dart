import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips the complete immutable V2 state in one value', () async {
    final repository = SharedPreferencesOnboardingJourneyRepository();
    final state = OnboardingJourneyState.initial(DateTime.utc(2026, 8, 26, 12))
        .copyWith(
          phase: OnboardingPhase.companion,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.studyWork,
          levelDraft: LearnerLevel.b2,
          companionDraft: OnboardingCompanion.joy,
          updatedAt: DateTime.utc(2026, 8, 26, 13),
        );

    await repository.save(state);

    expect(await repository.load(), state);
    expect(state.rolloutMode, OnboardingRolloutMode.full);
    expect(state.startEventSent, isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(
        SharedPreferencesOnboardingJourneyRepository.preferenceKey,
      ),
      isTrue,
    );
  });

  test('does not infer V2 progress from legacy first-run keys', () async {
    SharedPreferences.setMockInitialValues({
      'kl_onboarding_completed': true,
      'kl_session_count': 1,
      'kl_intro_preview_seen': true,
      'kl_user_level': 'c1',
    });
    final repository = SharedPreferencesOnboardingJourneyRepository();

    expect(await repository.load(), isNull);
  });

  test('schema five persists beginner separately from canonical A1', () async {
    final repository = SharedPreferencesOnboardingJourneyRepository();
    final state = OnboardingJourneyState.initial(
      DateTime.utc(2026, 9, 14),
    ).copyWith(levelDraft: LearnerLevel.a1, beginnerDraft: true);
    await repository.save(state);
    expect(await repository.load(), state);
    expect((await repository.load())!.purposeDraft, isNull);
  });

  test(
    'schema four reorders uncommitted pages without replaying saved gates',
    () async {
      for (final phase in OnboardingPhase.values) {
        final old = OnboardingJourneyState.initial(DateTime.utc(2026, 9, 14))
            .copyWith(
              phase: phase,
              storyPage: StoryPageId.saveAndReview,
              levelDraft: phase == OnboardingPhase.story
                  ? null
                  : LearnerLevel.b2,
              companionDraft: OnboardingCompanion.joy,
              commitStage: switch (phase) {
                OnboardingPhase.committing =>
                  OnboardingCommitStage.placementVerified,
                OnboardingPhase.gate ||
                OnboardingPhase.complete => OnboardingCommitStage.completed,
                _ => OnboardingCommitStage.none,
              },
              startEventSent: true,
              gateIntroAttempted: phase == OnboardingPhase.complete,
              gateIntroConsumed: phase == OnboardingPhase.complete,
              shellEntryEventSent: phase == OnboardingPhase.complete,
            );
        final json = old.toJson()..['schemaVersion'] = 4;
        json.remove('beginnerDraft');
        SharedPreferences.setMockInitialValues({
          SharedPreferencesOnboardingJourneyRepository.preferenceKey:
              jsonEncode(json),
        });
        final repository = SharedPreferencesOnboardingJourneyRepository();
        final migrated = (await repository.load())!;
        expect(migrated.phase, switch (phase) {
          OnboardingPhase.story => OnboardingPhase.setup,
          OnboardingPhase.confirmation => OnboardingPhase.companion,
          _ => phase,
        });
        expect(migrated.commitStage, old.commitStage);
        expect(migrated.rolloutMode, old.rolloutMode);
        expect(migrated.startEventSent, old.startEventSent);
        expect(migrated.gateIntroAttempted, old.gateIntroAttempted);
        expect(migrated.gateIntroConsumed, old.gateIntroConsumed);
        expect(migrated.shellEntryEventSent, old.shellEntryEventSent);
        expect(migrated.beginnerDraft, isFalse);
        expect(migrated.purposeDraft, isNull);
        expect(migrated.schemaVersion, 5);
        expect(await repository.load(), migrated);
      }
    },
  );

  test('an old book cursor includes games before resuming the book page', () {
    final raw =
        OnboardingJourneyState.initial(DateTime.utc(2026, 9, 14))
            .copyWith(
              phase: OnboardingPhase.story,
              storyPage: StoryPageId.saveAndReview,
              levelDraft: LearnerLevel.a2,
              purposeDraft: OnboardingPurpose.studyWork,
            )
            .toJson()
          ..['schemaVersion'] = 4;
    final migrated = OnboardingJourneyState.fromJson(raw);
    expect(migrated.phase, OnboardingPhase.story);
    expect(migrated.storyPage, StoryPageId.gamesAndRewards);
    expect(migrated.levelDraft, LearnerLevel.a2);
    expect(migrated.purposeDraft, OnboardingPurpose.studyWork);
  });

  test(
    'quarantines a future schema and clears the active retry loop',
    () async {
      const raw = '{"schemaVersion":999,"phase":"story"}';
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey: raw,
      });
      final repository = SharedPreferencesOnboardingJourneyRepository();

      expect(await repository.load(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesOnboardingJourneyRepository.quarantinePreferenceKey,
        ),
        raw,
      );
      expect(
        preferences.containsKey(
          SharedPreferencesOnboardingJourneyRepository.preferenceKey,
        ),
        isFalse,
      );
      expect(await repository.load(), isNull);
    },
  );

  test(
    'quarantines malformed JSON before allowing a fresh resolution',
    () async {
      const raw = '{not-json';
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey: raw,
      });
      final repository = SharedPreferencesOnboardingJourneyRepository();

      expect(await repository.load(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesOnboardingJourneyRepository.quarantinePreferenceKey,
        ),
        raw,
      );
      expect(
        preferences.containsKey(
          SharedPreferencesOnboardingJourneyRepository.preferenceKey,
        ),
        isFalse,
      );
    },
  );

  for (final entry in <String, String>{
    'missing': '{"schemaVersion":4,"phase":"story"}',
    'unknown':
        '{"schemaVersion":4,"rolloutMode":"surprise",'
        '"phase":"story"}',
  }.entries) {
    test(
      'quarantines a current-schema journal with ${entry.key} rollout mode',
      () async {
        SharedPreferences.setMockInitialValues({
          SharedPreferencesOnboardingJourneyRepository.preferenceKey:
              entry.value,
        });
        final repository = SharedPreferencesOnboardingJourneyRepository();

        expect(await repository.load(), isNull);
        final preferences = await SharedPreferences.getInstance();
        expect(
          preferences.getString(
            SharedPreferencesOnboardingJourneyRepository
                .quarantinePreferenceKey,
          ),
          entry.value,
        );
        expect(
          preferences.containsKey(
            SharedPreferencesOnboardingJourneyRepository.preferenceKey,
          ),
          isFalse,
        );
      },
    );
  }

  test('pre-schema story progress stays on the full rollout', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesOnboardingJourneyRepository.preferenceKey:
          '{"schemaVersion":2,"phase":"story",'
          '"storyPage":"saveAndReview"}',
    });
    final repository = SharedPreferencesOnboardingJourneyRepository();

    final state = await repository.load();

    expect(state!.rolloutMode, OnboardingRolloutMode.full);
    expect(state.phase, OnboardingPhase.setup);
    expect(state.storyPage, StoryPageId.personalCurriculum);
    final preferences = await SharedPreferences.getInstance();
    final migrated = preferences.getString(
      SharedPreferencesOnboardingJourneyRepository.preferenceKey,
    );
    expect(migrated, contains('"schemaVersion":5'));
    expect(migrated, contains('"rolloutMode":"full"'));
    expect(migrated, contains('"startEventSent":true'));
  });

  test('ambiguous pre-schema partial progress fails safe to minimal', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesOnboardingJourneyRepository.preferenceKey:
          '{"schemaVersion":2,"phase":"confirmation",'
          '"storyPage":"heritageJourney",'
          '"purposeDraft":"daily_travel","levelDraft":"a2",'
          '"companionDraft":"tiger"}',
    });
    final repository = SharedPreferencesOnboardingJourneyRepository();

    final state = await repository.load();

    expect(state!.rolloutMode, OnboardingRolloutMode.minimalSafe);
    expect(state.phase, OnboardingPhase.companion);
    final preferences = await SharedPreferences.getInstance();
    final migrated = preferences.getString(
      SharedPreferencesOnboardingJourneyRepository.preferenceKey,
    );
    expect(migrated, contains('"schemaVersion":5'));
    expect(migrated, contains('"rolloutMode":"minimalSafe"'));
    expect(migrated, contains('"startEventSent":true'));
  });

  test(
    'a reset after legacy decode cannot recreate the migrated journal',
    () async {
      const raw =
          '{"schemaVersion":3,"phase":"complete",'
          '"commitStage":"completed","gateIntroConsumed":true}';
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey: raw,
      });
      final rewriteStarted = Completer<void>();
      final rewriteMayContinue = Completer<void>();
      final preferences = await SharedPreferences.getInstance();
      final repository = SharedPreferencesOnboardingJourneyRepository(
        preferencesLoader: () async => preferences,
        beforeRewriteForTesting: () async {
          rewriteStarted.complete();
          await rewriteMayContinue.future;
        },
      );

      final pending = repository.load();
      await rewriteStarted.future;
      LocalDataLifetime.invalidate();
      await preferences.remove(
        SharedPreferencesOnboardingJourneyRepository.preferenceKey,
      );
      rewriteMayContinue.complete();

      await expectLater(
        pending,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(
        preferences.containsKey(
          SharedPreferencesOnboardingJourneyRepository.preferenceKey,
        ),
        isFalse,
      );
      expect(
        preferences.containsKey(
          SharedPreferencesOnboardingJourneyRepository.quarantinePreferenceKey,
        ),
        isFalse,
      );
    },
  );

  test(
    'completed pre-v4 state suppresses a duplicate shell-entry event',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey:
            '{"schemaVersion":3,"phase":"complete",'
            '"commitStage":"completed","gateIntroConsumed":true}',
      });
      final repository = SharedPreferencesOnboardingJourneyRepository();

      final state = await repository.load();

      expect(state!.phase, OnboardingPhase.complete);
      expect(state.shellEntryEventSent, isTrue);
    },
  );

  test(
    'in-progress pre-v4 state can still emit after its future shell frame',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingJourneyRepository.preferenceKey:
            '{"schemaVersion":3,"phase":"setup",'
            '"storyPage":"heritageJourney"}',
      });
      final repository = SharedPreferencesOnboardingJourneyRepository();

      final state = await repository.load();

      expect(state!.phase, OnboardingPhase.setup);
      expect(state.shellEntryEventSent, isFalse);
    },
  );
}
