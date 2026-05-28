import 'package:flutter_test/flutter_test.dart';
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

        final missing = KkeunmariEngine.validateUserWord('없는단어', next.first, {
          start.word,
        });
        expect(missing.$1, isFalse);
        expect(missing.$2, 'not_in_pool');
      },
    );
  });
}
