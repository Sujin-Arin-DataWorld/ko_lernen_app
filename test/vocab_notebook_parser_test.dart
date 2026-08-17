import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/book_ocr_document.dart';
import 'package:ko_lernen_app/services/vocab_notebook_parser.dart';

void main() {
  test('keeps inline notebook pairs with the learner meaning', () {
    final result = VocabNotebookParser.parse('''
학교 - Schule
학생 = Schüler
공부하다    lernen
친구	Freund
1. 시간 Zeit
사용 / benutzen
''');

    expect(result.looksLikeNotebook, isTrue);
    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      containsAll(<String>[
        '학교|Schule',
        '학생|Schüler',
        '공부하다|lernen',
        '친구|Freund',
        '시간|Zeit',
        '사용|benutzen',
      ]),
    );
  });

  test('keeps a Korean headword and Latin gloss on the same line', () {
    final result = VocabNotebookParser.parse('시작 Anfang\n개시 Eröffnung');
    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      <String>['시작|Anfang', '개시|Eröffnung'],
    );
  });

  test('pairs a Korean headword with the following gloss line', () {
    final result = VocabNotebookParser.parse('''
시작
Anfang
개시
Eröffnung
''');

    expect(result.pairs, hasLength(2));
    expect(result.pairs.first.korean, '시작');
    expect(result.pairs.first.meaning, 'Anfang');
    expect(result.pairs.last.korean, '개시');
    expect(result.pairs.last.meaning, 'Eröffnung');
  });

  test('does not treat a textbook sentence page as a notebook', () {
    final result = VocabNotebookParser.parse('''
한국에 처음 왔어요.
저는 학생이에요.
어디 가세요?
''');

    expect(result.pairs, isEmpty);
    expect(result.looksLikeNotebook, isFalse);
  });

  test('keeps German glosses that the textbook preprocessor would drop', () {
    final prepared = VocabNotebookParser.prepareText('학교 Schule\nHaus');
    expect(prepared, contains('Schule'));
    expect(prepared, contains('Haus'));
  });

  test('converts pairs into extracted words without inventing new vocab', () {
    final words = VocabNotebookParser.toExtractedWords(
      const <VocabNotebookPair>[
        VocabNotebookPair(korean: '학교', meaning: 'Schule'),
      ],
      translationLanguage: 'de',
    );

    expect(words.single.korean, '학교');
    expect(words.single.translationDe, 'Schule');
    expect(words.single.translationLanguage, 'de');
  });

  test('zips a two-column notebook after OCR reads Korean then German', () {
    final result = VocabNotebookParser.parse('''
학교
학생
시작
개시
Schule
Schüler
Anfang
Eröffnung
''');

    expect(result.looksLikeNotebook, isTrue);
    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      <String>[
        '학교|Schule',
        '학생|Schüler',
        '시작|Anfang',
        '개시|Eröffnung',
      ],
    );
  });

  test('keeps parenthetical glosses and leftover empty Hanja parens', () {
    final result = VocabNotebookParser.parse('''
학교 (Schule)
학생(Schüler)
시작(始作) Anfang
버스 정류장 Bushaltestelle
''');

    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      containsAll(<String>[
        '학교|Schule',
        '학생|Schüler',
        '시작|Anfang',
        '버스 정류장|Bushaltestelle',
      ]),
    );
  });

  test('splits two pairs that OCR glued onto one line', () {
    final result = VocabNotebookParser.parse('학교 Schule 학생 Schüler');
    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      <String>['학교|Schule', '학생|Schüler'],
    );
  });

  test('does not let a wrong OCR hint replace the written notebook gloss', () {
    final document = BookOcrDocument(
      regions: const <BookOcrRegion>[],
      units: <BookOcrUnit>[
        BookOcrUnit(
          id: 'u1',
          role: BookOcrUnitRole.headword,
          korean: '학교',
          bounds: Rect.zero,
          sourceLineIds: const <String>[],
          confidence: 1,
          foreignHints: const <BookOcrForeignHint>[
            BookOcrForeignHint(text: 'wrong', relation: 'inline_gloss'),
          ],
        ),
      ],
    );

    final result = VocabNotebookParser.parse(
      '학교 - Schule',
      document: document,
    );

    expect(result.pairs, hasLength(1));
    expect(result.pairs.single.meaning, 'Schule');
  });

  test('skips a Korean title when zipping two-column leftovers', () {
    final result = VocabNotebookParser.parse('''
단어장
학교
학생
시작
개시
Schule
Schüler
Anfang
Eröffnung
''');

    expect(
      result.pairs.map((pair) => '${pair.korean}|${pair.meaning}'),
      <String>[
        '학교|Schule',
        '학생|Schüler',
        '시작|Anfang',
        '개시|Eröffnung',
      ],
    );
  });
}
