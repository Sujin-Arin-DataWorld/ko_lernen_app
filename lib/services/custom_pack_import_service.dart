import 'package:csv/csv.dart';

import '../models/book_page.dart';
import 'book_analysis_text.dart';

const int maxCustomPackCsvRows = 8000;
const int maxCustomPackWords = maxCustomPackCsvRows;

/// Keeps the first occurrence of each Korean headword and stops at the
/// notebook / import ceiling so a 7000-word list can grow by photos
/// without duplicating or overflowing local storage.
List<ExtractedWord> mergeUniqueCustomPackWords(
  Iterable<ExtractedWord> existing,
  Iterable<ExtractedWord> incoming, {
  int maxWords = maxCustomPackWords,
}) {
  final merged = <ExtractedWord>[];
  final seen = <String>{};

  void add(ExtractedWord word) {
    final korean = word.korean.trim();
    if (korean.isEmpty || !seen.add(korean) || merged.length >= maxWords) {
      return;
    }
    merged.add(word);
  }

  for (final word in existing) {
    add(word);
  }
  for (final word in incoming) {
    add(word);
  }
  return merged;
}

String sanitizeCustomPackKoreanWord(String value) =>
    BookAnalysisTextPreprocessor.prepare(
      value,
    ).text.replaceAll(RegExp(r'\s+'), ' ').trim();

ExtractedWord buildCustomPackEditedWord({
  required String korean,
  required String meaning,
  required String exampleKorean,
  required String definitionKo,
  required String translationLanguage,
  String translationEn = '',
  ExtractedWord? existing,
}) {
  final language = translationLanguage == 'en' ? 'en' : 'de';
  final englishMeaning = language == 'en'
      ? meaning
      : (translationEn.isNotEmpty
            ? translationEn
            : (existing?.translationFor('en') ?? ''));
  if (existing == null) {
    return ExtractedWord.manual(
      korean: korean,
      translationDe: meaning,
      translationEn: englishMeaning,
      translationLanguage: language,
      exampleKorean: exampleKorean,
      definitionKo: definitionKo,
    );
  }
  return existing.copyWithEditable(
    korean: korean,
    translationDe: language == 'en' && existing.translationFor('de').isNotEmpty
        ? existing.translationDe
        : meaning,
    translationEn: englishMeaning,
    translationLanguage: language,
    exampleKorean: exampleKorean,
    definitionKo: definitionKo,
  );
}

/// Parses learner-provided CSV without losing the language of its meaning
/// column. The legacy German slot remains populated for existing games, while
/// English meanings are mirrored to [ExtractedWord.translationEn].
List<ExtractedWord> parseCustomPackCsvWords(
  String raw, {
  required String translationLanguage,
}) {
  final language = translationLanguage == 'en' ? 'en' : 'de';
  final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
    fieldDelimiter: _detectCustomPackDelimiter(normalized),
  ).convert(normalized);

  final words = <ExtractedWord>[];
  for (final row in rows.take(maxCustomPackCsvRows)) {
    if (row.isEmpty) {
      continue;
    }
    final korean = sanitizeCustomPackKoreanWord(row[0].toString());
    if (korean.isEmpty) {
      continue;
    }
    final meaning = row.length > 1 ? row[1].toString().trim() : '';
    final example = row.length > 2 ? row[2].toString().trim() : '';
    words.add(
      ExtractedWord.manual(
        korean: korean,
        translationDe: meaning,
        translationEn: language == 'en' ? meaning : '',
        translationLanguage: language,
        exampleKorean: example,
      ),
    );
  }
  return words;
}

String _detectCustomPackDelimiter(String raw) {
  final first = raw
      .split('\n')
      .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
  if (first.contains('\t')) {
    return '\t';
  }
  if (first.contains(';') && !first.contains(',')) {
    return ';';
  }
  return ',';
}
