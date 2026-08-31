/// 일두고택 건설 진행도 스냅샷 (Phase 1).
///
/// 진행도는 **anchorId(월드 인스턴스) 단위**로 저장한다 (설계 결정 D9).
/// 협문 3개·화장실 2개처럼 여러 인스턴스가 하나의
/// `IlDuBuildingConstructionPlan` 을 공유해도, 각 인스턴스의 완료 단계·모듈·
/// 초안은 서로 섞이지 않는다.
///
/// 직렬화는 결정론적이다 — 앵커 키와 모든 집합/맵을 정렬해 내보내므로 같은
/// 상태는 항상 같은 바이트가 된다. 순수 Dart 파일이며 저장 경계는
/// `lib/services/ildu_construction_progress_service.dart` 가 담당한다.
library;

import 'dart:collection';

/// 초안 하나의 최대 길이 (유니코드 코드포인트 기준).
const kIlDuConstructionDraftMaxCodePoints = 600;

/// planVersion 변경 시 자동 매핑되지 않은 완료 ID 를 삭제하지 않고 보관하는
/// 큐 (설계 §14). 새 플랜에 같은 ID 가 돌아오면 완료로 복원된다.
final class IlDuConstructionRecoveryQueue {
  IlDuConstructionRecoveryQueue({
    required Set<String> stageIds,
    required Set<String> moduleIds,
  }) : stageIds = Set.unmodifiable(SplayTreeSet.of(stageIds)),
       moduleIds = Set.unmodifiable(SplayTreeSet.of(moduleIds));

  static final empty = IlDuConstructionRecoveryQueue(
    stageIds: const {},
    moduleIds: const {},
  );

  final Set<String> stageIds;
  final Set<String> moduleIds;

  bool get isEmpty => stageIds.isEmpty && moduleIds.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'stageIds': stageIds.toList(),
    'moduleIds': moduleIds.toList(),
  };

  factory IlDuConstructionRecoveryQueue.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuConstructionRecoveryQueue(
      stageIds: _idSet(json['stageIds'], '$path.stageIds'),
      moduleIds: _idSet(json['moduleIds'], '$path.moduleIds'),
    );
  }
}

/// 앵커(건물 인스턴스) 하나의 진행 기록.
final class IlDuAnchorConstructionProgress {
  IlDuAnchorConstructionProgress({
    required this.buildingId,
    required this.planVersion,
    required Set<String> completedStageIds,
    required Set<String> completedModuleIds,
    required Map<String, String> draftsByModuleId,
    required this.recoveryQueue,
  }) : completedStageIds = Set.unmodifiable(SplayTreeSet.of(completedStageIds)),
       completedModuleIds = Set.unmodifiable(
         SplayTreeSet.of(completedModuleIds),
       ),
       draftsByModuleId = Map.unmodifiable(
         SplayTreeMap.of(draftsByModuleId),
       ) {
    for (final draft in draftsByModuleId.values) {
      if (draft.runes.length > kIlDuConstructionDraftMaxCodePoints) {
        throw ArgumentError.value(
          draft,
          'draftsByModuleId',
          'A draft exceeds $kIlDuConstructionDraftMaxCodePoints code points',
        );
      }
    }
  }

  factory IlDuAnchorConstructionProgress.fresh({
    required String buildingId,
    required String planVersion,
  }) => IlDuAnchorConstructionProgress(
    buildingId: buildingId,
    planVersion: planVersion,
    completedStageIds: const {},
    completedModuleIds: const {},
    draftsByModuleId: const {},
    recoveryQueue: IlDuConstructionRecoveryQueue.empty,
  );

  final String buildingId;

  /// 이 기록이 마지막으로 정합화된 건물 planVersion.
  final String planVersion;
  final Set<String> completedStageIds;
  final Set<String> completedModuleIds;
  final Map<String, String> draftsByModuleId;
  final IlDuConstructionRecoveryQueue recoveryQueue;

