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
    required Iterable<ContentLink> contentLinks,
  }) {
    final unitId = activeCourseUnitId?.trim();
    if (introPreviewSeen || unitId == null || unitId.isEmpty) {
      return false;
    }
    if (activeCourseLevel?.trim().toLowerCase() != 'a1') {
      return false;
    }
    final historicalIds = evidenceIdsBefore.toSet();

    return evidenceAfter.any((item) {
      if (historicalIds.contains(item.id) ||
          !item.courseEligible ||
          item.missionContentLinkId == null ||
          !item.isCorrect ||
          item.courseUnitId != unitId ||
          (item.contentKind != CurriculumContentKind.grammar &&
              item.contentKind != CurriculumContentKind.smalltalk &&
              item.contentKind != CurriculumContentKind.scenario)) {
        return false;
      }
      return contentLinks.any(
        (link) =>
            link.id == item.missionContentLinkId &&
            link.courseUnitId == item.courseUnitId &&
            link.contentKind == item.contentKind &&
            link.contentId == item.contentId &&
            link.conceptIds.contains(item.conceptId) &&
            link.role == ContentLinkRole.assess,
      );
    });
  }
}
