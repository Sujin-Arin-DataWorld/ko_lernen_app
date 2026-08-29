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
    expect(find.byType(InteractiveViewer), findsOneWidget);
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
    final gesture = tester.widget<GestureDetector>(dragTarget);
    gesture.onPanUpdate!(
      DragUpdateDetails(globalPosition: Offset.zero, delta: Offset(48, 24)),
    );
    gesture.onPanEnd!(DragEndDetails());
    await tester.pumpAndSettle();

    expect(anchorStore.placements, hasLength(1));
    expect(anchorStore.placements.single.anchorId, 'sarangchae');
    expect(anchorStore.placements.single.x, greaterThan(48.2));
    expect(anchorStore.placements.single.y, greaterThan(55.8));
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
