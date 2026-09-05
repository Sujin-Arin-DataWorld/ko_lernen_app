import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/my_words_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final tabs = find.byType(TabBar);
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
      final tabsContext = tester.element(find.byType(TabBar));
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
  RouteFactory? onGenerateRoute,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
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
