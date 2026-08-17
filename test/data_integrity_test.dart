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
      vocabRows = _parseCsv(
        File('assets/data/korean_vocab.csv').readAsStringSync(),
      );
      grammarRows = _parseCsv(
        File('assets/data/grammar.csv').readAsStringSync(),
      );
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
        expect(['a1', 'a2', 'b1', 'b2', 'c1', 'c2'], contains(level));
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
        'satzBauen',
        'diktat',
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
        'type_en',
        'explanation_en',
        'example_en',
        'note_en',
        'id',
        'quiz_focus_de',
        'quiz_focus_en',
        'quiz_enabled',
        'quiz_distractor_ids',
      ]);

      final vocabKeys = <String>{};
      for (final row in vocabRows.skip(1)) {
        expect(row.length, greaterThanOrEqualTo(8));
        expect(
          vocabKeys.add(row[0].toString()),
          isTrue,
          reason: 'Duplicate vocab key: ${row[0]}',
        );
        expect(
          ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
          contains(row[3].toString()),
        );
        for (final i in [0, 1, 2, 3, 4, 5, 6, 7]) {
          expect(row[i].toString().trim(), isNotEmpty);
        }
      }

      final grammarKeys = <String>{};
      final grammarById = <String, List<dynamic>>{};
      for (final row in grammarRows.skip(1)) {
        expect(row.length, 16);
        expect(
          grammarKeys.add(row[11].toString()),
          isTrue,
          reason: 'Duplicate grammar id: ${row[11]}',
        );
        grammarById[row[11].toString()] = row;
        expect(
          ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
          contains(row[1].toString()),
        );
        for (final i in Iterable<int>.generate(15)) {
          expect(row[i].toString().trim(), isNotEmpty);
        }
        expect(
          _occurrences(row[5].toString(), row[12].toString()),
          1,
          reason: 'quiz_focus_de must occur once: ${row[11]}',
        );
        expect(
          _occurrences(row[9].toString(), row[13].toString()),
          1,
          reason: 'quiz_focus_en must occur once: ${row[11]}',
        );
        expect(
          ['true', 'false'],
          contains(row[14].toString()),
          reason: 'quiz_enabled must be explicit: ${row[11]}',
        );
        if (row[14].toString() == 'true') {
          final distractors = row[15]
              .toString()
              .split('|')
              .where((id) => id.trim().isNotEmpty)
              .toList(growable: false);
          expect(
            distractors,
            hasLength(3),
            reason:
                'enabled grammar needs three authored distractors: ${row[11]}',
          );
          expect(
            distractors.toSet(),
            hasLength(3),
            reason: 'distractors must be unique: ${row[11]}',
          );
          expect(
            distractors,
            isNot(contains(row[11].toString())),
            reason: 'target cannot distract itself: ${row[11]}',
          );
        } else {
          expect(
            row[15].toString().trim(),
            isEmpty,
            reason: 'disabled grammar must not expose options: ${row[11]}',
          );
        }
      }

      for (final row in grammarRows.skip(1)) {
        if (row[14].toString() != 'true') {
          continue;
        }
        for (final distractorId
            in row[15]
                .toString()
                .split('|')
                .where((id) => id.trim().isNotEmpty)) {
          final distractor = grammarById[distractorId];
          expect(
            distractor,
            isNotNull,
            reason: 'unknown authored distractor $distractorId for ${row[11]}',
          );
          expect(
            distractor![1].toString(),
            row[1].toString(),
            reason: 'distractor must stay same-level: ${row[11]}',
          );
          expect(
            distractor[14].toString(),
            'true',
            reason: 'disabled grammar cannot be an option: ${row[11]}',
          );
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
      // 2026-08-06: Rive 리그(tiger.riv) 대기 항목 제거 — TigerStageRive/
      // TigerStage 프레임 경로를 통째로 폐지해 대기할 자산 자체가 없어졌다.
      const pending = <String>{};

      final missing = <String>[];
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final match in assetPattern.allMatches(source)) {
          var asset = match.group(1)!;
          // 보간 문자열('$_base/x.mp4')을 통째로 건너뛰면 안 된다 — 이 스킵
          // 때문에 CharacterClips.tigerRoarSeatedBonus 가 존재하지 않는 파일을
          // 가리킨 채 몇 세션을 통과했다(2026-07-31 발견). 같은 파일에서
          // 베이스 상수를 찾아 치환한 뒤 검사한다.
          if (asset.contains(r'$')) {
            final resolved = _resolveBase(asset, source);
            if (resolved == null) continue; // 베이스를 못 찾으면 종전대로 스킵
            asset = resolved;
          }
          if (asset.endsWith('/')) continue;
          if (pending.contains(asset)) continue;
          // A bare base-directory constant (e.g. CharacterClips._base =
          // 'assets/video/character', joined with a filename at use-site) is a
          // valid on-disk reference even though it is not itself a file.
          if (!File(asset).existsSync() && !Directory(asset).existsSync()) {
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

List<List<dynamic>> _parseCsv(String raw) {
  final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(normalized);
}

void _expectHeader(List<dynamic> actual, List<String> expected) {
  expect(
    actual.take(expected.length).map((e) => e.toString()).toList(),
    expected,
  );
}

int _occurrences(String source, String needle) {
  if (needle.isEmpty) {
    return 0;
  }
  var count = 0;
  var start = 0;
  while (true) {
    final found = source.indexOf(needle, start);
    if (found < 0) {
      return count;
    }
    count++;
    start = found + needle.length;
  }
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
    case 'satzBauen':
      expect(
        (data['targetKo'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.targetKo',
      );
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
      expect(
        data['distractors'],
        isA<List<dynamic>>(),
        reason: '$label.distractors',
      );
    case 'diktat':
      expect(
        (data['targetKo'] as String? ?? '').trim(),
        isNotEmpty,
        reason: '$label.targetKo',
      );
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

/// `'$_base/tiger_roar.mp4'` 처럼 같은 파일 안의 베이스 상수를 참조하는
/// 보간 자산 경로를 실제 경로로 푼다. 베이스를 못 찾으면 `null`.
///
/// 지원 형태: `static const String _base = 'assets/...';` (선행 `_` 유무 무관)
String? _resolveBase(String raw, String source) {
  final ref = RegExp(r'\$\{?(\w+)\}?').firstMatch(raw);
  if (ref == null) return null;
  final name = ref.group(1)!;
  final decl = RegExp(
    "(?:static\\s+)?const\\s+String\\s+$name\\s*=\\s*'([^']+)'",
  ).firstMatch(source);
  if (decl == null) return null;
  final resolved = raw.replaceAll(
    RegExp(r'\$\{?' + name + r'\}?'),
    decl.group(1)!,
  );
  // 남은 보간이 있으면 검사 불가 — 스킵.
  return resolved.contains(r'$') ? null : resolved;
}
