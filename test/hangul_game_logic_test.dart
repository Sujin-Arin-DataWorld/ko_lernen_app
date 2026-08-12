import 'package:flutter_test/flutter_test.dart';
// 초성 힌트가 정답을 노출하지 않는다는 회귀는 chosung_hint_test.dart 로 옮겼다.
// 그쪽은 계획·위젯 렌더링·번들 어휘 전수조사까지 본다 — 여기 있던 문자열
// 패턴 검사는 화면이 쓰지 않는 경로였고, 그래서 실제 노출 버그를 못 잡았다.
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

    test('decomposeHangulSyllable splits a syllable into cho/jung/jong', () {
      expect(decomposeHangulSyllable('한'.runes.first), ('ㅎ', 'ㅏ', 'ㄴ'));
      expect(decomposeHangulSyllable('더'.runes.first), ('ㄷ', 'ㅓ', ''));
      expect(decomposeHangulSyllable('꽃'.runes.first), ('ㄲ', 'ㅗ', 'ㅊ'));
      expect(decomposeHangulSyllable('K'.runes.first), isNull);
      expect(decomposeHangulSyllable('ㄱ'.runes.first), isNull); // 낱자는 음절 아님
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
