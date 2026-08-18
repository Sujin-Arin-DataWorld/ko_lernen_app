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

    // 2026-08-18: 예전엔 이 5글자가 예시어 전체(빵·다리·아빠·유리·의자)를
    // 읽었다. 테스터(Amor)가 "낱자를 누르면 순수 음가가 아니라 예시어가
    // 나온다"고 짚어 예외 없이 일반 규칙(자음+ㅡ · ㅇ+모음)으로 되돌렸다.
    // 1음절 계약 자체는 test/jamo_speech_test.dart 가 40자 전수로 지킨다.
    test('previously mispronounced jamo now use plain single syllables', () {
      expect(speakableJamo('ㅃ'), '쁘');
      expect(speakableJamo('ㄷ'), '드');
      expect(speakableJamo('ㅏ'), '아');
      expect(speakableJamo('ㅠ'), '유');
      expect(speakableJamo('ㅢ'), '의');
    });

    test('leaves complete syllables and other input unchanged', () {
      expect(speakableJamo('한'), '한');
      expect(speakableJamo(''), '');
    });
  });
}
