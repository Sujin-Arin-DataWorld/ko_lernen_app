import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/services/onboarding_flow_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('does not mark onboarding complete before consent', () async {
    await expectLater(
      OnboardingFlowService.completeAfterLevelSelection(),
      throwsA(isA<StateError>()),
    );

    expect(Storage.hasCompletedOnboarding, isFalse);
    expect(Storage.sessionCount, 0);
  });

  test(
    'marks the first usable level after consent without creating evidence',
    () async {
      await Storage.setConsentAccepted();

      await OnboardingFlowService.completeAfterLevelSelection(
        motivation: LearnerMotivation.travel,
      );

      expect(Storage.hasCompletedOnboarding, isTrue);
      expect(Storage.sessionCount, 1);
      expect(Storage.lastActivityTime, isNotEmpty);
      expect(Storage.motivation, LearnerMotivation.travel.id);
      expect(Storage.motivationAsked, isTrue);
      expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
    },
  );

  test(
    'preserves an existing session count and does not re-complete',
    () async {
      await Storage.setConsentAccepted();
      await Storage.setHasCompletedOnboarding(true);
      await Storage.setSessionCount(4);

      await OnboardingFlowService.completeAfterLevelSelection();

      expect(Storage.sessionCount, 4);
    },
  );
}
