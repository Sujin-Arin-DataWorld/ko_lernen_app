import 'course_mastery.dart';
import 'curriculum.dart';
import 'personal_hanok.dart';

/// Read-only learning language for the existing personal Hanok projection.
///
/// The Hanok's visual stage remains a legacy pack-progress projection. A
/// verified can-do is intentionally derived separately from completed course
/// units, so neither a decoration nor a browsed lesson can become a false
/// statement of ability.
class HanokBuildNarrative {
  static const int defaultScenesPerBeam = 2;

  const HanokBuildNarrative({
    required this.projection,
    this.verifiedUnit,
    this.nextUnit,
    this.safeSceneCount = 0,
    this.safeScenesTowardNextBeam = 0,
    this.scenesPerBeam = defaultScenesPerBeam,
    this.plannedBeamCount = 0,
  });

  final PersonalHanokProjection projection;
  final CourseUnit? verifiedUnit;
  final CourseUnit? nextUnit;

  /// Distinct course checkpoints whose latest eligible result still passes
  /// the owning unit's threshold. Browse history and stale IDs never count.
  final int safeSceneCount;

  /// The visible 0..[scenesPerBeam] goal for the beam currently in the plan.
  final int safeScenesTowardNextBeam;

  final int scenesPerBeam;

  /// Beams represented in the construction plan. A started two-scene goal is
  /// visible as one planned beam; it is never used to unlock course content.
  final int plannedBeamCount;

  bool get hasVerifiedCanDo => verifiedUnit != null;

  bool get hasNextCanDo => nextUnit != null;

  factory HanokBuildNarrative.empty(PersonalHanokProjection projection) =>
      HanokBuildNarrative(projection: projection);

  /// Chooses the latest completed course unit and the currently active one.
  ///
  /// Bypassed placement prerequisites are never presented as completed
  /// abilities. Unknown, contradictory, or stale IDs quietly produce no
  /// can-do claim; validation remains owned by the course service.
  factory HanokBuildNarrative.fromSnapshot({
    required PersonalHanokProjection projection,
    required CourseMasterySnapshot snapshot,
    required Iterable<CourseUnit> courseUnits,
    Iterable<ContentLink> contentLinks = const <ContentLink>[],
    int scenesPerBeam = defaultScenesPerBeam,
  }) {
    assert(scenesPerBeam > 0);
    final units = courseUnits.toList(growable: false);
    final unitsById = <String, CourseUnit>{
      for (final unit in units) unit.id: unit,
    };
    final completedIds = snapshot.completedUnitIds.toSet();
    final bypassedIds = snapshot.bypassedPrerequisiteUnitIds.toSet();
    final completed =
        units
            .where((unit) => completedIds.contains(unit.id))
            .toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order));

    final currentId = snapshot.currentCourseUnitId;
    final nextUnit =
        currentId == null ||
            completedIds.contains(currentId) ||
            bypassedIds.contains(currentId)
        ? null
        : units.cast<CourseUnit?>().firstWhere(
            (unit) => unit?.id == currentId,
            orElse: () => null,
          );

    final assessSceneKeys = <String>{
      for (final link in contentLinks)
        if (link.contentKind == CurriculumContentKind.scenario &&
            link.role == ContentLinkRole.assess)
          '${link.courseUnitId}\u0000${link.contentId}',
    };
    final latestByScene = <String, ScenarioCheckpointEvidence>{};
    for (final checkpoint in snapshot.scenarioCheckpoints) {
      final unitId = checkpoint.courseUnitId;
      if (!checkpoint.courseEligible || unitId == null) {
        continue;
      }
      final unit = unitsById[unitId];
      final contentId = 'scenario:${checkpoint.scenarioId}';
      final key = '$unitId\u0000${checkpoint.scenarioId}';
      if (unit == null ||
          !unit.checkpointContentIds.contains(contentId) ||
          !assessSceneKeys.contains(key) ||
          !checkpoint.score.isFinite ||
          checkpoint.score < 0 ||
          checkpoint.score > 1) {
        continue;
      }
      final previous = latestByScene[key];
      if (previous == null ||
          checkpoint.occurredAt.isAfter(previous.occurredAt)) {
        latestByScene[key] = checkpoint;
      }
    }
    final safeSceneCount = latestByScene.values.where((checkpoint) {
      final unit = unitsById[checkpoint.courseUnitId];
      return unit != null && checkpoint.score >= unit.passThreshold;
    }).length;
    final normalizedScenesPerBeam = scenesPerBeam <= 0
        ? defaultScenesPerBeam
        : scenesPerBeam;
    final safeScenesTowardNextBeam = safeSceneCount == 0
        ? 0
        : ((safeSceneCount - 1) % normalizedScenesPerBeam) + 1;
    final plannedBeamCount = safeSceneCount == 0
        ? 0
        : ((safeSceneCount - 1) ~/ normalizedScenesPerBeam) + 1;

    return HanokBuildNarrative(
      projection: projection,
      verifiedUnit: completed.isEmpty ? null : completed.last,
      nextUnit: nextUnit,
      safeSceneCount: safeSceneCount,
      safeScenesTowardNextBeam: safeScenesTowardNextBeam,
      scenesPerBeam: normalizedScenesPerBeam,
      plannedBeamCount: plannedBeamCount,
    );
  }
}
