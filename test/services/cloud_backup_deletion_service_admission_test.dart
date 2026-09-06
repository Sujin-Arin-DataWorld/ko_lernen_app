import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AdmissionJournalStore journal;
  late _NoopGateway gateway;
  late List<String> operations;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    journal = _AdmissionJournalStore(
      const SharedPreferencesCloudBackupDeletionJournalStore(),
    );
    operations = <String>[];
    gateway = _NoopGateway();
    final coordinator = CloudBackupDeletionCoordinator(
      sessions: CloudWriteSessionController()..acquire('durable'),
      currentUid: () => 'durable',
      journalStore: journal,
      gateway: gateway,
      createRequestKey: () => 'A' * 43,
    );
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(coordinator);
    AuthService.overrideDeleteAccountForTesting(() async {
      operations.add('delete-account');
    });
    CloudSync.overrideOperationsForTesting(
      backupWithResult: () async {
        operations.add('backup');
        return CloudWriteResult.completed;
      },
      restore: () async {
        operations.add('restore');
        return true;
      },
    );
  });

  tearDown(() {
    AuthService.resetCloudBackupDeletionForTesting();
    CloudSync.resetOperationsForTesting();
  });

  test(
    'direct services block loading admission before any operation starts',
    () async {
      final releaseRead = Completer<void>();
      final readStarted = Completer<void>();
      journal
        ..readBarrier = releaseRead.future
        ..readStarted = readStarted;

      final backup = CloudSync.backupWithResult();
      final restore = CloudSync.restore();
      final deletion = AuthService.deleteAccount(closeFeedback: () async {});

      await readStarted.future;
      expect(operations, isEmpty);

      releaseRead.complete();

      expect(await backup, CloudWriteResult.completed);
      expect(await restore, isTrue);
      await deletion;
      expect(operations, <String>['backup', 'restore', 'delete-account']);
      expect(journal.readCalls, 3);
    },
  );

  test(
    'direct backup/restore still block on a persisted pending journal, but '
    'account deletion (T5) tolerates it',
    () async {
      await journal.write(
        CloudBackupDeletionJournal.pending(
          session: const CloudWriteSession(
            uid: 'durable',
            epoch: 4,
            mode: CloudWriteMode.cleanupPending,
          ),
          requestKey: 'P' * 43,
        ),
      );

      await CloudSync.backup();
      expect(await CloudSync.backupWithResult(), CloudWriteResult.blocked);
      expect(await CloudSync.restore(), isFalse);
      // T5: a pending cloud-backup-deletion journal only cleans up server
      // data and never locks the deletion lane — deleteAccount is admitted.
      await AuthService.deleteAccount(closeFeedback: () async {});

      expect(operations, <String>['delete-account']);
    },
  );

  test(
    'direct account deletion does not start beside a replacement checkpoint',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.storageKey,
        'replacement-pending',
      );

      await expectLater(
        AuthService.deleteAccount(closeFeedback: () async {}),
        throwsA(
          isA<AccountOperationFailure>()
              .having(
                (failure) => failure.code,
                'code',
                AccountOperationFailureCode.blocked,
              )
              .having((failure) => failure.retryable, 'retryable', isFalse),
        ),
      );

      expect(operations, isEmpty);
    },
  );

  test(
    'activation handoff blocks ordinary work but admits only its exact UID',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionFeedbackActivationCheckpointPreferenceKey,
        _completedActivationCheckpointJson(),
      );

      final ordinary = await AuthService.runDurableAccountAdmission<bool>(
        onAdmitted: () async => true,
        onBlocked: () async => false,
      );
      final exact =
          await AuthService.runCompletedDeletionFeedbackActivationAdmission<
            bool
          >(
            deletedUid: 'deleted-source',
            onAdmitted: () async => true,
            onBlocked: () async => false,
          );
      final wrong =
          await AuthService.runCompletedDeletionFeedbackActivationAdmission<
            bool
          >(
            deletedUid: 'different-source',
            onAdmitted: () async => true,
            onBlocked: () async => false,
          );

      expect(ordinary, isFalse);
      expect(exact, isTrue);
      expect(wrong, isFalse);
    },
  );

  test(
    'direct sign out blocks a replacement checkpoint before identity work',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.storageKey,
        'replacement-pending',
      );

      await expectLater(
        AuthService.signOut(),
        throwsA(isA<CloudBackupDeletionIdentityChangeBlockedException>()),
      );
    },
  );

  test(
    'direct Google link blocks an account deletion checkpoint before identity work',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        'account-deletion-pending',
      );

      await expectLater(
        AuthService.linkWithGoogle(),
        throwsA(isA<CloudBackupDeletionIdentityChangeBlockedException>()),
      );
    },
  );

  test(
    'direct Apple link blocks an account deletion checkpoint before identity work',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        'account-deletion-pending',
      );

      await expectLater(
        AuthService.linkWithApple(),
        throwsA(isA<CloudBackupDeletionIdentityChangeBlockedException>()),
      );
    },
  );

  test(
    'account deletion admission permits its own durable checkpoint to resume',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        'account-deletion-pending',
      );

      await AuthService.deleteAccount(closeFeedback: () async {});

      expect(operations, <String>['delete-account']);
    },
  );

  test(
    'direct cloud deletion does not start beside a replacement checkpoint',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.storageKey,
        'replacement-pending',
      );

      expect(await AuthService.deleteCloudData(), CloudWriteResult.blocked);
      expect(gateway.deleteCalls, 0);
    },
  );

  test(
    'direct cloud deletion still starts when every durable checkpoint is clear',
    () async {
      expect(await AuthService.deleteCloudData(), CloudWriteResult.completed);
      expect(gateway.deleteCalls, 1);
    },
  );

  test(
    'direct cloud deletion does not start beside an account deletion checkpoint',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        'account-deletion-pending',
      );

      expect(await AuthService.deleteCloudData(), CloudWriteResult.blocked);
      expect(gateway.deleteCalls, 0);
    },
  );

  test('direct services fail closed when journal reload fails', () async {
    journal.failedReads = 4;

    await CloudSync.backup();
    expect(await CloudSync.backupWithResult(), CloudWriteResult.blocked);
    expect(await CloudSync.restore(), isFalse);
    await expectLater(
      AuthService.deleteAccount(closeFeedback: () async {}),
      throwsA(
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.blocked,
        ),
      ),
    );

    expect(operations, isEmpty);
  });

  test('direct services share one serial admission lane', () async {
    final backupStarted = Completer<void>();
    final releaseBackup = Completer<void>();
    CloudSync.overrideOperationsForTesting(
      backupWithResult: () async {
        operations.add('backup');
        backupStarted.complete();
        await releaseBackup.future;
        return CloudWriteResult.completed;
      },
      restore: () async {
        operations.add('restore');
        return true;
      },
    );

    final backup = CloudSync.backupWithResult();
    await backupStarted.future;
    final restore = CloudSync.restore();
    final deletion = AuthService.deleteAccount(closeFeedback: () async {});
    await Future<void>.delayed(Duration.zero);

    expect(operations, <String>['backup']);
    expect(journal.readCalls, 1);

    releaseBackup.complete();

    expect(await backup, CloudWriteResult.completed);
    expect(await restore, isTrue);
    await deletion;
    expect(operations, <String>['backup', 'restore', 'delete-account']);
    expect(journal.readCalls, 3);
  });

  test(
    'direct services run only after a fresh persisted clear admission',
    () async {
      await CloudSync.backup();
      expect(await CloudSync.backupWithResult(), CloudWriteResult.completed);
      expect(await CloudSync.restore(), isTrue);
      await AuthService.deleteAccount(closeFeedback: () async {});

      expect(operations, <String>[
        'backup',
        'backup',
        'restore',
        'delete-account',
      ]);
      expect(journal.readCalls, 4);
    },
  );
}

