part of 'decoration_reward_service.dart';

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
    this.receipt,
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
       receipt = null,
       ownedBefore = List<String>.unmodifiable(ownedBefore),
       pendingBefore = List<String>.unmodifiable(pendingBefore),
       pendingAfter = List<String>.unmodifiable(pendingBefore.skip(1));

  _RewardClaimJournal._decoded({
    required this.kind,
    required this.stage,
    required this.sourceQuestId,
    required this.decorationSlug,
    this.receipt,
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
  final DecorationRewardReceipt? receipt;
  final List<String> ownedBefore;
  final List<String> pendingBefore;
  final List<String> pendingAfter;

  String toRawJson() {
    final raw = <String, Object?>{
      'version': receipt == null ? 2 : 3,
      'kind': _kindWire(kind),
      'stage': _stageWire(stage),
      'sourceQuestId': sourceQuestId,
      'ownedBefore': ownedBefore,
      'pendingBefore': pendingBefore,
      'pendingAfter': pendingAfter,
    };
    if (kind == _RewardClaimKind.decoration) {
      raw['decorationSlug'] = decorationSlug;
      if (receipt != null) {
        raw['receipt'] = receipt!.toJson();
      }
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
      if (version == 3) {
        final journal = _tryParseV2(decoded);
        final rawReceipt = decoded['receipt'];
        if (journal == null ||
            journal.kind != _RewardClaimKind.decoration ||
            rawReceipt is! Map<String, dynamic>) {
          return null;
        }
        final receipt = DecorationRewardReceipt.fromJson(rawReceipt);
        if (receipt.sourceQuestId != journal.sourceQuestId ||
            receipt.decorationSlug != journal.decorationSlug ||
            receipt.acknowledged) {
          return null;
        }
        return journal.withReceipt(receipt);
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
    receipt: receipt,
    ownedBefore: ownedBefore,
    pendingBefore: pendingBefore,
    pendingAfter: pendingAfter,
  );

  _RewardClaimJournal withReceipt(DecorationRewardReceipt value) =>
      _RewardClaimJournal._decoded(
        kind: kind,
        stage: stage,
        sourceQuestId: sourceQuestId,
        decorationSlug: decorationSlug,
        receipt: value,
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
