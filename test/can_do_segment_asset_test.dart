import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical asset freezes the 86-slot core and full assessment IDs', () {
    final catalog = _json('assets/data/can_do_segments.json');
    final segments = _rows(catalog['segments']);
    final clusters = _rows(catalog['contentClusters']);
    final editions = _rows(catalog['trackEditions']);

    expect(segments, hasLength(86));
    expect(clusters, hasLength(86));
    expect(editions, hasLength(6));
    expect(_levelCounts(segments), const {
      'a1': 16,
      'a2': 16,
      'b1': 18,
      'b2': 20,
      'c1': 8,
      'c2': 8,
    });

    const modeSuffix = {
      'guidedProduction': 'guided_production',
      'dictation': 'dictation',
      'connectedProduction': 'connected_production',
      'openWriting': 'open_writing',
      'oralProduction': 'oral_production',
      'connectedEvidence': 'connected_evidence',
    };
    for (final segment in segments) {
      final segmentId = segment['id']! as String;
      final key = segmentId.substring('segment_'.length);
      expect(segment['constructLineageId'], segmentId);
      expect(segment['proofRevision'], 1);
      expect(segment['lifecycle'], 'published');
      for (final requirement in _rows(segment['assessmentRequirements'])) {
        final suffix = modeSuffix[requirement['evidenceMode']];
        expect(suffix, isNotNull);
        expect(requirement['assessmentItemId'], 'assess_${key}_${suffix}_v1');
        expect(
          requirement['missionContentLinkId'],
          'mission_${key}_${suffix}_v1',
        );
        expect(requirement['minimumScore'], .7);
      }
    }
  });

  test(
    'coverage joins every raw source through one direct or inherited route',
    () {
      final authority = _json('assets/data/can_do_content_authorities.json');
      final direct = _rows(authority['contentReferences']);
      final coverage = authority['coverage']! as Map<String, dynamic>;
      final inherited = _rows(coverage['inheritedContentReferences']);

      final directKeys = {
        for (final row in direct) '${row['kind']}:${row['id']}',
      };
      final inheritedKeys = {
        for (final row in inherited) '${row['kind']}:${row['id']}',
      };
      expect(directKeys.length, direct.length);
      expect(inheritedKeys.length, inherited.length);
      expect(directKeys.intersection(inheritedKeys), isEmpty);

      final vocabRows = _csv('assets/data/korean_vocab.csv');
      final vocabById = {for (final row in vocabRows) row['id']!: row};
      final grammarRows = _csv('assets/data/grammar.csv');
      final smalltalkRows = _rows(
        _json('assets/data/smalltalk.json')['phrases'],
      );
      final scenarioRows = _rows(
        _json('assets/data/scenarios.json')['scenarios'],
      );
      final clozeRows = _rows(_json('assets/data/cloze.json')['items']);
      final satzRows = _rows(_json('assets/data/satz_sentences.json')['items']);

      expect(_idsForKind(direct, 'vocabPack'), {
        for (final row in vocabRows) row['pack_id']!,
      });
      expect(_idsForKind(direct, 'grammar'), {
        for (final row in grammarRows) row['id']!,
      });
      expect(_idsForKind(direct, 'smalltalk'), {
        for (final row in smalltalkRows) row['id']!,
      });
      expect(_idsForKind(direct, 'scenario'), {
        for (final row in scenarioRows) row['id']!,
      });
      expect(
        _idsForKind(direct, 'cloze').union(_idsForKind(inherited, 'cloze')),
        {for (final row in clozeRows) row['id']!},
      );
      expect(
        _idsForKind(direct, 'satz').union(_idsForKind(inherited, 'satz')),
        {for (final row in satzRows) row['id']!},
      );
      for (final lineage in inherited) {
        final source = vocabById[lineage['sourceVocabId']];
        expect(source, isNotNull);
        expect(source!['pack_id'], lineage['sourceId']);
        expect(lineage['sourceVocabFingerprintSha256'], _fingerprint(source));
      }
      expect(coverage['uncoveredSourceIds'], isEmpty);
    },
  );

  test('all A1-B2 smalltalk routes have explicit semantic decisions', () {
    final authority = _json('assets/data/can_do_content_authorities.json');
    final coverage = authority['coverage']! as Map<String, dynamic>;
    final audit = coverage['smalltalkRoutingAudit']! as Map<String, dynamic>;
    final decisions = _rows(audit['phraseDecisions']);
    final decisionById = {for (final row in decisions) row['phraseId']: row};
    final phrases = _rows(_json('assets/data/smalltalk.json')['phrases'])
        .where((row) => const {'a1', 'a2', 'b1', 'b2'}.contains(row['level']))
        .toList(growable: false);
    final phrasesById = {for (final row in phrases) row['id']: row};

    expect(decisions, hasLength(321));
    expect(decisionById.keys.toSet(), {for (final row in phrases) row['id']});
    expect(audit['unresolvedAmbiguousIds'], isEmpty);
    expect(
      decisions.every(
        (row) => const {
          'approved',
          'bestAvailable',
          'exactMapped',
        }.contains(row['semanticStatus']),
      ),
      isTrue,
    );
    for (final decision in decisions) {
      expect(
        decision['phraseFingerprintSha256'],
        _fingerprint(phrasesById[decision['phraseId']]!),
      );
    }
    expect(
      decisionById['smalltalk_b2_0069']!['canDoSegmentId'],
      'segment_b2_personal_boundaries',
    );
    expect(decisionById['smalltalk_b2_0069']!['semanticStatus'], 'exactMapped');
    expect(
      decisionById['smalltalk_b2_0043']!['semanticStatus'],
      'bestAvailable',
    );
    expect(
      decisionById['smalltalk_b1_0012']!['semanticStatus'],
      'bestAvailable',
    );
    for (final decision in decisions) {
      if (decision['routingSource'] != 'exactOverride') {
        expect(decision['semanticStatus'], 'bestAvailable');
        expect(decision['reasonCode'], 'closestPublishedCoreSegment');
      }
    }
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _rows(Object? raw) =>
    (raw! as List).cast<Map<String, dynamic>>();

Map<String, int> _levelCounts(List<Map<String, dynamic>> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    final level = row['level']! as String;
    counts[level] = (counts[level] ?? 0) + 1;
  }
  return counts;
}

Set<String> _idsForKind(List<Map<String, dynamic>> rows, String kind) => {
  for (final row in rows)
    if (row['kind'] == kind) row['id']! as String,
};

List<Map<String, String>> _csv(String path) {
  final raw = File(
    path,
  ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(raw);
  final headers = table.first.cast<String>();
  return [
    for (final values in table.skip(1))
      if (values.any((value) => value.toString().isNotEmpty))
        {
          for (var index = 0; index < headers.length; index++)
            headers[index]: values[index].toString(),
        },
  ];
}

String _fingerprint(Object? value) {
  final canonical = jsonEncode(_canonicalize(value));
  return sha256.convert(utf8.encode(canonical)).toString();
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    return [for (final item in value) _canonicalize(item)];
  }
  return value;
}
