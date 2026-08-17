import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/grammar_choice_quiz.dart';

const _levels = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// These seven rows need a Korean-form prompt, not a translation-choice
/// question. Their disabled state is deliberately explicit in the CSV.
const _disabledIrregularIds = <String>{
  'grammar_a2_irregular_eu',
  'grammar_a2_irregular_bieup',
  'grammar_a2_irregular_digeut',
  'grammar_a2_irregular_rieul',
  'grammar_b1_irregular_reu',
  'grammar_b1_irregular_siot',
  'grammar_b1_irregular_hieut',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DataLoader.reset);

  test(
    'authored grammar-choice corpus is complete, safe, and canonical',
    () async {
      final grammar = await DataLoader.loadGrammar();
      final byId = {for (final item in grammar) item.id: item};
      final disabled = grammar.where((item) => !item.quizEnabled).toList();

      expect(grammar, hasLength(182));
      expect(
        disabled.map((item) => item.id),
        unorderedEquals(_disabledIrregularIds),
      );

      for (final item in grammar.where((item) => item.quizEnabled)) {
        expect(
          item.hasSingleExampleFocusFor('de'),
          isTrue,
          reason: '${item.id} needs one exact German focus',
        );
        expect(
          item.hasSingleExampleFocusFor('en'),
          isTrue,
          reason: '${item.id} needs one exact English focus',
        );
        expect(
          item.quizDistractorIds,
          hasLength(grammarChoiceOptionCount - 1),
          reason: '${item.id} needs exactly three authored distractors',
        );
        expect(
          item.quizDistractorIds.toSet(),
          hasLength(grammarChoiceOptionCount - 1),
          reason: '${item.id} repeats an authored distractor',
        );
        expect(
          item.quizDistractorIds,
          isNot(contains(item.id)),
          reason: '${item.id} cannot distract from itself',
        );

        for (final distractorId in item.quizDistractorIds) {
          final distractor = byId[distractorId];
          expect(
            distractor,
            isNotNull,
            reason: '${item.id} references missing $distractorId',
          );
          expect(
            distractor!.quizEnabled,
            isTrue,
            reason: '${item.id} references disabled $distractorId',
          );
          expect(
            distractor.level,
            item.level,
            reason: '${item.id} crosses level with $distractorId',
          );
        }

        final canonicalIds = <String>{item.id, ...item.quizDistractorIds};
        for (final languageCode in ['de', 'en']) {
          final question = buildGrammarChoiceQuestion(
            target: item,
            pool: grammar,
            random: Random(41),
          );

          expect(question, isNotNull, reason: '${item.id} must build');
          expect(
            question!.options.map((option) => option.id).toSet(),
            unorderedEquals(canonicalIds),
            reason: '${item.id} must use only its authored option set',
          );
          expect(
            question.options.every((option) => option.quizEnabled),
            isTrue,
            reason: '${item.id} exposed a disabled option for $languageCode',
          );
        }
      }
    },
  );

  test('prompt split preserves the reviewed focus as one emphasis span', () {
    final segments = splitGrammarPrompt(
      example: 'I am a student.',
      focus: 'am',
    );

    expect(segments.map((segment) => segment.text), [
      'I ',
      'am',
      ' a student.',
    ]);
    expect(segments.map((segment) => segment.isFocus), [false, true, false]);
  });

  test(
    'question uses exactly the authored options and is seed reproducible',
    () {
      final source = _fixture();
      final target = source.first;

      final first = buildGrammarChoiceQuestion(
        target: target,
        pool: source,
        random: Random(17),
      );
      final reordered = buildGrammarChoiceQuestion(
        target: target,
        pool: source.reversed,
        random: Random(17),
      );

      expect(first, isNotNull);
      expect(reordered, isNotNull);
      expect(first!.hasFourUniqueOptions, isTrue);
      expect(first.options, hasLength(grammarChoiceOptionCount));
      expect(
        first.options.map((option) => option.id).toSet(),
        unorderedEquals(<String>{target.id, ...target.quizDistractorIds}),
      );
      expect(
        first.options.map((option) => option.id),
        reordered!.options.map((option) => option.id),
      );
    },
  );

  test(
    'round keeps every authored target deterministic in each language and level',
    () async {
      final source = await DataLoader.loadGrammar();

      for (var levelIndex = 0; levelIndex < _levels.length; levelIndex++) {
        final level = _levels[levelIndex];
        final expectedTargetIds = source
            .where((item) => item.level == level && item.quizEnabled)
            .map((item) => item.id)
            .toSet();

        for (var languageIndex = 0; languageIndex < 2; languageIndex++) {
          final languageCode = languageIndex == 0 ? 'de' : 'en';
          final seed = 100 + (levelIndex * 10) + languageIndex;
          final first = buildGrammarChoiceRound(
            source: source,
            level: level,
            languageCode: languageCode,
            random: Random(seed),
            maxQuestions: source.length,
          );
          final sameSeed = buildGrammarChoiceRound(
            source: source,
            level: level,
            languageCode: languageCode,
            random: Random(seed),
            maxQuestions: source.length,
          );
          final reordered = buildGrammarChoiceRound(
            source: source.reversed,
            level: level,
            languageCode: languageCode,
            random: Random(seed),
            maxQuestions: source.length,
          );

          expect(
            first.map((question) => question.target.id).toSet(),
            unorderedEquals(expectedTargetIds),
            reason: '$languageCode $level must expose every authored target',
          );
          expect(
            _roundSignature(first),
            _roundSignature(sameSeed),
            reason: '$languageCode $level must be reproducible with a seed',
          );
          expect(
            _roundSignature(first),
            _roundSignature(reordered),
            reason: '$languageCode $level must ignore source input order',
          );
          for (final question in first) {
            expect(question.target.quizEnabled, isTrue);
            expect(
              question.options.map((option) => option.id).toSet(),
              unorderedEquals(<String>{
                question.target.id,
                ...question.target.quizDistractorIds,
              }),
              reason: '${question.target.id} must retain its canonical options',
            );
          }
        }
      }
    },
  );

  test('a missing, disabled, or cross-level authored option fails closed', () {
    final target = _grammar(
      'a1_target',
      distractorIds: const ['a1_missing', 'a2_1', 'a1_disabled'],
    );
    final question = buildGrammarChoiceQuestion(
      target: target,
      pool: [
        target,
        _grammar('a2_1', level: 'A2'),
        _grammar('a1_disabled', quizEnabled: false),
      ],
      random: Random(1),
    );

    expect(question, isNull);
  });

  test('disabled irregular rows stay out of targets and option sets', () async {
    final source = await DataLoader.loadGrammar();

    for (final level in _levels) {
      final round = buildGrammarChoiceRound(
        source: source,
        level: level,
        languageCode: 'en',
        random: Random(level.codeUnitAt(0)),
        maxQuestions: source.length,
      );
      final shownIds = round
          .expand((question) => question.options)
          .map((grammar) => grammar.id)
          .toSet();
      final targetIds = round.map((question) => question.target.id).toSet();

      expect(shownIds.intersection(_disabledIrregularIds), isEmpty);
      expect(targetIds.intersection(_disabledIrregularIds), isEmpty);
    }
  });

  test('round excludes a row with a missing focus individually', () {
    final source = _fixture();
    final missing = _grammar(
      'a1_missing_focus',
      exampleGerman: 'Ein Beispiel ohne Markierung.',
      exampleEn: 'An example without a marker.',
      exampleGermanFocus: '',
      exampleEnFocus: '',
      distractorIds: const ['a1_1', 'a1_2', 'a1_3'],
    );

    final round = buildGrammarChoiceRound(
      source: [...source, missing],
      level: 'A1',
      languageCode: 'en',
      random: Random(3),
      maxQuestions: 10,
    );

    expect(
      round.map((question) => question.target.id),
      isNot(contains(missing.id)),
    );
  });

  test('round excludes a row with an ambiguous focus individually', () {
    final source = _fixture();
    final unavailable = _grammar(
      'a1_unreviewed',
      exampleGerman: 'Der gleiche Teil, der gleiche Teil.',
      exampleEn: 'The same part, the same part.',
      exampleGermanFocus: 'gleiche Teil',
      exampleEnFocus: 'same part',
      distractorIds: const ['a1_1', 'a1_2', 'a1_3'],
    );

    final round = buildGrammarChoiceRound(
      source: [...source, unavailable],
      level: 'A1',
      languageCode: 'en',
      random: Random(3),
      maxQuestions: 10,
    );

    expect(
      round.map((question) => question.target.id),
      isNot(contains(unavailable.id)),
    );
  });
}

