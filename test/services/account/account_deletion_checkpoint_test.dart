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
      final events = <String>[];
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
          events.add('recover');
        },
        closeFeedback: () async => events.add('close-feedback'),
      );

      await expectLater(
        gate.run(),
        throwsA(isA<AccountDeletionRecoveryException>()),
      );
      await gate.run();

      expect(remoteStarts, 1);
      expect(recoveryCalls, 1);
      expect(events, <String>['close-feedback', 'recover']);
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

  test('checkpoint rejects unknown fields and secret material', () {
    final topLevel = _completedCheckpoint().toJson()
      ..['authorizationCode'] = 'private-secret';
    final nested = _completedCheckpoint().toJson();
    (nested['session']! as Map<String, Object?>)['token'] = 'private-token';
    final operation = _completedCheckpoint().toJson();
    (operation['operation']! as Map<String, Object?>)['proof'] =
        'private-proof';

    for (final json in <Map<String, Object?>>[topLevel, nested, operation]) {
      expect(
        () => AccountDeletionJournal.fromJson(json),
        throwsA(isA<AccountOperationFailure>()),
      );
    }
  });

  test('completed checkpoint rejects ready session and retryable terminal', () {
    final ready = _completedCheckpoint().toJson();
    (ready['session']! as Map<String, Object?>)['mode'] = 'ready';
    final retryable = _completedCheckpoint().toJson();
    (retryable['operation']! as Map<String, Object?>)['retryable'] = true;

    expect(
      () => AccountDeletionJournal.fromJson(ready),
      throwsA(isA<AccountOperationFailure>()),
    );
    expect(
      () => AccountDeletionJournal.fromJson(retryable),
      throwsA(isA<AccountOperationFailure>()),
    );
  });

  test(
    'missing operation is not completed and mismatched kind is rejected',
    () async {
      final pendingJson = _completedCheckpoint().toJson()..['operation'] = null;
      final pending = AccountDeletionJournal.fromJson(pendingJson);
      var remoteStarts = 0;
      await AccountDeletionRemoteGate(
        readCheckpoint: () async => pending,
        startOrResumeRemote: () async => remoteStarts += 1,
        recoverCompleted: (_) async => fail('must not recover'),
      ).run();
      expect(remoteStarts, 1);

      final mismatched = _completedCheckpoint().toJson();
      (mismatched['operation']! as Map<String, Object?>)['kind'] =
          'replacement';
      expect(
        () => AccountDeletionJournal.fromJson(mismatched),
        throwsA(isA<AccountOperationFailure>()),
      );
    },
  );

  test('checkpoint read failure never routes completed recovery', () async {
    var remoteStarts = 0;
    var recoveryCalls = 0;
    final gate = AccountDeletionRemoteGate(
      readCheckpoint: () async => throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      ),
      startOrResumeRemote: () async => remoteStarts += 1,
      recoverCompleted: (_) async => recoveryCalls += 1,
    );

    await expectLater(gate.run(), throwsA(isA<AccountOperationFailure>()));
    expect(remoteStarts, 0);
    expect(recoveryCalls, 0);
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
