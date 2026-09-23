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
    group('bundled copula forms $lang', () {
      const cases = {
        '학생이에요': '학생',
        '학생이어요': '학생',
        '학생입니다': '학생',
        '학생입니까': '학생',
        '학생이었어요': '학생',
        '학생이었습니다': '학생',
        '학생이었다': '학생',
        '학생이다': '학생',
        '친구예요': '친구',
        '친구여요': '친구',
        '친구이에요': '친구',
        '친구이어요': '친구',
        '친구입니다': '친구',
        '친구입니까': '친구',
        '친구였어요': '친구',
        '친구이었어요': '친구',
        '친구였습니다': '친구',
        '친구이었습니다': '친구',
        '친구였다': '친구',
        '친구이었다': '친구',
        '친구이다': '친구',
        '사이예요': '사이',
        '사이였어요': '사이',
        '효율적이에요': '효율적이다',
        '효율적이었습니다': '효율적이다',
        '효율적입니다': '효율적이다',
        '구체적이어요': '구체적이다',
      };
      for (final entry in cases.entries) {
        test('${entry.key} keeps the dictionary meaning', () async {
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

      test('exact nominal and predicate headwords stay intact', () async {
        for (final token in ['사이', '학생', '친구', '효율적이다']) {
          final words = await BookWordGlossResolver().resolve(
            _document(token),
            targetLang: lang,
          );
          expect(words.single.korean, token);
        }
      });

      test('invalid contractions and unknown stems are not invented', () async {
        for (final token in [
          '학생예요',
          '학생여요',
          '학생였어요',
          '책였습니다',
          '먹다입니다',
          '뾰롱섬이에요',
          '친구예요예요',
        ]) {
          final words = await BookWordGlossResolver().resolve(
            _document(token),
            targetLang: lang,
          );
          expect(words, isEmpty, reason: token);
        }
      });

      test('server meaning wins after nominal deduplication', () async {
        final words = await BookWordGlossResolver().resolve(
          _document('학생이에요 학생이었습니다'),
          targetLang: lang,
          serverWords: const [
            ExtractedWord(
              korean: '학생',
              romanization: 'haksaeng',
              posDe: 'Nomen',
              translationDe: 'geprüfte Bedeutung',
              translationEn: 'reviewed meaning',
              exampleKorean: '',
              exampleDe: '',
              savedToPackId: null,
            ),
          ],
        );
        expect(words, hasLength(1));
        expect(words.single.korean, '학생');
        expect(words.single.source, 'server');
        expect(words.single.translationDe, 'geprüfte Bedeutung');
        expect(words.single.translationEn, 'reviewed meaning');
      });
    });
  }
}
