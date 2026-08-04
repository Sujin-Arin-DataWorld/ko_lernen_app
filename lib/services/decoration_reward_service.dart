import 'dart:convert';

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
  recoveryConflict,
}

enum DecorationRewardClaimResult {
  claimed,
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

  /// 한 퀘스트가 항상 같은 세 후보를 주되, 이미 보유한 것은 제외한다.
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
    if (!kQuestById.containsKey(questId)) {
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
    return candidates;
  }

  /// 먼저 중단된 수령을 회복한 뒤 첫 미개봉 꾸러미의 표시 상태를 만든다.
  static Future<DecorationRewardOffer> loadNextOffer() =>
      _serialize(_loadNextOffer);

  /// 새로 완료된 퀘스트의 보자기를 최대 한 개만 큐에 넣는다.
  ///
  /// 수령과 같은 직렬 체인을 쓰므로, 수령 중에 뒤늦게 지급된 보상 상자가
  /// 첫 상자 소비 write와 경합해 유실되지 않는다. 새 생산 경로는 알 수 없는
  /// 출처를 저장하지 않아 화면이 복구할 수 없는 pending box를 만들지 않는다.
  static Future<void> ensurePendingBoxForQuest(String questId) =>
      _serialize(() => _ensurePendingBoxForQuest(questId));

  static Future<void> _ensurePendingBoxForQuest(String questId) async {
    if (!kQuestById.containsKey(questId)) {
      return;
    }
    if (Storage.pendingBoxes.contains(questId)) {
      return;
    }
    await Storage.addPendingBox(questId);
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
    if (!kQuestById.containsKey(sourceQuestId)) {
      return DecorationRewardOffer(
        state: DecorationRewardOfferState.unknownQuest,
        sourceQuestId: sourceQuestId,
      );
    }

    final candidates = candidatesForQuest(sourceQuestId);
    if (candidates.isEmpty) {
      return DecorationRewardOffer(
        state: DecorationRewardOfferState.noEligibleCandidates,
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
    if (!kQuestById.containsKey(sourceQuestId)) {
      return DecorationRewardClaimResult.unknownQuest;
    }

    final candidates = candidatesForQuest(sourceQuestId);
    if (candidates.isEmpty) {
      return DecorationRewardClaimResult.noEligibleCandidates;
    }
    if (!candidates.contains(slug)) {
      return DecorationRewardClaimResult.notOffered;
    }

    final journal = _RewardClaimJournal(
      sourceQuestId: sourceQuestId,
      decorationSlug: slug,
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
      await Storage.addOwnedDecor(journal.decorationSlug);
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
      await Storage.addOwnedDecor(journal.decorationSlug);
      await Storage.clearDecorationRewardClaimJournal();
      return DecorationRewardRecoveryResult.resumed;
    }
    return DecorationRewardRecoveryResult.conflict;
  }

  static bool _isClaimableJournal(_RewardClaimJournal journal) {
    if (!kQuestById.containsKey(journal.sourceQuestId)) {
      return false;
    }
    return candidatesForQuest(
      journal.sourceQuestId,
      owned: const <String>[],
    ).contains(journal.decorationSlug);
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

/// `kl_reward_claim_v1`의 유일한 해석기. Journal은 pending 목록 전체를 같이
/// 보관해 반복 출처 ID에서도 정확히 처음 선택한 상자 하나만 제거할 수 있다.
class _RewardClaimJournal {
  _RewardClaimJournal({
    required this.sourceQuestId,
    required this.decorationSlug,
    required List<String> pendingBefore,
  }) : stage = _RewardClaimStage.prepared,
       pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingBefore.skip(1));

  _RewardClaimJournal._decoded({
    required this.stage,
    required this.sourceQuestId,
    required this.decorationSlug,
    required List<String> pendingBefore,
    required List<String> pendingAfter,
  }) : pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingAfter);

  final _RewardClaimStage stage;
  final String sourceQuestId;
  final String decorationSlug;
  final List<String> pendingBefore;
  final List<String> pendingAfter;

  String toRawJson() => jsonEncode({
    'version': 1,
    'stage': _stageWire(stage),
    'sourceQuestId': sourceQuestId,
    'decorationSlug': decorationSlug,
    'pendingBefore': pendingBefore,
    'pendingAfter': pendingAfter,
  });

  static _RewardClaimJournal? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final version = decoded['version'];
      final stage = _stageFromWire(decoded['stage']);
      final sourceQuestId = decoded['sourceQuestId'];
      final decorationSlug = decoded['decorationSlug'];
      final pendingBefore = _stringList(decoded['pendingBefore']);
      final pendingAfter = _stringList(decoded['pendingAfter']);
      if (version is! int ||
          version != 1 ||
          stage == null ||
          sourceQuestId is! String ||
          sourceQuestId.isEmpty ||
          decorationSlug is! String ||
          decorationSlug.isEmpty ||
          pendingBefore == null ||
          pendingBefore.isEmpty ||
          pendingAfter == null ||
          sourceQuestId != pendingBefore.first ||
          !_sameList(pendingAfter, pendingBefore.skip(1))) {
        return null;
      }
      return _RewardClaimJournal._decoded(
        stage: stage,
        sourceQuestId: sourceQuestId,
        decorationSlug: decorationSlug,
        pendingBefore: pendingBefore,
        pendingAfter: pendingAfter,
      );
    } on Object {
      return null;
    }
  }

  _RewardClaimJournal withQueueCommitStarted() => _RewardClaimJournal._decoded(
    stage: _RewardClaimStage.queueCommitStarted,
    sourceQuestId: sourceQuestId,
    decorationSlug: decorationSlug,
    pendingBefore: pendingBefore,
    pendingAfter: pendingAfter,
  );

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
