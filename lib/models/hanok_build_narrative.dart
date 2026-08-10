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
  const HanokBuildNarrative({
    required this.projection,
    this.verifiedUnit,
    this.nextUnit,
  });

  final PersonalHanokProjection projection;
  final CourseUnit? verifiedUnit;
  final CourseUnit? nextUnit;

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
  }) {
    final units = courseUnits.toList(growable: false);
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

    return HanokBuildNarrative(
      projection: projection,
      verifiedUnit: completed.isEmpty ? null : completed.last,
      nextUnit: nextUnit,
    );
  }
}
