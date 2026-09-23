import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';
import 'package:ko_lernen_app/services/book_word_gloss_resolver.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

BookOcrDocument _document(List<String> lines) => BookOcrDocumentBuilder.build([
  for (var i = 0; i < lines.length; i++)
    BookOcrLine(
      text: lines[i],
      bounds: Rect.fromLTWH(0, i * 80, 300, 30),
      sourceLineId: 'page:0:line:$i',
      blockIndex: i,
      lineIndex: 0,
      confidence: .95,
      recognizedLanguages: const ['ko'],
    ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final lang in ['de', 'en']) {
    for (final reading in [('걸다', '걸어요', '걷다'), ('들다', '들어요', '듣다')]) {
      for (final separateUnits in [false, true]) {
        for (final exactFirst in [true, false]) {
          test('$lang ${reading.$1} ambiguity survives either order '
              '(separate=$separateUnits, exactFirst=$exactFirst)', () async {
            final tokens = exactFirst
                ? [reading.$1, reading.$2]
                : [reading.$2, reading.$1];
            final document = _document(
              separateUnits ? tokens : [tokens.join(' ')],
            );
            expect(document.analysisUnits, hasLength(separateUnits ? 2 : 1));
            final words = await BookWordGlossResolver().resolve(
              document,
              targetLang: lang,
            );
            final dictionary = (await DataLoader.loadVocab()).firstWhere(
              (word) => word.korean == reading.$1,
            );
            expect(words, hasLength(1));
            final word = words.single;
            expect(word.korean, reading.$1);
            expect(word.ambiguous, isTrue);
            expect(word.alternativeHeadword, reading.$3);
            expect(word.translationDe, dictionary.german);
            expect(word.translationEn, dictionary.english);
            expect(word.source, 'bundled');
            expect(word.sourceUnitId, document.analysisUnits.first.id);
            expect(word.confidence, 1);
          });
        }
      }
    }
    test('$lang exact duplicates do not invent ambiguity', () async {
      final words = await BookWordGlossResolver().resolve(
        _document(['걸다 걸다']),
        targetLang: lang,
      );
      expect(words, hasLength(1));
      expect(words.single.ambiguous, isFalse);
      expect(words.single.alternativeHeadword, isEmpty);
    });
    test('$lang explicit server result retains precedence', () async {
      final words = await BookWordGlossResolver().resolve(
        _document(['걸다 걸어요']),
        targetLang: lang,
        serverWords: const [
          ExtractedWord(
            korean: '걸다',
            romanization: '',
            posDe: 'Verb',
            translationDe: 'kontextgeprüfte Bedeutung',
            translationEn: 'context-checked meaning',
            exampleKorean: '',
            exampleDe: '',
            savedToPackId: null,
            sourceUnitId: 'server-unit',
          ),
        ],
      );
      expect(words, hasLength(1));
      expect(words.single.ambiguous, isFalse);
      expect(words.single.alternativeHeadword, isEmpty);
      expect(words.single.source, 'server');
      expect(words.single.sourceUnitId, 'server-unit');
      expect(words.single.translationEn, 'context-checked meaning');
    });
  }
}
