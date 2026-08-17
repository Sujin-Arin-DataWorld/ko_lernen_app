import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/hanja_lexicon.dart';

void main() {
  test('looks up Sino-Korean words and their synonym group', () {
    final start = HanjaLexicon.lookup('시작');
    final commence = HanjaLexicon.lookup('개시');

    expect(start?.hanja, '始作');
    expect(commence?.hanja, '開始');
    expect(start?.synonymGroup, commence?.synonymGroup);
    expect(start?.isFormal, isFalse);
    expect(commence?.isFormal, isTrue);
    expect(HanjaLexicon.groupmates(start!), hasLength(2));
  });

  test('strips 하다 when looking up a verb card', () {
    expect(HanjaLexicon.lookup('사용하다')?.korean, '사용');
  });

  test('native everyday words stay playable without invented Hanja', () {
    final house = HanjaLexicon.lookup('집');
    expect(house, isNotNull);
    expect(house!.hanja, isEmpty);
    expect(house.synonymGroup, 'home');
  });
}
