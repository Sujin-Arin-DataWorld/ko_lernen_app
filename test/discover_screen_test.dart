import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/discover_catalog.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets('04B shows four purpose filters and four priority routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <String>[];
    await _pumpDiscover(tester, onRoute: opened.add, textScale: 1.3);

    expect(find.text('Finde genau, was du brauchst.'), findsOneWidget);
    expect(
      find.text('Scannen, nachschlagen, hören oder eine kleine Pause machen.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      'Suchen: z. B. Aussprache, Buch, OCR …',
    );
    expect(find.text('Direkt zu deinem Ziel'), findsNothing);
    for (final filter in const ['Für mich', 'Sprache', 'Wörter', 'Freizeit']) {
      final finder = find.text(filter);
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0), reason: filter);
      expect(rect.right, lessThanOrEqualTo(308), reason: filter);
      final target = find.ancestor(of: finder, matching: find.byType(InkWell));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    }
    for (final priority in const [
      'Buch scannen',
      'Vokabelheft',
      'Aussprache hören',
      'Wörterbuch & Meine Wörter',
    ]) {
      expect(find.text(priority), findsOneWidget);
    }
    for (final body in const [
      'Text aus deinem Lehrbuch verstehen',
      'Dein Heft fotografieren und genau diese Wörter üben.',
      'Laute langsam vergleichen',
      'Gespeicherte Wörter wiederfinden',
    ]) {
      expect(find.text(body), findsOneWidget);
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    for (final entry in const [
      (key: 'book', route: '/book'),
      (key: 'notebook', route: '/vocab_notebook'),
      (key: 'pronunciation', route: '/listening'),
      (key: 'words', route: '/wordbook/search'),
    ]) {
      final priority = find.byKey(ValueKey('discover-priority-${entry.key}'));
      await tester.ensureVisible(priority);
      await tester.tap(priority);
      await tester.pumpAndSettle();
      expect(opened.last, entry.route);
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('filters the discoverable feature catalog by search and family', (
    tester,
  ) async {
    await _pumpDiscover(tester);

    await tester.enterText(find.byType(TextField), 'Wortkette');
    await tester.pump();

    expect(_plainText('Wortkette'), findsOneWidget);
    expect(find.text('Hangul'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump();

    await tester.tap(find.text('Wörter'));
    await tester.pump();

    expect(_plainText('Wortkette'), findsNothing);
    expect(find.text('Meine Wörter'), findsOneWidget);
  });

  testWidgets(
    'catalog entries keep every existing destination searchable and complete',
    (tester) async {
      await _pumpDiscover(tester);
      final t = AppL10n.of(tester.element(find.byType(DiscoverScreen)));
      final entries = discoverCatalog(t);

      expect(entries, hasLength(25));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(25));
      for (final entry in entries) {
        expect(entry.purpose, isNotNull, reason: entry.id);
        expect(entry.route, startsWith('/'), reason: entry.id);
        expect(entry.icon.codePoint, greaterThan(0), reason: entry.id);
        expect(entry.searchTerms, isNotEmpty, reason: entry.id);
        expect(
          entry.searchTerms.every((term) => term.trim().isNotEmpty),
          isTrue,
          reason: entry.id,
        );
      }
      expect(
        entries.map((entry) => entry.route),
        containsAll(const [
          '/book',
          '/vocab_notebook',
          '/hangul',
          '/grammar',
          '/scenarios',
          '/vocab',
          '/review',
          '/daily',
          '/chosung',
          '/wordle',
          '/cloze',
          '/speed_match',
          '/satz_arcade',
          '/kkeunmari',
          '/listening',
          '/smalltalk',
          '/bookshelf',
          '/wordbook/search',
          '/hard_words',
          '/path',
          '/stats',
          '/quests',
          '/dojangcheop',
          '/hanok',
          '/sarangbang',
        ]),
      );
    },
  );
}

Finder _plainText(String value) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data == value,
  description: 'plain text $value',
);

Future<void> _pumpDiscover(
  WidgetTester tester, {
  ValueChanged<String>? onRoute,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      onGenerateRoute: onRoute == null
          ? null
          : (settings) {
              onRoute(settings.name ?? '');
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: SizedBox()),
              );
            },
      home: textScale == 1
          ? const DiscoverScreen.preview()
          : MediaQuery.withClampedTextScaling(
              minScaleFactor: textScale,
              maxScaleFactor: textScale,
              child: const DiscoverScreen.preview(),
            ),
    ),
  );
}
