import '../data/learner_motivation.dart';

/// The real-life scene opened directly from onboarding purpose selection.
///
/// This mapping changes only the learner's first situation. Course placement
/// remains A1 and no mastery evidence is created by choosing a purpose.
class OnboardingFirstScene {
  const OnboardingFirstScene({
    required this.motivation,
    required this.scenarioId,
  });

  final LearnerMotivation motivation;
  final String scenarioId;

  static OnboardingFirstScene forMotivation(LearnerMotivation motivation) =>
      switch (motivation) {
        LearnerMotivation.loved => const OnboardingFirstScene(
          motivation: LearnerMotivation.loved,
          scenarioId: 'introduce_yourself',
        ),
        LearnerMotivation.career => const OnboardingFirstScene(
          motivation: LearnerMotivation.career,
          scenarioId: 'first_class_meeting',
        ),
        _ => const OnboardingFirstScene(
          motivation: LearnerMotivation.travel,
          scenarioId: 'airport_arrival',
        ),
      };
}
