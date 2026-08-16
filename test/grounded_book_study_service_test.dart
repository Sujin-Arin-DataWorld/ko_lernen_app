import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/grounded_book_study_service.dart';

void main() {
  const futureGrammar = GrammarHit(
    patternId: 'g_attribute_future',
    nameDe: 'Zukünftige Attributivform',
    matchedText: '먹을',
    level: 'A2',
    explanationDe: '-(으)ㄹ beschreibt hier eine zukünftige Handlung.',
    sourceUnitId: 'unit:2',
  );
  const presentGrammar = GrammarHit(
    patternId: 'g_attribute_present',
    nameDe: 'Gegenwärtige Attributivform',
    matchedText: '먹는',
    level: 'A2',
    explanationDe: '-는 beschreibt hier eine gegenwärtige Handlung.',
    sourceUnitId: 'unit:3',
  );
  const result = BookAnalysisResult(
    words: <ExtractedWord>[
      ExtractedWord(
        korean: '학교',
        romanization: '',
        posDe: 'Nomen',
        translationDe: 'Schule',
        translationEn: '',
        exampleKorean: '오늘은 학교에 가요.',
        exampleDe: 'UNTRUSTED WORD EXAMPLE TRANSLATION',
        sourceUnitId: 'unit:0',
        savedToPackId: null,
      ),
      ExtractedWord(
        korean: '음식',
        romanization: '',
        posDe: 'Nomen',
        translationDe: 'Essen',
        translationEn: '',
        exampleKorean: '저는 내일 먹을 음식을 준비해요.',
        exampleDe: 'Ich bereite Essen für morgen vor.',
        sourceUnitId: 'unit:2',
        savedToPackId: null,
      ),
    ],
    expressions: <ExtractedExpression>[
      ExtractedExpression(
        korean: '마음이 와닿아요',
        translationDe: 'es berührt mich',
        translationEn: '',
        translationLanguage: 'de',
        sourceUnitId: 'unit:1',
      ),
    ],
    grammar: <GrammarHit>[futureGrammar, presentGrammar],
    sentences: <TranslatedSentence>[
      TranslatedSentence(
        korean: '오늘은 학교에 가요.',
        translationDe: 'Heute gehe ich zur Schule.',
        sourceUnitId: 'unit:0',
      ),
      TranslatedSentence(
        korean: '저는 학교에서 한국어를 공부해요.',
        translationDe: 'Ich lerne Koreanisch in der Schule.',
        sourceUnitId: 'unit:0',
      ),
      TranslatedSentence(
        korean: '그 노래는 마음이 와닿아요.',
        translationDe: 'Das Lied berührt mich.',
        sourceUnitId: 'unit:1',
      ),
      TranslatedSentence(
        korean: '저는 내일 먹을 음식을 준비해요.',
        translationDe: 'Ich bereite Essen für morgen vor.',
        sourceUnitId: 'unit:2',
      ),
      TranslatedSentence(
        korean: '우리는 먹을 음식을 골라요.',
        translationDe: 'Wir wählen Essen aus.',
        sourceUnitId: 'unit:2',
      ),
      TranslatedSentence(
        korean: '지금 먹는 음식은 비빔밥이에요.',
        translationDe: 'Das Essen, das ich jetzt esse, ist Bibimbap.',
        sourceUnitId: 'unit:3',
      ),
    ],
    warnings: <String>[],
  );

  test('each grammar target exposes all four grounded intents', () {
    for (final grammar in result.grammar) {
      final target = GroundedBookTarget.forGrammar(grammar);
      final questions = GroundedBookStudyService.questionsForTarget(
        result,
        target,
      );

      expect(
        questions.map((question) => question.kind),
        <GroundedBookQuestionKind>[
          GroundedBookQuestionKind.explainForm,
          GroundedBookQuestionKind.showExample,
          GroundedBookQuestionKind.compare,
          GroundedBookQuestionKind.quiz,
        ],
      );
      expect(
        questions.every((question) => question.target.matches(target)),
        isTrue,
      );
    }
  });

  test(
    'grammar answers use only exact explanation, examples and comparison',
    () {
      final questions = GroundedBookStudyService.questionsForTarget(
        result,
        GroundedBookTarget.forGrammar(futureGrammar),
      );
      final answers = questions
          .map((question) => GroundedBookStudyService.answer(result, question))
          .toList(growable: false);

      expect(answers.every((answer) => answer.isSupported), isTrue);
      expect(answers[0].facts!.koreanEvidence, '먹을');
      expect(
        answers[0].facts!.explanation,
        contains('-(으)ㄹ beschreibt hier eine zukünftige Handlung.'),
      );
      expect(answers[1].facts!.koreanEvidence, '저는 내일 먹을 음식을 준비해요.');
      expect(answers[2].facts!.koreanEvidence, '먹을 ↔ 먹는');
      expect(answers[2].facts!.sourceUnitIds, <String>['unit:2', 'unit:3']);
      expect(answers[3].facts!.quizPromptEvidence, '저는 내일 _____ 음식을 준비해요.');
      expect(answers[3].facts!.quizAnswer, '먹을');
    },
  );

  test('unrelated grammar is not presented as a similar comparison', () {
    const unrelated = GrammarHit(
      patternId: 'g_reason',
      nameDe: 'Reason',
      matchedText: '먹어서',
      level: 'A2',
      explanationDe: '-아서/어서 gives a reason.',
      sourceUnitId: 'unit:9',
    );
    const unrelatedResult = BookAnalysisResult(
      words: <ExtractedWord>[],
      grammar: <GrammarHit>[futureGrammar, unrelated],
      sentences: <TranslatedSentence>[],
      warnings: <String>[],
    );
    final comparison =
        GroundedBookStudyService.questionsForTarget(
          unrelatedResult,
          GroundedBookTarget.forGrammar(futureGrammar),
        ).singleWhere(
          (question) => question.kind == GroundedBookQuestionKind.compare,
        );

    expect(
      GroundedBookStudyService.answer(unrelatedResult, comparison).status,
      GroundedBookAnswerStatus.unsupported,
    );
  });

  test('word, expression and sentence expose only appropriate intents', () {
    final wordQuestions = GroundedBookStudyService.questionsForTarget(
      result,
      GroundedBookTarget.forWord(result.words.first),
    );
    final expressionQuestions = GroundedBookStudyService.questionsForTarget(
      result,
      GroundedBookTarget.forExpression(result.expressions.single),
    );
    final sentenceQuestions = GroundedBookStudyService.questionsForTarget(
      result,
      GroundedBookTarget.forSentence(result.sentences[3]),
    );

    expect(
      wordQuestions.map((question) => question.kind),
      <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.quiz,
      ],
    );
    expect(
      expressionQuestions.map((question) => question.kind),
      <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.quiz,
      ],
    );
    expect(
      sentenceQuestions.map((question) => question.kind),
      <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.grammarInSentence,
        GroundedBookQuestionKind.quiz,
      ],
    );
    for (final question in <GroundedBookQuestion>[
      ...wordQuestions,
      ...expressionQuestions,
      ...sentenceQuestions,
    ]) {
      expect(
        GroundedBookStudyService.answer(result, question).isSupported,
        isTrue,
      );
    }
  });

  test('word example uses only a matching translated sentence', () {
    final exampleQuestion =
        GroundedBookStudyService.questionsForTarget(
          result,
          GroundedBookTarget.forWord(result.words.first),
        ).singleWhere(
          (question) => question.kind == GroundedBookQuestionKind.showExample,
        );

    final answer = GroundedBookStudyService.answer(result, exampleQuestion);

    expect(answer.isSupported, isTrue);
    expect(answer.facts!.koreanEvidence, '오늘은 학교에 가요.');
    expect(answer.facts!.explanation, 'Heute gehe ich zur Schule.');
    expect(
      answer.facts!.explanation,
      isNot(contains('UNTRUSTED WORD EXAMPLE TRANSLATION')),
    );
    expect(answer.facts!.sourceUnitIds, contains('unit:0'));
  });

  test('unverified word example falls back to an actual page sentence', () {
    const fallbackWord = ExtractedWord(
      korean: '학교',
      romanization: '',
      posDe: 'Nomen',
      translationDe: 'Schule',
      translationEn: '',
      exampleKorean: '이 문장은 페이지에 없어요.',
      exampleDe: 'UNTRUSTED',
      sourceUnitId: 'unit:0',
      savedToPackId: null,
    );
    const fallbackResult = BookAnalysisResult(
      words: <ExtractedWord>[fallbackWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[
        TranslatedSentence(
          korean: '다른 단에서 학교를 발견했어요.',
          translationDe: 'Die Schule wurde in einer anderen Spalte gefunden.',
          sourceUnitId: 'unit:7',
        ),
      ],
      warnings: <String>[],
    );
    final exampleQuestion =
        GroundedBookStudyService.questionsForTarget(
          fallbackResult,
          GroundedBookTarget.forWord(fallbackWord),
        ).singleWhere(
          (question) => question.kind == GroundedBookQuestionKind.showExample,
        );

    final answer = GroundedBookStudyService.answer(
      fallbackResult,
      exampleQuestion,
    );

    expect(answer.isSupported, isTrue);
    expect(answer.facts!.koreanEvidence, '다른 단에서 학교를 발견했어요.');
    expect(
      answer.facts!.explanation,
      'Die Schule wurde in einer anderen Spalte gefunden.',
    );
    expect(answer.facts!.sourceUnitIds, contains('unit:7'));
  });

  test('word example must contain the target word', () {
    const targetWord = ExtractedWord(
      korean: '학교',
      romanization: '',
      posDe: 'Nomen',
      translationDe: 'Schule',
      translationEn: '',
      exampleKorean: '오늘은 공원에 가요.',
      exampleDe: 'UNTRUSTED',
      sourceUnitId: 'unit:0',
      savedToPackId: null,
    );
    const pageResult = BookAnalysisResult(
      words: <ExtractedWord>[targetWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[
        TranslatedSentence(
          korean: '오늘은 공원에 가요.',
          translationDe: 'Heute gehe ich in den Park.',
          sourceUnitId: 'unit:0',
        ),
        TranslatedSentence(
          korean: '학교에서 공부해요.',
          translationDe: 'Ich lerne in der Schule.',
          sourceUnitId: 'unit:1',
        ),
      ],
      warnings: <String>[],
    );
    final question =
        GroundedBookStudyService.questionsForTarget(
          pageResult,
          GroundedBookTarget.forWord(targetWord),
        ).singleWhere(
          (candidate) => candidate.kind == GroundedBookQuestionKind.showExample,
        );

    final answer = GroundedBookStudyService.answer(pageResult, question);

    expect(answer.isSupported, isTrue);
    expect(answer.facts!.koreanEvidence, '학교에서 공부해요.');
    expect(answer.facts!.explanation, 'Ich lerne in der Schule.');
    expect(answer.facts!.sourceUnitIds, <String>['unit:0', 'unit:1']);
  });

  test('legacy target without provenance keeps questions but no facts', () {
    const legacyWord = ExtractedWord(
      korean: '학교',
      romanization: '',
      posDe: 'Nomen',
      translationDe: 'Schule',
      translationEn: '',
      exampleKorean: '',
      exampleDe: '',
      sourceUnitId: '',
      savedToPackId: null,
    );
    const offline = BookAnalysisResult(
      words: <ExtractedWord>[legacyWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[],
      warnings: <String>['offline_stub'],
    );

    final questions = GroundedBookStudyService.questionsForTarget(
      offline,
      GroundedBookTarget.forWord(legacyWord),
    );

    expect(offline.isSaveable, isTrue);
    expect(
      questions.map((question) => question.kind),
      <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.quiz,
      ],
    );
    for (final question in questions) {
      final answer = GroundedBookStudyService.answer(offline, question);
      expect(answer.status, GroundedBookAnswerStatus.unsupported);
      expect(answer.facts, isNull);
    }
  });

  test('missing evidence returns an explicit unsupported answer', () {
    const sparseGrammar = GrammarHit(
      patternId: 'g_sparse',
      nameDe: '',
      matchedText: '먹을',
      level: 'A2',
      explanationDe: '',
      sourceUnitId: 'unit:8',
    );
    const sparse = BookAnalysisResult(
      words: <ExtractedWord>[],
      grammar: <GrammarHit>[sparseGrammar],
      sentences: <TranslatedSentence>[
        TranslatedSentence(
          korean: '내일 먹을 음식을 준비해요.',
          translationDe: 'Ich bereite Essen vor.',
        ),
      ],
      warnings: <String>[],
    );
    final questions = GroundedBookStudyService.questionsForTarget(
      sparse,
      GroundedBookTarget.forGrammar(sparseGrammar),
    );

    expect(questions, hasLength(4));
    for (final question in questions) {
      final answer = GroundedBookStudyService.answer(sparse, question);
      expect(answer.status, GroundedBookAnswerStatus.unsupported);
      expect(answer.facts, isNull);
    }
  });

  test('meaningful contaminated analysis cannot open any target', () {
    final contaminated = BookAnalysisResult(
      words: result.words,
      grammar: result.grammar,
      sentences: result.sentences,
      expressions: result.expressions,
      warnings: const <String>['invalid_response_filtered'],
    );
    final target = GroundedBookTarget.forWord(result.words.first);
    final forged = GroundedBookQuestion(
      id: 'forged',
      kind: GroundedBookQuestionKind.meaning,
      target: target,
    );

    expect(
      GroundedBookStudyService.questionsForTarget(contaminated, target),
      isEmpty,
    );
    expect(
      GroundedBookStudyService.answer(contaminated, forged).status,
      GroundedBookAnswerStatus.unsupported,
    );
  });

  test(
    'forged item key, source or intent fails canonical provenance checks',
    () {
      final canonical = GroundedBookStudyService.questionsForTarget(
        result,
        GroundedBookTarget.forGrammar(futureGrammar),
      ).first;
      final forgedTargets = <GroundedBookTarget>[
        GroundedBookTarget(
          type: canonical.target.type,
          itemKey: 'forged',
          sourceUnitId: canonical.target.sourceUnitId,
        ),
        GroundedBookTarget(
          type: canonical.target.type,
          itemKey: canonical.target.itemKey,
          sourceUnitId: 'unit:999',
        ),
      ];

      for (final target in forgedTargets) {
        final forged = GroundedBookQuestion(
          id: canonical.id,
          kind: canonical.kind,
          target: target,
        );
        expect(
          GroundedBookStudyService.answer(result, forged).status,
          GroundedBookAnswerStatus.unsupported,
        );
      }
      final wrongIntent = GroundedBookQuestion(
        id: canonical.id,
        kind: GroundedBookQuestionKind.meaning,
        target: canonical.target,
      );
      expect(
        GroundedBookStudyService.answer(result, wrongIntent).status,
        GroundedBookAnswerStatus.unsupported,
      );
    },
  );

  test('additional example is exact evidence from the same page', () {
    final question = GroundedBookStudyService.questionsForTarget(
      result,
      GroundedBookTarget.forSentence(result.sentences.first),
    ).first;
    final facts = GroundedBookStudyService.answer(result, question).facts!;

    expect(facts.additionalExample, '저는 학교에서 한국어를 공부해요.');
    expect(
      result.sentences.map((sentence) => sentence.korean),
      contains(facts.additionalExample),
    );
    expect(facts.sourceUnitIds, contains('unit:0'));
  });

  test('answer language follows result and item provenance', () {
    const englishWord = ExtractedWord(
      korean: '학교',
      romanization: '',
      posDe: 'Noun',
      translationDe: 'legacy primary slot',
      translationEn: 'school',
      translationLanguage: 'en',
      exampleKorean: '',
      exampleDe: '',
      sourceUnitId: 'unit:5',
      savedToPackId: null,
    );
    const english = BookAnalysisResult(
      words: <ExtractedWord>[englishWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[],
      warnings: <String>[],
      analysisLanguage: 'en',
    );
    final target = GroundedBookTarget.forWord(englishWord);
    final meaning = GroundedBookStudyService.questionsForTarget(
      english,
      target,
    ).first;

    expect(
      GroundedBookStudyService.answer(english, meaning).facts!.explanation,
      'school',
    );

    const mismatched = BookAnalysisResult(
      words: <ExtractedWord>[englishWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[],
      warnings: <String>[],
      analysisLanguage: 'de',
    );
    expect(
      GroundedBookStudyService.answer(mismatched, meaning).status,
      GroundedBookAnswerStatus.unsupported,
    );
  });
}
