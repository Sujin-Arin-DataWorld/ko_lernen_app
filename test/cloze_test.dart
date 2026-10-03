// Cloze game: data-integrity of assets/data/cloze.json + pure ClozeItem logic.
//
// The data is generated from native-reviewed vocab example sentences
// (tools/content_factory/build_cloze.py) — these tests guard the contract the
// game screen relies on (blank present, 3 distractors, answer not among them).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';

const _blank = '＿'; // full-width underscore used as the gap marker
const _levels = {'a1', 'a2', 'b1', 'b2', 'c1', 'c2'};

typedef _LexicalAnswerKey = ({
  String id,
  String sourceVocabId,
  String answer,
  String fullKo,
});

// These corpus-matched lexical targets are price and month vocabulary, with
// contextual meaning cues and distinct distractors, rather than number guesses.
// Their complete source keys keep this exception from accepting new items.
const _singleSyllableLexicalCases = <_LexicalAnswerKey>{
  (
    id: 'cloze_a1_0422',
    sourceVocabId: 'vocab_a1_0488',
    answer: '값',
    fullKo: '이 신발 값은 싸요.',
  ),
  (
    id: 'cloze_a1_0638',
    sourceVocabId: 'vocab_a1_0704',
    answer: '달',
    fullKo: '일 년은 열두 달이에요.',
  ),
};

_LexicalAnswerKey _lexicalAnswerKey(Map<String, dynamic> item) => (
  id: item['id'] as String? ?? '',
  sourceVocabId: item['sourceVocabId'] as String? ?? '',
  answer: item['answer'] as String? ?? '',
  fullKo: item['fullKo'] as String? ?? '',
);

bool _meetsAnswerLengthContract(Map<String, dynamic> item) {
  final syllables = (item['answer'] as String).runes
      .where((r) => r >= 0xAC00 && r <= 0xD7A3)
      .length;
  return syllables >= 2 ||
      _singleSyllableLexicalCases.contains(_lexicalAnswerKey(item));
}

