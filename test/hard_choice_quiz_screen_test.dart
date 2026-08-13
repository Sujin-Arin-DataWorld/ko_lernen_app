// 어려운 철자 퀴즈 — 뜻 프롬프트 + 정답 한국어와 자모 하나 다른 비단어 보기
// (2026-08-13 테스터 피드백 ④: "was heißt machen? 할다/허다/하다/하가").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

Vocab _v(String ko, String de) => Vocab(
  id: 'hc_$ko',
  korean: ko,
  romanization: ko,
  german: de,
  level: 'A1',
  posDe: 'Verb',
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
      home: HardChoiceQuizScreen(deck: deck, vocabLoader: () async => deck),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('renders translation prompt + 4 options incl. the correct one', (
    tester,
  ) async {
    await _pump(tester, [_v('하다', 'machen')]);

    expect(find.text('machen'), findsOneWidget);
    final choices = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .toList();
    expect(choices, hasLength(4));
    expect(choices.where((c) => c.isCorrect), hasLength(1));
    expect(choices.where((c) => c.text == '하다'), hasLength(1));
    // 오답은 전부 원본과 다른 비단어 변이.
    for (final c in choices.where((c) => !c.isCorrect)) {
      expect(c.text, isNot('하다'));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong tap reveals, counts the miss, and finishes the round', (
    tester,
  ) async {
    await _pump(tester, [_v('하다', 'machen')]);

    final wrong = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((c) => !c.isCorrect);
    wrong.onSelected!();
    await tester.pump();
    expect(Storage.wrongCountOf('하다'), 1);

    // 850ms 딜레이 후 완료 뷰.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.hardQuizDoneTitle), findsOneWidget);
    expect(find.text(t.hardQuizScore(0, 1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('correct tap scores and completes', (tester) async {
    await _pump(tester, [_v('하다', 'machen')]);

    final correct = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((c) => c.isCorrect);
    correct.onSelected!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));

    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.hardQuizScore(1, 1)), findsOneWidget);
    expect(Storage.wrongCountOf('하다'), 0);
    expect(tester.takeException(), isNull);
  });
}
