import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/models/ildu_construction_progress.dart';
import 'package:ko_lernen_app/services/ildu_construction_progress_service.dart';

/// anchorId 단위 진행 저장(D9)·순서 있는 단계 완료·무후퇴·복구 큐(§14)
/// 계약 테스트.
void main() {
  group('IlDuConstructionProgressService', () {
    test('completes a stage only after every required module', () async {
      final service = await _initializedService(_twoModuleStagePlan());
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-a',
      );
      expect(_anchor(service, 'gate-a').completedStageIds, isEmpty);
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-b',
      );
      expect(
        _anchor(service, 'gate-a').completedStageIds,
        contains('hyeopmun-site'),
      );
    });

    test('promotes stages strictly in order', () async {
      final service = await _initializedService(_threeStagePlan());
      // 뒤 단계의 필수 모듈부터 완료해도 앞 단계가 열리기 전에는 단계가
      // 승격되지 않는다.
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-frame',
      );
      expect(_anchor(service, 'gate-a').completedStageIds, isEmpty);
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      expect(
        _anchor(service, 'gate-a').completedStageIds,
        containsAll(['hyeopmun-site', 'hyeopmun-frame']),
      );
    });

    test('keeps progress separate per anchor instance (D9)', () async {
      final service = await _initializedService(_threeStagePlan());
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      expect(
        _anchor(service, 'gate-a').completedStageIds,
        contains('hyeopmun-site'),
      );
      expect(service.snapshot.anchorFor('gate-b'), isNull);
      expect(
        service
            .currentStage(anchorId: 'gate-b', buildingId: 'hyeopmun')
            .stageId,
        'hyeopmun-site',
      );
      expect(
        service
            .currentStage(anchorId: 'gate-a', buildingId: 'hyeopmun')
            .stageId,
        'hyeopmun-frame',
      );
    });

    test('currentStage returns the final stage when everything is complete',
        () async {
      final service = await _initializedService(_threeStagePlan());
      for (final moduleId in ['module-site', 'module-frame', 'module-done']) {
        await service.completeModule(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: moduleId,
        );
      }
      expect(
        service
            .currentStage(anchorId: 'gate-a', buildingId: 'hyeopmun')
            .stageId,
        'hyeopmun-complete',
      );
    });

    test('serializes deterministically regardless of completion order',
        () async {
      final storeA = MemoryIlDuConstructionProgressStore();
      final storeB = MemoryIlDuConstructionProgressStore();
      final serviceA = await _initializedService(
        _threeStagePlan(),
        store: storeA,
      );
      final serviceB = await _initializedService(
        _threeStagePlan(),
        store: storeB,
      );
      for (final moduleId in ['module-site', 'module-frame']) {
        await serviceA.completeModule(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: moduleId,
        );
      }
      await serviceA.saveDraft(
        anchorId: 'gate-b',
        buildingId: 'hyeopmun',
        moduleId: 'module-done',
        text: '초안',
      );
      // 반대 순서로 같은 상태를 만든다.
      await serviceB.saveDraft(
        anchorId: 'gate-b',
        buildingId: 'hyeopmun',
        moduleId: 'module-done',
        text: '초안',
      );
      for (final moduleId in ['module-frame', 'module-site']) {
        await serviceB.completeModule(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: moduleId,
        );
      }
      expect(storeA.value, storeB.value);
    });

    test('a rejected write keeps the previous snapshot and rethrows',
        () async {
      final store = MemoryIlDuConstructionProgressStore();
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      final before = jsonEncode(service.snapshot.toJson());
      store.rejectWrites = true;
      await expectLater(
        service.completeModule(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: 'module-frame',
        ),
        throwsA(isA<IlDuConstructionProgressWriteException>()),
      );
      expect(jsonEncode(service.snapshot.toJson()), before);
      expect(
        _anchor(service, 'gate-a').completedModuleIds,
        isNot(contains('module-frame')),
      );
    });

    test('drafts survive, are anchor-scoped, and cap at 600 code points',
        () async {
      final store = MemoryIlDuConstructionProgressStore();
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      await service.saveDraft(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
        text: '그냥 넘기기에는 아쉬운 초안',
      );
      final reloaded = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      expect(
        _anchor(reloaded, 'gate-a').draftsByModuleId['module-site'],
        '그냥 넘기기에는 아쉬운 초안',
      );
      await expectLater(
        service.saveDraft(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: 'module-site',
          text: '가' * 601,
        ),
        throwsArgumentError,
      );
      // 600 코드포인트 정확히는 허용된다.
      await service.saveDraft(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
        text: '가' * 600,
      );
    });

    test('keeps unknown completed IDs in the recovery queue (§14)', () async {
      final store = MemoryIlDuConstructionProgressStore()
        ..value = jsonEncode({
          'schemaVersion': 1,
          'anchors': {
            'gate-a': {
              'buildingId': 'hyeopmun',
              'planVersion': 'hyeopmun-v0',
              'completedStageIds': ['removed-stage', 'hyeopmun-site'],
              'completedModuleIds': ['removed-module', 'module-site'],
              'draftsByModuleId': {'module-frame': '이어 쓰던 초안'},
              'recoveryQueue': {
                'stageIds': <String>[],
                'moduleIds': <String>[],
              },
            },
          },
        });
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      final anchor = _anchor(service, 'gate-a');
      // 새 플랜에 있는 안정 ID 는 완료로 유지된다 (무후퇴).
      expect(anchor.completedStageIds, contains('hyeopmun-site'));
      expect(anchor.completedModuleIds, contains('module-site'));
      // 매핑되지 않는 ID 는 삭제되지 않고 복구 큐에 남는다.
      expect(anchor.recoveryQueue.stageIds, contains('removed-stage'));
      expect(anchor.recoveryQueue.moduleIds, contains('removed-module'));
      // planVersion 은 현재 건물 버전으로 올라간다.
      expect(anchor.planVersion, 'hyeopmun-v1');
      // 초안은 그대로 보존된다.
      expect(anchor.draftsByModuleId['module-frame'], '이어 쓰던 초안');
    });

    test('reconcile restores queued IDs that return in a newer plan',
        () async {
      final store = MemoryIlDuConstructionProgressStore()
        ..value = jsonEncode({
          'schemaVersion': 1,
          'anchors': {
            'gate-a': {
              'buildingId': 'hyeopmun',
              'planVersion': 'hyeopmun-v0',
              'completedStageIds': <String>[],
              'completedModuleIds': <String>[],
              'draftsByModuleId': <String, String>{},
              'recoveryQueue': {
                'stageIds': ['hyeopmun-frame'],
                'moduleIds': ['module-frame'],
              },
            },
          },
        });
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      final anchor = _anchor(service, 'gate-a');
      expect(anchor.recoveryQueue.isEmpty, isTrue);
      expect(anchor.completedStageIds, contains('hyeopmun-frame'));
      expect(anchor.completedModuleIds, contains('module-frame'));
    });

    test('rejects a snapshot that exceeds the 64KiB budget', () async {
      final store = MemoryIlDuConstructionProgressStore();
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      // 앵커 수는 계약이 제한하지 않으므로, 많은 앵커 초안으로 예산을
      // 넘겨 본다. 실패한 쓰기는 이전 스냅샷을 유지해야 한다.
      Future<void> flood() async {
        for (var i = 0; i < 300; i++) {
          await service.saveDraft(
            anchorId: 'gate-$i',
            buildingId: 'hyeopmun',
            moduleId: 'module-site',
            text: '가' * 200,
          );
        }
      }

      await expectLater(
        flood(),
        throwsA(isA<IlDuConstructionProgressWriteException>()),
      );
      final persisted = store.value;
      expect(persisted, isNotNull);
      expect(utf8.encode(persisted!).length,
          lessThanOrEqualTo(IlDuConstructionProgressService.maxEncodedBytes));
      expect(
        jsonEncode(service.snapshot.toJson()),
        persisted,
        reason: '실패한 쓰기가 메모리 스냅샷을 오염시키면 안 된다',
      );
    });

    test('completing a module never removes earlier completions', () async {
      final service = await _initializedService(_threeStagePlan());
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      final anchor = _anchor(service, 'gate-a');
      expect(anchor.completedStageIds, contains('hyeopmun-site'));
      expect(anchor.completedModuleIds, contains('module-site'));
    });

    test('rejects a module that does not belong to the building', () async {
      final service = await _initializedService(_threeStagePlan());
      await expectLater(
        service.completeModule(
          anchorId: 'gate-a',
          buildingId: 'hyeopmun',
          moduleId: 'no-such-module',
        ),
        throwsArgumentError,
      );
    });

    test('an anchor cannot silently switch buildings', () async {
      final service = await _initializedService(_twoBuildingPlan());
      await service.completeModule(
        anchorId: 'gate-a',
        buildingId: 'hyeopmun',
        moduleId: 'module-site',
      );
      await expectLater(
        service.completeModule(
          anchorId: 'gate-a',
          buildingId: 'byeoltto',
          moduleId: 'module-other',
        ),
        throwsArgumentError,
      );
    });

    test('a malformed stored value starts empty without overwriting it',
        () async {
      final store = MemoryIlDuConstructionProgressStore()..value = '{broken';
      final service = await _initializedService(
        _threeStagePlan(),
        store: store,
      );
      expect(service.snapshot.anchors, isEmpty);
      // 손상된 원본은 성공적인 다음 쓰기 전까지 저장소에 남는다.
      expect(store.value, '{broken');
    });
  });
}

