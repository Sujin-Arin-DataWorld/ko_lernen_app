import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/ildu_anchor_placement_service.dart';
import 'package:ko_lernen_app/services/ildu_decoration_placement_service.dart';

void main() {
  late IlDuWorldManifest manifest;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
  });

  testWidgets('renders the spacious map fail-closed at iPhone width', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          ),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mein Ildu Gotaek'), findsOneWidget);
    expect(find.text('0 von 11 Gebäuden'), findsOneWidget);
    expect(find.text('Bauplatz'), findsOneWidget);
    expect(
      find.text('Schließe bestätigte Lernschritte auf A1 ab.'),
      findsOneWidget,
    );
    final mapViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(mapViewer.panEnabled, isTrue);
    expect(mapViewer.scaleEnabled, isTrue);
    expect(mapViewer.minScale, 1);
    expect(mapViewer.maxScale, 2.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning the selected Sarangchae updates its map frame', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedA1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-turntable-sarangchae')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-sarangchae-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-map-turntable-sarangchae-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('map pans and pinches only within the 1x to 2.2x range', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedA1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewerFinder = find.byType(InteractiveViewer);
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final controller = viewer.transformationController!;
    final viewerRect = tester.getRect(viewerFinder);
    final backgroundPoint = viewerRect.topLeft + const Offset(20, 28);
    final beforePan = controller.value.getTranslation();

    final pan = await tester.startGesture(backgroundPoint);
    await pan.moveBy(const Offset(72, 36));
    await pan.up();
    await tester.pumpAndSettle();

    final afterPan = controller.value.getTranslation();
    expect(afterPan.x, isNot(closeTo(beforePan.x, .001)));
    expect(afterPan.y, isNot(closeTo(beforePan.y, .001)));

    final zoomCenter = viewerRect.topLeft + const Offset(72, 72);
    final firstFinger = await tester.startGesture(
      zoomCenter - const Offset(16, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      zoomCenter + const Offset(16, 0),
      pointer: 2,
    );
    await tester.pump();
    await firstFinger.moveTo(zoomCenter - const Offset(80, 0));
    await secondFinger.moveTo(zoomCenter + const Offset(80, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();

    final zoom = controller.value.getMaxScaleOnAxis();
    expect(zoom, greaterThan(1));
    expect(zoom, lessThanOrEqualTo(2.2 + 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting and turning Jungmunganchae updates its map frame', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedA1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mapAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-jungmunganchae-2'),
    );
    final tapTarget = find.descendant(
      of: mapAnchor,
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(tapTarget).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('중문채'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ildu-turntable-jungmunganchae')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-map-turntable-jungmunganchae-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting and turning Sotdaeulmun updates its map frame', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gateAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-main-gate-0'),
    );
    final gateTapTarget = find.descendant(
      of: gateAnchor,
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(gateTapTarget).onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-turntable-main-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-main-gate-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-map-turntable-main-gate-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('B2 shrine anchors use their authored turntable frames', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB2Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-map-turntable-sadang-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-sadang-gate-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-hyeopmun-west-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-hyeopmun-east-0')),
      findsOneWidget,
    );

    final sadangAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-sadang-2'),
    );
    final sadangTapTarget = find.descendant(
      of: sadangAnchor,
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(sadangTapTarget).onTap!();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ildu-turntable-sadang')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-map-turntable-sadang-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting and turning Changgo updates its map frame', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final changoAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-changgo-2'),
    );
    final changoTapTarget = find.descendant(
      of: changoAnchor,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ),
    );
    tester.widget<GestureDetector>(changoTapTarget).onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-turntable-changgo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-changgo-2')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-changgo-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting Araechae exposes rotation and zoom in the map sheet', (
    tester,
  ) async {
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
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: _MemoryAnchorStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final araechaeAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-araechae-0'),
    );
    expect(araechaeAnchor, findsOneWidget);
    final tapTarget = find.descendant(
      of: araechaeAnchor,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ),
    );
    tester.widget<GestureDetector>(tapTarget).onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ildu-turntable-araechae')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hanok-turntable-zoom-in')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-araechae-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hanok-turntable-zoom-in')));
    await tester.pump();
    final zoomLayer = tester.widget<Transform>(
      find.byKey(const ValueKey('hanok-turntable-zoom-layer')),
    );
    expect(zoomLayer.transform.storage[0], 1.25);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging Sarangchae saves its map placement', (tester) async {
    // Keep the map anchor clear of the persistent detail sheet so this test
    // exercises the real nested gesture arena instead of invoking callbacks.
    tester.view.physicalSize = const Size(1179, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final anchorStore = _MemoryAnchorStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: IlDuWorldScreen(
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedA1Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: anchorStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final anchor = find.byKey(
      const ValueKey('ildu-map-turntable-sarangchae-0'),
    );
    final dragTarget = find.descendant(
      of: anchor,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onPanUpdate != null,
      ),
    );
    final mapController = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final mapTransformBeforeDrag = mapController.value.clone();
    await tester.drag(dragTarget, const Offset(48, 24));
    await tester.pumpAndSettle();

    expect(anchorStore.placements, hasLength(1));
    expect(anchorStore.placements.single.anchorId, 'sarangchae');
    expect(anchorStore.placements.single.x, greaterThan(48.2));
    expect(anchorStore.placements.single.y, greaterThan(55.8));
    expect(mapController.value, mapTransformBeforeDrag);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dedicated controls resize and restore all shrine asset types', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final anchorStore = _MemoryAnchorStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: IlDuWorldScreen(
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB2Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: anchorStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> resizeAnchor({
      required String anchorId,
      required int direction,
      required double scale,
    }) async {
      final anchor = find.byKey(
        ValueKey('ildu-map-turntable-$anchorId-$direction'),
      );
      final dragTarget = find.descendant(
        of: anchor,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onPanUpdate != null,
        ),
      );
      final gesture = tester.widget<GestureDetector>(dragTarget);
      expect(gesture.onScaleUpdate, isNull);
      gesture.onTap!();
      await tester.pumpAndSettle();

      final sliderFinder = find.byKey(ValueKey('ildu-scale-slider-$anchorId'));
      final slider = tester.widget<Slider>(sliderFinder);
      slider.onChanged!(scale);
      slider.onChangeEnd!(scale);
      await tester.pumpAndSettle();

      final saved = anchorStore.placements.singleWhere(
        (placement) => placement.anchorId == anchorId,
      );
      expect(saved.direction, direction);
      expect(saved.scale, closeTo(scale, .001));
      expect(tester.widget<Slider>(sliderFinder).value, closeTo(scale, .001));
    }

    await resizeAnchor(anchorId: 'sadang', direction: 2, scale: 1.35);
    await resizeAnchor(anchorId: 'sadang-gate', direction: 0, scale: .8);
    await resizeAnchor(anchorId: 'hyeopmun-west', direction: 0, scale: 1.2);

    expect(anchorStore.placements, hasLength(3));

    final sadangAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-sadang-2'),
    );
    final sadangTapTarget = find.descendant(
      of: sadangAnchor,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ),
    );
    tester.widget<GestureDetector>(sadangTapTarget).onTap!();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();
    final rotatedSadang = anchorStore.placements.singleWhere(
      (placement) => placement.anchorId == 'sadang',
    );
    expect(rotatedSadang.direction, 3);
    expect(rotatedSadang.scale, closeTo(1.35, .001));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: IlDuWorldScreen(
          loadManifest: () async => manifest,
          loadProjection: () async => _verifiedB2Projection(),
          decorationStore: _MemoryDecorationStore(),
          anchorPlacementStore: anchorStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final (anchorId, direction, scale) in <(String, int, double)>[
      ('sadang', 3, 1.35),
      ('sadang-gate', 0, .8),
      ('hyeopmun-west', 0, 1.2),
    ]) {
      final anchor = find.byKey(
        ValueKey('ildu-map-turntable-$anchorId-$direction'),
      );
      final tapTarget = find.descendant(
        of: anchor,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTap != null,
        ),
      );
      tester.widget<GestureDetector>(tapTarget).onTap!();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Slider>(find.byKey(ValueKey('ildu-scale-slider-$anchorId')))
            .value,
        closeTo(scale, .001),
      );
    }

    expect(tester.takeException(), isNull);
  });
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

