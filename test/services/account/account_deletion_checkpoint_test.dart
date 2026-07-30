import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  test(
    'remote-complete checkpoint survives restart and never starts deletion twice',
    () async {
      AccountDeletionJournal? checkpoint;
      var remoteStarts = 0;
      var recoveryCalls = 0;
      final gate = AccountDeletionRemoteGate(
        readCheckpoint: () async => checkpoint,
        startOrResumeRemote: () async {
          remoteStarts += 1;
          checkpoint = _completedCheckpoint();
          throw const AccountDeletionRecoveryException(<Object>[
            'provider signout pending',
          ]);
        },
        recoverCompleted: (_) async {
          recoveryCalls += 1;
        },
      );

      await expectLater(
        gate.run(),
        throwsA(isA<AccountDeletionRecoveryException>()),
      );
      await gate.run();

      expect(remoteStarts, 1);
      expect(recoveryCalls, 1);
    },
  );

  test(
    'recovered anonymous plus provider signout failure never re-enters remote deletion',
    () async {
      final checkpoint = _completedCheckpoint(
        sourceProviders: const {'google'},
      );
      var remoteStarts = 0;
      var recoveryCalls = 0;
      final gate = AccountDeletionRemoteGate(
        readCheckpoint: () async => checkpoint,
        startOrResumeRemote: () async {
          remoteStarts += 1;
        },
        recoverCompleted: (journal) async {
          recoveryCalls += 1;
          expect(journal.sourceProviders, const {'google'});
          throw const AccountDeletionRecoveryException(<Object>[
            'provider signout pending',
          ]);
        },
      );

      await expectLater(
        gate.run(),
        throwsA(isA<AccountDeletionRecoveryException>()),
      );
      await expectLater(
        gate.run(),
        throwsA(isA<AccountDeletionRecoveryException>()),
      );

      expect(remoteStarts, 0);
      expect(recoveryCalls, 2);
    },
  );

  test('checkpoint provider metadata rejects unknown values', () {
    final json = _completedCheckpoint().toJson()
      ..['sourceProviders'] = <String>['google', 'private-provider-token'];

    expect(
      () => AccountDeletionJournal.fromJson(json),
      throwsA(isA<AccountOperationFailure>()),
    );
  });
}

AccountDeletionJournal _completedCheckpoint({
  Set<String> sourceProviders = const {'google'},
}) {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'deleted-source',
      epoch: 9,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'request-1',
    sourceProviders: sourceProviders,
    operation: const AccountOperationResult(
      operationId: 'deletion-operation-1',
      kind: AccountOperationKind.deletion,
      phase: AccountOperationPhase.completed,
      version: 7,
      attemptCount: 2,
      retryable: false,
    ),
  );
}
