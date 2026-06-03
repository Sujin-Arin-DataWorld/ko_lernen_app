import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('learning data integrity', () {
    late Map<String, dynamic> scenarioRoot;
    late List<Map<String, dynamic>> scenarios;
    late List<List<dynamic>> vocabRows;
    late List<List<dynamic>> grammarRows;

    setUpAll(() {
      scenarioRoot =
          jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
              as Map<String, dynamic>;
      scenarios = ((scenarioRoot['scenarios'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      vocabRows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(File('assets/data/korean_vocab.csv').readAsStringSync());
      grammarRows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(File('assets/data/grammar.csv').readAsStringSync());
    });

    test('scenario pack is beta-sized and level-balanced enough', () {
      expect(scenarioRoot['version'], isA<int>());
      expect(scenarios.length, greaterThanOrEqualTo(20));

      final ids = <String>{};
      final levels = <String, int>{};
      for (final scenario in scenarios) {
        final id = scenario['id'] as String? ?? '';
        expect(id, matches(RegExp(r'^[a-z0-9_]+$')));
        expect(ids.add(id), isTrue, reason: 'Duplicate scenario id: $id');

        final level = scenario['level'] as String? ?? '';
        expect(['a1', 'a2', 'b1', 'b2'], contains(level));
        levels[level] = (levels[level] ?? 0) + 1;
      }

      for (final level in ['a1', 'a2', 'b1', 'b2']) {
        expect(levels[level] ?? 0, greaterThan(0), reason: 'No $level content');
      }
    });

    test('scenario text, dialogue, and quest blocks are complete', () {
      const allowedQuestTypes = {
        'hoerverstehen',
        'luecken',
        'uebersetzen',
        'particlePop',
        'batchimDrop',
        'schreiben',
      };

      for (final scenario in scenarios) {
        final id = scenario['id'] as String;
        _expectLocalizedText(scenario['title'], '$id.title');
        _expectLocalizedText(scenario['intro'], '$id.intro');

        final vocab = (scenario['vocab'] as List?) ?? const [];
        final dialog = (scenario['dialog'] as List?) ?? const [];
        final quests = (scenario['quests'] as List?) ?? const [];
        expect(vocab.length, greaterThanOrEqualTo(6), reason: '$id vocab');
        expect(dialog.length, greaterThanOrEqualTo(6), reason: '$id dialog');
        expect(quests.length, greaterThanOrEqualTo(3), reason: '$id quests');

        for (final line in dialog.cast<Map<String, dynamic>>()) {
          expect(
            (line['speaker'] as String? ?? ''),
            isNotEmpty,
            reason: '$id dialog speaker',
          );
          expect(
            (line['ko'] as String? ?? ''),
            isNotEmpty,
            reason: '$id dialog ko',
          );
          expect(
            (line['de'] as String? ?? ''),
            isNotEmpty,
            reason: '$id dialog de',
          );
          expect(
            (line['en'] as String? ?? ''),
            isNotEmpty,
            reason: '$id dialog en',
          );
        }

        final grammarBlock = scenario['grammarBlock'];
        expect(
          grammarBlock,
          isA<Map<String, dynamic>>(),
          reason: '$id grammarBlock',
        );
        _expectLocalizedText(
          (grammarBlock as Map<String, dynamic>)['title'],
          '$id.grammarBlock.title',
        );
        _expectLocalizedText(
          grammarBlock['explanation'],
          '$id.grammarBlock.explanation',
        );

        for (final quest in quests.cast<Map<String, dynamic>>()) {
          final type = quest['type'] as String? ?? '';
          expect(allowedQuestTypes, contains(type), reason: '$id quest type');
          final data = (quest['data'] as Map?)?.cast<String, dynamic>() ?? {};
          _expectQuestData(type, data, '$id.$type');
        }
      }
    });

    test('csv packs keep required shape and unique primary keys', () {
      expect(vocabRows.length - 1, greaterThanOrEqualTo(500));
      expect(grammarRows.length - 1, greaterThanOrEqualTo(80));

      _expectHeader(vocabRows.first, const [
        'korean',
        'romanization',
        'german',
        'level',
        'pos_de',
        'example_korean',
        'example_german',
        'topic',
      ]);
      _expectHeader(grammarRows.first, const [
        'pattern',
        'level',
        'type_de',
        'explanation_de',
        'example_korean',
        'example_german',
        'note',
      ]);

      final vocabKeys = <String>{};
      for (final row in vocabRows.skip(1)) {
        expect(row.length, greaterThanOrEqualTo(8));
        expect(
          vocabKeys.add(row[0].toString()),
          isTrue,
          reason: 'Duplicate vocab key: ${row[0]}',
        );
        expect(['A1', 'A2', 'B1', 'B2'], contains(row[3].toString()));
        for (final i in [0, 1, 2, 3, 4, 5, 6, 7]) {
          expect(row[i].toString().trim(), isNotEmpty);
        }
      }

      final grammarKeys = <String>{};
      for (final row in grammarRows.skip(1)) {
        expect(row.length, greaterThanOrEqualTo(7));
        expect(
          grammarKeys.add(row[0].toString()),
          isTrue,
          reason: 'Duplicate grammar key: ${row[0]}',
        );
        expect(['A1', 'A2', 'B1', 'B2'], contains(row[1].toString()));
        for (final i in [0, 1, 2, 3, 4, 5]) {
          expect(row[i].toString().trim(), isNotEmpty);
        }
      }
    });
  });

  group('asset references', () {
    test('literal assets referenced from lib exist on disk', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final assetPattern = RegExp(r'''['"]((?:assets/)[^'"]+)['"]''');

      // 의도적으로 아직 없는 자산 — 런타임에서 폴백 처리됨. 생기면 여기서 제거.
      const pending = <String>{
        // Rive 리그 제작 대기. 없으면 TigerStageRive가 프레임 TigerStage로 폴백.
        'assets/rive/tiger.riv',
      };

      final missing = <String>[];
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final match in assetPattern.allMatches(source)) {
          final asset = match.group(1)!;
          if (asset.contains(r'$') || asset.endsWith('/')) continue;
          if (pending.contains(asset)) continue;
          if (!File(asset).existsSync()) {
            missing.add('${file.path}: $asset');
          }
        }
      }

      expect(missing, isEmpty, reason: missing.join('\n'));
    });
  });

  group('kkeunmari data integrity', () {
    test('word-chain pool has consistent syllable metadata', () {
      final root =
          jsonDecode(File('assets/data/kkeunmari_pool.json').readAsStringSync())
              as Map<String, dynamic>;
      final words = ((root['words'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();

      expect(words.length, greaterThanOrEqualTo(200));

      final seen = <String>{};
      for (final item in words) {
        final word = item['word'] as String? ?? '';
        expect(word, isNotEmpty);
        expect(seen.add(word), isTrue, reason: 'Duplicate word: $word');

        final runes = word.runes.toList();
        expect(item['first'], String.fromCharCode(runes.first));
        expect(item['last'], String.fromCharCode(runes.last));
        expect(item['next_count'], isA<int>());
        expect(item['is_dead_end'], isA<bool>());
        if (item['is_dead_end'] == true) {
          expect(item['next_count'], 0, reason: '$word marked dead-end');
        }
      }
    });
  });
}

void _expectLocalizedText(Object? value, String label) {
  expect(value, isA<Map<String, dynamic>>(), reason: label);
  final text = (value as Map<String, dynamic>);
  expect((text['de'] as String? ?? '').trim(), isNotEmpty, reason: '$label.de');
  expect((text['en'] as String? ?? '').trim(), isNotEmpty, reason: '$label.en');
}

void _expectHeader(List<dynamic> actual, List<String> expected) {
  expect(
    actual.take(expected.length).map((e) => e.toString()).toList(),
    expected,
  );
}

void _expectQuestData(String type, Map<String, dynamic> data, String label) {
  switch (type) {
    case 'hoerverstehen':
      expect(
        (data['audioKo'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.audioKo',
      );
      _expectLocalizedOptions(data['options'], label);
      _expectCorrectIndex(data['correctIndex'], data['options'], label);
    case 'uebersetzen':
      expect(
        (data['promptDe'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.promptDe',
      );
      expect(
        (data['promptEn'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.promptEn',
      );
      _expectKoreanOptions(data['options'], label);
      _expectCorrectIndex(data['correctIndex'], data['options'], label);
    case 'luecken':
      expect(
        (data['sentence'] as String? ?? ''),
        contains('___'),
        reason: '$label.sentence',
      );
      _expectStringOptions(data['options'], label);
      _expectCorrectIndex(data['correctIndex'], data['options'], label);
    case 'particlePop':
      expect(
        ((data['prefix'] as String? ?? '') + (data['suffix'] as String? ?? ''))
            .trim(),
        isNotEmpty,
        reason: '$label.prefix/suffix',
      );
      _expectStringOptions(data['options'], label, min: 4);
      _expectCorrectIndex(data['correctIndex'], data['options'], label);
      expect(
        (data['explanationDe'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.explanationDe',
      );
      expect(
        (data['explanationEn'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.explanationEn',
      );
    case 'batchimDrop':
      expect(
        (data['audioKo'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.audioKo',
      );
      final target = data['targetWord'] as String? ?? '';
      expect(target.trim(), isNotEmpty, reason: '$label.targetWord');
      final index = (data['targetSyllableIndex'] as num?)?.toInt() ?? -1;
      expect(
        index,
        inInclusiveRange(0, target.runes.length - 1),
        reason: '$label.targetSyllableIndex',
      );
      _expectStringOptions(data['options'], label);
      _expectCorrectIndex(data['correctIndex'], data['options'], label);
      expect(
        (data['explanationDe'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.explanationDe',
      );
      expect(
        (data['explanationEn'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.explanationEn',
      );
    case 'schreiben':
      expect(data, isNotEmpty, reason: label);
  }
}

void _expectCorrectIndex(
  Object? indexValue,
  Object? optionsValue,
  String label,
) {
  final options = (optionsValue as List?) ?? const [];
  final index = (indexValue as num?)?.toInt() ?? -1;
  expect(
    index,
    inInclusiveRange(0, options.length - 1),
    reason: '$label.correctIndex',
  );
}

void _expectLocalizedOptions(Object? value, String label) {
  final options = (value as List?) ?? const [];
  expect(options.length, greaterThanOrEqualTo(4), reason: '$label.options');
  for (final option in options.cast<Map<String, dynamic>>()) {
    expect((option['de'] as String? ?? '').trim(), isNotEmpty);
    expect((option['en'] as String? ?? '').trim(), isNotEmpty);
  }
}

void _expectKoreanOptions(Object? value, String label) {
  final options = (value as List?) ?? const [];
  expect(options.length, greaterThanOrEqualTo(4), reason: '$label.options');
  for (final option in options.cast<Map<String, dynamic>>()) {
    expect((option['ko'] as String? ?? '').trim(), isNotEmpty);
  }
}

void _expectStringOptions(Object? value, String label, {int min = 4}) {
  final options = (value as List?) ?? const [];
  expect(options.length, greaterThanOrEqualTo(min), reason: '$label.options');
  for (final option in options) {
    expect(option.toString().trim(), isNotEmpty);
  }
}
