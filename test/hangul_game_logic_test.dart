import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart'
    show HintMode, buildPattern, fullyRevealedByChosungVowel;
import 'package:ko_lernen_app/services/hangul_util.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hangul utilities', () {
    test('extractChosung returns initial consonants only', () {
      expect(extractChosung('안녕하세요'), 'ㅇㄴㅎㅅㅇ');
      expect(extractChosung('한국 말'), 'ㅎㄱ ㅁ');
      expect(extractChosung('K-pop 한국어!'), ' ㅎㄱㅇ');
    });

    // 2026-08-12 전수조사: 전 음절 무받침 단어 196/930(A1 62/211)는 초성+모음
    // 힌트가 정답 전체를 노출했다(모르다 → ㅁㅗ ㄹㅡ ㄷㅏ). 쉬움 모드에서도
    // 그런 단어는 초성으로 강등되어야 한다 — 회귀 고정.
    test('Anlaut-Hinweis darf die Antwort nie vollständig zeigen', () {
      expect(fullyRevealedByChosungVowel('모르다'), isTrue);
      expect(fullyRevealedByChosungVowel('나라'), isTrue);
      expect(fullyRevealedByChosungVowel('한국'), isFalse);

      // 무받침 → 쉬움 모드에서도 초성만.
      expect(buildPattern('모르다', HintMode.chosungVowel), 'ㅁ ㄹ ㄷ');
      expect(buildPattern('나라', HintMode.chosungVowel), 'ㄴ ㄹ');

      // 받침이 있으면 쉬움 모드 유지(모음 공개, 받침은 숨김).
      expect(buildPattern('한국', HintMode.chosungVowel), 'ㅎㅏ ㄱㅜ');
      expect(buildPattern('안녕', HintMode.chosungVowel), 'ㅇㅏ ㄴㅕ');

      // hard 모드는 언제나 초성만.
      expect(buildPattern('모르다', HintMode.chosung), 'ㅁ ㄹ ㄷ');
    });

    test('hangulLength and isPureHangul classify learner input', () {
      expect(hangulLength('한국어'), 3);
      expect(hangulLength('한국어 101!'), 3);
      expect(isPureHangul('한국어'), isTrue);
      expect(isPureHangul('한국어!'), isFalse);
      expect(isPureHangul(''), isFalse);
    });
  });

  group('Kkeunmari engine', () {
    setUp(() => KkeunmariEngine.reset());

    test('loads pool and picks a fair starting word', () async {
      final pool = await KkeunmariEngine.load();
      expect(pool.length, greaterThanOrEqualTo(200));

      final start = KkeunmariEngine.pickStart();
      expect(start.word, isNotEmpty);
      expect(start.isDeadEnd, isFalse);
      expect(start.nextCount, greaterThanOrEqualTo(2));
    });

    test(
      'validates user words by pool membership, start syllable, and reuse',
      () async {
        await KkeunmariEngine.load();

        final start = KkeunmariEngine.pickStart();
        final next = KkeunmariEngine.pickTigerNext(start.last, {start.word});
        expect(next, isNotNull);

        final ok = KkeunmariEngine.validateUserWord(next!.word, next.first, {
          start.word,
        });
        expect(ok.$1, isTrue);
        expect(ok.$2, 'ok');
        expect(ok.$3?.word, next.word);

        final wrongRequiredFirst = [
          '가',
          '나',
          '다',
          '라',
        ].firstWhere((syllable) => syllable != next.first);
        final wrongStart = KkeunmariEngine.validateUserWord(
          next.word,
          wrongRequiredFirst,
          {start.word},
        );
        expect(wrongStart.$1, isFalse);
        expect(wrongStart.$2, 'wrong_start');

        final reused = KkeunmariEngine.validateUserWord(next.word, next.first, {
          start.word,
          next.word,
        });
        expect(reused.$1, isFalse);
        expect(reused.$2, 'already_used');

        // Engine v2 (2026-05-29, kkeunmari_engine.dart:110): validation
        // priority is wrong_start → not_in_pool, weil wrong_start die
        // hilfreichere Lern-Korrektur ist. Daher muss das "missing"-Wort
        // mit der RICHTIGEN Anfangssilbe beginnen, damit not_in_pool
        // tatsächlich erreicht wird. Sonst fängt wrong_start ab.
        // Verifiziert per Python: alle 471 möglichen first-syllables des
        // pools → '${first}없는단어' kollidiert nie mit dem Pool.
        final missing = KkeunmariEngine.validateUserWord(
          '${next.first}없는단어',
          next.first,
          {start.word},
        );
        expect(missing.$1, isFalse);
        expect(missing.$2, 'not_in_pool');
      },
    );

    test('creates a safe temporary word after dictionary verification', () {
      final word = KkeunmariWord.dictionary('\uC81C\uC0AC');

      expect(word.word, '\uC81C\uC0AC');
      expect(word.first, '\uC81C');
      expect(word.last, '\uC0AC');
      expect(word.isDeadEnd, isFalse);
    });
  });
}
