import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/discover_catalog.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets('prioritizes book capture and exposes all feature families', (
    tester,
  ) async {
    await _pumpDiscover(tester);

    expect(find.text('Finde genau, was du brauchst.'), findsOneWidget);
    expect(find.text('Starte mit deiner Buchseite'), findsOneWidget);
    expect(find.text('Buchseite'), findsOneWidget);
    expect(find.text('Wörter & Bücher'), findsOneWidget);
  });

  testWidgets('filters the discoverable feature catalog by search and family', (
    tester,
  ) async {
    await _pumpDiscover(tester);

    await tester.enterText(find.byType(TextField), 'Wortkette');
    await tester.pump();

    expect(_plainText('Wortkette'), findsOneWidget);
    expect(find.text('Hangul'), findsNothing);

    await tester.tap(find.text('Wörter & Bücher'));
    await tester.pump();

    expect(find.text('Keine passende Funktion gefunden.'), findsOneWidget);
  });

  testWidgets(
    'catalog entries keep every existing destination searchable and complete',
    (tester) async {
      await _pumpDiscover(tester);
      final t = AppL10n.of(tester.element(find.byType(DiscoverScreen)));
      final entries = discoverCatalog(t);

      expect(entries, hasLength(24));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(24));
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

Future<void> _pumpDiscover(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const DiscoverScreen(),
    ),
  );
}
