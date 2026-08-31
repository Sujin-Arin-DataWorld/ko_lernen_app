import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ildu_construction_plan.dart';
import '../models/ildu_construction_progress.dart';

/// 진행도 쓰기가 거부됐을 때 던진다. 서비스는 이 예외를 던지기 전에
/// 메모리 스냅샷을 이전 상태로 유지하므로, 호출자는 사용자의 답안·진행을
/// 잃지 않고 재시도할 수 있다 (설계 §14).
final class IlDuConstructionProgressWriteException implements Exception {
  const IlDuConstructionProgressWriteException(this.cause);

  final Object? cause;

  @override
  String toString() => 'IlDuConstructionProgressWriteException($cause)';
}

/// 저장 매체 경계. 화면·서비스 테스트는 메모리 구현을 주입한다.
abstract interface class IlDuConstructionProgressStore {
  Future<String?> read();

  Future<void> write(String encoded);
}

/// SharedPreferences 구현. 키는 스키마 버전을 포함한다.
final class SharedPreferencesIlDuConstructionProgressStore
    implements IlDuConstructionProgressStore {
  const SharedPreferencesIlDuConstructionProgressStore();

  static const key = 'kl_ildu_construction_progress_v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String encoded) async {
    final ok = await (await SharedPreferences.getInstance()).setString(
      key,
      encoded,
    );
    if (!ok) {
      throw StateError('SharedPreferences rejected the progress write.');
    }
  }
}

/// 일두 건설 진행도의 단일 조정자.
///
/// - 진행도는 anchorId(월드 인스턴스) 단위로 기록한다 (D9).
/// - 단계는 순서대로만 완료된다: 앞선 단계가 모두 완료되고 필수 모듈이 모두
///   완료된 단계만 완료로 승격한다.
/// - 무후퇴: 어떤 공개 연산도 완료된 단계·모듈을 제거하지 않는다.
/// - planVersion 이 바뀌면 새 플랜에 존재하는 안정 ID 를 우선 매핑하고,
///   매핑되지 않는 ID 는 삭제 대신 recoveryQueue 에 보관한다 (설계 §14).
final class IlDuConstructionProgressService {
  IlDuConstructionProgressService({
    required this._plan,
    required this._store,
  });

  /// 스냅샷 전체의 직렬화 상한 (바이트).
  static const maxEncodedBytes = 64 * 1024;

  IlDuEstateConstructionPlan _plan;
  final IlDuConstructionProgressStore _store;
  IlDuConstructionProgress _snapshot = IlDuConstructionProgress.empty();
  bool _initialized = false;

  IlDuConstructionProgress get snapshot => _snapshot;

