import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/ildu_construction_plan_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sarangchae catalog keeps the approved twelve-stage order', () async {
    final plan = await const IlDuConstructionPlanRepository().load();

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
    expect(
      plan
          .buildingFor('sarangchae')
          .stages
          .expand((stage) => stage.requiredModuleIds)
          .toSet(),
      hasLength(13),
    );
  });

  test(
    'late construction stages keep base and overlay responsibilities',
    () async {
      final plan = await const IlDuConstructionPlanRepository().load();

      expect(plan.stageFor('sarangchae-changho').overlayAssets, [
        'stage_10_work_props.png',
      ]);
      expect(
        plan.stageFor('sarangchae-hyeonpan').baseAsset,
        'stage_10_changho.png',
      );
      expect(plan.stageFor('sarangchae-hyeonpan').overlayAssets, [
        'stage_11_hyeonpan_work.png',
      ]);
      expect(
        plan.stageFor('sarangchae-complete').baseAsset,
        'stage_12_complete_v3_base.png',
      );
      expect(plan.stageFor('sarangchae-complete').overlayAssets, [
        'stage_12_hyeonpan_installed.png',
      ]);
    },
  );

  test(
    'every module has independent KO DE EN copy and evidence sources',
    () async {
      final plan = await const IlDuConstructionPlanRepository().load();

      expect(plan.modules, hasLength(13));
      for (final module in plan.modules) {
        expect(module.sourceRefs, isNotEmpty, reason: module.moduleId);
        expect(
          module.sourceRefs.every((source) => source.scheme == 'https'),
          isTrue,
          reason: module.moduleId,
        );
        expect(module.copyByLanguage.keys, containsAll(['ko', 'de', 'en']));
        expect(module.speechBrief.relationship, isNotEmpty);
        expect(module.speechBrief.speechStyle, isNotEmpty);
        expect(module.acceptedVariants, isNotEmpty);
        expect(module.criteria, isNotEmpty);
      }
    },
  );

  test('signboard modules preserve exact sources and Hanja', () async {
    final plan = await const IlDuConstructionPlanRepository().load();
    const sources = {
      'https://www.heritage.go.kr/heri/cul/culSelectDetail.do?ccbaCpno=1483801860000&pageNo=1_1_1_1',
      'https://korean.visitkorea.or.kr/detail/ms_detail.do?cotid=1d38a05f-4ce1-4468-8ffa-05ef0a7ef25a',
      'https://multi.ugyo.net/relic/view.do?currPage=1&listSize=10&orderBy=ASC&pageSize=10&relicCode=1026&relicType=3',
      'https://kli.korean.go.kr/corpus/main/requestMain.do?lang=ko',
    };

    expect(plan.moduleFor('baekse-cheongpung-2026').hanja, [
      '百',
      '世',
      '淸',
      '風',
    ]);
    expect(plan.moduleFor('takcheongjae-2026').hanja, ['濯', '淸', '齋']);
    for (final id in const ['baekse-cheongpung-2026', 'takcheongjae-2026']) {
      expect(
        plan
            .moduleFor(id)
            .sourceRefs
            .map((source) => source.toString())
            .toSet(),
        sources,
      );
    }
  });

  test(
    'signboard modules grade communication but never moral stance',
    () async {
      final plan = await const IlDuConstructionPlanRepository().load();

      for (final id in const ['baekse-cheongpung-2026', 'takcheongjae-2026']) {
        final module = plan.moduleFor(id);
        expect(module.scoredDimensions, {
          'communicativeFunction',
          'relationshipRegister',
          'targetLanguage',
        });
        expect(module.scoredDimensions, isNot(contains('stance')));
        expect(
          module.copyFor('ko').sceneLine,
          isNot(anyOf(contains('백세청풍'), contains('탁청재'))),
        );
      }
    },
  );

  test(
    '2026 Korean actions use natural workplace and group-chat speech',
    () async {
      final plan = await const IlDuConstructionPlanRepository().load();

      final baekse = plan.moduleFor('baekse-cheongpung-2026');
      expect(
        baekse.copyFor('ko').sceneLine,
        '동료: 이 정도는 그냥 넘어가도 되지 않을까요? 괜히 일만 커질 것 같은데요.',
      );
      expect(
        baekse.acceptedVariants,
        contains('일을 키우자는 뜻은 아니고요. 더 늦기 전에 먼저 말씀드리는 게 좋을 것 같아요.'),
      );

      final tak = plan.moduleFor('takcheongjae-2026');
      expect(
        tak.copyFor('ko').sceneLine,
        '상대: 제 말이 그렇게 이해하기 어려웠나요? 답이 없으니까 더 답답하네요.',
      );
      expect(
        tak.acceptedVariants,
        contains('무시하려는 건 아니에요. 조금만 생각해 보고 정리해서 다시 말씀드릴게요.'),
      );
    },
  );
}