void main() {
  group('cloze.json integrity', () {
    final raw = File('assets/data/cloze.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    test('has a healthy number of items across all levels', () {
      expect(items.length, greaterThan(100));
      final byLevel = <String, int>{};
      for (final it in items) {
        byLevel[it['level'] as String] =
            (byLevel[it['level'] as String] ?? 0) + 1;
      }
      for (final lv in _levels) {
        expect(byLevel[lv] ?? 0, greaterThan(0), reason: 'no items for $lv');
      }
    });

    test('every item satisfies the game contract', () {
      for (final it in items) {
        final level = it['level'] as String;
        final sentence = it['sentenceKo'] as String;
        final answer = it['answer'] as String;
        final de = it['de'] as String;
        final distractors = (it['distractors'] as List).cast<String>();
        final acceptedVariants =
            (it['acceptedVariants'] as List?)?.cast<String>() ?? const [];

        expect(_levels.contains(level), isTrue, reason: 'bad level: $level');
        expect(
          sentence.contains(_blank),
          isTrue,
          reason: 'no blank in: $sentence',
        );
        expect(answer.trim(), isNotEmpty);
        expect(de.trim(), isNotEmpty, reason: 'no translation for: $answer');
        expect(distractors.length, 3, reason: 'need 3 distractors: $answer');
        expect(
          distractors.contains(answer),
          isFalse,
          reason: 'answer leaked into distractors: $answer',
        );
        expect(
          distractors.toSet().length,
          3,
          reason: 'duplicate distractors: $answer',
        );
        expect(
          acceptedVariants.every((variant) => variant == variant.trim()),
          isTrue,
          reason: 'accepted variant must be trimmed: $answer',
        );
        expect(
          acceptedVariants.every((variant) => variant.isNotEmpty),
          isTrue,
          reason: 'accepted variant must not be empty: $answer',
        );
        expect(
          acceptedVariants.toSet().length,
          acceptedVariants.length,
          reason: 'duplicate accepted variants: $answer',
        );
        expect(
          acceptedVariants.contains(answer),
          isFalse,
          reason: 'canonical answer duplicated as accepted variant: $answer',
        );
        expect(
          acceptedVariants.toSet().intersection(distractors.toSet()),
          isEmpty,
          reason: 'accepted variant leaked into distractors: $answer',
        );
        // Keep the general two-syllable gate; only the exact lexical cases
        // above have corpus-specific evidence for a shorter answer.
        expect(
          _meetsAnswerLengthContract(it),
          isTrue,
          reason: 'unreviewed single-syllable answer: $answer',
        );
      }
    });
  });

  group('single-syllable lexical answer boundaries', () {
    test('the two corpus cases retain their exact source fields', () {
      final raw =
          jsonDecode(File('assets/data/cloze.json').readAsStringSync())
              as Map<String, dynamic>;
      final items = (raw['items'] as List).cast<Map<String, dynamic>>();
      for (final key in _singleSyllableLexicalCases) {
        final item = items.singleWhere((item) => item['id'] == key.id);
        expect(_lexicalAnswerKey(item), key);
      }
    });

    test('any source key change expires the lexical exception', () {
      for (final key in _singleSyllableLexicalCases) {
        final item = <String, dynamic>{
          'id': key.id,
          'sourceVocabId': key.sourceVocabId,
          'answer': key.answer,
          'fullKo': key.fullKo,
        };
        expect(_meetsAnswerLengthContract(item), isTrue);
        for (final field in item.keys) {
          final changed = Map<String, dynamic>.of(item);
          changed[field] = field == 'answer' ? '일' : '${changed[field]}!';
          expect(_meetsAnswerLengthContract(changed), isFalse, reason: field);
        }
      }
    });

    test('unreviewed numbers and new lexical items remain rejected', () {
      for (final answer in ['일', '값', '달']) {
        expect(
          _meetsAnswerLengthContract({
            'id': 'unreviewed-cloze-fixture',
            'sourceVocabId': 'unreviewed-vocab-fixture',
            'answer': answer,
            'fullKo': '',
          }),
          isFalse,
        );
      }
    });
  });

  group('ClozeItem logic', () {
    final item = ClozeItem.fromJson(const {
      'level': 'A1',
      'sentenceKo': '저는 ＿＿＿이에요.',
      'answer': '학생',
      'fullKo': '저는 학생이에요.',
      'de': 'Ich bin Student.',
      'en': 'I am a student.',
      'distractors': ['가족', '거기', '계란'],
      'acceptedVariants': ['학생이요'],
    });

    test('fromJson lowercases level and parses fields', () {
      expect(item.level, 'a1');
      expect(item.answer, '학생');
      expect(item.distractors, hasLength(3));
      expect(item.acceptedVariants, ['학생이요']);
      expect(item.acceptedAnswers, {'학생', '학생이요'});
      expect(item.accepts('학생'), isTrue);
      expect(item.accepts('학생이요'), isTrue);
      expect(item.accepts('가족'), isFalse);
    });

    test('options() returns answer + 3 distractors, all unique', () {
      final opts = item.options(7);
      expect(opts, hasLength(4));
      expect(opts.toSet(), hasLength(4));
      expect(opts.contains('학생'), isTrue);
      expect(opts.contains('학생이요'), isFalse);
    });

    test('options() shuffle is deterministic for a given seed', () {
      expect(item.options(42), item.options(42));
    });

    test('meaning() falls back to German, uses English when lang=en', () {
      expect(item.meaning('de'), 'Ich bin Student.');
      expect(item.meaning('en'), 'I am a student.');
    });

    test('legacy items keep a canonical-only acceptance set', () {
      final legacy = ClozeItem.fromJson(const {
        'level': 'A1',
        'sentenceKo': '저는 ＿＿＿이에요.',
        'answer': '학생',
        'fullKo': '저는 학생이에요.',
        'de': 'Ich bin Student.',
        'en': 'I am a student.',
        'distractors': ['가족', '거기', '계란'],
      });

      expect(legacy.acceptedVariants, isEmpty);
      expect(legacy.acceptedAnswers, {'학생'});
      expect(legacy.options(7), hasLength(4));
      expect(
        legacy.id,
        item.id,
        reason: 'accepted variants must not change ID',
      );
    });
  });
}
