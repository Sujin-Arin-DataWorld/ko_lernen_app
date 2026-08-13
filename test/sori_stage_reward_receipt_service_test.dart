import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/sori_stage_reward_receipt_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  test('receipt contains only positive changes observed after an activity', () {
    final before = _snapshot(
      xp: 100,
      stamps: 2,
      bojagi: 0,
      ratios: const LevelRatios(a1: 1, a2: 1, b1: .24, b2: 0),
      questCurrent: 3,
    );
    final after = _snapshot(
      xp: 120,
      stamps: 3,
      bojagi: 1,
      ratios: const LevelRatios(a1: 1, a2: 1, b1: .25, b2: 0),
      questCurrent: 4,
    );

    final receipt = SoriStageRewardReceiptService.compare(
      activityId: 'course',
      before: before,
      after: after,
    );

    expect(receipt.items.map((item) => item.kind), <SoriRewardKind>[
      SoriRewardKind.xp,
      SoriRewardKind.stamp,
      SoriRewardKind.questProgress,
      SoriRewardKind.hanokProgress,
      SoriRewardKind.bojagi,
    ]);
    expect(receipt.items.map((item) => item.amount), <int?>[20, 1, 1, 1, 1]);
  });

  test('unchanged, reduced, and already completed state yields no receipt', () {
    final before = _snapshot(
      xp: 120,
      stamps: 3,
      bojagi: 1,
      ratios: const LevelRatios(a1: 1, a2: 1, b1: .25, b2: 0),
      questCurrent: 4,
    );
    final after = _snapshot(
      xp: 110,
      stamps: 2,
      bojagi: 0,
      ratios: const LevelRatios(a1: 1, a2: 1, b1: .24, b2: 0),
      questCurrent: 3,
    );

    final receipt = SoriStageRewardReceiptService.compare(
      activityId: 'course',
      before: before,
      after: after,
    );

    expect(receipt.isEmpty, isTrue);
  });

  test(
    'quest delta is matched by id and ignores newly visible old progress',
    () {
      final before = _snapshot(questCurrent: 2);
      final after = _snapshot(
        questCurrent: 4,
        extraQuest: const QuestProgress(
          questId: 'seasonal-old-progress',
          current: 8,
          target: 10,
          active: true,
          completed: false,
          completedAtIso: null,
        ),
      );

      final receipt = SoriStageRewardReceiptService.compare(
        activityId: 'review',
        before: before,
        after: after,
      );

      expect(
        receipt.items
            .singleWhere((item) => item.kind == SoriRewardKind.questProgress)
            .amount,
        2,
      );
    },
  );

  test(
    'capture never blocks learning when the before snapshot fails',
    () async {
      var opened = false;
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: 'course',
        loadSnapshot: () => throw StateError('local snapshot unavailable'),
        openActivity: () async => opened = true,
      );

      expect(opened, isTrue);
      expect(receipt, isNull);
    },
  );

  test('capture compares state only after the activity returns', () async {
    var state = _snapshot(xp: 2);
    final receipt = await SoriStageRewardReceiptService.capture(
      activityId: 'review',
      loadSnapshot: () async => state,
      openActivity: () async => state = _snapshot(xp: 14),
    );

    expect(receipt, isNotNull);
    expect(receipt!.items.single.amount, 12);
  });
}

SoriStageProgressionSnapshot _snapshot({
  int xp = 0,
  int stamps = 0,
  int bojagi = 0,
  LevelRatios ratios = const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  int questCurrent = 0,
  QuestProgress? extraQuest,
}) => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(pick: null),
  hanok: PersonalHanokProjection.from(ratios),
  quests: <QuestProgress>[
    QuestProgress(
      questId: 'tracked',
      current: questCurrent,
      target: 10,
      active: true,
      completed: questCurrent >= 10,
      completedAtIso: null,
    ),
    if (extraQuest != null) extraQuest,
  ],
  pendingBojagiCount: bojagi,
  stampCount: stamps,
  xp: xp,
  streakDays: 0,
  todayReward: null,
);
