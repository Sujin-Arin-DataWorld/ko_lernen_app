// Satz-Bauen Arcade: Daten-Integrität von assets/data/satz_sentences.json
// + SatzSentence-Logik. Daten aus muttersprachlich geprüften Beispielsätzen
// (tools/content_factory/build_satzbauen.py).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';

const _levels = {'a1', 'a2', 'b1', 'b2', 'c1', 'c2'};

void main() {
  group('satz_sentences.json integrity', () {
    final raw = File('assets/data/satz_sentences.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    test('healthy volume across all levels', () {
      expect(items.length, greaterThan(80));
      final byLevel = <String, int>{};
      for (final it in items) {
        byLevel[it['level'] as String] =
            (byLevel[it['level'] as String] ?? 0) + 1;
      }
      for (final lv in _levels) {
        expect(byLevel[lv] ?? 0, greaterThan(0), reason: 'no items for $lv');
      }
    });

    test('every item satisfies the build contract', () {
      String strip(String t) =>
          t.replaceAll(RegExp(r'[ !?.,~()]'), '').replaceAll('…', '');
      for (final it in items) {
        final level = it['level'] as String;
        final target = it['targetKo'] as String;
        final de = it['promptDe'] as String;
        final distractors = (it['distractors'] as List).cast<String>();

        expect(_levels.contains(level), isTrue, reason: 'bad level: $level');
        expect(
          target.split(' ').length,
          greaterThanOrEqualTo(3),
          reason: 'too short to build: $target',
        );
        expect(de.trim(), isNotEmpty, reason: 'no translation: $target');
        expect(
          distractors,
          hasLength(2),
          reason: 'need 2 distractors: $target',
        );
        expect(
          distractors.toSet(),
          hasLength(2),
          reason: 'duplicate distractors: $target',
        );
        // Distraktoren dürfen nicht im Zielsatz vorkommen (sonst korrekt).
        final own = target.split(' ').map(strip).toSet();
        for (final d in distractors) {
          expect(
            own.contains(strip(d)),
            isFalse,
            reason: 'distractor "$d" is part of target: $target',
          );
        }
      }
    });
  });

  group('SatzSentence logic', () {
    final s = SatzSentence.fromJson(const {
      'level': 'A1',
      'targetKo': '저는 학생 이에요',
      'promptDe': 'Ich bin Student.',
      'promptEn': 'I am a student.',
      'distractors': ['가방', '오늘'],
    });

    test('fromJson lowercases level and parses', () {
      expect(s.level, 'a1');
      expect(s.distractors, hasLength(2));
    });

    test('toQuestData exposes the keys SatzBauenQuest reads', () {
      final d = s.toQuestData();
      expect(d['targetKo'], '저는 학생 이에요');
      expect(d['promptDe'], 'Ich bin Student.');
      expect(d['audioKo'], '저는 학생 이에요'); // TTS = Zielsatz
      expect(d['distractors'], ['가방', '오늘']);
    });

    test('filter by level', () {
      final all = [
        s,
        SatzSentence.fromJson(const {
          'level': 'b1',
          'targetKo': 'a b c',
          'promptDe': 'x',
          'promptEn': 'x',
          'distractors': ['d', 'e'],
        }),
      ];
      expect(SatzLoader.filter(all, 'a1'), hasLength(1));
      expect(SatzLoader.filter(all, null), hasLength(2));
    });
  });
}