String _completedActivationCheckpointJson() {
  return jsonEncode(
    AccountDeletionJournal(
      version: AccountDeletionJournal.currentVersion,
      session: const CloudWriteSession(
        uid: 'deleted-source',
        epoch: 9,
        mode: CloudWriteMode.cleanupPending,
      ),
      requestKey: 'activation-request-1',
      operation: const AccountOperationResult(
        operationId: 'activation-operation-1',
        kind: AccountOperationKind.deletion,
        phase: AccountOperationPhase.completed,
        version: 3,
        attemptCount: 1,
        retryable: false,
      ),
    ).toJson(),
  );
}

class _AdmissionJournalStore implements CloudBackupDeletionJournalStore {
  _AdmissionJournalStore(this._delegate);

  final CloudBackupDeletionJournalStore _delegate;
  Completer<void>? readStarted;
  Future<void>? readBarrier;
  int readCalls = 0;
  int failedReads = 0;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) =>
      _delegate.clearIfCurrent(expected);

  @override
  Future<CloudBackupDeletionJournal?> read() async {
    readCalls += 1;
    if (readStarted case final started? when !started.isCompleted) {
      started.complete();
    }
    await readBarrier;
    if (failedReads > 0) {
      failedReads -= 1;
      throw StateError('durable journal reload failed');
    }
    return _delegate.read();
  }

  @override
  Future<void> write(CloudBackupDeletionJournal journal) =>
      _delegate.write(journal);
}

class _NoopGateway implements CloudBackupDeletionGateway {
  int deleteCalls = 0;

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    deleteCalls += 1;
    return CloudBackupDeletionRemoteState.completed;
  }
}
