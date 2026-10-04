import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/my_words_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await DataLoader.loadVocab();
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_custom_packs_v1': '{}',
      'kl_tut_bookshelf': true,
      'kl_tut_hardWords': true,
    });
    await Storage.init();
  });

  testWidgets(
    'initial tab, keyboard arrows, and 200 percent compact layout stay usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(const MyWordsScreen(initialTab: MyWordsTab.shelf), textScale: 2),
      );
      await tester.pump();

      final t = AppL10n.of(tester.element(find.byType(MyWordsScreen)));
      final tabs = find.byKey(const ValueKey('my-words-tabs'));
      expect(tabs, findsOneWidget);
      expect(DefaultTabController.of(tester.element(tabs)).index, 1);
      expect(find.text(t.myWordsTabSearch), findsOneWidget);
      expect(find.text(t.myWordsTabShelf), findsOneWidget);
      expect(find.text(t.myWordsTabDifficult), findsOneWidget);

      final searchTab = find.byKey(const ValueKey('my-words-tab-search'));
      await tester.ensureVisible(searchTab);
      await tester.pump();
      await tester.tap(searchTab);
      await tester.pumpAndSettle();
      expect(DefaultTabController.of(tester.element(tabs)).index, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(DefaultTabController.of(tester.element(tabs)).index, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all destinations stay visible and selectable at 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      for (final locale in const [Locale('de'), Locale('en')]) {
        await tester.pumpWidget(
          _host(const MyWordsScreen(), textScale: 2, locale: locale),
        );
        await tester.pumpAndSettle();
        final navigation = find.byKey(const ValueKey('my-words-tabs'));
        final controller = DefaultTabController.of(tester.element(navigation));
        final horizontalScrollers = find.descendant(
          of: navigation,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.right,
          ),
        );
        expect(horizontalScrollers, findsNothing);
        for (final tab in MyWordsTab.values) {
          final target = find.byKey(ValueKey('my-words-tab-${tab.name}'));
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(48));
          final before = tester.getSemantics(target).getSemanticsData();
          expect(before.hasAction(ui.SemanticsAction.tap), isTrue);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(controller.index, tab.index);
          expect(
            tester
                .getSemantics(target)
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            ui.Tristate.isTrue,
          );
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('tabs carry search/bookmark/heart icons (1.6 룰링)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MyWordsScreen()));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my-words-tab-search')),
        matching: find.byIcon(Icons.search_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my-words-tab-shelf')),
        matching: find.byIcon(Icons.bookmark_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my-words-tab-difficult')),
        matching: find.byIcon(Icons.favorite_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('+ Photo sheet keeps the two existing named destinations', (
    tester,
  ) async {
    final routes = <String>[];
    await tester.pumpWidget(
      _host(
        const MyWordsScreen(),
        onGenerateRoute: (settings) {
          routes.add(settings.name ?? '');
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text(settings.name ?? '')),
          );
        },
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(MyWordsScreen)));

    await tester.tap(find.text(t.myWordsPhotoAction));
    await tester.pumpAndSettle();
    expect(find.text(t.bookCaptureTitle), findsOneWidget);
    expect(find.text(t.vocabNotebookTitle), findsOneWidget);
    // 지시서 1.19 정리: 설명 없이 나열되던 두 옵션에 한 줄 부제가 붙는다.
    expect(find.text(t.myWordsPhotoBookOptionSubtitle), findsOneWidget);
    expect(find.text(t.myWordsPhotoNotebookOptionSubtitle), findsOneWidget);
    await tester.tap(find.text(t.bookCaptureTitle));
    await tester.pumpAndSettle();
    expect(routes.last, '/book');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.myWordsPhotoAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.vocabNotebookTitle));
    await tester.pumpAndSettle();
    expect(routes.last, '/vocab_notebook');
  });

  testWidgets('all aliases select the exact tab and retain route settings', (
    tester,
  ) async {
    const expected = <String, MyWordsTab>{
      '/my_words': MyWordsTab.search,
      '/wordbook/search': MyWordsTab.search,
      '/bookshelf': MyWordsTab.shelf,
      '/hard_words': MyWordsTab.difficult,
    };
    await tester.pumpWidget(
      _host(
        const Scaffold(body: Text('root')),
        onGenerateRoute: (settings) {
          final tab = myWordsTabForRoute(settings.name);
          if (tab == null) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => MyWordsScreen(initialTab: tab),
          );
        },
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final entry in expected.entries) {
      navigator.pushNamed(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final screen = find.byType(MyWordsScreen);
      expect(screen, findsOneWidget);
      final context = tester.element(screen);
      final tabsContext = tester.element(
        find.byKey(const ValueKey('my-words-tabs')),
      );
      expect(DefaultTabController.of(tabsContext).index, entry.value.index);
      expect(ModalRoute.of(context)!.settings.name, entry.key);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('root'), findsOneWidget);
    }
  });

  test('main registers the canonical route and all compatibility aliases', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final route in const <String>[
      '/my_words',
      '/wordbook/search',
      '/bookshelf',
      '/hard_words',
    ]) {
      expect(source, contains("case '$route':"));
    }
    expect(source, contains('myWordsTabForRoute(settings.name)'));
    expect(source, contains('MyWordsScreen(initialTab: initialTab)'));
  });
}

Widget _host(
  Widget home, {
  double textScale = 1,
  Locale locale = const Locale('de'),
  RouteFactory? onGenerateRoute,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    onGenerateRoute: onGenerateRoute,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: SoriTypeScale(child: child!),
    ),
    home: home,
  );
}
