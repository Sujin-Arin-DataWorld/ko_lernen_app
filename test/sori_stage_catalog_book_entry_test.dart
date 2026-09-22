import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

void main() {
  late LearningFocus focus;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    focus = await loadFirstCatalogFocus();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_book': true});
    await Storage.init();
  });

  for (final language in ['de', 'en']) {
    for (final viewport in [
      (size: const Size(320, 640), scale: 2.0),
      (size: const Size(390, 844), scale: 1.0),
      (size: const Size(720, 1024), scale: 2.0),
    ]) {
      testWidgets(
        '$language book entry is visible without scrolling at $viewport',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final semantics = tester.ensureSemantics();
          try {
            final controller = LearningFocusController()..value = focus;
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              catalogTestApp(
                locale: language,
                scale: viewport.scale,
                controller: controller,
              ),
            );
            await pumpSoriStage(tester);
            final label = language == 'de'
                ? 'Buchseite einlesen'
                : 'Snap a page';
            final entry = find.byTooltip(label).hitTestable();
            expect(entry.hitTestable(), findsOneWidget);
            final rect = tester.getRect(entry);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(viewport.size.width));
            final nav = find.byType(NavigationBar);
            final bottom = nav.evaluate().isEmpty
                ? viewport.size.height
                : tester.getTopLeft(nav).dy;
            expect(rect.bottom, lessThanOrEqualTo(bottom));
            expect(
              tester.getSemantics(entry),
              matchesSemantics(
                tooltip: label,
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final state in ['ready', 'loading', 'error']) {
    testWidgets('book entry opens capture directly with $state progress', (
      tester,
    ) async {
      final pending = Completer<SoriStageProgressionSnapshot>();
      var permissionRequests = 0;
      final routes = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          loadSnapshot: () => state == 'ready'
              ? Future.value(catalogSnapshot())
              : pending.future,
          onGenerateRoute: (settings) {
            routes.add(settings.name);
            expect(settings.name, '/book');
            expect(settings.arguments, isNull);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => BookCaptureScreen(
                requestCameraPermission: () async {
                  permissionRequests++;
                  return false;
                },
              ),
            );
          },
        ),
      );
      await pumpSoriStage(tester);
      if (state == 'error') {
        pending.completeError(StateError('progress unavailable'));
        await pumpSoriStage(tester);
      }
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      await tester.tap(find.byTooltip('Snap a page').hitTestable());
      await pumpSoriStage(tester);
      expect(routes, ['/book']);
      expect(find.byType(BookCaptureScreen), findsOneWidget);
      expect(find.widgetWithText(SoriButton, 'Camera'), findsOneWidget);
      expect(find.widgetWithText(SoriButton, 'From gallery'), findsOneWidget);
      expect(permissionRequests, 0);
      Navigator.of(tester.element(find.byType(BookCaptureScreen))).pop();
      await pumpSoriStage(tester);
      expect(find.byTooltip('Snap a page').hitTestable(), findsOneWidget);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Games retains its own activity catalog', (tester) async {
    await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
    await pumpSoriStage(tester);
    expect(find.byTooltip('Snap a page'), findsNothing);
  });

  for (final fraction in [.25, .5, .75]) {
    testWidgets('camera entry accepts taps at $fraction header collapse', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final opened = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          locale: 'de',
          scale: 2,
          disableAnimations: false,
          scrollController: scroll,
          onGenerateRoute: (settings) {
            opened.add(settings.name);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Capture destination')),
            );
          },
        ),
      );
      await pumpSoriStage(tester);
      final header = tester.widget<SliverPersistentHeader>(
        find.byType(SliverPersistentHeader),
      );
      final range = header.delegate.maxExtent - header.delegate.minExtent;
      expect(range, greaterThan(0));
      scroll.jumpTo(20 + range * fraction);
      await pumpSoriStage(tester);
      final layer = tester.widget<Opacity>(
        find.byKey(const ValueKey('sori-collapsing-header-collapsed')),
      );
      expect(layer.opacity, closeTo(fraction, .001));
      final entry = find.byTooltip('Buchseite einlesen').hitTestable();
      expect(entry, findsOneWidget);
      await tester.tap(entry);
      await pumpSoriStage(tester);
      expect(opened, ['/book']);
      expect(find.text('Capture destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('camera entry stays usable in the collapsed and rotated header', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(catalogTestApp(scrollController: scroll));
    await pumpSoriStage(tester);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await pumpSoriStage(tester);
    expect(find.byTooltip('Snap a page').hitTestable(), findsOneWidget);
    tester.view.physicalSize = const Size(844, 390);
    await pumpSoriStage(tester);
    expect(find.byTooltip('Snap a page').hitTestable(), findsOneWidget);
    scroll.jumpTo(0);
    await pumpSoriStage(tester);
    expect(find.byTooltip('Snap a page').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
