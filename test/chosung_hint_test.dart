// 초성 퀴즈 힌트 — "정답이 화면에 통째로 보이면 안 된다"는 단 하나의 불변식을
// 세 겹으로 고정한다.
//   ① 계획(plan) 단위: 규칙 자체
//   ② 위젯 단위: 화면이 그 계획을 실제로 따르는가 (2026-08-12 회귀의 진짜 구멍)
//   ③ 전수조사: 지금 번들된 어휘 전부 × 모든 모드
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/widgets/sori/chosung_hint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 전 음절 무받침 = 초성+모음 힌트가 곧 정답인 단어들.
  // '더'는 Jin이 실기기에서 잡은 실제 사례(A1, "mehr").
  const fullyRevealing = ['더', '모르다', '나라', '아빠', '어머니', '주다'];

  // 받침이 하나라도 있으면 쉬움 모드를 유지해도 정답이 안 드러난다.
  const safeInEasyMode = ['한국', '안녕', '사람', '학생'];

  group('ChosungHintPlan', () {
    test('무받침 단어는 쉬움 모드를 요청해도 초성으로 강등된다', () {
      for (final word in fullyRevealing) {
        final plan = buildChosungHintPlan(word, HintMode.chosungVowel);
        expect(plan.revealsAnswer, isFalse, reason: word);
        expect(plan.effectiveMode, HintMode.chosung, reason: word);
        expect(plan.wasDowngraded, isTrue, reason: word);
      }
    });

    test('받침이 있으면 쉬움 모드가 그대로 유지된다', () {
      for (final word in safeInEasyMode) {
        final plan = buildChosungHintPlan(word, HintMode.chosungVowel);
        expect(plan.revealsAnswer, isFalse, reason: word);
        expect(plan.effectiveMode, HintMode.chosungVowel, reason: word);
        expect(plan.wasDowngraded, isFalse, reason: word);
      }
    });

    test('어려움 모드는 언제나 초성만 — 강등도 노출도 없다', () {
      for (final word in [...fullyRevealing, ...safeInEasyMode]) {
        final plan = buildChosungHintPlan(word, HintMode.chosung);
        expect(plan.revealsAnswer, isFalse, reason: word);
        expect(plan.effectiveMode, HintMode.chosung, reason: word);
      }
    });

    test('음절 분해는 hangul_util 의 테이블을 그대로 따른다', () {
      final plan = buildChosungHintPlan('한국', HintMode.chosungVowel);
      final syllables = plan.units.whereType<ChosungHintSyllable>().toList();
      expect(syllables.length, 2);
      expect(
        syllables.map((s) => (s.chosung, s.jungsung, s.jongsung)),
        [('ㅎ', 'ㅏ', 'ㄴ'), ('ㄱ', 'ㅜ', 'ㄱ')],
      );
      expect(syllables.every((s) => s.hasJongsung), isTrue);
    });

    test('한글이 아닌 글자는 그대로 통과하고 노출 판정 대상이 아니다', () {
      final plan = buildChosungHintPlan('K-pop', HintMode.chosungVowel);
      expect(plan.units.whereType<ChosungHintLiteral>().length, 5);
      expect(plan.revealsAnswer, isFalse);
    });

    test('빈 문자열은 노출 판정 대상이 아니다', () {
      final plan = buildChosungHintPlan('', HintMode.chosungVowel);
      expect(plan.units, isEmpty);
      expect(plan.revealsAnswer, isFalse);
      expect(plan.wasDowngraded, isFalse);
    });
  });

  group('ChosungHint 위젯 — 화면이 계획을 실제로 따르는가', () {
    Future<void> pump(WidgetTester tester, String word, HintMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChosungHint(word: word, mode: mode, accent: Colors.teal),
            ),
          ),
        ),
      );
    }

    // ⛔ 이 테스트가 2026-08-12 회귀의 핵심이다. 규칙은 buildPattern 에만 있었고
    // 화면은 mode 를 날것으로 읽어 '더' → ㄷ + ㅓ 를 그렸다.
    testWidgets('무받침 단어의 모음은 쉬움 모드에서도 화면에 없다', (tester) async {
      await pump(tester, '더', HintMode.chosungVowel);
      expect(find.text('ㄷ'), findsOneWidget);
      expect(find.text('ㅓ'), findsNothing);
      expect(find.text('모음'), findsOneWidget);
      expect(find.text('받침'), findsNothing);
    });

    testWidgets('무받침 다음절도 전부 모음이 가려진다', (tester) async {
      await pump(tester, '모르다', HintMode.chosungVowel);
      for (final vowel in ['ㅗ', 'ㅡ', 'ㅏ']) {
        expect(find.text(vowel), findsNothing, reason: vowel);
      }
      expect(find.text('모음'), findsNWidgets(3));
    });

    testWidgets('받침 있는 단어는 쉬움 모드에서 모음을 보여준다', (tester) async {
      await pump(tester, '한국', HintMode.chosungVowel);
      expect(find.text('ㅎ'), findsOneWidget);
      expect(find.text('ㅏ'), findsOneWidget);
      expect(find.text('ㅜ'), findsOneWidget);
      expect(find.text('받침'), findsNWidgets(2));
      expect(find.text('모음'), findsNothing);
      // 받침 자모(ㄴ/ㄱ)는 화면에 절대 없다.
      expect(find.text('ㄴ'), findsNothing);
    });

    testWidgets('어려움 모드는 모음을 절대 그리지 않는다', (tester) async {
      await pump(tester, '한국', HintMode.chosung);
      expect(find.text('모음'), findsNWidgets(2));
      expect(find.text('받침'), findsNWidgets(2));
      expect(find.text('ㅏ'), findsNothing);
      expect(find.text('ㅜ'), findsNothing);
    });

    testWidgets('한글이 아닌 글자는 그대로 표시된다', (tester) async {
      await pump(tester, 'K-pop', HintMode.chosungVowel);
      for (final ch in ['K', '-', 'p', 'o']) {
        expect(find.text(ch), findsWidgets, reason: ch);
      }
    });
  });

  group('번들 어휘 전수조사', () {
    test('korean_vocab.csv 의 모든 단어 × 모든 모드에서 정답이 노출되지 않는다', () async {
      final vocab = await DataLoader.loadVocab();
      expect(
        vocab.length,
        greaterThan(500),
        reason: '어휘 CSV 로드 실패 시 조용히 통과하지 않도록 하한선을 둔다',
      );

      final leaks = <String>[];
      for (final entry in vocab) {
        for (final mode in HintMode.values) {
          if (buildChosungHintPlan(entry.korean, mode).revealsAnswer) {
            leaks.add('${entry.korean} (${entry.level}, $mode)');
          }
        }
      }
      expect(leaks, isEmpty, reason: '힌트가 정답을 통째로 노출하는 단어: $leaks');
    });

    test('무받침 단어가 실제로 존재해야 전수조사가 의미를 갖는다', () async {
      final vocab = await DataLoader.loadVocab();
      final downgraded = vocab
          .where(
            (v) => buildChosungHintPlan(
              v.korean,
              HintMode.chosungVowel,
            ).wasDowngraded,
          )
          .length;
      // 2026-08-12 전수조사 기준 196개. 0이면 위 테스트가 빈 케이스를 도는 셈.
      expect(downgraded, greaterThan(50));
    });
  });
}
