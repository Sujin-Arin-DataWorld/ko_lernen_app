import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/models/room_layout.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_segment_catalog.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/hanok_experience_projector.dart';
import 'package:ko_lernen_app/services/hanok_grant_catalog.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/productive_assessment_fixture.dart';
import 'support/hanok_grant_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('completed CourseUnit opens reassessment but earns no grant', () async {
    final fixture = await _fixture();
    final snapshot = CourseMasterySnapshot(
      completedUnitIds: const ['a1_01_greetings_hangul'],
    );
    final projection = fixture.project(snapshot);

    expect(projection.earnedGrants, isEmpty);
    expect(projection.a1ConstructionStep, 0);
    expect(
      projection.reassessmentEligibleSegmentIds,
      contains('segment_a1_01_greetings_hangul'),
    );
  });

  test('bypassed CourseUnit cannot earn or open reassessment', () async {
    final fixture = await _fixture();
    final projection = fixture.project(
      CourseMasterySnapshot(
        completedUnitIds: const ['a1_01_greetings_hangul'],
        bypassedPrerequisiteUnitIds: const ['a1_01_greetings_hangul'],
      ),
    );

    expect(projection.earnedGrants, isEmpty);
    expect(projection.reassessmentEligibleSegmentIds, isEmpty);
  });

  test(
    'next grant skips bypassed and prerequisite-blocked A1 rewards',
    () async {
      final fixture = await _fixture();
      final bypassedA1Units = fixture.segments.publishedSegments
          .where((segment) => segment.level.code == 'a1')
          .map((segment) => segment.parentCourseUnitId)
          .toSet()
          .toList(growable: false);
      final projection = fixture.project(
        CourseMasterySnapshot(
          completedUnitIds: bypassedA1Units,
          bypassedPrerequisiteUnitIds: bypassedA1Units,
        ),
      );

      expect(projection.nextGrant, isNotNull);
      expect(projection.nextGrant!.level.code, 'a2');
    },
  );

  test('trusted productive proof earns exactly the first A1 state', () async {
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
    final result = const ProductiveTextAssessmentEngine().evaluate(
      definition: definition,
      input: definition.authoredContextExamples.single,
      occurredAt: DateTime.utc(2026, 8, 16, 10),
    );
    final update = await service.recordProductiveAssessment(
      result: result,
      assessmentCatalog: fixture.productive,
      segmentCatalog: fixture.segments,
    );

    final projection = fixture.project(update.snapshot);
    expect(projection.earnedGrantIds, {'hanok_a1_01_site_setout'});
    expect(projection.a1ConstructionStep, 1);
    expect(projection.trackProgress.single.earned, 1);
    expect(projection.trackProgress.single.total, 86);
  });

  test('A1 productive proof and construction rewards advance in order', () async {
    final fixture = await _fixture();
    final service = CourseMasteryService(fixture.curriculum);
    await service.applyReconciledSnapshot(
      const CourseMasterySnapshot(
        placementLevel: 'a1',
        completedUnitIds: [
          'a1_01_greetings_hangul',
          'a1_02_self_intro_identity',
        ],
      ),
      expectedGeneration: null,
    );
    final first = fixture
        .productive
        .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
    final second = fixture
        .productive
        .definitionsById['assess_a1_02_self_intro_identity_connected_production_v1']!;
    final engine = const ProductiveTextAssessmentEngine();
    final secondResult = engine.evaluate(
      definition: second,
      input: second.authoredContextExamples.single,
      occurredAt: DateTime.utc(2026, 8, 16, 10, 1),
    );
    await expectLater(
      service.recordProductiveAssessment(
        result: secondResult,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      ),
      throwsStateError,
    );

    final firstUpdate = await service.recordProductiveAssessment(
      result: engine.evaluate(
        definition: first,
        input: first.authoredContextExamples.single,
        occurredAt: DateTime.utc(2026, 8, 16, 10),
      ),
      assessmentCatalog: fixture.productive,
      segmentCatalog: fixture.segments,
    );
    expect(fixture.project(firstUpdate.snapshot).a1ConstructionStep, 1);

    final secondUpdate = await service.recordProductiveAssessment(
      result: secondResult,
      assessmentCatalog: fixture.productive,
      segmentCatalog: fixture.segments,
    );
    final projection = fixture.project(secondUpdate.snapshot);
    expect(projection.a1ConstructionStep, 2);
    expect(projection.earnedGrantIds, {
      'hanok_a1_01_site_setout',
      'hanok_a1_02_plan_layout',
    });
  });

  test(
    'non-construction A1 reward never extends the fixed 0-16 renderer',
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
      final grantJson = await loadDraftHanokGrantJson();
      final first = (grantJson['grants'] as List).first as Map<String, dynamic>;
      first['kind'] = 'ambience';
      final nonConstructionCatalog = HanokGrantCatalog.fromJson(
        grantJson,
        segmentCatalog: fixture.segments,
      );
      final projection = fixture.projector.project(
        courseMastery: update.snapshot,
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
        grantCatalog: nonConstructionCatalog,
        state: HanokState.fresh(
          manifestVersion: nonConstructionCatalog.manifestVersion,
        ),
        asOf: DateTime.utc(2026, 8, 16, 12),
      );

      expect(projection.earnedGrantIds, {'hanok_a1_01_site_setout'});
      expect(projection.a1ConstructionStep, 0);
    },
  );

  test('room-v3 items remain exact while a room is dormant', () async {
    final fixture = await _fixture();
    const item = RoomLayoutItem(
      instanceId: 'decor:moon_jar',
      kind: RoomAssetKind.decoration,
      assetId: 'moon_jar',
      x: .33,
      y: .66,
      width: .21,
      rotation: .1,
    );
    final dormant = fixture.projector.partitionRoomLayouts(
      roomLayouts: const {
        PersonalRoomSurface.sarangbang: [item],
      },
      openedVenues: const {},
    );
    final active = fixture.projector.partitionRoomLayouts(
      roomLayouts: const {
        PersonalRoomSurface.sarangbang: [item],
      },
      openedVenues: const {PersonalRoomSurface.sarangbang},
    );

    expect(dormant.active, isEmpty);
    expect(dormant.dormant[PersonalRoomSurface.sarangbang], [item]);
    expect(active.dormant, isEmpty);
    expect(active.active[PersonalRoomSurface.sarangbang], [item]);
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
