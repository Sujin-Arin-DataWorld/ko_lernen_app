import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/account/account_deletion_status_receipt.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';
import 'package:ko_lernen_app/services/push_service.dart';

void main() {
  group('completed deletion identity recovery', () {
    test('recognizes a different anonymous UID as already recovered', () {
      expect(
        isCompletedDeletionAlreadyRecovered(
          deletedUid: 'deleted-uid',
          currentUid: 'new-anonymous-uid',
          currentIsAnonymous: true,
        ),
        isTrue,
      );
    });

    test('rejects a different non-anonymous UID as recovery', () {
      expect(
        isCompletedDeletionAlreadyRecovered(
          deletedUid: 'deleted-uid',
          currentUid: 'linked-user',
          currentIsAnonymous: false,
        ),
        isFalse,
      );
    });

    test(
      'different anonymous UID requires a strict completed cleanup checkpoint',
      () async {
        final pendingCheckpoint = _completedDeletionJournal().copyWith(
          operation: _operation(AccountOperationPhase.deletionRequested),
        );
        var providerCleanupCalls = 0;
        var firebaseRecoveryCalls = 0;

        await expectLater(
          recoverCompletedDeletionIdentity(
            checkpoint: pendingCheckpoint,
            currentUid: 'unrelated-anonymous-uid',
            currentIsAnonymous: true,
            cleanupGoogleProvider: () async => providerCleanupCalls += 1,
            recoverFirebaseIdentity: () async => firebaseRecoveryCalls += 1,
          ),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(providerCleanupCalls, 0);
        expect(firebaseRecoveryCalls, 0);
        expect(
          () => assertCompletedDeletionFeedbackActivationIdentitySafe(
            checkpoint: pendingCheckpoint,
            currentUid: 'unrelated-anonymous-uid',
            currentIsAnonymous: true,
          ),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );
      },
    );

    test(
      'already-recovered anonymous identity still retries Google cleanup',
      () async {
        var googleCleanupCalls = 0;
        var firebaseRecoveryCalls = 0;
        var failGoogleCleanup = true;
        final checkpoint = _completedDeletionJournal(
          sourceProviders: const {'google'},
        );

        Future<void> recover() => recoverCompletedDeletionIdentity(
          checkpoint: checkpoint,
          currentUid: 'new-anonymous-uid',
          currentIsAnonymous: true,
          cleanupGoogleProvider: () async {
            googleCleanupCalls += 1;
            if (failGoogleCleanup) {
              throw StateError('provider cleanup unavailable');
            }
          },
          recoverFirebaseIdentity: () async {
            firebaseRecoveryCalls += 1;
          },
        );

        await expectLater(
          recover(),
          throwsA(isA<AccountDeletionRecoveryException>()),
        );
        failGoogleCleanup = false;
        await recover();

        expect(googleCleanupCalls, 2);
        expect(firebaseRecoveryCalls, 0);
      },
    );

    test(
      'wrong durable identity is blocked before Google provider cleanup',
      () async {
        var googleCleanupCalls = 0;
        var firebaseRecoveryCalls = 0;

        await expectLater(
          recoverCompletedDeletionIdentity(
            checkpoint: _completedDeletionJournal(
              sourceProviders: const {'google'},
            ),
            currentUid: 'different-durable-uid',
            currentIsAnonymous: false,
            cleanupGoogleProvider: () async => googleCleanupCalls += 1,
            recoverFirebaseIdentity: () async => firebaseRecoveryCalls += 1,
          ),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(googleCleanupCalls, 0);
        expect(firebaseRecoveryCalls, 0);
      },
    );

    test(
      'failed completed recovery cannot clear another account feedback',
      () async {
        var feedbackCloses = 0;
        final gate = AccountDeletionRemoteGate(
          readCheckpoint: () async => _completedDeletionJournal(),
          startOrResumeRemote: () async {
            fail('completed deletion must not start another remote request');
          },
          recoverCompleted: (_) async {
            throw const AccountOperationFailure(
              AccountOperationFailureCode.blocked,
              retryable: false,
            );
          },
          preflight: (_) {
            throw const AccountOperationFailure(
              AccountOperationFailureCode.blocked,
              retryable: false,
            );
          },
          closeFeedback: () async => feedbackCloses += 1,
        );

        await expectLater(gate.run(), throwsA(isA<AccountOperationFailure>()));

        expect(feedbackCloses, 0);
      },
    );
  });

  group('completed deletion recovery-only gate', () {
    test(
      'missing completed checkpoint fails closed without fallback',
      () async {
        var recoveryCalls = 0;
        var feedbackCloses = 0;
        final gate = CompletedAccountDeletionRecoveryGate(
          readCheckpoint: () async => null,
          preflight: (_) {},
          recoverCompleted: (_) async => recoveryCalls += 1,
          closeFeedback: () async => feedbackCloses += 1,
        );

        await expectLater(
          gate.run(),
          throwsA(
            isA<AccountOperationFailure>().having(
              (failure) => failure.code,
              'code',
              AccountOperationFailureCode.blocked,
            ),
          ),
        );

        expect(recoveryCalls, 0);
        expect(feedbackCloses, 0);
      },
    );

    test('identity preflight precedes feedback close and recovery', () async {
      final events = <String>[];
      final gate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: () async => _completedDeletionJournal(),
        preflight: (_) => events.add('identity-preflight'),
        recoverCompleted: (_) async => events.add('identity-recovery'),
        closeFeedback: () async => events.add('feedback-close'),
      );

      await gate.run();

      expect(events, <String>[
        'identity-preflight',
        'feedback-close',
        'identity-recovery',
      ]);
    });
  });

  group('completed deletion feedback activation', () {
    test(
      'false activation retains only the handoff and a retry succeeds',
      () async {
        final checkpoint = _completedDeletionJournal();
        final completed = _DeletionJournalStore(checkpoint);
        final activation = _DeletionJournalStore(null);
        final activationResults = <bool>[false, true];
        final checkpointPresenceDuringActivation = <bool>[];
        final coordinator = CompletedDeletionFeedbackActivationCoordinator(
          completedStore: completed,
          activationStore: activation,
          activateFeedback: (_) async {
            checkpointPresenceDuringActivation.add(completed.journal != null);
            return activationResults.removeAt(0);
          },
        );

        await expectLater(
          coordinator.run(),
          throwsA(
            isA<AccountOperationFailure>()
                .having((failure) => failure.retryable, 'retryable', isTrue)
                .having(
                  (failure) => failure.code,
                  'code',
                  AccountOperationFailureCode.unavailable,
                ),
          ),
        );
        expect(completed.journal, isNull);
        expect(activation.journal?.toJson(), checkpoint.toJson());

        await coordinator.run();

        expect(completed.journal, isNull);
        expect(activation.journal, isNull);
        expect(checkpointPresenceDuringActivation, [false, false]);
      },
    );

    test('activation failure retains the handoff journal', () async {
      final checkpoint = _completedDeletionJournal();
      final completed = _DeletionJournalStore(checkpoint);
      final activation = _DeletionJournalStore(null);
      final coordinator = CompletedDeletionFeedbackActivationCoordinator(
        completedStore: completed,
        activationStore: activation,
        activateFeedback: (_) async => false,
      );

      await expectLater(
        coordinator.run(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.retryable,
            'retryable',
            isTrue,
          ),
        ),
      );

      expect(completed.journal, isNull);
      expect(activation.journal?.toJson(), checkpoint.toJson());
    });
  });

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

  });

  test(
    'first durable-link activation never uploads a replacement identity',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('anonymous-source');
      var liveUid = 'anonymous-source';
      final uploads = <String>[];
      final backfill = FirstDurableLinkBackfill(
        sessions: sessions,
        currentUid: () => liveUid,
        hasBlockingAccountJournal: () async => false,
        journalStore:
            const SharedPreferencesFirstDurableLinkBackfillJournalStore(),
        uploadBookshelf: (session, {required operationId}) async {
          uploads.add('bookshelf:${session.uid}');
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (session, {required operationId}) async {
          uploads.add('packs:${session.uid}');
          return CloudWriteResult.completed;
        },
      );
      final activation = FirstDurableLinkActivation(
        sessions: sessions,
        backfill: backfill,
      );

      final result = await activation.activate(
        sourceUid: 'anonymous-source',
        linkedUid: 'existing-account',
        linkedIsAnonymous: false,
      );

      expect(result, CloudWriteResult.stale);
      expect(uploads, isEmpty);
      expect(liveUid, 'anonymous-source');
    },
  );

  test(
    'Google-linked deletion accepts and finishes without any delay seam',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.deleteAccount();

      expect(events, [
        'google-reauth',
        'push-remove:user-1',
        'journal-write:pending',
        'request:request-key-1',
        'journal-write:operation-1',
        'delete-firebase-user',
        // Written twice: once inside the transition (session still
        // `quiesced`), then again by _persistCurrentOwnedSession after the
        // ownership transition has advanced the session to `cleanupPending`
        // — the only durable write of the `completed` operation, since
        // AccountDeletionJournal.fromJson requires that session mode.
        'journal-write:operation-1',
        'identity-recover',
      ]);
      expect(operations.requestCalls, 1);
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(operations.statusCalls, 0);
      expect(operations.receiptAckCalls, 0);
      final journal = operations.journal;
      expect(journal?.operationId, 'operation-1');
      expect(journal?.operation?.phase, AccountOperationPhase.completed);
      expect(journal?.operation?.retryable, isFalse);
      expect(operations.recoveryCalls, 1);
      // The receipt is never acknowledged/cleared here — it stays for
      // silent background verification
      // (AccountDeletionReceiptRecoveryCoordinator), per design principle 1.
      expect(operations.receipt, isNotNull);
      expect(operations.receiptAckCalls, 0);
      expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
    },
  );

  test(
    'Apple-linked deletion completes revocation before deleting the Firebase user',
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
        ..appleResults.add(
          _operation(AccountOperationPhase.deletionRequested, version: 1),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.deleteAccount();

      expect(events, [
        'apple-reauth',
        'push-remove:user-1',
        'journal-write:pending',
        'request:request-key-1',
        'journal-write:operation-1',
        'apple-complete:operation-1:1:one-use-code',
        'delete-firebase-user',
        // See the Google-linked test above for why this is written twice.
        'journal-write:operation-1',
        'identity-recover',
      ]);
      expect(operations.appleOperationIds, ['operation-1']);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(operations.recoveryCalls, 1);
    },
  );

  test(
    'a stale-version Apple revocation failure is deferred; deletion still completes',
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
        ..appleFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.staleOperationVersion,
            retryable: false,
          ),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.deleteAccount();

      expect(
        events,
        containsAllInOrder(<String>[
          'apple-complete:operation-1:1:one-use-code',
          'delete-firebase-user',
          'identity-recover',
        ]),
      );
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(operations.recoveryCalls, 1);
    },
  );

  for (final phase in <AccountOperationPhase>[
    AccountOperationPhase.blocked,
    AccountOperationPhase.cancelled,
  ]) {
    test(
      'a request result of ${phase.name} throws blocked and never deletes '
      'the Firebase user',
      () async {
        final events = <String>[];
        final operations = _FakeDeletionOperations(events)
          ..requestResults.add(_operation(phase));
        final sessions = _readySessions();
        final coordinator = AccountDeletionCoordinator(
          operations: operations,
          ownershipTransitions: _ownership(events, sessions),
          sessions: sessions,
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

        expect(operations.deleteFirebaseUserCalls, 0);
        expect(events, isNot(contains('delete-firebase-user')));
      },
    );
  }

  test(
    'resumePendingDeletion with a legacy non-completed journal deletes the '
    'Firebase user and completes locally without any status call',
    () async {
      final events = <String>[];
      const journalSession = CloudWriteSession(
        uid: 'user-1',
        epoch: 7,
        mode: CloudWriteMode.quiesced,
      );
      final operations = _FakeDeletionOperations(events)
        ..journal = AccountDeletionJournal(
          version: AccountDeletionJournal.currentVersion,
          session: journalSession,
          requestKey: 'request-key-1',
          operation: _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = CloudWriteSessionController()
        ..resume(journalSession, expectedUid: 'user-1');
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.resumePendingDeletion();

      expect(operations.deleteFirebaseUserCalls, 1);
      expect(operations.requestCalls, 0);
      expect(operations.statusCalls, 0);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(operations.journal?.session.mode, CloudWriteMode.cleanupPending);
      expect(operations.recoveryCalls, 1);
      expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
    },
  );

  test(
    'resumePendingDeletion with an already-completed journal only recovers '
    'identity and never touches the journal or the server',
    () async {
      final events = <String>[];
      final journal = AccountDeletionJournal(
        version: AccountDeletionJournal.currentVersion,
        session: const CloudWriteSession(
          uid: 'user-1',
          epoch: 7,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'request-key-completed',
        operation: _operation(AccountOperationPhase.completed),
      );
      final operations = _FakeDeletionOperations(events)..journal = journal;
      final sessions = CloudWriteSessionController();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.resumePendingDeletion();

      expect(operations.recoveryCalls, 1);
      expect(operations.deleteFirebaseUserCalls, 0);
      expect(operations.requestCalls, 0);
      expect(operations.journalWrites, isEmpty);
      expect(operations.journal, same(journal));
    },
  );

  test(
    // NOTE: this exercises the literal brief contract (clear + rerun
    // _deleteAccount fresh). It requires the cloud-write session to already
    // be `ready` — see the risk note in the T5 evidence report about why an
    // immediate same-process retry (session left `blocked` by
    // PushOwnershipTransitionCoordinator after the first failure) cannot
    // reach this success path; the realistic recovery route for that case is
    // the existing orphan-receipt-reuse path exercised below instead.
    'resumePendingDeletion with operation==null clears the stale journal and '
    'reruns the flow fresh once the session is ready again',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..journal = AccountDeletionJournal.pending(
          session: const CloudWriteSession(
            uid: 'user-1',
            epoch: 2,
            mode: CloudWriteMode.quiesced,
          ),
          requestKey: 'stale-request-key',
        )
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
      );

      await coordinator.resumePendingDeletion();

      expect(operations.clearPendingDeletionJournalCalls, 1);
      expect(operations.requestCalls, 1);
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(operations.recoveryCalls, 1);
    },
  );

  test(
    'request failure before the server barrier leaves feedback open',
    () async {
      final events = <String>[];
      var closeCalls = 0;
      final operations = _FakeDeletionOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..requestFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        closeFeedback: () async {
          closeCalls += 1;
          events.add('feedback-close');
        },
      );

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(closeCalls, 0);
      expect(events, isNot(contains('feedback-close')));
      expect(operations.statusCalls, 0);
      expect(operations.deleteFirebaseUserCalls, 0);
      expect(operations.journal?.operation, isNull);
    },
  );

  test(
    'journals the deletion barrier, closes feedback, then finishes locally',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        closeFeedback: () async => events.add('feedback-close'),
      );

      await coordinator.deleteAccount();

      expect(
        events,
        containsAllInOrder(<String>[
          'request:request-key-1',
          'journal-write:operation-1',
          'feedback-close',
          'delete-firebase-user',
        ]),
      );
      expect(operations.statusCalls, 0);
    },
  );

  test(
    'resume does not retry a failed feedback close — it finishes the '
    'deletion directly instead',
    () async {
      final events = <String>[];
      var closeAttempts = 0;
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final firstSessions = _readySessions();
      final firstCoordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, firstSessions),
        sessions: firstSessions,
        closeFeedback: () async {
          closeAttempts += 1;
          events.add('feedback-close-failed');
          throw StateError('secure outbox unavailable');
        },
      );

      await expectLater(
        firstCoordinator.deleteAccount(),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(closeAttempts, 1);
      expect(operations.journal?.operationId, 'operation-1');
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.deletionRequested,
      );
      expect(operations.deleteFirebaseUserCalls, 0);

      final restartedSessions = CloudWriteSessionController()
        ..resume(operations.journal!.session, expectedUid: operations.userId);
      final restartedCoordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, restartedSessions),
        sessions: restartedSessions,
        closeFeedback: () async {
          closeAttempts += 1;
          events.add('feedback-close');
        },
      );

      await restartedCoordinator.resumePendingDeletion();

      // T5: resume never retries closeFeedback — a single synchronous
      // accept-and-finish call replaces the old 20+ minute polling window in
      // which that retry used to matter.
      expect(closeAttempts, 1);
      expect(events, isNot(contains('feedback-close')));
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(operations.recoveryCalls, 1);
    },
  );

  test(
    'final feedback clear failure retains deletion for a text-safe retry',
    () async {
      final events = <String>[];
      final store = _DeletionFeedbackOutboxStore();
      final feedbackClient = _DeletionFeedbackClient();
      final feedback = _deletionFeedbackService(store, feedbackClient);
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final firstSessions = _readySessions();
      final firstCoordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, firstSessions),
        sessions: firstSessions,
        closeFeedback: feedback.closeAndDiscard,
      );

      final submission = feedback.submit(
        const ContentFeedbackContext(
          completionId: 'completion-before-delete',
          contentType: 'scenario',
          contentId: 'airport',
          contentLabel: 'Airport',
          level: 'A1',
          scoreSummary: 'completed',
        ),
        const ContentFeedbackDraft(
          category: FeedbackCategory.other,
          message: 'Private tester text before deletion.',
        ),
      );
      await store.writeStarted.future;

      final deletion = firstCoordinator.deleteAccount();
      await store.firstClearStarted.future;
      expect(store.clearCount, 1);
      store.releaseWrite.complete();

      await expectLater(deletion, throwsA(isA<AccountOperationFailure>()));
      final submissionResult = await submission;

      expect(submissionResult.status, ContentFeedbackSubmitStatus.closed);
      expect(store.clearCount, 2);
      // The final authoritative clear (clearCount 2) throws before it can
      // remove the item the first clear (clearCount 1, on an empty list)
      // missed — the submission's own write only lands once releaseWrite
      // above completes, which is after that first clear already ran.
      expect(store.items, hasLength(1));
      expect(operations.statusCalls, 0);
      expect(operations.deleteFirebaseUserCalls, 0);
      expect(operations.recoveryCalls, 0);
      expect(operations.journal?.operationId, 'operation-1');
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.deletionRequested,
      );

      final closedSubmit = await feedback.submit(
        const ContentFeedbackContext(
          completionId: 'completion-after-delete',
          contentType: 'scenario',
          contentId: 'airport',
          contentLabel: 'Airport',
          level: 'A1',
          scoreSummary: 'completed',
        ),
        const ContentFeedbackDraft(
          category: FeedbackCategory.other,
          message: 'Must never leave the closed outbox.',
        ),
      );
      final closedResume = await feedback.resumePending();
      expect(closedSubmit.status, ContentFeedbackSubmitStatus.closed);
      expect(closedResume.closed, isTrue);
      expect(feedbackClient.feedbackIds, isEmpty);

      final restartedSessions = CloudWriteSessionController()
        ..resume(operations.journal!.session, expectedUid: operations.userId);
      final restartedCoordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, restartedSessions),
        sessions: restartedSessions,
        closeFeedback: feedback.closeAndDiscard,
      );

      await restartedCoordinator.resumePendingDeletion();

      // T5 (known, disclosed trade-off — see the evidence report's risk
      // section): resume never retries closeFeedback, so the one item that
      // survived the failed first attempt's authoritative clear is never
      // discarded. It also never leaks — the service is already `_closed`,
      // so no later submit/resume can ever read or resubmit it either.
      expect(operations.statusCalls, 0);
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(operations.recoveryCalls, 1);
      expect(store.items, hasLength(1));
      expect(feedbackClient.feedbackIds, isEmpty);
    },
  );

  test(
    'orphan receipt from first journal failure reuses its request key and capability',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..nextRequestKeys.addAll(<String>[
          'orphan-request-key',
          'must-not-replace-orphan-key',
        ])
        ..journalWriteFailures = 2;
      final firstSessions = _readySessions();
      final firstCoordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, firstSessions),
        sessions: firstSessions,
      );

      await expectLater(
        firstCoordinator.deleteAccount(),
        throwsA(isA<AccountOperationFailure>()),
      );

      final orphan = operations.receipt;
      expect(operations.journal, isNull);
      expect(orphan, isNotNull);
      expect(orphan?.requestKey, 'orphan-request-key');
      expect(orphan?.operationId, isNull);
      expect(operations.requestCalls, 0);

      operations.requestResults.add(
        _operation(AccountOperationPhase.completed),
      );
      final restartedSessions = _readySessions();
      final restarted = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, restartedSessions),
        sessions: restartedSessions,
      );

      await restarted.deleteAccount();

      expect(operations.requestKeyCalls, 1);
      expect(operations.requestCalls, 1);
      expect(operations.journal?.requestKey, 'orphan-request-key');
      expect(
        operations.requestedReceipts.single,
        orphan?.terminalStatusReceipt,
      );
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(operations.recoveryCalls, 1);
    },
  );

  test(
    'orphan receipt owned by another source blocks a new deletion',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..receipt = AccountDeletionStatusReceipt.checked(
          sourceUid: 'another-source',
          requestKey: 'another-request',
          terminalStatusReceipt: 'A' * 43,
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
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
      expect(events, isNot(contains('push-remove:user-1')));
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
      ..requestResults.add(_operation(AccountOperationPhase.blocked));
    final sessions = _readySessions();
    final coordinator = AccountDeletionCoordinator(
      operations: operations,
      ownershipTransitions: _ownership(events, sessions),
      sessions: sessions,
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
    expect(operations.deleteFirebaseUserCalls, 0);
    expect(operations.recoveryCalls, 0);
  });

  test(
    'a rejected deletion request hands the session back so the same session '
    'can retry without an app restart',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        )
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = _readySessions();
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        rebindPush: () async => events.add('push-rebind'),
      );

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.code,
            'code',
            AccountOperationFailureCode.unavailable,
          ),
        ),
      );

      // The lost request left nothing on the server, so the source session
      // is ready again (not parked in `blocked`) and push is re-bound.
      expect(sessions.current?.uid, 'user-1');
      expect(sessions.current?.mode, CloudWriteMode.ready);
      expect(events, contains('push-rebind'));
      expect(operations.deleteFirebaseUserCalls, 0);

      await coordinator.deleteAccount();

      expect(operations.requestCalls, 2);
      expect(operations.deleteFirebaseUserCalls, 1);
      expect(
        operations.journal?.operation?.phase,
        AccountOperationPhase.completed,
      );
      expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
    },
  );

  test(
    'a failure after server acceptance keeps the session blocked',
    () async {
      final events = <String>[];
      final operations = _FakeDeletionOperations(events)
        ..requestResults.add(
          _operation(AccountOperationPhase.deletionRequested),
        );
      final sessions = _readySessions();
      var rebinds = 0;
      final coordinator = AccountDeletionCoordinator(
        operations: operations,
        ownershipTransitions: _ownership(events, sessions),
        sessions: sessions,
        closeFeedback: () async => throw StateError('feedback close failed'),
        rebindPush: () async => rebinds += 1,
      );

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(isA<AccountOperationFailure>()),
      );

      // The server already owns the deletion: never hand the session back.
      expect(sessions.current?.uid, 'user-1');
      expect(sessions.current?.mode, CloudWriteMode.blocked);
      expect(rebinds, 0);
    },
  );

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
    'pending feedback activation manual retry skips every destructive cleanup',
    () async {
      final events = <String>[];
      var remoteDeletionCalls = 0;
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events, () async => remoteDeletionCalls += 1),
        finalizePendingFeedbackActivation: () async {
          events.add('activation-finalize');
          return true;
        },
      );

      await workflow.run();

      expect(events, <String>['activation-finalize']);
      expect(remoteDeletionCalls, 0);
    },
  );

  test(
    'overlapping Settings instances share one destructive workflow',
    () async {
      final events = <String>[];
      final completionStarted = Completer<void>();
      final allowCompletion = Completer<void>();
      var remoteDeletionCalls = 0;
      var completionCalls = 0;
      final firstWorkflow = AccountDeletionWorkflow(
        _CleanupOperations(events, () async => remoteDeletionCalls += 1),
        finalizePendingFeedbackActivation: () async => false,
        completeCheckpoint: () async {
          completionCalls += 1;
          if (completionCalls == 1) {
            completionStarted.complete();
            await allowCompletion.future;
          }
        },
      );
      final secondWorkflow = AccountDeletionWorkflow(
        _CleanupOperations(events, () async => remoteDeletionCalls += 1),
        finalizePendingFeedbackActivation: () async => false,
        completeCheckpoint: () async => completionCalls += 1,
      );

      final first = firstWorkflow.run();
      await completionStarted.future;
      final overlappingRetry = secondWorkflow.run();
      allowCompletion.complete();
      await Future.wait([first, overlappingRetry]);

      expect(remoteDeletionCalls, 1);
      expect(completionCalls, 1);
      expect(events.where((event) => event == 'local-reset'), hasLength(1));
      expect(events.where((event) => event == 'push-disable'), hasLength(1));
      expect(events.where((event) => event == 'image-delete'), hasLength(1));
      expect(events.where((event) => event == 'tts-clear'), hasLength(1));
      expect(events.where((event) => event == 'memory-reset'), hasLength(1));

      await secondWorkflow.run();
      expect(remoteDeletionCalls, 2);
      expect(completionCalls, 2);
    },
  );

  test(
    'invalid feedback activation marker cannot fall through to remote deletion',
    () async {
      final events = <String>[];
      var remoteDeletionCalls = 0;
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events, () async => remoteDeletionCalls += 1),
        finalizePendingFeedbackActivation: () async {
          throw const AccountOperationFailure(
            AccountOperationFailureCode.blocked,
            retryable: false,
          );
        },
      );

      await expectLater(
        workflow.run(),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(events, isEmpty);
      expect(remoteDeletionCalls, 0);
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
        );
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
      expect(operations.deleteFirebaseUserCalls, 0);
      expect(operations.journalWrites, isEmpty);
    });
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

