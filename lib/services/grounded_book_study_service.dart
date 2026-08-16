import '../models/book_page.dart';

enum GroundedBookTargetType { word, expression, grammar, sentence }

class GroundedBookTarget {
  const GroundedBookTarget({
    required this.type,
    required this.itemKey,
    required this.sourceUnitId,
  });

  factory GroundedBookTarget.forWord(ExtractedWord word) => GroundedBookTarget(
    type: GroundedBookTargetType.word,
    itemKey: word.korean,
    sourceUnitId: word.sourceUnitId,
  );

  factory GroundedBookTarget.forExpression(ExtractedExpression expression) =>
      GroundedBookTarget(
        type: GroundedBookTargetType.expression,
        itemKey: expression.korean,
        sourceUnitId: expression.sourceUnitId,
      );

  factory GroundedBookTarget.forGrammar(
    GrammarHit grammar,
  ) => GroundedBookTarget(
    type: GroundedBookTargetType.grammar,
    itemKey:
        '${grammar.patternId.length}:${grammar.patternId}${grammar.matchedText}',
    sourceUnitId: grammar.sourceUnitId,
  );

  factory GroundedBookTarget.forSentence(TranslatedSentence sentence) =>
      GroundedBookTarget(
        type: GroundedBookTargetType.sentence,
        itemKey: sentence.korean,
        sourceUnitId: sentence.sourceUnitId,
      );

  final GroundedBookTargetType type;
  final String itemKey;
  final String sourceUnitId;

  bool matches(GroundedBookTarget other) =>
      type == other.type &&
      itemKey == other.itemKey &&
      sourceUnitId == other.sourceUnitId;
}

enum GroundedBookQuestionKind {
  explainForm,
  showExample,
  compare,
  quiz,
  meaning,
  grammarInSentence,
}

class GroundedBookQuestion {
  const GroundedBookQuestion({
    required this.id,
    required this.kind,
    required this.target,
  });

  final String id;
  final GroundedBookQuestionKind kind;
  final GroundedBookTarget target;
}

class GroundedBookFactPayload {
  GroundedBookFactPayload({
    required this.koreanEvidence,
    required this.explanation,
    required Iterable<String> sourceUnitIds,
    this.additionalExample = '',
    this.quizPromptEvidence = '',
    this.quizAnswer = '',
  }) : sourceUnitIds = List<String>.unmodifiable(
         sourceUnitIds.where((source) => source.isNotEmpty).toSet(),
       );

  final String koreanEvidence;
  final String explanation;
  final List<String> sourceUnitIds;
  final String additionalExample;
  final String quizPromptEvidence;
  final String quizAnswer;
}

enum GroundedBookAnswerStatus { supported, unsupported }

class GroundedBookAnswer {
  const GroundedBookAnswer._({
    required this.question,
    required this.status,
    this.facts,
  });

  factory GroundedBookAnswer.supported(
    GroundedBookQuestion question,
    GroundedBookFactPayload facts,
  ) => GroundedBookAnswer._(
    question: question,
    status: GroundedBookAnswerStatus.supported,
    facts: facts,
  );

  factory GroundedBookAnswer.unsupported(GroundedBookQuestion question) =>
      GroundedBookAnswer._(
        question: question,
        status: GroundedBookAnswerStatus.unsupported,
      );

  final GroundedBookQuestion question;
  final GroundedBookAnswerStatus status;
  final GroundedBookFactPayload? facts;

  bool get isSupported =>
      status == GroundedBookAnswerStatus.supported && facts != null;
}

typedef _VerifiedExample = ({
  String korean,
  String explanation,
  String sourceUnitId,
});

/// Produces one persona-independent fact payload from validated page evidence.
/// Taego and Joy may present this payload differently, but cannot alter it.
class GroundedBookStudyService {
  const GroundedBookStudyService._();

  static const List<Set<String>> _comparableGrammarFamilies = <Set<String>>[
    <String>{'g_progressive', 'g_progressive_past'},
    <String>{'g_reason', 'g_reason_nikka'},
    <String>{'g_future_will', 'g_future_kkeyo', 'g_future_kkayo'},
    <String>{'g_can', 'g_cannot'},
    <String>{'g_neg_an', 'g_neg_ji_anhda'},
    <String>{'g_attribute_present', 'g_attribute_past', 'g_attribute_future'},
    <String>{'g_conditional', 'g_conditional_seasonal'},
    <String>{'g_to_e', 'g_to_eseo'},
  ];

