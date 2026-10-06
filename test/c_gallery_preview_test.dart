import 'dart:ui'
    show SemanticsAction, Tristate, PointerDeviceKind, ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/companion_art.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_objects.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_diy_preview.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

import '../tool/concept_c_preview.dart';

Future<void> prepareArt(WidgetTester tester) async {
  await tester.runAsync(() async {
    final font = FontLoader('NotoSansKR')
      ..addFont(
        rootBundle.load('assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf'),
      );
    await font.load();
    final interfaceFont = FontLoader('Paperlogy');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      interfaceFont.addFont(
        rootBundle.load('assets/fonts/Paperlogy/Paperlogy-$weight.ttf'),
      );
    }
    await interfaceFont.load();
    await Future.wait([
      CImageCache.load('assets/illustrations/concept_c/material_atlas.png'),
      CImageCache.load('assets/illustrations/concept_c/hero_atlas.png'),
      CImageCache.load('assets/illustrations/concept_c/game_object_atlas.png'),
      CImageCache.load(CReferenceArt.path),
      CImageCache.load(CGameReferenceArt.path),
      CImageCache.load(CGameReferenceArt.labelRepairPath),
    ]);
  });
}

Finder imageAction(String label) => find.byWidgetPredicate(
  (widget) => widget is CImageTap && widget.label == label,
);

