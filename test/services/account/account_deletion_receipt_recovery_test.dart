import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_deletion_status_receipt.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  test(
    'source-less startup records receipt status without creating auth',
    () async {
      final harness = await _Harness.create(
        status: _operation(AccountOperationPhase.processorCleanupPending),
      );

      final result = await harness.coordinator.resume();

      expect(result, AccountDeletionReceiptRecoveryStatus.pending);
      expect(
        harness.journalStore.journal?.operation?.phase,
        AccountOperationPhase.processorCleanupPending,
      );
      expect(harness.statusCalls, 1);
      expect(harness.ackCalls, 0);
      expect(harness.recoveryCalls, 0);
      expect(harness.sessions.current, isNull);
      expect(await harness.receiptStore.read(), isNotNull);
    },
  );

  test(
    'durable completed journal precedes ack, secure clear, and recovery',
    () async {
      final harness = await _Harness.create(
        status: _operation(AccountOperationPhase.completed, retryable: false),
      );

      final result = await harness.coordinator.resume();

      expect(result, AccountDeletionReceiptRecoveryStatus.completed);
      expect(harness.ackSawCompletedJournal, isTrue);
      expect(harness.clearPrecededRecovery, isTrue);
      expect(harness.recoveryCalls, 1);
      expect(
        harness.journalStore.journal?.session.mode,
        CloudWriteMode.cleanupPending,
      );
      expect(await harness.receiptStore.read(), isNull);
    },
  );

  test(
    'a locally completed journal is revalidated against exact server status',
    () async {
      final harness = await _Harness.create(
        journalPhase: AccountOperationPhase.completed,
        journalMode: CloudWriteMode.cleanupPending,
        status: _operation(AccountOperationPhase.completed, retryable: false),
      );

      final result = await harness.coordinator.resume();

      expect(result, AccountDeletionReceiptRecoveryStatus.completed);
      expect(harness.statusCalls, 1);
      expect(harness.ackCalls, 1);
      expect(harness.recoveryCalls, 1);
    },
  );

  for (final terminalPhase in <AccountOperationPhase>[
    AccountOperationPhase.blocked,
    AccountOperationPhase.cancelled,
  ]) {
    test(
      'local completion never acknowledges authoritative ${terminalPhase.name}',
      () async {
        final harness = await _Harness.create(
          journalPhase: AccountOperationPhase.completed,
          journalMode: CloudWriteMode.cleanupPending,
          status: _operation(terminalPhase, retryable: false),
        );

        await expectLater(
          harness.coordinator.resume(),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(harness.statusCalls, 1);
        expect(harness.ackCalls, 0);
        expect(harness.recoveryCalls, 0);
        expect(await harness.receiptStore.read(), isNotNull);
      },
    );
  }

  test('completed status must be explicitly non-retryable', () async {
    final harness = await _Harness.create(
      journalPhase: AccountOperationPhase.completed,
      journalMode: CloudWriteMode.cleanupPending,
      status: _operation(AccountOperationPhase.completed, retryable: true),
    );

    await expectLater(
      harness.coordinator.resume(),
      throwsA(
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.invalidResponse,
        ),
      ),
    );

    expect(harness.ackCalls, 0);
    expect(await harness.receiptStore.read(), isNotNull);
  });

  test(
    'ack response loss keeps receipt and retries from completed journal',
    () async {
      final harness =
          await _Harness.create(
              status: _operation(
                AccountOperationPhase.completed,
                retryable: false,
              ),
            )
            ..failAck = true;

      final first = await harness.coordinator.resume();

      expect(first, AccountDeletionReceiptRecoveryStatus.unavailable);
      expect(
        harness.journalStore.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(await harness.receiptStore.read(), isNotNull);
      expect(harness.recoveryCalls, 0);

      harness.failAck = false;
      harness.statusFailure = const AccountOperationFailure(
        AccountOperationFailureCode.operationNotFound,
        retryable: false,
      );
      final second = await harness.coordinator.resume();

      expect(second, AccountDeletionReceiptRecoveryStatus.completed);
      expect(harness.statusCalls, 2);
      expect(harness.ackCalls, 2);
      expect(await harness.receiptStore.read(), isNull);
      expect(harness.recoveryCalls, 1);
    },
  );

  test(
    'completed journal write failure resumes from its exact cleanup session',
    () async {
      final harness =
          await _Harness.create(
              status: _operation(
                AccountOperationPhase.completed,
                retryable: false,
              ),
              restoreSession: true,
            )
            ..journalStore.writeFailures = 1;

      await expectLater(
        harness.coordinator.resume(),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(harness.sessions.current?.mode, CloudWriteMode.cleanupPending);
      expect(
        harness.journalStore.journal?.session.mode,
        CloudWriteMode.quiesced,
      );
      expect(harness.ackCalls, 0);
      expect(await harness.receiptStore.read(), isNotNull);

      final retry = await harness.coordinator.resume();

      expect(retry, AccountDeletionReceiptRecoveryStatus.completed);
      expect(harness.ackCalls, 1);
      expect(harness.recoveryCalls, 1);
      expect(await harness.receiptStore.read(), isNull);
    },
  );

  test('unrelated durable identity is blocked before capability use', () async {
    final harness = await _Harness.create(
      status: _operation(AccountOperationPhase.completed, retryable: false),
      identity: (uid: 'durable-other', isAnonymous: false),
    );

    await expectLater(
      harness.coordinator.resume(),
      throwsA(
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.blocked,
        ),
      ),
    );

    expect(harness.statusCalls, 0);
    expect(harness.ackCalls, 0);
    expect(await harness.receiptStore.read(), isNotNull);
  });

  test(
    'receipt cannot replace a journal operation with another operation',
    () async {
      final harness = await _Harness.create(
        status: _operation(
          AccountOperationPhase.completed,
          operationId: 'different-operation',
          retryable: false,
        ),
      );

      await expectLater(
        harness.coordinator.resume(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.code,
            'code',
            AccountOperationFailureCode.invalidResponse,
          ),
        ),
      );

      expect(harness.ackCalls, 0);
      expect(await harness.receiptStore.read(), isNotNull);
    },
  );

  for (final boundary in <String>[
    'status',
    'bind',
    'close',
    'write',
    'ack',
    'clear',
  ]) {
    test(
      'identity snapshot change during $boundary blocks later destructive steps',
      () async {
        final harness =
            await _Harness.create(
                status: _operation(
                  AccountOperationPhase.completed,
                  retryable: false,
                ),
                bindReceipt: boundary != 'bind',
              )
              ..mutateIdentityAt = boundary;

        await expectLater(
          harness.coordinator.resume(),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        if (boundary == 'status' ||
            boundary == 'bind' ||
            boundary == 'close' ||
            boundary == 'write') {
          expect(harness.ackCalls, 0);
          expect(await harness.receiptStore.read(), isNotNull);
        }
        if (boundary == 'ack') {
          expect(harness.ackCalls, 1);
          expect(await harness.receiptStore.read(), isNotNull);
        }
        expect(harness.recoveryCalls, 0);
      },
    );
  }
}

