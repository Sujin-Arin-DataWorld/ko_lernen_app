import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AccountReconciliationSnapshot _snapshot(String raw) =>
    AccountReconciliationSnapshot(
      fields: {'foundation_progress_json': raw},
      srsCards: {},
      customPacks: {},
      packProgress: {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FoundationProgressService service;

  setUp(() async {
    cloudWriteSessionController.clear();
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    service = FoundationProgressService(clock: () => DateTime.utc(2026, 10, 5));
  });

  tearDown(() async {
    await FoundationProgressStorage.drain();
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
  });

  test(
    'backup payload includes durable cursor, practice and explicit A1 choice',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      await service.savePractice(
        const FoundationPracticeEvidence.listen(
          FoundationTask.soundG,
          playbackSucceeded: true,
          spokenConfirmation: true,
        ),
        lease: FoundationLearningLease.capture(),
      );
      await service.chooseContinueA1(lease: FoundationLearningLease.capture());
      final payload = await CloudSync.buildBackupPayload(
        courseMasteryCapture: const CourseMasteryLocalCapture(
          snapshot: null,
          canonicalGeneration: '',
        ),
        ilduWorldStateCapture: const IlDuWorldStateLocalCapture(
          state: null,
          generation: '',
        ),
      );
      final progress = FoundationProgress.decode(
        payload['foundation_progress_json'] as String,
      );
      expect(progress.currentStep, FoundationStep.sounds);
      expect(progress.practicedTasks, {FoundationTask.soundG});
      expect(progress.continuedToA1, isTrue);
      expect(progress.isComplete, isFalse);
      expect(payload.containsKey('course_mastery_json'), isFalse);
    },
  );

  test(
    'an unused foundation path does not fabricate a cloud progress field',
    () async {
      final payload = await CloudSync.buildBackupPayload(
        courseMasteryCapture: const CourseMasteryLocalCapture(
          snapshot: null,
          canonicalGeneration: '',
        ),
        ilduWorldStateCapture: const IlDuWorldStateLocalCapture(
          state: null,
          generation: '',
        ),
      );
      expect(payload.containsKey('foundation_progress_json'), isFalse);
    },
  );

  test(
    'cloud restore unions practice and preserves explicit course choice',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      await service.savePractice(
        const FoundationPracticeEvidence.listen(
          FoundationTask.soundG,
          playbackSucceeded: true,
          spokenConfirmation: true,
        ),
        lease: FoundationLearningLease.capture(),
      );
      final remote = FoundationProgress()
          .withOpened(
            FoundationStep.firstWords,
            cursorUpdatedAt: DateTime.utc(2026, 10, 6).millisecondsSinceEpoch,
          )
          .withPractice(FoundationTask.wordBag)
          .withContinueA1();
      await CloudSync.applyRestorePayload({
        'foundation_progress_json': remote.encode(),
      });
      final restored = await service.load();
      expect(restored.practicedTasks, {
        FoundationTask.soundG,
        FoundationTask.wordBag,
      });
      expect(restored.currentStep, FoundationStep.firstWords);
      expect(restored.continuedToA1, isTrue);
      expect(restored.isComplete, isFalse);
      expect(Storage.xp, 0);
      expect(Storage.courseMasteryRawJson, isEmpty);
      await CloudSync.applyRestorePayload({
        'foundation_progress_json': remote.encode(),
      });
      expect((await service.load()).encode(), restored.encode());
    },
  );

  test(
    'malformed/future foundation backup fails before other restore writes',
    () async {
      await service.markStepOpened(FoundationStep.tracing);
      final before = FoundationProgressStorage.readRawJson();
      for (final raw in [
        '',
        '{broken',
        '{"version":2,"openedSteps":[],"practicedTasks":[]}',
      ]) {
        await expectLater(
          CloudSync.applyRestorePayload({
            'foundation_progress_json': raw,
            'progress': {'xp': 1234},
          }),
          throwsFormatException,
        );
        expect(FoundationProgressStorage.readRawJson(), before);
        expect(Storage.xp, 0);
      }
    },
  );

  test(
    'late cloud restore is fenced by the current local-data lifetime',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final before = FoundationProgressStorage.readRawJson();
      final remote = FoundationProgress().withContinueA1().encode();
      await expectLater(
        CloudSync.applyRestorePayload({
          'foundation_progress_json': remote,
        }, beforeWrite: LocalDataLifetime.invalidate),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(FoundationProgressStorage.readRawJson(), before);
    },
  );

  test(
    'reconciliation merges devices without scalar/string conflicts or mastery',
    () {
      final local = FoundationProgress()
          .withOpened(FoundationStep.sounds, cursorUpdatedAt: 10)
          .withPractice(FoundationTask.soundG);
      final remote = FoundationProgress()
          .withOpened(FoundationStep.tracing, cursorUpdatedAt: 20)
          .withPractice(FoundationTask.traceG)
          .withContinueA1();
      final merged = AccountReconciliationMerger.merge(
        local: _snapshot(local.encode()),
        remote: _snapshot(remote.encode()),
        catalog: {},
      );
      expect(merged.conflicts, isEmpty);
      expect(merged.merged, isNotNull);
      final fields = merged.merged!.toCloudDocument();
      final progress = FoundationProgress.decode(
        fields['foundation_progress_json'] as String,
      );
      expect(progress.practicedTasks, {
        FoundationTask.soundG,
        FoundationTask.traceG,
      });
      expect(progress.continuedToA1, isTrue);
      expect(progress.currentStep, FoundationStep.tracing);
      expect(progress.isComplete, isFalse);
      expect(fields.containsKey('course_mastery_json'), isFalse);
      final reverse = AccountReconciliationMerger.merge(
        local: _snapshot(remote.encode()),
        remote: _snapshot(local.encode()),
        catalog: {},
      );
      expect(
        reverse.merged!.fields['foundation_progress_json'],
        progress.encode(),
      );
    },
  );

  test('reconciliation cloud reads reject corrupt foundation records', () {
    for (final value in [null, '', '{broken', 5]) {
      final result = AccountReconciliationSnapshot.decodeCloudDocument({
        'foundation_progress_json': value,
      });
      expect(result.state, CloudReadState.invalid);
    }
    final valid = AccountReconciliationSnapshot.decodeCloudDocument({
      'foundation_progress_json': FoundationProgress().encode(),
    });
    expect(valid.state, CloudReadState.present);
  });

  test(
    'a malformed foundation merge is a required reconciliation conflict',
    () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot(FoundationProgress().encode()),
        remote: _snapshot('{broken'),
        catalog: {},
      );
      expect(result.merged, isNull);
      expect(
        result.conflicts.any(
          (conflict) => conflict.id == 'foundation_progress_json',
        ),
        isTrue,
      );
    },
  );

  test(
    'reconciled restore accepts its explicit account owner and rejects a stale session',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('account-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final remote = FoundationProgress()
          .withOpened(FoundationStep.tracing, cursorUpdatedAt: 10)
          .withContinueA1();
      await CloudSync.applyReconciledRestorePayload(
        {'foundation_progress_json': remote.encode()},
        uid: 'account-a',
        session: session,
        sessions: sessions,
      );
      expect((await service.load()).continuedToA1, isTrue);
      final before = FoundationProgressStorage.readRawJson();
      sessions.acquire('account-b');
      await expectLater(
        CloudSync.applyReconciledRestorePayload(
          {'foundation_progress_json': FoundationProgress().encode()},
          uid: 'account-a',
          session: session,
          sessions: sessions,
        ),
        throwsStateError,
      );
      expect(FoundationProgressStorage.readRawJson(), before);
    },
  );
}