AccountDeletionJournal _completedDeletionJournal({
  Set<String> sourceProviders = const <String>{},
}) {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'deleted-uid',
      epoch: 7,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'request-key-completed',
    sourceProviders: sourceProviders,
    operation: _operation(AccountOperationPhase.completed),
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

ContentFeedbackService _deletionFeedbackService(
  FeedbackOutboxStore store,
  ContentFeedbackClient client,
) {
  return ContentFeedbackService(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    outboxStore: store,
    client: client,
    currentUid: () => 'user-1',
    versionProvider: _DeletionFeedbackVersionProvider(),
    createFeedbackId: () => 'feedback-before-delete',
    now: () => DateTime.utc(2026, 8, 2),
    platform: () => 'android',
    locale: () => 'de',
    deletionActive: () async => false,
  );
}

class _DeletionFeedbackOutboxStore implements FeedbackOutboxStore {
  final List<ContentFeedbackOutboxItem> items = [];
  final Completer<void> writeStarted = Completer<void>();
  final Completer<void> releaseWrite = Completer<void>();
  final Completer<void> firstClearStarted = Completer<void>();
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async => List.of(items);

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    writeCount += 1;
    if (writeCount == 1) {
      writeStarted.complete();
      await releaseWrite.future;
    }
    items
      ..clear()
      ..addAll(value);
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    if (clearCount == 1) firstClearStarted.complete();
    if (clearCount == 2) {
      throw StateError('final secure outbox clear failed');
    }
    items.clear();
  }
}

