import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/ildu_anchor_placement_service.dart';
import 'package:ko_lernen_app/services/ildu_construction_progress_service.dart';
import 'package:ko_lernen_app/services/ildu_decoration_placement_service.dart';

void main() {
  late IlDuWorldManifest manifest;
  late IlDuEstateConstructionPlan constructionPlan;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
    constructionPlan = IlDuEstateConstructionPlan.fromJson(
      jsonDecode(
        await File(
          'assets/data/ildu_construction/estate_plan_v1.json',
        ).readAsString(),
      ),
      {
        'sarangchae': jsonDecode(
          await File(
            'assets/data/ildu_construction/sarangchae_v1.json',
          ).readAsString(),
        ),
      },
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

  testWidgets(
    'every authored turntable anchor exposes map transform controls',
    (tester) async {
      tester.view.physicalSize = const Size(1179, 4000);
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

      final anchors = <String, IlDuWorldAnchor>{
        for (final anchor in <IlDuWorldAnchor>[
          ...manifest.buildings,
          ...manifest.gates,
        ])
          anchor.id: anchor,
      };
      expect(kIlDuTurntables.keys, everyElement(isIn(anchors.keys)));

      for (final entry in kIlDuTurntables.entries) {
        final anchor = anchors[entry.key]!;
        final direction = entry.value.directionForDegrees(anchor.rotation);
        expect(
          find.byKey(ValueKey('ildu-map-turntable-${anchor.id}-$direction')),
          findsOneWidget,
          reason: '${anchor.id} must render its authored map direction.',
        );
        expect(
          find.byKey(ValueKey('ildu-anchor-gesture-${anchor.id}')),
          findsOneWidget,
          reason: '${anchor.id} must own its direct drag and pinch surface.',
        );

        _selectMapAnchor(tester, anchor.id);
        await tester.pumpAndSettle();

        expect(
          find.byKey(ValueKey('ildu-turntable-${anchor.id}')),
          findsOneWidget,
          reason: '${anchor.id} must expose the eight-direction control.',
        );
        expect(
          find.byKey(ValueKey('ildu-scale-slider-${anchor.id}')),
          findsOneWidget,
          reason: '${anchor.id} must expose the persisted size control.',
        );
      }

      expect(tester.takeException(), isNull);
    },
  );

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
    expect(mapAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'jungmunganchae');
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
    expect(gateAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'main-gate');
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
    expect(sadangAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'sadang');
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
    expect(changoAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'changgo');
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

  testWidgets('selecting Anchae exposes its approved eight-view turntable', (
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

    final anchaeAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-anchae-2'),
    );
    expect(anchaeAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'anchae');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ildu-turntable-anchae')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('ildu-map-turntable-anchae-3')),
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
    _selectMapAnchor(tester, 'araechae');
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
    expect(anchor, findsOneWidget);
    final dragTarget = find.byKey(
      const ValueKey('ildu-anchor-gesture-sarangchae'),
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
    expect(anchorStore.placements.single.scale, 1);
    expect(anchorStore.saveCalls, 1);
    expect(mapController.value, mapTransformBeforeDrag);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two finger pinch scales one building and saves once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 2556);
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

    final mapController = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final anchor = find.byKey(const ValueKey('ildu-map-turntable-sadang-2'));
    final center = tester.getCenter(anchor);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);

    await first.down(center - const Offset(36, 0));
    await second.down(center - const Offset(12, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(60, 0));
    await second.moveTo(center + const Offset(12, 0));
    await tester.pump();
    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('ildu-scale-slider-sadang')),
          )
          .value,
      greaterThan(1),
    );
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(anchorStore.placements, hasLength(1));
    expect(anchorStore.saveCalls, 1);
    expect(anchorStore.placements.single.anchorId, 'sadang');
    expect(anchorStore.placements.single.direction, 2);
    expect(anchorStore.placements.single.scale, greaterThan(1));
    expect(
      anchorStore.placements.single.scale,
      lessThanOrEqualTo(IlDuAnchorPlacement.maximumScale),
    );
    expect(mapController.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dedicated controls resize and restore authored asset types', (
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
      expect(anchor, findsOneWidget);
      _selectMapAnchor(tester, anchorId);
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
    await resizeAnchor(anchorId: 'anchae-store', direction: 2, scale: 1.15);
    await resizeAnchor(anchorId: 'gokgan', direction: 2, scale: 1.3);
    await resizeAnchor(anchorId: 'toilet-north', direction: 0, scale: .9);
    await resizeAnchor(anchorId: 'toilet-south', direction: 0, scale: 1.1);

    expect(anchorStore.placements, hasLength(7));

    final sadangAnchor = find.byKey(
      const ValueKey('ildu-map-turntable-sadang-2'),
    );
    expect(sadangAnchor, findsOneWidget);
    _selectMapAnchor(tester, 'sadang');
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
      ('anchae-store', 2, 1.15),
      ('gokgan', 2, 1.3),
      ('toilet-north', 0, .9),
      ('toilet-south', 0, 1.1),
    ]) {
      final anchor = find.byKey(
        ValueKey('ildu-map-turntable-$anchorId-$direction'),
      );
      expect(anchor, findsOneWidget);
      _selectMapAnchor(tester, anchorId);
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

  testWidgets('transform saves stay ordered and persist the latest snapshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final anchorStore = _ControlledAnchorStore();

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

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pump();
    expect(anchorStore.saveSnapshots, hasLength(1));
    expect(anchorStore.maximumConcurrentSaves, 1);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('ildu-scale-slider-sarangchae')),
    );
    slider.onChanged!(1.35);
    slider.onChangeEnd!(1.35);
    await tester.pump();

    expect(
      anchorStore.saveSnapshots,
      hasLength(1),
      reason: 'A newer transform must wait for the active durable write.',
    );
    anchorStore.completeNextSave();
    await tester.pump();
    expect(anchorStore.saveSnapshots, hasLength(2));
    expect(anchorStore.maximumConcurrentSaves, 1);

    anchorStore.completeNextSave();
    await tester.pump();

    expect(anchorStore.placements, hasLength(1));
    expect(anchorStore.placements.single.direction, 1);
    expect(anchorStore.placements.single.scale, closeTo(1.35, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a successful latest transform clears an earlier save failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final anchorStore = _ControlledAnchorStore();

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
    final screenContext = tester.element(find.byType(IlDuWorldScreen));
    final saveError = AppL10n.of(screenContext).ilduWorldSaveError;

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pump();
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('ildu-scale-slider-sarangchae')),
    );
    slider.onChanged!(1.35);
    slider.onChangeEnd!(1.35);
    await tester.pump();

    anchorStore.completeNextSave(fail: true);
    await tester.pump();
    anchorStore.completeNextSave();
    await tester.pump();

    expect(anchorStore.placements.single.direction, 1);
    expect(anchorStore.placements.single.scale, closeTo(1.35, .001));
    expect(find.text(saveError), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a construction-active Sarangchae renders the ghost layer and next-step '
    'sheet while the map keeps pan and zoom',
    (tester) async {
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
            loadConstructionPlan: () async => constructionPlan,
            constructionProgressStore: _MemoryConstructionStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 단계 에셋이 아직 없으므로 1차 렌더 경로는 고스트 모드다.
      expect(
        find.byKey(const ValueKey('ildu-construction-layer-sarangchae')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-ghost-sarangchae')),
        findsOneWidget,
      );
      // 시트: 현재 공정 태그·단계명·다음 공정 CTA.
      expect(
        find.byKey(const ValueKey('ildu-construction-process-tag')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-stage-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-next-cta')),
        findsOneWidget,
      );
      // 기존 지도 상호작용은 그대로다.
      final mapViewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(mapViewer.panEnabled, isTrue);
      expect(mapViewer.scaleEnabled, isTrue);
      expect(mapViewer.minScale, 1);
      expect(mapViewer.maxScale, 2.2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed construction plan load falls back to the turntable render',
    (tester) async {
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
            loadConstructionPlan: () async =>
                throw const FormatException('broken plan'),
            constructionProgressStore: _MemoryConstructionStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // fail-open 렌더: 화면은 죽지 않고 기존 턴테이블 경로로 복귀한다.
      expect(
        find.byKey(const ValueKey('ildu-map-turntable-sarangchae-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-layer-sarangchae')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ildu-construction-next-cta')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

void _selectMapAnchor(WidgetTester tester, String anchorId) {
  final tapTarget = find.ancestor(
    of: find.byKey(ValueKey('ildu-anchor-gesture-$anchorId')),
    matching: find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.onTap != null,
    ),
  );
  tester.widget<GestureDetector>(tapTarget).onTap!();
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

final class _MemoryConstructionStore implements IlDuConstructionProgressStore {
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
  int saveCalls = 0;

  @override
  Future<List<IlDuAnchorPlacement>> load(IlDuWorldManifest manifest) async =>
      placements;

  @override
  Future<void> save(List<IlDuAnchorPlacement> placements) async {
    saveCalls += 1;
    this.placements = List.unmodifiable(placements);
  }
}

class _ControlledAnchorStore implements IlDuAnchorPlacementStore {
  List<IlDuAnchorPlacement> placements = const [];
  final List<List<IlDuAnchorPlacement>> saveSnapshots = [];
  final List<Completer<void>> _pendingSaves = [];
  int _activeSaves = 0;
  int maximumConcurrentSaves = 0;

  @override
  Future<List<IlDuAnchorPlacement>> load(IlDuWorldManifest manifest) async =>
      placements;

  @override
  Future<void> save(List<IlDuAnchorPlacement> placements) async {
    final snapshot = List<IlDuAnchorPlacement>.unmodifiable(placements);
    final completion = Completer<void>();
    saveSnapshots.add(snapshot);
    _pendingSaves.add(completion);
    _activeSaves++;
    if (_activeSaves > maximumConcurrentSaves) {
      maximumConcurrentSaves = _activeSaves;
    }
    await completion.future;
    this.placements = snapshot;
    _activeSaves--;
  }

  void completeNextSave({bool fail = false}) {
    final completion = _pendingSaves.removeAt(0);
    if (fail) {
      completion.completeError(StateError('controlled save failure'));
      return;
    }
    completion.complete();
  }
}
