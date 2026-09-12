import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/phase_task_drafts.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CurriculumCatalog curriculum;
  late PhaseTaskCatalog phases;
  final time = DateTime.utc(2026, 9, 11);
  setUpAll(() async {
    curriculum = await CurriculumCatalog.load();
    phases = await PhaseTaskCatalog.load();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  PhaseTaskResult result() => phases.byId('KP01:writing:01').evaluate({
    'name': '유나',
    'country': '한국',
    'occupation': '선생님',
    'introduction': '저는 선생님이에요.',
    'contrast': '저는 학생이 아니에요.',
  }, assessment: true);
  CourseMasterySnapshot snapshot(PhaseAttemptEvidence e) =>
      CourseMasterySnapshot(
        curriculumGeneration: curriculum.scenarioCorpusGeneration,
        phaseTaskEvidence: [e],
      );

  test('v1-v4 cannot introduce Phase mastery, v5 requires a valid list', () {
    for (final version in [1, 2, 3, 4]) {
      final raw = const CourseMasterySnapshot.empty().toJson()
        ..['version'] = version;
      raw['phaseTaskEvidence'] = [result().evidence('old', time).toJson()];
      expect(CourseMasterySnapshot.fromJson(raw).phaseTaskEvidence, isEmpty);
    }
    final raw = const CourseMasterySnapshot.empty().toJson()
      ..remove('phaseTaskEvidence');
    expect(() => CourseMasterySnapshot.fromJson(raw), throwsFormatException);
  });
  test(
    'save, restart and duplicate submission preserve one valid attempt without course completion',
    () async {
      final service = CourseMasteryService(curriculum);
      final saved = await service.recordPhaseAttempt(
        result: result(),
        phaseCatalog: phases,
        attemptId: 'one',
        occurredAt: time,
      );
      expect(saved.completedUnitIds, isEmpty);
      expect(saved.evidence, isEmpty);
      final restarted = CourseMasteryService(curriculum);
      expect(restarted.readForDisplay()!.phaseTaskEvidence.length, 1);
      await restarted.recordPhaseAttempt(
        result: result(),
        phaseCatalog: phases,
        attemptId: 'one',
        occurredAt: time,
      );
      expect(restarted.readForDisplay()!.phaseTaskEvidence.length, 1);
      expect(Storage.courseMasterySnapshotRawJson, isNot(contains('유나')));
      expect(
        phases.byId('KP01:writing:01').passedBy(saved.phaseTaskEvidence.single),
        isTrue,
      );
    },
  );
  test('two-device merge is commutative and conflicting attempt IDs fail', () {
    final a = result().evidence('one', time),
        b = result().evidence('two', time);
    final service = CourseMasteryService(curriculum);
    final forward = service.mergeForReconciliation(
      local: snapshot(a),
      remote: snapshot(b),
    );
    final reverse = service.mergeForReconciliation(
      local: snapshot(b),
      remote: snapshot(a),
    );
    expect(forward.isValid, isTrue);
    expect(forward.snapshot!.toJson(), reverse.snapshot!.toJson());
    final altered = PhaseAttemptEvidence.fromJson(a.toJson()..['score'] = 0.0);
    expect(
      service
          .mergeForReconciliation(local: snapshot(a), remote: snapshot(altered))
          .isValid,
      isFalse,
    );
  });
  test('old revisions remain history and raw answer fields are rejected', () {
    final task = phases.byId('KP01:writing:01');
    final old = PhaseAttemptEvidence.fromJson(
      result().evidence('old', time).toJson()..['rubricVersion'] = 2,
    );
    expect(task.passedBy(old), isFalse);
    expect(
      CourseMasterySnapshot.fromJson(
        snapshot(old).toJson(),
      ).phaseTaskEvidence.length,
      1,
    );
    expect(
      () => PhaseAttemptEvidence.fromJson(
        old.toJson()..['answer'] = 'private text',
      ),
      throwsFormatException,
    );
  });
  test(
    'account transition prevents queued recording and local draft writes',
    () async {
      final sessions = CloudWriteSessionController()..acquire('account-a');
      final drafts = PhaseTaskDrafts('hash', sessions: sessions);
      await drafts.save(true, {'name': 'fictional'});
      expect(await PhaseTaskDrafts('hash', sessions: sessions).load(true), {
        'name': 'fictional',
      });
      sessions.acquire('account-b');
      expect(
        await PhaseTaskDrafts('hash', sessions: sessions).load(true),
        isEmpty,
      );
      await expectLater(drafts.save(true, {'name': 'late'}), throwsStateError);
      final service = CourseMasteryService(curriculum);
      await expectLater(
        service.recordPhaseAttempt(
          result: result(),
          phaseCatalog: phases,
          attemptId: 'late',
          occurredAt: time,
          assertCurrentWrite: drafts.assertCurrent,
        ),
        throwsStateError,
      );
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
    },
  );
  test('account deletion removes drafts and invalidates late saves', () async {
    final sessions = CloudWriteSessionController()..acquire('delete-me');
    final drafts = PhaseTaskDrafts('hash', sessions: sessions);
    await drafts.save(false, {'name': 'fictional'});
    await Storage.resetAllStrict();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith('kl_phase_draft_')),
      isEmpty,
    );
    await expectLater(
      drafts.save(false, {'name': 'late'}),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(
      await PhaseTaskDrafts('hash', sessions: sessions).load(false),
      isEmpty,
    );
  });
  test('missing and duplicate evidence IDs fail without dropping history', () {
    final e = result().evidence('same', time);
    final raw = snapshot(e).toJson()
      ..['phaseTaskEvidence'] = [e.toJson(), e.toJson()];
    expect(
      () => CourseMasterySnapshot.fromJson(jsonDecode(jsonEncode(raw))),
      throwsFormatException,
    );
  });
}
