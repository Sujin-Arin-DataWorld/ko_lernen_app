import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/custom_pack_import_service.dart';

void main() {
  test('English CSV keeps legacy meaning slot and English provenance', () {
    final words = parseCustomPackCsvWords(
      '학생,student,저는 학생이에요.\n책,book',
      translationLanguage: 'en',
    );

    expect(words, hasLength(2));
    expect(words.first.translationDe, 'student');
    expect(words.first.translationEn, 'student');
    expect(words.first.translationLanguage, 'en');
    expect(words.first.exampleKorean, '저는 학생이에요.');
  });

  test('German CSV keeps German provenance and an empty English slot', () {
    final word = parseCustomPackCsvWords(
      '학생,Schüler',
      translationLanguage: 'de',
    ).single;

    expect(word.translationDe, 'Schüler');
    expect(word.translationEn, isEmpty);
    expect(word.translationLanguage, 'de');
  });

  test('manual and auto-filled English edits mirror the legacy slot', () {
    final manual = buildCustomPackEditedWord(
      korean: '학생',
      meaning: 'student',
      exampleKorean: '',
      definitionKo: '',
      translationLanguage: 'en',
    );
    final edited = buildCustomPackEditedWord(
      existing: ExtractedWord.manual(
        korean: '학생',
        translationDe: 'Schüler',
        imagePath: 'word:photo.jpg',
      ),
      korean: '학생',
      meaning: 'student',
      exampleKorean: '저는 학생이에요.',
      definitionKo: '학교에 다니며 공부하는 사람.',
      translationLanguage: 'en',
    );

    for (final word in [manual, edited]) {
      expect(word.translationDe, 'student');
      expect(word.translationEn, 'student');
      expect(word.translationLanguage, 'en');
    }
    expect(edited.imagePath, 'word:photo.jpg');
  });

  test('manual and CSV words remove unsupported and format controls', () {
    final manual = buildCustomPackEditedWord(
      korean: '안녕\u202eمرحبا하세요',
      meaning: 'stu\u0085dent مرحبا',
      exampleKorean: '저는\u200b 학생مرحبا이에요.',
      definitionKo: '학습자\u202e مرحبا',
      translationLanguage: 'en',
    );
    final csv = parseCustomPackCsvWords(
      '안녕\u202eمرحبا하세요,stu\u0085dent مرحبا,저는\u200b 학생مرحبا이에요.',
      translationLanguage: 'en',
    ).single;

    for (final word in [manual, csv]) {
      final serialized = word.toPortableJson().values.join(' ');
      expect(serialized, isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
      expect(serialized, isNot(contains('\u202e')));
      expect(serialized, isNot(contains('\u200b')));
      expect(serialized, isNot(contains('\u0085')));
      expect(word.translationLanguage, 'en');
      expect(word.translationEn, word.translationDe);
    }
  });

  test('CSV skips unsupported-only rows and caps imported row count', () {
    final rows = <String>['مرحبا,hello'];
    rows.addAll(
      List<String>.generate(
        maxCustomPackCsvRows + 20,
        (index) => '단어$index,meaning$index',
      ),
    );

    final words = parseCustomPackCsvWords(
      rows.join('\n'),
      translationLanguage: 'en',
    );

    expect(words, hasLength(maxCustomPackCsvRows - 1));
    expect(words.every((word) => word.korean.isNotEmpty), isTrue);
  });

  test('manual fields are capped at their storage boundaries', () {
    final word = ExtractedWord.manual(
      korean: List<String>.filled(100, '가').join(),
      translationDe: List<String>.filled(300, 'a').join(),
      exampleKorean: List<String>.filled(600, '나').join(),
      definitionKo: List<String>.filled(600, '다').join(),
    );

    expect(word.korean.runes, hasLength(maxExtractedWordKoreanCharacters));
    expect(
      word.translationDe.runes,
      hasLength(maxExtractedWordMeaningCharacters),
    );
    expect(
      word.exampleKorean.runes,
      hasLength(maxExtractedWordExampleCharacters),
    );
    expect(
      word.definitionKo.runes,
      hasLength(maxExtractedWordDefinitionCharacters),
    );
  });
}
