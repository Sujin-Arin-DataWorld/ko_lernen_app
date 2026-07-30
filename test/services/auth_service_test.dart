import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/push_service.dart';

void main() {
  test(
    'deletion requests and polls the server without direct client deletion',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        )
        ..statusResults.addAll([
          _operation(AccountOperationPhase.userTreeDeleting, version: 2),
          _operation(AccountOperationPhase.completed, version: 8),
        ]);
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await coordinator.deleteAccount();

      expect(events, [
        'google-reauth',
        'push-remove:user-1',
        'journal-write:pending',
        'request:request-key-1',
        'journal-write:operation-1',
        'status:operation-1',
        'journal-write:operation-1',
        'status:operation-1',
        'journal-write:operation-1',
        'journal-write:operation-1',
      ]);
      expect(operations.requestCalls, 1);
      expect(operations.statusCalls, 2);
      expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
    },
  );

  test(
    'Apple code is transient and completed only through the server',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: false,
          isAppleLinked: true,
        )
        ..appleAuthorizationCode = 'one-use-code'
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        )
        ..statusResults.add(
          _operation(AccountOperationPhase.appleRevocationPending, version: 4),
        )
        ..appleResults.add(
          _operation(AccountOperationPhase.authDeleted, version: 5),
        )
        ..statusResults.add(
          _operation(AccountOperationPhase.completed, version: 8),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await coordinator.deleteAccount();

      expect(
        events,
        containsAllInOrder([
          'apple-reauth',
          'request:request-key-1',
          'status:operation-1',
          'apple-complete:operation-1:4:one-use-code',
          'status:operation-1',
        ]),
      );
      expect(
        operations.journalWrites.every(
          (journal) => !journal.toJson().toString().contains('one-use-code'),
        ),
        isTrue,
      );
    },
  );

  test('unknown status persists and resume never reissues deletion', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..requestResults.add(_operation(AccountOperationPhase.deletionRequested))
      ..statusFailures.add(
        const AccountOperationFailure(
          AccountOperationFailureCode.unavailable,
          retryable: true,
        ),
      );
    final firstSessions = _readySessions();
    final firstCoordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, firstSessions),
      sessions: firstSessions,
      pollDelay: (_) async {},
    );

    await expectLater(
      firstCoordinator.deleteAccount(),
      throwsA(isA<AccountOperationFailure>()),
    );

    expect(operations.requestCalls, 1);
    expect(firstSessions.current?.mode, CloudWriteMode.blocked);
    final durableJournal = operations.journal;
    expect(durableJournal?.operationId, 'operation-1');

    operations.statusResults.add(
      _operation(AccountOperationPhase.completed, version: 8),
    );
    final restartedSessions = CloudWriteSessionController();
    restartedSessions.resume(
      durableJournal!.session,
      expectedUid: operations.userId,
    );
    final restartedCoordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, restartedSessions),
      sessions: restartedSessions,
      pollDelay: (_) async {},
    );

    await restartedCoordinator.resumePendingDeletion();

    expect(operations.requestCalls, 1);
    expect(operations.statusCalls, 2);
    expect(restartedSessions.current?.mode, CloudWriteMode.cleanupPending);
  });
}

AccountOperationResult _operation(
  AccountOperationPhase phase, {
  int version = 1,
}) {
  return AccountOperationResult(
    operationId: 'operation-1',
    kind: AccountOperationKind.deletion,
    phase: phase,
    version: version,
    attemptCount: 0,
    retryable: phase != AccountOperationPhase.completed,
  );
}

CloudWriteSessionController _readySessions() {
  final sessions = CloudWriteSessionController();
  sessions.acquire('user-1');
  return sessions;
}

PushOwnershipTransitionCoordinator _ownership(
  List<String> events,
  CloudWriteSessionController sessions,
) {
  return PushOwnershipTransitionCoordinator(
    push: _FakePush(events),
    notificationsEnabled: () => false,
    sessions: sessions,
  );
}

class _FakeDeletionOperations implements AccountDeletionOperations {
  _FakeDeletionOperations(this.events);

  final List<String> events;
  AuthProviderState providers = const AuthProviderState(
    isGoogleLinked: false,
    isAppleLinked: false,
  );
  String? appleAuthorizationCode;
  AccountDeletionJournal? journal;
  final List<AccountDeletionJournal> journalWrites = [];
  final List<AccountOperationResult> requestResults = [];
  final List<AccountOperationResult> statusResults = [];
  final List<AccountOperationResult> appleResults = [];
  final List<AccountOperationFailure> statusFailures = [];
  int requestCalls = 0;
  int statusCalls = 0;

  @override
  String get userId => 'user-1';

  @override
  AuthProviderState get providerState => providers;

  @override
  String createRequestKey() => 'request-key-1';

  @override
  Future<AccountDeletionJournal?> readDeletionJournal() async => journal;

  @override
  Future<void> writeDeletionJournal(AccountDeletionJournal value) async {
    journal = value;
    journalWrites.add(value);
    events.add('journal-write:${value.operationId ?? 'pending'}');
  }

  @override
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  ) async {
    requestCalls += 1;
    events.add('request:${request.requestKey}');
    return requestResults.removeAt(0);
  }

  @override
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  ) async {
    statusCalls += 1;
    events.add('status:${request.operationId}');
    if (statusFailures.isNotEmpty) {
      throw statusFailures.removeAt(0);
    }
    return statusResults.removeAt(0);
  }

  @override
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  ) async {
    events.add(
      'apple-complete:${request.operationId}:'
      '${request.expectedVersion}:${request.authorizationCode}',
    );
    return appleResults.removeAt(0);
  }

  @override
  Future<String?> reauthenticateWithApple() async {
    events.add('apple-reauth');
    return appleAuthorizationCode;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    events.add('google-reauth');
  }
}

class _FakePush implements PushTokenOwner {
  _FakePush(this.events);

  final List<String> events;

  @override
  Future<void> bindCurrentUser() async => events.add('push-bind');

  @override
  Future<void> removeTokenFrom(String uid) async {
    events.add('push-remove:$uid');
  }
}
