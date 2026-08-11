import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';

void main() {
  test('production learning content carries explicit immutable source IDs', () {
    final vocabRows = _csvRows('assets/data/korean_vocab.csv');
    expect(vocabRows, hasLength(823));
    expect(vocabRows.first.last, 'id');
    _expectRawIds(vocabRows.skip(1).map((row) => row.last.toString()), 822);

    final smalltalk = _jsonObject('assets/data/smalltalk.json');
    final phrases = (smalltalk['phrases'] as List).cast<Map<String, dynamic>>();
    expect(phrases, hasLength(145));
    _expectRawIds(phrases.map((item) => item['id']?.toString() ?? ''), 145);

    final cloze = _jsonObject('assets/data/cloze.json');
    final clozeItems = (cloze['items'] as List).cast<Map<String, dynamic>>();
    expect(clozeItems, hasLength(286));
    _expectRawIds(clozeItems.map((item) => item['id']?.toString() ?? ''), 286);

    final satz = _jsonObject('assets/data/satz_sentences.json');
    final satzItems = (satz['items'] as List).cast<Map<String, dynamic>>();
    expect(satzItems, hasLength(191));
    _expectRawIds(satzItems.map((item) => item['id']?.toString() ?? ''), 191);
  });

  test('explicit IDs survive copy edits and source list reordering', () {
    final vocab = Vocab.fromRow(const [
      'coffee',
      'keopi',
      'Kaffee',
      'A1',
      'Nomen',
      'coffee',
      'coffee',
      'food',
      'a1_food_1',
      '1',
      'false',
      'coffee',
      'noun',
      'coffee',
      'vocab_a1_0001',
    ]);
    final editedVocab = Vocab.fromRow(const [
      'coffee revised',
      'new',
      'edited',
      'A2',
      'edited',
      'edited',
      'edited',
      'edited',
      'other_pack',
      '999',
      'true',
      'edited',
      'edited',
      'edited',
      'vocab_a1_0001',
    ]);
    expect(vocab.id, 'vocab_a1_0001');
    expect(editedVocab.id, vocab.id);
    expect(_hasExplicitId(vocab), isTrue);

    final smalltalk = SmalltalkPhrase.fromJson(const {
      'id': 'smalltalk_a1_0001',
      'category': 'food',
      'level': 'a1',
      'kind': 'opener',
      'ko': 'coffee',
      'de': 'coffee',
      'en': 'coffee',
    });
    final editedSmalltalk = SmalltalkPhrase.fromJson(const {
      'id': 'smalltalk_a1_0001',
      'category': 'edited',
      'level': 'b2',
      'kind': 'question',
      'ko': 'rewritten',
      'de': 'edited',
      'en': 'edited',
    });
    expect(smalltalk.id, 'smalltalk_a1_0001');
    expect(editedSmalltalk.id, smalltalk.id);
    expect(_hasExplicitId(smalltalk), isTrue);

    final cloze = ClozeItem.fromJson(const {
      'id': 'cloze_a1_0001',
      'level': 'a1',
      'sentenceKo': '___',
      'answer': 'answer',
      'fullKo': 'answer',
      'de': 'answer',
      'en': 'answer',
      'distractors': ['other'],
      'topic': 'food',
    });
    final editedCloze = ClozeItem.fromJson(const {
      'id': 'cloze_a1_0001',
      'level': 'b2',
      'sentenceKo': 'rewritten',
      'answer': 'rewritten',
      'fullKo': 'rewritten',
      'de': 'edited',
      'en': 'edited',
      'distractors': ['edited'],
      'topic': 'edited',
    });
    expect(cloze.id, 'cloze_a1_0001');
    expect(editedCloze.id, cloze.id);
    expect(_hasExplicitId(cloze), isTrue);

    final satz = SatzSentence.fromJson(const {
      'id': 'satz_a1_0001',
      'level': 'a1',
      'targetKo': 'target',
      'promptDe': 'target',
      'promptEn': 'target',
      'distractors': ['other'],
      'vocabKo': 'word',
    });
    final editedSatz = SatzSentence.fromJson(const {
      'id': 'satz_a1_0001',
      'level': 'b2',
      'targetKo': 'rewritten',
      'promptDe': 'edited',
      'promptEn': 'edited',
      'distractors': ['edited'],
      'vocabKo': 'edited',
    });
    expect(satz.id, 'satz_a1_0001');
    expect(editedSatz.id, satz.id);
    expect(_hasExplicitId(satz), isTrue);

    final inSourceOrder = [vocab.id, smalltalk.id, cloze.id, satz.id];
    expect(inSourceOrder.reversed.toSet(), inSourceOrder.toSet());
  });

  test('legacy fixtures fall back without claiming an explicit source ID', () {
    final vocab = Vocab.fromRow(const [
      'coffee',
      'keopi',
      'Kaffee',
      'A1',
      'Nomen',
      'coffee',
      'coffee',
      'food',
    ]);
    final smalltalk = SmalltalkPhrase.fromJson(const {
      'category': 'food',
      'level': 'a1',
      'kind': 'opener',
      'ko': 'coffee',
      'de': 'coffee',
      'en': 'coffee',
    });

    expect(vocab.id, isNotEmpty);
    expect(smalltalk.id, isNotEmpty);
    expect(_hasExplicitId(vocab), isFalse);
    expect(_hasExplicitId(smalltalk), isFalse);
  });

  test(
    'malformed evidence contentKind is rejected instead of becoming vocab',
    () {
      expect(
        () => MasteryEvidence.fromJson({
          'conceptId': 'concept_particle_object',
          'contentKind': 'made_up_kind',
          'contentId': 'content_1',
          'isCorrect': true,
          'occurredAt': '2026-08-02T10:00:00.000Z',
        }),
        throwsFormatException,
      );
    },
  );

  test('catalog reports a linked item that has only a legacy fallback ID', () {
    final legacyVocab = Vocab.fromRow(const [
      'coffee',
      'keopi',
      'Kaffee',
      'A1',
      'Nomen',
      'coffee',
      'coffee',
      'food',
      'legacy_1',
      '1',
      'false',
      'coffee',
      'noun',
      'coffee',
    ]);
    final catalog = CurriculumCatalog.fromDataForTesting(
      manifestJson: const {
        'courseUnits': [
          {
            'id': 'unit_a1',
            'level': 'a1',
            'order': 1,
            'title': {'ko': 'x', 'de': 'x', 'en': 'x'},
            'canDo': {'ko': 'x', 'de': 'x', 'en': 'x'},
            'requiredConceptIds': ['concept_a1'],
          },
        ],
        'concepts': [
          {
            'id': 'concept_a1',
            'level': 'a1',
            'kind': 'vocabulary',
            'title': {'ko': 'x', 'de': 'x', 'en': 'x'},
            'explanation': {'ko': 'x', 'de': 'x', 'en': 'x'},
          },
        ],
        'surfaceForms': [],
        'formFamilies': [],
        'contentLinks': [],
        'vocabPackUnitMap': {'legacy': 'unit_a1'},
        'smalltalkCategoryUnitMap': {},
        'clozeTopicUnitMap': {},
        'grammarRuleMap': {},
      },
      vocab: [legacyVocab],
      grammar: const [],
      smalltalk: const [],
      cloze: const [],
      satz: const [],
      scenarios: const [],
    );

    expect(
      catalog.validationIssues,
      contains('vocab requires explicit ID coffee'),
    );
  });
}

