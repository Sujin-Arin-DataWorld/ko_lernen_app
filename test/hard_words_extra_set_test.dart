// Extra-Lernset — 어려운 단어 화면이 SRS leech ∪ 명시적 오답 3회+ 의
// 합집합을 보여주고, 두 연습 CTA(집중 복습 + 어려운 철자 퀴즈)를 노출한다
// (2026-08-13 테스터 피드백 ③).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

Vocab _v(String ko) => Vocab(
  id: 'hw_$ko',
  korean: ko,
  romanization: ko,
  german: 'de-$ko',
  level: 'B2',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

Future<void> _pump(WidgetTester tester, List<Vocab> deck) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: HardWordsScreen(deckLoader: () async => deck),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('hardWords');
  });

  testWidgets(
    'word with 3 explicit misses appears without being an SRS leech',
    (tester) async {
      // leech 조건(리뷰 3회+)은 전혀 만족하지 않는 신선한 단어.
      for (var i = 0; i < 3; i++) {
        await Storage.incrementWrongCount('양극화');
      }
      expect(Storage.hardIds(['양극화']), isEmpty);

      await _pump(tester, [_v('양극화'), _v('멀쩡한단어')]);
      final t = await AppL10n.delegate.load(const Locale('de'));

      expect(find.text('양극화'), findsOneWidget);
      expect(find.text('멀쩡한단어'), findsNothing);
      // 두 CTA 모두 노출 — 철자 퀴즈(신규) + 집중 복습(기존).
      expect(find.text(t.hardWordsHardQuizCta), findsOneWidget);
      expect(find.text(t.hardWordsStudyCta), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty state when nothing is hard', (tester) async {
    await _pump(tester, [_v('멀쩡한단어')]);
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.hardWordsEmptyTitle), findsOneWidget);
    expect(find.text(t.hardWordsHardQuizCta), findsNothing);
  });
}