class _Harness {
  _Harness._({
    required this.journalStore,
    required this.receiptStore,
    required this.secureStorage,
    required this.sessions,
    required this.identity,
    required this.status,
  });

  static Future<_Harness> create({
    required AccountOperationResult status,
    AccountOperationPhase journalPhase = AccountOperationPhase.authDeleted,
    CloudWriteMode journalMode = CloudWriteMode.quiesced,
    bool bindReceipt = true,
    bool restoreSession = false,
    ({String? uid, bool isAnonymous}) identity = const (
      uid: null,
      isAnonymous: false,
    ),
  }) async {
    final journalStore = _JournalStore(
      AccountDeletionJournal.pending(
        session: CloudWriteSession(
          uid: 'deleted-source',
          epoch: 7,
          mode: journalMode,
        ),
        requestKey: 'request-1',
      ).copyWith(
        operation: _operation(
          journalPhase,
          retryable: journalPhase != AccountOperationPhase.completed,
        ),
      ),
    );
    final secureStorage = _SecureStorage();
    final receiptStore = AccountDeletionStatusReceiptStore(
      storage: secureStorage,
      generateReceipt: () => 'A' * 43,
    );
    final receipt = await receiptStore.create(
      sourceUid: 'deleted-source',
      requestKey: 'request-1',
    );
    if (bindReceipt) {
      await receiptStore.bindOperation(
        expected: receipt,
        operationId: 'operation-1',
      );
    }
    final sessions = CloudWriteSessionController();
    if (restoreSession) {
      sessions.resume(
        journalStore.journal!.session,
        expectedUid: 'deleted-source',
      );
    }
    final harness = _Harness._(
      journalStore: journalStore,
      receiptStore: receiptStore,
      secureStorage: secureStorage,
      sessions: sessions,
      identity: identity,
      status: status,
    );
    journalStore.onWrite = () => harness._mutateIdentity('write');
    secureStorage.onWrite = () => harness._mutateIdentity('bind');
    secureStorage.onDelete = () => harness._mutateIdentity('clear');
    return harness;
  }

