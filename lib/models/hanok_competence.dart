import 'course_mastery.dart';
import 'curriculum.dart';
import 'hanok_stage.dart';

/// Read-only structural evidence for the personal Hanok.
///
/// A completed course unit is the existing engine's durable proof that every
/// required concept and declared scenario checkpoint passed independently.
/// In particular, a scenario checkpoint needs its own configured threshold
/// (70% in the current curriculum). Browsed lessons, pack clears, placement
/// bypasses, decorations, and raw checkpoint history never appear here.
class HanokCompetenceProjection {
  const HanokCompetenceProjection._({
    required this.a1Ratio,
    required this.a2Ratio,
    required this.b1Ratio,
    required this.b2Ratio,
    required this.completedUnitCount,
    required this.totalUnitCount,
    required this.stage,
  });

  const HanokCompetenceProjection.empty()
    : a1Ratio = 0,
      a2Ratio = 0,
      b1Ratio = 0,
      b2Ratio = 0,
      completedUnitCount = 0,
      totalUnitCount = 0,
      stage = HanokStage.empty;

  final double a1Ratio;
  final double a2Ratio;
  final double b1Ratio;
  final double b2Ratio;
  final int completedUnitCount;
  final int totalUnitCount;

  /// The stage supported by course-unit completion alone. It is deliberately
  /// separate from the legacy pack-derived [HanokStage].
  final HanokStage stage;

  bool get hasVerifiedStructure => completedUnitCount > 0;

  /// Creates a projection only from current catalog units and completed
  /// course-unit ids. A bypass is an onboarding placement choice, not a
  /// claimed ability, and unknown or duplicate ids are ignored.
  factory HanokCompetenceProjection.fromSnapshot({
    required CourseMasterySnapshot snapshot,
    required Iterable<CourseUnit> courseUnits,
  }) {
    const levels = <String>{'a1', 'a2', 'b1', 'b2'};
    final unitsById = <String, CourseUnit>{
      for (final unit in courseUnits)
        if (levels.contains(unit.level) && unit.id.isNotEmpty) unit.id: unit,
    };
    final totals = <String, int>{for (final level in levels) level: 0};
    for (final unit in unitsById.values) {
      totals[unit.level] = totals[unit.level]! + 1;
    }

    final bypassed = snapshot.bypassedPrerequisiteUnitIds.toSet();
    final completedByLevel = <String, int>{
      for (final level in levels) level: 0,
    };
    final countedIds = <String>{};
    for (final id in snapshot.completedUnitIds) {
      if (!countedIds.add(id) || bypassed.contains(id)) continue;
      final unit = unitsById[id];
      if (unit == null) continue;
      completedByLevel[unit.level] = completedByLevel[unit.level]! + 1;
    }

    double ratio(String level) {
      final total = totals[level] ?? 0;
      if (total == 0) return 0;
      return (completedByLevel[level]! / total).clamp(0.0, 1.0);
    }

    final a1 = ratio('a1');
    final a2 = ratio('a2');
    final b1 = ratio('b1');
    final b2 = ratio('b2');
    return HanokCompetenceProjection._(
      a1Ratio: a1,
      a2Ratio: a2,
      b1Ratio: b1,
      b2Ratio: b2,
      completedUnitCount: completedByLevel.values.fold(0, (a, b) => a + b),
      totalUnitCount: totals.values.fold(0, (a, b) => a + b),
      stage: computeStage(a1Ratio: a1, a2Ratio: a2, b1Ratio: b1, b2Ratio: b2),
    );
  }
}