PersonalHanokProjection _verifiedB1Projection() {
  const text = CurriculumText(ko: '솟을대문', de: 'Tor', en: 'Gate');
  final competence = HanokCompetenceProjection.fromSnapshot(
    snapshot: const CourseMasterySnapshot(
      completedUnitIds: <String>['a1-1', 'a2-1', 'b1-1'],
    ),
    courseUnits: const <CourseUnit>[
      CourseUnit(id: 'a1-1', level: 'a1', order: 1, title: text, canDo: text),
      CourseUnit(id: 'a2-1', level: 'a2', order: 1, title: text, canDo: text),
      CourseUnit(id: 'b1-1', level: 'b1', order: 1, title: text, canDo: text),
    ],
  );
  return PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    competence: competence,
  );
}

PersonalHanokProjection _verifiedB2Projection() {
  const text = CurriculumText(ko: '사당', de: 'Schrein', en: 'Shrine');
  final competence = HanokCompetenceProjection.fromSnapshot(
    snapshot: const CourseMasterySnapshot(
      completedUnitIds: <String>['a1-1', 'a2-1', 'b1-1', 'b2-1'],
    ),
    courseUnits: const <CourseUnit>[
      CourseUnit(id: 'a1-1', level: 'a1', order: 1, title: text, canDo: text),
      CourseUnit(id: 'a2-1', level: 'a2', order: 1, title: text, canDo: text),
      CourseUnit(id: 'b1-1', level: 'b1', order: 1, title: text, canDo: text),
      CourseUnit(id: 'b2-1', level: 'b2', order: 1, title: text, canDo: text),
    ],
  );
  return PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
    competence: competence,
  );
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
