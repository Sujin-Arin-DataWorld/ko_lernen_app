import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_segment_catalog.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/hanok_experience_projector.dart';
import 'package:ko_lernen_app/services/hanok_grant_catalog.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/hanok_grant_fixture.dart';
import 'support/productive_assessment_fixture.dart';

/// Covers Phase 1 PR-C's alpha-ramp mechanism ("살아 있는 한옥" plan):
/// [SegmentEvidenceProgress] and [canDoSegmentEvidenceProgress] must reach
/// 1.0 only when a segment would also be verified, and 0.0 with zero
/// trusted evidence -- never claim progress that isn't backed by the same
/// trusted evidence [verifiedCanDoSegmentIds] reads.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  group('SegmentEvidenceProgress.fraction', () {
    test('is the plain satisfied/total ratio at 1/3, 2/3, 3/3', () {
      expect(
        const SegmentEvidenceProgress(satisfied: 1, total: 3).fraction,
        closeTo(1 / 3, 1e-9),
      );
      expect(
        const SegmentEvidenceProgress(satisfied: 2, total: 3).fraction,
        closeTo(2 / 3, 1e-9),
      );
      expect(
        const SegmentEvidenceProgress(satisfied: 3, total: 3).fraction,
        1.0,
      );
    });

    test('is 0.0 for an empty (bundle-blocked or no-requirement) segment', () {
      expect(SegmentEvidenceProgress.none.fraction, 0.0);
      expect(
        const SegmentEvidenceProgress(satisfied: 0, total: 3).fraction,
        0.0,
      );
    });
  });

  group('canDoSegmentEvidenceProgress against the real trust pipeline', () {
    test(
      'reaches exactly 1.0 only once the segment is also verified',
      () async {
        final fixture = await _fixture();
        const segmentId = 'segment_a1_01_greetings_hangul';

        final before = canDoSegmentEvidenceProgress(
          segmentId: segmentId,
          evidence: const [],
          projectStepEvidence: const [],
          segmentCatalog: fixture.segments,
          assessmentCatalog: fixture.productive,
        );
        expect(before.satisfied, 0);
        expect(before.total, greaterThan(0));
        expect(before.fraction, 0.0);

        final service = CourseMasteryService(fixture.curriculum);
        await service.applyReconciledSnapshot(
          const CourseMasterySnapshot(
            placementLevel: 'a1',
            completedUnitIds: ['a1_01_greetings_hangul'],
          ),
          expectedGeneration: null,
        );
        final definition = fixture
            .productive
            .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
        final update = await service.recordProductiveAssessment(
          result: const ProductiveTextAssessmentEngine().evaluate(
            definition: definition,
            input: definition.authoredContextExamples.single,
            occurredAt: DateTime.utc(2026, 8, 16, 10),
          ),
          assessmentCatalog: fixture.productive,
          segmentCatalog: fixture.segments,
        );

        final after = canDoSegmentEvidenceProgress(
          segmentId: segmentId,
          evidence: update.snapshot.productiveEvidence,
          projectStepEvidence: update.snapshot.productiveProjectStepEvidence,
          segmentCatalog: fixture.segments,
          assessmentCatalog: fixture.productive,
        );
        expect(after.satisfied, after.total);
        expect(after.fraction, 1.0);

        final verified = verifiedCanDoSegmentIds(
          evidence: update.snapshot.productiveEvidence,
          projectStepEvidence: update.snapshot.productiveProjectStepEvidence,
          segmentCatalog: fixture.segments,
          assessmentCatalog: fixture.productive,
        );
        expect(
          verified.contains(segmentId),
          after.fraction == 1.0,
          reason:
              'canDoSegmentEvidenceProgress must reach 1.0 exactly when '
              'verifiedCanDoSegmentIds independently agrees the segment is '
              'verified -- two readings of the same trusted evidence must '
              'never disagree.',
        );
      },
    );

    test('an unrelated segment id yields none, not a crash', () async {
      final fixture = await _fixture();
      final progress = canDoSegmentEvidenceProgress(
        segmentId: 'segment_does_not_exist',
        evidence: const [],
        projectStepEvidence: const [],
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
      );
      expect(progress.satisfied, 0);
      expect(progress.total, 0);
      expect(progress.fraction, 0.0);
    });
  });

  group('HanokExperienceProjection.nextGrantProgress', () {
    test('is 0.0 with a fresh snapshot and a non-null nextGrant', () async {
      final fixture = await _fixture();
      final projection = fixture.project(const CourseMasterySnapshot());

      expect(projection.nextGrant, isNotNull);
      expect(projection.nextGrantProgress, 0.0);
    });

    test(
      'advances to the newly-current nextGrant after the prior one is earned',
      () async {
        final fixture = await _fixture();
        final service = CourseMasteryService(fixture.curriculum);
        await service.applyReconciledSnapshot(
          const CourseMasterySnapshot(
            placementLevel: 'a1',
            completedUnitIds: ['a1_01_greetings_hangul'],
          ),
          expectedGeneration: null,
        );
        final definition = fixture
            .productive
            .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
        final update = await service.recordProductiveAssessment(
          result: const ProductiveTextAssessmentEngine().evaluate(
            definition: definition,
            input: definition.authoredContextExamples.single,
            occurredAt: DateTime.utc(2026, 8, 16, 10),
          ),
          assessmentCatalog: fixture.productive,
          segmentCatalog: fixture.segments,
        );

        final projection = fixture.project(update.snapshot);
        expect(projection.earnedGrantIds, {'hanok_a1_01_site_setout'});
        // The first grant is earned; nextGrant has moved on to the next
        // slot, which has no evidence of its own yet.
        expect(projection.nextGrant, isNotNull);
        expect(projection.nextGrant!.id, isNot('hanok_a1_01_site_setout'));
        expect(projection.nextGrantProgress, 0.0);
      },
    );
  });
}

Future<_Fixture> _fixture() async {
  final curriculum = await CurriculumCatalog.load();
  final bundle = await CanonicalCourseSegmentLoader.load(
    curriculumCatalog: curriculum,
    productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
  );
  final grants = await loadDraftHanokGrantCatalog(bundle.segments);
  return _Fixture(
    curriculum: curriculum,
    segments: bundle.segments,
    productive: bundle.productiveAssessments,
    grants: grants,
  );
}

final class _Fixture {
  _Fixture({
    required this.curriculum,
    required this.segments,
    required this.productive,
    required this.grants,
  });

  final CurriculumCatalog curriculum;
  final CourseSegmentCatalog segments;
  final ProductiveAssessmentCatalog productive;
  final HanokGrantCatalog grants;
  final projector = const HanokExperienceProjector();

  HanokExperienceProjection project(CourseMasterySnapshot snapshot) =>
      projector.project(
        courseMastery: snapshot,
        segmentCatalog: segments,
        assessmentCatalog: productive,
        grantCatalog: grants,
        state: HanokState.fresh(manifestVersion: grants.manifestVersion),
        asOf: DateTime.utc(2026, 8, 16, 12),
      );
}
