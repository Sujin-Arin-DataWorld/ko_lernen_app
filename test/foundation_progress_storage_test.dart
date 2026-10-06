import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';

const _sound = FoundationPracticeEvidence.listen(
  FoundationTask.soundG,
  playbackSucceeded: true,
  spokenConfirmation: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  late FoundationProgressService service;

  setUp(() async {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    service = FoundationProgressService(clock: () => DateTime.utc(2026, 10, 5));
  });

  tearDown(() async {
    await FoundationProgressStorage.drain();
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test(
    'practice and explicit A1 choice survive storage/service recreation',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      await service.savePractice(
        _sound,
        lease: FoundationLearningLease.capture(),
      );
      await service.chooseContinueA1(lease: FoundationLearningLease.capture());
      await service.markStepOpened(FoundationStep.tracing);
      final native = platform.values[FoundationProgressStorage.preferenceKey];
      Storage.resetForTesting();
      await Storage.init();
      final resumed = await FoundationProgressService().load();
      expect(resumed.hasPracticed(FoundationTask.soundG), isTrue);
      expect(resumed.currentStep, FoundationStep.tracing);
      expect(resumed.continuedToA1, isTrue);
      expect(resumed.isComplete, isFalse);
      expect(platform.values[FoundationProgressStorage.preferenceKey], native);
      expect(Storage.xp, 0);
      expect(Storage.courseMasteryRawJson, isEmpty);
    },
  );

  test(
    'simultaneous visits/practice/A1 choice preserve every update',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final lease = FoundationLearningLease.capture();
      await Future.wait([
        service.savePractice(_sound, lease: lease),
        service.markStepOpened(FoundationStep.tracing, lease: lease),
        service.chooseContinueA1(lease: lease),
      ]);
      final current = await service.load();
      expect(current.practicedTasks, {FoundationTask.soundG});
      expect(current.currentStep, FoundationStep.tracing);
      expect(current.continuedToA1, isTrue);
    },
  );

  test(
    'a failed playback or missing confirmation never writes practice',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final baseline = platform.values[FoundationProgressStorage.preferenceKey];
      for (final evidence in [
        const FoundationPracticeEvidence.listen(
          FoundationTask.soundG,
          playbackSucceeded: false,
          spokenConfirmation: true,
        ),
        const FoundationPracticeEvidence.listen(
          FoundationTask.soundG,
          playbackSucceeded: true,
          spokenConfirmation: false,
        ),
        const FoundationPracticeEvidence.listen(
          FoundationTask.traceG,
          playbackSucceeded: true,
          spokenConfirmation: true,
        ),
      ]) {
        await expectLater(
          service.savePractice(
            evidence,
            lease: FoundationLearningLease.capture(),
          ),
          throwsStateError,
        );
      }
      expect(
        platform.values[FoundationProgressStorage.preferenceKey],
        baseline,
      );
      expect((await service.load()).practicedCount, 0);
    },
  );

  test(
    'a rejected native write retains evidence for an explicit retry',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final lease = FoundationLearningLease.capture();
      platform.rejectKey = FoundationProgressStorage.preferenceKey;
      await expectLater(
        service.savePractice(_sound, lease: lease),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect((await service.load()).practicedCount, 0);
      platform.rejectKey = null;
      await service.savePractice(_sound, lease: lease);
      expect(
        (await service.load()).hasPracticed(FoundationTask.soundG),
        isTrue,
      );
    },
  );

  test(
    'a successful transport reply without native equality is rejected',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      platform.rejectKey = FoundationProgressStorage.preferenceKey;
      platform.successfulReply = true;
      await expectLater(
        service.savePractice(_sound, lease: FoundationLearningLease.capture()),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect((await service.load()).practicedCount, 0);
    },
  );

  test(
    'lost reply after native commit is confirmed once by native readback',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      platform.rejectKey = FoundationProgressStorage.preferenceKey;
      platform.commitBeforeFailure = true;
      platform.throwReply = true;
      final lease = FoundationLearningLease.capture();
      await service.savePractice(_sound, lease: lease);
      await service.savePractice(_sound, lease: lease);
      expect((await service.load()).practicedTasks, {FoundationTask.soundG});
    },
  );

  test(
    'unknown native outcome cannot be displayed as saved; retry reconciles it',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final lease = FoundationLearningLease.capture();
      platform.rejectKey = FoundationProgressStorage.preferenceKey;
      platform.commitBeforeFailure = true;
      platform.throwReply = true;
      platform.failReloadAfterWrite = true;
      await expectLater(
        service.savePractice(_sound, lease: lease),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      await expectLater(
        service.load(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      platform.unavailable = false;
      platform.rejectKey = null;
      await service.savePractice(_sound, lease: lease);
      expect((await service.load()).practicedTasks, {FoundationTask.soundG});
    },
  );

  test(
    'stale account and A-to-B-to-A exercises cannot write the active account',
    () async {
      cloudWriteSessionController.acquire('account-a');
      await service.markStepOpened(FoundationStep.sounds);
      final lease = FoundationLearningLease.capture();
      final baseline = platform.values[FoundationProgressStorage.preferenceKey];
      cloudWriteSessionController.acquire('account-b');
      cloudWriteSessionController.acquire('account-a');
      await expectLater(
        service.savePractice(_sound, lease: lease),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(
        platform.values[FoundationProgressStorage.preferenceKey],
        baseline,
      );
    },
  );

  test(
    'quiesced account and durable transition journal block new practice',
    () async {
      cloudWriteSessionController.acquire('account-a');
      await service.markStepOpened(FoundationStep.sounds);
      cloudWriteSessionController.transition(CloudWriteMode.quiesced);
      await expectLater(
        service.chooseContinueA1(lease: FoundationLearningLease.capture()),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      cloudWriteSessionController.acquire('account-a');
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('kl_account_switch_journal_v1', '{}');
      await expectLater(
        service.savePractice(_sound, lease: FoundationLearningLease.capture()),
        throwsA(isA<PackCompletionPendingException>()),
      );
    },
  );

  test(
    'learning downgrade lock blocks practice but a guarded restore may recover',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      Storage.lockLearningWrites('newer-schema');
      await expectLater(
        service.savePractice(_sound, lease: FoundationLearningLease.capture()),
        throwsA(isA<PackCompletionPendingException>()),
      );
      final remote = FoundationProgress()
          .withOpened(FoundationStep.firstWords, cursorUpdatedAt: 10)
          .withPractice(FoundationTask.wordBag)
          .withContinueA1();
      await FoundationProgressService.mergeCloudJson(
        remote.encode(),
        beforeWrite: () {},
      );
      final restored = await service.load();
      expect(restored.hasOpened(FoundationStep.sounds), isTrue);
      expect(restored.hasPracticed(FoundationTask.wordBag), isTrue);
      expect(restored.continuedToA1, isTrue);
    },
  );

  test(
    'reset drains a delayed native write and it cannot recreate erased practice',
    () async {
      await service.markStepOpened(FoundationStep.sounds);
      final lease = FoundationLearningLease.capture();
      final entered = Completer<void>();
      final release = Completer<void>();
      platform.rejectKey = FoundationProgressStorage.preferenceKey;
      platform.commitBeforeFailure = true;
      platform.throwReply = true;
      platform.writeEntered = entered;
      platform.releaseWrite = release;
      final saving = service.savePractice(_sound, lease: lease);
      final failedSave = expectLater(
        saving,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;
      final reset = Storage.resetAllStrict();
      await expectLater(
        service.chooseContinueA1(lease: FoundationLearningLease.capture()),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      release.complete();
      await failedSave;
      await reset;
      expect(
        platform.values.containsKey(FoundationProgressStorage.preferenceKey),
        isFalse,
      );
      expect((await service.load()).practicedCount, 0);
      expect((await service.load()).continuedToA1, isFalse);
    },
  );

  test(
    'backup includes confirmed cursor/choice and corruption is not overwritten',
    () async {
      await service.markStepOpened(FoundationStep.tracing);
      await service.chooseContinueA1(lease: FoundationLearningLease.capture());
      final backup = await FoundationProgressService.captureBackupJson();
      final progress = FoundationProgress.decode(backup!);
      expect(progress.currentStep, FoundationStep.tracing);
      expect(progress.continuedToA1, isTrue);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        FoundationProgressStorage.preferenceKey,
        '{bad',
      );
      Storage.resetCachesAfterExternalWrite();
      await expectLater(service.load(), throwsFormatException);
      await expectLater(
        service.markStepOpened(FoundationStep.sounds),
        throwsFormatException,
      );
      expect(platform.values[FoundationProgressStorage.preferenceKey], '{bad');
    },
  );
}
