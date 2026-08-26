import 'dart:async';

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

  test(
    'same persisted transition produces the same replay-safe receipt id',
    () {
      final before = _snapshot(xp: 10, gyeLanternCount: 1);
      final after = _snapshot(xp: 20, gyeLanternCount: 2);
      final first = SoriStageRewardReceiptService.compare(
        activityId: 'course',
        before: before,
        after: after,
      );
      final replay = SoriStageRewardReceiptService.compare(
        activityId: 'course',
        before: before,
        after: after,
      );
      expect(replay.receiptId, first.receiptId);
      expect(
        replay.items.map((item) => item.kind),
        contains(SoriRewardKind.gyeLantern),
      );
    },
  );

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

  SoriStageNetworkBeforeFields networkFields({
    List<QuestProgress> quests = const [],
    int gyeLanternCount = 0,
  }) => (
    quests: quests,
    hanok: PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    ),
    gyeLanternCount: gyeLanternCount,
  );

  SoriStageLocalBeforeFields localFields({int xp = 0}) => (
    xp: xp,
    stamps: 0,
    streakDays: 0,
    pendingBojagiCount: 0,
    gameBests: const <String, int>{},
  );

  test(
    'capture never blocks learning when local field capture fails (검수#7 fail-open)',
    () async {
      var opened = false;
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: 'course',
        captureLocalBefore: () =>
            throw StateError('local snapshot unavailable'),
        loadNetworkBefore: () async => networkFields(),
        loadSnapshot: () async => _snapshot(xp: 0),
        openActivity: () async => opened = true,
      );

      expect(opened, isTrue);
      expect(receipt, isNull);
    },
  );

  test('capture compares state only after the activity returns', () async {
    final receipt = await SoriStageRewardReceiptService.capture(
      activityId: 'review',
      captureLocalBefore: () => localFields(xp: 2),
      loadNetworkBefore: () async => networkFields(),
      openActivity: () async {},
      loadSnapshot: () async => _snapshot(xp: 14),
    );

    expect(receipt, isNotNull);
    expect(receipt!.items.single.amount, 12);
  });

  test(
    'local fields are captured synchronously before openActivity(); network '
    'fields are awaited only after the activity returns (검수#7 race, '
    'Completer 기반 — 기존 () async => state 고정 테스트는 이 순서를 못 잡았다)',
    () async {
      final events = <String>[];
      final networkCompleter = Completer<SoriStageNetworkBeforeFields>();

      final receiptFuture = SoriStageRewardReceiptService.capture(
        activityId: 'course',
        captureLocalBefore: () {
          events.add('local-captured');
          return localFields(xp: 10);
        },
        loadNetworkBefore: () {
          events.add('network-started');
          return networkCompleter.future;
        },
        openActivity: () async {
          events.add('activity-opened');
        },
        loadSnapshot: () async {
          events.add('after-loaded');
          return _snapshot(xp: 30);
        },
      );

      // openActivity() 는 이미 실행됐고 network future 는 아직 안 끝났다 —
      // capture() 가 완료를 기다리지 않고 "병행" 시작했다는 증거.
      await Future<void>.delayed(Duration.zero);
      expect(events, ['local-captured', 'network-started', 'activity-opened']);

      networkCompleter.complete(networkFields());
      final receipt = await receiptFuture;

      expect(events.last, 'after-loaded');
      expect(receipt, isNotNull);
      expect(receipt!.items.single.amount, 20);
    },
  );
}

SoriStageProgressionSnapshot _snapshot({
  int xp = 0,
  int stamps = 0,
  int bojagi = 0,
  int gyeLanternCount = 0,
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
  gyeLanternCount: gyeLanternCount,
);
