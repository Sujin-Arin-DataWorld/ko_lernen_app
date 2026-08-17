import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/scenario_json.dart';

const _shippedLearnerFiles = <String>[
  'assets/data/korean_vocab.csv',
  'assets/data/grammar.csv',
  'assets/data/smalltalk.json',
  'assets/data/scenarios_a1.json',
  'assets/data/scenarios_a2.json',
  'assets/data/scenarios_b1.json',
  'assets/data/scenarios_b2.json',
  'assets/data/scenarios_c1.json',
  'assets/data/scenarios_c2.json',
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
        allScenarioRoot();
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

  // 캐스트 규칙: 남자 NPC = 현우, 학습자(여자) = 레나. 학습자가 자기를 현우라고
  // 소개하면 "새 동료 현우를 만난다"는 지문과 동명이인이 된다 — `[이름]` 자리를
  // 현우로 굳힌 뒤 NPC 가 민수→현우로 개명되며 생긴 2026-08-17 회귀.
  // 3인칭 언급(`현우 씨가 늦는대요`)은 정상이므로 자기소개 형태만 막는다.
  test('learner lines never introduce themselves with the NPC name', () {
    final root =
        allScenarioRoot();
    final selfIntro = RegExp(r'(저는|나는|제 이름은|이름이)\s*현우');
    final hits = <String>[];
    for (final scenario
        in (root['scenarios'] as List).cast<Map<String, dynamic>>()) {
      final id = scenario['id'] as String? ?? 'unknown';
      for (final line
          in ((scenario['dialog'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()) {
        if (line['speaker'] != 'user') {
          continue;
        }
        final ko = line['ko'] as String? ?? '';
        if (selfIntro.hasMatch(ko)) {
          hits.add('$id.dialog: $ko');
        }
      }
      // particlePop 은 prefix + 정답 + suffix 를 이어 붙여 학습자가 말한다.
      for (final quest
          in ((scenario['quests'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()) {
        final data = quest['data'];
        if (data is! Map<String, dynamic>) {
          continue;
        }
        final options = (data['options'] as List?) ?? const [];
        final correctIndex = (data['correctIndex'] as num?)?.toInt() ?? 0;
        final answer =
            correctIndex >= 0 &&
                correctIndex < options.length &&
                options[correctIndex] is String
            ? options[correctIndex] as String
            : '';
        final spoken = '${data['prefix'] ?? ''}$answer${data['suffix'] ?? ''}';
        if (selfIntro.hasMatch(spoken)) {
          hits.add('$id.${quest['id']}: $spoken');
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
