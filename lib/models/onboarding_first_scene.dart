import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';

/// The real-life scene opened directly from onboarding purpose selection.
///
/// This mapping changes only the learner's first situation. Course placement
/// remains A1 and no mastery evidence is created by choosing a purpose.
class OnboardingFirstScene {
  const OnboardingFirstScene({
    required this.motivation,
    required this.scenarioId,
    required this.successPhrase,
  });

  final LearnerMotivation motivation;
  final String scenarioId;
  final String successPhrase;

  static OnboardingFirstScene forMotivation(LearnerMotivation motivation) =>
      switch (motivation) {
        LearnerMotivation.loved => const OnboardingFirstScene(
          motivation: LearnerMotivation.loved,
          scenarioId: 'introduce_yourself',
          successPhrase: '안녕하세요.',
        ),
        LearnerMotivation.career => const OnboardingFirstScene(
          motivation: LearnerMotivation.career,
          scenarioId: 'first_class_meeting',
          successPhrase: '네, 처음이에요.',
        ),
        _ => const OnboardingFirstScene(
          motivation: LearnerMotivation.travel,
          scenarioId: 'airport_arrival',
          successPhrase: '네, 여기 있어요.',
        ),
      };

  String canDo(AppL10n t) => switch (motivation) {
    LearnerMotivation.loved => t.onboardingFirstScenePeopleCanDo,
    LearnerMotivation.career => t.onboardingFirstSceneWorkCanDo,
    _ => t.onboardingFirstSceneTravelCanDo,
  };
}
