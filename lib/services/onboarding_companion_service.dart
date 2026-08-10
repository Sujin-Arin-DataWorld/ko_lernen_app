import '../models/curriculum.dart';

/// Decides whether the optional companion invitation may appear after a
/// learner's first verified success. It deliberately reads existing course
/// evidence and never writes mastery, progress, or completion state.
class OnboardingCompanionService {
  const OnboardingCompanionService._();

  static bool shouldOffer({
    required bool introPreviewSeen,
    required String? activeCourseUnitId,
    required String? activeCourseLevel,
    required Iterable<MasteryEvidence> evidence,
  }) {
    final unitId = activeCourseUnitId?.trim();
    if (introPreviewSeen || unitId == null || unitId.isEmpty) return false;
    if (activeCourseLevel?.trim().toLowerCase() != 'a1') return false;

    return evidence.any(
      (item) =>
          item.courseEligible && item.isCorrect && item.courseUnitId == unitId,
    );
  }
}
