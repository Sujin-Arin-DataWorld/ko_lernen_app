import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_analysis_text.dart';

void main() {
  test('matches the shared Dart and Python text-quality contract', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/book_analysis_text_contract.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

    expect(fixture['version'], 'book-analysis-text-v2');

    for (final entry in cases) {
      final prepared = BookAnalysisTextPreprocessor.prepare(
        entry['input'] as String,
      );
      expect(prepared.text, entry['output'], reason: entry['name'] as String);
      expect(
        prepared.warnings,
        (entry['warnings'] as List).cast<String>(),
        reason: entry['name'] as String,
      );
    }
  });

  test('reports unsupported-script ratio before sanitizing OCR text', () {
    final inspection = BookAnalysisTextPreprocessor.inspect('안녕مرحبا');

    expect(inspection.hasKoreanText, isTrue);
    expect(inspection.unsupportedCharacterCount, 5);
    expect(inspection.consideredCharacterCount, 7);
    expect(inspection.unsupportedRatio, closeTo(5 / 7, 0.0001));
  });

  test(
    'safe edited text requires Hangul and no unsupported or format runes',
    () {
      expect(
        BookAnalysisTextPreprocessor.inspect(
          '저는 Berlin에 살아요.',
        ).isSafeEditedText,
        isTrue,
      );
      expect(
        BookAnalysisTextPreprocessor.inspect('안녕\u202Eabc').isSafeEditedText,
        isFalse,
      );
      expect(
        BookAnalysisTextPreprocessor.inspect('안녕\u0085하세요').isSafeEditedText,
        isFalse,
      );
      expect(
        BookAnalysisTextPreprocessor.inspect('Only English').isSafeEditedText,
        isFalse,
      );
    },
  );

  test('truncation happens after NFC normalization and filtering', () {
    final prepared = BookAnalysisTextPreprocessor.prepare(
      List<String>.filled(100, '안녕하세요.').join(' '),
      maxCharacters: 80,
    );

    expect(prepared.text.length, lessThanOrEqualTo(80));
    expect(prepared.warnings, contains('text_truncated'));
  });
}
