import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _shippedLearnerFiles = <String>[
  'assets/data/korean_vocab.csv',
  'assets/data/grammar.csv',
  'assets/data/smalltalk.json',
  'assets/data/scenarios.json',
  'assets/data/cloze.json',
  'assets/data/satz_sentences.json',
  'assets/data/pronunciation_phrases.json',
];

const _generatorFiles = <String>[
  'tools/content_factory/lexicon/partner_family_packs.py',
  'tools/content_factory/lexicon/partner_family_rest.py',
  'tools/content_factory/lexicon/partner_family_rest2.py',
  'tools/content_factory/lexicon/partner_family_advanced.py',
  'tools/content_factory/build_batch_07_partner_family.py',
  'tools/content_factory/build_batch_08_partner_family_scenarios.py',
  'tools/content_factory/add_phrasebook_smalltalk.py',
  'tools/content_factory/build_productive_assessments.py',
];

final _textbookNames = <RegExp>[
  RegExp('민수'),
  RegExp(r'\bMinsu\b'),
  RegExp('철수'),
  RegExp('영희'),
  RegExp('안나'),
  RegExp(r'\bAnna\b'),
  RegExp(r'010-1234-5678'),
];

final _textbookPhrases = <RegExp>[
  RegExp(r'studying about', caseSensitive: false),
  RegExp('Classic ice-breaker'),
  RegExp('Vorstellungen Pflicht'),
  RegExp('Laecheln'),
  RegExp('Saetze'),
  RegExp('oeffnete'),
  RegExp(r'\bliess\b'),
  RegExp('다양한 사회에 살아요'),
  RegExp(r'May I speak with Hyunwoo'),
  RegExp('scope of responsibility'),
  RegExp('I said it is delicious at every plate'),
  RegExp('double-bow angle'),
  RegExp('drilled the New Year bow angle'),
];

final _spokenIAm = RegExp(r'\bI am\b');
final _spokenIWill = RegExp(r'\bI will\b');

void main() {
  test('shipped learner copy keeps textbook names and calques out', () {
    final hits = <String>[];
    for (final path in _shippedLearnerFiles) {
      hits.addAll(_scanFile(path, includeNames: true, includePhrases: true));
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('content factory sources cannot regenerate Minsu or Anna', () {
    final hits = <String>[];
    for (final path in _generatorFiles) {
      hits.addAll(_scanFile(path, includeNames: true, includePhrases: true));
    }
    for (final file in Directory('tools/content_factory/review').listSync()) {
      if (file is File && file.path.contains('partner_family')) {
        hits.addAll(
          _scanFile(file.path, includeNames: true, includePhrases: true),
        );
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('scenario dialogue does not use uncontracted I am / I will', () {
    final root =
        jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
            as Map<String, dynamic>;
    final hits = <String>[];
    for (final scenario in (root['scenarios'] as List).cast<Map<String, dynamic>>()) {
      final id = scenario['id'] as String? ?? 'unknown';
      for (final line
          in ((scenario['dialog'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        _collectSpoken(hits, '$id.dialog', line['en']);
      }
      for (final quest
          in ((scenario['quests'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        final data = quest['data'];
        if (data is! Map<String, dynamic>) {
          continue;
        }
        _collectSpoken(hits, '$id.${quest['id']}.promptEn', data['promptEn']);
        final options = data['options'];
        if (options is List) {
          for (final option in options) {
            if (option is Map<String, dynamic>) {
              _collectSpoken(hits, '$id.${quest['id']}.option', option['en']);
            }
          }
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

List<String> _scanFile(
  String path, {
  required bool includeNames,
  required bool includePhrases,
}) {
  final text = File(path).readAsStringSync();
  final hits = <String>[];
  if (includeNames) {
    for (final pattern in _textbookNames) {
      for (final match in pattern.allMatches(text)) {
        hits.add('$path: ${match.group(0)}');
      }
    }
  }
  if (includePhrases) {
    for (final pattern in _textbookPhrases) {
      for (final match in pattern.allMatches(text)) {
        hits.add('$path: ${match.group(0)}');
      }
    }
  }
  return hits;
}

void _collectSpoken(List<String> hits, String label, Object? value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) {
    return;
  }
  if (_spokenIAm.hasMatch(text)) {
    hits.add('$label I am: $text');
  }
  if (_spokenIWill.hasMatch(text)) {
    hits.add('$label I will: $text');
  }
}
