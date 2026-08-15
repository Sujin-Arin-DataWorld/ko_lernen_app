import 'package:csv/csv.dart';

import '../models/book_page.dart';
import 'book_analysis_text.dart';

const int maxCustomPackCsvRows = 200;

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
  final englishMeaning = language == 'en' ? meaning : translationEn;
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
    translationDe: meaning,
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
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

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
