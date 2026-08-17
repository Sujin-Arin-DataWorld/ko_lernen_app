import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/course_segment_catalog.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/hanok_cutover_service.dart';
import 'package:ko_lernen_app/services/hanok_grant_catalog.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/productive_assessment_fixture.dart';
import 'support/hanok_grant_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_hanok_stages_seen_v1': <String>['foundation'],
      'kl_personal_hanok_milestones_seen_v1': <String>['anchae'],
      'kl_room_layouts_v3': '{"preserve":true}',
      'kl_owned_decor': <String>['moon_jar'],
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  test(
    'cutover removes only legacy reveal ledgers and commits marker last',
    () async {
      final fixture = await _fixture();
      final state = await const _Runner().run(fixture);

      expect(state.seenRevealIds, isEmpty);
      expect(Storage.hanokStateRawJson, isNotEmpty);
      expect(Storage.hanokCutoverRawValue, HanokCutoverService.markerValue);
      expect(Storage.seenHanokStages, isEmpty);
      expect(
        Storage.personalHanokMilestoneRevealSnapshot.isInitialized,
        isFalse,
      );
      expect(Storage.roomLayoutsV3Raw, '{"preserve":true}');
      expect(Storage.ownedDecor, ['moon_jar']);
    },
  );

  test(
    'interrupted cutover reruns without duplicate or legacy import',
    () async {
      final fixture = await _fixture();
      final interrupted = HanokCutoverService(
        afterStateSavedForTesting: () async => throw StateError('interrupt'),
      );
      await expectLater(
        _Runner(service: interrupted).run(fixture),
        throwsStateError,
      );
      final firstState = Storage.hanokStateRawJson;
      expect(firstState, isNotEmpty);
      expect(Storage.hanokCutoverRawValue, isEmpty);
      expect(Storage.seenHanokStages, ['foundation']);

      final completed = await const _Runner().run(fixture);
      expect(Storage.hanokStateRawJson, firstState);
      expect(completed.seenRevealIds, isEmpty);
      expect(Storage.hanokCutoverRawValue, HanokCutoverService.markerValue);
      expect(Storage.seenHanokStages, isEmpty);
    },
  );
}

Future<_Fixture> _fixture() async {
  final curriculum = await CurriculumCatalog.load();
  final bundle = await CanonicalCourseSegmentLoader.load(
    curriculumCatalog: curriculum,
    productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
  );
  final grants = await loadDraftHanokGrantCatalog(bundle.segments);
  return _Fixture(
    segments: bundle.segments,
    productive: bundle.productiveAssessments,
    grants: grants,
  );
}

final class _Fixture {
  const _Fixture({
    required this.segments,
    required this.productive,
    required this.grants,
  });

  final CourseSegmentCatalog segments;
  final ProductiveAssessmentCatalog productive;
  final HanokGrantCatalog grants;
}

final class _Runner {
  const _Runner({this.service = const HanokCutoverService()});

  final HanokCutoverService service;

  Future<HanokState> run(_Fixture fixture) => service.ensureCutover(
    courseMastery: const CourseMasterySnapshot.empty(),
    segmentCatalog: fixture.segments,
    assessmentCatalog: fixture.productive,
    grantCatalog: fixture.grants,
    asOf: DateTime.utc(2026, 8, 16, 12),
  );
}
