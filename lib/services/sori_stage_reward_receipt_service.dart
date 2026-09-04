import 'dart:async';

import '../models/quest.dart';
import '../models/sori_stage_progression.dart';
import 'sori_stage_progression_service.dart';
import 'today_learning_snapshot.dart';

/// Compares two read-only progression snapshots after an activity returns.
///
/// A reward contract is a promise before learning. This service is deliberately
/// independent of that promise: only a positive delta observed in persisted
/// progression may be rendered as an earned reward.
abstract final class SoriStageRewardReceiptService {
  /// Opens learning even when progress measurement is unavailable.
  ///
  /// This fail-open boundary keeps a diagnostic/reward surface from becoming
  /// an entitlement gate. A receipt is returned only after both snapshots can
  /// be read and a concrete positive delta exists.
  static Future<RewardReceipt?> capture({
    required String activityId,
    required Future<SoriStageProgressionSnapshot> Function() loadSnapshot,
    required Future<void> Function() openActivity,
    SoriStageLocalBeforeFields Function()? captureLocalBefore,
    Future<SoriStageNetworkBeforeFields> Function()? loadNetworkBefore,
  }) async {
    final captureLocal =
        captureLocalBefore ?? SoriStageProgressionService.captureLocalBeforeFields;
    final loadNetwork =
        loadNetworkBefore ?? SoriStageProgressionService.loadNetworkBeforeFields;

    SoriStageLocalBeforeFields local;
    Future<SoriStageNetworkBeforeFields> networkFuture;
    try {
      // §검수#7: 로컬 필드는 openActivity() 호출 바로 앞, 같은 동기 실행
      // 구간 안에서 읽는다 — 사이에 await 이 없어 다른 코드가 끼어들 여지가
      // 없다. 네트워크 조회는 여기서 "시작만" 하고 기다리지 않는다.
      local = captureLocal();
      networkFuture = loadNetwork();
      // §정리#1: openActivity() 가 돌아올 때까지(수 분 뒤일 수 있음) 이
      // future 는 여기서 await 되지 않는다 — 그 사이 실패하면 아무도 안 듣는
      // 채로 Dart 가 루트 존에 미청취 비동기 에러를 보고한다. 지금 바로
      // no-op 리스너를 붙여 "청취됨" 상태로 만든다 — Future 는 리스너를
      // 여러 개 가질 수 있어, 실제 값/에러는 그대로 networkFuture 에 남고
      // 아래 await 지점에서 기존과 동일하게 catch 돼 fail-open(null) 으로
      // 이어진다(동작 불변).
      unawaited(networkFuture.then<void>((_) {}, onError: (_) {}));
    } catch (_) {
      await openActivity();
      return null;
    }

    await openActivity();

    try {
      final network = await networkFuture;
      final before = SoriStageProgressionSnapshot(
        today: const TodayLearningSnapshot(pick: null),
        hanok: network.hanok,
        quests: network.quests,
        pendingBojagiCount: local.pendingBojagiCount,
        stampCount: local.stamps,
        xp: local.xp,
        streakDays: local.streakDays,
        todayReward: null,
        gameBests: local.gameBests,
        gyeLanternCount: network.gyeLanternCount,
      );
      final receipt = compare(
        activityId: activityId,
        before: before,
        after: await loadSnapshot(),
      );
      return receipt.isEmpty ? null : receipt;
    } catch (_) {
      return null;
    }
  }

  static RewardReceipt compare({
    required String activityId,
    required SoriStageProgressionSnapshot before,
    required SoriStageProgressionSnapshot after,
    String? receiptId,
  }) {
    final items = <RewardReceiptItem>[];
    _appendDelta(
      items,
      kind: SoriRewardKind.xp,
      delta: after.xp - before.xp,
      label: const SoriLocalizedCopy(
        de: 'Lern-XP',
        en: 'XP',
        key: SoriCopyKey.rewardXp,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.stamp,
      delta: after.stampCount - before.stampCount,
      label: const SoriLocalizedCopy(
        de: 'Dojang-Stempel',
        en: 'Dojang stamp',
        key: SoriCopyKey.rewardStamp,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.questProgress,
      delta: _questDelta(before.quests, after.quests),
      label: const SoriLocalizedCopy(
        de: 'Quest-Fortschritt',
        en: 'Quest progress',
        key: SoriCopyKey.rewardQuestProgress,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.hanokProgress,
      delta: after.hanok.unlocked.length - before.hanok.unlocked.length,
      label: const SoriLocalizedCopy(
        de: 'Neues Hanok-Bauteil',
        en: 'New Hanok building piece',
        key: SoriCopyKey.rewardHanokPiece,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.bojagi,
      delta: after.pendingBojagiCount - before.pendingBojagiCount,
      label: const SoriLocalizedCopy(
        de: 'Bojagi',
        en: 'Bojagi',
        key: SoriCopyKey.rewardBojagi,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.personalBest,
      delta: _personalBestDelta(before.gameBests, after.gameBests),
      label: const SoriLocalizedCopy(
        de: 'Persönliche Bestleistung',
        en: 'Personal best',
        key: SoriCopyKey.rewardBest,
      ),
    );
    _appendDelta(
      items,
      kind: SoriRewardKind.gyeLantern,
      delta: after.gyeLanternCount - before.gyeLanternCount,
      label: const SoriLocalizedCopy(
        de: 'Gye-Laterne',
        en: 'Gye lantern',
        key: SoriCopyKey.rewardGyeLantern,
      ),
    );
    final stableId = receiptId ?? _stableReceiptId(activityId, before, after);
    return RewardReceipt(
      activityId: activityId,
      receiptId: stableId,
      items: List.unmodifiable(items),
    );
  }

  static int _questDelta(
    List<QuestProgress> before,
    List<QuestProgress> after,
  ) {
    final previous = <String, int>{
      for (final quest in before) quest.questId: quest.current,
    };
    var delta = 0;
    for (final quest in after) {
      final oldValue = previous[quest.questId];
      if (oldValue == null) {
        continue;
      }
      final increase = quest.current - oldValue;
      if (increase > 0) {
        delta += increase;
      }
    }
    return delta;
  }

  static int _personalBestDelta(
    Map<String, int> before,
    Map<String, int> after,
  ) {
    var improved = 0;
    for (final entry in after.entries) {
      final previous = before[entry.key] ?? 0;
      if (entry.value > previous) {
        improved++;
      }
    }
    return improved;
  }

  static String _stableReceiptId(
    String activityId,
    SoriStageProgressionSnapshot before,
    SoriStageProgressionSnapshot after,
  ) {
    final fingerprint = <Object?>[
      activityId,
      before.xp,
      after.xp,
      before.stampCount,
      after.stampCount,
      before.pendingBojagiCount,
      after.pendingBojagiCount,
      before.gyeLanternCount,
      after.gyeLanternCount,
      ...after.quests.map((quest) => '${quest.questId}:${quest.current}'),
      ...after.gameBests.entries.map((entry) => '${entry.key}:${entry.value}'),
    ].join('|');
    var hash = 0x811c9dc5;
    for (final byte in fingerprint.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '$activityId-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static void _appendDelta(
    List<RewardReceiptItem> items, {
    required SoriRewardKind kind,
    required int delta,
    required SoriLocalizedCopy label,
  }) {
    if (delta <= 0) {
      return;
    }
    items.add(RewardReceiptItem(kind: kind, label: label, amount: delta));
  }
}
