import '../models/book_page.dart';
import '../models/vocab.dart';

/// Backfills a saved curated card for display without changing stored user
/// content. A matching meaning is required: the same Hangul may have multiple
/// senses and a learner's own translation must never be replaced by a guess.
ExtractedWord localizeSavedWord(ExtractedWord word, Iterable<Vocab> catalog) {
  Vocab? match;
  for (final candidate in catalog) {
    if (candidate.korean.trim() != word.korean.trim()) {
      continue;
    }
    final sameGerman =
        word.translationDe.trim().isNotEmpty &&
        word.translationDe.trim() == candidate.german.trim();
    final sameEnglish =
        word.translationEn.trim().isNotEmpty &&
        word.translationEn.trim() == candidate.english.trim();
    if (sameGerman || sameEnglish) {
      match = candidate;
      break;
    }
  }
  if (match == null) {
    return word;
  }
  // The saved-book sanitizer puts adjacent sentences on separate lines;
  // the curated CSV keeps a space. Those are the same authored example.
  String normalizedExample(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final sameExample =
      normalizedExample(word.exampleKorean) ==
      normalizedExample(match.exampleKorean);
  final englishExample = word.exampleFor('en');
  final fillGermanExample = sameExample && word.exampleFor('de').trim().isEmpty;
  return word.copyWithEditable(
    translationEn: word.translationEn.trim().isEmpty ? match.english : null,
    exampleEn: sameExample && word.exampleEn.trim().isEmpty
        ? (englishExample.isNotEmpty ? englishExample : match.exampleEnglish)
        : null,
    exampleDe: fillGermanExample ? match.exampleGerman : null,
    exampleLanguage: fillGermanExample ? 'de' : null,
  );
}
