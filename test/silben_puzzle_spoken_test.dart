import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';

void main() {
  SilbenWord word(String answer, String exampleKo) => SilbenWord(
    dir: 'h', row: 0, col: 0, answer: answer,
    german: '', exampleKo: exampleKo, exampleDe: '',
  );

  test('◯ 런을 정답으로 복원한다', () {
    expect(word('다섯', '◯◯ 명이 왔어요.').exampleKoSpoken, '다섯 명이 왔어요.');
  });
  test('정답이 두 번 나와도 전부 복원한다', () {
    expect(word('눈', '◯이 오면 ◯사람을 만들어요.').exampleKoSpoken,
        '눈이 오면 눈사람을 만들어요.');
  });
  test('예문이 없으면 빈 문자열', () {
    expect(word('다섯', '').exampleKoSpoken, '');
  });
}
