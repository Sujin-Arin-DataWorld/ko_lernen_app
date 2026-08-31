import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/services/ildu_construction_plan_repository.dart';

/// 가변 단계 플랜 파서의 fail-closed 계약 테스트.
///
/// 픽스처는 일부러 **3단계짜리 협문**이다 — 파서가 8·12 같은 단계 수를
/// 도메인 불변식으로 갖지 않는다는 것(D2)을 사랑채와 무관한 수로 증명한다.
void main() {
  group('IlDuEstateConstructionPlan.fromJson', () {
    test('accepts a three-stage building without a fixed-count invariant', () {
      final plan = IlDuEstateConstructionPlan.fromJson(
        _validIndexJson(),
        _validBuildingDocs(),
      );
      expect(plan.estateId, 'ildu-gotaek-v3');
      expect(plan.canvas.width, 2412);
      expect(plan.canvas.height, 2622);
      expect(plan.viewport.width, 1206);
      expect(plan.buildingFor('hyeopmun').stages, hasLength(3));
      expect(plan.moduleFor('hyeopmun-frame-language').moduleId,
          'hyeopmun-frame-language');
    });

    test('rejects a wrong schema version and a wrong estate ID', () {
      final badVersion = _validIndexJson()..['schemaVersion'] = 2;
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          badVersion,
          _validBuildingDocs(),
        ),
        throwsFormatException,
      );
      final badEstate = _validIndexJson()..['estateId'] = 'other-estate';
      expect(
        () =>
            IlDuEstateConstructionPlan.fromJson(badEstate, _validBuildingDocs()),
        throwsFormatException,
      );
    });

    test('rejects a broken camera contract', () {
      final index = _validIndexJson();
      (index['viewport'] as Map)['width'] = 620;
      expect(
        () => IlDuEstateConstructionPlan.fromJson(index, _validBuildingDocs()),
        throwsFormatException,
      );
    });

    test('rejects duplicate stage IDs', () {
      final docs = _validBuildingDocs();
      final stages = _stagesOf(docs);
      (stages[2] as Map)['stageId'] = (stages[0] as Map)['stageId'];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects a sequence that is not strictly increasing', () {
      final docs = _validBuildingDocs();
      final stages = _stagesOf(docs);
      (stages[2] as Map)['sequence'] = 2;
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects an unknown required module reference', () {
      final docs = _validBuildingDocs();
      final stages = _stagesOf(docs);
      (stages[1] as Map)['requiredModuleIds'] = ['no-such-module'];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects a stage without required modules', () {
      final docs = _validBuildingDocs();
      final stages = _stagesOf(docs);
      (stages[1] as Map)['requiredModuleIds'] = <String>[];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('enforces the fallback integrity chain', () {
      // 첫 단계는 fallback 이 없어야 한다.
      final withFirstFallback = _validBuildingDocs();
      (_stagesOf(withFirstFallback)[0] as Map)['fallbackStageId'] =
          'hyeopmun-frame';
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          _validIndexJson(),
          withFirstFallback,
        ),
        throwsFormatException,
      );

      // 뒤 단계는 fallback 이 반드시 있어야 한다.
      final withoutFallback = _validBuildingDocs();
      (_stagesOf(withoutFallback)[1] as Map)['fallbackStageId'] = null;
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          _validIndexJson(),
          withoutFallback,
        ),
        throwsFormatException,
      );

      // fallback 은 더 이른 단계만 가리킬 수 있다.
      final laterFallback = _validBuildingDocs();
      (_stagesOf(laterFallback)[1] as Map)['fallbackStageId'] =
          'hyeopmun-complete';
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          _validIndexJson(),
          laterFallback,
        ),
        throwsFormatException,
      );
    });

    test('rejects an unknown process tag', () {
      final docs = _validBuildingDocs();
      (_stagesOf(docs)[1] as Map)['processTags'] = ['flyingButtress'];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects a non-HTTPS source reference', () {
      final docs = _validBuildingDocs();
      (_modulesOf(docs)[0] as Map)['sourceRefs'] = [
        'http://www.heritage.go.kr/insecure',
      ];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects a module without all three languages', () {
      final docs = _validBuildingDocs();
      ((_modulesOf(docs)[0] as Map)['copy'] as Map).remove('de');
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects any moral-stance scored dimension', () {
      final docs = _validBuildingDocs();
      (_modulesOf(docs)[0] as Map)['scoredDimensions'] = [
        'communicativeFunction',
        'stance',
      ];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects an unknown criterion kind', () {
      final docs = _validBuildingDocs();
      final criteria = (_modulesOf(docs)[0] as Map)['criteria'] as List;
      (criteria[0] as Map)['kind'] = 'moralJudgement';
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('validates completionEvidence variants (D3)', () {
      // canDoSegment 는 segmentId 가 필수다.
      final missingSegment = _validBuildingDocs();
      (_modulesOf(missingSegment)[0] as Map)['completionEvidence'] = {
        'type': 'canDoSegment',
      };
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          _validIndexJson(),
          missingSegment,
        ),
        throwsFormatException,
      );

      // 알 수 없는 증거 타입은 거부한다.
      final unknownType = _validBuildingDocs();
      (_modulesOf(unknownType)[0] as Map)['completionEvidence'] = {
        'type': 'vibes',
      };
      expect(
        () =>
            IlDuEstateConstructionPlan.fromJson(_validIndexJson(), unknownType),
        throwsFormatException,
      );

      // segmentId 가 있는 canDoSegment 는 유효하다.
      final canDo = _validBuildingDocs();
      (_modulesOf(canDo)[0] as Map)['completionEvidence'] = {
        'type': 'canDoSegment',
        'segmentId': 'a1-greetings-01',
      };
      final plan = IlDuEstateConstructionPlan.fromJson(_validIndexJson(), canDo);
      final evidence =
          plan.moduleFor('hyeopmun-site-language').completionEvidence;
      expect(evidence.type, IlDuCompletionEvidenceType.canDoSegment);
      expect(evidence.segmentId, 'a1-greetings-01');
    });

    test('rejects a building file whose planVersion disagrees with the index',
        () {
      final docs = _validBuildingDocs();
      ((docs['hyeopmun'] as Map)['building'] as Map)['planVersion'] =
          'hyeopmun-v2';
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects a missing building document', () {
      expect(
        () => IlDuEstateConstructionPlan.fromJson(
          _validIndexJson(),
          <String, Object?>{},
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate module IDs across the estate', () {
      final docs = _validBuildingDocs();
      final modules = _modulesOf(docs);
      (modules[1] as Map)['moduleId'] = (modules[0] as Map)['moduleId'];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(_validIndexJson(), docs),
        throwsFormatException,
      );
    });

    test('rejects an unresolved siteStageIds entry', () {
      final index = _validIndexJson()..['siteStageIds'] = ['no-such-stage'];
      expect(
        () => IlDuEstateConstructionPlan.fromJson(index, _validBuildingDocs()),
        throwsFormatException,
      );
    });
  });

  group('IlDuConstructionPlanRepository', () {
    test('assembles the estate plan from the index and building files',
        () async {
      final repository = IlDuConstructionPlanRepository(
        bundle: _MapAssetBundle(_validBundleEntries()),
      );
      final plan = await repository.load();
      expect(plan.buildingOrder, ['hyeopmun']);
      expect(plan.buildingFor('hyeopmun').planVersion, 'hyeopmun-v1');
    });

    test('caches a successful load', () async {
      final repository = IlDuConstructionPlanRepository(
        bundle: _MapAssetBundle(_validBundleEntries()),
      );
      final first = await repository.load();
      final second = await repository.load();
      expect(identical(first, second), isTrue);
    });

    test('fails closed on a malformed index and retries after failure',
        () async {
      final entries = _validBundleEntries();
      final good = entries[IlDuConstructionPlanRepository.indexAssetPath]!;
      entries[IlDuConstructionPlanRepository.indexAssetPath] = '{"broken": true}';
      final repository = IlDuConstructionPlanRepository(
        bundle: _MapAssetBundle(entries),
      );
      await expectLater(repository.load(), throwsFormatException);
      // 실패는 캐시되지 않는다 — 인덱스가 복구되면 다음 로드는 성공한다.
      entries[IlDuConstructionPlanRepository.indexAssetPath] = good;
      final plan = await repository.load();
      expect(plan.estateId, 'ildu-gotaek-v3');
    });

    test('fails closed when a referenced building file is missing', () async {
      final entries = _validBundleEntries()
        ..remove('${IlDuConstructionPlanRepository.assetDirectory}'
            'hyeopmun_v1.json');
      final repository = IlDuConstructionPlanRepository(
        bundle: _MapAssetBundle(entries),
      );
      await expectLater(repository.load(), throwsA(isA<Object>()));
    });
  });
}

