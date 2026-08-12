import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import '../models/gye_weekly_promise.dart';
import '../models/scenario.dart';
import 'cloud_sync.dart';
import 'course_mastery_service.dart';
import 'course_progress_service.dart';

/// Maps each existing scenario exercise to the narrowest correction category
/// that can be offered without free-form speech scoring.
MasteryErrorReason masteryErrorForQuestType(QuestType type) => switch (type) {
  QuestType.particlePop => MasteryErrorReason.particleRole,
  QuestType.batchimDrop => MasteryErrorReason.batchim,
  QuestType.satzBauen || QuestType.schreiben => MasteryErrorReason.wordOrder,
  QuestType.diktat => MasteryErrorReason.spellingSpacing,
  QuestType.hoerverstehen => MasteryErrorReason.listening,
  QuestType.luecken ||
  QuestType.uebersetzen => MasteryErrorReason.vocabularyRecall,
};

/// Converts an existing scenario's quest count into the 0..1 checkpoint score
/// used by the course engine. The clamp keeps malformed legacy scores from
/// accidentally satisfying a checkpoint.
double scenarioCheckpointScore({required int passed, required int total}) {
  if (total <= 0) return 0;
  return passed.clamp(0, total) / total;
}

/// Best-effort bridge from legacy activities into the one serialized course
/// service. Activity UX must never fail because an old free-browse item has no
/// graph link, but failures remain visible in debug logs for content QA.
class CourseActivityReporter {
  const CourseActivityReporter._();

  @visibleForTesting
  static Future<CourseUpdate> Function(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect,
    CoursePracticeContext? courseContext,
    MasteryErrorReason? errorReason,
    String? conceptId,
    double? score,
  )?
  recordContentAttemptForTesting;

  @visibleForTesting
  static Future<CourseUpdate> Function(
    String scenarioId,
    double score,
    CoursePracticeContext? courseContext,
  )?
  recordScenarioCheckpointForTesting;

  @visibleForTesting
  static Future<void> Function()? lifePromiseProjectionSyncForTesting;

  @visibleForTesting
  static void resetOverridesForTesting() {
    recordContentAttemptForTesting = null;
    recordScenarioCheckpointForTesting = null;
    lifePromiseProjectionSyncForTesting = null;
  }

  static Future<CourseUpdate?> recordContentAttempt(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect, {
    CoursePracticeContext? courseContext,
    MasteryErrorReason? errorReason,
    String? conceptId,
    double? score,
  }) async {
    try {
      final override = recordContentAttemptForTesting;
      return override != null
          ? await override(
              kind,
              contentId,
              isCorrect,
              courseContext,
              errorReason,
              conceptId,
              score,
            )
          : await CourseProgressService.shared.recordContentAttempt(
              kind,
              contentId,
              isCorrect,
              courseContext: courseContext,
              conceptId: conceptId,
              errorReason: errorReason,
              score: score,
            );
    } catch (error, stackTrace) {
      debugPrint('Course evidence skipped for $kind:$contentId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<CourseUpdate?> recordScenarioCheckpoint(
    String scenarioId, {
    required int passed,
    required int total,
    CoursePracticeContext? courseContext,
  }) async {
    try {
      final score = scenarioCheckpointScore(passed: passed, total: total);
      final override = recordScenarioCheckpointForTesting;
      final update = override != null
          ? await override(scenarioId, score, courseContext)
          : await CourseProgressService.shared.recordScenarioCheckpoint(
              scenarioId,
              score,
              courseContext: courseContext,
            );
      final latestCheckpoint = update.snapshot.scenarioCheckpoints.isEmpty
          ? null
          : update.snapshot.scenarioCheckpoints.last;
      if (score >= .7 &&
          latestCheckpoint?.scenarioId == scenarioId &&
          latestCheckpoint?.courseEligible == true &&
          latestCheckpoint?.missionContentLinkId != null &&
          GyeWeeklyPromises.byScenarioId(scenarioId) != null) {
        _scheduleLifePromiseProjectionSync();
      }
      return update;
    } catch (error, stackTrace) {
      debugPrint('Course checkpoint skipped for $scenarioId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// A scenario result already writes its local course evidence before this
  /// request. This best-effort backup only mirrors that evidence to the
  /// existing account-root sync channel; it never writes a Gye aggregate from
  /// the client. The server later re-checks course eligibility before credit.
  static void _scheduleLifePromiseProjectionSync() {
    final override = lifePromiseProjectionSyncForTesting;
    unawaited(
      (override != null ? override() : _backupCourseEvidence()).then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Gye life-promise sync skipped: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      ),
    );
  }

  static Future<void> _backupCourseEvidence() async {
    await CloudSync.backupWithResult();
  }
}