  final _JournalStore journalStore;
  final AccountDeletionStatusReceiptStore receiptStore;
  final _SecureStorage secureStorage;
  final CloudWriteSessionController sessions;
  ({String? uid, bool isAnonymous}) identity;
  final AccountOperationResult status;
  int statusCalls = 0;
  int ackCalls = 0;
  int recoveryCalls = 0;
  bool failAck = false;
  AccountOperationFailure? statusFailure;
  String? mutateIdentityAt;
  bool ackSawCompletedJournal = false;
  bool clearPrecededRecovery = false;

  AccountDeletionReceiptRecoveryCoordinator get coordinator {
    return AccountDeletionReceiptRecoveryCoordinator(
      journalStore: journalStore,
      receiptStore: receiptStore,
      sessions: sessions,
      currentIdentity: () => identity,
      readStatus: (_) async {
        statusCalls += 1;
        _mutateIdentity('status');
        final failure = statusFailure;
        if (failure != null) {
          statusFailure = null;
          throw failure;
        }
        return status;
      },
      acknowledge: (_) async {
        ackCalls += 1;
        ackSawCompletedJournal =
            journalStore.journal?.operation?.phase ==
                AccountOperationPhase.completed &&
            journalStore.journal?.session.mode == CloudWriteMode.cleanupPending;
        _mutateIdentity('ack');
        if (failAck) {
          throw const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          );
        }
      },
      closeFeedback: () async => _mutateIdentity('close'),
      recoverCompleted: (_) async {
        recoveryCalls += 1;
        clearPrecededRecovery = await receiptStore.read() == null;
      },
    );
  }

  void _mutateIdentity(String boundary) {
    if (mutateIdentityAt != boundary) return;
    mutateIdentityAt = null;
    identity = (uid: 'durable-other', isAnonymous: false);
  }
}

class _JournalStore implements AccountDeletionJournalStore {
  _JournalStore(this.journal);

  AccountDeletionJournal? journal;
  void Function()? onWrite;
  int writeFailures = 0;

  @override
  Future<AccountDeletionJournal?> read() async => journal;

  @override
  Future<void> write(AccountDeletionJournal value) async {
    if (writeFailures > 0) {
      writeFailures -= 1;
      throw StateError('journal unavailable');
    }
    journal = value;
    onWrite?.call();
  }

  @override
  Future<void> clearCompleted(String operationId) async {
    throw UnimplementedError();
  }
}

class _SecureStorage implements AccountDeletionStatusReceiptSecureStorage {
  String? value;
  void Function()? onWrite;
  void Function()? onDelete;

  @override
  Future<void> delete() async {
    value = null;
    onDelete?.call();
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String next) async {
    value = next;
    onWrite?.call();
  }
}

AccountOperationResult _operation(
  AccountOperationPhase phase, {
  String operationId = 'operation-1',
  bool retryable = true,
}) {
  return AccountOperationResult(
    operationId: operationId,
    kind: AccountOperationKind.deletion,
    phase: phase,
    version: 4,
    attemptCount: 0,
    retryable: retryable,
  );
}
