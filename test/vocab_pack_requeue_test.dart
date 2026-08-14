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
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

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

/// Learn 하단 판정은 이제 대형 텍스트 CTA 가 아니라 DeckActionBar 의
/// 미니 아이콘 버튼이다 (Sori Deck 2.0). 키로 찾아 핸들러를 직접 호출한다 —
/// 탭 좌표는 테스트 뷰포트의 코치 오버레이에 가려 불안정하다.
void _tapDeckAction(WidgetTester tester, String name) {
  tester
      .widget<SoriPressable>(
        find.descendant(
          of: find.byKey(deckActionKey(name)),
          matching: find.byType(SoriPressable),
        ),
      )
      .onTap!();
}

Future<void> _revealCurrentLearnCard(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _revealAndTapDeckAction(WidgetTester tester, String name) async {
  await _revealCurrentLearnCard(tester);
  _tapDeckAction(tester, name);
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
    // Sori Deck 2.0 의 의도된 변경: 플립 전 판정 버튼은 **죽은 버튼이 아니라**
    // 비활성 표시 + 탭 시 "먼저 뒤집으세요" 힌트다. 계약의 본질은 라벨이나
    // onTap 이 null 인지가 아니라 **판정이 기록되지 않는 것**이므로 그걸 단언한다.
    final bar = tester.widget<DeckActionBar>(find.byType(DeckActionBar));
    expect(
      bar.judgmentEnabled,
      isFalse,
      reason: 'Learn actions stay unavailable until the gloss is revealed',
    );
    _tapDeckAction(tester, 'dontknow');
    await _settle(tester);
    expect(find.text('재단어1'), findsOneWidget, reason: '플립 전 판정은 전진시키지 않는다');
    expect(Storage.wrongCountOf('재단어1'), 0, reason: '플립 전 판정은 기록되지 않는다');

    // 단어1 뜻을 확인한 뒤 몰라요 → 분자 유지, 단어2 서빙.
    await _revealAndTapDeckAction(tester, 'dontknow');
    await _settle(tester);
    expect(find.text('재단어2'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(Storage.wrongCountOf('재단어1'), 1);

    // 단어2·3 알아요 → 단어1이 다시 나온다.
    await _revealAndTapDeckAction(tester, 'know');
    await _settle(tester);
    expect(find.text('재단어3'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);

    await _revealAndTapDeckAction(tester, 'know');
    await _settle(tester);
    // Current-pack Boss word is intentionally taught before either assessment.
    expect(find.text('재단어4'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);

    await _revealAndTapDeckAction(tester, 'know');
    await _settle(tester);
    expect(find.text('재단어1'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);

    // 재출제에서 알아요 → Learn 종료, 퀴즈 진입 (Learn 버튼 소멸).
    await _revealAndTapDeckAction(tester, 'know');
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
      _tapDeckAction(tester, 'know');
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
      await _revealAndTapDeckAction(tester, 'dontknow');
      await _settle(tester);
    }

    // 졸업 → Learn 종료 (퀴즈 스테이지로 전환).
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(Storage.wrongCountOf('재단어1'), 3);
    expect(tester.takeException(), isNull);
  });
}
