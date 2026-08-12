import 'course_mastery.dart';
import 'curriculum.dart';
import 'hanok_stage.dart';

/// A read-only explanation of a persisted scenario checkpoint. It deliberately
/// cannot create or modify course evidence; callers must provide the snapshot
/// returned after the existing checkpoint write has completed.
enum ScenarioCanDoStatus { verified, reviewNeeded, practiceOnly }

class ScenarioCanDoResult {
  const ScenarioCanDoResult({
    required this.status,
    required this.score,
    this.courseUnit,
    this.structureStageBefore,
    this.structureStageAfter,
  });

  final ScenarioCanDoStatus status;
  final double score;
  final CourseUnit? courseUnit;
  final HanokStage? structureStageBefore;
  final HanokStage? structureStageAfter;

  bool get isVerified => status == ScenarioCanDoStatus.verified;
  bool get hasStructureEvidence =>
      structureStageBefore != null && structureStageAfter != null;
  bool get hasStructureChange =>
      hasStructureEvidence &&
      structureStageAfter!.ordinal > structureStageBefore!.ordinal;

  /// Revalidates the latest saved checkpoint against the current unit data.
  /// An absent write produces no result instead of an optimistic UI claim.
  static ScenarioCanDoResult? fromSnapshot({
    required CourseMasterySnapshot snapshot,
    required String scenarioId,
    required Iterable<CourseUnit> courseUnits,
    required Iterable<ContentLink> contentLinks,
    HanokStage? structureStageBefore,
    HanokStage? structureStageAfter,
  }) {
    final normalizedScenarioId = scenarioId.trim();
    if (normalizedScenarioId.isEmpty) return null;

    ScenarioCheckpointEvidence? latest;
    for (final checkpoint in snapshot.scenarioCheckpoints) {
      if (checkpoint.scenarioId != normalizedScenarioId) continue;
      if (latest == null || checkpoint.occurredAt.isAfter(latest.occurredAt)) {
        latest = checkpoint;
      }
    }
    final checkpoint = latest;
    if (checkpoint == null) return null;

    if (!checkpoint.courseEligible ||
        checkpoint.missionContentLinkId == null ||
        checkpoint.courseUnitId == null) {
      return ScenarioCanDoResult(
        status: ScenarioCanDoStatus.practiceOnly,
        score: checkpoint.score,
        structureStageBefore: structureStageBefore,
        structureStageAfter: structureStageAfter,
      );
    }

    final unit = courseUnits.cast<CourseUnit?>().firstWhere(
      (item) => item?.id == checkpoint.courseUnitId,
      orElse: () => null,
    );
    final hasExactAssessment =
        unit != null &&
        unit.checkpointContentIds.contains('scenario:$normalizedScenarioId') &&
        contentLinks.any(
          (link) =>
              link.id == checkpoint.missionContentLinkId &&
              link.contentKind == CurriculumContentKind.scenario &&
              link.contentId == normalizedScenarioId &&
              link.courseUnitId == unit.id &&
              link.exactlyAssesses(unit),
        );
    if (!hasExactAssessment) {
      return ScenarioCanDoResult(
        status: ScenarioCanDoStatus.practiceOnly,
        score: checkpoint.score,
        structureStageBefore: structureStageBefore,
        structureStageAfter: structureStageAfter,
      );
    }

    return ScenarioCanDoResult(
      status: checkpoint.score >= unit.passThreshold
          ? ScenarioCanDoStatus.verified
          : ScenarioCanDoStatus.reviewNeeded,
      score: checkpoint.score,
      courseUnit: unit,
      structureStageBefore: structureStageBefore,
      structureStageAfter: structureStageAfter,
    );
  }
}
