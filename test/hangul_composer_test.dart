import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hangul_composer.dart';

/// 자모를 순서대로 눌렀을 때의 최종 텍스트.
String typed(String jamos) {
  final c = HangulComposer();
  for (final r in jamos.runes) {
    c.addJamo(String.fromCharCode(r));
  }
  return c.text;
}

HangulComposer after(String jamos) {
  final c = HangulComposer();
  for (final r in jamos.runes) {
    c.addJamo(String.fromCharCode(r));
  }
  return c;
}

void main() {
  group('조합 — 화면 자판이 정답을 만들 수 있어야 한다', () {
    // 2026-08-12 회귀 방지: 예전 자판은 자모를 이어붙이기만 해서 "ㅅㅏㄱㅘ" 가
    // 됐고, 채점이 `답 == "사과"` 라 어떤 조합으로도 정답이 안 나왔다.
    test('사과 — 받침 없는 2음절 + 겹모음', () {
      expect(typed('ㅅㅏㄱㅘ'), '사과');
      expect(typed('ㅅㅏㄱㅗㅏ'), '사과', reason: 'ㅗ+ㅏ 를 눌러도 ㅘ 로 합쳐져야 한다');
    });

    test('사장 — Jin 이 틀렸다고 신고한 A2 단어', () {
      expect(typed('ㅅㅏㅈㅏㅇ'), '사장');
    });

    test('받침이 다음 음절 초성으로 넘어간다', () {
      expect(typed('ㅁㅏㄴㅏ'), '마나');
      expect(typed('ㅎㅏㄴㄱㅜㄱ'), '한국');
    });

    test('겹받침', () {
      expect(typed('ㄱㅏㅂㅅ'), '값');
      expect(typed('ㅇㅏㄴㅈ'), '앉');
      expect(typed('ㄷㅏㄹㄱ'), '닭');
    });

    test('겹받침 뒤에 모음이 오면 뒷자만 넘어간다', () {
      expect(typed('ㅇㅏㄴㅈㅏ'), '안자');
      expect(typed('ㄱㅏㅂㅅㅣ'), '갑시');
    });

    test('ㄸ·ㅃ·ㅉ 은 받침이 못 되므로 새 음절을 연다', () {
      expect(typed('ㄱㅏㄸㅏ'), '가따');
      expect(typed('ㅇㅏㅃㅏ'), '아빠');
    });

    test('홀자음·홀모음도 그대로 남는다', () {
      expect(typed('ㄱ'), 'ㄱ');
      expect(typed('ㅏ'), 'ㅏ');
      expect(typed('ㄱㄴ'), 'ㄱㄴ');
      expect(typed('ㅏㅓ'), 'ㅏㅓ');
    });

    test('모든 겹모음', () {
      expect(typed('ㅇㅗㅏ'), '와');
      expect(typed('ㅇㅗㅐ'), '왜');
      expect(typed('ㅇㅗㅣ'), '외');
      expect(typed('ㅇㅜㅓ'), '워');
      expect(typed('ㅇㅜㅔ'), '웨');
      expect(typed('ㅇㅜㅣ'), '위');
      expect(typed('ㅇㅡㅣ'), '의');
    });
  });

  group('backspace — 시스템 IME 와 같은 감각', () {
    test('조합 중인 음절을 자모 단위로 되돌린다', () {
      final c = after('ㄱㅘㄴ'); // 관
      expect(c.text, '관');
      c.backspace();
      expect(c.text, '과');
      c.backspace();
      expect(c.text, '고', reason: '겹모음 ㅘ 는 ㅗ 로 되돌아간다');
      c.backspace();
      expect(c.text, 'ㄱ');
      c.backspace();
      expect(c.text, '');
      c.backspace();
      expect(c.text, '', reason: '빈 상태에서 더 지워도 안전해야 한다');
    });

    test('겹받침은 한 단계씩 풀린다', () {
      final c = after('ㄱㅏㅂㅅ'); // 값
      c.backspace();
      expect(c.text, '갑');
      c.backspace();
      expect(c.text, '가');
    });

    test('확정된 앞 음절도 자모 단위로 지워진다', () {
      final c = after('ㅅㅏㄱㅘ'); // 사과
      c.backspace();
      expect(c.text, '사고');
      c.backspace();
      expect(c.text, '사ㄱ');
      c.backspace();
      expect(c.text, '사');
      c.backspace();
      expect(c.text, 'ㅅ');
    });
  });

  group('외부 입력과의 동기화', () {
    test('resetTo 는 조합 상태를 버리고 주어진 텍스트를 확정으로 삼는다', () {
      final c = HangulComposer();
      c.addJamo('ㅅ');
      c.addJamo('ㅏ');
      expect(c.text, '사');
      c.resetTo('바나나');
      expect(c.text, '바나나');
      c.addJamo('ㅅ');
      expect(c.text, '바나나ㅅ', reason: '이어 입력은 확정본 뒤에 붙는다');
    });

    test('clear', () {
      final c = HangulComposer()..addJamo('ㄱ');
      c.clear();
      expect(c.text, '');
      expect(c.isEmpty, isTrue);
    });

    test('한글이 아닌 문자는 그대로 붙는다', () {
      final c = HangulComposer();
      c.addJamo('ㄱ');
      c.addJamo('ㅏ');
      c.addJamo('!');
      expect(c.text, '가!');
    });
  });
}
