import 'dart:math' as math;

import '../models/vocab.dart';
import 'storage_service.dart';

/// The SRS consequence of one optional, typed vocabulary-recall attempt.
///
/// A revealed hint makes a later correct entry useful practice, but not a
/// stand-alone positive SRS signal. A wrong entry or an answer reveal is a
/// negative signal; the recall UI locks that prompt afterwards, so it cannot
/// be overwritten by a correction in the same attempt.
enum VocabRecallEvidence { positive, negative, none }

class VocabRecallGrade {
  final bool isCorrect;
  final VocabRecallEvidence evidence;

  const VocabRecallGrade({required this.isCorrect, required this.evidence});
}

/// Compares Korean vocabulary answers without treating spacing inside a word
/// or short phrase as a spelling failure. Other characters remain exact.
String normalizeVocabRecallAnswer(String value) =>
    value.replaceAll(RegExp(r'\s+'), '').trim();

/// Grades the learner's first typed response.
VocabRecallGrade gradeVocabRecallAnswer({
  required String submitted,
  required String expected,
  required bool usedHint,
}) {
  final isCorrect =
      normalizeVocabRecallAnswer(submitted) ==
      normalizeVocabRecallAnswer(expected);
  if (!isCorrect) {
    return const VocabRecallGrade(
      isCorrect: false,
      evidence: VocabRecallEvidence.negative,
    );
  }
  return VocabRecallGrade(
    isCorrect: true,
    evidence: usedHint
        ? VocabRecallEvidence.none
        : VocabRecallEvidence.positive,
  );
}

/// Revealing the answer means the word was not recalled independently.
const VocabRecallGrade revealedVocabRecallAnswer = VocabRecallGrade(
  isCorrect: false,
  evidence: VocabRecallEvidence.negative,
);

/// A tiny, progressive cue for optional Korean typing practice.
String vocabRecallFirstSyllable(String korean) {
  final trimmed = korean.trim();
  return trimmed.isEmpty ? '' : trimmed.substring(0, 1);
}

/// Reuses the app's existing leech/frequent-miss threshold for a small,
/// contextual Hard Words CTA. A one-off recall miss stays with normal SRS.
bool shouldOfferVocabRecallHardWordPractice(Iterable<String> missedWordIds) {
  final ids = missedWordIds.toSet();
  if (ids.isEmpty) {
    return false;
  }
  return Storage.hardIds(ids).isNotEmpty ||
      Storage.frequentlyMissedIds(ids).isNotEmpty;
}

/// Returns a reproducibly shuffled boss-word order without leaving a
/// multi-word list in its source order. The caller controls [rng] for tests.
List<Vocab> shuffledVocabRecallWords(
  Iterable<Vocab> words, {
  required math.Random rng,
}) {
  final source = words.toList(growable: false);
  final shuffled = List<Vocab>.of(source)..shuffle(rng);
  if (shuffled.length > 1 && _sameWordOrder(source, shuffled)) {
    final first = shuffled.removeAt(0);
    shuffled.add(first);
  }
  return shuffled;
}

bool _sameWordOrder(List<Vocab> left, List<Vocab> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i].id != right[i].id) {
      return false;
    }
  }
  return true;
}
