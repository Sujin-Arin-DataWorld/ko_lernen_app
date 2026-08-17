import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_corpus_resolver.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';

void main() {
  const cloze = <ClozeItem>[
    ClozeItem(
      id: 'c1',
      level: 'a1',
      sentenceKo: '나는 ＿＿＿에 가요.',
      answer: '학교',
      fullKo: '나는 학교에 가요.',
      de: 'Ich gehe zur Schule.',
      en: 'I go to school.',
      distractors: <String>['집', '가게'],
    ),
    ClozeItem(
      id: 'c2',
      level: 'a2',
      sentenceKo: '지금 ＿＿＿해요.',
      answer: '공부',
      fullKo: '지금 공부해요.',
      de: 'Ich lerne jetzt.',
      en: 'I am studying now.',
      distractors: <String>['운동', '요리'],
    ),
  ];

  const satz = <SatzSentence>[
    SatzSentence(
      id: 's1',
      level: 'a1',
      targetKo: '학교에 가요.',
      promptDe: 'Ich gehe zur Schule.',
      promptEn: 'I go to school.',
      distractors: <String>['집에'],
      vocabKo: '학교',
    ),
  ];

  const vocab = <Vocab>[
    Vocab(
      korean: '학교',
      romanization: 'hakgyo',
      german: 'Schule',
      level: 'a1',
      posDe: 'Nomen',
      exampleKorean: '학교에 가요.',
      exampleGerman: 'Ich gehe zur Schule.',
      topic: 'school',
    ),
  ];

  test('keeps only curated items for the chosen notebook words', () {
    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['학교', '사과'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
    );

    expect(match.cloze.map((item) => item.answer), <String>['학교']);
    expect(match.satz.map((item) => item.vocabKo), <String>['학교']);
    expect(match.vocab.map((item) => item.korean), <String>['학교']);
  });

  test('does not invent sentences for unknown notebook words', () {
    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['번데기'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
    );

    expect(match.cloze, isEmpty);
    expect(match.satz, isEmpty);
    expect(match.vocab, isEmpty);
  });

  test('matches a 하다 notebook headword to the bare curated stem', () {
    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['공부하다'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
    );

    expect(match.cloze.single.answer, '공부');
  });

  test('restricts a packed match when the learner drops a word', () {
    final all = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['학교', '공부하다'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
    );

    expect(all.cloze, hasLength(2));
    expect(all.restrictTo(<String>['학교']).cloze.single.answer, '학교');
  });

  test('falls back to the notebook gloss for speed and chosung', () {
    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['번데기'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
      fallbackWords: <ExtractedWord>[
        ExtractedWord.manual(korean: '번데기', translationDe: 'Puppe'),
      ],
    );

    expect(match.cloze, isEmpty);
    expect(match.vocab.single.korean, '번데기');
    expect(match.vocab.single.german, 'Puppe');
    expect(match.chosung.single.korean, '번데기');
  });

  test('chosung drops notebook leftovers that are not Hangul-only', () {
    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['학교', 'TV'],
      cloze: cloze,
      satz: satz,
      vocab: <Vocab>[
        ...vocab,
        const Vocab(
          korean: 'TV',
          romanization: 'tibi',
          german: 'Fernseher',
          level: 'a1',
          posDe: 'Nomen',
          exampleKorean: '',
          exampleGerman: '',
          topic: 'media',
        ),
      ],
    );

    expect(match.vocab.map((item) => item.korean), <String>['학교', 'TV']);
    expect(match.chosung.map((item) => item.korean), <String>['학교']);
  });
}
