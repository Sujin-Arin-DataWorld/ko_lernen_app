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

  /// Derives the Gye tab's 3-step flow indicator's current step
  /// (§W-G G1.3 / W-G2 item 1) from the caller's own memberships.
  ///
  /// Returns **1** ("lantern earned") as soon as any [metas] entry has
  /// reached its weekly goal this week (`hasWeeklyGoal &&
  /// weeklyFraction >= 1`); **0** ("mission") otherwise, including an
  /// empty list or a list where every membership is still mid-goal.
  ///
  /// Step **2** ("shared hanok" growing) is never returned by this
  /// function: nothing in [GyeMeta] records *when* a weekly goal was last
  /// completed, only the running `lifetimeGoalsAchieved` count, so there is
  /// no field that distinguishes "just reached the goal this week" from
  /// "the shared hanok has been growing for a while". The flow visual
  /// still draws all three steps to narrate what comes next — it just
  /// cannot yet tell the UI that step 2 is the *current* one.
  static int currentStepFor(
    Iterable<GyeMeta> metas, {
    required int elementCount,
  }) {
    for (final meta in metas) {
      final progress = GyeLanternProgress.fromMeta(
        meta,
        elementCount: elementCount,
      );
      if (progress.hasWeeklyGoal && progress.weeklyFraction >= 1) {
        return 1;
      }
    }
    return 0;
  }
}
