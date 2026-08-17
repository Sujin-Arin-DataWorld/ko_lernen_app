import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/hanok_grant_catalog.dart';

import 'support/productive_assessment_fixture.dart';
import 'support/hanok_grant_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical Hanok catalog owns one immutable grant per core slot',
    () async {
      final segmentBundle = await CanonicalCourseSegmentLoader.load(
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );
      final catalog = await loadDraftHanokGrantCatalog(segmentBundle.segments);

      expect(catalog.schemaVersion, 1);
      expect(catalog.manifestVersion, 'hanok_v1_core_2026_v1');
      expect(catalog.grants, hasLength(86));
      expect(catalog.grantsBySegmentId, hasLength(86));
      expect(catalog.grantsById, hasLength(86));
      expect(
        {
          for (final level in LearnerLevel.values)
            level: catalog.grants.where((grant) => grant.level == level).length,
        },
        {
          LearnerLevel.a1: 16,
          LearnerLevel.a2: 16,
          LearnerLevel.b1: 18,
          LearnerLevel.b2: 20,
          LearnerLevel.c1: 8,
          LearnerLevel.c2: 8,
        },
      );
      expect(catalog.grants.take(16).map((grant) => grant.kind).toSet(), {
        HanokGrantKind.constructionPiece,
      });
      expect(catalog.grants.first.id, 'hanok_a1_01_site_setout');
      expect(catalog.grants.first.revealAssetIds, [
        'hanok_a1_state_01_site_setout',
      ]);
      expect(catalog.grants[15].id, 'hanok_a1_16_landscape_move_in');
      expect(
        () => catalog.grants.first.revealAssetIds.add('mutate'),
        throwsUnsupportedError,
      );
    },
  );

  test('catalog rejects missing, duplicate, and non-segment rewards', () async {
    final segmentBundle = await CanonicalCourseSegmentLoader.load(
      productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
    );
    final canonical = await loadDraftHanokGrantJson();

    final missing = _copy(canonical);
    (missing['grants']! as List).removeLast();
    expect(
      () => HanokGrantCatalog.fromJson(
        missing,
        segmentCatalog: segmentBundle.segments,
      ),
      throwsFormatException,
    );

    final duplicate = _copy(canonical);
    final duplicateRows = duplicate['grants']! as List;
    duplicateRows[1] = Map<String, dynamic>.from(duplicateRows.first as Map);
    expect(
      () => HanokGrantCatalog.fromJson(
        duplicate,
        segmentCatalog: segmentBundle.segments,
      ),
      throwsFormatException,
    );

    final unknown = _copy(canonical);
    final unknownRows = unknown['grants']! as List;
    unknownRows[0] = <String, dynamic>{
      ...Map<String, dynamic>.from(unknownRows.first as Map),
      'canDoSegmentId': 'segment_unknown_future',
    };
    expect(
      () => HanokGrantCatalog.fromJson(
        unknown,
        segmentCatalog: segmentBundle.segments,
      ),
      throwsFormatException,
    );
  });

  test(
    'published grant identities are immutable across catalog evolution',
    () async {
      final segmentBundle = await CanonicalCourseSegmentLoader.load(
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );
      final canonicalJson = await loadDraftHanokGrantJson();
      final previous = HanokGrantCatalog.fromJson(
        canonicalJson,
        segmentCatalog: segmentBundle.segments,
      );
      expect(() => previous.validateEvolutionFrom(previous), returnsNormally);

      final renamed = _copy(canonicalJson);
      final renamedRows = renamed['grants']! as List;
      renamedRows[15] = <String, dynamic>{
        ...Map<String, dynamic>.from(renamedRows[15] as Map),
        'id': 'hanok_a1_16_landscape_move_in_rewritten',
      };
      final renamedCatalog = HanokGrantCatalog.fromJson(
        renamed,
        segmentCatalog: segmentBundle.segments,
      );
      expect(
        () => renamedCatalog.validateEvolutionFrom(previous),
        throwsFormatException,
      );

      final changedCopy = _copy(canonicalJson);
      final changedRows = changedCopy['grants']! as List;
      changedRows[0] = <String, dynamic>{
        ...Map<String, dynamic>.from(changedRows.first as Map),
        'userDescriptionKey': 'hanokGrant_rewritten_copy',
      };
      final changedCatalog = HanokGrantCatalog.fromJson(
        changedCopy,
        segmentCatalog: segmentBundle.segments,
      );
      expect(
        () => changedCatalog.validateEvolutionFrom(previous),
        throwsFormatException,
      );
    },
  );
}

Map<String, dynamic> _copy(Map<String, dynamic> source) =>
    Map<String, dynamic>.fromEntries(
      source.entries.map((entry) {
        if (entry.value is List) {
          return MapEntry(entry.key, [
            for (final value in entry.value as List)
              value is Map ? Map<String, dynamic>.from(value) : value,
          ]);
        }
        return MapEntry(entry.key, entry.value);
      }),
    );
