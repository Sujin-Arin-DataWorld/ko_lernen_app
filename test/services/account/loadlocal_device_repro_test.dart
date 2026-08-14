import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// 실기기(샤오미 9053622f) `link.reconcile.loadLocal.invalid` 무한 루프 회귀.
///
/// 근본 원인: `buildBackupPayload` 는 커스텀 팩이 없을 때
/// `custom_packs_json: ''`(빈 문자열)을 실어 보내는데, `decodePortableRemote('')`
/// 이 `jsonDecode('')` 로 던져 invalid 로 취급 → `decodeCloudDocument` invalid →
/// `LocalAccountReconciliationStore.load` FormatException → 조정 러너 invalid →
/// 계정 연동 `reconciliationPending` 무한 루프. 커스텀 팩이 없는 거의 모든
/// 계정에서 결정적으로 재현됐다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodePortableRemote empty-string handling (the fix)', () {
    test('empty string is treated as absent, not invalid', () {
      expect(CustomPackService.decodePortableRemote('').state.name, 'absent');
      expect(
        CustomPackService.decodePortableRemote('   ').state.name,
        'absent',
      );
      expect(CustomPackService.decodePortableRemote(null).state.name, 'absent');
    });

    test('valid and malformed inputs are unchanged', () {
      expect(
        CustomPackService.decodePortableRemote('{}').state.name,
        'present',
      );
      expect(
        CustomPackService.decodePortableRemote('not json').state.name,
        'invalid',
      );
    });
  });

  group('LocalAccountReconciliationStore.load with real device data', () {
    const courseRaw =
        '{"version":2,"placementLevel":"a1","currentCourseUnitId":"a1_01_greetings_hangul","completedUnitIds":[],"bypassedPrerequisiteUnitIds":[],"evidence":[{"id":"evidence:82613523e2f9231a52ba9044","conceptId":"concept_greeting_politeness","contentKind":"vocab","contentId":"vocab_a1_0001","courseUnitId":"a1_01_greetings_hangul","isCorrect":false,"occurredAt":"2026-08-10T21:56:48.043850Z","errorReason":"vocabularyRecall","courseEligible":true}],"scenarioCheckpoints":[]}';
    const srsRaw =
        '{"안녕하세요":{"e":2.3499999999999996,"i":1,"n":"2026-08-11","r":2},"안녕":{"e":2.55,"i":1,"n":"2026-08-11","r":1}}';
    const packRaw =
        '{"a1_greetings_1":{"level":"A1","status":"inProgress","wordsLearned":7,"wordsTotal":9,"bossAccuracy":0.0,"attempts":0,"clearedAt":null}}';

    setUp(() async {
      Storage.resetForTesting();
      Storage.resetCourseMasteryForTesting();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'flutter.kl_course_mastery_v2': courseRaw,
        'flutter.kl_srs_v1': srsRaw,
        'flutter.kl_pack_progress_v1': packRaw,
        'flutter.kl_placement_level_v1': 'a1',
        'flutter.kl_course_unit_v1': 'a1_01_greetings_hangul',
        // Note: NO custom_packs key — this is the empty-custom-packs case that
        // made buildBackupPayload emit custom_packs_json='' and loop.
      });
      await Storage.init();
    });

    test(
      'load() succeeds (no FormatException) for an account without custom packs',
      () async {
        final snapshot = await LocalAccountReconciliationStore.load();
        expect(snapshot.srsCards.length, 2);
        expect(snapshot.packProgress.length, 1);
        expect(snapshot.courseMastery, isNotNull);
        expect(snapshot.customPacks, isEmpty);
      },
    );
  });
}
