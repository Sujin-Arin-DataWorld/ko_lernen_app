import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/services/ildu_construction_plan_repository.dart';

void main() {
  test(
    'accepts a twelve-stage Sarangchae without an eight-stage invariant',
    () {
      final plan = IlDuEstateConstructionPlan.fromJson(_validPlanJson());

      expect(plan.canvas, const Size(2412, 2622));
      expect(plan.viewport, const Size(1206, 2622));
      expect(plan.buildingFor('sarangchae').stages, hasLength(12));
      expect(plan.stageFor('sarangchae-site').sequence, 1);
      expect(plan.moduleFor('module-a').moduleId, 'module-a');
    },
  );

  test('rejects duplicate stage IDs', () {
    final json = _validPlanJson();
    final stages =
        ((json['buildings'] as List).single as Map<String, Object?>)['stages']!
            as List<Object?>;
    (stages.last! as Map<String, Object?>)['stageId'] =
        (stages.first! as Map<String, Object?>)['stageId'];

    expect(
      () => IlDuEstateConstructionPlan.fromJson(json),
      throwsFormatException,
    );
  });

  test('rejects unknown required module references', () {
    final json = _validPlanJson();
    final stages =
        ((json['buildings'] as List).single as Map<String, Object?>)['stages']!
            as List<Object?>;
    (stages.first! as Map<String, Object?>)['requiredModuleIds'] = [
      'missing-module',
    ];

    expect(
      () => IlDuEstateConstructionPlan.fromJson(json),
      throwsFormatException,
    );
  });

  test('rejects a fallback that does not point to an earlier stage', () {
    final json = _validPlanJson();
    final stages =
        ((json['buildings'] as List).single as Map<String, Object?>)['stages']!
            as List<Object?>;
    (stages[1]! as Map<String, Object?>)['fallbackStageId'] =
        'sarangchae-stage-12';

    expect(
      () => IlDuEstateConstructionPlan.fromJson(json),
      throwsFormatException,
    );
  });

  test('rejects non-HTTPS learning sources', () {
    final json = _validPlanJson();
    final modules = json['modules']! as List<Object?>;
    (modules.single! as Map<String, Object?>)['sourceRefs'] = [
      'http://example.com/source',
    ];

    expect(
      () => IlDuEstateConstructionPlan.fromJson(json),
      throwsFormatException,
    );
  });

  test('repository loads and validates the injected bundled asset', () async {
    final bundle = _MemoryAssetBundle(jsonEncode(_validPlanJson()));

    final plan = await IlDuConstructionPlanRepository(bundle: bundle).load();

    expect(bundle.requestedKeys, [IlDuConstructionPlanRepository.assetPath]);
    expect(plan.buildingOrder, ['sarangchae']);
  });
}

Map<String, Object?> _validPlanJson() {
  final stages = <Object?>[];
  for (var sequence = 1; sequence <= 12; sequence++) {
    stages.add({
      'stageId': sequence == 1
          ? 'sarangchae-site'
          : 'sarangchae-stage-$sequence',
      'sequence': sequence,
      'processTags': [sequence == 1 ? 'site' : 'framePosts'],
      'baseAsset': 'stage_${sequence.toString().padLeft(2, '0')}.png',
      'overlayAssets': <String>[],
      'requiredModuleIds': ['module-a'],
      'optionalModuleIds': <String>[],
      'completionEffect': 'install',
      'fallbackStageId': sequence == 1
          ? null
          : sequence == 2
          ? 'sarangchae-site'
          : 'sarangchae-stage-${sequence - 1}',
    });
  }

  return {
    'schemaVersion': 1,
    'estateId': 'ildu-gotaek-v3',
    'planVersion': 'sarangchae-v1',
    'canvas': {'width': 2412, 'height': 2622},
    'viewport': {'width': 1206, 'height': 2622},
    'siteStageIds': ['sarangchae-site'],
    'buildingOrder': ['sarangchae'],
    'buildings': [
      {
        'buildingId': 'sarangchae',
        'planVersion': 'sarangchae-v1',
        'canonicalAsset': 'sarangchae_try07_edit.png',
        'canonicalSha256':
            'f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212',
        'buildingRole': '주인과 손님이 만나는 사랑채',
        'culturalMeaning': '관계와 수양을 드러내는 공간',
        'stages': stages,
      },
    ],
    'modules': [
      {
        'moduleId': 'module-a',
        'sourceRefs': ['https://example.com/source'],
        'levelBand': ['b1'],
        'knowledgeLenses': ['construction'],
        'copy': {
          'ko': _copy('사랑채 공정'),
          'de': _copy('Bau des Sarangchae'),
          'en': _copy('Building the Sarangchae'),
        },
        'speechBrief': {
          'scene': '직장 대화',
          'channel': '대면',
          'purpose': '정중히 제안하기',
          'speaker': '학습자',
          'addressee': '동료',
          'relationship': '직장 동료',
          'speechStyle': '해요체',
          'speechAct': '제안',
          'knownFacts': ['보고서에 실수가 있다'],
          'unresolvedFacts': ['누가 수정할지 정해지지 않았다'],
          'forbiddenInvention': ['직급을 만들지 않는다'],
        },
        'targetExpressions': ['공유하는 게 낫지 않을까요'],
        'acceptedVariants': ['지금 공유하는 게 낫지 않을까요?'],
        'criteria': [
          {
            'id': 'suggest-sharing',
            'kind': 'meaningSlot',
            'acceptedVariants': ['공유하는 게 낫지 않을까요'],
            'requiredForCompletion': true,
          },
        ],
        'scoredDimensions': [
          'communicativeFunction',
          'relationshipRegister',
          'targetLanguage',
        ],
      },
    ],
  };
}

Map<String, Object?> _copy(String title) => {
  'title': title,
  'history': '역사 맥락',
  'criticalLens': '비판적 관점',
  'modernScene': '2026년 장면',
  'sceneLine': '상대의 말',
  'actionPrompt': '한국어로 답해 보세요.',
};

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.encoded);

  final String encoded;
  final List<String> requestedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    final bytes = Uint8List.fromList(utf8.encode(encoded));
    return ByteData.sublistView(bytes);
  }
}
