import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/media_phrase.dart';
import 'package:ko_lernen_app/screens/media_phrase_screen.dart';

void main() {
  test('exact-level selector never sends an A1 greeting to a C learner', () {
    const a1 = MediaPhrase(
      id: 'a1',
      level: 'A1',
      korean: '안녕하세요',
      romanization: '',
      german: 'Hallo',
      english: 'Hello',
      sourceType: 'original',
      sourceStyle: 'dialogue',
    );
    const c1 = MediaPhrase(
      id: 'c1',
      level: 'C1',
      korean: '지표의 범위를 먼저 한정해야 합니다.',
      romanization: '',
      german: 'Zuerst muss die Reichweite der Kennzahl eingegrenzt werden.',
      english: 'The scope of the indicator needs to be limited first.',
      sourceType: 'original',
      sourceStyle: 'debate',
    );

    expect(mediaPhrasesForLevel([a1, c1], 'C1'), [c1]);
    expect(mediaPhrasesForLevel([a1, c1], 'C2'), isEmpty);
  });

  test('the live media asset has exact-level practice for A1 through C2', () {
    final root =
        jsonDecode(File('assets/data/media_phrases.json').readAsStringSync())
            as Map<String, dynamic>;
    final counts = <String, int>{};
    for (final phrase
        in (root['phrases'] as List).cast<Map<String, dynamic>>()) {
      final level = phrase['level'] as String;
      counts[level] = (counts[level] ?? 0) + 1;
    }
    for (final level in const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(counts[level], greaterThanOrEqualTo(8), reason: level);
    }
  });

  test(
    'media practice is reachable from route, Discover, and Practice Hub',
    () {
      expect(
        File('lib/main.dart').readAsStringSync(),
        contains("case '/media_phrases':"),
      );
      expect(
        File('lib/models/discover_catalog.dart').readAsStringSync(),
        contains("id: 'media_phrases'"),
      );
      expect(
        File('lib/screens/practice_hub_screen.dart').readAsStringSync(),
        contains("route: '/media_phrases'"),
      );
    },
  );
}