List<Grammar> _fixture() => [
  _grammar('a1_1', distractorIds: const ['a1_2', 'a1_3', 'a1_4']),
  _grammar('a1_2', distractorIds: const ['a1_1', 'a1_3', 'a1_4']),
  _grammar('a1_3', distractorIds: const ['a1_1', 'a1_2', 'a1_4']),
  _grammar('a1_4', distractorIds: const ['a1_1', 'a1_2', 'a1_3']),
];

Grammar _grammar(
  String id, {
  String level = 'A1',
  bool quizEnabled = true,
  List<String> distractorIds = const [],
  String? exampleGerman,
  String? exampleEn,
  String? exampleGermanFocus,
  String? exampleEnFocus,
}) => Grammar(
  id: id,
  pattern: '-$id',
  level: level,
  typeDe: 'Test',
  explanationDe: 'Test',
  exampleKorean: '예문입니다.',
  exampleGerman: exampleGerman ?? 'Das Beispiel $id.',
  note: 'Test',
  typeEn: 'Test',
  explanationEn: 'Test',
  exampleEn: exampleEn ?? 'The example $id.',
  noteEn: 'Test',
  exampleGermanFocus: exampleGermanFocus ?? id,
  exampleEnFocus: exampleEnFocus ?? id,
  quizEnabled: quizEnabled,
  quizDistractorIds: distractorIds,
);

String _roundSignature(List<GrammarChoiceQuestion> round) => round
    .map(
      (question) =>
          '${question.target.id}:${question.options.map((option) => option.id).join(',')}',
    )
    .join('|');
