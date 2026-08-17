import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
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

  test('finds existing smalltalk and pronunciation sentences by stem', () {
    const smalltalk = <SmalltalkPhrase>[
      SmalltalkPhrase(
        id: 'st1',
        category: 'school',
        level: 'a1',
        kind: 'opener',
        ko: '오늘 학교에 가요.',
        de: 'Ich gehe heute zur Schule.',
        en: 'I go to school today.',
      ),
      SmalltalkPhrase(
        id: 'st2',
        category: 'food',
        level: 'a1',
        kind: 'opener',
        ko: '배고파요.',
        de: 'Ich habe Hunger.',
        en: 'I am hungry.',
      ),
    ];
    const pronunciation = <PronunciationPhrase>[
      PronunciationPhrase(
        id: 'pronunciation_a1_0001',
        level: LearnerLevel.a1,
        ko: '지금 공부해요.',
        de: 'Ich lerne jetzt.',
        en: 'I am studying now.',
        focus: '받침',
      ),
    ];

    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['학교', '공부하다'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
      smalltalk: smalltalk,
      pronunciation: pronunciation,
    );

    expect(match.smalltalk.single.id, 'st1');
    expect(match.pronunciation.single.ko, '지금 공부해요.');
    expect(
      CustomPackCorpusResolver.occursIn('안녕하세요', <String>['이']),
      isFalse,
    );
  });

  test('keeps scenarios and word-web clusters that already name the word', () {
    const scenario = Scenario(
      id: 'sc-school',
      level: LearnerLevel.a1,
      emoji: '🏫',
      register: Register.polite,
      title: LocalizedText(ko: '학교', de: 'Schule', en: 'School'),
      intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
      vocab: <VocabRef>[VocabRef(korean: '학교')],
      grammarIds: <String>[],
      dialog: <DialogLine>[
        DialogLine(speaker: 'a', ko: '안녕', de: 'Hallo', en: 'Hi'),
      ],
      quests: <QuestSpec>[],
    );
    const other = Scenario(
      id: 'sc-food',
      level: LearnerLevel.a1,
      emoji: '🍜',
      register: Register.polite,
      title: LocalizedText(ko: '밥', de: 'Essen', en: 'Food'),
      intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
      vocab: <VocabRef>[VocabRef(korean: '밥')],
      grammarIds: <String>[],
      dialog: <DialogLine>[
        DialogLine(speaker: 'a', ko: '밥 먹어요', de: 'Essen', en: 'Eat'),
      ],
      quests: <QuestSpec>[],
    );
    const wordWeb = <WordRelationCluster>[
      WordRelationCluster(
        id: 'ww-school',
        sourceKo: '학교',
        sourceVocabId: '학교',
        level: 'a1',
        synonyms: <WordNeighbor>[
          WordNeighbor(ko: '학원', de: 'Akademie', en: 'academy'),
        ],
      ),
    ];

    final match = CustomPackCorpusResolver.resolve(
      koreanHeadwords: <String>['학교'],
      cloze: cloze,
      satz: satz,
      vocab: vocab,
      scenarios: <Scenario>[scenario, other],
      wordWeb: wordWeb,
    );

    expect(match.scenarios.single.id, 'sc-school');
    expect(match.wordWeb.single.sourceKo, '학교');
    expect(match.hasCuratedItems, isTrue);
  });
}