List<List<String>> _csvRows(String path) {
  final normalized = File(
    path,
  ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return _logicalCsvRecords(
    normalized,
  ).where((record) => record.isNotEmpty).map(_csvFields).toList();
}

List<String> _logicalCsvRecords(String raw) {
  final records = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var index = 0; index < raw.length; index++) {
    final char = raw[index];
    if (char == '"') {
      if (quoted && index + 1 < raw.length && raw[index + 1] == '"') {
        current.write('""');
        index++;
      } else {
        quoted = !quoted;
        current.write(char);
      }
    } else if (char == '\n' && !quoted) {
      records.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) records.add(current.toString());
  return records;
}

List<String> _csvFields(String record) {
  final fields = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var index = 0; index < record.length; index++) {
    final char = record[index];
    if (char == '"') {
      if (quoted && index + 1 < record.length && record[index + 1] == '"') {
        current.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      fields.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  fields.add(current.toString());
  return fields;
}

Map<String, dynamic> _jsonObject(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void _expectRawIds(Iterable<String> ids, int expectedCount) {
  final all = ids.toList(growable: false);
  expect(all, hasLength(expectedCount));
  expect(all.every((id) => id.trim().isNotEmpty), isTrue);
  expect(all.toSet(), hasLength(expectedCount));
}

bool _hasExplicitId(dynamic content) => content.hasExplicitId as bool;