// ---------------------------------------------------------------------------
// 픽스처 — 3단계 협문 하나와 모듈 3개짜리 최소 유효 플랜.

Map<String, Object?> _validIndexJson() => <String, Object?>{
  'schemaVersion': 1,
  'estateId': 'ildu-gotaek-v3',
  'planVersion': 'test-v1',
  'canvas': {'width': 2412, 'height': 2622},
  'viewport': {'width': 1206, 'height': 2622},
  'siteStageIds': ['hyeopmun-site'],
  'buildingOrder': ['hyeopmun'],
  'buildings': [
    {
      'buildingId': 'hyeopmun',
      'file': 'hyeopmun_v1.json',
      'planVersion': 'hyeopmun-v1',
    },
  ],
};

Map<String, Object?> _validBuildingDocs() => <String, Object?>{
  'hyeopmun': <String, Object?>{
    'schemaVersion': 1,
    'building': <String, Object?>{
      'buildingId': 'hyeopmun',
      'planVersion': 'hyeopmun-v1',
      'canonicalAsset': 'hyeopmun_master.png',
      'canonicalSha256':
          '0000000000000000000000000000000000000000000000000000000000000000',
      'buildingRole': '안마당과 바깥을 잇는 작은 문',
      'culturalMeaning': '드나듦을 조절하던 경계',
      'stages': [
        _stage(
          stageId: 'hyeopmun-site',
          sequence: 1,
          moduleId: 'hyeopmun-site-language',
          fallbackStageId: null,
        ),
        _stage(
          stageId: 'hyeopmun-frame',
          sequence: 2,
          moduleId: 'hyeopmun-frame-language',
          fallbackStageId: 'hyeopmun-site',
        ),
        _stage(
          stageId: 'hyeopmun-complete',
          sequence: 3,
          moduleId: 'hyeopmun-complete-language',
          fallbackStageId: 'hyeopmun-frame',
        ),
      ],
    },
    'modules': [
      _module('hyeopmun-site-language'),
      _module('hyeopmun-frame-language'),
      _module('hyeopmun-complete-language'),
    ],
  },
};

