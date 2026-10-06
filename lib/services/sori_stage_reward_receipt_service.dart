import 'dart:async';
import '../models/quest.dart';
import '../models/sori_stage_progression.dart';
import '../models/yeopjeon_reward_moment.dart';
import '../models/yeopjeon_wallet.dart';
import 'local_data_lifetime.dart';
import 'diagnostics_service.dart';
import 'sori_stage_progression_service.dart';
import 'storage_service.dart';
import 'today_learning_snapshot.dart';
import 'yeopjeon_learning_checkpoint.dart';

/// Compares two read-only progression snapshots after an activity returns.
///
/// A reward contract is a promise before learning. This service is deliberately
/// independent of that promise: only a positive delta observed in persisted
/// progression may be rendered as an earned reward.
abstract final class SoriStageRewardReceiptService {
  /// Opens learning even when progress measurement is unavailable.
  ///
  /// This fail-open boundary keeps a diagnostic/reward surface from becoming
  /// an entitlement gate. Aggregate deltas need both snapshots; independently
  /// confirmed ledger results and pending verification survive optional read failures.
  static Future<RewardReceipt?> capture({
    required String activityId,
    required Future<SoriStageProgressionSnapshot> Function() loadSnapshot,
    required Future<void> Function() openActivity,
    Duration measurementTimeout = const Duration(seconds: 5),
    SoriStageLocalBeforeFields Function()? captureLocalBefore,
    Future<SoriStageNetworkBeforeFields> Function()? loadNetworkBefore,
    Future<YeopjeonLearningCheckpoint> Function()? captureCheckpoint,
    List<YeopjeonRewardMoment> Function()? confirmedRewardMoments,
    List<YeopjeonPendingReward> Function()? pendingRewardMoments,
  }) async {
    final lifetime = LocalDataLifetime.capture();
    final captureLocal =
        captureLocalBefore ??
        SoriStageProgressionService.captureLocalBeforeFields;
    final loadNetwork =
        loadNetworkBefore ??
        SoriStageProgressionService.loadNetworkBeforeFields;

    // Start the durable money baseline before navigation without awaiting it.
    // A stalled optional reward read must never block the learning route.
    final checkpointFuture =
        Future<YeopjeonLearningCheckpoint>.sync(
              captureCheckpoint ?? YeopjeonLearningCheckpoint.capture,
            )
            .timeout(measurementTimeout)
            .then<YeopjeonLearningCheckpoint?>(
              (value) => value,
              onError: (Object error, StackTrace stack) {
                unawaited(
                  DiagnosticsService.reportSwallowed(
                    'yeopjeon.checkpoint',
                    StateError(error.runtimeType.toString()),
                    stack,
                  ),
                );
                return null;
              },
            );
    Set<String>? stampIds;
    SoriStageLocalBeforeFields? local;
    Future<SoriStageNetworkBeforeFields>? networkFuture;
    try {
      // §검수#7: 로컬 필드는 openActivity() 호출 바로 앞, 같은 동기 실행
      // 구간 안에서 읽는다 — 사이에 await 이 없어 다른 코드가 끼어들 여지가
      // 없다. 네트워크 조회는 여기서 "시작만" 하고 기다리지 않는다.
      local = captureLocal();
      try {
        stampIds = Storage.earnedStamps.toSet();
      } catch (_) {
        /* unavailable provenance */
      }
      networkFuture = loadNetwork().timeout(measurementTimeout);
      // §정리#1: openActivity() 가 돌아올 때까지(수 분 뒤일 수 있음) 이
      // future 는 여기서 await 되지 않는다 — 그 사이 실패하면 아무도 안 듣는
      // 채로 Dart 가 루트 존에 미청취 비동기 에러를 보고한다. 지금 바로
      // no-op 리스너를 붙여 "청취됨" 상태로 만든다 — Future 는 리스너를
      // 여러 개 가질 수 있어, 실제 값/에러는 그대로 networkFuture 에 남고
      // 아래 await 지점에서 기존과 동일하게 catch 돼 fail-open(null) 으로
      // 이어진다(동작 불변).
      unawaited(networkFuture.then<void>((_) {}, onError: (_) {}));
    } catch (_) {
      // Optional aggregate fields cannot suppress a separately confirmed coin.
      local = null;
    }

    await openActivity();
    YeopjeonLearningCheckpoint? checkpoint;
    YeopjeonWallet? settledWallet;
    List<YeopjeonRewardMoment> moments = const [];
    List<YeopjeonPendingReward> pendingMoments = const [];
    YeopjeonPendingReward? pending;
    try {
      lifetime.assertCurrent();
      checkpoint = await checkpointFuture;
      try {
        settledWallet = await checkpoint?.settle().timeout(measurementTimeout);
      } catch (error, stack) {
        unawaited(
          DiagnosticsService.reportSwallowed(
            'yeopjeon.settle',
            StateError(error.runtimeType.toString()),
            stack,
          ),
        );
      }
      lifetime.assertCurrent();
      moments = [...?checkpoint?.rewardMoments];
      pendingMoments = [if (checkpoint?.pendingReward case final value?) value];
      try {
        moments = [...?confirmedRewardMoments?.call(), ...moments];
      } catch (_) {
        /* Independently confirmed checkpoint results remain available. */
      }
      try {
        pendingMoments = [...pendingMoments, ...?pendingRewardMoments?.call()];
      } catch (_) {
        /* Independently captured pending sources remain available. */
      }
      moments = [
        ...moments,
        ..._pendingReadbackMoments(pendingMoments, settledWallet),
      ];
      pending = _mergePending(pendingMoments, settledWallet);
      final network = await networkFuture;
      final confirmedLocal = local;
      if (network == null || confirmedLocal == null) {
        return _confirmedMoneyReceipt(
          activityId,
          moments,
          checkpoint,
          settledWallet,
          pending,
        );
      }
      final before = SoriStageProgressionSnapshot(
        wallet: checkpoint?.wallet,
        today: const TodayLearningSnapshot(pick: null),
        hanokCompetence: network.hanokCompetence,
        quests: network.quests,
        pendingBojagiCount: confirmedLocal.pendingBojagiCount,
        stampCount: confirmedLocal.stamps,
        stampIds: stampIds,
        xp: confirmedLocal.xp,
        streakDays: confirmedLocal.streakDays,
        todayReward: null,
        gameBests: confirmedLocal.gameBests,
        gyeLanternCount: network.gyeLanternCount,
      );
      final after = await loadSnapshot().timeout(measurementTimeout);
      lifetime.assertCurrent();
      moments = [
        ...moments,
        ..._pendingReadbackMoments(pendingMoments, after.wallet),
      ];
      pending = _mergePending(pendingMoments, after.wallet ?? settledWallet);
      var receipt = compare(
        activityId: activityId,
        before: before,
        after: after,
        confirmedRewardMoments: moments,
        pendingYeopjeon: pending,
      );
      // An unavailable money baseline has no authority to infer deltas. Actual
      // native transaction results still have their independent confirmation.
      if ((checkpoint == null || after.wallet == null) && moments.isNotEmpty) {
        final money = _confirmedMoneyReceipt(
          activityId,
          moments,
          null,
          settledWallet,
          pending,
        )!;
        receipt = RewardReceipt(
          activityId: receipt.activityId,
          receiptId: receipt.receiptId,
          items: List.unmodifiable([...receipt.items, ...money.items]),
          yeopjeonReward: money.yeopjeonReward,
          pendingYeopjeon: receipt.pendingYeopjeon,
          sarangchaeStageBefore: receipt.sarangchaeStageBefore,
          sarangchaeStageAfter: receipt.sarangchaeStageAfter,
          b2ConstructionStageBefore: receipt.b2ConstructionStageBefore,
          b2ConstructionStageAfter: receipt.b2ConstructionStageAfter,
        );
      }
      return receipt.isEmpty ? null : receipt;
    } catch (_) {
      if (!lifetime.isCurrent) {
        return null;
      }
      return _confirmedMoneyReceipt(
        activityId,
        moments,
        checkpoint,
        settledWallet,
        pending,
      );
    }
  }

