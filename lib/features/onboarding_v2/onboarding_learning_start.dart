import '../../models/course_mastery.dart';
import '../../models/learner_level.dart';
import '../../services/catalog_history_lease.dart';
import '../../services/foundation_progress_service.dart';
import 'onboarding_journey_repository.dart';
import 'onboarding_journey_state.dart';

/// Account-scoped introductory practice remains available until the learner
/// chooses A1. Route visits, XP and tutorial dismissal are not completion.
abstract final class OnboardingLearningStart {
  static Future<bool> shouldOfferHangul({
    required CourseMasterySnapshot? course,
    OnboardingJourneyRepository? repository,
  }) async {
    final lease = CatalogHistoryLease.capture();
    try {
      if (_hasPriorLearning(course)) {
        return false;
      }
      final state =
          await (repository ?? SharedPreferencesOnboardingJourneyRepository())
              .load();
      if (!lease.isCurrent) {
        return false;
      }
      final foundation = await FoundationProgressService.shared.load();
      return lease.isCurrent &&
          state?.phase == OnboardingPhase.complete &&
          state?.beginnerDraft == true &&
          state?.levelDraft == LearnerLevel.a1 &&
          !foundation.continuedToA1 &&
          !_hasPriorLearning(course);
    } catch (_) {
      // Optional introductory copy must never hide a valid course mission.
      return false;
    }
  }

  static bool _hasPriorLearning(CourseMasterySnapshot? course) =>
      course?.placementLevel != 'a1' ||
      course!.completedUnitIds.isNotEmpty ||
      course.evidence.isNotEmpty ||
      course.scenarioCheckpoints.isNotEmpty ||
      course.phaseTaskEvidence.isNotEmpty ||
      course.productiveEvidence.isNotEmpty ||
      course.productiveProjectStepEvidence.isNotEmpty ||
      course.archivedProductiveEvidence.isNotEmpty ||
      course.archivedProductiveProjectStepEvidence.isNotEmpty;
}
