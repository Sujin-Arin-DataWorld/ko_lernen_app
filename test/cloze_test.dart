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
        // No 1-syllable answers (numbers/counters) — unfair gap (review #1).
        final syll = answer.runes
            .where((r) => r >= 0xAC00 && r <= 0xD7A3)
            .length;
        expect(
          syll,
          greaterThanOrEqualTo(2),
          reason: 'single-syllable answer is unfair: $answer',
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
    });

    test('fromJson lowercases level and parses fields', () {
      expect(item.level, 'a1');
      expect(item.answer, '학생');
      expect(item.distractors, hasLength(3));
    });

    test('options() returns answer + 3 distractors, all unique', () {
      final opts = item.options(7);
      expect(opts, hasLength(4));
      expect(opts.toSet(), hasLength(4));
      expect(opts.contains('학생'), isTrue);
    });

    test('options() shuffle is deterministic for a given seed', () {
      expect(item.options(42), item.options(42));
    });

    test('meaning() falls back to German, uses English when lang=en', () {
      expect(item.meaning('de'), 'Ich bin Student.');
      expect(item.meaning('en'), 'I am a student.');
    });
  });
}