void main() {
  for (final imageOnly in [false, true]) {
    testWidgets(
      '${imageOnly ? 'image' : 'material'} action stays separate from a sibling heading',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var activations = 0;
        void activate() => activations++;
        final action = imageOnly
            ? CImageTap(
                label: 'Üben',
                onTap: activate,
                child: const SizedBox(width: 48, height: 48),
              )
            : CMaterialAction(
                label: 'Üben',
                onTap: activate,
                compact: true,
                surfaceTexture: const SizedBox.expand(),
              );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CPaperPanel(
                surfaceTexture: const SizedBox.expand(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text('Laute kennenlernen'),
                    ),
                    action,
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.bySemanticsLabel(RegExp(r'^Üben$'));
        expect(button, findsOneWidget);
        final node = tester.getSemantics(button);
        var data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isHeader, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(activations, 1);

        final pressable = find.byType(SoriPressable);
        final focusContext = tester.element(
          find.descendant(of: pressable, matching: find.byType(MouseRegion)),
        );
        Focus.of(focusContext).requestFocus();
        await tester.pumpAndSettle();
        data = tester.getSemantics(button).getSemanticsData();
        expect(data.flagsCollection.isFocused, Tristate.isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(activations, 2);

        final contact = await tester.startGesture(tester.getCenter(pressable));
        await tester.pump();
        await contact.cancel();
        await tester.pumpAndSettle();
        expect(activations, 2);
        await tester.tap(pressable);
        await tester.pumpAndSettle();
        expect(activations, 3);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'unlit lantern changes only transmitted light, keeping its frame',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: ValueKey('lit-lantern'),
                  child: SizedBox(
                    width: 80,
                    height: 119,
                    child: CLantern(lit: true),
                  ),
                ),
                RepaintBoundary(
                  key: ValueKey('unlit-lantern'),
                  child: SizedBox(
                    width: 80,
                    height: 119,
                    child: CLantern(lit: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(CObjectArt.path(CObject.lantern)),
          tester.element(find.byType(CLantern).first),
        );
      });
      await tester.pumpAndSettle();
      final rendered = await tester.runAsync(() async {
        final data = <List<int>>[];
        for (final key in ['lit-lantern', 'unlit-lantern']) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(ValueKey(key)),
          );
          final image = await boundary.toImage(pixelRatio: 4);
          final pixels = await image.toByteData(
            format: ImageByteFormat.rawRgba,
          );
          data.add(pixels!.buffer.asUint8List().toList());
          image.dispose();
        }
        return data;
      });
      List<int> pixel(int state, Offset source) {
        final x = ((80 - 119 * 926 / 1698) / 2 + source.dx * 119 / 1698) * 4;
        final y = source.dy * 119 / 1698 * 4;
        final index = (y.round() * 320 + x.round()) * 4;
        return rendered![state].sublist(index, index + 4);
      }

      for (final point in const [
        Offset(480, 40),
        Offset(480, 510),
        Offset(527, 960),
        Offset(430, 1470),
        Offset(310, 840),
        Offset(310, 1258),
      ]) {
        expect(pixel(0, point)[3], greaterThan(0));
        expect(
          pixel(1, point),
          pixel(0, point),
          reason: 'Brass and wood must stay identical',
        );
      }
      expect(
        pixel(1, const Offset(310, 900)),
        isNot(pixel(0, const Offset(310, 900))),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Heute scrolls to the whole C Hanok with wheel and mouse drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 947);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await prepareArt(tester);
    await tester.pumpWidget(const CPreviewApp());
    await tester.pumpAndSettle();

    final scroll = find.byKey(const ValueKey('c-scroll-0'));
    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    final nav = tester.getRect(imageAction('Heute'));
    expect(controller.position.maxScrollExtent, greaterThan(0));
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(195, 450),
        scrollDelta: Offset(0, 160),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));

    controller.jumpTo(0);
    await tester.pump();
    await tester.drag(
      scroll,
      const Offset(0, -240),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(imageAction('Zurück'), findsNothing);

    final scene = find.byKey(const ValueKey('c-today-hanok-scene'));
    await tester.ensureVisible(scene);
    await tester.pumpAndSettle();
    final whole = tester.getRect(scene);
    expect(whole.width / whole.height, closeTo(278 / 229, .001));
    expect(whole.bottom, lessThanOrEqualTo(nav.top));
    expect(tester.getRect(imageAction('Heute')), nav);
    await tester.tap(imageAction('Hanok'));
    await tester.pumpAndSettle();
    final hanok = tester.getSize(find.byKey(const ValueKey('c-hanok-scene')));
    expect(
      hanok.width / hanok.height,
      closeTo(whole.width / whole.height, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'next lesson and treasure action stay above navigation with an iPhone inset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await prepareArt(tester);
      await tester.pumpWidget(const CPreviewApp());
      await tester.pumpAndSettle();
      final navTop = tester.getRect(imageAction('Heute')).top;
      for (final name in ['Weiterlernen', 'Öffnen']) {
        final action = find.byWidgetPredicate(
          (widget) => widget is CMaterialAction && widget.label == name,
        );
        expect(
          tester.getRect(action).bottom,
          lessThanOrEqualTo(navTop),
          reason: name,
        );
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      }
      final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(overlay.value.statusBarColor, Colors.transparent);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'image-only navigation keeps one accessible name and a tap action',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await prepareArt(tester);
      await tester.pumpWidget(const CPreviewApp());
      await tester.pumpAndSettle();
      for (final label in ['Heute', 'Lernen', 'Spiele', 'Hanok', 'Gye']) {
        final finder = imageAction(label);
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        await tester.tap(finder);
        await tester.pumpAndSettle();
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(data.label, label);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.flagsCollection.isSelected, Tristate.isTrue);
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    '320dp with OS 200% text and reduce motion keeps all tabs usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await prepareArt(tester);
      await tester.pumpWidget(const CPreviewApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(CPreviewSpaces));
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      for (final label in ['Heute', 'Lernen', 'Spiele', 'Hanok', 'Gye']) {
        final finder = imageAction(label);
        expect(tester.getRect(finder).bottom, lessThanOrEqualTo(740));
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
        if (label == 'Spiele') {
          expect(find.text('Vorschau'), findsNothing);
          expect(find.text('Preview'), findsNothing);
        }
      }
    },
  );

  testWidgets(
    'Heute uses canonical Taego and primary action responds immediately',
    (tester) async {
      tester.view.physicalSize = const Size(390, 947);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await prepareArt(tester);
      await tester.pumpWidget(const CPreviewApp());
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  CompanionArt.taegoPortrait,
        ),
        findsOneWidget,
      );
      final action = find.byWidgetPredicate(
        (widget) => widget is CMaterialAction && widget.label == 'Weiterlernen',
      );
      expect(tester.getSize(action).width, greaterThan(330));
      await tester.tap(action);
      await tester.pump();
      expect(imageAction('Zurück'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Gye never invents membership and projects confirmed counts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 947);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await prepareArt(tester);
    await tester.pumpWidget(const CPreviewApp());
    await tester.pumpAndSettle();
    await tester.tap(imageAction('Gye'));
    await tester.pumpAndSettle();
    expect(find.text('4 Mitglieder'), findsNothing);
    expect(find.text('2 von 3 Laternen'), findsNothing);
    for (final name in [
      'Gruppe finden',
      'Gruppe erstellen',
      'Gye kennenlernen',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.pumpWidget(
      const CPreviewApp(
        group: CGroupSnapshot(
          name: 'Unser Dienstag',
          memberCount: 7,
          litLanterns: 1,
          totalLanterns: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unser Dienstag'), findsOneWidget);
    expect(find.text('7 Mitglieder'), findsOneWidget);
    expect(find.text('1 von 3 Laternen'), findsOneWidget);
    expect(find.text('Gruppe öffnen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eight games remain reachable including DIY saved-pack entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 947);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await prepareArt(tester);
    await tester.pumpWidget(const CPreviewApp());
    await tester.pumpAndSettle();
    await tester.tap(imageAction('Spiele'));
    await tester.pumpAndSettle();
    final hero = find.byWidgetPredicate(
      (w) => w is CMaterialAction && w.label == 'Spiel ansehen',
    );
    await tester.tap(hero);
    await tester.pumpAndSettle();
    expect(find.text('Lege die passende Silbe.'), findsOneWidget);
    for (final tile in ['호', '텔', '변', '사', '상']) {
      final f = find.byWidgetPredicate(
        (w) => w is CMaterialAction && w.label == tile,
      );
      expect(tester.getSize(f).width, greaterThanOrEqualTo(48));
    }
    await tester.tap(imageAction('Zurück'));
    await tester.pumpAndSettle();
    for (final name in [
      'Anlaute',
      'Lückentext',
      'Blitz-Paare',
      'Satzbau',
      'Wortkette',
      'Eigene Wörter · DIY-Spiel',
      'Tageschallenge',
    ]) {
      final f = imageAction(
        name == 'Tageschallenge' ? 'Tageschallenge ansehen' : name,
      );
      expect(f, findsOneWidget, reason: name);
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
      expect(imageAction('Zurück'), findsOneWidget, reason: name);
      if (name == 'Eigene Wörter · DIY-Spiel') {
        expect(find.text('Deine Wörter. Dein Spiel.'), findsOneWidget);
        expect(find.text('Wörter sammeln'), findsOneWidget);
      }
      if (name == 'Wortkette') {
        expect(find.text('끝말잇기'), findsOneWidget);
        expect(find.text('사과 → 과자'), findsOneWidget);
      }
      await tester.tap(imageAction('Zurück'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'DIY carries the chosen saved pack ID and gates quiz by word count',
    (tester) async {
      String? playedPack;
      String? playedMode;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CDiyPackChooser(
                packs: const [
                  CGamePackSnapshot(
                    id: 'saved-pack-7',
                    title: 'Mein Café',
                    usableWordCount: 2,
                  ),
                ],
                english: false,
                onCollect: () {},
                onPlay: (id, mode) {
                  playedPack = id;
                  playedMode = mode;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pack = find.byWidgetPredicate(
        (w) => w is CMaterialAction && w.label == 'Mein Café · 2',
      );
      await tester.tap(pack);
      await tester.pumpAndSettle();
      final quiz = tester.widget<CMaterialAction>(
        find.byWidgetPredicate(
          (w) => w is CMaterialAction && w.label == 'Quiz',
        ),
      );
      expect(quiz.onTap, isNull);
      expect(find.text('Ab 4 Wörtern mit Übersetzung.'), findsOneWidget);
      final matching = find.byWidgetPredicate(
        (w) => w is CMaterialAction && w.label == 'Paare finden',
      );
      await tester.ensureVisible(matching);
      await tester.tap(matching);
      await tester.pump();
      expect(playedPack, 'saved-pack-7');
      expect(playedMode, 'matching');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings turns on hover and focus without delaying keyboard activation',
    (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CImageTap(
              label: 'Settings',
              onTap: () => opened++,
              child: const SizedBox.square(
                dimension: 48,
                child: CSettingsCog(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rotation = find.descendant(
        of: find.byType(CSettingsCog),
        matching: find.byType(RotationTransition),
      );
      final turn = tester.widget<RotationTransition>(rotation);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(200, 200));
      await mouse.moveTo(tester.getCenter(find.byType(CSettingsCog)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(turn.turns.value, greaterThan(0));
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(200, 200));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.byType(CSettingsCog))).unfocus();
      await tester.pump();
      Focus.of(tester.element(find.byType(CSettingsCog))).requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester.widget<RotationTransition>(rotation).turns.value,
        allOf(greaterThan(0), lessThan(1)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 1);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings respects reduced motion while keeping tap available', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: CImageTap(
              label: 'Settings',
              onTap: () => opened++,
              child: const SizedBox.square(
                dimension: 48,
                child: CSettingsCog(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.byType(CSettingsCog))).requestFocus();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(CSettingsCog),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value,
      0,
    );
    await tester.tap(find.byType(CSettingsCog));
    await tester.pump();
    expect(opened, 1);
  });
}
