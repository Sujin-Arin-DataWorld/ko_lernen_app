import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/ildu_learning_module_screen.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/ildu_anchor_placement_service.dart';
import 'package:ko_lernen_app/services/ildu_construction_progress_service.dart';
import 'package:ko_lernen_app/services/ildu_decoration_placement_service.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_construction_stage_layer.dart';

/// 신규 학습자의 사랑채 건설 여정: site 고스트 → 모듈 완료 → 진행 전진 →
/// 12단계 complete → 8각도 턴테이블 해금 → 재로드 생존.
void main() {
  late IlDuWorldManifest manifest;
  late IlDuEstateConstructionPlan plan;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
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
    plan = IlDuEstateConstructionPlan.fromJson(index, {
      'sarangchae': building,
    });
  });

  Future<void> pumpWorld(
    WidgetTester tester,
    _MemoryProgressStore progressStore, {
    Key? key,
  }) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: IlDuWorldScreen(
          key: key,
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedA1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
          loadConstructionPlan: () async => plan,
          constructionProgressStore: progressStore,
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/hanok/module') {
            final args = settings.arguments as IlDuLearningModuleArgs;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => IlDuLearningModuleScreen(
                args: args,
                loadPlan: () async => plan,
                progressStore: progressStore,
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a new learner starts at the site ghost and advances through the module',
    (tester) async {
      final store = _MemoryProgressStore();
      await pumpWorld(tester, store);

      // 신규 학습자: 에셋 없는 첫 단계는 고스트 모드, 드러난 부분 0.
      expect(
        find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
        findsOneWidget,
      );
      final revealBefore = tester.widget<ClipRect>(
        find.byKey(const ValueKey('ildu-ghost-reveal-sarangchae')),
      );
      expect(
        (revealBefore.clipper as IlDuGhostRevealClipper).fraction,
        0,
      );

      // 시트: 현재 공정(Baugrund)과 다음 공정 CTA.
      expect(
        find.byKey(const ValueKey('ildu-construction-process-tag')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('ildu-construction-process-tag')),
            )
            .data,
        contains('Baugrund'),
      );

      // CTA → 모듈 화면 → 저작 답안 → 완료 → 월드 복귀.
      await tester.tap(
        find.byKey(const ValueKey('ildu-construction-next-cta')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ildu-module-input')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('ildu-module-input')),
        '일단 정리부터 시작하자.',
      );
      await tester.tap(find.byKey(const ValueKey('ildu-module-submit')));
      await tester.pumpAndSettle();

      // 진행도 재로드: 시트가 다음 공정(Fundament)으로 전진하고 고스트가
      // 1/12 만큼 드러난다.
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('ildu-construction-process-tag')),
            )
            .data,
        contains('Fundament'),
      );
      final revealAfter = tester.widget<ClipRect>(
        find.byKey(const ValueKey('ildu-ghost-reveal-sarangchae')),
      );
      expect(
        (revealAfter.clipper as IlDuGhostRevealClipper).fraction,
        closeTo(1 / 12, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'finishing all twelve stages restores the eight-view turntable and '
    'survives a reload',
    (tester) async {
      final store = _MemoryProgressStore();
      final service = IlDuConstructionProgressService(
        plan: plan,
        store: store,
      );
      await service.initialize();
      final building = plan.buildingFor('sarangchae');
      for (final stage in building.stages) {
        for (final moduleId in stage.requiredModuleIds) {
          await service.completeModule(
            anchorId: 'sarangchae',
            buildingId: 'sarangchae',
            moduleId: moduleId,
          );
        }
      }
      expect(
        service.snapshot.anchorFor('sarangchae')!.completedStageIds,
        contains('sarangchae-complete'),
      );

      await pumpWorld(tester, store);

      // 완공 해금: 건설 레이어·고스트 없이 기존 턴테이블 렌더로 복귀.
      expect(
        find.byKey(const ValueKey('ildu-construction-layer-sarangchae')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ildu-map-turntable-sarangchae-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-next-cta')),
        findsNothing,
      );
      // 시트도 기존 추천 미션 블록으로 복귀한다.
      expect(
        find.byKey(const ValueKey('ildu-turntable-sarangchae')),
        findsOneWidget,
      );

      // 재로드 생존: 같은 저장소로 새 서비스를 만들어도 완료가 유지된다.
      final reloaded = IlDuConstructionProgressService(
        plan: plan,
        store: store,
      );
      await reloaded.initialize();
      final record = reloaded.snapshot.anchorFor('sarangchae')!;
      expect(record.completedStageIds, hasLength(building.stages.length));
      expect(
        reloaded
            .currentStage(anchorId: 'sarangchae', buildingId: 'sarangchae')
            .stageId,
        'sarangchae-complete',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

PersonalHanokProjection _verifiedA1Projection() {
  const text = CurriculumText(ko: '사랑채', de: 'Sarangchae', en: 'Sarangchae');
  final competence = HanokCompetenceProjection.fromSnapshot(
    snapshot: const CourseMasterySnapshot(completedUnitIds: <String>['a1-1']),
    courseUnits: const <CourseUnit>[
      CourseUnit(id: 'a1-1', level: 'a1', order: 1, title: text, canDo: text),
    ],
  );
  return PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    competence: competence,
  );
}

final class _MemoryProgressStore implements IlDuConstructionProgressStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encoded) async {
    value = encoded;
  }
}

class _MemoryDecorationStore implements IlDuDecorationPlacementStore {
  List<IlDuDecorationPlacement> placements = const [];

  @override
  Future<List<IlDuDecorationPlacement>> load(
    IlDuWorldManifest manifest,
  ) async => placements;

  @override
  Future<void> save(List<IlDuDecorationPlacement> placements) async {
    this.placements = List.unmodifiable(placements);
  }
}

class _MemoryAnchorStore implements IlDuAnchorPlacementStore {
  List<IlDuAnchorPlacement> placements = const [];

  @override
  Future<List<IlDuAnchorPlacement>> load(IlDuWorldManifest manifest) async =>
      placements;

  @override
  Future<void> save(List<IlDuAnchorPlacement> placements) async {
    this.placements = List.unmodifiable(placements);
  }
}
