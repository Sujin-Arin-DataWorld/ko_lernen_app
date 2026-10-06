import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show SynchronousFuture, visibleForTesting;
import 'package:uuid/uuid.dart';

import '../data/quest_catalog.dart';
import '../models/decoration_reward_receipt.dart';
import '../models/yeopjeon_wallet.dart';
import '../widgets/sori/placed_decoration.dart';
import 'account/cloud_write_session.dart';
import 'analytics_service.dart';
import 'local_data_lifetime.dart';
import 'room_layout_service.dart';
import 'storage_service.dart';

export '../models/decoration_reward_receipt.dart';

part 'decoration_reward_claim_journal.dart';

/// 사랑방 보자기에서 나올 수 있는 실내 장식의 v1 순서.
///
/// 기존 항목을 재정렬하거나 사이에 삽입하면 이미 열린 상자의 후보가 달라진다.
/// 미래 장식은 반드시 목록 끝에만 추가한다.
const List<String> kDecorationRewardPool = <String>[
  'decoration_chaekgado',
  'decoration_seoan',
  'decoration_munbangsau',
  'decoration_sagunja_maehwa',
  'decoration_soban',
  'decoration_gat_buchae',
  'decoration_sagunja_nan',
  'decoration_jagae_mungap',
  'decoration_pyeonaek',
  'decoration_sagunja_guk',
  'decoration_sagunja_juk',
];

enum DecorationRewardOfferState {
  ready,
  noPendingBox,
  unknownQuest,
  noEligibleCandidates,
  collectionComplete,
  recoveryConflict,
}

enum DecorationRewardClaimResult {
  claimed,
  collectionArchived,
  noPendingBox,
  unknownQuest,
  noEligibleCandidates,
  notOffered,
  recoveryConflict,
}

enum DecorationRewardRecoveryResult { none, resumed, conflict }

/// 첫 미개봉 꾸러미의 화면 표시용 상태.
///
/// [sourceQuestId]와 [candidates]는 [state]가 [ready]일 때만 동시에 채워진다.
/// 실패·대기 상태에도 출처를 남겨 UI가 지원 경로를 표시할 수 있게 한다.
class DecorationRewardOffer {
  DecorationRewardOffer({
    required this.state,
    this.sourceQuestId,
    Iterable<String> candidates = const <String>[],
  }) : candidates = List<String>.unmodifiable(candidates);

  final DecorationRewardOfferState state;
  final String? sourceQuestId;
  final List<String> candidates;
}

enum SingleDecorationRewardOfferState {
  ready,
  receiptAvailable,
  noPendingBox,
  unknownQuest,
  noEligibleCandidates,
  collectionComplete,
  recoveryConflict,
  accountUnavailable,
}

/// An opaque offer for one occurrence of the first queued box. The queue and
/// ownership preimages cannot be replaced by a caller-provided source ID.
final class SingleDecorationRewardOffer {
  SingleDecorationRewardOffer._({
    required this.state,
    this.sourceQuestId,
    this.decorationSlug,
    this.receipt,
    this._lease,
    this._receiptId,
    Iterable<String> pendingBefore = const [],
    Iterable<String> ownedBefore = const [],
  }) : _pendingBefore = List.unmodifiable(pendingBefore),
       _ownedBefore = List.unmodifiable(ownedBefore);

  final SingleDecorationRewardOfferState state;
  final String? sourceQuestId;
  final String? decorationSlug;
  final DecorationRewardReceipt? receipt;
  final _RewardOperationLease? _lease;
  final String? _receiptId;
  final List<String> _pendingBefore;
  final List<String> _ownedBefore;
}

final class SingleDecorationRewardClaim {
  const SingleDecorationRewardClaim(this.result, {this.receipt});

  final DecorationRewardClaimResult result;
  final DecorationRewardReceipt? receipt;
}

final class _RewardOperationLease {
  _RewardOperationLease({required this.allowReconciliation})
    : lifetime = LocalDataLifetime.capture(),
      session = cloudWriteSessionController.current,
      identityEpoch = cloudWriteSessionController.identityEpoch;

  final LocalDataLifetimeLease lifetime;
  final CloudWriteSession? session;
  final int identityEpoch;
  final bool allowReconciliation;