// ---------------------------------------------------------------------------

final class MemoryIlDuConstructionProgressStore
    implements IlDuConstructionProgressStore {
  String? value;
  bool rejectWrites = false;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encoded) async {
    if (rejectWrites) {
      throw StateError('rejected test write');
    }
    value = encoded;
  }
}

IlDuAnchorConstructionProgress _anchor(
  IlDuConstructionProgressService service,
  String anchorId,
) {
  final record = service.snapshot.anchorFor(anchorId);
  expect(record, isNotNull, reason: 'anchor $anchorId must exist');
  return record!;
}

Future<IlDuConstructionProgressService> _initializedService(
  IlDuEstateConstructionPlan plan, {
  MemoryIlDuConstructionProgressStore? store,
}) async {
  final service = IlDuConstructionProgressService(
    plan: plan,
    store: store ?? MemoryIlDuConstructionProgressStore(),
  );
  await service.initialize();
  return service;
}

/// 한 단계에 필수 모듈이 두 개인 최소 플랜.
IlDuEstateConstructionPlan _twoModuleStagePlan() => _plan(
  stages: [
    _stage(
      stageId: 'hyeopmun-site',
      sequence: 1,
      requiredModuleIds: ['module-a', 'module-b'],
      fallbackStageId: null,
    ),
  ],
  moduleIds: ['module-a', 'module-b'],
);

