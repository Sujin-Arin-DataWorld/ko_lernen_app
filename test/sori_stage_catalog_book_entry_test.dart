import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

final _book = find.byKey(const ValueKey('catalog-card-book_capture'));
final _start = find.byKey(const ValueKey('catalog-start-book_capture'));

Future<void> _showBook(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    _book,
    250,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 60,
  );
  await Scrollable.ensureVisible(tester.element(_book), alignment: .15);
  await pumpSoriStage(tester);
}

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
      testWidgets('$language illustrated book card is reachable at $viewport', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
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
        await _showBook(tester);
        expect(_book, findsOneWidget);
        final card = tester.widget<SoriCatalogCard>(_book);
        expect(card.entry.learnSection, SoriLearnSection.words);
        final artFinder = find.descendant(
          of: _book,
          matching: find.byType(Image),
        );
        final art = tester.widget<Image>(artFinder);
        expect(
          (art.image as AssetImage).assetName,
          'assets/illustrations/activities/book_capture.webp',
        );
        expect(art.fit, BoxFit.contain);
        expect(tester.getSize(artFinder).aspectRatio, closeTo(4 / 3, .001));
        final title = find.descendant(
          of: _book,
          matching: find.text(
            language == 'de' ? 'Buch fotografieren' : 'Scan a book',
          ),
        );
        expect(title.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse,
        );
        expect(_start.hitTestable(), findsOneWidget);
        final rect = tester.getRect(_book);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(viewport.size.width));
        expect(
          find.byTooltip(
            language == 'de' ? 'Buchseite einlesen' : 'Snap a page',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final state in ['ready', 'loading', 'error']) {
    for (final withFocus in [false, true]) {
      testWidgets(
        'book card opens capture with $state progress, focus=$withFocus',
        (tester) async {
          final pending = Completer<SoriStageProgressionSnapshot>();
          final controller = LearningFocusController()..value = focus;
          addTearDown(controller.dispose);
          var permissionRequests = 0;
          final routes = <String?>[];
          await tester.pumpWidget(
            catalogTestApp(
              controller: withFocus ? controller : null,
              onOpen: (_, _) =>
                  fail('Scanning must not wait for reward snapshots'),
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
          await _showBook(tester);
          final prefs = await SharedPreferences.getInstance();
          final before = {
            for (final key in prefs.getKeys()) key: prefs.get(key),
          };
          await tester.tap(_start);
          await pumpSoriStage(tester);
          expect(routes, ['/book']);
          expect(find.byType(BookCaptureScreen), findsOneWidget);
          expect(find.widgetWithText(SoriButton, 'Camera'), findsOneWidget);
          expect(
            find.widgetWithText(SoriButton, 'From gallery'),
            findsOneWidget,
          );
          expect(permissionRequests, 0);
          Navigator.of(tester.element(find.byType(BookCaptureScreen))).pop();
          await pumpSoriStage(tester);
          expect(_start.hitTestable(), findsOneWidget);
          expect({
            for (final key in prefs.getKeys()) key: prefs.get(key),
          }, before);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Games retains its own activity catalog', (tester) async {
    await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
    await pumpSoriStage(tester);
    expect(_book, findsNothing);
  });
  testWidgets('book card stays reachable after rotation and scrolling back', (
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
    await _showBook(tester);
    tester.view.physicalSize = const Size(844, 390);
    await pumpSoriStage(tester);
    await _showBook(tester);
    expect(_start.hitTestable(), findsOneWidget);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await pumpSoriStage(tester);
    scroll.jumpTo(0);
    await pumpSoriStage(tester);
    await _showBook(tester);
    expect(_start.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