Map<String, Object?> _stage({
  required String stageId,
  required int sequence,
  required String moduleId,
  required String? fallbackStageId,
}) => <String, Object?>{
  'stageId': stageId,
  'sequence': sequence,
  'processTags': ['site'],
  'baseAsset': 'stage_0${sequence}_test.png',
  'overlayAssets': <String>[],
  'requiredModuleIds': [moduleId],
  'optionalModuleIds': <String>[],
  'completionEffect': 'install-part',
  'fallbackStageId': fallbackStageId,
};

Map<String, Object?> _module(String moduleId) => <String, Object?>{
  'moduleId': moduleId,
  'sourceRefs': [
    'https://www.heritage.go.kr/heri/cul/culSelectDetail.do?ccbaCpno=1483801860000&pageNo=1_1_1_1',
  ],
  'levelBand': ['a1', 'a2'],
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
      'id': 'test-criterion',
      'kind': 'meaningSlot',
      'acceptedVariants': ['시작하자'],
      'requiredForCompletion': true,
    },
  ],
  'scoredDimensions': [
    'communicativeFunction',
    'relationshipRegister',
    'targetLanguage',
  ],
  'completionEvidence': {'type': 'inApp'},
};

List<Object?> _stagesOf(Map<String, Object?> docs) =>
    ((docs['hyeopmun'] as Map)['building'] as Map)['stages'] as List;

List<Object?> _modulesOf(Map<String, Object?> docs) =>
    (docs['hyeopmun'] as Map)['modules'] as List;

Map<String, String> _validBundleEntries() => <String, String>{
  IlDuConstructionPlanRepository.indexAssetPath: jsonEncode(_validIndexJson()),
  '${IlDuConstructionPlanRepository.assetDirectory}hyeopmun_v1.json':
      jsonEncode(_validBuildingDocs()['hyeopmun']),
};

/// 메모리 맵으로 동작하는 테스트 번들. 실패 캐시 금지 검증을 위해 항목을
/// 도중에 바꿀 수 있다.
final class _MapAssetBundle extends CachingAssetBundle {
  _MapAssetBundle(this.entries);

  final Map<String, String> entries;

  @override
  Future<ByteData> load(String key) async {
    final value = entries[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    return ByteData.sublistView(
      Uint8List.fromList(utf8.encode(value)),
    );
  }

  // CachingAssetBundle 은 loadString 결과를 캐시한다. 이 테스트 번들은 항목
  // 교체를 허용해야 하므로 캐시를 우회한다.
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = entries[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    return value;
  }
}
