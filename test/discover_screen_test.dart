import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets('prioritizes book capture and exposes all feature families', (
    tester,
  ) async {
    await _pumpDiscover(tester);

    expect(find.text('Alle Lernwerkzeuge'), findsOneWidget);
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
