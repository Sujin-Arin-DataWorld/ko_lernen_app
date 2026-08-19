import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/grammar_study_copy.dart';

void main() {
  test('splits polite past into title, three rules, three examples', () {
    const grammar = Grammar(
      pattern: 'V-았/었어요',
      level: 'A1',
      typeDe: 'Höfliche Vergangenheit',
      explanationDe:
          'Höfliche Vergangenheitsform. ㅏ/ㅗ → 았어요 · Sonst → 었어요 · 하다 → 했어요',
      exampleKorean: '갔어요. / 먹었어요. / 했어요.',
      exampleGerman: 'Ich bin gegangen. / Ich habe gegessen. / Ich habe gemacht.',
      note: '하다 → 했어요',
      typeEn: 'Polite past',
      explanationEn:
          'Polite past tense. ㅏ/ㅗ → 았어요 · otherwise → 었어요 · 하다 → 했어요',
      exampleEn: 'I went. / I ate. / I did.',
      noteEn: '하다 → 했어요',
    );

    final copy = GrammarStudyCopy.fromGrammar(grammar, 'en');
    expect(copy.title, 'Polite past tense.');
    expect(copy.rules, [
      'ㅏ/ㅗ → 았어요',
      'otherwise → 었어요',
      '하다 → 했어요',
    ]);
    expect(copy.examples.map((e) => e.korean), [
      '갔어요.',
      '먹었어요.',
      '했어요.',
    ]);
    expect(copy.examples.map((e) => e.gloss), [
      'I went.',
      'I ate.',
      'I did.',
    ]);
    expect(copy.note, isEmpty);
    // 스피커는 **화면에 보이는 예문 하나**만 읽는다. 예전에는 셋을 공백으로
    // 이어 붙여 읽었는데, (a) 앞면은 첫 예문만 보여주므로 보는 것과 듣는
    // 것이 달랐고 (b) 그 이어붙인 문자열은 Storage 에 없었다 — 사전생성기는
    // CSV 원본('… / … / …')을 합성하는데 앱은 공백 join 을 요청해서 sha1 이
    // 어긋났다. 2026-08-19 --verify-storage 의 유일한 누락이 이 문자열이다.
    expect(copy.speakKorean, '갔어요.');
    expect(copy.speakKoreanAt(1), '먹었어요.');
    expect(copy.speakKoreanAt(2), '했어요.');
    expect(copy.speakKoreanAt(3), '', reason: '범위 밖은 무음');
    for (var i = 0; i < copy.examples.length; i++) {
      expect(
        copy.speakKoreanAt(i),
        copy.examples[i].korean,
        reason: '발화 문자열은 언제나 splitStudyPhrases 의 원소여야 한다',
      );
    }
  });

  test('keeps a single example unsliced', () {
    expect(splitStudyPhrases('어렵더라도 포기하지 마세요.'), [
      '어렵더라도 포기하지 마세요.',
    ]);
  });
}