  /// 저장소에서 진행도를 읽고 현재 플랜과 정합화한다.
  ///
  /// 저장값이 손상된 경우(FormatException) 빈 진행도로 시작하되, 즉시
  /// 덮어쓰지 않는다 — 손상된 원본은 다음 성공적인 쓰기 전까지 저장소에
  /// 그대로 남아 조사할 수 있다.
  Future<void> initialize() async {
    final raw = await _store.read();
    var loaded = IlDuConstructionProgress.empty();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        loaded = IlDuConstructionProgress.fromJson(jsonDecode(raw));
      } on FormatException {
        loaded = IlDuConstructionProgress.empty();
      }
    }
    _snapshot = loaded;
    _initialized = true;
    final reconciled = _reconciledWith(_plan, loaded);
    if (!identical(reconciled, loaded)) {
      await _commit(reconciled);
    }
  }

  /// 학습자의 초안을 앵커·모듈 단위로 보존한다. 빈 문자열은 초안 삭제다.
  Future<void> saveDraft({
    required String anchorId,
    required String buildingId,
    required String moduleId,
    required String text,
  }) async {
    _assertInitialized();
    if (text.runes.length > kIlDuConstructionDraftMaxCodePoints) {
      throw ArgumentError.value(
        text,
        'text',
        'Drafts are limited to $kIlDuConstructionDraftMaxCodePoints '
            'code points',
      );
    }
    final record = _anchorRecord(anchorId, buildingId);
    if (!_plan.hasModule(moduleId)) {
      throw ArgumentError.value(moduleId, 'moduleId', 'Unknown module');
    }
    final drafts = {...record.draftsByModuleId};
    if (text.isEmpty) {
      if (!drafts.containsKey(moduleId)) {
        return;
      }
      drafts.remove(moduleId);
    } else {
      if (drafts[moduleId] == text) {
        return;
      }
      drafts[moduleId] = text;
    }
    await _commit(
      _snapshot.withAnchor(anchorId, record.copyWith(draftsByModuleId: drafts)),
    );
  }

  /// 모듈 완료를 기록하고, 조건을 채운 단계를 순서대로 완료로 승격한다.
  ///
  /// 쓰기가 거부되면 메모리 스냅샷을 이전 상태로 유지한 채
  /// [IlDuConstructionProgressWriteException] 을 던진다.
  Future<void> completeModule({
    required String anchorId,
    required String buildingId,
    required String moduleId,
  }) async {
    _assertInitialized();
    final building = _plan.buildingFor(buildingId);
    if (!_plan.hasModule(moduleId)) {
      throw ArgumentError.value(moduleId, 'moduleId', 'Unknown module');
    }
    final referenced = building.stages.any(
      (stage) =>
          stage.requiredModuleIds.contains(moduleId) ||
          stage.optionalModuleIds.contains(moduleId),
    );
    if (!referenced) {
      throw ArgumentError.value(
        moduleId,
        'moduleId',
        'Module is not part of building "$buildingId"',
      );
    }
    final record = _anchorRecord(anchorId, buildingId);
    if (record.completedModuleIds.contains(moduleId)) {
      return;
    }
    final completedModules = {...record.completedModuleIds, moduleId};
    final completedStages = _sweepStages(building, record, completedModules);
    final drafts = {...record.draftsByModuleId}..remove(moduleId);
    await _commit(
      _snapshot.withAnchor(
        anchorId,
        record.copyWith(
          completedModuleIds: completedModules,
          completedStageIds: completedStages,
          draftsByModuleId: drafts,
        ),
      ),
    );
  }

  /// 이 앵커에서 학습자가 지금 보고·작업할 단계: 첫 미완료 단계, 전부
  /// 완료면 마지막 단계.
  IlDuConstructionStage currentStage({
    required String anchorId,
    required String buildingId,
  }) {
    _assertInitialized();
    final building = _plan.buildingFor(buildingId);
    final record = _snapshot.anchorFor(anchorId);
    if (record != null && record.buildingId != buildingId) {
      throw ArgumentError.value(
        buildingId,
        'buildingId',
        'Anchor "$anchorId" belongs to building "${record.buildingId}"',
      );
    }
    final completed = record?.completedStageIds ?? const <String>{};
    for (final stage in building.stages) {
      if (!completed.contains(stage.stageId)) {
        return stage;
      }
    }
    return building.stages.last;
  }

  /// 새 플랜으로 교체하고 저장된 진행도를 정합화한다 (설계 §14).
  Future<void> reconcile(IlDuEstateConstructionPlan newPlan) async {
    _assertInitialized();
    final reconciled = _reconciledWith(newPlan, _snapshot);
    _plan = newPlan;
    if (!identical(reconciled, _snapshot)) {
      await _commit(reconciled);
    }
  }

  // -------------------------------------------------------------------------

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'IlDuConstructionProgressService.initialize() must run first.',
      );
    }
  }

  IlDuAnchorConstructionProgress _anchorRecord(
    String anchorId,
    String buildingId,
  ) {
    if (anchorId.trim().isEmpty) {
      throw ArgumentError.value(anchorId, 'anchorId', 'Must not be empty');
    }
    final building = _plan.buildingFor(buildingId);
    final existing = _snapshot.anchorFor(anchorId);
    if (existing == null) {
      return IlDuAnchorConstructionProgress.fresh(
        buildingId: building.buildingId,
        planVersion: building.planVersion,
      );
    }
    if (existing.buildingId != buildingId) {
      throw ArgumentError.value(
        buildingId,
        'buildingId',
        'Anchor "$anchorId" belongs to building "${existing.buildingId}"',
      );
    }
    return existing;
  }

  /// 단계 완료 스윕: 순서대로, 앞선 단계가 전부 완료되고 필수 모듈이 모두
  /// 완료된 단계만 완료로 올린다. 이미 완료된 단계는 절대 내리지 않는다.
  Set<String> _sweepStages(
    IlDuBuildingConstructionPlan building,
    IlDuAnchorConstructionProgress record,
    Set<String> completedModules,
  ) {
    final completedStages = {...record.completedStageIds};
    for (final stage in building.stages) {
      if (completedStages.contains(stage.stageId)) {
        continue;
      }
      final requirementsMet = stage.requiredModuleIds.every(
        completedModules.contains,
      );
      if (!requirementsMet) {
        break;
      }
      completedStages.add(stage.stageId);
    }
    return completedStages;
  }

  /// 새 플랜 기준의 정합화. 아무 것도 삭제하지 않는다:
  /// - 새 플랜에 존재하는 완료 ID 는 완료로 유지된다.
  /// - 존재하지 않는 완료 ID 는 recoveryQueue 로 이동한다.
  /// - recoveryQueue 에 있던 ID 가 새 플랜에 돌아오면 완료로 복원된다.
  /// - 플랜에 없는 건물의 앵커 기록은 그대로 보존한다.
  IlDuConstructionProgress _reconciledWith(
    IlDuEstateConstructionPlan plan,
    IlDuConstructionProgress progress,
  ) {
    var changed = false;
    final anchors = <String, IlDuAnchorConstructionProgress>{};
    progress.anchors.forEach((anchorId, record) {
      if (!plan.hasBuilding(record.buildingId)) {
        anchors[anchorId] = record;
        return;
      }
      final building = plan.buildingFor(record.buildingId);
      final knownStageIds = {
        for (final stage in building.stages) stage.stageId,
      };
      bool knownModule(String moduleId) => plan.hasModule(moduleId);

      final completedStages = <String>{};
      final queuedStages = {...record.recoveryQueue.stageIds};
      for (final stageId in record.completedStageIds) {
        (knownStageIds.contains(stageId) ? completedStages : queuedStages).add(
          stageId,
        );
      }
      for (final stageId in record.recoveryQueue.stageIds) {
        if (knownStageIds.contains(stageId)) {
          queuedStages.remove(stageId);
          completedStages.add(stageId);
        }
      }

      final completedModules = <String>{};
      final queuedModules = {...record.recoveryQueue.moduleIds};
      for (final moduleId in record.completedModuleIds) {
        (knownModule(moduleId) ? completedModules : queuedModules).add(
          moduleId,
        );
      }
      for (final moduleId in record.recoveryQueue.moduleIds) {
        if (knownModule(moduleId)) {
          queuedModules.remove(moduleId);
          completedModules.add(moduleId);
        }
      }

      final reconciled = record.copyWith(
        planVersion: building.planVersion,
        completedStageIds: completedStages,
        completedModuleIds: completedModules,
        recoveryQueue: IlDuConstructionRecoveryQueue(
          stageIds: queuedStages,
          moduleIds: queuedModules,
        ),
      );
      changed = changed || !_sameRecord(record, reconciled);
      anchors[anchorId] = reconciled;
    });
    if (!changed) {
      return progress;
    }
    return IlDuConstructionProgress(anchors: anchors);
  }

  bool _sameRecord(
    IlDuAnchorConstructionProgress a,
    IlDuAnchorConstructionProgress b,
  ) => jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  /// 스냅샷 후보를 인코딩·검증·저장하고 성공 시에만 메모리에 반영한다.
  Future<void> _commit(IlDuConstructionProgress candidate) async {
    final encoded = jsonEncode(candidate.toJson());
    if (utf8.encode(encoded).length > maxEncodedBytes) {
      throw IlDuConstructionProgressWriteException(
        StateError('Encoded progress exceeds $maxEncodedBytes bytes.'),
      );
    }
    try {
      await _store.write(encoded);
    } catch (cause) {
      throw IlDuConstructionProgressWriteException(cause);
    }
    _snapshot = candidate;
  }
}
