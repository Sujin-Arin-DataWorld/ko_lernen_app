import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';
import 'package:ko_lernen_app/services/book_word_gloss_resolver.dart';

BookOcrDocument _document(String text) => BookOcrDocumentBuilder.build([
  BookOcrLine(
    text: text,
    bounds: const Rect.fromLTWH(0, 0, 300, 30),
    sourceLineId: 'page:0:line:0',
    blockIndex: 0,
    lineIndex: 0,
    confidence: 0.95,
    recognizedLanguages: const ['ko'],
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final lang in ['de', 'en']) {
    group('bundled OCR particle chains $lang', () {
      const cases = {
        '학교에서도': '학교',
        '학교에서만': '학교',
        '학교에는': '학교',
        '학교에도': '학교',
        '학교에만': '학교',
        '친구에게는': '친구',
        '친구에게도': '친구',
        '친구에게만': '친구',
        '친구에게서는': '친구',
        '친구에게서도': '친구',
        '친구한테는': '친구',
        '친구한테도': '친구',
        '친구한테서도': '친구',
        '집으로도': '집',
        '집으로만은': '집',
        '학교로만은': '학교',
        '길로만은': '길',
        '학교로는': '학교',
        '학교로도': '학교',
        '학교까지만': '학교',
        '학교부터는': '학교',
        '책만은': '책',
        '학교에서만은': '학교',
        '오늘만은': '오늘',
        '내일까지만': '내일',
        '어제부터는': '어제',
      };
      for (final entry in cases.entries) {
        test('${entry.key} retains bundled meaning and source', () async {
          final resolver = BookWordGlossResolver();
          final words = await resolver.resolve(
            _document(entry.key),
            targetLang: lang,
          );
          final dictionary = await resolver.resolve(
            _document(entry.value),
            targetLang: lang,
          );
          expect(words, hasLength(1));
          expect(words.single.korean, entry.value);
          expect(words.single.source, 'bundled');
          expect(words.single.sourceUnitId, isNotEmpty);
          expect(words.single.translationDe, dictionary.single.translationDe);
          expect(words.single.translationEn, dictionary.single.translationEn);
          expect(words.single.translationDe, isNotEmpty);
          expect(words.single.translationEn, isNotEmpty);
        });
      }

      test(
        'exact headwords with particle-looking endings stay intact',
        () async {
          for (final token in ['학교', '사과', '사이', '바다']) {
            final words = await BookWordGlossResolver().resolve(
              _document(token),
              targetLang: lang,
            );
            expect(words.single.korean, token);
          }
        },
      );

      test(
        'an existing inflected phrase keeps its dictionary meaning',
        () async {
          final words = await BookWordGlossResolver().resolve(
            _document('집까지만'),
            targetLang: lang,
          );
          expect(words.single.korean, '집까지');
          expect(words.single.translationDe, 'bis nach Hause');
        },
      );

      test(
        'unknown or recursively repeated suffixes do not invent words',
        () async {
          for (final token in ['뾰롱섬에서도', '학교에서도도', '먹다에게도', '빠르다만은']) {
            final words = await BookWordGlossResolver().resolve(
              _document(token),
              targetLang: lang,
            );
            expect(words, isEmpty, reason: token);
          }
        },
      );

      test(
        'server precedence and headword deduplication remain intact',
        () async {
          const server = ExtractedWord(
            korean: '학교',
            romanization: 'hakgyo',
            posDe: 'Nomen',
            translationDe: 'Schule (Server)',
            translationEn: 'school (server)',
            exampleKorean: '',
            exampleDe: '',
            savedToPackId: null,
          );
          final words = await BookWordGlossResolver().resolve(
            _document('학교에서도 학교에는 학교'),
            targetLang: lang,
            serverWords: const [server],
          );
          expect(words, hasLength(1));
          expect(words.single.source, 'server');
          expect(words.single.translationDe, server.translationDe);
          expect(words.single.translationEn, server.translationEn);
        },
      );

      for (final token in ['빨리에게도', '천천히한테만']) {
        test('$token rejects a dative chain on an adverb', () async {
          final words = await BookWordGlossResolver().resolve(
            _document(token),
            targetLang: lang,
          );
          expect(words, isEmpty);
        });
      }
    });
  }
}
