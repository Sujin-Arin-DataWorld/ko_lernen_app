import '../models/curriculum.dart';

/// Decides whether the optional companion invitation may appear after a
/// learner's first verified success in the current attempt. It never writes
/// mastery, progress, or completion state.
class OnboardingCompanionService {
  const OnboardingCompanionService._();

  static bool shouldOfferAfterAttempt({
    required bool introPreviewSeen,
    required String? activeCourseUnitId,
    required String? activeCourseLevel,
    required Iterable<String> evidenceIdsBefore,
    required Iterable<MasteryEvidence> evidenceAfter,
  }) {
    final unitId = activeCourseUnitId?.trim();
    if (introPreviewSeen || unitId == null || unitId.isEmpty) {
      return false;
    }
    if (activeCourseLevel?.trim().toLowerCase() != 'a1') {
      return false;
    }
    final historicalIds = evidenceIdsBefore.toSet();

    return evidenceAfter.any(
      (item) =>
          !historicalIds.contains(item.id) &&
          item.courseEligible &&
          item.isCorrect &&
          item.courseUnitId == unitId,
    );
  }
}
