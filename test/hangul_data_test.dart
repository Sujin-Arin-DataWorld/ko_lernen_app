import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_data.dart';

void main() {
  group('speakableJamo', () {
    test('turns consonants into pronounceable eu syllables', () {
      expect(speakableJamo('ㄱ'), '그');
      expect(speakableJamo('ㅉ'), '쯔');
      expect(speakableJamo('ㅎ'), '흐');
    });

    test('turns vowels into pronounceable silent-ieung syllables', () {
      expect(speakableJamo('ㅓ'), '어');
      expect(speakableJamo('ㅣ'), '이');
    });

    test('uses stable carrier words for device-mispronounced jamo', () {
      expect(speakableJamo('ㅃ'), '빵');
      expect(speakableJamo('ㄷ'), '다리');
      expect(speakableJamo('ㅏ'), '아빠');
      expect(speakableJamo('ㅠ'), '유리');
      expect(speakableJamo('ㅢ'), '의자');
    });

    test('leaves complete syllables and other input unchanged', () {
      expect(speakableJamo('한'), '한');
      expect(speakableJamo(''), '');
    });
  });
}
