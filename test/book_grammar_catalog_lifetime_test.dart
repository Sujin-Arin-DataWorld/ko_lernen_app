import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Grammar> catalog;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_book': true});
    await Storage.init();
    catalog = await DataLoader.loadGrammar();
  });

  testWidgets('slow optional catalog never delays the analysis result', (
    tester,
  ) async {
    final pending = Completer<List<Grammar>>();
    await _pump(tester, () => pending.future);
    expect(find.text('Meaning en'), findsOneWidget);
    expect(find.text('Open grammar card'), findsNothing);
    pending.complete(catalog);
    await tester.pump();
    await tester.pump();
    expect(
      find.widgetWithText(SoriButton, 'Open grammar card'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('failed catalog leaves the result and description readable', (
    tester,
  ) async {
    await _pump(tester, () async => throw StateError('catalog unavailable'));
    expect(find.text('Meaning en'), findsOneWidget);
    expect(find.text('Open grammar card'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('an old-language catalog cannot attach links to a newer result', (
    tester,
  ) async {
    final pending = Completer<List<Grammar>>();
    await _pump(tester, () => pending.future, language: 'de');
    expect(find.text('Meaning de'), findsOneWidget);
    await _pump(tester, () async => [], language: 'en');
    expect(find.text('Meaning en'), findsOneWidget);
    pending.complete(catalog);
    await tester.pump();
    await tester.pump();
    expect(find.text('Open grammar card'), findsNothing);
    expect(find.text('Meaning en'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('late catalog completion after leaving has no UI effect', (
    tester,
  ) async {
    final pending = Completer<List<Grammar>>();
    await _pump(tester, () => pending.future);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(catalog);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Future<List<Grammar>> Function() loader, {
  String language = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: BookResultScreen(
        args: const {'text': '읽을 수 있어요.'},
        grammarLoader: loader,
        analyzer: ({required text, required targetLang}) async =>
            BookAnalysisResult(
              words: const [],
              grammar: [
                GrammarHit(
                  patternId: 'g_can',
                  nameDe: 'Ability',
                  matchedText: '을 수 있어요',
                  level: 'A1',
                  explanationDe: 'Meaning $targetLang',
                ),
              ],
              sentences: const [],
              warnings: const ['offline_stub'],
              analysisLanguage: targetLang,
            ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