  void assertCurrent() {
    lifetime.assertCurrent();
    if (identityEpoch != cloudWriteSessionController.identityEpoch ||
        session != cloudWriteSessionController.current ||
        (session != null &&
            session!.mode != CloudWriteMode.ready &&
            !(allowReconciliation &&
                session!.mode == CloudWriteMode.reconciling))) {
      throw const _RewardAccountUnavailableException();
    }
  }
}

final class _RewardAccountUnavailableException implements Exception {
  const _RewardAccountUnavailableException();
}

/// 사랑방 보상 선택의 비시각적 규칙.
///
/// 화면은 이 서비스로부터 후보를 받고, 이후 단계에서 제공될 claim API로만
/// 소유권과 큐 소비를 요청한다. 후보의 안정성은 Dart hashCode가 아니라
/// [_stableStartIndex]의 명시적 코드 유닛 산술로 보장한다.
class DecorationRewardService {
  DecorationRewardService._();

  /// 모든 공개 요청을 한 줄로 처리한다. 같은 보자기를 빠르게 두 번 눌러도
  /// 두 번째 요청은 첫 번째의 journal 정리 뒤 현재 큐를 다시 읽는다.
  static Future<void> _mutation = Future<void>.value();
  static final Object _leaseZoneKey = Object();
  static Expando<_RewardOperationLease> _receiptLeases = Expando();

  static Future<void> get packCompletionDrain => _mutation;

  /// 화면 테스트 사이의 전역 직렬 큐를 격리한다.
  ///
  /// [SynchronousFuture]를 써서 다음 테스트의 fake-async frame에서 즉시 새
  /// operation을 시작할 수 있게 한다. 앱 런타임에서는 호출하지 않는다.
  @visibleForTesting
  static void resetForTesting() {
    _mutation = SynchronousFuture<void>(null);
    _receiptLeases = Expando();
  }

  /// 팩 클리어 보상 출처의 접두사. 출처 id 는 `pack:<packId>`(예 `pack:food_a1`).
  /// 콜론을 포함하지 않는 퀘스트 id 와 충돌하지 않는다.
  static const String kPackSourcePrefix = 'pack:';

  /// 마일스톤 달성 보상 출처의 접두사. 출처 id 는 `milestone:<milestoneId>`
  /// (예 `milestone:level_5`). 콜론 없는 퀘스트 id·`pack:` 출처와 충돌하지 않는다.
  static const String kMilestoneSourcePrefix = 'milestone:';

  static bool _hasPrefixedBody(String id, String prefix) =>
      id.startsWith(prefix) && id.length > prefix.length;

  /// 보자기를 낼 수 있는 유효한 보상 출처인가.
  ///
  /// 등록된 퀘스트이거나, 형식이 올바른 팩 출처(`pack:` + 비어있지 않은 id),
  /// 또는 마일스톤 출처(`milestone:` + 비어있지 않은 id)면 true. 모든 출처의
  /// 후보는 [_stableStartIndex] 해시로만 결정돼 출처 종류와 무관하게 항상
  /// 결정적·수령 가능하므로 별도 목록 검증이 필요 없다. 각 경로(pack-clear,
  /// 마일스톤 축하)가 실제 id 로만 생산하므로 잘못된 출처는 생기지 않는다.
  static bool isRewardSource(String id) =>
      kQuestById.containsKey(id) ||
      _hasPrefixedBody(id, kPackSourcePrefix) ||
      _hasPrefixedBody(id, kMilestoneSourcePrefix);

  /// 한 퀘스트가 항상 같은 세 후보를 주되, 이미 보유한 것은 제외한다.
  ///
  /// 원래 세 종을 전부 보유했을 때만 바로 다음 순환 위치에서 미보유 세 종을
  /// 찾는다. 따라서 이전 보상의 고정성은 그대로이고, 풀에 아직 장식이 남았는데
  /// 한 상자가 영구 대기열을 막는 일도 없다.
  ///
  /// 알 수 없는 출처는 손상된 pending box로 보고 어떤 장식도 제안하지 않는다.
  static List<String> candidatesForQuest(
    String questId, {
    Iterable<String>? owned,
  }) {
    assert(
      kDecorationRewardPool.every(kDecorCategory.containsKey),
      'Reward pool may contain only registered interior decorations.',
    );
    if (!isRewardSource(questId)) {
      return const <String>[];
    }

    final ownedSet = (owned ?? Storage.ownedDecor).toSet();
    final start = _stableStartIndex(questId);
    final candidates = <String>[];
    for (var offset = 0; offset < 3; offset++) {
      final slug =
          kDecorationRewardPool[(start + offset) %
              kDecorationRewardPool.length];
      if (!ownedSet.contains(slug)) {
        candidates.add(slug);
      }
    }
    if (candidates.isNotEmpty) {
      return candidates;
    }

    for (var offset = 3; offset < kDecorationRewardPool.length; offset++) {
      final slug =
          kDecorationRewardPool[(start + offset) %
              kDecorationRewardPool.length];
      if (!ownedSet.contains(slug)) {
        candidates.add(slug);
        if (candidates.length == 3) {
          break;
        }
      }
    }
    return candidates;
  }

