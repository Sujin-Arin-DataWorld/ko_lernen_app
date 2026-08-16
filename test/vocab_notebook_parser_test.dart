import 'package:flutter_test/flutter_test.dart';

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
}