  static RewardReceipt? _confirmedMoneyReceipt(
    String activityId,
    List<YeopjeonRewardMoment> moments,
    YeopjeonLearningCheckpoint? checkpoint,
    YeopjeonWallet? settledWallet,
    YeopjeonPendingReward? pending,
  ) {
    final claims = <String, int>{
      for (final moment in moments)
        for (final entry in moment.claims.entries)
          if (entry.value > 0 &&
              !(checkpoint?.wallet.claims.containsKey(entry.key) ?? false))
            entry.key: entry.value,
    };
    if (claims.isEmpty && pending == null) {
      return null;
    }
    final first = moments
        .where(
          (m) => m.playMintVideo && claims.containsKey('daily:${m.day}:first'),
        )
        .firstOrNull;
    final moment = claims.isEmpty
        ? null
        : YeopjeonRewardMoment(
            claims: claims,
            balance: settledWallet?.balance ?? moments.last.balance,
            source: first?.source ?? YeopjeonRewardSource.recovery,
            day: first?.day ?? moments.last.day,
          );
    return RewardReceipt(
      activityId: activityId,
      receiptId:
          'money:$activityId:${claims.keys.join('|')}:'
          '${pending?.sourceIds.join('|') ?? ''}',
      pendingYeopjeon: pending,
      yeopjeonReward: moment,
      items: List.unmodifiable([
        for (final entry in claims.entries)
          RewardReceiptItem(
            kind: SoriRewardKind.yeopjeon,
            identity: entry.key,
            amount: entry.value,
            label: const SoriLocalizedCopy(
              de: 'Yeopjeon',
              en: 'Yeopjeon',
              key: SoriCopyKey.rewardYeopjeon,
            ),
          ),
      ]),
    );
  }

