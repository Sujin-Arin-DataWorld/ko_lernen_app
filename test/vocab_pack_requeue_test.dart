// Learn 단계 재출제 통합 — "몰라요" 단어는 같은 세션에서 다시 나오고,
// 진행 칩 분모는 고정이며, 3회 실패는 졸업 후 퀴즈로 넘어간다
// (2026-08-13 테스터 피드백 ②).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'helpers/deck_actions.dart';

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
  });

  testWidgets('unknown word is re-served and Boss words are learned first', (
    tester,
  ) async {
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
    expect(find.text('재단어1'), findsOneWidget);
    // 재단어1은 세션 초반 "몰라요"로 이미 한 번 서빙된 재출제 카드라
    // "+1 Wdh." 접미사가 병기된다 (지시서 1.1 / T2 카운터).
    expect(find.text('4 / 4 · +1 Wdh.'), findsOneWidget);

    // 재출제에서 알아요 → Learn 종료, 퀴즈 진입 (Learn 버튼 소멸).
    await _revealAndTapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    expect(find.text(t.vocabPackDontKnow), findsNothing);
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

  testWidgets('3rd miss graduates the word and the stage still finishes', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1, boss: true)],
    );
    final t = await _pump(tester, pack);

    for (var i = 0; i < 3; i++) {
      expect(find.text('재단어1'), findsOneWidget);
      await _revealAndTapButton(tester, t.vocabPackDontKnow);
      await _settle(tester);
    }

    // 졸업 → Learn 종료 (퀴즈 스테이지로 전환).
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(Storage.wrongCountOf('재단어1'), 3);
    expect(tester.takeException(), isNull);
  });
}
