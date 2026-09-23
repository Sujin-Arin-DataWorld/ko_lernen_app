import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/services/kkeunmari_dictionary_service.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_deck_source.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'support/sori_speech_stubs.dart';

KkeunmariWord word(String text) => KkeunmariWord(
  word: text,
  first: text[0],
  last: text[text.length - 1],
  level: 'A1',
  german: text,
  topic: 'test',
  nextCount: 99,
  isDeadEnd: false,
);

VocabDeckSource source(List<String> words) => VocabDeckSource(
  packId: 'my-pack',
  words: [
    for (final text in words)
      ExtractedWord.manual(
        korean: text,
        translationDe: 'Mein $text',
        translationEn: 'My $text',
      ),
  ],
);

Future<void> pump(WidgetTester tester, Widget screen, String language) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: screen,
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    KkeunmariEngine.reset();
    SharedPreferences.setMockInitialValues({'kl_tut_kkeunmari': true});
    await Storage.init();
  });
  tearDown(KkeunmariEngine.reset);

  for (final lang in ['de', 'en']) {
    testWidgets(
      '$lang empty, disconnected and unverified selections never start or award',
      (tester) async {
        final normal = [word('학교'), word('교실'), word('실내')];
        KkeunmariEngine.setPoolForTesting(normal);
        for (final selected in <List<String>>[
          [],
          ['학교'],
          ['학교', '나무'],
          ['뢔뷁', '뷁뢔'],
        ]) {
          await pump(tester, KkeunmariScreen(source: source(selected)), lang);
          expect(find.byType(SoriEmptyState), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(
            find.byKey(const ValueKey('kkeunmari-gameplay')),
            findsNothing,
          );
          await tester.pump(const Duration(seconds: 35));
          expect(Storage.xp, 0);
          expect(Storage.kkeunmariWins, 0);
          expect(KkeunmariEngine.pool, normal);
          expect(tester.takeException(), isNull);
          await dispose(tester);
        }
      },
    );

    testWidgets(
      '$lang selection rejects outside answers without dictionary fallback and plays valid reply',
      (tester) async {
        var dictionaryCalls = 0;
        final normal = [word('학교'), word('교실'), word('교수'), word('실내')];
        KkeunmariEngine.setPoolForTesting(normal);
        await pump(
          tester,
          KkeunmariScreen(
            source: source(['학교', '교실']),
            dictionaryValidator: (_) async {
              dictionaryCalls++;
              return const KkeunmariDictionaryResult(
                KkeunmariDictionaryStatus.valid,
              );
            },
          ),
          lang,
        );
        expect(find.text('학교'), findsOneWidget);
        final input = find.byType(TextField);
        await tester.ensureVisible(input);
        await tester.enterText(input, '교수');
        tester.widget<TextField>(input).onSubmitted!('교수');
        await tester.pump();
        final t = AppL10n.of(tester.element(input));
        expect(find.text(t.kkeunmariNotInSelection), findsOneWidget);
        expect(dictionaryCalls, 0);
        expect(Storage.xp, 0);
        await tester.enterText(input, '교실');
        tester.widget<TextField>(input).onSubmitted!('교실');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text(t.kkeunmariNotInSelection), findsNothing);
        expect(Storage.gameBest('kkeunmari'), 2);
        expect(Storage.kkeunmariWins, 1);
        expect(KkeunmariEngine.pool, normal);
        expect(dictionaryCalls, 0);
        expect(tester.takeException(), isNull);
        await dispose(tester);
      },
    );
  }

  testWidgets(
    'failed dictionary loading can retry the same selection without changing global pool',
    (tester) async {
      var calls = 0;
      final normal = [word('나무'), word('무지개')];
      KkeunmariEngine.setPoolForTesting(normal);
      await pump(
        tester,
        KkeunmariScreen(
          source: source(['학교', '교실']),
          poolLoader: () async {
            calls++;
            if (calls == 1) {
              throw StateError('unavailable');
            }
            return [word('학교'), word('교실')];
          },
        ),
        'en',
      );
      expect(find.byType(AppError), findsOneWidget);
      final retry = find.widgetWithText(SoriButton, 'Try again');
      if (retry.evaluate().isNotEmpty) {
        tester.widget<SoriButton>(retry).onTap!();
      } else {
        tester.widget<AppError>(find.byType(AppError)).onRetry!();
      }
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(calls, 2);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('학교'), findsOneWidget);
      expect(KkeunmariEngine.pool, normal);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );
}
