import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/gye_lantern_progress.dart';

GyeMeta _meta({
  int weeklyGoalPacks = 0,
  int weeklyGoalProgress = 0,
  int weeklyPromiseSchemaVersion = 0,
  String weeklyPromiseId = '',
  int weeklyPromiseTarget = 0,
  int weeklyPromiseProgress = 0,
  int lifetimeGoalsAchieved = 0,
  bool xpBoostActive = false,
  String lastWeekMvp = '',
}) => GyeMeta(
  id: 'ABC234',
  name: 'Moon courtyard',
  code: 'ABC234',
  ownerId: 'owner',
  weeklyGoalPacks: weeklyGoalPacks,
  weeklyGoalProgress: weeklyGoalProgress,
  weeklyPromiseSchemaVersion: weeklyPromiseSchemaVersion,
  weeklyPromiseId: weeklyPromiseId,
  weeklyPromiseTarget: weeklyPromiseTarget,
  weeklyPromiseProgress: weeklyPromiseProgress,
  lifetimeGoalsAchieved: lifetimeGoalsAchieved,
  xpBoostActive: xpBoostActive,
  lastWeekMvp: lastWeekMvp,
);

void main() {
  test('uses legacy weekly-goal fields for an unmigrated courtyard visual', () {
    final progress = GyeLanternProgress.fromMeta(
      _meta(
        weeklyGoalPacks: 5,
        weeklyGoalProgress: 3,
        lifetimeGoalsAchieved: 2,
        xpBoostActive: true,
        lastWeekMvp: 'Mina',
      ),
      elementCount: 8,
    );

    expect(progress.permanentElementCount, 3);
    expect(progress.weeklyFraction, 0.6);
    expect(progress.hasWeeklyGoal, isTrue);
  });

  test('prefers an anonymous weekly life-promise aggregate when available', () {
    final progress = GyeLanternProgress.fromMeta(
      _meta(
        weeklyGoalPacks: 10,
        weeklyGoalProgress: 9,
        weeklyPromiseSchemaVersion: 1,
        weeklyPromiseId: 'cafe_order',
        weeklyPromiseTarget: 3,
        weeklyPromiseProgress: 2,
      ),
      elementCount: 8,
    );

    expect(progress.weeklyFraction, closeTo(2 / 3, 0.0001));
    expect(progress.hasWeeklyGoal, isTrue);
  });

  test('does not activate an unversioned partial promise migration', () {
    final progress = GyeLanternProgress.fromMeta(
      _meta(
        weeklyGoalPacks: 5,
        weeklyGoalProgress: 2,
        weeklyPromiseId: 'cafe_order',
        weeklyPromiseTarget: 3,
        weeklyPromiseProgress: 3,
      ),
      elementCount: 8,
    );

    expect(progress.weeklyFraction, 0.4);
  });

  test('does not invent weekly progress when no goal is configured', () {
    final progress = GyeLanternProgress.fromMeta(
      _meta(weeklyGoalProgress: 99),
      elementCount: 8,
    );

    expect(progress.permanentElementCount, 1);
    expect(progress.weeklyFraction, 0);
    expect(progress.hasWeeklyGoal, isFalse);
  });

  test('clamps malformed remote counters to the visible courtyard bounds', () {
    final progress = GyeLanternProgress.fromMeta(
      _meta(
        weeklyGoalPacks: 2,
        weeklyGoalProgress: 20,
        lifetimeGoalsAchieved: 99,
      ),
      elementCount: 8,
    );

    expect(progress.permanentElementCount, 8);
    expect(progress.weeklyFraction, 1);
  });
}
