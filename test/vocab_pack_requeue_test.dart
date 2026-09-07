// Learn → Quiz 전환 통합. 모든 팩 카드를 한 번씩 확인하면 `몰라요`가
// 재삽입한 카드가 있더라도 n / n에서 멈추지 않고 평가로 넘어간다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

import 'helpers/deck_actions.dart';
import 'support/sori_speech_stubs.dart';

Vocab _word(int n, {bool boss = false}) => Vocab(
  id: 'rq_v$n',
  korean: '재단어$n',
  romanization: 'jaedaneo$n',
  german: 'RQ-GER-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_rq_1',
  packOrder: n,
  isReviewBoss: boss,
);

Future<AppL10n> _pump(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => [pack],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

void _tapButton(WidgetTester tester, String label) {
  tapDeckAction(tester, label);
}

Future<void> _revealCurrentLearnCard(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _revealAndTapButton(WidgetTester tester, String label) async {
  await _revealCurrentLearnCard(tester);
  _tapButton(tester, label);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    stubSoriSpeech();
  });

  testWidgets('real Alltag 8-card pack opens Quiz after exactly eight cards', (
    tester,
  ) async {
    final pack = await tester.runAsync(
      () => VocabPackService.findById('a2_daily_1'),
    );
    expect(pack, isNotNull);
    expect(pack!.total, 8);
    final t = await _pump(tester, pack);

    for (var index = 0; index < pack.total; index++) {
      await _revealAndTapButton(
        tester,
        index == 0 ? t.vocabPackDontKnow : t.vocabPackGotIt,
      );
      await _settle(tester);
    }

    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(find.text(t.vocabPackQuizHint), findsOneWidget);
    expect(find.byType(QuizChoice), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown word does not hold the screen at n / n', (tester) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3), _word(4, boss: true)],
    );
    final t = await _pump(tester, pack);

    expect(find.text('재단어1'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    // §P2-3: 판정 버튼은 뜻 공개 전에는 힌트 훅만 발동한다 — 탭해도 판정
    // 기록 0 + 같은 카드 유지 (게이트의 행동 단언, 옛 onTap==null 단언 대체).
    _tapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);
    expect(find.text('재단어1'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      Storage.wrongCountOf('재단어1'),
      0,
      reason: 'Learn judgments stay unavailable until the gloss is revealed',
    );

    // 단어1 뜻을 확인한 뒤 몰라요 → 처음 보는 단어2가 서빙되므로 분자 증가.
    await _revealAndTapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);
    expect(find.text('재단어2'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(Storage.wrongCountOf('재단어1'), 1);

    // 단어2·3 알아요 → 단어1이 다시 나온다.
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    expect(find.text('재단어3'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);

    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    // Current-pack Boss word is intentionally taught before either assessment.
    expect(find.text('재단어4'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);

    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    // 네 고유 카드를 모두 한 번 확인한 즉시 Learn 종료, 퀴즈 진입.
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(find.text(t.vocabPackQuizHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every Boss word reveals its gloss before assessment begins', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1), _word(2, boss: true), _word(3, boss: true)],
    );
    final t = await _pump(tester, pack);

    for (final word in pack.learnWords) {
      expect(find.text(word.korean), findsOneWidget);
      expect(find.text(word.german), findsNothing);
      await _revealCurrentLearnCard(tester);
      expect(
        find.text(word.german),
        findsOneWidget,
        reason: '${word.korean} must be taught in Learn before assessment',
      );
      _tapButton(tester, t.vocabPackGotIt);
      await _settle(tester);
    }

    expect(find.text(t.vocabPackQuizHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-card pack enters assessment after its first answer', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1, boss: true)],
    );
    final t = await _pump(tester, pack);

    expect(find.text('재단어1'), findsOneWidget);
    await _revealAndTapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);

    // 첫 패스 완료 → Learn 종료 (Boss 평가로 전환).
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(Storage.wrongCountOf('재단어1'), 1);
    expect(tester.takeException(), isNull);
  });
}
