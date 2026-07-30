import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/push_service.dart';

void main() {
  group('anonymous credential linking', () {
    for (final provider in AccountLinkProvider.values) {
      test(
        '${provider.name} collision is typed and preserves the primary user',
        () async {
          var primaryUid = 'anonymous-source';

          final result = await attemptAnonymousCredentialLink<String>(
            provider: provider,
            sourceUid: primaryUid,
            currentUid: () => primaryUid,
            linkCredential: () async {
              throw FirebaseAuthException(
                code: 'credential-already-in-use',
                message: 'unsafe provider detail',
              );
            },
          );

          expect(
            result,
            isA<ExistingAccountLinkConflict>().having(
              (conflict) => conflict.provider,
              'provider',
              provider,
            ),
          );
          expect(primaryUid, 'anonymous-source');
          expect(result.toString(), isNot(contains('unsafe provider detail')));
        },
      );
    }

    test('durable-to-durable transition is blocked before credential use', () {
      var linkCalls = 0;

      expect(
        () => attemptAnonymousCredentialLink<String>(
          provider: AccountLinkProvider.google,
          sourceUid: 'durable-source',
          sourceIsAnonymous: false,
          currentUid: () => 'durable-source',
          linkCredential: () async {
            linkCalls += 1;
            return 'wrong-target';
          },
        ),
        throwsA(isA<DurableAccountTransitionNotSupported>()),
      );
      expect(linkCalls, 0);
    });

    test(
      'isolated Firebase verifier disposes its temporary app on failure',
      () async {
        final context = _FakeTemporaryAuthContext()
          ..signInFailure = StateError('invalid target');
        final verifier = FirebaseIsolatedTargetVerifier(
          openContext: () async => context,
          acquireCredential: (_) async =>
              GoogleAuthProvider.credential(idToken: 'fresh-id-token'),
        );

        await expectLater(
          verifier.verify(AccountLinkProvider.google),
          throwsA(isA<StateError>()),
        );

        expect(context.disposeCalls, 1);
      },
    );

    test(
      'isolated Firebase target owns a secondary callable gateway',
      () async {
        final context = _FakeTemporaryAuthContext();
        final verifier = FirebaseIsolatedTargetVerifier(
          openContext: () async => context,
          acquireCredential: (_) async =>
              GoogleAuthProvider.credential(idToken: 'fresh-id-token'),
        );

        final target = await verifier.verify(AccountLinkProvider.google);

        expect(target.uid, 'durable-target');
        expect(target.isAnonymous, isFalse);
        expect(target, isA<AccountOperationTargetContext>());
        expect(
          (target as AccountOperationTargetContext).operationGateway,
          same(context.operationGateway),
        );
        await target.dispose();
        expect(context.disposeCalls, 1);
      },
    );

    test(
      'primary target activation is fenced after credential acquisition',
      () async {
        final sessions = CloudWriteSessionController()
          ..acquire('anonymous-source');
        final expected = sessions.transition(CloudWriteMode.cleanupPending);
        var primaryUid = 'anonymous-source';
        var primaryIsAnonymous = true;
        var signInCalls = 0;
        final identity = FirebaseAccountTransitionIdentity.test(
          currentUid: () => primaryUid,
          currentIsAnonymous: () => primaryIsAnonymous,
          acquireCredential: (_) async {
            sessions
              ..transition(CloudWriteMode.blocked)
              ..transition(CloudWriteMode.cleanupPending);
            return GoogleAuthProvider.credential(idToken: 'fresh-id-token');
          },
          signIn: (_) async {
            signInCalls += 1;
            primaryUid = 'durable-target';
            primaryIsAnonymous = false;
            return primaryUid;
          },
          signOut: () async {},
        );

        await expectLater(
          identity.activateTarget(
            AccountLinkProvider.google,
            expectedTargetUid: 'durable-target',
            expectedSourceSession: expected,
            sessions: sessions,
            allowMissingSource: true,
          ),
          throwsA(isA<AccountLinkSafetyFailure>()),
        );

        expect(signInCalls, 0);
        expect(primaryUid, 'anonymous-source');
      },
    );

    test(
      'primary activation rejects a returned target when live auth changed',
      () async {
        final sessions = CloudWriteSessionController()
          ..acquire('anonymous-source');
        final expected = sessions.transition(CloudWriteMode.cleanupPending);
        String? currentUid = 'anonymous-source';
        var currentIsAnonymous = true;
        var signOutCalls = 0;
        final identity = FirebaseAccountTransitionIdentity.test(
          currentUid: () => currentUid,
          currentIsAnonymous: () => currentIsAnonymous,
          acquireCredential: (_) async =>
              GoogleAuthProvider.credential(idToken: 'fresh-id-token'),
          signIn: (_) async {
            currentUid = 'unexpected-durable-account';
            currentIsAnonymous = false;
            return 'durable-target';
          },
          signOut: () async {
            signOutCalls += 1;
            currentUid = null;
          },
        );

        await expectLater(
          identity.activateTarget(
            AccountLinkProvider.google,
            expectedTargetUid: 'durable-target',
            expectedSourceSession: expected,
            sessions: sessions,
            allowMissingSource: true,
          ),
          throwsA(isA<AccountLinkSafetyFailure>()),
        );

        expect(signOutCalls, 1);
        expect(currentUid, isNull);
      },
    );

    test('primary activation verifies the live expected target', () async {
      final sessions = CloudWriteSessionController()
        ..acquire('anonymous-source');
      final expected = sessions.transition(CloudWriteMode.cleanupPending);
      String? currentUid = 'anonymous-source';
      var currentIsAnonymous = true;
      var signOutCalls = 0;
      final identity = FirebaseAccountTransitionIdentity.test(
        currentUid: () => currentUid,
        currentIsAnonymous: () => currentIsAnonymous,
        acquireCredential: (_) async =>
            GoogleAuthProvider.credential(idToken: 'fresh-id-token'),
        signIn: (_) async {
          currentUid = 'durable-target';
          currentIsAnonymous = false;
          return currentUid;
        },
        signOut: () async => signOutCalls += 1,
      );

      await identity.activateTarget(
        AccountLinkProvider.google,
        expectedTargetUid: 'durable-target',
        expectedSourceSession: expected,
        sessions: sessions,
        allowMissingSource: true,
      );

      expect(currentUid, 'durable-target');
      expect(signOutCalls, 0);
    });
  });

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
        'identity-recover',
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

  test(
    'a pre-call freshness failure keeps a pending deletion retryable',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestFailures.add(
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
      final pending = operations.journal;
      expect(pending, isNotNull);
      expect(pending?.operation, isNull);
      expect(operations.requestCalls, 1);

      operations.requestResults.add(
        _operation(AccountOperationPhase.completed),
      );
      final restartedSessions = CloudWriteSessionController();
      restartedSessions.resume(
        pending!.session,
        expectedUid: operations.userId,
      );
      final restarted = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, restartedSessions),
        sessions: restartedSessions,
        pollDelay: (_) async {},
      );

      await restarted.resumePendingDeletion();

      expect(operations.requestCalls, 2);
      expect(operations.journal?.operationId, 'operation-1');
      expect(operations.recoveryCalls, 1);
    },
  );

  test('missing Apple code is a safe typed pre-request failure', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..providers = const AuthProviderState(
        isGoogleLinked: false,
        isAppleLinked: true,
      );
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
      pollDelay: (_) async {},
    );

    await expectLater(
      coordinator.deleteAccount(),
      throwsA(
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.recentAuthenticationRequired,
        ),
      ),
    );

    expect(events, <String>['apple-reauth']);
    expect(operations.requestCalls, 0);
  });

  test('dual-linked deletion selects Apple and never Google reauth', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..providers = const AuthProviderState(
        isGoogleLinked: true,
        isAppleLinked: true,
      )
      ..appleAuthorizationCode = 'apple-code'
      ..requestResults.add(_operation(AccountOperationPhase.completed));
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
      pollDelay: (_) async {},
    );

    await coordinator.deleteAccount();

    expect(events.first, 'apple-reauth');
    expect(events, isNot(contains('google-reauth')));
    expect(operations.recoveryCalls, 1);
  });

  test('typed recent-auth failure stops local privacy cleanup', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..providers = const AuthProviderState(
        isGoogleLinked: true,
        isAppleLinked: false,
      )
      ..googleReauthFailure = const AccountOperationFailure(
        AccountOperationFailureCode.recentAuthenticationRequired,
        retryable: false,
      );
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
      pollDelay: (_) async {},
    );
    final cleanup = _CleanupOperations(events, coordinator.deleteAccount);

    await expectLater(
      AccountDeletionWorkflow(cleanup).run(),
      throwsA(isA<AccountOperationFailure>()),
    );

    expect(events, <String>['google-reauth']);
    expect(operations.requestCalls, 0);
  });

  test(
    'raw Firebase recent-login error maps to the typed prerequisite',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..googleReauthFailure = FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'unsafe provider detail',
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      Object? caught;
      try {
        await coordinator.deleteAccount();
      } catch (error) {
        caught = error;
      }

      expect(
        caught,
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.recentAuthenticationRequired,
        ),
      );
      expect(caught.toString(), isNot(contains('unsafe provider detail')));
      expect(operations.requestCalls, 0);
    },
  );

  test('server-blocked deletion stops local privacy cleanup', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..requestResults.add(_operation(AccountOperationPhase.deletionRequested))
      ..statusResults.add(_operation(AccountOperationPhase.blocked));
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
      pollDelay: (_) async {},
    );
    final cleanup = _CleanupOperations(events, coordinator.deleteAccount);

    await expectLater(
      AccountDeletionWorkflow(cleanup).run(),
      throwsA(
        isA<AccountOperationFailure>().having(
          (failure) => failure.code,
          'code',
          AccountOperationFailureCode.blocked,
        ),
      ),
    );

    expect(events, isNot(contains('local-reset')));
    expect(operations.recoveryCalls, 0);
  });

  test(
    'completed server deletion recovers identity before local cleanup',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(_operation(AccountOperationPhase.completed));
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await AccountDeletionWorkflow(
        _CleanupOperations(events, coordinator.deleteAccount),
      ).run();

      expect(
        events,
        containsAllInOrder(<String>['identity-recover', 'local-reset']),
      );
      expect(operations.recoveryCalls, 1);
    },
  );

  test(
    'post-server identity recovery failure still runs local cleanup safely',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(_operation(AccountOperationPhase.completed))
        ..recoveryFailure = StateError('private recovery detail');
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await expectLater(
        AccountDeletionWorkflow(
          _CleanupOperations(events, coordinator.deleteAccount),
        ).run(),
        throwsA(
          isA<AccountDeletionFailure>().having(
            (failure) => failure.toString(),
            'safe text',
            isNot(contains('private recovery detail')),
          ),
        ),
      );

      expect(
        events,
        containsAllInOrder(<String>[
          'identity-recover',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]),
      );
    },
  );

  for (final source in <String>['reauth', 'push-removal']) {
    test(
      'raw $source error is mapped to a non-disclosing typed failure',
      () async {
        final events = <String>[];
        final operations = _FakeDeletionOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: true,
            isAppleLinked: false,
          )
          ..requestResults.add(_operation(AccountOperationPhase.completed));
        if (source == 'reauth') {
          operations.googleReauthFailure = StateError('secret reauth token');
        }
        final sessions = _readySessions();
        final coordinator = AccountDeletionCoordinator(
          operations: operations,
          ownershipTransitions: _ownership(
            events,
            sessions,
            removalFailure: source == 'push-removal'
                ? StateError('secret push token')
                : null,
          ),
          sessions: sessions,
          pollDelay: (_) async {},
        );

        Object? caught;
        try {
          await coordinator.deleteAccount();
        } catch (error) {
          caught = error;
        }

        expect(caught, isA<AccountOperationFailure>());
        expect(caught.toString(), isNot(contains('secret')));
        expect(operations.requestCalls, 0);
      },
    );
  }

  test(
    'status response for another operation is rejected before journaling',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        )
        ..statusResults.add(
          _operation(
            AccountOperationPhase.completed,
            operationId: 'operation-wrong',
          ),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.code,
            'code',
            AccountOperationFailureCode.invalidResponse,
          ),
        ),
      );

      expect(operations.statusOperationIds, <String>['operation-1']);
      expect(operations.journalWrites.last.operationId, 'operation-1');
      expect(
        operations.journalWrites.any(
          (journal) => journal.operationId == 'operation-wrong',
        ),
        isFalse,
      );
    },
  );

  test('Apple completion for another operation is never journaled', () async {
    final events = <String>[];
    final operations = _FakeDeletionOperations(events)
      ..providers = const AuthProviderState(
        isGoogleLinked: false,
        isAppleLinked: true,
      )
      ..appleAuthorizationCode = 'apple-code'
      ..requestResults.add(_operation(AccountOperationPhase.deletionRequested))
      ..statusResults.add(
        _operation(AccountOperationPhase.appleRevocationPending, version: 4),
      )
      ..appleResults.add(
        _operation(
          AccountOperationPhase.completed,
          operationId: 'operation-wrong',
          version: 5,
        ),
      );
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
      pollDelay: (_) async {},
    );

    await expectLater(
      coordinator.deleteAccount(),
      throwsA(isA<AccountOperationFailure>()),
    );

    expect(operations.appleOperationIds, <String>['operation-1']);
    expect(operations.journalWrites.last.operationId, 'operation-1');
    expect(
      operations.journalWrites.any(
        (journal) => journal.operationId == 'operation-wrong',
      ),
      isFalse,
    );
  });

  for (final mode in <String>[
    'missing',
    'different-uid',
    'different-epoch',
    'different-mode',
  ]) {
    test('resume rejects $mode current session without changing it', () async {
      final events = <String>[];
      final journalSession = CloudWriteSession(
        uid: 'user-1',
        epoch: 7,
        mode: CloudWriteMode.blocked,
      );
      final operations = _FakeDeletionOperations(events)
        ..journal = AccountDeletionJournal(
          version: AccountDeletionJournal.currentVersion,
          session: journalSession,
          requestKey: 'request-key-1',
          operation: _operation(AccountOperationPhase.deletionRequested),
        )
        ..statusResults.add(_operation(AccountOperationPhase.completed));
      final sessions = CloudWriteSessionController();
      if (mode == 'different-uid') {
        sessions.acquire('other-user');
      } else if (mode == 'different-epoch') {
        sessions.resume(
          CloudWriteSession(
            uid: journalSession.uid,
            epoch: journalSession.epoch + 1,
            mode: journalSession.mode,
          ),
          expectedUid: journalSession.uid,
        );
      } else if (mode == 'different-mode') {
        sessions.resume(
          CloudWriteSession(
            uid: journalSession.uid,
            epoch: journalSession.epoch,
            mode: CloudWriteMode.ready,
          ),
          expectedUid: journalSession.uid,
        );
      }
      final before = sessions.current;
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        pollDelay: (_) async {},
      );

      await expectLater(
        coordinator.resumePendingDeletion(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.code,
            'code',
            AccountOperationFailureCode.blocked,
          ),
        ),
      );

      expect(sessions.current, before);
      expect(operations.statusCalls, 0);
      expect(operations.journalWrites, isEmpty);
    });
  }

  for (final replacement in <String>[
    'null',
    'different UID',
    'same UID with different epoch',
    'same UID with different mode',
  ]) {
    test(
      'resume preserves its journal when session becomes $replacement mid-poll',
      () async {
        final events = <String>[];
        const restoredSession = CloudWriteSession(
          uid: 'user-1',
          epoch: 7,
          mode: CloudWriteMode.blocked,
        );
        final durableJournal = AccountDeletionJournal(
          version: AccountDeletionJournal.currentVersion,
          session: restoredSession,
          requestKey: 'request-key-1',
          operation: _operation(AccountOperationPhase.deletionRequested),
        );
        final statusStarted = Completer<void>();
        final delayedStatus = Completer<AccountOperationResult>();
        final operations = _FakeDeletionOperations(events)
          ..journal = durableJournal
          ..statusStarted = statusStarted
          ..delayedStatusResult = delayedStatus
          ..statusResults.add(
            _operation(AccountOperationPhase.completed, version: 8),
          );
        final sessions = CloudWriteSessionController()
          ..resume(restoredSession, expectedUid: 'user-1');
        final coordinator = AccountDeletionCoordinator(
          operations: operations,
          ownershipTransitions: _ownership(events, sessions),
          sessions: sessions,
          pollDelay: (_) async {},
        );

        final resume = coordinator.resumePendingDeletion();
        await statusStarted.future;
        switch (replacement) {
          case 'null':
            sessions.clear();
          case 'different UID':
            sessions.acquire('other-user');
          case 'same UID with different epoch':
            sessions
              ..transition(CloudWriteMode.ready)
              ..transition(CloudWriteMode.blocked);
          case 'same UID with different mode':
            sessions
              ..clear()
              ..resume(
                const CloudWriteSession(
                  uid: 'user-1',
                  epoch: 7,
                  mode: CloudWriteMode.ready,
                ),
                expectedUid: 'user-1',
              );
        }
        final replacementSession = sessions.current;
        delayedStatus.complete(
          _operation(AccountOperationPhase.userTreeDeleting, version: 2),
        );

        await expectLater(
          resume,
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(operations.statusCalls, 1);
        expect(operations.journal, same(durableJournal));
        expect(operations.journalWrites, isEmpty);
        expect(operations.recoveryCalls, 0);
        expect(sessions.current, replacementSession);
      },
    );
  }

  for (final testCase in <String, CloudWriteSessionController>{
    'missing': CloudWriteSessionController(),
    'mismatched': CloudWriteSessionController()..acquire('other-user'),
  }.entries) {
    test(
      '${testCase.key} ready session blocks deletion before the request',
      () async {
        final events = <String>[];
        final operations = _FakeDeletionOperations(events)
          ..requestResults.add(
            _operation(AccountOperationPhase.deletionRequested),
          );
        final sessions = testCase.value;
        final coordinator = AccountDeletionCoordinator(
          operations: operations,
          ownershipTransitions: _ownership(events, sessions),
          sessions: sessions,
          pollDelay: (_) async {},
        );

        await expectLater(
          coordinator.deleteAccount(),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(operations.requestCalls, 0);
        expect(operations.journalWrites, isEmpty);
        expect(events, isEmpty);
      },
    );
  }
}

AccountOperationResult _operation(
  AccountOperationPhase phase, {
  int version = 1,
  String operationId = 'operation-1',
}) {
  return AccountOperationResult(
    operationId: operationId,
    kind: AccountOperationKind.deletion,
    phase: phase,
    version: version,
    attemptCount: 0,
    retryable: phase != AccountOperationPhase.completed,
    blockedReason: phase == AccountOperationPhase.blocked
        ? AccountOperationBlockedReason.operationBlocked
        : null,
  );
}

CloudWriteSessionController _readySessions() {
  final sessions = CloudWriteSessionController();
  sessions.acquire('user-1');
  return sessions;
}

PushOwnershipTransitionCoordinator _ownership(
  List<String> events,
  CloudWriteSessionController sessions, {
  Object? removalFailure,
}) {
  return PushOwnershipTransitionCoordinator(
    push: _FakePush(events, removalFailure: removalFailure),
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
  final List<AccountOperationFailure> requestFailures = [];
  final List<AccountOperationResult> statusResults = [];
  final List<AccountOperationResult> appleResults = [];
  final List<AccountOperationFailure> statusFailures = [];
  final List<String> statusOperationIds = [];
  final List<String> appleOperationIds = [];
  Completer<void>? statusStarted;
  Completer<AccountOperationResult>? delayedStatusResult;
  Object? googleReauthFailure;
  Object? appleReauthFailure;
  Object? recoveryFailure;
  int requestCalls = 0;
  int statusCalls = 0;
  int recoveryCalls = 0;

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
    if (requestFailures.isNotEmpty) throw requestFailures.removeAt(0);
    return requestResults.removeAt(0);
  }

  @override
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  ) async {
    statusCalls += 1;
    statusOperationIds.add(request.operationId);
    events.add('status:${request.operationId}');
    final started = statusStarted;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
    final delayed = delayedStatusResult;
    if (delayed != null) {
      delayedStatusResult = null;
      return delayed.future;
    }
    if (statusFailures.isNotEmpty) {
      throw statusFailures.removeAt(0);
    }
    return statusResults.removeAt(0);
  }

  @override
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  ) async {
    appleOperationIds.add(request.operationId);
    events.add(
      'apple-complete:${request.operationId}:'
      '${request.expectedVersion}:${request.authorizationCode}',
    );
    return appleResults.removeAt(0);
  }

  @override
  Future<String?> reauthenticateWithApple() async {
    events.add('apple-reauth');
    if (appleReauthFailure case final failure?) {
      throw failure;
    }
    return appleAuthorizationCode;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    events.add('google-reauth');
    if (googleReauthFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> recoverDeletedIdentity() async {
    recoveryCalls += 1;
    events.add('identity-recover');
    if (recoveryFailure case final failure?) {
      throw failure;
    }
  }
}

class _FakePush implements PushTokenOwner {
  _FakePush(this.events, {this.removalFailure});

  final List<String> events;
  final Object? removalFailure;

  @override
  Future<void> bindCurrentUser() async => events.add('push-bind');

  @override
  Future<void> removeTokenFrom(String uid) async {
    events.add('push-remove:$uid');
    if (removalFailure case final failure?) {
      throw failure;
    }
  }
}

class _CleanupOperations implements AccountDeletionCleanupOperations {
  _CleanupOperations(this.events, this.deleteRemote);

  final List<String> events;
  final Future<void> Function() deleteRemote;

  @override
  Future<void> deleteRemoteAccount() => deleteRemote();

  @override
  Future<void> resetLocalStorage() async => events.add('local-reset');

  @override
  Future<void> disablePush() async => events.add('push-disable');

  @override
  Future<void> deleteLocalImages() async => events.add('image-delete');

  @override
  Future<void> clearTtsCache() async => events.add('tts-clear');

  @override
  void resetInMemoryData() => events.add('memory-reset');
}

class _FakeTemporaryAuthContext implements TemporaryFirebaseAuthContext {
  _FakeTemporaryAuthContext()
    : operationGateway = AccountOperationClient(
        transport: _UnusedAccountOperationTransport(),
      );

  @override
  final AccountOperationGateway operationGateway;
  Object? signInFailure;
  int disposeCalls = 0;

  @override
  Future<void> dispose() async => disposeCalls += 1;

  @override
  Future<TemporaryFirebaseUser> signIn(AuthCredential credential) async {
    if (signInFailure != null) throw signInFailure!;
    return const TemporaryFirebaseUser(
      uid: 'durable-target',
      isAnonymous: false,
    );
  }
}

class _UnusedAccountOperationTransport implements AccountOperationTransport {
  @override
  Future<Object?> call(AccountOperationTransportCall call) {
    throw StateError('not used');
  }
}