  static List<GroundedBookQuestion> questionsForTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) {
    if (!result.isSaveable) {
      return const <GroundedBookQuestion>[];
    }
    final canonical = _canonicalTarget(result, target);
    if (canonical == null) {
      return const <GroundedBookQuestion>[];
    }
    final kinds = switch (canonical.type) {
      GroundedBookTargetType.grammar => const <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.explainForm,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.compare,
        GroundedBookQuestionKind.quiz,
      ],
      GroundedBookTargetType.word => const <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.quiz,
      ],
      GroundedBookTargetType.expression => const <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.showExample,
        GroundedBookQuestionKind.quiz,
      ],
      GroundedBookTargetType.sentence => const <GroundedBookQuestionKind>[
        GroundedBookQuestionKind.meaning,
        GroundedBookQuestionKind.grammarInSentence,
        GroundedBookQuestionKind.quiz,
      ],
    };
    return kinds
        .map((kind) => _questionFor(canonical, kind))
        .toList(growable: false);
  }

  static GroundedBookAnswer answer(
    BookAnalysisResult result,
    GroundedBookQuestion question,
  ) {
    if (!result.isSaveable) {
      return GroundedBookAnswer.unsupported(question);
    }
    final canonical = _firstWhereOrNull(
      questionsForTarget(result, question.target),
      (candidate) =>
          candidate.id == question.id &&
          candidate.kind == question.kind &&
          candidate.target.matches(question.target),
    );
    if (canonical == null) {
      return GroundedBookAnswer.unsupported(question);
    }
    if (canonical.target.sourceUnitId.isEmpty) {
      return GroundedBookAnswer.unsupported(canonical);
    }
    final facts = switch (canonical.target.type) {
      GroundedBookTargetType.word => _wordFacts(result, canonical),
      GroundedBookTargetType.expression => _expressionFacts(result, canonical),
      GroundedBookTargetType.grammar => _grammarFacts(result, canonical),
      GroundedBookTargetType.sentence => _sentenceFacts(result, canonical),
    };
    return facts == null
        ? GroundedBookAnswer.unsupported(canonical)
        : GroundedBookAnswer.supported(canonical, facts);
  }

  static GroundedBookQuestion _questionFor(
    GroundedBookTarget target,
    GroundedBookQuestionKind kind,
  ) => GroundedBookQuestion(
    id: '${target.type.name}|${target.sourceUnitId}|${target.itemKey}|${kind.name}',
    kind: kind,
    target: target,
  );

  static GroundedBookTarget? _canonicalTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) {
    if (target.itemKey.isEmpty) {
      return null;
    }
    final candidates = switch (target.type) {
      GroundedBookTargetType.word => result.words.map(
        GroundedBookTarget.forWord,
      ),
      GroundedBookTargetType.expression => result.expressions.map(
        GroundedBookTarget.forExpression,
      ),
      GroundedBookTargetType.grammar => result.grammar.map(
        GroundedBookTarget.forGrammar,
      ),
      GroundedBookTargetType.sentence => result.sentences.map(
        GroundedBookTarget.forSentence,
      ),
    };
    return _firstWhereOrNull(
      candidates,
      (candidate) => candidate.matches(target),
    );
  }

  static GroundedBookFactPayload? _wordFacts(
    BookAnalysisResult result,
    GroundedBookQuestion question,
  ) {
    final word = _wordForTarget(result, question.target);
    if (word == null) {
      return null;
    }
    final meaning = _wordMeaning(result, word);
    final example = _wordExample(result, word);
    final additional = example == null
        ? null
        : _additionalSentence(
            result,
            excludedKorean: example.korean,
            containing: word.korean,
          );
    final sources = <String>[
      word.sourceUnitId,
      if (example != null) example.sourceUnitId,
    ];
    return switch (question.kind) {
      GroundedBookQuestionKind.meaning when meaning.isNotEmpty =>
        GroundedBookFactPayload(
          koreanEvidence: word.korean,
          explanation: meaning,
          sourceUnitIds: sources,
          additionalExample: example?.korean ?? '',
        ),
      GroundedBookQuestionKind.showExample when example != null =>
        GroundedBookFactPayload(
          koreanEvidence: example.korean,
          explanation: example.explanation.isNotEmpty
              ? example.explanation
              : meaning,
          sourceUnitIds: <String>[
            ...sources,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
        ),
      GroundedBookQuestionKind.quiz when meaning.isNotEmpty =>
        GroundedBookFactPayload(
          koreanEvidence: word.korean,
          explanation: meaning,
          sourceUnitIds: sources,
          additionalExample: example?.korean ?? '',
          quizPromptEvidence: meaning,
          quizAnswer: word.korean,
        ),
      _ => null,
    };
  }

  static GroundedBookFactPayload? _expressionFacts(
    BookAnalysisResult result,
    GroundedBookQuestion question,
  ) {
    final expression = _expressionForTarget(result, question.target);
    if (expression == null) {
      return null;
    }
    final meaning = _expressionMeaning(result, expression);
    final example = _sentenceExample(
      result,
      sourceUnitId: expression.sourceUnitId,
      containing: expression.korean,
    );
    final additional = example == null
        ? null
        : _additionalSentence(
            result,
            excludedKorean: example.korean,
            containing: expression.korean,
          );
    final sources = <String>[
      expression.sourceUnitId,
      if (example != null) example.sourceUnitId,
    ];
    return switch (question.kind) {
      GroundedBookQuestionKind.meaning when meaning.isNotEmpty =>
        GroundedBookFactPayload(
          koreanEvidence: expression.korean,
          explanation: meaning,
          sourceUnitIds: sources,
          additionalExample: example?.korean ?? '',
        ),
      GroundedBookQuestionKind.showExample when example != null =>
        GroundedBookFactPayload(
          koreanEvidence: example.korean,
          explanation: example.explanation.isNotEmpty
              ? example.explanation
              : meaning,
          sourceUnitIds: <String>[
            ...sources,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
        ),
      GroundedBookQuestionKind.quiz when meaning.isNotEmpty =>
        GroundedBookFactPayload(
          koreanEvidence: expression.korean,
          explanation: meaning,
          sourceUnitIds: sources,
          additionalExample: example?.korean ?? '',
          quizPromptEvidence: meaning,
          quizAnswer: expression.korean,
        ),
      _ => null,
    };
  }

  static GroundedBookFactPayload? _grammarFacts(
    BookAnalysisResult result,
    GroundedBookQuestion question,
  ) {
    final grammar = _grammarForTarget(result, question.target);
    if (grammar == null) {
      return null;
    }
    final explanation = _grammarExplanation(result, grammar);
    final example = _sentenceExample(
      result,
      sourceUnitId: grammar.sourceUnitId,
      containing: grammar.matchedText,
    );
    switch (question.kind) {
      case GroundedBookQuestionKind.explainForm:
        if (explanation.isEmpty) {
          return null;
        }
        return GroundedBookFactPayload(
          koreanEvidence: grammar.matchedText,
          explanation: explanation,
          sourceUnitIds: <String>[
            grammar.sourceUnitId,
            if (example != null) example.sourceUnitId,
          ],
          additionalExample: example?.korean ?? '',
        );
      case GroundedBookQuestionKind.showExample:
        if (example == null) {
          return null;
        }
        final additional = _additionalSentence(
          result,
          excludedKorean: example.korean,
          containing: grammar.matchedText,
        );
        return GroundedBookFactPayload(
          koreanEvidence: example.korean,
          explanation: explanation,
          sourceUnitIds: <String>[
            grammar.sourceUnitId,
            example.sourceUnitId,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
        );
      case GroundedBookQuestionKind.compare:
        final comparison = _firstWhereOrNull(
          result.grammar,
          (candidate) =>
              candidate.sourceUnitId.isNotEmpty &&
              !GroundedBookTarget.forGrammar(
                candidate,
              ).matches(question.target) &&
              _areComparableGrammarPatterns(
                grammar.patternId,
                candidate.patternId,
              ) &&
              _grammarExplanation(result, candidate).isNotEmpty,
        );
        if (comparison == null || explanation.isEmpty) {
          return null;
        }
        final comparisonExample = _sentenceExample(
          result,
          sourceUnitId: comparison.sourceUnitId,
          containing: comparison.matchedText,
        );
        return GroundedBookFactPayload(
          koreanEvidence: '${grammar.matchedText} ↔ ${comparison.matchedText}',
          explanation:
              '$explanation\n\n${_grammarExplanation(result, comparison)}',
          sourceUnitIds: <String>[
            grammar.sourceUnitId,
            comparison.sourceUnitId,
            if (comparisonExample != null) comparisonExample.sourceUnitId,
          ],
          additionalExample: comparisonExample?.korean ?? '',
        );
      case GroundedBookQuestionKind.quiz:
        if (example == null || grammar.matchedText.isEmpty) {
          return null;
        }
        final additional = _additionalSentence(
          result,
          excludedKorean: example.korean,
          containing: grammar.matchedText,
        );
        return GroundedBookFactPayload(
          koreanEvidence: example.korean,
          explanation: explanation,
          sourceUnitIds: <String>[
            grammar.sourceUnitId,
            example.sourceUnitId,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
          quizPromptEvidence: example.korean.replaceFirst(
            grammar.matchedText,
            '_____',
          ),
          quizAnswer: grammar.matchedText,
        );
      case GroundedBookQuestionKind.meaning:
      case GroundedBookQuestionKind.grammarInSentence:
        return null;
    }
  }

  static GroundedBookFactPayload? _sentenceFacts(
    BookAnalysisResult result,
    GroundedBookQuestion question,
  ) {
    final sentence = _sentenceForTarget(result, question.target);
    if (sentence == null) {
      return null;
    }
    final additional = _additionalSentence(
      result,
      excludedKorean: sentence.korean,
      preferredSourceUnitId: sentence.sourceUnitId,
    );
    switch (question.kind) {
      case GroundedBookQuestionKind.meaning:
        final meaning = _sentenceMeaning(result, sentence);
        if (meaning.isEmpty) {
          return null;
        }
        return GroundedBookFactPayload(
          koreanEvidence: sentence.korean,
          explanation: meaning,
          sourceUnitIds: <String>[
            sentence.sourceUnitId,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
        );
      case GroundedBookQuestionKind.grammarInSentence:
        final grammar = _firstWhereOrNull(
          result.grammar,
          (candidate) =>
              candidate.sourceUnitId == sentence.sourceUnitId &&
              candidate.matchedText.isNotEmpty &&
              sentence.korean.contains(candidate.matchedText) &&
              _grammarExplanation(result, candidate).isNotEmpty,
        );
        if (grammar == null) {
          return null;
        }
        final grammarAdditional = _additionalSentence(
          result,
          excludedKorean: sentence.korean,
          containing: grammar.matchedText,
        );
        return GroundedBookFactPayload(
          koreanEvidence: grammar.matchedText,
          explanation: _grammarExplanation(result, grammar),
          sourceUnitIds: <String>[
            sentence.sourceUnitId,
            grammar.sourceUnitId,
            if (grammarAdditional != null) grammarAdditional.sourceUnitId,
          ],
          additionalExample: grammarAdditional?.korean ?? '',
        );
      case GroundedBookQuestionKind.quiz:
        final meaning = _sentenceMeaning(result, sentence);
        if (meaning.isEmpty) {
          return null;
        }
        return GroundedBookFactPayload(
          koreanEvidence: sentence.korean,
          explanation: meaning,
          sourceUnitIds: <String>[
            sentence.sourceUnitId,
            if (additional != null) additional.sourceUnitId,
          ],
          additionalExample: additional?.korean ?? '',
          quizPromptEvidence: meaning,
          quizAnswer: sentence.korean,
        );
      case GroundedBookQuestionKind.explainForm:
      case GroundedBookQuestionKind.showExample:
      case GroundedBookQuestionKind.compare:
        return null;
    }
  }

  static ExtractedWord? _wordForTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) => _firstWhereOrNull(
    result.words,
    (candidate) => GroundedBookTarget.forWord(candidate).matches(target),
  );

  static ExtractedExpression? _expressionForTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) => _firstWhereOrNull(
    result.expressions,
    (candidate) => GroundedBookTarget.forExpression(candidate).matches(target),
  );

  static GrammarHit? _grammarForTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) => _firstWhereOrNull(
    result.grammar,
    (candidate) => GroundedBookTarget.forGrammar(candidate).matches(target),
  );

  static TranslatedSentence? _sentenceForTarget(
    BookAnalysisResult result,
    GroundedBookTarget target,
  ) => _firstWhereOrNull(
    result.sentences,
    (candidate) => GroundedBookTarget.forSentence(candidate).matches(target),
  );

  static String _wordMeaning(BookAnalysisResult result, ExtractedWord word) {
    if (word.translationLanguage != result.analysisLanguage) {
      return '';
    }
    return result.analysisLanguage == 'en'
        ? word.translationEn
        : word.translationDe;
  }

  static String _expressionMeaning(
    BookAnalysisResult result,
    ExtractedExpression expression,
  ) {
    if (expression.translationLanguage != result.analysisLanguage) {
      return '';
    }
    return result.analysisLanguage == 'en'
        ? expression.translationEn
        : expression.translationDe;
  }

  static String _sentenceMeaning(
    BookAnalysisResult result,
    TranslatedSentence sentence,
  ) => sentence.translationLanguage == result.analysisLanguage
      // translationDe is the legacy primary-translation slot. Its language is
      // recorded separately and the response parser verifies analysisLanguage.
      ? sentence.translationDe
      : '';

  static String _grammarExplanation(
    BookAnalysisResult result,
    GrammarHit grammar,
  ) {
    if (!const <String>{'de', 'en'}.contains(result.analysisLanguage)) {
      return '';
    }
    // These legacy field names hold the requested analysis language. The
    // response-level analysisLanguage was already checked by the parser.
    return <String>[
      if (grammar.nameDe.isNotEmpty) grammar.nameDe,
      if (grammar.explanationDe.isNotEmpty) grammar.explanationDe,
    ].join('\n');
  }

  static bool _areComparableGrammarPatterns(String left, String right) =>
      _comparableGrammarFamilies.any(
        (family) => family.contains(left) && family.contains(right),
      );

  static _VerifiedExample? _wordExample(
    BookAnalysisResult result,
    ExtractedWord word,
  ) {
    final exactSentence = word.exampleKorean.isEmpty
        ? null
        : _firstWhereOrNull(
            result.sentences,
            (candidate) =>
                candidate.sourceUnitId.isNotEmpty &&
                candidate.sourceUnitId == word.sourceUnitId &&
                candidate.korean == word.exampleKorean &&
                candidate.korean.contains(word.korean),
          );
    if (exactSentence != null) {
      return (
        korean: exactSentence.korean,
        explanation: _sentenceMeaning(result, exactSentence),
        sourceUnitId: exactSentence.sourceUnitId,
      );
    }
    return _sentenceExample(
      result,
      sourceUnitId: word.sourceUnitId,
      containing: word.korean,
    );
  }

  static _VerifiedExample? _sentenceExample(
    BookAnalysisResult result, {
    required String sourceUnitId,
    required String containing,
  }) {
    final sentence =
        _firstWhereOrNull(
          result.sentences,
          (candidate) =>
              candidate.sourceUnitId.isNotEmpty &&
              candidate.sourceUnitId == sourceUnitId &&
              candidate.korean.contains(containing),
        ) ??
        _firstWhereOrNull(
          result.sentences,
          (candidate) =>
              candidate.sourceUnitId.isNotEmpty &&
              candidate.korean.contains(containing),
        );
    if (sentence == null) {
      return null;
    }
    return (
      korean: sentence.korean,
      explanation: _sentenceMeaning(result, sentence),
      sourceUnitId: sentence.sourceUnitId,
    );
  }

  static _VerifiedExample? _additionalSentence(
    BookAnalysisResult result, {
    required String excludedKorean,
    String containing = '',
    String preferredSourceUnitId = '',
  }) {
    bool matches(TranslatedSentence candidate) =>
        candidate.sourceUnitId.isNotEmpty &&
        candidate.korean != excludedKorean &&
        (containing.isEmpty || candidate.korean.contains(containing));

    final preferred = preferredSourceUnitId.isEmpty
        ? null
        : _firstWhereOrNull(
            result.sentences,
            (candidate) =>
                candidate.sourceUnitId == preferredSourceUnitId &&
                matches(candidate),
          );
    final sentence = preferred ?? _firstWhereOrNull(result.sentences, matches);
    if (sentence == null) {
      return null;
    }
    return (
      korean: sentence.korean,
      explanation: _sentenceMeaning(result, sentence),
      sourceUnitId: sentence.sourceUnitId,
    );
  }

  static T? _firstWhereOrNull<T>(
    Iterable<T> values,
    bool Function(T value) predicate,
  ) {
    for (final value in values) {
      if (predicate(value)) {
        return value;
      }
    }
    return null;
  }
}
