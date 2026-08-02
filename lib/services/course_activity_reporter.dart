import 'package:flutter/foundation.dart';

import '../models/curriculum.dart';
import '../models/scenario.dart';
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

  static Future<CourseUpdate?> recordContentAttempt(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect, {
    MasteryErrorReason? errorReason,
    String? conceptId,
  }) async {
    try {
      return await CourseProgressService.shared.recordContentAttempt(
        kind,
        contentId,
        isCorrect,
        conceptId: conceptId,
        errorReason: errorReason,
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
  }) async {
    try {
      return await CourseProgressService.shared.recordScenarioCheckpoint(
        scenarioId,
        scenarioCheckpointScore(passed: passed, total: total),
      );
    } catch (error, stackTrace) {
      debugPrint('Course checkpoint skipped for $scenarioId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