/// 세 단계짜리 협문 플랜.
IlDuEstateConstructionPlan _threeStagePlan() => _plan(
  stages: [
    _stage(
      stageId: 'hyeopmun-site',
      sequence: 1,
      requiredModuleIds: ['module-site'],
      fallbackStageId: null,
    ),
    _stage(
      stageId: 'hyeopmun-frame',
      sequence: 2,
      requiredModuleIds: ['module-frame'],
      fallbackStageId: 'hyeopmun-site',
    ),
    _stage(
      stageId: 'hyeopmun-complete',
      sequence: 3,
      requiredModuleIds: ['module-done'],
      fallbackStageId: 'hyeopmun-frame',
    ),
  ],
  moduleIds: ['module-site', 'module-frame', 'module-done'],
);

IlDuEstateConstructionPlan _twoBuildingPlan() =>
    IlDuEstateConstructionPlan.fromJson(
      _indexJson(
        buildingOrder: ['hyeopmun', 'byeoltto'],
        buildings: [
          {
            'buildingId': 'hyeopmun',
            'file': 'hyeopmun_v1.json',
            'planVersion': 'hyeopmun-v1',
          },
          {
            'buildingId': 'byeoltto',
            'file': 'byeoltto_v1.json',
            'planVersion': 'byeoltto-v1',
          },
        ],
      ),
      {
        'hyeopmun': _buildingDoc(
          buildingId: 'hyeopmun',
          planVersion: 'hyeopmun-v1',
          stages: [
            _stage(
              stageId: 'hyeopmun-site',
              sequence: 1,
              requiredModuleIds: ['module-site'],
              fallbackStageId: null,
            ),
          ],
          moduleIds: ['module-site'],
        ),
        'byeoltto': _buildingDoc(
          buildingId: 'byeoltto',
          planVersion: 'byeoltto-v1',
          stages: [
            _stage(
              stageId: 'byeoltto-site',
              sequence: 1,
              requiredModuleIds: ['module-other'],
              fallbackStageId: null,
            ),
          ],
          moduleIds: ['module-other'],
        ),
      },
    );

