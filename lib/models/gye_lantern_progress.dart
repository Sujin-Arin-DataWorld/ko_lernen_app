import 'gye.dart';

/// Read-only values for the shared-courtyard illustration.
///
/// These values describe either the legacy pack goal or a server-projected
/// life-situation promise. They do not expose individual answers, scores,
/// mastery, XP, or rankings.
class GyeLanternProgress {
  const GyeLanternProgress({
    required this.permanentElementCount,
    required this.weeklyFraction,
    required this.hasWeeklyGoal,
  });

  final int permanentElementCount;
  final double weeklyFraction;
  final bool hasWeeklyGoal;

  factory GyeLanternProgress.fromMeta(
    GyeMeta meta, {
    required int elementCount,
  }) {
    final usesPromise =
        meta.weeklyPromiseSchemaVersion == 1 &&
        meta.weeklyPromiseId.isNotEmpty &&
        meta.weeklyPromiseTarget > 0;
    final target = usesPromise
        ? meta.weeklyPromiseTarget
        : meta.weeklyGoalPacks;
    final progress = usesPromise
        ? meta.weeklyPromiseProgress
        : meta.weeklyGoalProgress;
    final hasWeeklyGoal = target > 0;
    return GyeLanternProgress(
      permanentElementCount: (1 + meta.lifetimeGoalsAchieved).clamp(
        1,
        elementCount,
      ),
      weeklyFraction: hasWeeklyGoal ? (progress / target).clamp(0.0, 1.0) : 0.0,
      hasWeeklyGoal: hasWeeklyGoal,
    );
  }
}
