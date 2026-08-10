import '../data/learner_motivation.dart';
import 'storage_service.dart';

/// Owns the durable boundary between agreeing to onboarding and completing it.
///
/// Selecting a purpose is useful personalisation, but it must never make a
/// learner look onboarded before consent and a usable course placement exist.
class OnboardingFlowService {
  const OnboardingFlowService._();

  static Future<void> completeAfterLevelSelection({
    LearnerMotivation? motivation,
  }) async {
    if (!Storage.consentAccepted) {
      throw StateError(
        'Onboarding completion requires consent and a completed placement.',
      );
    }

    if (motivation != null) {
      await Storage.setMotivation(motivation.id);
      await Storage.setMotivationAsked();
    }

    if (Storage.hasCompletedOnboarding) {
      return;
    }

    await Storage.setHasCompletedOnboarding(true);
    await Storage.setLastActivityTime(DateTime.now().toIso8601String());
    if (Storage.sessionCount == 0) {
      await Storage.setSessionCount(1);
    }
  }
}