IlDuEstateConstructionPlan _plan({
  required List<Map<String, Object?>> stages,
  required List<String> moduleIds,
}) => IlDuEstateConstructionPlan.fromJson(
  _indexJson(
    buildingOrder: ['hyeopmun'],
    buildings: [
      {
        'buildingId': 'hyeopmun',
        'file': 'hyeopmun_v1.json',
        'planVersion': 'hyeopmun-v1',
      },
    ],
  ),
  {
    'hyeopmun': _buildingDoc(
      buildingId: 'hyeopmun',
      planVersion: 'hyeopmun-v1',
      stages: stages,
      moduleIds: moduleIds,
    ),
  },
);

Map<String, Object?> _indexJson({
  required List<String> buildingOrder,
  required List<Map<String, Object?>> buildings,
}) => <String, Object?>{
  'schemaVersion': 1,
  'estateId': 'ildu-gotaek-v3',
  'planVersion': 'test-v1',
  'canvas': {'width': 2412, 'height': 2622},
  'viewport': {'width': 1206, 'height': 2622},
  'siteStageIds': <String>[],
  'buildingOrder': buildingOrder,
  'buildings': buildings,
};

Map<String, Object?> _buildingDoc({
  required String buildingId,
  required String planVersion,
  required List<Map<String, Object?>> stages,
  required List<String> moduleIds,
}) => <String, Object?>{
  'schemaVersion': 1,
  'building': <String, Object?>{
    'buildingId': buildingId,
    'planVersion': planVersion,
    'canonicalAsset': 'master.png',
    'canonicalSha256':
        '0000000000000000000000000000000000000000000000000000000000000000',
    'buildingRole': '테스트 건물',
    'culturalMeaning': '테스트 의미',
    'stages': stages,
  },
  'modules': [for (final moduleId in moduleIds) _module(moduleId)],
};

Map<String, Object?> _stage({
  required String stageId,
  required int sequence,
  required List<String> requiredModuleIds,
  required String? fallbackStageId,
}) => <String, Object?>{
  'stageId': stageId,
  'sequence': sequence,
  'processTags': ['site'],
  'baseAsset': 'stage_0${sequence}_test.png',
  'overlayAssets': <String>[],
  'requiredModuleIds': requiredModuleIds,
  'optionalModuleIds': <String>[],
  'completionEffect': 'install-part',
  'fallbackStageId': fallbackStageId,
};

Map<String, Object?> _module(String moduleId) => <String, Object?>{
  'moduleId': moduleId,
  'sourceRefs': [
    'https://www.heritage.go.kr/heri/cul/culSelectDetail.do?ccbaCpno=1483801860000&pageNo=1_1_1_1',
  ],
  'levelBand': ['a1'],
  'knowledgeLenses': ['construction'],
  'copy': {
    for (final language in ['ko', 'de', 'en'])
      language: {
        'title': '제목 $language',
        'history': '역사 $language',
        'criticalLens': '비판 $language',
        'modernScene': '장면 $language',
        'sceneLine': '대사 $language',
        'actionPrompt': '행동 $language',
      },
  },
  'speechBrief': {
    'scene': '테스트 장면',
    'channel': '대면',
    'purpose': '제안',
    'speaker': '학습자',
    'addressee': '친구',
    'relationship': '가까운 친구',
    'speechStyle': '해체',
    'speechAct': '제안',
    'knownFacts': ['사실 하나'],
    'unresolvedFacts': ['미정 하나'],
    'forbiddenInvention': ['금지 하나'],
  },
  'targetExpressions': ['시작하자'],
  'acceptedVariants': ['일단 시작하자.'],
  'criteria': [
    {
      'id': 'criterion-$moduleId',
      'kind': 'meaningSlot',
      'acceptedVariants': ['시작하자'],
      'requiredForCompletion': true,
    },
  ],
  'scoredDimensions': ['communicativeFunction'],
  'completionEvidence': {'type': 'inApp'},
};
