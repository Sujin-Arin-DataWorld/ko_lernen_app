import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/services/ildu_construction_plan_repository.dart';

/// 번들에 실린 사랑채 시드(`assets/data/ildu_construction/`)의 콘텐츠 가드.
///
/// 2026-08-29 승인 스펙의 12단계 순서·fallback 체인·3개국어·HTTPS 출처·
/// inApp completionEvidence(D3)·채점 금지 규정을 실 데이터에 고정한다.
void main() {
  late IlDuEstateConstructionPlan plan;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    plan = await IlDuConstructionPlanRepository().load();
  });

  test('the estate index declares the approved contract values', () {
    expect(plan.estateId, 'ildu-gotaek-v3');
    expect(plan.planVersion, 'sarangchae-v1');
    expect(plan.canvas.width, 2412);
    expect(plan.canvas.height, 2622);
    expect(plan.viewport.width, 1206);
    expect(plan.viewport.height, 2622);
    expect(plan.buildingOrder, ['sarangchae']);
    expect(plan.buildingFor('sarangchae').planVersion, 'sarangchae-v1');
  });

  test('the Sarangchae keeps the approved twelve-stage order', () {
    expect(
      plan.buildingFor('sarangchae').stages.map((stage) => stage.stageId),
      const [
        'sarangchae-site',
        'sarangchae-foundation',
        'sarangchae-posts-floor-frame',
        'sarangchae-beams-purlins',
        'sarangchae-rafters-sanja',
        'sarangchae-roof-bed',
        'sarangchae-roof-tiles',
        'sarangchae-floor-numaru',
        'sarangchae-wall-infill',
        'sarangchae-changho',
        'sarangchae-hyeonpan',
        'sarangchae-complete',
      ],
    );
  });

  test('stage IDs are unique and sequences are consecutive from one', () {
    final stages = plan.buildingFor('sarangchae').stages;
    final ids = stages.map((stage) => stage.stageId).toSet();
    expect(ids, hasLength(stages.length));
    for (final (index, stage) in stages.indexed) {
      expect(stage.sequence, index + 1);
    }
  });

  test('the fallback chain steps back one stage at a time to the bare site',
      () {
    final stages = plan.buildingFor('sarangchae').stages;
    expect(stages.first.fallbackStageId, isNull);
    for (var i = 1; i < stages.length; i++) {
      expect(
        stages[i].fallbackStageId,
        stages[i - 1].stageId,
        reason: '${stages[i].stageId} 는 바로 앞 단계로만 후퇴해야 한다',
      );
    }
  });

  test('every stage requires at least one resolvable module', () {
    for (final stage in plan.buildingFor('sarangchae').stages) {
      expect(stage.requiredModuleIds, isNotEmpty);
      for (final moduleId in [
        ...stage.requiredModuleIds,
        ...stage.optionalModuleIds,
      ]) {
        expect(plan.hasModule(moduleId), isTrue,
            reason: '$moduleId 는 플랜 안에서 해석돼야 한다');
      }
    }
  });

  test('the hyeonpan stage requires both signboard modules', () {
    final hyeonpan =
        plan.buildingFor('sarangchae').stageFor('sarangchae-hyeonpan');
    expect(
      hyeonpan.requiredModuleIds,
      containsAll(['baekse-cheongpung-2026', 'takcheongjae-2026']),
    );
  });

  test('every module carries independent ko, de and en copy', () {
    expect(plan.modules, hasLength(13));
    for (final module in plan.modules) {
      for (final language in kIlDuRequiredCopyLanguages) {
        final copy = module.copyByLanguage[language];
        expect(copy, isNotNull,
            reason: '${module.moduleId} 에 $language 본문이 없다');
        expect(copy!.title.trim(), isNotEmpty);
        expect(copy.sceneLine.trim(), isNotEmpty);
        expect(copy.actionPrompt.trim(), isNotEmpty);
      }
    }
  });

  test('every source reference is HTTPS', () {
    for (final module in plan.modules) {
      expect(module.sourceRefs, isNotEmpty);
      for (final ref in module.sourceRefs) {
        expect(ref.scheme, 'https',
            reason: '${module.moduleId} 의 출처 $ref 는 HTTPS 여야 한다');
      }
    }
  });

  test('every seed module completes in-app (D3)', () {
    for (final module in plan.modules) {
      expect(
        module.completionEvidence.type,
        IlDuCompletionEvidenceType.inApp,
        reason: '${module.moduleId} 의 시드 증거는 inApp 이어야 한다',
      );
      expect(module.completionEvidence.segmentId, isNull);
    }
  });

  test('no module grades a moral stance', () {
    for (final module in plan.modules) {
      expect(
        module.scoredDimensions,
        isNot(contains('stance')),
        reason: '${module.moduleId} 는 입장을 채점하면 안 된다',
      );
      for (final dimension in module.scoredDimensions) {
        expect(kIlDuAllowedScoredDimensions, contains(dimension));
      }
    }
    for (final id in const ['baekse-cheongpung-2026', 'takcheongjae-2026']) {
      expect(plan.moduleFor(id).scoredDimensions, isNot(contains('stance')));
    }
  });

  test('signboard modules keep their hanja and authored criteria kinds', () {
    expect(
      plan.moduleFor('baekse-cheongpung-2026').hanja,
      ['百', '世', '淸', '風'],
    );
    expect(plan.moduleFor('takcheongjae-2026').hanja, ['濯', '淸', '齋']);
    const supportedKinds = {
      IlDuLearningCriterionKind.meaningSlot,
      IlDuLearningCriterionKind.tokenSequence,
      IlDuLearningCriterionKind.sentenceEnding,
    };
    for (final module in plan.modules) {
      expect(module.criteria, isNotEmpty);
      for (final criterion in module.criteria) {
        expect(supportedKinds, contains(criterion.kind));
        expect(criterion.acceptedVariants, isNotEmpty);
      }
    }
  });
}