  /// 홈·진입점 배지용 — 지금 열 수 있는 보자기 개수.
  ///
  /// 손상된(알 수 없는 퀘스트) pending box 는 제외한다. 그런 상자는 bojagi
  /// 화면이 "문제" 상태로 안내하고 큐에서 정리하므로, 사용자에게 "선물 N개"로
  /// 세어 보이면 존재하지 않는 보상을 약속하는 셈이 된다. 후보 소진·전체 수집
  /// 상자는 여전히 여는 동작(교체·보관)이 필요하므로 센다.
  static int openableBoxCount({Iterable<String>? pending}) {
    final boxes = pending ?? Storage.pendingBoxes;
    return boxes.where(isRewardSource).length;
  }

  /// 먼저 중단된 수령을 회복한 뒤 첫 미개봉 꾸러미의 표시 상태를 만든다.
  static Future<DecorationRewardOffer> loadNextOffer() =>
      _serialize(_loadNextOffer);

  /// Returns a durable unfinished presentation before offering another box.
  static Future<SingleDecorationRewardOffer> loadSingleOffer() async {
    try {
      return await _serialize(_loadSingleOffer);
    } on _RewardAccountUnavailableException {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.accountUnavailable,
      );
    } on StaleLocalDataLifetimeException {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.accountUnavailable,
      );
    }
  }

  static Future<SingleDecorationRewardOffer> _loadSingleOffer() async {
    final recovery = await _resumePendingClaim();
    _assertCurrent();
    if (recovery == DecorationRewardRecoveryResult.conflict) {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.recoveryConflict,
      );
    }
    final history = await _readReceiptHistory();
    final receipt = history.pending;
    if (receipt != null) {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.receiptAvailable,
        sourceQuestId: receipt.sourceQuestId,
        decorationSlug: receipt.decorationSlug,
        receipt: _bindReceipt(receipt),
        lease: _currentLease,
      );
    }
    final pending = Storage.pendingBoxes;
    if (pending.isEmpty) {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.noPendingBox,
      );
    }
    final source = pending.first;
    if (!isRewardSource(source)) {
      return SingleDecorationRewardOffer._(
        state: SingleDecorationRewardOfferState.unknownQuest,
        sourceQuestId: source,
      );
    }
    final owned = Storage.ownedDecor;
    final candidates = candidatesForQuest(source, owned: owned);
    if (candidates.isEmpty) {
      return SingleDecorationRewardOffer._(
        state: _hasCompleteRewardCollection(owned)
            ? SingleDecorationRewardOfferState.collectionComplete
            : SingleDecorationRewardOfferState.noEligibleCandidates,
        sourceQuestId: source,
      );
    }
    return SingleDecorationRewardOffer._(
      state: SingleDecorationRewardOfferState.ready,
      sourceQuestId: source,
      decorationSlug: candidates.first,
      lease: _currentLease,
      receiptId: const Uuid().v4(),
      pendingBefore: pending,
      ownedBefore: owned,
    );
  }

  static Future<SingleDecorationRewardClaim> claimSingleOffer(
    SingleDecorationRewardOffer offer,
  ) async {
    try {
      return await _serialize(() => _claimSingleOffer(offer));
    } on _RewardAccountUnavailableException {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.notOffered,
      );
    } on StaleLocalDataLifetimeException {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.notOffered,
      );
    }
  }

  static Future<SingleDecorationRewardClaim> _claimSingleOffer(
    SingleDecorationRewardOffer offer,
  ) async {
    offer._lease?.assertCurrent();
    if (offer._lease == null) {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.notOffered,
      );
    }
    final recovery = await _resumePendingClaim();
    _assertCurrent();
    if (recovery == DecorationRewardRecoveryResult.conflict) {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.recoveryConflict,
      );
    }
    final history = await _readReceiptHistory();
    final priorId = offer._receiptId ?? offer.receipt?.id;
    final prior = priorId == null ? null : history.find(priorId);
    if (prior != null) {
      return SingleDecorationRewardClaim(
        DecorationRewardClaimResult.claimed,
        receipt: _bindReceipt(prior),
      );
    }
    if (offer.state != SingleDecorationRewardOfferState.ready ||
        offer._receiptId == null ||
        history.pending != null ||
        !_startsWith(Storage.pendingBoxes, offer._pendingBefore) ||
        !_sameOwned(Storage.ownedDecor, offer._ownedBefore)) {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.notOffered,
      );
    }
    final pending = Storage.pendingBoxes;
    final candidates = candidatesForQuest(offer.sourceQuestId!);
    if (pending.isEmpty ||
        pending.first != offer.sourceQuestId ||
        candidates.isEmpty ||
        candidates.first != offer.decorationSlug) {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.notOffered,
      );
    }
    final receipt = await _captureReceipt(
      id: offer._receiptId,
      sourceQuestId: offer.sourceQuestId!,
      decorationSlug: offer.decorationSlug!,
    );
    final journal = _RewardClaimJournal.decoration(
      sourceQuestId: receipt.sourceQuestId,
      decorationSlug: receipt.decorationSlug,
      ownedBefore: offer._ownedBefore,
      pendingBefore: pending,
      receipt: receipt,
    );
    await Storage.setDecorationRewardClaimJournalRawJson(
      journal.toRawJson(),
      assertCurrentWrite: _assertCurrent,
    );
    _assertCurrent();
    final resumed = await _resumePendingClaim();
    _assertCurrent();
    if (resumed != DecorationRewardRecoveryResult.resumed) {
      return const SingleDecorationRewardClaim(
        DecorationRewardClaimResult.recoveryConflict,
      );
    }
    // Return the confirmed receipt directly; looking up the next offer would
    // erase the just-completed presentation when the last box was consumed.
    final confirmed = (await _readReceiptHistory()).find(receipt.id);
    return SingleDecorationRewardClaim(
      confirmed == null
          ? DecorationRewardClaimResult.recoveryConflict
          : DecorationRewardClaimResult.claimed,
      receipt: confirmed == null ? null : _bindReceipt(confirmed),
    );
  }

  /// Only the presentation's final CTA calls this. Replays and culture reads
  /// use the frozen receipt and never enter a reward mutation.
  static Future<bool> acknowledgeSingleReward(
    DecorationRewardReceipt receipt,
  ) async {
    try {
      return await _serialize(() async {
        final lease = _receiptLeases[receipt];
        if (lease == null) {
          return false;
        }
        lease.assertCurrent();
        final history = await _readReceiptHistory();
        final stored = history.find(receipt.id);
        if (stored == null || !stored.hasSameReward(receipt)) {
          return false;
        }
        if (!stored.acknowledged) {
          await Storage.setDecorationRewardReceiptRawJson(
            history.acknowledge(receipt.id).encode(),
            assertCurrentWrite: _assertCurrent,
          );
          _assertCurrent();
        }
        return true;
      });
    } on _RewardAccountUnavailableException {
      return false;
    } on StaleLocalDataLifetimeException {
      return false;
    }
  }

  /// Cloud reconciliation restores presentation only. It cannot mint rewards,
  /// replay a claim journal, restore ownership, or recreate a queued box.
  static Future<void> mergeReceiptPresentation(
    String raw, {
    void Function()? beforeWrite,
  }) => _serialize(() async {
    final history = await _readReceiptHistory();
    final merged = DecorationRewardReceiptHistory.mergeJson(
      history.encode(),
      raw,
    );
    _assertCurrent();
    beforeWrite?.call();
    await Storage.setDecorationRewardReceiptRawJson(
      merged,
      assertCurrentWrite: () {
        _assertCurrent();
        beforeWrite?.call();
      },
    );
    _assertCurrent();
  }, allowReconciliation: beforeWrite != null);

  /// 새로 완료된 보상 출처(퀘스트 또는 팩 클리어)의 보자기를 최대 한 개만
  /// 큐에 넣는다.
  ///
  /// 수령과 같은 직렬 체인을 쓰므로, 수령 중에 뒤늦게 지급된 보상 상자가
  /// 첫 상자 소비 write와 경합해 유실되지 않는다. 유효하지 않은(알 수 없는)
  /// 출처는 저장하지 않아 화면이 복구할 수 없는 pending box를 만들지 않는다.
  static Future<void> ensurePendingBox(String sourceId) =>
      _serialize(() => _ensurePendingBox(sourceId));

  /// 하위호환 별칭 — 퀘스트 완료 경로([QuestTracker.persistNewCompletions]).
  static Future<void> ensurePendingBoxForQuest(String questId) =>
      ensurePendingBox(questId);

  static Future<void> _ensurePendingBox(String sourceId) async {
    if (!isRewardSource(sourceId)) {
      return;
    }
    if (await _resumePendingClaim() ==
        DecorationRewardRecoveryResult.conflict) {
      throw StateError('Decoration reward recovery is blocked.');
    }
    _assertCurrent();
    if (Storage.pendingBoxes.contains(sourceId)) {
      return;
    }
    await Storage.addPendingBox(sourceId, assertCurrentWrite: _assertCurrent);
    _assertCurrent();
  }

  static Future<DecorationRewardOffer> _loadNextOffer() async {
    final recovery = await _resumePendingClaim();
    if (recovery == DecorationRewardRecoveryResult.conflict) {
      return DecorationRewardOffer(
        state: DecorationRewardOfferState.recoveryConflict,
      );
    }

    final pending = Storage.pendingBoxes;
    if (pending.isEmpty) {
      return DecorationRewardOffer(
        state: DecorationRewardOfferState.noPendingBox,
      );
    }

    final sourceQuestId = pending.first;
    if (!isRewardSource(sourceQuestId)) {
      return DecorationRewardOffer(
        state: DecorationRewardOfferState.unknownQuest,
        sourceQuestId: sourceQuestId,
      );
    }

    final candidates = candidatesForQuest(sourceQuestId);
    if (candidates.isEmpty) {
      return DecorationRewardOffer(
        state: _hasCompleteRewardCollection(Storage.ownedDecor)
            ? DecorationRewardOfferState.collectionComplete
            : DecorationRewardOfferState.noEligibleCandidates,
        sourceQuestId: sourceQuestId,
      );
    }
    return DecorationRewardOffer(
      state: DecorationRewardOfferState.ready,
      sourceQuestId: sourceQuestId,
      candidates: candidates,
    );
  }

  /// 첫 pending box가 제안한 [slug]를 멱등 보유 장식으로 수령한다.
  ///
  /// journal을 먼저 기록한 뒤 같은 복구 루틴으로 완성하므로, 각 저장 사이에
  /// 앱이 종료돼도 다음 시작에서 같은 결과로 수렴한다.
  static Future<DecorationRewardClaimResult> claimNextBox(
    String slug, {
    String? expectedSourceQuestId,
  }) => _serialize(() => _claimNextBox(slug, expectedSourceQuestId));

  static Future<DecorationRewardClaimResult> _claimNextBox(
    String slug,
    String? expectedSourceQuestId,
  ) async {
    final previousRecovery = await _resumePendingClaim();
    if (previousRecovery == DecorationRewardRecoveryResult.conflict) {
      return DecorationRewardClaimResult.recoveryConflict;
    }

    final pendingBefore = List<String>.from(Storage.pendingBoxes);
    if (pendingBefore.isEmpty) {
      return DecorationRewardClaimResult.noPendingBox;
    }

    final sourceQuestId = pendingBefore.first;
    if (expectedSourceQuestId != null &&
        sourceQuestId != expectedSourceQuestId) {
      return DecorationRewardClaimResult.notOffered;
    }
    if (!isRewardSource(sourceQuestId)) {
      return DecorationRewardClaimResult.unknownQuest;
    }

    final candidates = candidatesForQuest(sourceQuestId);
    if (candidates.isEmpty) {
      return DecorationRewardClaimResult.noEligibleCandidates;
    }
    if (!candidates.contains(slug)) {
      return DecorationRewardClaimResult.notOffered;
    }

    final journal = _RewardClaimJournal.decoration(
      sourceQuestId: sourceQuestId,
      decorationSlug: slug,
      ownedBefore: Storage.ownedDecor,
      pendingBefore: pendingBefore,
    );
    await Storage.setDecorationRewardClaimJournalRawJson(
      journal.toRawJson(),
      assertCurrentWrite: _assertCurrent,
    );
    _assertCurrent();

    final recovery = await _resumePendingClaim();
    return switch (recovery) {
      DecorationRewardRecoveryResult.resumed =>
        DecorationRewardClaimResult.claimed,
      DecorationRewardRecoveryResult.none ||
      DecorationRewardRecoveryResult.conflict =>
        DecorationRewardClaimResult.recoveryConflict,
    };
  }

  /// 풀의 모든 장식을 이미 가진 사용자가 보상 상자를 명시적으로 보관 처리한다.
  ///
  /// 새 보상을 조용히 버리지 않도록 전체 수집 상태에서만 허용하며, 일반 수령과
  /// 같은 journal/직렬 체인을 거쳐 첫 상자 하나만 소비한다.
  static Future<DecorationRewardClaimResult> archiveCompleteCollectionBox({
    String? expectedSourceQuestId,
  }) => _serialize(() => _archiveCompleteCollectionBox(expectedSourceQuestId));

  static Future<DecorationRewardClaimResult> _archiveCompleteCollectionBox(
    String? expectedSourceQuestId,
  ) async {
    final previousRecovery = await _resumePendingClaim();
    if (previousRecovery == DecorationRewardRecoveryResult.conflict) {
      return DecorationRewardClaimResult.recoveryConflict;
    }

    final pendingBefore = List<String>.from(Storage.pendingBoxes);
    if (pendingBefore.isEmpty) {
      return DecorationRewardClaimResult.noPendingBox;
    }

    final sourceQuestId = pendingBefore.first;
    if (expectedSourceQuestId != null &&
        sourceQuestId != expectedSourceQuestId) {
      return DecorationRewardClaimResult.notOffered;
    }
    if (!isRewardSource(sourceQuestId)) {
      return DecorationRewardClaimResult.unknownQuest;
    }
    if (!_hasCompleteRewardCollection(Storage.ownedDecor)) {
      return DecorationRewardClaimResult.noEligibleCandidates;
    }

    final journal = _RewardClaimJournal.archiveCompleteCollection(
      sourceQuestId: sourceQuestId,
      ownedBefore: Storage.ownedDecor,
      pendingBefore: pendingBefore,
    );
    await Storage.setDecorationRewardClaimJournalRawJson(
      journal.toRawJson(),
      assertCurrentWrite: _assertCurrent,
    );
    _assertCurrent();

    final recovery = await _resumePendingClaim();
    return switch (recovery) {
      DecorationRewardRecoveryResult.resumed =>
        DecorationRewardClaimResult.collectionArchived,
      DecorationRewardRecoveryResult.none ||
      DecorationRewardRecoveryResult.conflict =>
        DecorationRewardClaimResult.recoveryConflict,
    };
  }

  /// 앱 시작·화면 재개에도 호출할 수 있는 journal 복구 진입점.
  static Future<DecorationRewardRecoveryResult> resumePendingClaim() =>
      _serialize(_resumePendingClaim);

  static Future<DecorationRewardRecoveryResult> _resumePendingClaim() async {
    DecorationRewardReceiptHistory history;
    try {
      history = await _readReceiptHistory();
    } on FormatException {
      return DecorationRewardRecoveryResult.conflict;
    }
    final rawJournal = Storage.decorationRewardClaimJournalRawJson;
    if (rawJournal.isEmpty) {
      return DecorationRewardRecoveryResult.none;
    }

    var journal = _RewardClaimJournal.tryParse(rawJournal);
    if (journal == null || !_isClaimableJournal(journal)) {
      return DecorationRewardRecoveryResult.conflict;
    }

    if (journal.receipt != null) {
      final stored = history.find(journal.receipt!.id);
      if (stored != null) {
        if (!stored.hasSameReward(journal.receipt!) ||
            journal.stage != _RewardClaimStage.queueCommitStarted) {
          return DecorationRewardRecoveryResult.conflict;
        }
        // The receipt is written only after queue consumption. A failed clear
        // must never consume a newly appended occurrence of the same source.
        await Storage.clearDecorationRewardClaimJournal(
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
        return DecorationRewardRecoveryResult.resumed;
      }
    }

    final current = Storage.pendingBoxes;
    if (journal.stage == _RewardClaimStage.prepared &&
        !_startsWith(current, journal.pendingBefore)) {
      return DecorationRewardRecoveryResult.conflict;
    }
    if (!_startsWith(current, journal.pendingBefore) &&
        !(journal.stage == _RewardClaimStage.queueCommitStarted &&
            _startsWith(current, journal.pendingAfter))) {
      return DecorationRewardRecoveryResult.conflict;
    }
    if (journal.kind == _RewardClaimKind.decoration &&
        journal.receipt == null) {
      final receipt = await _captureReceipt(
        id: const Uuid().v4(),
        sourceQuestId: journal.sourceQuestId,
        decorationSlug: journal.decorationSlug!,
      );
      journal = journal.withReceipt(receipt);
      // Upgrade v1/v2 before the next mutation so recovery freezes the same
      // receipt without rerolling their already-selected decoration.
      await Storage.setDecorationRewardClaimJournalRawJson(
        journal.toRawJson(),
        assertCurrentWrite: _assertCurrent,
      );
      _assertCurrent();
    }
    if (journal.receipt != null) {
      try {
        history = history.add(journal.receipt!);
      } on FormatException {
        return DecorationRewardRecoveryResult.conflict;
      }
    }
    if (_startsWith(current, journal.pendingBefore)) {
      final suffix = current.sublist(journal.pendingBefore.length);
      if (journal.kind == _RewardClaimKind.decoration) {
        await Storage.addOwnedDecor(
          journal.decorationSlug!,
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
        await Storage.recordDecorEarnedAt(
          journal.decorationSlug!,
          journal.receipt!.claimedAtUtc.toIso8601String(),
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
      }
      if (journal.stage == _RewardClaimStage.prepared) {
        await Storage.setDecorationRewardClaimJournalRawJson(
          journal.withQueueCommitStarted().toRawJson(),
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
      }
      await Storage.setPendingBoxes([
        ...journal.pendingAfter,
        ...suffix,
      ], assertCurrentWrite: _assertCurrent);
      _assertCurrent();
      await _finishJournal(journal, history);
      return DecorationRewardRecoveryResult.resumed;
    }
    if (journal.stage == _RewardClaimStage.queueCommitStarted &&
        _startsWith(current, journal.pendingAfter)) {
      if (journal.kind == _RewardClaimKind.decoration) {
        await Storage.addOwnedDecor(
          journal.decorationSlug!,
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
        await Storage.recordDecorEarnedAt(
          journal.decorationSlug!,
          journal.receipt!.claimedAtUtc.toIso8601String(),
          assertCurrentWrite: _assertCurrent,
        );
        _assertCurrent();
      }
      await _finishJournal(journal, history);
      return DecorationRewardRecoveryResult.resumed;
    }
    return DecorationRewardRecoveryResult.conflict;
  }

  static Future<void> _finishJournal(
    _RewardClaimJournal journal,
    DecorationRewardReceiptHistory history,
  ) async {
    if (journal.receipt != null) {
      await Storage.setDecorationRewardReceiptRawJson(
        history.encode(),
        assertCurrentWrite: _assertCurrent,
      );
      _assertCurrent();
    }
    await Storage.clearDecorationRewardClaimJournal(
      assertCurrentWrite: _assertCurrent,
    );
    _assertCurrent();
  }

  static Future<DecorationRewardReceiptHistory> _readReceiptHistory() async {
    final raw = await Storage.readDecorationRewardReceiptRawJsonStrict(
      assertCurrentRead: _assertCurrent,
    );
    _assertCurrent();
    return DecorationRewardReceiptHistory.decode(raw);
  }

  static Future<DecorationRewardReceipt> _captureReceipt({
    required String id,
    required String sourceQuestId,
    required String decorationSlug,
  }) async {
    final walletRevision = Storage.captureYeopjeonReadRevision();
    final walletRaw = await Storage.readYeopjeonRawJsonStrict();
    _assertCurrent();
    Storage.assertYeopjeonReadRevision(walletRevision);
    final xp = Storage.xp;
    return DecorationRewardReceipt(
      id: id,
      sourceQuestId: sourceQuestId,
      decorationSlug: decorationSlug,
      claimedAtUtc: DateTime.now().toUtc(),
      totalXp: xp,
      xpLevel: xp ~/ 100 + 1,
      xpToNext: 100 - xp % 100,
      yeopjeonBalance: walletRaw == null
          ? null
          : YeopjeonWallet.decode(walletRaw).balance,
    );
  }

  static DecorationRewardReceipt _bindReceipt(DecorationRewardReceipt receipt) {
    _receiptLeases[receipt] = _currentLease;
    return receipt;
  }

  static bool _sameOwned(List<String> first, List<String> second) {
    final firstSet = first.toSet();
    final secondSet = second.toSet();
    return firstSet.length == secondSet.length &&
        firstSet.containsAll(secondSet);
  }

  static _RewardOperationLease get _currentLease =>
      Zone.current[_leaseZoneKey] as _RewardOperationLease;

  static void _assertCurrent() => _currentLease.assertCurrent();

  static bool _isClaimableJournal(_RewardClaimJournal journal) {
    if (!isRewardSource(journal.sourceQuestId)) {
      return false;
    }
    return switch (journal.kind) {
      _RewardClaimKind.decoration => candidatesForQuest(
        journal.sourceQuestId,
        owned: journal.ownedBefore,
      ).contains(journal.decorationSlug),
      _RewardClaimKind.archiveCompleteCollection =>
        _hasCompleteRewardCollection(journal.ownedBefore),
    };
  }

  static bool _hasCompleteRewardCollection(Iterable<String> owned) {
    final ownedSet = owned.toSet();
    return kDecorationRewardPool.every(ownedSet.contains);
  }

  /// Logs `reward_unused` at most once per calendar day: one call per
  /// distinct age bucket present among owned-but-unplaced décor (never one
  /// call per item, to keep event volume low). Safe to call on every room
  /// screen open — the day-dedup makes repeated calls a no-op.
  static Future<void> maybeLogRewardUnused() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (Storage.rewardUnusedLoggedDate == today) {
      return;
    }
    await Storage.setRewardUnusedLoggedDate(today);
    final buckets = unusedRewardBuckets(
      owned: Storage.ownedDecor,
      placed: RoomLayoutService.placedDecorSlugs(),
      earnedAt: Storage.decorEarnedAt,
      now: DateTime.now(),
    );
    for (final bucket in buckets) {
      await Analytics.rewardUnused(
        rewardType: 'decoration',
        daysSinceEarnedBucket: bucket,
      );
    }
  }

  /// Pure — the distinct days-since-earned buckets among decorations that
  /// are owned but not placed on any surface. Exposed for testing; use
  /// [maybeLogRewardUnused] in app code.
  @visibleForTesting
  static Set<String> unusedRewardBuckets({
    required Iterable<String> owned,
    required Set<String> placed,
    required Map<String, String> earnedAt,
    required DateTime now,
  }) {
    final buckets = <String>{};
    for (final slug in owned) {
      if (placed.contains(slug)) {
        continue;
      }
      final earnedIso = earnedAt[slug];
      if (earnedIso == null) {
        continue;
      }
      final earned = DateTime.tryParse(earnedIso);
      if (earned == null) {
        continue;
      }
      final days = now.difference(earned).inDays;
      if (days < 0) {
        continue;
      }
      buckets.add(_daysSinceEarnedBucket(days));
    }
    return buckets;
  }

  static String _daysSinceEarnedBucket(int days) {
    if (days < 3) return '0-2';
    if (days < 7) return '3-6';
    if (days < 14) return '7-13';
    if (days < 30) return '14-29';
    return '30plus';
  }

  static bool _startsWith(List<String> values, List<String> prefix) {
    if (values.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (values[i] != prefix[i]) return false;
    }
    return true;
  }

  static Future<T> _serialize<T>(
    Future<T> Function() operation, {
    bool allowReconciliation = false,
  }) {
    PackCompletionStorage.assertAdmission();
    final lease = _RewardOperationLease(
      allowReconciliation: allowReconciliation,
    );
    lease.assertCurrent();
    final result = _mutation.then<T>((_) {
      lease.assertCurrent();
      return runZoned(operation, zoneValues: {_leaseZoneKey: lease});
    });
    _mutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static int _stableStartIndex(String questId) {
    var hash = 0;
    for (final codeUnit in questId.codeUnits) {
      hash = (hash * 31 + codeUnit) % kDecorationRewardPool.length;
    }
    return hash;
  }
}
