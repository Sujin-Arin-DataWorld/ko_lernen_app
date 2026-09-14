import '../../models/course_mastery.dart';
import '../../models/learner_level.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/catalog_history_lease.dart';
import '../../services/storage_service.dart';
import 'onboarding_journey_repository.dart';
import 'onboarding_journey_state.dart';

/// One introductory recommendation, consumed by the shell's existing activity
/// history after a real route launch. Reading it never changes course progress.
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
      return lease.isCurrent &&
          state?.phase == OnboardingPhase.complete &&
          state?.beginnerDraft == true &&
          state?.levelDraft == LearnerLevel.a1 &&
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
      course.archivedProductiveProjectStepEvidence.isNotEmpty ||
      Storage.tutSeen('hangul') ||
      Storage.recentCatalogActivityId(SoriStageTab.learn) != null ||
      Storage.recentCatalogActivityId(SoriStageTab.games) != null ||
      Storage.lastActivityId != null ||
      Storage.xp > 0 ||
      Storage.vokSeenIds.isNotEmpty ||
      Storage.grammarSeen.isNotEmpty ||
      Storage.hangulHard.isNotEmpty ||
      Storage.completedScenarios.isNotEmpty;
}
