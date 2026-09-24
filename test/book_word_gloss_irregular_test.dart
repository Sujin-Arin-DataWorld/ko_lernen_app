import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';
import 'package:ko_lernen_app/services/book_word_gloss_resolver.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

BookOcrDocument _document(String text) => BookOcrDocumentBuilder.build([
  BookOcrLine(
    text: text,
    bounds: const Rect.fromLTWH(0, 0, 300, 30),
    sourceLineId: 'page:0:line:0',
    blockIndex: 0,
    lineIndex: 0,
    confidence: .95,
    recognizedLanguages: const ['ko'],
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const forms = <String, List<String>>{
    '돕다': ['도와요', '도왔어요'],
    '춥다': ['추워요', '추웠어요'],
    '덥다': ['더워요', '더웠어요'],
    '아름답다': ['아름다워요', '아름다웠어요'],
    '쉽다': ['쉬워요', '쉬웠어요'],
    '어렵다': ['어려워요', '어려웠어요'],
    '맵다': ['매워요', '매웠어요'],
    '모르다': ['몰라요', '몰랐어요'],
    '부르다': ['불러요', '불렀어요'],
    '다르다': ['달라요', '달랐어요'],
    '빠르다': ['빨라요', '빨랐어요'],
    '게으르다': ['게을러요', '게을렀어요'],
    '서투르다': ['서툴러요', '서툴렀어요'],
    '배부르다': ['배불렀어요'],
    // The corpus already has this complete expression; exact meaning wins.
    '배불러요': ['배불러요'],
    '고르다': ['골라요', '골랐어요'],
    '쓰다': ['써요', '썼어요'],
    '크다': ['커요', '컸어요'],
    '바쁘다': ['바빠요', '바빴어요'],
    '예쁘다': ['예뻐요', '예뻤어요'],
    '슬프다': ['슬퍼요', '슬펐어요'],
    '그렇다': ['그래요', '그랬어요'],
  };
  for (final lang in ['de', 'en']) {
    group(lang, () {
      for (final entry in forms.entries) {
        for (final surface in entry.value) {
          test('$surface retains bundled ${entry.key} meaning', () async {
            final dictionary = (await DataLoader.loadVocab()).firstWhere(
              (word) => word.korean == entry.key,
            );
            final document = _document(surface);
            final words = await BookWordGlossResolver().resolve(
              document,
              targetLang: lang,
            );
            expect(words, hasLength(1));
            expect(words.single.korean, entry.key);
            expect(words.single.translationDe, dictionary.german);
            expect(words.single.translationEn, dictionary.english);
            expect(words.single.posDe, dictionary.posDe);
            expect(words.single.source, 'bundled');
            expect(words.single.sourceUnitId, document.analysisUnits.single.id);
            expect(words.single.ambiguous, isFalse);
          });
        }
      }
      for (final entry in {
        '걸어요': ['걸다', '걷다'],
        '걸었어요': ['걸다', '걷다'],
        '들어요': ['들다', '듣다'],
        '들었어요': ['들다', '듣다'],
      }.entries) {
        test('${entry.key} retains both valid predicate readings', () async {
          final words = await BookWordGlossResolver().resolve(
            _document(entry.key),
            targetLang: lang,
          );
          expect(words, hasLength(1));
          expect(words.single.korean, entry.value.first);
          expect(words.single.alternativeHeadword, entry.value.last);
          expect(words.single.ambiguous, isTrue);
        });
      }
      test('unknown forms do not invent dictionary entries', () async {
        for (final text in ['뾰롱워요', '도와요요', '추워어요', '더와요']) {
          final words = await BookWordGlossResolver().resolve(
            _document(text),
            targetLang: lang,
          );
          expect(words, isEmpty, reason: text);
        }
      });
      test(
        'regular predicate and exact nominal matching stay intact',
        () async {
          for (final entry in {
            '먹어요': '먹다',
            '잡아요': '잡다',
            '학생': '학생',
            '친구': '친구',
          }.entries) {
            final words = await BookWordGlossResolver().resolve(
              _document(entry.key),
              targetLang: lang,
            );
            expect(words.single.korean, entry.value);
          }
        },
      );
      test('deduplication and server precedence survive inflection', () async {
        final words = await BookWordGlossResolver().resolve(
          _document('도와요 도왔어요'),
          targetLang: lang,
          serverWords: const [
            ExtractedWord(
              korean: '돕다',
              romanization: '',
              posDe: 'Verb',
              translationDe: 'geprüfte Bedeutung',
              translationEn: 'reviewed meaning',
              exampleKorean: '',
              exampleDe: '',
              savedToPackId: null,
            ),
          ],
        );
        expect(words, hasLength(1));
        expect(words.single.source, 'server');
        expect(words.single.translationEn, 'reviewed meaning');
      });
    });
  }
}
