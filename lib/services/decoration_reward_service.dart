import 'dart:convert';

import 'package:flutter/foundation.dart'
    show SynchronousFuture, visibleForTesting;

import '../data/quest_catalog.dart';
import '../widgets/sori/placed_decoration.dart';
import 'storage_service.dart';

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

  /// 화면 테스트 사이의 전역 직렬 큐를 격리한다.
  ///
  /// [SynchronousFuture]를 써서 다음 테스트의 fake-async frame에서 즉시 새
  /// operation을 시작할 수 있게 한다. 앱 런타임에서는 호출하지 않는다.
  @visibleForTesting
  static void resetForTesting() {
    _mutation = SynchronousFuture<void>(null);
  }

  /// 팩 클리어 보상 출처의 접두사. 출처 id 는 `pack:<packId>`(예 `pack:food_a1`).
  /// 콜론을 포함하지 않는 퀘스트 id 와 충돌하지 않는다.
  static const String kPackSourcePrefix = 'pack:';

  /// 보자기를 낼 수 있는 유효한 보상 출처인가.
  ///
  /// 등록된 퀘스트이거나, 형식이 올바른 팩 출처(`pack:` + 비어있지 않은 id)면
  /// true. 팩 출처의 후보는 [_stableStartIndex] 해시로만 결정돼 출처 종류와
  /// 무관하게 항상 결정적·수령 가능하므로 별도 팩 목록 검증이 필요 없다. 오직
  /// pack-clear 경로가 실제 pack.id 로 생산하므로 잘못된 팩 출처는 생기지 않는다.
  static bool isRewardSource(String id) =>
      kQuestById.containsKey(id) ||
      (id.startsWith(kPackSourcePrefix) &&
          id.length > kPackSourcePrefix.length);

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
    if (Storage.pendingBoxes.contains(sourceId)) {
      return;
    }
    await Storage.addPendingBox(sourceId);
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
  static Future<DecorationRewardClaimResult> claimNextBox(String slug) =>
      _serialize(() => _claimNextBox(slug));

  static Future<DecorationRewardClaimResult> _claimNextBox(String slug) async {
    final previousRecovery = await _resumePendingClaim();
    if (previousRecovery == DecorationRewardRecoveryResult.conflict) {
      return DecorationRewardClaimResult.recoveryConflict;
    }

    final pendingBefore = List<String>.from(Storage.pendingBoxes);
    if (pendingBefore.isEmpty) {
      return DecorationRewardClaimResult.noPendingBox;
    }

    final sourceQuestId = pendingBefore.first;
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
    await Storage.setDecorationRewardClaimJournalRawJson(journal.toRawJson());

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
  static Future<DecorationRewardClaimResult> archiveCompleteCollectionBox() =>
      _serialize(_archiveCompleteCollectionBox);

  static Future<DecorationRewardClaimResult>
  _archiveCompleteCollectionBox() async {
    final previousRecovery = await _resumePendingClaim();
    if (previousRecovery == DecorationRewardRecoveryResult.conflict) {
      return DecorationRewardClaimResult.recoveryConflict;
    }

    final pendingBefore = List<String>.from(Storage.pendingBoxes);
    if (pendingBefore.isEmpty) {
      return DecorationRewardClaimResult.noPendingBox;
    }

    final sourceQuestId = pendingBefore.first;
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
    await Storage.setDecorationRewardClaimJournalRawJson(journal.toRawJson());

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
    final rawJournal = Storage.decorationRewardClaimJournalRawJson;
    if (rawJournal.isEmpty) {
      return DecorationRewardRecoveryResult.none;
    }

    final journal = _RewardClaimJournal.tryParse(rawJournal);
    if (journal == null || !_isClaimableJournal(journal)) {
      return DecorationRewardRecoveryResult.conflict;
    }

    final current = Storage.pendingBoxes;
    if (journal.stage == _RewardClaimStage.prepared &&
        !_startsWith(current, journal.pendingBefore)) {
      return DecorationRewardRecoveryResult.conflict;
    }
    if (_startsWith(current, journal.pendingBefore)) {
      final suffix = current.sublist(journal.pendingBefore.length);
      if (journal.kind == _RewardClaimKind.decoration) {
        await Storage.addOwnedDecor(journal.decorationSlug!);
      }
      if (journal.stage == _RewardClaimStage.prepared) {
        await Storage.setDecorationRewardClaimJournalRawJson(
          journal.withQueueCommitStarted().toRawJson(),
        );
      }
      await Storage.setPendingBoxes([...journal.pendingAfter, ...suffix]);
      await Storage.clearDecorationRewardClaimJournal();
      return DecorationRewardRecoveryResult.resumed;
    }
    if (journal.stage == _RewardClaimStage.queueCommitStarted &&
        _startsWith(current, journal.pendingAfter)) {
      if (journal.kind == _RewardClaimKind.decoration) {
        await Storage.addOwnedDecor(journal.decorationSlug!);
      }
      await Storage.clearDecorationRewardClaimJournal();
      return DecorationRewardRecoveryResult.resumed;
    }
    return DecorationRewardRecoveryResult.conflict;
  }

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

  static bool _startsWith(List<String> values, List<String> prefix) {
    if (values.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (values[i] != prefix[i]) return false;
    }
    return true;
  }

  static Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _mutation.then<T>((_) => operation());
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

enum _RewardClaimStage { prepared, queueCommitStarted }

enum _RewardClaimKind { decoration, archiveCompleteCollection }

/// `kl_reward_claim_v1`의 유일한 해석기. v1 장식 journal은 계속 읽고, 새
/// v2 journal은 후보 산출 당시의 보유 스냅샷과 전체 수집 보관 처리를 추가한다.
///
/// pending 목록 전체를 같이 보관하므로 반복 출처 ID에서도 처음 선택한 상자 하나만
/// 제거하고, 그 뒤에 추가된 상자는 보존한다.
class _RewardClaimJournal {
  _RewardClaimJournal.decoration({
    required this.sourceQuestId,
    required this.decorationSlug,
    required Iterable<String> ownedBefore,
    required List<String> pendingBefore,
  }) : kind = _RewardClaimKind.decoration,
       stage = _RewardClaimStage.prepared,
       ownedBefore = List<String>.unmodifiable(ownedBefore),
       pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingBefore.skip(1));

  _RewardClaimJournal.archiveCompleteCollection({
    required this.sourceQuestId,
    required Iterable<String> ownedBefore,
    required List<String> pendingBefore,
  }) : kind = _RewardClaimKind.archiveCompleteCollection,
       stage = _RewardClaimStage.prepared,
       decorationSlug = null,
       ownedBefore = List<String>.unmodifiable(ownedBefore),
       pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingBefore.skip(1));

  _RewardClaimJournal._decoded({
    required this.kind,
    required this.stage,
    required this.sourceQuestId,
    required this.decorationSlug,
    required Iterable<String> ownedBefore,
    required List<String> pendingBefore,
    required List<String> pendingAfter,
  }) : ownedBefore = List<String>.unmodifiable(ownedBefore),
       pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingAfter);

  final _RewardClaimKind kind;
  final _RewardClaimStage stage;
  final String sourceQuestId;
  final String? decorationSlug;
  final List<String> ownedBefore;
  final List<String> pendingBefore;
  final List<String> pendingAfter;

  String toRawJson() {
    final raw = <String, Object?>{
      'version': 2,
      'kind': _kindWire(kind),
      'stage': _stageWire(stage),
      'sourceQuestId': sourceQuestId,
      'ownedBefore': ownedBefore,
      'pendingBefore': pendingBefore,
      'pendingAfter': pendingAfter,
    };
    if (kind == _RewardClaimKind.decoration) {
      raw['decorationSlug'] = decorationSlug;
    }
    return jsonEncode(raw);
  }

  static _RewardClaimJournal? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final version = decoded['version'];
      if (version == 1) {
        return _tryParseV1(decoded);
      }
      if (version == 2) {
        return _tryParseV2(decoded);
      }
      return null;
    } on Object {
      return null;
    }
  }

  static _RewardClaimJournal? _tryParseV1(Map decoded) {
    final stage = _stageFromWire(decoded['stage']);
    final sourceQuestId = decoded['sourceQuestId'];
    final decorationSlug = decoded['decorationSlug'];
    final pendingBefore = _stringList(decoded['pendingBefore']);
    final pendingAfter = _stringList(decoded['pendingAfter']);
    if (!_hasValidQueueShape(
          stage: stage,
          sourceQuestId: sourceQuestId,
          pendingBefore: pendingBefore,
          pendingAfter: pendingAfter,
        ) ||
        decorationSlug is! String ||
        decorationSlug.isEmpty) {
      return null;
    }
    return _RewardClaimJournal._decoded(
      kind: _RewardClaimKind.decoration,
      stage: stage!,
      sourceQuestId: sourceQuestId as String,
      decorationSlug: decorationSlug,
      ownedBefore: const <String>[],
      pendingBefore: pendingBefore!,
      pendingAfter: pendingAfter!,
    );
  }

  static _RewardClaimJournal? _tryParseV2(Map decoded) {
    final kind = _kindFromWire(decoded['kind']);
    final stage = _stageFromWire(decoded['stage']);
    final sourceQuestId = decoded['sourceQuestId'];
    final ownedBefore = _stringList(decoded['ownedBefore']);
    final pendingBefore = _stringList(decoded['pendingBefore']);
    final pendingAfter = _stringList(decoded['pendingAfter']);
    if (kind == null ||
        ownedBefore == null ||
        ownedBefore.any((slug) => slug.isEmpty) ||
        !_hasValidQueueShape(
          stage: stage,
          sourceQuestId: sourceQuestId,
          pendingBefore: pendingBefore,
          pendingAfter: pendingAfter,
        )) {
      return null;
    }

    if (kind == _RewardClaimKind.decoration) {
      final decorationSlug = decoded['decorationSlug'];
      if (decorationSlug is! String || decorationSlug.isEmpty) {
        return null;
      }
      return _RewardClaimJournal._decoded(
        kind: kind,
        stage: stage!,
        sourceQuestId: sourceQuestId as String,
        decorationSlug: decorationSlug,
        ownedBefore: ownedBefore,
        pendingBefore: pendingBefore!,
        pendingAfter: pendingAfter!,
      );
    }

    if (decoded.containsKey('decorationSlug')) {
      return null;
    }
    return _RewardClaimJournal._decoded(
      kind: kind,
      stage: stage!,
      sourceQuestId: sourceQuestId as String,
      decorationSlug: null,
      ownedBefore: ownedBefore,
      pendingBefore: pendingBefore!,
      pendingAfter: pendingAfter!,
    );
  }

  static bool _hasValidQueueShape({
    required _RewardClaimStage? stage,
    required Object? sourceQuestId,
    required List<String>? pendingBefore,
    required List<String>? pendingAfter,
  }) {
    return stage != null &&
        sourceQuestId is String &&
        sourceQuestId.isNotEmpty &&
        pendingBefore != null &&
        pendingBefore.isNotEmpty &&
        pendingAfter != null &&
        sourceQuestId == pendingBefore.first &&
        _sameList(pendingAfter, pendingBefore.skip(1));
  }

  _RewardClaimJournal withQueueCommitStarted() => _RewardClaimJournal._decoded(
    kind: kind,
    stage: _RewardClaimStage.queueCommitStarted,
    sourceQuestId: sourceQuestId,
    decorationSlug: decorationSlug,
    ownedBefore: ownedBefore,
    pendingBefore: pendingBefore,
    pendingAfter: pendingAfter,
  );

  static String _kindWire(_RewardClaimKind kind) => switch (kind) {
    _RewardClaimKind.decoration => 'decoration',
    _RewardClaimKind.archiveCompleteCollection => 'archive_complete_collection',
  };

  static _RewardClaimKind? _kindFromWire(Object? raw) => switch (raw) {
    'decoration' => _RewardClaimKind.decoration,
    'archive_complete_collection' => _RewardClaimKind.archiveCompleteCollection,
    _ => null,
  };

  static String _stageWire(_RewardClaimStage stage) => switch (stage) {
    _RewardClaimStage.prepared => 'prepared',
    _RewardClaimStage.queueCommitStarted => 'queue_commit_started',
  };

  static _RewardClaimStage? _stageFromWire(Object? raw) => switch (raw) {
    'prepared' => _RewardClaimStage.prepared,
    'queue_commit_started' => _RewardClaimStage.queueCommitStarted,
    _ => null,
  };

  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    final strings = <String>[];
    for (final item in value) {
      if (item is! String) return null;
      strings.add(item);
    }
    return strings;
  }

  static bool _sameList(Iterable<String> first, Iterable<String> second) {
    final firstList = first.toList();
    final secondList = second.toList();
    if (firstList.length != secondList.length) return false;
    for (var i = 0; i < firstList.length; i++) {
      if (firstList[i] != secondList[i]) return false;
    }
    return true;
  }
}