  static YeopjeonPendingReward? _mergePending(
    List<YeopjeonPendingReward> pending,
    YeopjeonWallet? verifiedWallet,
  ) {
    final sources = {for (final value in pending) ...value.sourceIds}
      ..removeAll(verifiedWallet?.completedSourceIds ?? const {});
    if (sources.isEmpty) {
      return null;
    }
    Set<String>? baseline;
    for (final value in pending) {
      if (value.hasClaimBaseline) {
        baseline = baseline == null
            ? value.baselineClaimIds.toSet()
            : baseline.intersection(value.baselineClaimIds);
      }
    }
    return YeopjeonPendingReward(
      sourceIds: sources,
      baselineClaimIds: baseline ?? const {},
      hasClaimBaseline: baseline != null,
    );
  }

  static List<YeopjeonRewardMoment> _pendingReadbackMoments(
    List<YeopjeonPendingReward> pending,
    YeopjeonWallet? verifiedWallet,
  ) {
    if (verifiedWallet == null) {
      return const [];
    }
    final claims = <String, int>{};
    for (final value in pending) {
      if (!value.hasClaimBaseline ||
          !value.sourceIds.any(verifiedWallet.completedSourceIds.contains)) {
        continue;
      }
      for (final entry in verifiedWallet.claims.entries) {
        if (entry.value > 0 && !value.baselineClaimIds.contains(entry.key)) {
          claims[entry.key] = entry.value;
        }
      }
    }
    if (claims.isEmpty) {
      return const [];
    }
    return [
      YeopjeonRewardMoment(
        claims: claims,
        balance: verifiedWallet.balance,
        source: YeopjeonRewardSource.recovery,
        day: YeopjeonRewardMoment.dayKey(DateTime.now()),
      ),
    ];
  }

