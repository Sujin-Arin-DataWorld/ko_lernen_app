import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_construction_stage_layer.dart';

/// Phase 3 계약: ① 단계 에셋이 있으면 base+overlay Stack, 실패 시 fallback
/// 체인으로 **더 이른** 단계 유지 ② 에셋이 하나도 없으면(현재 릴리스 기본)
/// 신규 에셋 0장의 고스트 모드 ③ 완공 진행도는 필터 없는 완성 스프라이트.
void main() {
  late IlDuBuildingConstructionPlan sarangchae;

  setUpAll(() async {
    final index = jsonDecode(
      await File(
        'assets/data/ildu_construction/estate_plan_v1.json',
      ).readAsString(),
    );
    final building = jsonDecode(
      await File(
        'assets/data/ildu_construction/sarangchae_v1.json',
      ).readAsString(),
    );
    final plan = IlDuEstateConstructionPlan.fromJson(index, {
      'sarangchae': building,
    });
    sarangchae = plan.buildingFor('sarangchae');
  });

  Widget host(Widget layer) => MaterialApp(
    home: Center(child: SizedBox(width: 240, height: 192, child: layer)),
  );

  testWidgets('renders ghost mode when no stage asset is bundled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        IlDuConstructionStageLayer(
          buildingId: 'sarangchae',
          anchorId: 'sarangchae',
          building: sarangchae,
          currentStage: sarangchae.stages.first,
          completedStageCount: 0,
          completedFrame: kIlDuSarangchaeTurntable.frames[0],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-ghost-silhouette-sarangchae')),
      findsOneWidget,
    );
    final reveal = tester.widget<ClipRect>(
      find.byKey(const ValueKey('ildu-ghost-reveal-sarangchae')),
    );
    expect((reveal.clipper as IlDuGhostRevealClipper).fraction, 0);
    // 저채도 실루엣 계약: 불투명도 ~0.25.
    final silhouette = tester.widget<Opacity>(
      find.byKey(const ValueKey('ildu-ghost-silhouette-sarangchae')),
    );
    expect(silhouette.opacity, closeTo(.25, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ghost reveal follows the stage progress ratio bottom-up', (
    tester,
  ) async {
    // 12단계 중 6단계 완료 → 완성 스프라이트의 아래 절반이 드러난다.
    await tester.pumpWidget(
      host(
        IlDuConstructionStageLayer(
          buildingId: 'sarangchae',
          anchorId: 'sarangchae',
          building: sarangchae,
          currentStage: sarangchae.stages[6],
          completedStageCount: 6,
          completedFrame: kIlDuSarangchaeTurntable.frames[0],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reveal = tester.widget<ClipRect>(
      find.byKey(const ValueKey('ildu-ghost-reveal-sarangchae')),
    );
    final clipper = reveal.clipper as IlDuGhostRevealClipper;
    expect(clipper.fraction, closeTo(6 / 12, .001));
    // 하부→상부 클리핑: 드러나는 영역은 항상 바닥에 붙어 있다.
    final clip = clipper.getClip(const Size(100, 200));
    expect(clip.bottom, 200);
    expect(clip.top, closeTo(100, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falls back along the authored chain to the last available stage',
    (tester) async {
      // 3단계(기둥) 에셋은 없고 2단계(기단) 에셋만 번들에 있다 →
      // 일반 한옥 대체물 없이 더 이른 2단계를 유지해야 한다.
      final bundle = _StageAssetBundle({
        ilduConstructionStageAssetPath(
          'sarangchae',
          'stage_02_foundation.png',
        ): _kTransparentPng,
      });
      await tester.pumpWidget(
        host(
          IlDuConstructionStageLayer(
            buildingId: 'sarangchae',
            anchorId: 'sarangchae',
            building: sarangchae,
            currentStage: sarangchae.stageFor('sarangchae-posts-floor-frame'),
            completedStageCount: 2,
            completedFrame: kIlDuSarangchaeTurntable.frames[0],
            bundle: bundle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ildu-construction-stage-sarangchae-foundation'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
        findsNothing,
      );
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(
            const ValueKey('ildu-construction-stage-sarangchae-foundation'),
          ),
          matching: find.byType(Image),
        ),
      );
      final provider = image.image;
      expect(provider, isA<ResizeImage>());
      final inner = (provider as ResizeImage).imageProvider;
      expect(
        (inner as AssetImage).assetName,
        ilduConstructionStageAssetPath('sarangchae', 'stage_02_foundation.png'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders base plus overlays when the full stage set exists', (
    tester,
  ) async {
    // 11단계(현판 설치 중)는 base(stage_10_changho) + overlay(작업 현판).
    final hyeonpan = sarangchae.stageFor('sarangchae-hyeonpan');
    final bundle = _StageAssetBundle({
      ilduConstructionStageAssetPath('sarangchae', hyeonpan.baseAsset):
          _kTransparentPng,
      for (final overlay in hyeonpan.overlayAssets)
        ilduConstructionStageAssetPath('sarangchae', overlay): _kTransparentPng,
    });
    await tester.pumpWidget(
      host(
        IlDuConstructionStageLayer(
          buildingId: 'sarangchae',
          anchorId: 'sarangchae',
          building: sarangchae,
          currentStage: hyeonpan,
          completedStageCount: 10,
          completedFrame: kIlDuSarangchaeTurntable.frames[0],
          bundle: bundle,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stack = find.byKey(
      const ValueKey('ildu-construction-stage-sarangchae-hyeonpan'),
    );
    expect(stack, findsOneWidget);
    expect(
      find.descendant(of: stack, matching: find.byType(Image)),
      findsNWidgets(1 + hyeonpan.overlayAssets.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete progress renders the unfiltered finished sprite', (
    tester,
  ) async {
    // 해금 자체는 월드 화면이 턴테이블 복귀로 처리하지만, 레이어도 완공
    // 진행도를 받으면 고스트 필터 없이 완성 스프라이트를 그린다.
    await tester.pumpWidget(
      host(
        IlDuConstructionStageLayer(
          buildingId: 'sarangchae',
          anchorId: 'sarangchae',
          building: sarangchae,
          currentStage: sarangchae.stages.last,
          completedStageCount: sarangchae.stages.length,
          completedFrame: kIlDuSarangchaeTurntable.frames[0],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-construction-complete-frame-sarangchae')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ildu-ghost-silhouette-sarangchae')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('resident window keeps at most three stages (fallback·current·next)',
      () {
    final resident = ilduConstructionResidentStages(
      sarangchae,
      'sarangchae-roof-tiles',
    );
    expect(resident, hasLength(3));
    expect(resident[0].stageId, 'sarangchae-roof-bed');
    expect(resident[1].stageId, 'sarangchae-roof-tiles');
    expect(resident[2].stageId, 'sarangchae-floor-numaru');

    final first = ilduConstructionResidentStages(sarangchae, 'sarangchae-site');
    expect(first.map((stage) => stage.stageId), [
      'sarangchae-site',
      'sarangchae-foundation',
    ]);
  });

  test('eviction targets cover every non-resident stage asset exactly once',
      () {
    final targets = ilduConstructionEvictionTargets(
      building: sarangchae,
      currentStageId: 'sarangchae-roof-tiles',
    );
    expect(
      targets,
      isNot(
        contains(
          ilduConstructionStageAssetPath('sarangchae', 'stage_07_roof_tiles.png'),
        ),
      ),
    );
    expect(
      targets,
      contains(
        ilduConstructionStageAssetPath('sarangchae', 'stage_01_site.png'),
      ),
    );
    expect(targets.toSet(), hasLength(targets.length));
  });
}

/// 프로브(load)와 렌더(Image.asset)가 같은 경계를 지나도록 단계 에셋만
/// 주입하고 나머지는 rootBundle 로 위임하는 테스트 번들.
class _StageAssetBundle extends CachingAssetBundle {
  _StageAssetBundle(this._extraAssets);

  final Map<String, Uint8List> _extraAssets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = _extraAssets[key];
    if (bytes != null) {
      return ByteData.view(bytes.buffer);
    }
    return rootBundle.load(key);
  }
}

/// 유효한 1x1 투명 PNG — 디코드 실패로 errorBuilder 가 오작동하지 않게 한다.
final Uint8List _kTransparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, //
  0x0b, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x60, 0x00, 0x02, 0x00, //
  0x00, 0x05, 0x00, 0x01, 0x7a, 0x5e, 0xab, 0x3f, 0x00, 0x00, 0x00, 0x00, //
  0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);
