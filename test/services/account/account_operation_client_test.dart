import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/firebase_app_check_initializer.dart';

void main() {
  group('FirebaseAppCheckInitializer', () {
    test('uses debug providers only in debug builds', () async {
      AndroidProvider? android;
      AppleProvider? apple;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: true,
        activate: ({required androidProvider, required appleProvider}) async {
          android = androidProvider;
          apple = appleProvider;
        },
      );

      await initializer.initialize();

      expect(android, AndroidProvider.debug);
      expect(apple, AppleProvider.debug);
    });

    test('uses attestation providers in release builds', () async {
      AndroidProvider? android;
      AppleProvider? apple;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: false,
        activate: ({required androidProvider, required appleProvider}) async {
          android = androidProvider;
          apple = appleProvider;
        },
      );

      await initializer.initialize();

      expect(android, AndroidProvider.playIntegrity);
      expect(apple, AppleProvider.appAttestWithDeviceCheckFallback);
    });
  });

  group('AccountOperationClient', () {
    test('transport call equality has an order-independent hash', () {
      const first = AccountOperationTransportCall(
        name: 'getAccountOperation',
        data: {'operationId': 'operation-1', 'expectedVersion': 4},
      );
      const second = AccountOperationTransportCall(
        name: 'getAccountOperation',
        data: {'expectedVersion': 4, 'operationId': 'operation-1'},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('uses europe-west3 and returns a typed deletion operation', () async {
      String? selectedRegion;
      final transport = _FakeTransport()
        ..responses.add({
          'operationId': 'operation-1',
          'kind': 'deletion',
          'phase': 'deletionRequested',
          'version': 1,
          'attemptCount': 0,
          'retryable': true,
          'blockedReason': null,
        });
      final client = AccountOperationClient.firebase(
        transportForRegion: (region) {
          selectedRegion = region;
          return transport;
        },
      );

      final result = await client.requestAccountDeletion(
        const AccountDeletionRequest(requestKey: 'request-1'),
      );

      expect(selectedRegion, 'europe-west3');
      expect(
        transport.calls.single,
        const AccountOperationTransportCall(
          name: 'requestAccountDeletion',
          data: {'requestKey': 'request-1'},
        ),
      );
      expect(result.operationId, 'operation-1');
      expect(result.kind, AccountOperationKind.deletion);
      expect(result.phase, AccountOperationPhase.deletionRequested);
      expect(result.version, 1);
      expect(result.retryable, isTrue);
    });

    test('maps safe callable details to a typed failure', () async {
      final transport = _FakeTransport()
        ..failures.add(
          const AccountOperationTransportException(
            code: 'failed-precondition',
            safeCode: 'recent-authentication-required',
            unsafeMessage: 'raw Firebase token secret-value',
          ),
        );
      final client = AccountOperationClient(transport: transport);

      Object? caught;
      try {
        await client.requestAccountDeletion(
          const AccountDeletionRequest(requestKey: 'request-1'),
        );
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<AccountOperationFailure>());
      final failure = caught! as AccountOperationFailure;
      expect(
        failure.code,
        AccountOperationFailureCode.recentAuthenticationRequired,
      );
      expect(failure.retryable, isFalse);
      expect(failure.toString(), isNot(contains('secret-value')));
      expect(failure.toString(), isNot(contains('Firebase')));
    });

    test(
      'rejects malformed callable data without exposing raw values',
      () async {
        final transport = _FakeTransport()
          ..responses.add({
            'operationId': 'operation-1',
            'kind': 'deletion',
            'phase': 'not-a-server-phase-secret',
            'version': 1,
            'attemptCount': 0,
            'retryable': true,
            'blockedReason': null,
          });
        final client = AccountOperationClient(transport: transport);

        await expectLater(
          client.requestAccountDeletion(
            const AccountDeletionRequest(requestKey: 'request-1'),
          ),
          throwsA(
            isA<AccountOperationFailure>()
                .having(
                  (failure) => failure.code,
                  'code',
                  AccountOperationFailureCode.invalidResponse,
                )
                .having(
                  (failure) => failure.toString(),
                  'safe text',
                  isNot(contains('not-a-server-phase-secret')),
                ),
          ),
        );
      },
    );

    test('bounds transient retries to idempotent status reads', () async {
      final statusTransport = _FakeTransport()
        ..failures.addAll([
          const AccountOperationTransportException(code: 'unavailable'),
          const AccountOperationTransportException(code: 'deadline-exceeded'),
        ])
        ..responses.add({
          'operationId': 'operation-1',
          'kind': 'deletion',
          'phase': 'completed',
          'version': 8,
          'attemptCount': 3,
          'retryable': false,
          'blockedReason': null,
        });
      final delays = <Duration>[];
      final statusClient = AccountOperationClient(
        transport: statusTransport,
        retryDelay: (duration) async => delays.add(duration),
      );

      final result = await statusClient.getAccountOperation(
        const AccountOperationStatusRequest(operationId: 'operation-1'),
      );

      expect(result.phase, AccountOperationPhase.completed);
      expect(statusTransport.calls, hasLength(3));
      expect(delays, hasLength(2));

      final requestTransport = _FakeTransport()
        ..failures.add(
          const AccountOperationTransportException(code: 'unavailable'),
        );
      final requestClient = AccountOperationClient(transport: requestTransport);

      await expectLater(
        requestClient.requestAccountDeletion(
          const AccountDeletionRequest(requestKey: 'request-1'),
        ),
        throwsA(isA<AccountOperationFailure>()),
      );
      expect(requestTransport.calls, hasLength(1));
    });

    test('sends Apple authorization only to the completion callable', () async {
      final transport = _FakeTransport()
        ..responses.add({
          'operationId': 'operation-1',
          'kind': 'deletion',
          'phase': 'authDeleted',
          'version': 5,
          'attemptCount': 2,
          'retryable': true,
          'blockedReason': null,
        });
      final client = AccountOperationClient(transport: transport);

      await client.completeAppleRevocation(
        const AppleRevocationCompletionRequest(
          operationId: 'operation-1',
          expectedVersion: 4,
          authorizationCode: 'one-use-code',
        ),
      );

      expect(
        transport.calls.single,
        const AccountOperationTransportCall(
          name: 'completeAppleRevocation',
          data: {
            'operationId': 'operation-1',
            'expectedVersion': 4,
            'authorizationCode': 'one-use-code',
          },
        ),
      );
    });
  });
}

class _FakeTransport implements AccountOperationTransport {
  final List<AccountOperationTransportCall> calls = [];
  final List<Object?> responses = [];
  final List<AccountOperationTransportException> failures = [];

  @override
  Future<Object?> call(AccountOperationTransportCall call) async {
    calls.add(call);
    if (failures.isNotEmpty) {
      throw failures.removeAt(0);
    }
    return responses.removeAt(0);
  }
}
