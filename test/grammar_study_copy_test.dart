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
    expect(copy.speakKorean, '갔어요. 먹었어요. 했어요.');
  });

  test('keeps a single example unsliced', () {
    expect(splitStudyPhrases('어렵더라도 포기하지 마세요.'), [
      '어렵더라도 포기하지 마세요.',
    ]);
  });
}
