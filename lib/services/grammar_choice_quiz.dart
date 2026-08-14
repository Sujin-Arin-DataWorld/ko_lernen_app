import 'dart:math';

import '../models/grammar.dart';

/// One reviewed, recognition-only grammar question.
///
/// The source sentence is in the learner's UI language. It deliberately does
/// not show the Korean example before selection, so the answer cannot be read
/// directly from an inflected Korean surface form. This is free practice: the
/// question itself has no course-progress or vocabulary-SRS side effects.
class GrammarChoiceQuestion {
  const GrammarChoiceQuestion({required this.target, required this.options});

  final Grammar target;
  final List<Grammar> options;

  bool isCorrect(Grammar option) => option.id == target.id;

  bool get hasFourUniqueOptions =>
      options.length == grammarChoiceOptionCount &&
      options.map((option) => option.id).toSet().length == options.length &&
      options.any((option) => option.id == target.id);
}

/// Four choices keep the new exercise consistent with the app's other
/// recognition practice without relabeling it as recall or mastery.
const int grammarChoiceOptionCount = 4;

/// Whether [grammar] is explicitly approved for the four-choice exercise.
///
/// Eligibility is authored in `grammar.csv`, not inferred from translations
/// or maintained in a partial Dart conflict map. That keeps ambiguous
/// learner-language examples out of a false `grammarHard` signal by failing
/// closed when future content omits its reviewed option set.
bool isGrammarChoiceTargetEligible(Grammar grammar) => grammar.quizEnabled;

/// A plain-text segment for a sentence with one reviewed focus phrase.
class GrammarPromptSegment {
  const GrammarPromptSegment(this.text, {this.isFocus = false});

  final String text;
  final bool isFocus;
}

/// Splits a reviewed sentence into quiet text plus its one emphasis span.
///
/// Callers should only use this after [Grammar.hasSingleExampleFocusFor]; the
/// defensive fallback renders the source intact if a legacy fixture supplies
/// no valid marker.
List<GrammarPromptSegment> splitGrammarPrompt({
  required String example,
  required String focus,
}) {
  final trimmedFocus = focus.trim();
  final start = trimmedFocus.isEmpty ? -1 : example.indexOf(trimmedFocus);
  if (start < 0) {
    return <GrammarPromptSegment>[GrammarPromptSegment(example)];
  }
  final end = start + trimmedFocus.length;
  return <GrammarPromptSegment>[
    if (start > 0) GrammarPromptSegment(example.substring(0, start)),
    GrammarPromptSegment(example.substring(start, end), isFocus: true),
    if (end < example.length) GrammarPromptSegment(example.substring(end)),
  ];
}

/// Builds a question from its one authored target and three reviewed options.
///
/// The caller owns [random], which makes answer order reproducible in tests
/// while keeping production rounds fresh. No random fallback is permitted: a
/// missing, duplicate, cross-level, disabled, or stale authored ID means the
/// row stays study-only until content review repairs it.
GrammarChoiceQuestion? buildGrammarChoiceQuestion({
  required Grammar target,
  required Iterable<Grammar> pool,
  required Random random,
}) {
  if (!isGrammarChoiceTargetEligible(target) ||
      target.quizDistractorIds.length != grammarChoiceOptionCount - 1) {
    return null;
  }
  final byId = <String, Grammar>{
    for (final grammar in pool) grammar.id: grammar,
  };
  final optionIds = <String>[target.id, ...target.quizDistractorIds];
  if (optionIds.toSet().length != grammarChoiceOptionCount) {
    return null;
  }
  final options = <Grammar>[];
  for (final id in optionIds) {
    final option = byId[id];
    if (option == null ||
        !isGrammarChoiceTargetEligible(option) ||
        option.level != target.level) {
      return null;
    }
    options.add(option);
  }
  options.shuffle(random);
  return GrammarChoiceQuestion(
    target: target,
    options: List<Grammar>.unmodifiable(options),
  );
}

/// Creates a fresh, level-scoped practice round from authored prompts.
///
/// Rows lacking a reviewed focus phrase or canonical option set remain
/// available in normal study but are never guessed into this exercise.
List<GrammarChoiceQuestion> buildGrammarChoiceRound({
  required Iterable<Grammar> source,
  required String level,
  required String languageCode,
  required Random random,
  int maxQuestions = 10,
}) {
  if (maxQuestions <= 0) {
    return const <GrammarChoiceQuestion>[];
  }
  final all = source
      .where(
        (grammar) =>
            isGrammarChoiceTargetEligible(grammar) &&
            grammar.hasSingleExampleFocusFor(languageCode),
      )
      .toList(growable: false);
  final targets =
      all.where((grammar) => grammar.level == level).toList(growable: false)
        ..sort((a, b) => a.id.compareTo(b.id))
        ..shuffle(random);
  final round = <GrammarChoiceQuestion>[];
  for (final target in targets) {
    final question = buildGrammarChoiceQuestion(
      target: target,
      pool: all,
      random: random,
    );
    if (question == null) {
      continue;
    }
    round.add(question);
    if (round.length >= maxQuestions) {
      break;
    }
  }
  return List<GrammarChoiceQuestion>.unmodifiable(round);
}