class _DeletionFeedbackClient implements ContentFeedbackClient {
  final List<String> feedbackIds = [];

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission, {
    required String expectedOwnerUid,
  }) async {
    feedbackIds.add(submission.feedbackId);
    return const ContentFeedbackDelivery(
      acknowledgement: ContentFeedbackAcknowledgement.accepted,
    );
  }
}

class _DeletionFeedbackVersionProvider
    implements ContentFeedbackVersionProvider {
  @override
  Future<String> readVersion() async => '2.0.1+6';
}

class _DeletionJournalStore implements AccountDeletionJournalStore {
  _DeletionJournalStore(this.journal);

  AccountDeletionJournal? journal;
  bool failNextWrite = false;

  @override
  Future<AccountDeletionJournal?> read() async => journal;

  @override
  Future<void> write(AccountDeletionJournal value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('journal write failed');
    }
    journal = value;
  }

  @override
  Future<void> clearCompleted(String operationId) async {
    if (journal?.operationId != operationId ||
        journal?.operation?.phase != AccountOperationPhase.completed) {
      throw StateError('completed journal mismatch');
    }
    journal = null;
  }

  @override
  Future<void> clearPending() async {
    if (journal?.operation != null) {
      throw StateError('pending journal mismatch');
    }
    journal = null;
  }
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
  AccountDeletionStatusReceipt? receipt;
  final List<AccountDeletionJournal> journalWrites = [];
  final List<String> requestedReceipts = [];
  final List<AccountOperationResult> requestResults = [];
  final List<AccountOperationFailure> requestFailures = [];
  final List<AccountOperationResult> statusResults = [];
  final List<AccountOperationResult> appleResults = [];
  final List<AccountOperationFailure> appleFailures = [];
  final List<AccountOperationFailure> statusFailures = [];
  final List<String> nextRequestKeys = [];
  final List<String> statusOperationIds = [];
  final List<String> appleOperationIds = [];
  Completer<void>? statusStarted;
  Completer<AccountOperationResult>? delayedStatusResult;
  Object? googleReauthFailure;
  Object? appleReauthFailure;
  Object? recoveryFailure;
  Object? receiptAckFailure;
  int requestCalls = 0;
  int requestKeyCalls = 0;
  int statusCalls = 0;
  int receiptAckCalls = 0;
  int recoveryCalls = 0;
  int deleteFirebaseUserCalls = 0;
  int clearPendingDeletionJournalCalls = 0;
  bool firstJournalSawReceipt = false;
  bool ackSawDurableCompletedJournal = false;
  bool ackPrecededIdentityRecovery = false;
  int journalWriteFailures = 0;

  @override
  String get userId => 'user-1';

  @override
  AuthProviderState get providerState => providers;

  @override
  String createRequestKey() {
    requestKeyCalls += 1;
    return nextRequestKeys.isEmpty
        ? 'request-key-1'
        : nextRequestKeys.removeAt(0);
  }

  @override
  Future<AccountDeletionJournal?> readDeletionJournal() async => journal;

  @override
  Future<void> writeDeletionJournal(AccountDeletionJournal value) async {
    if (journalWriteFailures > 0) {
      journalWriteFailures -= 1;
      events.add('journal-write-failed');
      throw StateError('journal write failed');
    }
    if (journalWrites.isEmpty) {
      firstJournalSawReceipt = receipt != null;
    }
    journal = value;
    journalWrites.add(value);
    events.add('journal-write:${value.operationId ?? 'pending'}');
  }

  @override
  Future<AccountDeletionStatusReceipt?> readDeletionStatusReceipt() async {
    return receipt;
  }

  @override
  Future<AccountDeletionStatusReceipt> createDeletionStatusReceipt({
    required String sourceUid,
    required String requestKey,
  }) async {
    final current = receipt;
    if (current != null) return current;
    final created = AccountDeletionStatusReceipt.checked(
      sourceUid: sourceUid,
      requestKey: requestKey,
      terminalStatusReceipt: 'A' * 43,
    );
    receipt = created;
    return created;
  }

  @override
  Future<AccountDeletionStatusReceipt> bindDeletionStatusReceipt({
    required AccountDeletionStatusReceipt expected,
    required String operationId,
  }) async {
    if (receipt != expected) throw StateError('receipt mismatch');
    final bound = expected.withOperationId(operationId);
    receipt = bound;
    return bound;
  }

  @override
  Future<bool> clearDeletionStatusReceipt(
    AccountDeletionStatusReceipt expected,
  ) async {
    if (receipt != expected) return false;
    receipt = null;
    return true;
  }

  @override
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  ) async {
    requestCalls += 1;
    requestedReceipts.add(request.terminalStatusReceipt);
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
    if (statusResults.isEmpty) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.operationNotFound,
        retryable: false,
      );
    }
    return statusResults.removeAt(0);
  }

  @override
  Future<AccountOperationResult> getAccountDeletionStatusByReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) async {
    statusCalls += 1;
    final operationId = receipt?.operationId ?? journal?.operationId;
    statusOperationIds.add(operationId ?? 'receipt-only');
    events.add('status:${operationId ?? 'receipt-only'}');
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
    if (statusResults.isEmpty) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.operationNotFound,
        retryable: false,
      );
    }
    return statusResults.removeAt(0);
  }

  @override
  Future<void> acknowledgeAccountDeletionStatusReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) async {
    receiptAckCalls += 1;
    ackSawDurableCompletedJournal =
        journal?.operation?.phase == AccountOperationPhase.completed &&
        journal?.session.mode == CloudWriteMode.cleanupPending;
    ackPrecededIdentityRecovery = recoveryCalls == 0;
    if (receiptAckFailure case final failure?) {
      throw failure;
    }
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
    if (appleFailures.isNotEmpty) {
      throw appleFailures.removeAt(0);
    }
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

  @override
  Future<void> deleteFirebaseUser() async {
    deleteFirebaseUserCalls += 1;
    events.add('delete-firebase-user');
  }

  @override
  Future<void> clearPendingDeletionJournal() async {
    clearPendingDeletionJournalCalls += 1;
    events.add('journal-cleared');
    journal = null;
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

