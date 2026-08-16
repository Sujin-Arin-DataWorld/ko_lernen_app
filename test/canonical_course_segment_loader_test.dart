import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';

import 'support/productive_assessment_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical loader binds 86 segments to executable assessments',
    () async {
      final result = await CanonicalCourseSegmentLoader.load(
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );

      expect(result.segments.denominatorForReleaseTrack('core_2026_v1'), 86);
      expect(result.segments.publishedSegments, hasLength(86));
      expect(result.productiveAssessments.definitions, hasLength(118));
      expect(result.inheritedContentRoutesByKey, hasLength(527));
      final route = result.inheritedRouteFor(
        const ContentReference(
          kind: ContentReferenceKind.cloze,
          id: 'cloze_a1_0011',
        ),
      );
      expect(route, isNotNull);
      expect(route!.source.id, 'a1_misc_1');
      expect(route.sourceVocabId, 'vocab_a1_0020');
      expect(route.canDoSegmentId, isNotEmpty);
      expect(
        () => result.inheritedContentRoutesByKey['cloze:future'] = route,
        throwsUnsupportedError,
      );
    },
  );

  test(
    'canonical loader rejects inherited content with an unknown source',
    () async {
      final fixture = await _fixture();
      final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
      final inherited = (coverage['inheritedContentReferences']! as List)
          .cast<Map<String, dynamic>>();
      inherited.first['sourceId'] = 'missing_vocab_pack';

      expect(fixture.decode, throwsFormatException);
    },
  );

  test('canonical loader requires exact derived-vocab provenance', () async {
    final fixture = await _fixture();
    final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
    final inherited = (coverage['inheritedContentReferences']! as List)
        .cast<Map<String, dynamic>>();
    inherited.first.remove('sourceVocabFingerprintSha256');

    expect(fixture.decode, throwsFormatException);
  });

  test('canonical loader rejects duplicate inherited child routes', () async {
    final fixture = await _fixture();
    final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
    final inherited = (coverage['inheritedContentReferences']! as List)
        .cast<Map<String, dynamic>>();
    inherited.add(Map<String, dynamic>.from(inherited.first));
    final counts =
        coverage['inheritedReferenceCounts']! as Map<String, dynamic>;
    final kind = inherited.first['kind']! as String;
    counts[kind] = (counts[kind]! as int) + 1;

    expect(fixture.decode, throwsFormatException);
  });

  test('canonical loader rejects stale source vocab fingerprint', () async {
    final fixture = await _fixture();
    final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
    final inherited = (coverage['inheritedContentReferences']! as List)
        .cast<Map<String, dynamic>>();
    inherited.first['sourceVocabFingerprintSha256'] = 'a' * 64;

    expect(fixture.decode, throwsFormatException);
  });

  test('canonical loader rejects incomplete raw-source coverage', () async {
    final fixture = await _fixture();
    final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
    coverage['uncoveredSourceIds'] = ['smalltalk:missing_review'];

    expect(fixture.decode, throwsFormatException);
  });

  test('canonical loader rejects a stale smalltalk review target', () async {
    final fixture = await _fixture();
    final coverage = fixture.authorities['coverage']! as Map<String, dynamic>;
    final audit = coverage['smalltalkRoutingAudit']! as Map<String, dynamic>;
    final decisions = (audit['phraseDecisions']! as List)
        .cast<Map<String, dynamic>>();
    final decision = decisions.singleWhere(
      (row) => row['phraseId'] == 'smalltalk_b2_0069',
    );
    decision['canDoSegmentId'] = 'segment_b2_digital_source_judgment';

    expect(fixture.decode, throwsFormatException);
  });
}

final class _LoaderFixture {
  const _LoaderFixture({
    required this.segments,
    required this.authorities,
    required this.curriculum,
    required this.productive,
  });

  final Map<String, dynamic> segments;
  final Map<String, dynamic> authorities;
  final CurriculumCatalog curriculum;
  final ProductiveAssessmentCatalog productive;

  CanonicalCourseSegmentBundle decode() {
    return CanonicalCourseSegmentLoader.fromJson(
      segmentJson: segments,
      contentAuthorityJson: authorities,
      curriculumCatalog: curriculum,
      productiveAssessmentCatalog: productive,
      sourceVocabFingerprintsById: _sourceVocabFingerprints(),
    );
  }
}

Future<_LoaderFixture> _fixture() async {
  return _LoaderFixture(
    segments: _json('assets/data/can_do_segments.json'),
    authorities: _json('assets/data/can_do_content_authorities.json'),
    curriculum: await CurriculumCatalog.load(),
    productive: loadDraftProductiveAssessmentCatalog(),
  );
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, String> _sourceVocabFingerprints() {
  final raw = File(
    'assets/data/korean_vocab.csv',
  ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(raw);
  final headers = table.first.map((value) => value.toString()).toList();
  headers[0] = headers[0].replaceFirst('\uFEFF', '');
  final result = <String, String>{};
  for (final values in table.skip(1)) {
    if (values.every((value) => value.toString().isEmpty)) {
      continue;
    }
    final row = <String, String>{
      for (var index = 0; index < headers.length; index++)
        headers[index]: values[index].toString(),
    };
    result[row['id']!] = _fingerprint(row);
  }
  return result;
}

String _fingerprint(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalize(value)))).toString();

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