  static RewardReceipt compare({
    required String activityId,
    required SoriStageProgressionSnapshot before,
    required SoriStageProgressionSnapshot after,
    String? receiptId,
    List<YeopjeonRewardMoment> confirmedRewardMoments = const [],
    YeopjeonPendingReward? pendingYeopjeon,
  }) {
    final items = <RewardReceiptItem>[];
    final beforeWallet = before.wallet;
    final afterWallet = after.wallet;
    if (beforeWallet != null && afterWallet != null) {
      for (final claim in afterWallet.claims.entries) {
        if (!beforeWallet.claims.containsKey(claim.key) && claim.value > 0) {
          items.add(
            RewardReceiptItem(
              kind: SoriRewardKind.yeopjeon,
              identity: claim.key,
              amount: claim.value,
              label: const SoriLocalizedCopy(
                de: 'Yeopjeon',
                en: 'Yeopjeon',
                key: SoriCopyKey.rewardYeopjeon,
              ),
            ),
          );
        }
      }
    }
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
    if (before.stampIds != null && after.stampIds != null) {
      for (final id in after.stampIds!.difference(before.stampIds!)) {
        items.add(
          RewardReceiptItem(
            kind: SoriRewardKind.stamp,
            amount: 1,
            identity: id,
            label: const SoriLocalizedCopy(
              de: 'Dojang-Stempel',
              en: 'Dojang stamp',
              key: SoriCopyKey.rewardStamp,
            ),
          ),
        );
      }
    } else {
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
    }
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
      delta: after.ownedSarangchaeStage - before.ownedSarangchaeStage,
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
    for (final entry in after.gameBests.entries) {
      if (entry.value > (before.gameBests[entry.key] ?? 0)) {
        items.add(
          RewardReceiptItem(
            kind: SoriRewardKind.personalBest,
            identity: entry.key,
            amount: 1,
            label: const SoriLocalizedCopy(
              de: 'Persönliche Bestleistung',
              en: 'Personal best',
              key: SoriCopyKey.rewardBest,
            ),
          ),
        );
      }
    }
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
    final claims = <String, int>{
      for (final item in items)
        if (item.kind == SoriRewardKind.yeopjeon && item.identity != null)
          item.identity!: item.amount!,
    };
    final firstMoment = confirmedRewardMoments
        .where(
          (moment) =>
              moment.playMintVideo &&
              claims.containsKey('daily:${moment.day}:first'),
        )
        .firstOrNull;
    return RewardReceipt(
      activityId: activityId,
      receiptId: stableId,
      items: List.unmodifiable(items),
      pendingYeopjeon: pendingYeopjeon,
      yeopjeonReward: claims.isEmpty || afterWallet == null
          ? null
          : YeopjeonRewardMoment(
              claims: claims,
              balance: afterWallet.balance,
              source: firstMoment?.source ?? YeopjeonRewardSource.recovery,
              day:
                  firstMoment?.day ??
                  YeopjeonRewardMoment.dayKey(DateTime.now()),
            ),
      sarangchaeStageBefore: before.ownedSarangchaeStage,
      sarangchaeStageAfter: after.ownedSarangchaeStage,
      b2ConstructionStageBefore: before.ownedB2Stage,
      b2ConstructionStageAfter: after.ownedB2Stage,
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

  static String _stableReceiptId(
    String activityId,
    SoriStageProgressionSnapshot before,
    SoriStageProgressionSnapshot after,
  ) {
    final fingerprint = <Object?>[
      activityId,
      before.xp,
      after.xp,
      before.wallet?.balance,
      after.wallet?.balance,
      ...?after.wallet?.claims.keys,
      before.stampCount,
      after.stampCount,
      before.pendingBojagiCount,
      after.pendingBojagiCount,
      before.gyeLanternCount,
      after.gyeLanternCount,
      before.hanokCompetence.sarangchaeConstructionStage,
      after.hanokCompetence.sarangchaeConstructionStage,
      before.hanokCompetence.b2ConstructionStage,
      after.hanokCompetence.b2ConstructionStage,
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