  IlDuAnchorConstructionProgress copyWith({
    String? planVersion,
    Set<String>? completedStageIds,
    Set<String>? completedModuleIds,
    Map<String, String>? draftsByModuleId,
    IlDuConstructionRecoveryQueue? recoveryQueue,
  }) => IlDuAnchorConstructionProgress(
    buildingId: buildingId,
    planVersion: planVersion ?? this.planVersion,
    completedStageIds: completedStageIds ?? this.completedStageIds,
    completedModuleIds: completedModuleIds ?? this.completedModuleIds,
    draftsByModuleId: draftsByModuleId ?? this.draftsByModuleId,
    recoveryQueue: recoveryQueue ?? this.recoveryQueue,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'buildingId': buildingId,
    'planVersion': planVersion,
    'completedStageIds': completedStageIds.toList(),
    'completedModuleIds': completedModuleIds.toList(),
    'draftsByModuleId': draftsByModuleId,
    'recoveryQueue': recoveryQueue.toJson(),
  };

  factory IlDuAnchorConstructionProgress.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final rawDrafts = _map(json['draftsByModuleId'], '$path.draftsByModuleId');
    final drafts = <String, String>{};
    rawDrafts.forEach((moduleId, draft) {
      if (draft is! String) {
        throw FormatException(
          '$path.draftsByModuleId.$moduleId must be a string.',
        );
      }
      drafts[moduleId] = draft;
    });
    return IlDuAnchorConstructionProgress(
      buildingId: _id(json['buildingId'], '$path.buildingId'),
      planVersion: _id(json['planVersion'], '$path.planVersion'),
      completedStageIds: _idSet(
        json['completedStageIds'],
        '$path.completedStageIds',
      ),
      completedModuleIds: _idSet(
        json['completedModuleIds'],
        '$path.completedModuleIds',
      ),
      draftsByModuleId: drafts,
      recoveryQueue: IlDuConstructionRecoveryQueue.fromJson(
        json['recoveryQueue'],
        '$path.recoveryQueue',
      ),
    );
  }
}

/// 전체 건설 진행도. 앵커 키로 정렬된 결정론적 스냅샷이다.
final class IlDuConstructionProgress {
  IlDuConstructionProgress({
    required Map<String, IlDuAnchorConstructionProgress> anchors,
  }) : anchors = Map.unmodifiable(SplayTreeMap.of(anchors));

  factory IlDuConstructionProgress.empty() =>
      IlDuConstructionProgress(anchors: const {});

  /// 스냅샷 스키마 버전. 저장 키(`kl_ildu_construction_progress_v1`)와 함께
  /// 마이그레이션 기준이 된다.
  static const schemaVersion = 1;

  final Map<String, IlDuAnchorConstructionProgress> anchors;

  IlDuAnchorConstructionProgress? anchorFor(String anchorId) =>
      anchors[anchorId];

  IlDuConstructionProgress withAnchor(
    String anchorId,
    IlDuAnchorConstructionProgress record,
  ) => IlDuConstructionProgress(anchors: {...anchors, anchorId: record});

  /// 정렬 키 결정론 직렬화 — 같은 상태는 항상 같은 JSON 을 만든다.
  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'anchors': {
      for (final entry in anchors.entries) entry.key: entry.value.toJson(),
    },
  };

  factory IlDuConstructionProgress.fromJson(Object? value) {
    const path = 'progress';
    final json = _map(value, path);
    if (json['schemaVersion'] != schemaVersion) {
      throw FormatException('$path.schemaVersion must be $schemaVersion.');
    }
    final rawAnchors = _map(json['anchors'], '$path.anchors');
    final anchors = <String, IlDuAnchorConstructionProgress>{};
    rawAnchors.forEach((anchorId, record) {
      if (anchorId.trim().isEmpty) {
        throw FormatException('$path.anchors has an empty anchor ID.');
      }
      anchors[anchorId] = IlDuAnchorConstructionProgress.fromJson(
        record,
        '$path.anchors.$anchorId',
      );
    });
    return IlDuConstructionProgress(anchors: anchors);
  }
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return value.map((key, entry) {
    if (key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    return MapEntry(key, entry);
  });
}

String _id(Object? value, String path) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('$path must be a non-empty string.');
}

Set<String> _idSet(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path must be a list.');
  }
  final result = <String>{};
  for (final (i, id) in value.indexed) {
    result.add(_id(id, '$path[$i]'));
  }
  return result;
}
