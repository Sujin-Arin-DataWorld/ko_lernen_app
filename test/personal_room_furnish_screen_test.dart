import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/models/room_layout.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/room_layout_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/cultural_help.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:ko_lernen_app/widgets/sori/free_room_layer.dart';
import 'package:ko_lernen_app/widgets/sori/personal_room_scene.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/room_layer.dart';
import 'package:ko_lernen_app/widgets/sori/sticker_image.dart';

void main() {
  late CulturalGlossary culturalCatalog;

  setUpAll(() async {
    culturalCatalog = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  setUp(() async {
    RoomLayoutService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('locked anbang never exposes a placement write surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.anbang,
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .24),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RoomLayer), findsNothing);
    expect(find.text('This room is still being built'), findsOneWidget);
  });

  testWidgets('keeps the unlocked room interactive through the shared scene', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PersonalRoomScene), findsOneWidget);
    expect(find.byType(FreeRoomLayer), findsOneWidget);
    expect(find.byType(RoomLayer), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets(
    'a short vertical drag moves the item instead of scrolling the editor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const initial = RoomLayoutItem(
        instanceId: 'sticker:16:1',
        kind: RoomAssetKind.sticker,
        assetId: '16',
        x: .5,
        y: .5,
        width: .18,
      );
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_room_layouts_v3': jsonEncode({
          'version': 3,
          'surfaces': {
            'sarangbang': [initial.toJson(z: 0)],
          },
        }),
      });
      await Storage.init();
      RoomLayoutItem? submitted;
      await tester.pumpWidget(
        _host(
          PersonalRoomFurnishScreen(
            surface: PersonalRoomSurface.sarangbang,
            loadRatios: () async =>
                const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
            loadProjection: _legacyProjection,
            updateLayoutItem: (surface, item) {
              submitted = item;
              return SynchronousFuture(
                RoomLayoutMutation(
                  layouts: {
                    surface: [item],
                  },
                  result: RoomLayoutWriteResult.updated,
                  selectedId: item.instanceId,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final scrollOffset = scrollable.position.pixels;

      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
      expect(
        tester.widget<FreeRoomLayer>(find.byType(FreeRoomLayer)).selectedId,
        initial.instanceId,
      );
      expect(
        tester.widget<FreeRoomLayer>(find.byType(FreeRoomLayer)).items.single.y,
        greaterThan(initial.y),
      );
      await gesture.up();
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted!.x, closeTo(initial.x, .01));
      expect(submitted!.y, greaterThan(initial.y));
      expect(scrollable.position.pixels, closeTo(scrollOffset, .01));
    },
  );

  testWidgets(
    'two pointers scale and rotate inside the editor without scrolling it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const initial = RoomLayoutItem(
        instanceId: 'sticker:16:1',
        kind: RoomAssetKind.sticker,
        assetId: '16',
        x: .5,
        y: .5,
        width: .18,
      );
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_room_layouts_v3': jsonEncode({
          'version': 3,
          'surfaces': {
            'sarangbang': [initial.toJson(z: 0)],
          },
        }),
      });
      await Storage.init();
      final submitted = <RoomLayoutItem>[];
      await tester.pumpWidget(
        _host(
          PersonalRoomFurnishScreen(
            surface: PersonalRoomSurface.sarangbang,
            loadRatios: () async =>
                const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
            loadProjection: _legacyProjection,
            updateLayoutItem: (surface, item) {
              submitted.add(item);
              return SynchronousFuture(
                RoomLayoutMutation(
                  layouts: {
                    surface: [item],
                  },
                  result: RoomLayoutWriteResult.updated,
                  selectedId: item.instanceId,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final scrollOffset = scrollable.position.pixels;
      final center = tester.getCenter(target);
      final first = await tester.createGesture(pointer: 1);
      final second = await tester.createGesture(pointer: 2);

      await first.down(center - const Offset(12, 0));
      await second.down(center + const Offset(12, 0));
      await tester.pump();
      await first.moveTo(center - const Offset(0, 30));
      await second.moveTo(center + const Offset(0, 30));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pump();

      expect(submitted, hasLength(1));
      expect(submitted.single.width, greaterThan(initial.width));
      expect(submitted.single.rotation.abs(), greaterThan(.25));
      expect(scrollable.position.pixels, closeTo(scrollOffset, .01));
    },
  );

  testWidgets('unlocks a room from verified course structure alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
          loadProjection: (_) async => _courseSarangbangProjection(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PersonalRoomScene), findsOneWidget);
    expect(find.byType(FreeRoomLayer), findsOneWidget);
    expect(find.byType(RoomLayer), findsNothing);
  });

  testWidgets('a future layout version keeps its migrated fallback read only', (
    tester,
  ) async {
    final futureDocument = jsonEncode({'version': 4, 'surfaces': {}});
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_owned_decor': <String>['decoration_soban'],
      'kl_room_placements_v2': jsonEncode({
        'sarangbang': {'floor_center': 'decoration_soban'},
      }),
      'kl_room_layouts_v3': futureDocument,
    });
    await Storage.init();
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final layerFinder = find.byType(FreeRoomLayer);
    final initialLayer = tester.widget<FreeRoomLayer>(layerFinder);
    expect(initialLayer.interactive, isFalse);
    expect(initialLayer.items, hasLength(1));
    expect(initialLayer.onTransform, isNull);
    expect(initialLayer.onTransformEnd, isNull);
    expect(Storage.roomLayoutsV3Raw, futureDocument);
  });

  testWidgets('makes every sticker reachable and submits a room copy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    RoomLayoutItem? added;
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
          addLayoutItem: (surface, kind, assetId) {
            final item = RoomLayoutItem(
              instanceId: 'sticker:$assetId:1',
              kind: kind,
              assetId: assetId,
              x: .5,
              y: .5,
              width: .18,
            );
            added = item;
            return SynchronousFuture(
              RoomLayoutMutation(
                layouts: {
                  surface: [item],
                },
                result: RoomLayoutWriteResult.added,
                selectedId: item.instanceId,
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('room-inventory-tab-sticker')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('room-inventory-tab-sticker')));
    await tester.pumpAndSettle();

    expect(find.byType(StickerImage), findsNWidgets(30));
    final sticker = find.byKey(
      const ValueKey('room-inventory-item-sticker-16'),
    );
    await tester.ensureVisible(sticker);
    await tester.pumpAndSettle();
    expect(sticker.hitTestable(), findsOneWidget);
    final node = tester.getSemantics(sticker);
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => candidate.id == node.id),
    );
    await tester.pumpAndSettle();

    expect(added?.instanceId, 'sticker:16:1');
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 1800),
      1800,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('room-item-sticker:16:1')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('shows all owned furnishings and all earned stamps', (
    tester,
  ) async {
    CulturalGlossaryRepository.setLoaderForTesting(() async => culturalCatalog);
    addTearDown(CulturalGlossaryRepository.resetForTesting);
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_owned_decor': kDecorationRewardPool,
      'kl_stamps_earned': [
        for (final motif in DancheongMotif.values) motif.name,
      ],
    });
    await Storage.init();
    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('room-inventory-tab-decoration')),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    // 11 = kDecorationRewardPool(퀘스트 보상으로 획득) + 12 = A2 사랑방
    // 가구(furnishedDecorSlugs 의 방별 무상 풀 — Storage.ownedDecor 와 무관하게
    // 이 방(sarangbang)이 openedVenues 에 있으면 항상 보인다.
    // `kRoomFurnishingPool` 문서 참고).
    expect(find.byType(SoriDecorationImage), findsNWidgets(23));
    expect(
      find.byType(CulturalDecorationHelpButton),
      findsNWidgets(6),
      reason: '사군자 4폭은 같은 화면에서 문화어 도움말 하나만 보여야 한다',
    );
    await tester.tap(find.byKey(const ValueKey('room-inventory-tab-stamp')));
    await tester.pumpAndSettle();
    // 씨앗이 `DancheongMotif.values` 전수라 기대값도 enum 에서 끌어온다 —
    // 문양을 늘릴 때마다 상수를 고치러 오지 않도록.
    expect(
      find.byType(DancheongStamp),
      findsNWidgets(DancheongMotif.values.length),
    );
  });

  testWidgets(
    'an unlocked room outside kRoomFurnishingPool never gains another '
    'room\'s furniture (PR-D room-scoping fix)',
    (tester) async {
      CulturalGlossaryRepository.setLoaderForTesting(
        () async => culturalCatalog,
      );
      addTearDown(CulturalGlossaryRepository.resetForTesting);
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_owned_decor': kDecorationRewardPool,
      });
      await Storage.init();
      await tester.pumpWidget(
        _host(
          PersonalRoomFurnishScreen(
            surface: PersonalRoomSurface.anbang,
            loadRatios: () async =>
                const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .25),
            loadProjection: _legacyProjection,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('room-inventory-tab-decoration')),
        400,
        scrollable: find.byType(Scrollable).first,
      );

      // Only the 11 kDecorationRewardPool items -- none of A2 sarangbang's
      // 12 kRoomFurnishingPool items, since anbang has no pool entry yet.
      expect(find.byType(SoriDecorationImage), findsNWidgets(11));
    },
  );

  testWidgets('an older save callback cannot overwrite a newer drag draft', (
    tester,
  ) async {
    const initial = RoomLayoutItem(
      instanceId: 'sticker:16:1',
      kind: RoomAssetKind.sticker,
      assetId: '16',
      x: .5,
      y: .16,
      width: .18,
    );
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_room_layouts_v3': jsonEncode({
        'version': 3,
        'surfaces': {
          'sarangbang': [initial.toJson(z: 0)],
        },
      }),
    });
    await Storage.init();
    final pending = <Completer<RoomLayoutMutation>>[];
    final submitted = <RoomLayoutItem>[];

    await tester.pumpWidget(
      _host(
        PersonalRoomFurnishScreen(
          surface: PersonalRoomSurface.sarangbang,
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
          loadProjection: _legacyProjection,
          updateLayoutItem: (_, item) {
            submitted.add(item);
            final completer = Completer<RoomLayoutMutation>();
            pending.add(completer);
            return completer.future;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    var scene = tester.widget<PersonalRoomScene>(
      find.byType(PersonalRoomScene),
    );
    final firstDraft = initial.copyWith(x: .6);
    scene.onTransformItem!(firstDraft);
    scene.onTransformEnd!(firstDraft);
    await tester.pump();

    scene = tester.widget<PersonalRoomScene>(find.byType(PersonalRoomScene));
    final secondDraft = firstDraft.copyWith(x: .7);
    scene.onTransformItem!(secondDraft);
    scene.onTransformEnd!(secondDraft);
    await tester.pump();

    expect(pending, hasLength(2));
    expect(submitted[1].x, greaterThan(submitted[0].x));

    final saveFailed = AppL10n.of(
      tester.element(find.byType(PersonalRoomFurnishScreen)),
    ).personalRoomSaveFailed;
    pending[0].completeError(StateError('stale save failed'));
    await tester.pump();
    expect(find.text(saveFailed), findsNothing);
    expect(
      tester.widget<FreeRoomLayer>(find.byType(FreeRoomLayer)).items.single.x,
      submitted[1].x,
    );

    pending[1].complete(
      RoomLayoutMutation(
        layouts: {
          PersonalRoomSurface.sarangbang: [submitted[1]],
        },
        result: RoomLayoutWriteResult.updated,
        selectedId: submitted[1].instanceId,
      ),
    );
    await tester.pump();
    expect(
      tester.widget<FreeRoomLayer>(find.byType(FreeRoomLayer)).items.single.x,
      submitted[1].x,
    );
  });

  testWidgets(
    'narrow 200 percent text keeps the complete sticker chest usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_room_layouts_v3': jsonEncode({
          'version': 3,
          'surfaces': {
            'sarangbang': [
              {
                'instanceId': 'sticker:16:1',
                'kind': 'sticker',
                'assetId': '16',
                'x': .5,
                'y': .5,
                'width': .18,
                'rotation': 0,
                'z': 0,
              },
            ],
          },
        }),
      });
      await Storage.init();
      await tester.pumpWidget(
        _host(
          PersonalRoomFurnishScreen(
            surface: PersonalRoomSurface.sarangbang,
            loadRatios: () async =>
                const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0),
            loadProjection: _legacyProjection,
          ),
          textScaler: TextScaler.linear(2),
          size: const Size(320, 640),
          safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump();

      final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(SoriAppBar),
          matching: find.text(appBar.title),
        ),
      );
      expect(appBar.title, 'Study room');
      expect(title.maxLines, isNotNull);
      expect(title.overflow, TextOverflow.clip);

      final stickerTab = find.byKey(
        const ValueKey('room-inventory-tab-sticker'),
      );
      await tester.scrollUntilVisible(
        stickerTab,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(stickerTab);
      await tester.pumpAndSettle();
      expect(stickerTab.hitTestable(), findsOneWidget);
      await tester.tap(stickerTab.hitTestable());
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, -3000),
        1800,
      );
      await tester.pumpAndSettle();

      expect(find.byType(StickerImage), findsNWidgets(30));
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  Size size = Size.zero,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: safeInsets,
      viewPadding: safeInsets,
      disableAnimations: true,
      textScaler: textScaler,
    ),
    child: child,
  ),
);

const _text = CurriculumText(ko: '?λ㈃', de: 'Szene', en: 'Scene');

PersonalHanokProjection _courseSarangbangProjection() =>
    PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      competence: HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_01', 'a2_01', 'b1_01'],
        ),
        courseUnits: const [
          CourseUnit(
            id: 'a1_01',
            level: 'a1',
            order: 1,
            title: _text,
            canDo: _text,
          ),
          CourseUnit(
            id: 'a2_01',
            level: 'a2',
            order: 1,
            title: _text,
            canDo: _text,
          ),
          CourseUnit(
            id: 'b1_01',
            level: 'b1',
            order: 1,
            title: _text,
            canDo: _text,
          ),
        ],
      ),
    );

Future<PersonalHanokProjection> _legacyProjection(LevelRatios ratios) async =>
    PersonalHanokProjection.from(ratios);
