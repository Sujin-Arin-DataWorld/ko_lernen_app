import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account/account_failure_reason.dart';
import 'account/account_deletion_status_receipt.dart';
import 'account/account_operation_client.dart';
import 'account/account_reconciliation.dart';
import 'account/account_transition_coordinator.dart';
import 'account/account_transition_journal.dart';
import 'account/cloud_backup_deletion.dart';
import 'account/cloud_write_session.dart';
import 'account/firebase_app_check_initializer.dart';
import 'account/first_link_backfill.dart';
import 'account/first_link_backfill_journal.dart';
import 'app_startup_coordinator.dart';
import 'bookshelf_service.dart';
import 'pack_progress_service.dart';
import 'push_service.dart';
import 'storage_service.dart';

@immutable
class AuthProviderState {
  const AuthProviderState({
    required this.isGoogleLinked,
    required this.isAppleLinked,
  });

  factory AuthProviderState.fromProviderIds(Iterable<String> providerIds) {
    final ids = providerIds.toSet();
    return AuthProviderState(
      isGoogleLinked: ids.contains('google.com'),
      isAppleLinked: ids.contains('apple.com'),
    );
  }

  final bool isGoogleLinked;
  final bool isAppleLinked;

  bool get isDurable => isGoogleLinked || isAppleLinked;
}

/// Selects the Firebase UID that may own learning-data cloud backups.
///
/// Anonymous Firebase Auth remains available to optional authenticated
/// features, but it does not by itself authorize progress or bookshelf sync.
@immutable
class CloudBackupAccessPolicy {
  const CloudBackupAccessPolicy._();

  static String? uidFor({
    required String? uid,
    required Iterable<String> providerIds,
  }) {
    final normalizedUid = uid?.trim();
    if (normalizedUid == null || normalizedUid.isEmpty) {
      return null;
    }
    final providers = AuthProviderState.fromProviderIds(providerIds);
    return providers.isDurable ? normalizedUid : null;
  }
}

@immutable
class AuthAccountSnapshot {
  const AuthAccountSnapshot({
    required this.providers,
    this.displayName,
    this.photoUrl,
  });

  final AuthProviderState providers;
  final String? displayName;
  final String? photoUrl;
}

abstract interface class AccountDeletionOperations {
  String get userId;
  AuthProviderState get providerState;

  Future<void> reauthenticateWithGoogle();
  Future<String?> reauthenticateWithApple();
  Future<void> recoverDeletedIdentity();
  String createRequestKey();
  Future<AccountDeletionJournal?> readDeletionJournal();
  Future<void> writeDeletionJournal(AccountDeletionJournal journal);
  Future<AccountDeletionStatusReceipt?> readDeletionStatusReceipt();
  Future<AccountDeletionStatusReceipt> createDeletionStatusReceipt({
    required String sourceUid,
    required String requestKey,
  });
  Future<AccountDeletionStatusReceipt> bindDeletionStatusReceipt({
    required AccountDeletionStatusReceipt expected,
    required String operationId,
  });
  Future<bool> clearDeletionStatusReceipt(
    AccountDeletionStatusReceipt expected,
  );
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  );
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  );
  Future<AccountOperationResult> getAccountDeletionStatusByReceipt(
    AccountDeletionStatusByReceiptRequest request,
  );
  Future<void> acknowledgeAccountDeletionStatusReceipt(
    AccountDeletionStatusByReceiptRequest request,
  );
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  );
}

abstract interface class AccountDeletionJournalStore {
  Future<AccountDeletionJournal?> read();
  Future<void> write(AccountDeletionJournal journal);
  Future<void> clearCompleted(String operationId);
}

@immutable
class AccountDeletionJournal {
  const AccountDeletionJournal({
    required this.version,
    required this.session,
    required this.requestKey,
    this.sourceProviders = const <String>{},
    this.operation,
  });

  factory AccountDeletionJournal.pending({
    required CloudWriteSession session,
    required String requestKey,
    Set<String> sourceProviders = const <String>{},
  }) {
    return AccountDeletionJournal(
      version: currentVersion,
      session: session,
      requestKey: requestKey,
      sourceProviders: sourceProviders,
    );
  }

  factory AccountDeletionJournal.fromJson(Map<String, Object?> json) {
    try {
      if (!setEquals(json.keys.toSet(), const <String>{
        'version',
        'session',
        'requestKey',
        'sourceProviders',
        'operation',
      })) {
        throw const FormatException();
      }
      final version = json['version'];
      final requestKey = json['requestKey'];
      final rawSession = json['session'];
      final rawOperation = json['operation'];
      final rawSourceProviders = json['sourceProviders'];
      if (version is! int ||
          version != currentVersion ||
          requestKey is! String ||
          !_validCoordinationId(requestKey) ||
          rawSession is! Map ||
          rawSourceProviders is! List) {
        throw const FormatException();
      }
      if (!setEquals(
        rawSession.keys.map((key) => key.toString()).toSet(),
        const <String>{'version', 'uid', 'epoch', 'mode'},
      )) {
        throw const FormatException();
      }
      final sourceProviders = <String>{};
      for (final provider in rawSourceProviders) {
        if (provider is! String ||
            !const {'google', 'apple'}.contains(provider) ||
            !sourceProviders.add(provider)) {
          throw const FormatException();
        }
      }
      final session = AccountTransitionJournal.fromJson(
        rawSession.map((key, value) => MapEntry(key.toString(), value)),
      ).session;
      AccountOperationResult? operation;
      if (rawOperation != null) {
        if (rawOperation is! Map ||
            !setEquals(
              rawOperation.keys.map((key) => key.toString()).toSet(),
              const <String>{
                'operationId',
                'kind',
                'phase',
                'version',
                'attemptCount',
                'retryable',
                'blockedReason',
              },
            )) {
          throw const FormatException();
        }
        operation = AccountOperationResult.fromJson(
          rawOperation.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      if (operation != null &&
          (operation.kind != AccountOperationKind.deletion ||
              !_validCoordinationId(operation.operationId))) {
        throw const FormatException();
      }
      if (session.mode != CloudWriteMode.quiesced &&
          session.mode != CloudWriteMode.cleanupPending) {
        throw const FormatException();
      }
      if (operation?.phase == AccountOperationPhase.completed &&
          (session.mode != CloudWriteMode.cleanupPending ||
              operation!.retryable)) {
        throw const FormatException();
      }
      return AccountDeletionJournal(
        version: version,
        session: session,
        requestKey: requestKey,
        sourceProviders: Set<String>.unmodifiable(sourceProviders),
        operation: operation,
      );
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  static const currentVersion = 1;

  static bool _validCoordinationId(String value) =>
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value);

  static String canonicalizeCompleted(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) throw const FormatException();
      final checkpoint = AccountDeletionJournal.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (checkpoint.operation?.phase != AccountOperationPhase.completed) {
        throw const FormatException();
      }
      return jsonEncode(checkpoint.toJson());
    } on AccountOperationFailure {
      rethrow;
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  final int version;
  final CloudWriteSession session;
  final String requestKey;
  final Set<String> sourceProviders;
  final AccountOperationResult? operation;

  String? get operationId => operation?.operationId;

  AccountDeletionJournal copyWith({
    CloudWriteSession? session,
    AccountOperationResult? operation,
  }) {
    return AccountDeletionJournal(
      version: version,
      session: session ?? this.session,
      requestKey: requestKey,
      sourceProviders: sourceProviders,
      operation: operation ?? this.operation,
    );
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'session': AccountTransitionJournal.fromSession(session).toJson(),
    'requestKey': requestKey,
    'sourceProviders': sourceProviders.toList()..sort(),
    'operation': operation?.toJson(),
  };
}

typedef CompletedDeletionCheckpointReader =
    Future<AccountDeletionJournal?> Function();
typedef CompletedDeletionRecovery =
    Future<void> Function(AccountDeletionJournal checkpoint);
typedef CompletedDeletionPreflight =
    void Function(AccountDeletionJournal checkpoint);
typedef AccountDeletionFeedbackCloser = Future<void> Function();
typedef AccountDeletionFeedbackActivator =
    Future<bool> Function(String deletedUid);
typedef CompletedDeletionProviderCleanup = Future<void> Function();
typedef CompletedDeletionFirebaseRecovery = Future<void> Function();

bool _isStrictCompletedDeletionRecoveryCheckpoint(
  AccountDeletionJournal checkpoint,
) {
  final operation = checkpoint.operation;
  return operation?.kind == AccountOperationKind.deletion &&
      operation?.phase == AccountOperationPhase.completed &&
      operation?.retryable == false &&
      checkpoint.operationId != null &&
      checkpoint.session.mode == CloudWriteMode.cleanupPending;
}

void assertCompletedDeletionRecoveryIdentitySafe({
  required AccountDeletionJournal checkpoint,
  required String? currentUid,
  required bool currentIsAnonymous,
}) {
  final normalizedCurrent = currentUid?.trim();
  final isDifferentIdentity =
      normalizedCurrent != null &&
      normalizedCurrent.isNotEmpty &&
      normalizedCurrent != checkpoint.session.uid;
  if (isDifferentIdentity &&
      (!currentIsAnonymous ||
          !_isStrictCompletedDeletionRecoveryCheckpoint(checkpoint))) {
    throw const AccountOperationFailure(
      AccountOperationFailureCode.blocked,
      retryable: false,
    );
  }
}

void assertCompletedDeletionFeedbackActivationIdentitySafe({
  required AccountDeletionJournal checkpoint,
  required String? currentUid,
  required bool currentIsAnonymous,
}) {
  if (!_isStrictCompletedDeletionRecoveryCheckpoint(checkpoint) ||
      !isCompletedDeletionAlreadyRecovered(
        deletedUid: checkpoint.session.uid,
        currentUid: currentUid,
        currentIsAnonymous: currentIsAnonymous,
      )) {
    throw const AccountOperationFailure(
      AccountOperationFailureCode.blocked,
      retryable: false,
    );
  }
}

bool isCompletedDeletionAlreadyRecovered({
  required String deletedUid,
  required String? currentUid,
  required bool currentIsAnonymous,
}) {
  final deleted = deletedUid.trim();
  final current = currentUid?.trim();
  return deleted.isNotEmpty &&
      current != null &&
      current.isNotEmpty &&
      current != deleted &&
      currentIsAnonymous;
}

Future<void> recoverCompletedDeletionIdentity({
  required AccountDeletionJournal checkpoint,
  required String? currentUid,
  required bool currentIsAnonymous,
  CompletedDeletionProviderCleanup? cleanupGoogleProvider,
  required CompletedDeletionFirebaseRecovery recoverFirebaseIdentity,
}) async {
  assertCompletedDeletionRecoveryIdentitySafe(
    checkpoint: checkpoint,
    currentUid: currentUid,
    currentIsAnonymous: currentIsAnonymous,
  );
  final normalizedCurrent = currentUid?.trim();

  final failures = <Object>[];
  if (checkpoint.sourceProviders.contains('google')) {
    try {
      final cleanup = cleanupGoogleProvider;
      if (cleanup == null) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.unavailable,
          retryable: true,
        );
      }
      await cleanup();
    } catch (error) {
      failures.add(error);
    }
  }

  final alreadyRecovered = isCompletedDeletionAlreadyRecovered(
    deletedUid: checkpoint.session.uid,
    currentUid: currentUid,
    currentIsAnonymous: currentIsAnonymous,
  );
  if (!alreadyRecovered) {
    if (normalizedCurrent == null ||
        normalizedCurrent.isEmpty ||
        normalizedCurrent == checkpoint.session.uid) {
      try {
        await recoverFirebaseIdentity();
      } catch (error) {
        failures.add(error);
      }
    } else {
      failures.add(
        const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        ),
      );
    }
  }

  if (failures.isNotEmpty) {
    throw AccountDeletionRecoveryException(List<Object>.unmodifiable(failures));
  }
}

class CompletedDeletionFeedbackActivationCoordinator {
  const CompletedDeletionFeedbackActivationCoordinator({
    required this.completedStore,
    required this.activationStore,
    required this.activateFeedback,
  });

  final AccountDeletionJournalStore completedStore;
  final AccountDeletionJournalStore activationStore;
  final AccountDeletionFeedbackActivator activateFeedback;

  Future<void> run() async {
    final completed = await _read(completedStore);
    final activation = await _read(activationStore);
    final checkpoint = completed ?? activation;
    if (checkpoint?.operation?.phase != AccountOperationPhase.completed ||
        checkpoint?.operationId == null ||
        (completed != null &&
            activation != null &&
            jsonEncode(completed.toJson()) !=
                jsonEncode(activation.toJson()))) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    final durableCheckpoint = checkpoint!;

    if (activation == null) {
      await _write(activationStore, durableCheckpoint);
    }
    if (completed != null) {
      await _clear(completedStore, durableCheckpoint.operationId!);
    }

    bool activated;
    try {
      activated = await activateFeedback(durableCheckpoint.session.uid);
    } catch (_) {
      throw _retryableFailure();
    }
    if (!activated) {
      throw _retryableFailure();
    }

    await _clear(activationStore, durableCheckpoint.operationId!);
  }

  Future<AccountDeletionJournal?> _read(
    AccountDeletionJournalStore store,
  ) async {
    try {
      return await store.read();
    } on AccountOperationFailure {
      rethrow;
    } catch (_) {
      throw _retryableFailure();
    }
  }

  Future<void> _write(
    AccountDeletionJournalStore store,
    AccountDeletionJournal checkpoint,
  ) async {
    try {
      await store.write(checkpoint);
    } catch (_) {
      throw _retryableFailure();
    }
  }

  Future<void> _clear(
    AccountDeletionJournalStore store,
    String operationId,
  ) async {
    try {
      await store.clearCompleted(operationId);
    } catch (_) {
      throw _retryableFailure();
    }
  }

  static AccountOperationFailure _retryableFailure() =>
      const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
}

typedef CompletedDeletionFeedbackPreparation = Future<bool> Function();
typedef CompletedDeletionFeedbackFinalization = Future<void> Function();

class CompletedDeletionFeedbackSerialGate {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

/// Keeps the durable admission scope separate from feedback activation.
///
/// The preparation callback may hold the shared account-auth gate. It must
/// finish before [closeAfterAdmission] and [finalizeAfterAdmission], because
/// both feedback lifecycle operations serialize with activation, whose
/// authoritative journal reads acquire that same gate.
class CompletedDeletionFeedbackFinalizer {
  const CompletedDeletionFeedbackFinalizer({
    required this.prepareWithinAdmission,
    required this.closeAfterAdmission,
    required this.finalizeAfterAdmission,
  });

  final CompletedDeletionFeedbackPreparation prepareWithinAdmission;
  final CompletedDeletionFeedbackFinalization closeAfterAdmission;
  final CompletedDeletionFeedbackFinalization finalizeAfterAdmission;

  Future<bool> run() async {
    if (!await prepareWithinAdmission()) {
      return false;
    }
    await closeAfterAdmission();
    await finalizeAfterAdmission();
    return true;
  }
}

Future<void> _noopAccountDeletionFeedbackCloser() async {}

class AccountDeletionRemoteGate {
  const AccountDeletionRemoteGate({
    required this.readCheckpoint,
    required this.startOrResumeRemote,
    required this.recoverCompleted,
    required this.preflight,
    this.closeFeedback = _noopAccountDeletionFeedbackCloser,
  });

  final CompletedDeletionCheckpointReader readCheckpoint;
  final Future<void> Function() startOrResumeRemote;
  final CompletedDeletionRecovery recoverCompleted;
  final CompletedDeletionPreflight preflight;
  final AccountDeletionFeedbackCloser closeFeedback;

  Future<void> run() async {
    final checkpoint = await readCheckpoint();
    if (checkpoint?.operation?.phase == AccountOperationPhase.completed) {
      preflight(checkpoint!);
      await closeFeedback();
      await recoverCompleted(checkpoint);
      return;
    }
    await startOrResumeRemote();
  }
}

/// Recovers only an already-completed account deletion.
///
/// Unlike [AccountDeletionRemoteGate], absence or mutation of the completed
/// checkpoint is a hard block and can never fall through to a new request.
class CompletedAccountDeletionRecoveryGate {
  const CompletedAccountDeletionRecoveryGate({
    required this.readCheckpoint,
    required this.recoverCompleted,
    required this.closeFeedback,
    required this.preflight,
  });

  final CompletedDeletionCheckpointReader readCheckpoint;
  final CompletedDeletionRecovery recoverCompleted;
  final AccountDeletionFeedbackCloser closeFeedback;
  final CompletedDeletionPreflight preflight;

  Future<void> run() async {
    final checkpoint = await readCheckpoint();
    if (checkpoint?.operation?.phase != AccountOperationPhase.completed ||
        checkpoint?.operationId == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    preflight(checkpoint!);
    await closeFeedback();
    await recoverCompleted(checkpoint);
  }
}

/// Retained for the local cleanup workflow's existing recovery contract.
class AccountDeletionRecoveryException implements Exception {
  const AccountDeletionRecoveryException(this.causes);

  final List<Object> causes;

  @override
  String toString() =>
      'The account was deleted, but identity recovery failed '
      '(${causes.length} failure(s)).';
}

/// Orders sensitive remote account deletion operations around Task 2's strict
/// push-ownership transition.
class AccountDeletionCoordinator {
  const AccountDeletionCoordinator({
    required this.operations,
    required this.ownershipTransitions,
    required this.sessions,
    this.closeFeedback = _noopAccountDeletionFeedbackCloser,
    this.pollDelay = _defaultAccountOperationPollDelay,
    this.maxPolls = 30,
  }) : assert(maxPolls > 0);

  final AccountDeletionOperations operations;
  final PushOwnershipTransitionCoordinator ownershipTransitions;
  final CloudWriteSessionController sessions;
  final AccountDeletionFeedbackCloser closeFeedback;
  final Future<void> Function(Duration duration) pollDelay;
  final int maxPolls;

  Future<void> deleteAccount() async {
    try {
      await _deleteAccount();
    } on AccountOperationFailure {
      rethrow;
    } on AccountDeletionRecoveryException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_safeAccountDeletionFailure(error), stackTrace);
    }
  }

  Future<void> _deleteAccount() async {
    final existing = await operations.readDeletionJournal();
    if (existing != null) {
      await resumePendingDeletion(journal: existing);
      return;
    }

    // A secure receipt can outlive the first non-secret journal write. Reuse
    // that exact capability/request key so the next explicit deletion remains
    // idempotent. A receipt owned by any other source fails closed.
    final orphanReceipt = await operations.readDeletionStatusReceipt();
    if (orphanReceipt != null && orphanReceipt.sourceUid != operations.userId) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }

    final providers = operations.providerState;
    String? appleAuthorizationCode;
    if (providers.isAppleLinked) {
      appleAuthorizationCode = _requireAppleAuthorizationCode(
        await operations.reauthenticateWithApple(),
      );
    } else if (providers.isGoogleLinked) {
      await operations.reauthenticateWithGoogle();
    }

    AccountDeletionJournal? journal;
    AccountDeletionStatusReceipt? receipt;
    try {
      final transitionResult = await ownershipTransitions.run(
        oldUid: operations.userId,
        transition: () async {
          final quiesced = sessions.current;
          if (quiesced == null ||
              quiesced.uid != operations.userId ||
              quiesced.mode != CloudWriteMode.quiesced) {
            throw const AccountOperationFailure(
              AccountOperationFailureCode.blocked,
              retryable: false,
            );
          }
          final requestKey =
              orphanReceipt?.requestKey ?? operations.createRequestKey();
          receipt = await operations.createDeletionStatusReceipt(
            sourceUid: operations.userId,
            requestKey: requestKey,
          );
          journal = AccountDeletionJournal.pending(
            session: quiesced,
            requestKey: requestKey,
            sourceProviders: {
              if (operations.providerState.isGoogleLinked) 'google',
              if (operations.providerState.isAppleLinked) 'apple',
            },
          );
          await operations.writeDeletionJournal(journal!);
          final requested = orphanReceipt == null
              ? await operations.requestAccountDeletion(
                  AccountDeletionRequest(
                    requestKey: journal!.requestKey,
                    terminalStatusReceipt: receipt!.terminalStatusReceipt,
                  ),
                )
              : await _readReceiptStatusOrRequest(journal!, receipt!);
          _requireDeletionOperation(requested);
          receipt = await operations.bindDeletionStatusReceipt(
            expected: receipt!,
            operationId: requested.operationId,
          );
          journal = journal!.copyWith(operation: requested);
          await operations.writeDeletionJournal(journal!);
          await closeFeedback();
          journal = await _pollToTerminal(
            journal!,
            receipt: receipt!,
            appleAuthorizationCode: appleAuthorizationCode,
          );
        },
      );
      if (transitionResult != CloudWriteResult.completed) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
    } catch (_) {
      await _persistCurrentOwnedSession(journal);
      rethrow;
    }
    await _persistCurrentOwnedSession(journal);
    final completedReceipt = receipt;
    if (completedReceipt != null) {
      await _acknowledgeAndClearReceipt(completedReceipt);
    }
    await _recoverDeletedIdentity();
  }

  Future<void> resumePendingDeletion({AccountDeletionJournal? journal}) async {
    try {
      var pending = journal ?? await operations.readDeletionJournal();
      if (pending == null) {
        return;
      }
      if (pending.session.uid != operations.userId) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.permissionDenied,
          retryable: false,
        );
      }
      var expectedSession = pending.session;
      _requireExactSession(expectedSession);
      var receipt = await _readOrCreateMatchingReceipt(pending);
      if (pending.operation == null) {
        _requireExactSession(expectedSession);
        final requested = await _readReceiptStatusOrRequest(pending, receipt);
        _requireExactSession(expectedSession);
        _requireDeletionOperation(requested);
        receipt = await operations.bindDeletionStatusReceipt(
          expected: receipt,
          operationId: requested.operationId,
        );
        pending = pending.copyWith(operation: requested);
        await operations.writeDeletionJournal(pending);
        _requireExactSession(expectedSession);
      } else {
        receipt = await operations.bindDeletionStatusReceipt(
          expected: receipt,
          operationId: pending.operationId!,
        );
      }
      await closeFeedback();
      _requireExactSession(expectedSession);
      final completed = await _pollToTerminal(
        pending,
        receipt: receipt,
        requiredSession: expectedSession,
      );
      _requireExactSession(expectedSession);
      if (completed.operation?.phase != AccountOperationPhase.completed) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
      if (expectedSession.mode != CloudWriteMode.cleanupPending) {
        _requireExactSession(expectedSession);
        expectedSession = sessions.transition(CloudWriteMode.cleanupPending);
        _requireExactSession(expectedSession);
      }
      _requireExactSession(expectedSession);
      await operations.writeDeletionJournal(
        completed.copyWith(session: expectedSession),
      );
      _requireExactSession(expectedSession);
      await _acknowledgeAndClearReceipt(receipt);
      _requireExactSession(expectedSession);
      await _recoverDeletedIdentity();
    } on AccountOperationFailure {
      rethrow;
    } on AccountDeletionRecoveryException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_safeAccountDeletionFailure(error), stackTrace);
    }
  }

  AccountOperationFailure _safeAccountDeletionFailure(Object error) {
    if (error is AccountDeletionStatusReceiptFailure) {
      return switch (error.code) {
        AccountDeletionStatusReceiptFailureCode.unavailable ||
        AccountDeletionStatusReceiptFailureCode.verificationFailed =>
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        AccountDeletionStatusReceiptFailureCode.invalidRecord ||
        AccountDeletionStatusReceiptFailureCode.conflict =>
          const AccountOperationFailure(
            AccountOperationFailureCode.blocked,
            retryable: false,
          ),
      };
    }
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'requires-recent-login' => const AccountOperationFailure(
          AccountOperationFailureCode.recentAuthenticationRequired,
          retryable: false,
        ),
        'user-token-expired' ||
        'invalid-user-token' => const AccountOperationFailure(
          AccountOperationFailureCode.authenticationRequired,
          retryable: false,
        ),
        'network-request-failed' => const AccountOperationFailure(
          AccountOperationFailureCode.unavailable,
          retryable: true,
        ),
        _ => const AccountOperationFailure(
          AccountOperationFailureCode.unknown,
          retryable: false,
        ),
      };
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const AccountOperationFailure(
          AccountOperationFailureCode.permissionDenied,
          retryable: false,
        ),
        'unavailable' => const AccountOperationFailure(
          AccountOperationFailureCode.unavailable,
          retryable: true,
        ),
        _ => const AccountOperationFailure(
          AccountOperationFailureCode.unknown,
          retryable: false,
        ),
      };
    }
    return const AccountOperationFailure(
      AccountOperationFailureCode.unknown,
      retryable: false,
    );
  }

  Future<void> _persistCurrentOwnedSession(
    AccountDeletionJournal? journal,
  ) async {
    final current = sessions.current;
    if (journal != null &&
        current != null &&
        current.uid == operations.userId) {
      await operations.writeDeletionJournal(journal.copyWith(session: current));
    }
  }

  Future<void> _recoverDeletedIdentity() async {
    try {
      await operations.recoverDeletedIdentity();
    } on AccountDeletionRecoveryException {
      rethrow;
    } catch (error) {
      throw AccountDeletionRecoveryException(<Object>[error]);
    }
  }

  Future<AccountDeletionJournal> _pollToTerminal(
    AccountDeletionJournal initial, {
    required AccountDeletionStatusReceipt receipt,
    String? appleAuthorizationCode,
    CloudWriteSession? requiredSession,
  }) async {
    var journal = initial;
    var result = journal.operation!;
    for (var poll = 0; poll < maxPolls; poll += 1) {
      _requireDeletionOperation(
        result,
        expectedOperationId: journal.operationId,
      );
      if (result.phase == AccountOperationPhase.completed) {
        _requireExactSessionIfPresent(requiredSession);
        return journal;
      }
      if (result.phase == AccountOperationPhase.blocked) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
      final expectedOperationId = result.operationId;
      if (result.phase == AccountOperationPhase.appleRevocationPending) {
        _requireExactSessionIfPresent(requiredSession);
        final code =
            appleAuthorizationCode ??
            _requireAppleAuthorizationCode(
              await operations.reauthenticateWithApple(),
            );
        _requireExactSessionIfPresent(requiredSession);
        appleAuthorizationCode = null;
        _requireExactSessionIfPresent(requiredSession);
        result = await operations.completeAppleRevocation(
          AppleRevocationCompletionRequest(
            operationId: expectedOperationId,
            expectedVersion: result.version,
            authorizationCode: code,
          ),
        );
        _requireExactSessionIfPresent(requiredSession);
      } else {
        _requireExactSessionIfPresent(requiredSession);
        await pollDelay(const Duration(seconds: 2));
        _requireExactSessionIfPresent(requiredSession);
        try {
          result = await operations.getAccountDeletionStatusByReceipt(
            AccountDeletionStatusByReceiptRequest(
              terminalStatusReceipt: receipt.terminalStatusReceipt,
            ),
          );
        } on AccountOperationFailure catch (failure) {
          if (failure.code != AccountOperationFailureCode.operationNotFound) {
            rethrow;
          }
          result = await operations.requestAccountDeletion(
            AccountDeletionRequest(
              requestKey: journal.requestKey,
              terminalStatusReceipt: receipt.terminalStatusReceipt,
            ),
          );
        }
        _requireExactSessionIfPresent(requiredSession);
      }
      _requireDeletionOperation(
        result,
        expectedOperationId: expectedOperationId,
      );
      journal = journal.copyWith(operation: result);
      _requireExactSessionIfPresent(requiredSession);
      if (result.phase == AccountOperationPhase.completed) {
        return journal;
      }
      await operations.writeDeletionJournal(journal);
      _requireExactSessionIfPresent(requiredSession);
    }
    throw const AccountOperationFailure(
      AccountOperationFailureCode.unavailable,
      retryable: true,
    );
  }

  Future<AccountDeletionStatusReceipt> _readOrCreateMatchingReceipt(
    AccountDeletionJournal journal,
  ) async {
    final existing = await operations.readDeletionStatusReceipt();
    final receipt =
        existing ??
        await operations.createDeletionStatusReceipt(
          sourceUid: journal.session.uid,
          requestKey: journal.requestKey,
        );
    final operationIdMatches =
        receipt.operationId == null ||
        journal.operationId == null ||
        receipt.operationId == journal.operationId;
    if (!receipt.matchesWorkflow(
          sourceUid: journal.session.uid,
          requestKey: journal.requestKey,
        ) ||
        !operationIdMatches) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    return receipt;
  }

  Future<AccountOperationResult> _readReceiptStatusOrRequest(
    AccountDeletionJournal journal,
    AccountDeletionStatusReceipt receipt,
  ) async {
    try {
      return await operations.getAccountDeletionStatusByReceipt(
        AccountDeletionStatusByReceiptRequest(
          terminalStatusReceipt: receipt.terminalStatusReceipt,
        ),
      );
    } on AccountOperationFailure catch (failure) {
      if (failure.code != AccountOperationFailureCode.operationNotFound) {
        rethrow;
      }
      return operations.requestAccountDeletion(
        AccountDeletionRequest(
          requestKey: journal.requestKey,
          terminalStatusReceipt: receipt.terminalStatusReceipt,
        ),
      );
    }
  }

  Future<void> _acknowledgeAndClearReceipt(
    AccountDeletionStatusReceipt receipt,
  ) async {
    await operations.acknowledgeAccountDeletionStatusReceipt(
      AccountDeletionStatusByReceiptRequest(
        terminalStatusReceipt: receipt.terminalStatusReceipt,
      ),
    );
    if (!await operations.clearDeletionStatusReceipt(receipt)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  void _requireExactSessionIfPresent(CloudWriteSession? expected) {
    if (expected != null) {
      _requireExactSession(expected);
    }
  }

  void _requireExactSession(CloudWriteSession expected) {
    if (sessions.current != expected) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  void _requireDeletionOperation(
    AccountOperationResult result, {
    String? expectedOperationId,
  }) {
    if (result.kind != AccountOperationKind.deletion ||
        (expectedOperationId != null &&
            result.operationId != expectedOperationId)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  String _requireAppleAuthorizationCode(String? authorizationCode) {
    final code = authorizationCode?.trim();
    if (code == null || code.isEmpty) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.recentAuthenticationRequired,
        retryable: false,
      );
    }
    return code;
  }
}

Future<void> _defaultAccountOperationPollDelay(Duration duration) {
  return Future<void>.delayed(duration);
}

typedef AccountDeletionReceiptStatusReader =
    Future<AccountOperationResult> Function(
      AccountDeletionStatusByReceiptRequest request,
    );
typedef AccountDeletionReceiptAcknowledger =
    Future<void> Function(AccountDeletionStatusByReceiptRequest request);
typedef AccountDeletionReceiptIdentityReader =
    ({String? uid, bool isAnonymous}) Function();

enum AccountDeletionReceiptRecoveryStatus { pending, completed, unavailable }

/// Recovers only an already-requested deletion through its device-held status
/// capability. This path never creates or advances a remote operation and can
/// run after the worker has deleted the source Firebase Auth identity.
class AccountDeletionReceiptRecoveryCoordinator {
  const AccountDeletionReceiptRecoveryCoordinator({
    required this.journalStore,
    required this.receiptStore,
    required this.sessions,
    required this.currentIdentity,
    required this.readStatus,
    required this.acknowledge,
    required this.closeFeedback,
    required this.recoverCompleted,
  });

  final AccountDeletionJournalStore journalStore;
  final AccountDeletionStatusReceiptStore receiptStore;
  final CloudWriteSessionController sessions;
  final AccountDeletionReceiptIdentityReader currentIdentity;
  final AccountDeletionReceiptStatusReader readStatus;
  final AccountDeletionReceiptAcknowledger acknowledge;
  final AccountDeletionFeedbackCloser closeFeedback;
  final CompletedDeletionRecovery recoverCompleted;

  Future<AccountDeletionReceiptRecoveryStatus> resume() async {
    try {
      return await _resume();
    } on AccountOperationFailure catch (failure) {
      if (failure.retryable ||
          failure.code == AccountOperationFailureCode.operationNotFound) {
        return AccountDeletionReceiptRecoveryStatus.unavailable;
      }
      rethrow;
    } on AccountDeletionStatusReceiptFailure catch (failure) {
      if (failure.code == AccountDeletionStatusReceiptFailureCode.unavailable ||
          failure.code ==
              AccountDeletionStatusReceiptFailureCode.verificationFailed) {
        return AccountDeletionReceiptRecoveryStatus.unavailable;
      }
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    } on AccountDeletionRecoveryException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const AccountOperationFailure(
          AccountOperationFailureCode.unknown,
          retryable: false,
        ),
        stackTrace,
      );
    }
  }

  Future<AccountDeletionReceiptRecoveryStatus> _resume() async {
    final identitySnapshot = _identitySnapshot();
    var journal = await _guardIdentity(identitySnapshot, journalStore.read);
    if (journal == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    var activeJournal = journal;
    _requireSafeStartingIdentity(activeJournal, identitySnapshot);
    final receipt = await _guardIdentity(identitySnapshot, receiptStore.read);
    if (receipt == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    _requireMatchingReceipt(activeJournal, receipt);

    AccountOperationResult status;
    try {
      status = await _guardIdentity(
        identitySnapshot,
        () => readStatus(
          AccountDeletionStatusByReceiptRequest(
            terminalStatusReceipt: receipt.terminalStatusReceipt,
          ),
        ),
      );
    } on AccountOperationFailure catch (failure) {
      if (failure.code != AccountOperationFailureCode.operationNotFound ||
          !_isStrictAcknowledgementRetry(activeJournal, receipt)) {
        rethrow;
      }
      // A previous ACK may have committed server-side while its response was
      // lost. The idempotent ACK is the only safe proof for the tombstoned
      // capability: unknown/nonterminal receipts still return not-found.
      await _guardIdentity(identitySnapshot, closeFeedback);
      await _guardIdentity(
        identitySnapshot,
        () => acknowledge(
          AccountDeletionStatusByReceiptRequest(
            terminalStatusReceipt: receipt.terminalStatusReceipt,
          ),
        ),
      );
      await _clearReceipt(identitySnapshot, receipt);
      _requireIdentityUnchanged(identitySnapshot);
      await recoverCompleted(activeJournal);
      return AccountDeletionReceiptRecoveryStatus.completed;
    }

    _requireCompatibleStatus(activeJournal, receipt, status);
    if (status.phase == AccountOperationPhase.blocked ||
        status.phase == AccountOperationPhase.cancelled) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    if (activeJournal.operation?.phase == AccountOperationPhase.completed &&
        (status.phase != AccountOperationPhase.completed || status.retryable)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }

    final boundReceipt = await _guardIdentity(
      identitySnapshot,
      () => receiptStore.bindOperation(
        expected: receipt,
        operationId: status.operationId,
      ),
    );
    activeJournal = activeJournal.copyWith(operation: status);
    if (status.phase != AccountOperationPhase.completed) {
      await _guardIdentity(identitySnapshot, closeFeedback);
      await _guardIdentity(
        identitySnapshot,
        () => journalStore.write(activeJournal),
      );
      return AccountDeletionReceiptRecoveryStatus.pending;
    }
    if (status.retryable) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }

    await _guardIdentity(identitySnapshot, closeFeedback);
    _requireIdentityUnchanged(identitySnapshot);
    final completed = activeJournal.copyWith(
      session: _cleanupSession(activeJournal),
    );
    _requireIdentityUnchanged(identitySnapshot);
    // The non-secret completed checkpoint is the durable proof boundary. ACK
    // and secure-capability removal may be retried after any later failure.
    await _guardIdentity(identitySnapshot, () => journalStore.write(completed));
    await _guardIdentity(
      identitySnapshot,
      () => acknowledge(
        AccountDeletionStatusByReceiptRequest(
          terminalStatusReceipt: boundReceipt.terminalStatusReceipt,
        ),
      ),
    );
    await _clearReceipt(identitySnapshot, boundReceipt);
    _requireIdentityUnchanged(identitySnapshot);
    await recoverCompleted(completed);
    return AccountDeletionReceiptRecoveryStatus.completed;
  }

  Future<void> _clearReceipt(
    ({String? uid, bool isAnonymous}) identitySnapshot,
    AccountDeletionStatusReceipt receipt,
  ) async {
    final cleared = await _guardIdentity(
      identitySnapshot,
      () => receiptStore.clearIfCurrent(receipt),
    );
    if (!cleared) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  void _requireMatchingReceipt(
    AccountDeletionJournal journal,
    AccountDeletionStatusReceipt receipt,
  ) {
    final operationMatches =
        receipt.operationId == null ||
        journal.operationId == null ||
        receipt.operationId == journal.operationId;
    if (!receipt.matchesWorkflow(
          sourceUid: journal.session.uid,
          requestKey: journal.requestKey,
        ) ||
        !operationMatches) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  void _requireSafeStartingIdentity(
    AccountDeletionJournal journal,
    ({String? uid, bool isAnonymous}) identity,
  ) {
    final uid = identity.uid;
    final isCompletedAfterRecovery =
        journal.operation?.phase == AccountOperationPhase.completed &&
        journal.operation?.retryable == false &&
        journal.session.mode == CloudWriteMode.cleanupPending;
    final safe = switch (uid) {
      null => !identity.isAnonymous,
      final value when value == journal.session.uid => true,
      _ => identity.isAnonymous && isCompletedAfterRecovery,
    };
    if (!safe) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  void _requireCompatibleStatus(
    AccountDeletionJournal journal,
    AccountDeletionStatusReceipt receipt,
    AccountOperationResult status,
  ) {
    final prior = journal.operation;
    final expectedOperationId = prior?.operationId ?? receipt.operationId;
    if (status.kind != AccountOperationKind.deletion ||
        (expectedOperationId != null &&
            status.operationId != expectedOperationId) ||
        (prior != null && status.version < prior.version)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  bool _isStrictAcknowledgementRetry(
    AccountDeletionJournal journal,
    AccountDeletionStatusReceipt receipt,
  ) {
    return journal.operation?.phase == AccountOperationPhase.completed &&
        journal.operation?.retryable == false &&
        journal.operationId != null &&
        journal.session.mode == CloudWriteMode.cleanupPending &&
        receipt.operationId == journal.operationId;
  }

  ({String? uid, bool isAnonymous}) _identitySnapshot() {
    final identity = currentIdentity();
    final normalized = identity.uid?.trim();
    return (
      uid: normalized == null || normalized.isEmpty ? null : normalized,
      isAnonymous: identity.isAnonymous,
    );
  }

  void _requireIdentityUnchanged(({String? uid, bool isAnonymous}) expected) {
    if (_identitySnapshot() != expected) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
  }

  Future<T> _guardIdentity<T>(
    ({String? uid, bool isAnonymous}) expected,
    Future<T> Function() action,
  ) async {
    _requireIdentityUnchanged(expected);
    try {
      final result = await action();
      _requireIdentityUnchanged(expected);
      return result;
    } catch (error, stackTrace) {
      _requireIdentityUnchanged(expected);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  CloudWriteSession _cleanupSession(AccountDeletionJournal journal) {
    if (journal.session.mode == CloudWriteMode.cleanupPending) {
      return journal.session;
    }
    final current = sessions.current;
    if (current == journal.session) {
      return sessions.transition(CloudWriteMode.cleanupPending);
    }
    // A prior attempt can transition the in-memory fence and then fail while
    // durably writing the completed journal. Accept only that exact one-step
    // successor so the same receipt/status operation remains retryable.
    if (current != null &&
        current.uid == journal.session.uid &&
        current.mode == CloudWriteMode.cleanupPending &&
        current.epoch == journal.session.epoch + 1) {
      return current;
    }
    if (current == null) {
      return journal.session.copyWith(mode: CloudWriteMode.cleanupPending);
    }
    final identity = currentIdentity();
    if (identity.isAnonymous &&
        identity.uid == current.uid &&
        current.uid != journal.session.uid) {
      return journal.session.copyWith(mode: CloudWriteMode.cleanupPending);
    }
    throw const AccountOperationFailure(
      AccountOperationFailureCode.blocked,
      retryable: false,
    );
  }
}

class _FirebaseAccountDeletionOperations implements AccountDeletionOperations {
  const _FirebaseAccountDeletionOperations({
    required this.user,
    required this.client,
    required this.anonymousSource,
    required this.sessions,
    required this.journalStore,
    required this.receiptStore,
  });

  final User user;
  final AccountOperationGateway client;
  final FreshAnonymousAccountOperationGateway anonymousSource;
  final CloudWriteSessionController sessions;
  final AccountDeletionJournalStore journalStore;
  final AccountDeletionStatusReceiptStore receiptStore;

  @override
  String get userId => user.uid;

  @override
  AuthProviderState get providerState => AuthProviderState.fromProviderIds(
    user.providerData.map((provider) => provider.providerId),
  );

  @override
  Future<void> recoverDeletedIdentity() async {
    final failures = <Object>[];
    if (providerState.isGoogleLinked) {
      try {
        await GoogleSignIn().signOut();
      } catch (error) {
        failures.add(error);
      }
    }
    final auth = AuthService._auth;
    if (auth == null) {
      failures.add(
        const AccountOperationFailure(
          AccountOperationFailureCode.authenticationRequired,
          retryable: false,
        ),
      );
    } else {
      try {
        await auth.signOut();
      } catch (error) {
        failures.add(error);
      }
      Object? lastAnonymousFailure;
      for (var attempt = 0; attempt < 2; attempt += 1) {
        try {
          await AuthService.ensureSignedIn();
          lastAnonymousFailure = null;
          break;
        } catch (error) {
          lastAnonymousFailure = error;
        }
      }
      if (lastAnonymousFailure != null) {
        failures.add(lastAnonymousFailure);
      }
    }
    if (failures.isNotEmpty) {
      throw AccountDeletionRecoveryException(
        List<Object>.unmodifiable(failures),
      );
    }
  }

  @override
  Future<AccountOperationResult> completeAppleRevocation(
    AppleRevocationCompletionRequest request,
  ) {
    return client.completeAppleRevocation(request);
  }

  @override
  String createRequestKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<AccountOperationResult> getAccountOperation(
    AccountOperationStatusRequest request,
  ) {
    return client.getAccountOperation(request);
  }

  @override
  Future<AccountOperationResult> getAccountDeletionStatusByReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) {
    return client.getAccountDeletionStatusByReceipt(request);
  }

  @override
  Future<void> acknowledgeAccountDeletionStatusReceipt(
    AccountDeletionStatusByReceiptRequest request,
  ) {
    return client.acknowledgeAccountDeletionStatusReceipt(request);
  }

  @override
  Future<AccountDeletionJournal?> readDeletionJournal() {
    return journalStore.read();
  }

  @override
  Future<AccountDeletionStatusReceipt?> readDeletionStatusReceipt() {
    return receiptStore.read();
  }

  @override
  Future<AccountDeletionStatusReceipt> createDeletionStatusReceipt({
    required String sourceUid,
    required String requestKey,
  }) {
    return receiptStore.create(sourceUid: sourceUid, requestKey: requestKey);
  }

  @override
  Future<AccountDeletionStatusReceipt> bindDeletionStatusReceipt({
    required AccountDeletionStatusReceipt expected,
    required String operationId,
  }) {
    return receiptStore.bindOperation(
      expected: expected,
      operationId: operationId,
    );
  }

  @override
  Future<bool> clearDeletionStatusReceipt(
    AccountDeletionStatusReceipt expected,
  ) {
    return receiptStore.clearIfCurrent(expected);
  }

  @override
  Future<String?> reauthenticateWithApple() {
    return AuthService._reauthenticateWithApple(user);
  }

  @override
  Future<void> reauthenticateWithGoogle() {
    return AuthService._reauthenticateWithGoogle(user);
  }

  @override
  Future<AccountOperationResult> requestAccountDeletion(
    AccountDeletionRequest request,
  ) {
    if (user.isAnonymous) {
      final expectedSession = sessions.current;
      if (expectedSession == null || expectedSession.uid != user.uid) {
        throw const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        );
      }
      return anonymousSource.requestAnonymousAccountDeletion(
        expectedSession: expectedSession,
        request: request,
      );
    }
    return client.requestAccountDeletion(request);
  }

  @override
  Future<void> writeDeletionJournal(AccountDeletionJournal journal) {
    return journalStore.write(journal);
  }
}

class _SharedPreferencesAccountDeletionJournalStore
    implements AccountDeletionJournalStore {
  const _SharedPreferencesAccountDeletionJournalStore([
    this.key = AuthService.accountDeletionCheckpointPreferenceKey,
  ]);

  final String key;

  @override
  Future<void> clearCompleted(String operationId) async {
    final current = await read();
    if (current?.operation?.phase != AccountOperationPhase.completed ||
        current?.operationId != operationId) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(key);
    if (!removed && preferences.containsKey(key)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
    }
  }

  @override
  Future<AccountDeletionJournal?> read() async {
    final encoded = (await SharedPreferences.getInstance()).getString(key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException();
      }
      return AccountDeletionJournal.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.invalidResponse,
        retryable: false,
      );
    }
  }

  @override
  Future<void> write(AccountDeletionJournal journal) async {
    final preferences = await SharedPreferences.getInstance();
    final wrote = await preferences.setString(
      key,
      jsonEncode(journal.toJson()),
    );
    if (!wrote) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
    }
  }
}

abstract interface class UserDataDeletionStore {
  Future<void> deleteSubcollection(String name);
  Future<void> removeUserFields(Set<String> fields);
}

class UserDataDeletionCoordinator {
  const UserDataDeletionCoordinator(this.store);

  final UserDataDeletionStore store;

  static const Set<String> operationalFields = {
    'gyeIds',
    'blockedUids',
    'fcmTokens',
  };

  static const Set<String> backupFields = {
    'vok',
    'chosung',
    'wordle',
    'grammar',
    'app',
    'progress',
    'srs_json',
    'custom_packs_json',
    'bookshelf_json',
    'updated_at',
  };

  static const List<String> backupSubcollections = [
    'packs',
    'quests',
    'bookshelf',
    'custom_packs',
    'custom_words',
    'sync_generations',
    'sync_metadata',
  ];

  Future<void> deleteCloudBackup() async {
    for (final collectionName in backupSubcollections) {
      await store.deleteSubcollection(collectionName);
    }
    await store.removeUserFields(backupFields);
  }
}

/// Hybrid-Auth — **immer** anonym eingeloggt. Optional kann der
/// User mit Google verlinken, um Cloud-Backup zu aktivieren.
///
/// **Web-Sicherheit**: Firebase ist auf Web fragil (JS-Interop) — wenn keine
/// Firebase-Config vorliegt, wirft `FirebaseAuth.instance` eine
/// `FirebaseException`, die als JS-`TypeError` durchschlägt und z.B. die
/// Settings-Seite rot crashen lässt. Daher fangen **alle Lese-Getter**
/// Ausnahmen ab und liefern sichere Defaults; Aktions-Methoden brechen
/// sauber ab, wenn Firebase nicht verfügbar ist. Auf Android (mit
/// google-services.json) greifen die Guards nie — normales Verhalten.
@immutable
class TemporaryFirebaseUser {
  const TemporaryFirebaseUser({required this.uid, required this.isAnonymous});

  final String uid;
  final bool isAnonymous;
}

abstract interface class TemporaryFirebaseAuthContext {
  AccountOperationGateway get operationGateway;
  Future<TemporaryFirebaseUser> signIn(AuthCredential credential);
  Future<void> dispose();
}

abstract interface class TemporaryFirebaseReconciliationContext
    implements TemporaryFirebaseAuthContext {
  FirebaseAccountReconciliationRemote reconciliationRemote({
    required String fenceUid,
  });
}

typedef TemporaryFirebaseAuthContextFactory =
    Future<TemporaryFirebaseAuthContext> Function();
typedef FreshProviderCredential =
    Future<AuthCredential> Function(AccountLinkProvider provider);
typedef SilentGoogleActivationCredential = Future<AuthCredential?> Function();
typedef ExplicitAppleActivationCredential = Future<AuthCredential> Function();

class FirebaseIsolatedTargetVerifier implements IsolatedTargetVerifier {
  FirebaseIsolatedTargetVerifier({
    TemporaryFirebaseAuthContextFactory? openContext,
    FreshProviderCredential? acquireCredential,
  }) : _openContext = openContext ?? _openTemporaryFirebaseContext,
       _acquireCredential =
           acquireCredential ?? AuthService._acquireFreshProviderCredential;

  final TemporaryFirebaseAuthContextFactory _openContext;
  final FreshProviderCredential _acquireCredential;

  @override
  Future<VerifiedTargetContext> verify(AccountLinkProvider provider) async {
    final context = await _openContext();
    try {
      final credential = await _acquireCredential(provider);
      final user = await context.signIn(credential);
      if (user.uid.trim().isEmpty || user.isAnonymous) {
        throw const AccountLinkSafetyFailure();
      }
      if (context is TemporaryFirebaseReconciliationContext) {
        return _FirebaseVerifiedReconciliationTargetContext(
          context: context,
          user: user,
        );
      }
      return _FirebaseVerifiedTargetContext(context: context, user: user);
    } catch (_) {
      await context.dispose();
      rethrow;
    }
  }

  static Future<TemporaryFirebaseAuthContext>
  _openTemporaryFirebaseContext() async {
    final primary = Firebase.app();
    final random = Random.secure();
    final suffix = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final app = await Firebase.initializeApp(
      name: 'account-transition-$suffix',
      options: primary.options,
    );
    return initializeTemporaryContextWithCleanup(
      initializeContext: () => initializeTemporaryAppCheckThen(
        initializerFactory: FirebaseAppCheckInitializer.productionWithActivator,
        activate:
            ({providerWeb, required providerAndroid, required providerApple}) {
              return FirebaseAppCheck.instanceFor(app: app).activate(
                providerWeb: providerWeb,
                providerAndroid: providerAndroid,
                providerApple: providerApple,
              );
            },
        afterActivation: () async => _PluginTemporaryFirebaseAuthContext(app),
      ),
      deleteApp: app.delete,
    );
  }

  /// Activates App Check before a temporary target context can expose an auth
  /// or callable client. The factory seam proves that secondary Firebase apps
  /// use the same Web key/provider policy as the primary app.
  static Future<T> initializeTemporaryAppCheckThen<T>({
    required FirebaseAppCheckInitializerFactory initializerFactory,
    required FirebaseAppCheckActivator activate,
    required Future<T> Function() afterActivation,
  }) async {
    await initializerFactory(activate: activate).initialize();
    return afterActivation();
  }

  /// Ensures a failed asynchronous secondary-App Check activation cannot leak
  /// the isolated Firebase app that was just created for reconciliation.
  static Future<T> initializeTemporaryContextWithCleanup<T>({
    required Future<T> Function() initializeContext,
    required Future<void> Function() deleteApp,
  }) async {
    try {
      return await initializeContext();
    } catch (_) {
      await deleteApp();
      rethrow;
    }
  }
}

class _FirebaseVerifiedTargetContext implements AccountOperationTargetContext {
  const _FirebaseVerifiedTargetContext({
    required TemporaryFirebaseAuthContext context,
    required TemporaryFirebaseUser user,
  }) : this._(context, user);

  const _FirebaseVerifiedTargetContext._(this._context, this._user);

  final TemporaryFirebaseAuthContext _context;
  final TemporaryFirebaseUser _user;

  @override
  String get uid => _user.uid;

  @override
  bool get isAnonymous => _user.isAnonymous;

  @override
  AccountOperationGateway get operationGateway => _context.operationGateway;

  @override
  Future<void> dispose() => _context.dispose();
}

class _FirebaseVerifiedReconciliationTargetContext
    extends _FirebaseVerifiedTargetContext
    implements AccountReconciliationTargetContext {
  const _FirebaseVerifiedReconciliationTargetContext({
    required TemporaryFirebaseReconciliationContext context,
    required super.user,
  }) : _reconciliationContext = context,
       super(context: context);

  final TemporaryFirebaseReconciliationContext _reconciliationContext;

  @override
  FirebaseAccountReconciliationRemote reconciliationRemote({
    required String fenceUid,
  }) => _reconciliationContext.reconciliationRemote(fenceUid: fenceUid);
}

class _PluginTemporaryFirebaseAuthContext
    implements TemporaryFirebaseReconciliationContext {
  _PluginTemporaryFirebaseAuthContext(this._app)
    : _auth = FirebaseAuth.instanceFor(app: _app),
      operationGateway = AccountOperationClient(
        transport: FirebaseFunctionsAccountOperationTransport.fromFunctions(
          FirebaseFunctions.instanceFor(
            app: _app,
            region: AccountOperationClient.region,
          ),
        ),
      );

  final FirebaseApp _app;
  final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: _app,
  );
  bool _disposed = false;

  @override
  final AccountOperationGateway operationGateway;

  @override
  FirebaseAccountReconciliationRemote reconciliationRemote({
    required String fenceUid,
  }) {
    return FirebaseAccountReconciliationRemote.firestore(
      firestore: _firestore,
      fenceUid: fenceUid,
    );
  }

  @override
  Future<TemporaryFirebaseUser> signIn(AuthCredential credential) async {
    if (_disposed) {
      throw const AccountLinkSafetyFailure();
    }
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw const AccountLinkSafetyFailure();
    }
    return TemporaryFirebaseUser(uid: user.uid, isAnonymous: user.isAnonymous);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _auth.signOut();
    } finally {
      await _app.delete();
    }
  }
}

class FirebaseAccountTransitionIdentity implements AccountTransitionIdentity {
  const FirebaseAccountTransitionIdentity()
    : this._(null, null, null, null, null, null);

  const FirebaseAccountTransitionIdentity._(
    this._currentUid,
    this._currentIsAnonymous,
    this._acquireGoogleCredentialSilently,
    this._acquireAppleCredentialExplicitly,
    this._signIn,
    this._signOut,
  );

  @visibleForTesting
  factory FirebaseAccountTransitionIdentity.test({
    required String? Function() currentUid,
    required bool Function() currentIsAnonymous,
    required SilentGoogleActivationCredential acquireGoogleCredentialSilently,
    required ExplicitAppleActivationCredential acquireAppleCredentialExplicitly,
    required Future<String?> Function(AuthCredential credential) signIn,
    required Future<void> Function() signOut,
  }) => FirebaseAccountTransitionIdentity._(
    currentUid,
    currentIsAnonymous,
    acquireGoogleCredentialSilently,
    acquireAppleCredentialExplicitly,
    signIn,
    signOut,
  );

  final String? Function()? _currentUid;
  final bool Function()? _currentIsAnonymous;
  final SilentGoogleActivationCredential? _acquireGoogleCredentialSilently;
  final ExplicitAppleActivationCredential? _acquireAppleCredentialExplicitly;
  final Future<String?> Function(AuthCredential credential)? _signIn;
  final Future<void> Function()? _signOut;

  @override
  String? get currentUid =>
      _currentUid == null ? AuthService.current?.uid : _currentUid();

  @override
  bool get currentIsAnonymous =>
      _currentIsAnonymous?.call() ??
      (AuthService.current?.isAnonymous ?? false);

  @override
  Future<void> activateTarget(
    AccountLinkProvider provider, {
    required String expectedTargetUid,
    required CloudWriteSession expectedSourceSession,
    required CloudWriteSessionController sessions,
    required bool allowMissingSource,
  }) async {
    if (expectedTargetUid.trim().isEmpty) {
      throw const AccountLinkSafetyFailure();
    }
    _assertSource(
      expectedSourceSession,
      sessions,
      allowMissingSource: allowMissingSource,
    );
    final credential = await _acquireActivationCredential(provider);
    _assertSource(
      expectedSourceSession,
      sessions,
      allowMissingSource: allowMissingSource,
    );
    _assertSource(
      expectedSourceSession,
      sessions,
      allowMissingSource: allowMissingSource,
    );
    final signedInUid =
        await (_signIn?.call(credential) ?? _signInPrimary(credential));
    try {
      sessions.assertCurrent(expectedSourceSession);
    } on StateError {
      await _signOutActivationIfOwned(signedInUid: signedInUid);
      throw const AccountLinkSafetyFailure();
    }
    if (signedInUid != expectedTargetUid ||
        currentUid != expectedTargetUid ||
        currentIsAnonymous) {
      await _signOutActivationIfOwned(signedInUid: signedInUid);
      throw const AccountLinkSafetyFailure();
    }
  }

  Future<void> _signOutActivationIfOwned({required String? signedInUid}) async {
    final liveUid = currentUid;
    if (signedInUid == null || liveUid != signedInUid) {
      return;
    }
    // FirebaseAuth exposes no auth-incarnation token here. A concurrent auth
    // replacement that resolves to the exact same UID cannot be distinguished
    // from this call's sign-in; UID-exact ownership is the current model limit.
    await _signOutPrimary();
  }

  Future<AuthCredential> _acquireActivationCredential(
    AccountLinkProvider provider,
  ) async {
    switch (provider) {
      case AccountLinkProvider.google:
        final credential =
            await (_acquireGoogleCredentialSilently?.call() ??
                AuthService._acquireGoogleActivationCredentialSilently());
        if (credential == null) {
          throw const AccountLinkSafetyFailure();
        }
        return credential;
      case AccountLinkProvider.apple:
        return _acquireAppleCredentialExplicitly?.call() ??
            AuthService._acquireAppleActivationCredentialExplicitly();
    }
  }

  void _assertSource(
    CloudWriteSession expected,
    CloudWriteSessionController sessions, {
    required bool allowMissingSource,
  }) {
    try {
      sessions.assertCurrent(expected);
    } on StateError {
      throw const AccountLinkSafetyFailure();
    }
    final uid = currentUid;
    if (uid == expected.uid && currentIsAnonymous) return;
    if (allowMissingSource && uid == null) return;
    throw const AccountLinkSafetyFailure();
  }

  Future<String?> _signInPrimary(AuthCredential credential) async {
    final auth = AuthService._auth;
    if (auth == null) throw const AccountLinkSafetyFailure();
    return (await auth.signInWithCredential(credential)).user?.uid;
  }

  Future<void> _signOutPrimary() async {
    final testSignOut = _signOut;
    if (testSignOut != null) return testSignOut();
    final auth = AuthService._auth;
    if (auth != null) await auth.signOut();
  }
}

typedef ReplacementJournalReader = Future<AccountTransitionJournal?> Function();
typedef DeletionJournalReader = Future<AccountDeletionJournal?> Function();
typedef DeletionStatusReceiptReader =
    Future<AccountDeletionStatusReceipt?> Function();
typedef DeletionReceiptRecoveryIdentityGuard = bool Function(String liveUid);
typedef CloudBackupDeletionJournalReader =
    Future<CloudBackupDeletionJournal?> Function();

class AccountStartupJournalResolver {
  const AccountStartupJournalResolver({
    required this.sessions,
    required this.readReplacement,
    required this.readDeletion,
    this.readDeletionStatusReceipt,
    this.isDeletionReceiptRecoveryIdentitySafe,
    this.readFeedbackActivation,
    this.readCloudBackupDeletion,
  });

  final CloudWriteSessionController sessions;
  final ReplacementJournalReader readReplacement;
  final DeletionJournalReader readDeletion;
  final DeletionStatusReceiptReader? readDeletionStatusReceipt;
  final DeletionReceiptRecoveryIdentityGuard?
  isDeletionReceiptRecoveryIdentitySafe;
  final DeletionJournalReader? readFeedbackActivation;
  final CloudBackupDeletionJournalReader? readCloudBackupDeletion;

  Future<AccountStartupRestoration> restore(String? liveUid) async {
    final normalizedUid = liveUid?.trim();
    try {
      final replacement = await readReplacement();
      final deletion = await readDeletion();
      final deletionReceipt = deletion == null
          ? null
          : await readDeletionStatusReceipt?.call();
      final feedbackActivation = await readFeedbackActivation?.call();
      final cloudBackupDeletion = await readCloudBackupDeletion?.call();
      replacement?.toJson();
      deletion?.toJson();
      feedbackActivation?.toJson();
      cloudBackupDeletion?.toJson();
      final journalCount = <Object?>[
        replacement,
        deletion ?? feedbackActivation,
        cloudBackupDeletion,
      ].where((journal) => journal != null).length;
      if (journalCount > 1) {
        return const AccountStartupRestoration.blocked();
      }
      if (replacement != null) {
        return _restoreReplacement(replacement, normalizedUid);
      }
      if (feedbackActivation != null) {
        if (feedbackActivation.operation?.phase !=
                AccountOperationPhase.completed ||
            feedbackActivation.operationId == null ||
            (deletion != null &&
                jsonEncode(deletion.toJson()) !=
                    jsonEncode(feedbackActivation.toJson()))) {
          return const AccountStartupRestoration.blocked();
        }
        return const AccountStartupRestoration.feedbackActivationPending();
      }
      if (deletion != null) {
        return _restoreDeletion(deletion, normalizedUid, deletionReceipt);
      }
      if (cloudBackupDeletion != null) {
        return _restoreCloudBackupDeletion(cloudBackupDeletion, normalizedUid);
      }
      return const AccountStartupRestoration.none();
    } catch (_) {
      return const AccountStartupRestoration.blocked();
    }
  }

  AccountStartupRestoration _restoreReplacement(
    AccountTransitionJournal journal,
    String? liveUid,
  ) {
    if (liveUid == journal.session.uid) {
      if (!_resumeExact(journal.session, liveUid!)) {
        return const AccountStartupRestoration.blocked();
      }
      return AccountStartupRestoration.replacement(journal.session);
    }
    final sourceMayBeDeleted =
        journal.replacementPhase == AccountReplacementPhase.cleanupStarting ||
        journal.replacementPhase == AccountReplacementPhase.cleanupPending ||
        journal.replacementPhase == AccountReplacementPhase.activationPending;
    final targetIsLive =
        liveUid != null && liveUid == journal.replacementTargetUid;
    if (sourceMayBeDeleted && (liveUid == null || targetIsLive)) {
      return const AccountStartupRestoration.replacement(null);
    }
    return const AccountStartupRestoration.blocked();
  }

  AccountStartupRestoration _restoreDeletion(
    AccountDeletionJournal journal,
    String? liveUid,
    AccountDeletionStatusReceipt? receipt,
  ) {
    if (_receiptMatches(journal, receipt)) {
      if (_receiptRecoveryIdentityIsSafe(journal, liveUid)) {
        // A capability-bound status read is sufficient even while the exact
        // source identity is still live. Avoid the interactive normal resume,
        // which can otherwise surface an Apple/Google OAuth prompt at startup.
        return const AccountStartupRestoration.deletionReceiptPending();
      }
      return const AccountStartupRestoration.blocked();
    }
    if (journal.operation?.phase == AccountOperationPhase.completed) {
      if (receipt == null) {
        return const AccountStartupRestoration.localCleanupPending();
      }
      return const AccountStartupRestoration.blocked();
    }
    if (liveUid == journal.session.uid) {
      if (!_resumeExact(journal.session, liveUid!)) {
        return const AccountStartupRestoration.blocked();
      }
      return AccountStartupRestoration.deletion(journal.session);
    }
    return const AccountStartupRestoration.blocked();
  }

  bool _receiptMatches(
    AccountDeletionJournal journal,
    AccountDeletionStatusReceipt? receipt,
  ) {
    if (receipt == null) return false;
    return receipt.matchesWorkflow(
          sourceUid: journal.session.uid,
          requestKey: journal.requestKey,
        ) &&
        (receipt.operationId == null ||
            journal.operationId == null ||
            receipt.operationId == journal.operationId);
  }

  bool _receiptRecoveryIdentityIsSafe(
    AccountDeletionJournal journal,
    String? liveUid,
  ) {
    if (liveUid == null || liveUid == journal.session.uid) return true;
    final completedAfterRecovery =
        journal.operation?.phase == AccountOperationPhase.completed &&
        journal.operation?.retryable == false &&
        journal.session.mode == CloudWriteMode.cleanupPending;
    return completedAfterRecovery &&
        (isDeletionReceiptRecoveryIdentitySafe?.call(liveUid) ?? false);
  }

  AccountStartupRestoration _restoreCloudBackupDeletion(
    CloudBackupDeletionJournal journal,
    String? liveUid,
  ) {
    if (liveUid == null ||
        liveUid != journal.session.uid ||
        !_resumeExact(journal.session, liveUid)) {
      return const AccountStartupRestoration.blocked();
    }
    return AccountStartupRestoration.cloudBackupDeletion(journal.session);
  }

  bool _resumeExact(CloudWriteSession session, String expectedUid) {
    final current = sessions.current;
    if (current == session) return true;
    if (current != null) return false;
    try {
      sessions.resume(session, expectedUid: expectedUid);
      return true;
    } on StateError {
      return false;
    }
  }
}

class AuthService {
  static const accountDeletionCheckpointPreferenceKey =
      Storage.accountDeletionCheckpointPreferenceKey;
  static const accountDeletionFeedbackActivationCheckpointPreferenceKey =
      Storage.accountDeletionFeedbackActivationCheckpointPreferenceKey;
  static const AccountDeletionJournalStore _accountDeletionJournalStore =
      _SharedPreferencesAccountDeletionJournalStore();
  static final AccountDeletionStatusReceiptStore
  _accountDeletionStatusReceiptStore = AccountDeletionStatusReceiptStore();
  static const AccountDeletionJournalStore
  _accountDeletionFeedbackActivationJournalStore =
      _SharedPreferencesAccountDeletionJournalStore(
        accountDeletionFeedbackActivationCheckpointPreferenceKey,
      );
  static const CloudBackupDeletionJournalStore
  _cloudBackupDeletionJournalStore =
      SharedPreferencesCloudBackupDeletionJournalStore();

  static String canonicalizeCompletedDeletionCheckpoint(String encoded) =>
      AccountDeletionJournal.canonicalizeCompleted(encoded);

  static final PushOwnershipTransitionCoordinator _pushOwnershipTransitions =
      PushOwnershipTransitionCoordinator(
        push: pushService,
        notificationsEnabled: () => Storage.notificationsEnabled,
        sessions: cloudWriteSessionController,
      );

  /// Firebase-Auth-Instanz — `null`, wenn Firebase nicht initialisiert
  /// (z.B. Web ohne Config). Wirft nie.
  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAnonymousSourceAuthFreshness _anonymousSourceAuthFreshness() {
    return FirebaseAnonymousSourceAuthFreshness(
      sessions: cloudWriteSessionController,
      currentIdentity: () {
        final user = current;
        return (uid: user?.uid, isAnonymous: user?.isAnonymous ?? false);
      },
      refreshIdToken:
          ({required String expectedUid, required bool forceRefresh}) async {
            final user = current;
            if (user == null || user.uid != expectedUid || !user.isAnonymous) {
              throw const AccountOperationFailure(
                AccountOperationFailureCode.authenticationRequired,
                retryable: false,
              );
            }
            if ((await user.getIdToken(forceRefresh))?.isEmpty ?? true) {
              throw const AccountOperationFailure(
                AccountOperationFailureCode.authenticationRequired,
                retryable: false,
              );
            }
          },
    );
  }

  static FreshAnonymousAccountOperationGateway _anonymousSourceOperationGateway(
    AccountOperationGateway gateway,
  ) {
    return FreshAnonymousAccountOperationGateway(
      gateway: gateway,
      freshness: _anonymousSourceAuthFreshness(),
    );
  }

  static ReplacementAccountOperations replacementAccountOperations() {
    final gateway = AccountOperationClient.firebase();
    return CallableReplacementAccountOperations(
      source: _anonymousSourceOperationGateway(gateway),
    );
  }

  /// Aktueller User — null-safe, wirft nie (Web-Crash-Schutz).
  static User? get current {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isSignedIn => current != null;
  static bool get isAnonymous => current?.isAnonymous ?? true;

  static AuthProviderState get providerState {
    try {
      return AuthProviderState.fromProviderIds(
        current?.providerData.map((provider) => provider.providerId) ??
            const <String>[],
      );
    } catch (_) {
      return const AuthProviderState(
        isGoogleLinked: false,
        isAppleLinked: false,
      );
    }
  }

  static bool get isGoogleLinked => providerState.isGoogleLinked;
  static bool get isAppleLinked => providerState.isAppleLinked;
  static bool get isDurableLinked => providerState.isDurable;

  /// UID eligible for learning-progress backup, or `null` for anonymous-only
  /// and unavailable identities.
  static String? get cloudBackupUid {
    try {
      final user = current;
      return CloudBackupAccessPolicy.uidFor(
        uid: user?.uid,
        providerIds:
            user?.providerData.map((provider) => provider.providerId) ??
            const <String>[],
      );
    } catch (_) {
      return null;
    }
  }

  /// Apple Sign-In ist nur auf Apple-Plattformen verfügbar (App-Store-
  /// Richtlinie 4.8 verlangt es, sobald Google-Login angeboten wird).
  static bool get appleSignInAvailable {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static String? get displayName => current?.displayName ?? current?.email;
  static String? get photoUrl => current?.photoURL;
  static AuthAccountSnapshot get accountSnapshot => AuthAccountSnapshot(
    providers: providerState,
    displayName: displayName,
    photoUrl: photoUrl,
  );

  /// In `main()` aufrufen — sorgt dafür, dass IMMER ein User existiert.
  /// Bricht still ab, wenn Firebase nicht verfügbar ist (Web ohne Config).
  static Future<void> ensureSignedIn() async {
    final auth = _auth;
    if (auth == null) {
      return;
    }
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  static void synchronizeReadyCloudWriteSession(String uid) {
    CloudWriteSessionSynchronizer(
      cloudWriteSessionController,
    ).synchronizeReady(uid);
  }

  static const FirstDurableLinkBackfillJournalStore
  _firstDurableLinkBackfillJournalStore =
      SharedPreferencesFirstDurableLinkBackfillJournalStore();

  static final FirstDurableLinkBackfill _firstDurableLinkBackfill =
      FirstDurableLinkBackfill(
        sessions: cloudWriteSessionController,
        currentUid: () => cloudBackupUid,
        hasBlockingAccountJournal: _hasAnyOtherDurableAccountJournal,
        journalStore: _firstDurableLinkBackfillJournalStore,
        uploadBookshelf: (session, {required operationId}) =>
            BookshelfService.uploadLocalGenerationForFirstDurableLink(
              session: session,
              sessions: cloudWriteSessionController,
              operationId: operationId,
            ),
        uploadPackProgress: (session, {required operationId}) =>
            PackProgressService.uploadLocalProgressForFirstDurableLink(
              session: session,
              sessions: cloudWriteSessionController,
            ),
      );

  static final FirstDurableLinkActivation _firstDurableLinkActivation =
      FirstDurableLinkActivation(
        sessions: cloudWriteSessionController,
        backfill: _firstDurableLinkBackfill,
      );

  static Future<bool> _hasAnyOtherDurableAccountJournal() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      return preferences.containsKey(AccountTransitionJournal.storageKey) ||
          preferences.containsKey(accountDeletionCheckpointPreferenceKey) ||
          preferences.containsKey(
            accountDeletionFeedbackActivationCheckpointPreferenceKey,
          ) ||
          preferences.containsKey(
            Storage.cloudBackupDeletionJournalPreferenceKey,
          );
    } catch (_) {
      return true;
    }
  }

  static Future<User?> _activateSignedInUser(
    User? user, {
    required String sourceUid,
  }) async {
    final uid = user?.uid;
    if (uid != null) {
      synchronizeReadyCloudWriteSession(uid);
      await _firstDurableLinkActivation.activate(
        sourceUid: sourceUid,
        linkedUid: uid,
        linkedIsAnonymous: user!.isAnonymous,
      );
    }
    return user;
  }

  /// Resumes only a receipt owned by the current durable Firebase account.
  ///
  /// Startup enters the shared account admission lane before calling this.
  /// The initial link path already owns that lane, so it calls the backfill
  /// core directly through [_firstDurableLinkActivation] instead.
  static Future<void> resumePendingFirstDurableLinkBackfill() async {
    final expectedUid = cloudBackupUid;
    if (expectedUid == null) return;
    await runDurableAccountAdmission<CloudWriteResult>(
      onAdmitted: () async {
        if (cloudBackupUid != expectedUid) return CloudWriteResult.stale;
        return _firstDurableLinkBackfill.resume(expectedUid: expectedUid);
      },
      onBlocked: () async => CloudWriteResult.blocked,
    );
  }

  /// Restores durable fencing only after [expectedUid] has been obtained from
  /// the live Firebase Auth user. Journal metadata never supplies that value.
  static Future<CloudWriteSession?> restoreCloudWriteSession(
    String expectedUid,
  ) async {
    final liveUid = current?.uid;
    if (liveUid == null || liveUid != expectedUid) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.permissionDenied,
        retryable: false,
      );
    }
    final journal = await _accountDeletionJournalStore.read();
    if (journal == null) {
      return null;
    }
    final currentSession = cloudWriteSessionController.current;
    if (currentSession == journal.session) {
      return currentSession;
    }
    if (currentSession != null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    return cloudWriteSessionController.resume(
      journal.session,
      expectedUid: expectedUid,
    );
  }

  static Future<AccountStartupRestoration> restorePendingAccountState(
    String? liveUid,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final replacementStore = SharedPreferencesReplacementTransitionJournalStore(
      preferences,
    );
    return AccountStartupJournalResolver(
      sessions: cloudWriteSessionController,
      readReplacement: replacementStore.read,
      readDeletion: _accountDeletionJournalStore.read,
      readDeletionStatusReceipt: _accountDeletionStatusReceiptStore.read,
      isDeletionReceiptRecoveryIdentitySafe: (liveUid) {
        final live = current;
        return live != null && live.uid == liveUid && live.isAnonymous;
      },
      readFeedbackActivation:
          _accountDeletionFeedbackActivationJournalStore.read,
      readCloudBackupDeletion: _cloudBackupDeletionJournalStore.read,
    ).restore(liveUid);
  }

  /// Anonymen User mit Google-Account verlinken.
  /// Existing-account collisions preserve the primary anonymous session and
  /// require explicit confirmation through [AccountTransitionCoordinator].
  static Future<User?> linkWithGoogle() {
    return _runDurableIdentityMutation(() async {
      final auth = _auth;
      // ⚠️ Firebase 미초기화는 **사용자 취소가 아니다**. 예전에는 둘 다 null 을
      // 반환해 UI 가 조용히 취소로 처리했고, 사용자에겐 반응 없는 버튼만 남았다.
      if (auth == null) {
        throw const AccountLinkUnavailable();
      }

      final googleUser = await GoogleSignIn().signIn();
      // 여기 null 은 진짜 사용자 취소다 (계정 선택 시트를 닫음).
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = auth.currentUser;
      if (user != null && user.isAnonymous) {
        final sourceUid = user.uid;
        final attempt = await attemptAnonymousCredentialLink<User?>(
          provider: AccountLinkProvider.google,
          sourceUid: sourceUid,
          currentUid: () => auth.currentUser?.uid,
          linkCredential: () async {
            final result = await user.linkWithCredential(credential);
            return result.user;
          },
        );
        if (attempt is ExistingAccountLinkConflict) {
          throw attempt;
        }
        return _activateSignedInUser(
          (attempt as AnonymousCredentialLinked<User?>).value,
          sourceUid: sourceUid,
        );
      }
      throw const DurableAccountTransitionNotSupported();
    });
  }

  /// Anonymen User mit Apple-Account verlinken (iOS — App-Store-Pflicht 4.8).
  /// Existing-account collisions never activate the target implicitly.
  static Future<User?> linkWithApple() {
    return _runDurableIdentityMutation(() async {
      final auth = _auth;
      // Google 과 같은 이유 — 시스템 불가와 사용자 취소를 구분한다.
      if (auth == null) {
        throw const AccountLinkUnavailable();
      }

      final rawNonce = _generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce),
      );
      final credential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final user = auth.currentUser;
      if (user != null && user.isAnonymous) {
        final sourceUid = user.uid;
        final attempt = await attemptAnonymousCredentialLink<User?>(
          provider: AccountLinkProvider.apple,
          sourceUid: sourceUid,
          currentUid: () => auth.currentUser?.uid,
          linkCredential: () async {
            final result = await user.linkWithCredential(credential);
            return result.user;
          },
        );
        if (attempt is ExistingAccountLinkConflict) {
          throw attempt;
        }
        final linked = (attempt as AnonymousCredentialLinked<User?>).value;
        await _maybeSetAppleName(linked, appleCredential);
        return _activateSignedInUser(linked, sourceUid: sourceUid);
      }
      throw const DurableAccountTransitionNotSupported();
    });
  }

  /// Apple liefert den Namen nur beim allerersten Login — übernehmen, wenn
  /// vorhanden und noch kein displayName gesetzt ist.
  static Future<void> _maybeSetAppleName(
    User? user,
    AuthorizationCredentialAppleID c,
  ) async {
    if (user == null) return;
    if (user.displayName != null && user.displayName!.isNotEmpty) return;
    final name = [
      c.givenName,
      c.familyName,
    ].where((e) => e != null && e.isNotEmpty).join(' ').trim();
    if (name.isEmpty) return;
    try {
      await user.updateDisplayName(name);
    } catch (_) {
      // best-effort — Name ist optional.
    }
  }

  static CloudBackupDeletionCoordinator? _cloudBackupDeletion;
  static Future<void> Function()? _deleteAccountForTesting;
  static final CompletedDeletionFeedbackSerialGate
  _completedFeedbackFinalizationGate = CompletedDeletionFeedbackSerialGate();

  static CloudBackupDeletionCoordinator get _cloudBackupDeletionCoordinator =>
      _cloudBackupDeletion ??= CloudBackupDeletionCoordinator(
        sessions: cloudWriteSessionController,
        currentUid: () => cloudBackupUid,
        journalStore: _cloudBackupDeletionJournalStore,
        firstLinkJournalStore: _firstDurableLinkBackfillJournalStore,
        gateway: FirebaseCloudBackupDeletionGateway.production(
          currentUid: () => cloudBackupUid,
        ),
      );

  static ValueListenable<CloudBackupDeletionJournalState>
  get cloudBackupDeletionJournalState =>
      _cloudBackupDeletionCoordinator.journalState;

  // Kept as a binary projection for internal callers that only need an
  // action lock. Both loading and an unresolved journal project to `true`.
  static ValueListenable<bool> get cloudBackupDeletionPending =>
      _cloudBackupDeletionCoordinator.pending;

  /// Why the last remote cloud-deletion attempt failed (code-derived only).
  static ValueListenable<AccountFailureReason?>
  get cloudBackupDeletionLastFailureReason =>
      _cloudBackupDeletionCoordinator.lastFailureReason;

  static Future<CloudBackupDeletionJournalState>
  refreshCloudBackupDeletionJournalState() =>
      _cloudBackupDeletionCoordinator.refreshJournalState();

  static Future<bool> refreshCloudBackupDeletionPending() =>
      _cloudBackupDeletionCoordinator.refreshPending();

  /// Admits a cloud-data service operation only after a fresh durable read of
  /// the backup-deletion journal. The operation remains in the same serial
  /// lane as deletion recovery and identity changes.
  static Future<T> runCloudBackupDeletionAdmission<T>({
    required Future<T> Function() onAdmitted,
    required Future<T> Function() onBlocked,
  }) {
    return _cloudBackupDeletionCoordinator.runWithClearJournalAdmission(
      onAdmitted: onAdmitted,
      onBlocked: onBlocked,
    );
  }

  /// Admits a new account-affecting operation only when every durable account
  /// journal is absent. The cloud backup deletion check and this fresh
  /// replacement/deletion check run in the cloud coordinator's shared serial
  /// lane, so public identity mutations cannot begin beside a retry journal.
  ///
  /// Account-deletion recovery is the one exception: its own durable
  /// checkpoint must stay admissible so [AccountDeletionRemoteGate] can
  /// resume or recover that exact operation. Replacement resume/cancel has
  /// the equivalent exception for its own transition journal.
  static Future<T> runDurableAccountAdmission<T>({
    required Future<T> Function() onAdmitted,
    required Future<T> Function() onBlocked,
    bool allowAccountDeletionCheckpoint = false,
    bool allowReplacementTransitionJournal = false,
    bool allowFeedbackActivationCheckpoint = false,
  }) {
    return runCloudBackupDeletionAdmission<T>(
      onAdmitted: () async {
        final clear = await _otherDurableAccountJournalsAreClear(
          allowAccountDeletionCheckpoint: allowAccountDeletionCheckpoint,
          allowReplacementTransitionJournal: allowReplacementTransitionJournal,
          allowFeedbackActivationCheckpoint: allowFeedbackActivationCheckpoint,
        );
        return clear ? onAdmitted() : onBlocked();
      },
      onBlocked: onBlocked,
    );
  }

  /// Admits the feedback handoff only after the primary deletion,
  /// replacement, and cloud-deletion journals are gone. The dedicated
  /// activation marker remains durable during this narrow handoff.
  static Future<T> runCompletedDeletionFeedbackActivationAdmission<T>({
    required String deletedUid,
    required Future<T> Function() onAdmitted,
    required Future<T> Function() onBlocked,
  }) {
    return runCloudBackupDeletionAdmission<T>(
      onAdmitted: () async {
        try {
          final normalizedDeletedUid = deletedUid.trim();
          if (normalizedDeletedUid.isEmpty) return onBlocked();
          final completed = await _accountDeletionJournalStore.read();
          final activation =
              await _accountDeletionFeedbackActivationJournalStore.read();
          if (completed != null ||
              activation?.operation?.phase != AccountOperationPhase.completed ||
              activation?.operationId == null ||
              activation?.session.uid != normalizedDeletedUid) {
            return onBlocked();
          }
          final clear = await _otherDurableAccountJournalsAreClear(
            allowAccountDeletionCheckpoint: false,
            allowReplacementTransitionJournal: false,
            allowFeedbackActivationCheckpoint: true,
          );
          return clear ? onAdmitted() : onBlocked();
        } catch (_) {
          return onBlocked();
        }
      },
      onBlocked: onBlocked,
    );
  }

  static Future<bool> _otherDurableAccountJournalsAreClear({
    required bool allowAccountDeletionCheckpoint,
    required bool allowReplacementTransitionJournal,
    bool allowFeedbackActivationCheckpoint = false,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      if (!allowReplacementTransitionJournal &&
          preferences.containsKey(AccountTransitionJournal.storageKey)) {
        return false;
      }
      return (allowAccountDeletionCheckpoint ||
              !preferences.containsKey(
                accountDeletionCheckpointPreferenceKey,
              )) &&
          (allowFeedbackActivationCheckpoint ||
              !preferences.containsKey(
                accountDeletionFeedbackActivationCheckpointPreferenceKey,
              ));
    } catch (_) {
      return false;
    }
  }

  static Future<T> _runDurableIdentityMutation<T>(
    Future<T> Function() mutation,
  ) {
    return runDurableAccountAdmission<T>(
      onAdmitted: mutation,
      onBlocked: () => Future<T>.error(
        const CloudBackupDeletionIdentityChangeBlockedException(),
      ),
    );
  }

  @visibleForTesting
  static void overrideCloudBackupDeletionCoordinatorForTesting(
    CloudBackupDeletionCoordinator coordinator,
  ) {
    _cloudBackupDeletion = coordinator;
  }

  @visibleForTesting
  static void overrideDeleteAccountForTesting(
    Future<void> Function()? operation,
  ) {
    _deleteAccountForTesting = operation;
  }

  @visibleForTesting
  static void resetCloudBackupDeletionForTesting() {
    _cloudBackupDeletion = null;
    _deleteAccountForTesting = null;
  }

  /// Requests bounded server-owned backup removal. Local data stays untouched.
  ///
  /// A persisted cloud-deletion journal is still allowed to resume, but a new
  /// deletion cannot begin while replacement or account-deletion recovery has
  /// an outstanding durable checkpoint.
  static Future<CloudWriteResult> deleteCloudData() =>
      _cloudBackupDeletionCoordinator.run(
        canStart: () => _otherDurableAccountJournalsAreClear(
          allowAccountDeletionCheckpoint: false,
          allowReplacementTransitionJournal: false,
        ),
      );

  /// Resumes a persisted cloud-backup deletion journal without ever being
  /// able to start a new deletion (canStart fails closed when no journal
  /// exists). Safe as an automatic startup step.
  static Future<CloudWriteResult> resumePendingCloudBackupDeletion() =>
      _cloudBackupDeletionCoordinator.run(canStart: () async => false);

  /// Requests server-owned account deletion and polls its authoritative state.
  ///
  /// Caller clears local device data only after this completes.
  static Future<void> deleteAccount({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) {
    return runDurableAccountAdmission<void>(
      allowAccountDeletionCheckpoint: true,
      allowFeedbackActivationCheckpoint: true,
      onAdmitted: () =>
          _deleteAccountAfterCloudBackupAdmission(closeFeedback: closeFeedback),
      onBlocked: () => Future<void>.error(
        const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        ),
      ),
    );
  }

  static Future<void> _deleteAccountAfterCloudBackupAdmission({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) {
    final override = _deleteAccountForTesting;
    if (override != null) return override();
    return AccountDeletionRemoteGate(
      readCheckpoint: _readPrimaryDeletionCheckpointForRemoteGate,
      startOrResumeRemote: () =>
          _startOrResumeRemoteAccountDeletion(closeFeedback: closeFeedback),
      recoverCompleted: (checkpoint) =>
          _recoverCompletedAccountDeletionAndReceipt(
            checkpoint,
            closeFeedback: closeFeedback,
          ),
      preflight: _preflightCompletedAccountDeletionRecovery,
      // Receipt-aware recovery owns its identity snapshot across feedback,
      // status verification, ACK, and secure capability removal.
      closeFeedback: _noopAccountDeletionFeedbackCloser,
    ).run();
  }

  static Future<void> _startOrResumeRemoteAccountDeletion({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) async {
    final user = current;
    if (user == null) {
      throw StateError('The Firebase account is unavailable.');
    }

    final client = AccountOperationClient.firebase();
    await AccountDeletionCoordinator(
      operations: _FirebaseAccountDeletionOperations(
        user: user,
        client: client,
        anonymousSource: _anonymousSourceOperationGateway(client),
        sessions: cloudWriteSessionController,
        journalStore: _accountDeletionJournalStore,
        receiptStore: _accountDeletionStatusReceiptStore,
      ),
      ownershipTransitions: _pushOwnershipTransitions,
      sessions: cloudWriteSessionController,
      closeFeedback: closeFeedback,
    ).deleteAccount();
  }

  static Future<void> _recoverCompletedAccountDeletion(
    AccountDeletionJournal checkpoint,
  ) async {
    final auth = _auth;
    final live = current;
    await recoverCompletedDeletionIdentity(
      checkpoint: checkpoint,
      currentUid: live?.uid,
      currentIsAnonymous: live?.isAnonymous ?? false,
      cleanupGoogleProvider: () async {
        await GoogleSignIn().signOut();
      },
      recoverFirebaseIdentity: () async {
        if (auth == null) {
          throw const AccountOperationFailure(
            AccountOperationFailureCode.authenticationRequired,
            retryable: false,
          );
        }
        await auth.signOut();
        await ensureSignedIn();
      },
    );
  }

  static Future<void> _recoverCompletedAccountDeletionAndReceipt(
    AccountDeletionJournal checkpoint, {
    required AccountDeletionFeedbackCloser closeFeedback,
  }) async {
    final receipt = await _accountDeletionStatusReceiptStore.read();
    if (receipt == null) {
      await closeFeedback();
      await _recoverCompletedAccountDeletion(checkpoint);
      return;
    }
    final client = AccountOperationClient.firebase();
    final status = await AccountDeletionReceiptRecoveryCoordinator(
      journalStore: _accountDeletionJournalStore,
      receiptStore: _accountDeletionStatusReceiptStore,
      sessions: cloudWriteSessionController,
      currentIdentity: () =>
          (uid: current?.uid, isAnonymous: current?.isAnonymous ?? false),
      readStatus: client.getAccountDeletionStatusByReceipt,
      acknowledge: client.acknowledgeAccountDeletionStatusReceipt,
      closeFeedback: closeFeedback,
      recoverCompleted: _recoverCompletedAccountDeletion,
    ).resume();
    if (status != AccountDeletionReceiptRecoveryStatus.completed) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.unavailable,
        retryable: true,
      );
    }
  }

  static void _preflightCompletedAccountDeletionRecovery(
    AccountDeletionJournal checkpoint,
  ) {
    final live = current;
    assertCompletedDeletionRecoveryIdentitySafe(
      checkpoint: checkpoint,
      currentUid: live?.uid,
      currentIsAnonymous: live?.isAnonymous ?? false,
    );
  }

  static Future<void> completeLocalAccountDeletionCleanup({
    AccountDeletionFeedbackActivator? activateFeedback,
  }) => _completedFeedbackFinalizationGate.run(
    () => CompletedDeletionFeedbackActivationCoordinator(
      completedStore: _accountDeletionJournalStore,
      activationStore: _accountDeletionFeedbackActivationJournalStore,
      activateFeedback: activateFeedback ?? (_) async => true,
    ).run(),
  );

  /// Finishes only the post-cleanup feedback handoff left by a crash or an
  /// earlier activation failure. This path never repeats remote deletion or
  /// destructive local account cleanup.
  static Future<bool> finalizePendingAccountDeletionFeedback({
    required AccountDeletionFeedbackCloser closeFeedback,
    required AccountDeletionFeedbackActivator activateFeedback,
  }) {
    return _completedFeedbackFinalizationGate.run(
      () => _finalizePendingAccountDeletionFeedback(
        closeFeedback: closeFeedback,
        activateFeedback: activateFeedback,
      ),
    );
  }

  static Future<bool> _finalizePendingAccountDeletionFeedback({
    required AccountDeletionFeedbackCloser closeFeedback,
    required AccountDeletionFeedbackActivator activateFeedback,
  }) {
    return CompletedDeletionFeedbackFinalizer(
      prepareWithinAdmission: () => runDurableAccountAdmission<bool>(
        allowAccountDeletionCheckpoint: true,
        allowFeedbackActivationCheckpoint: true,
        onAdmitted: () async {
          final activation =
              await _accountDeletionFeedbackActivationJournalStore.read();
          if (activation == null) {
            return false;
          }
          final completed = await _accountDeletionJournalStore.read();
          if (activation.operation?.phase != AccountOperationPhase.completed ||
              activation.operationId == null ||
              (completed != null &&
                  jsonEncode(completed.toJson()) !=
                      jsonEncode(activation.toJson()))) {
            throw const AccountOperationFailure(
              AccountOperationFailureCode.blocked,
              retryable: false,
            );
          }
          final live = current;
          assertCompletedDeletionFeedbackActivationIdentitySafe(
            checkpoint: activation,
            currentUid: live?.uid,
            currentIsAnonymous: live?.isAnonymous ?? false,
          );
          return true;
        },
        onBlocked: () => Future<bool>.error(
          const AccountOperationFailure(
            AccountOperationFailureCode.blocked,
            retryable: false,
          ),
        ),
      ),
      closeAfterAdmission: closeFeedback,
      finalizeAfterAdmission: () =>
          CompletedDeletionFeedbackActivationCoordinator(
            completedStore: _accountDeletionJournalStore,
            activationStore: _accountDeletionFeedbackActivationJournalStore,
            activateFeedback: activateFeedback,
          ).run(),
    ).run();
  }

  static Future<AccountDeletionJournal?>
  _readPrimaryDeletionCheckpointForRemoteGate() async {
    final activation = await _accountDeletionFeedbackActivationJournalStore
        .read();
    if (activation != null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    return _accountDeletionJournalStore.read();
  }

  static Future<AccountDeletionJournal?> readAccountDeletionCheckpoint() async {
    final completed = await _accountDeletionJournalStore.read();
    final activation = await _accountDeletionFeedbackActivationJournalStore
        .read();
    if (activation != null &&
        (activation.operation?.phase != AccountOperationPhase.completed ||
            activation.operationId == null)) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    if (completed != null &&
        activation != null &&
        jsonEncode(completed.toJson()) != jsonEncode(activation.toJson())) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.blocked,
        retryable: false,
      );
    }
    return completed ?? activation;
  }

  /// Continues the exact durable server operation restored at startup.
  static Future<void> resumePendingAccountDeletion({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) {
    return runDurableAccountAdmission<void>(
      allowAccountDeletionCheckpoint: true,
      onAdmitted: () => _resumePendingAccountDeletionAfterCloudBackupAdmission(
        closeFeedback: closeFeedback,
      ),
      onBlocked: () => Future<void>.error(
        const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        ),
      ),
    );
  }

  /// Reads only a capability-bound deletion status after source Auth removal.
  /// It never creates, advances, or cancels a remote account operation.
  static Future<void> resumePendingAccountDeletionByReceipt({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) {
    return runDurableAccountAdmission<void>(
      allowAccountDeletionCheckpoint: true,
      onAdmitted: () async {
        final client = AccountOperationClient.firebase();
        await AccountDeletionReceiptRecoveryCoordinator(
          journalStore: _accountDeletionJournalStore,
          receiptStore: _accountDeletionStatusReceiptStore,
          sessions: cloudWriteSessionController,
          currentIdentity: () =>
              (uid: current?.uid, isAnonymous: current?.isAnonymous ?? false),
          readStatus: client.getAccountDeletionStatusByReceipt,
          acknowledge: client.acknowledgeAccountDeletionStatusReceipt,
          closeFeedback: closeFeedback,
          recoverCompleted: _recoverCompletedAccountDeletion,
        ).resume();
      },
      onBlocked: () => Future<void>.error(
        const AccountOperationFailure(
          AccountOperationFailureCode.blocked,
          retryable: false,
        ),
      ),
    );
  }

  static Future<void> _resumePendingAccountDeletionAfterCloudBackupAdmission({
    required AccountDeletionFeedbackCloser closeFeedback,
  }) async {
    final user = current;
    if (user == null) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.authenticationRequired,
        retryable: false,
      );
    }
    final client = AccountOperationClient.firebase();
    await AccountDeletionCoordinator(
      operations: _FirebaseAccountDeletionOperations(
        user: user,
        client: client,
        anonymousSource: _anonymousSourceOperationGateway(client),
        sessions: cloudWriteSessionController,
        journalStore: _accountDeletionJournalStore,
        receiptStore: _accountDeletionStatusReceiptStore,
      ),
      ownershipTransitions: _pushOwnershipTransitions,
      sessions: cloudWriteSessionController,
      closeFeedback: closeFeedback,
    ).resumePendingDeletion();
  }

  /// Aus Google-Account ausloggen → wieder anonym.
  static Future<void> signOut() {
    return _runDurableIdentityMutation(() async {
      final auth = _auth;
      final oldUid = auth?.currentUser?.uid;
      if (auth == null || oldUid == null) {
        return;
      }
      await _pushOwnershipTransitions.run(
        oldUid: oldUid,
        transition: () async {
          await GoogleSignIn().signOut();
          await auth.signOut();
          await ensureSignedIn(); // wieder anonym
        },
      );
    });
  }

  static Future<void> _reauthenticateWithGoogle(User user) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'reauth-cancelled',
        message: 'Google reauthentication was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  static Future<AuthCredential> _acquireFreshProviderCredential(
    AccountLinkProvider provider,
  ) async {
    switch (provider) {
      case AccountLinkProvider.google:
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'target-verification-cancelled',
            message: 'Target verification was cancelled.',
          );
        }
        final googleAuth = await googleUser.authentication;
        return GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      case AccountLinkProvider.apple:
        final rawNonce = _generateNonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: const [AppleIDAuthorizationScopes.email],
          nonce: _sha256(rawNonce),
        );
        return OAuthProvider(
          'apple.com',
        ).credential(idToken: apple.identityToken, rawNonce: rawNonce);
    }
  }

  /// Reuses only the account selected by the immediately preceding isolated
  /// Google verification. A missing/expired cached session is a resumable
  /// activation failure; it must never open a second interactive chooser.
  static Future<AuthCredential?>
  _acquireGoogleActivationCredentialSilently() async {
    final googleUser = await GoogleSignIn().signInSilently(
      suppressErrors: false,
      reAuthenticate: false,
    );
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  /// Apple credentials are intentionally single-use and nonce-bound, so
  /// activation keeps the existing fresh Sign in with Apple prompt.
  static Future<AuthCredential> _acquireAppleActivationCredentialExplicitly() {
    return _acquireFreshProviderCredential(AccountLinkProvider.apple);
  }

  static Future<String?> _reauthenticateWithApple(User user) async {
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
      nonce: _sha256(rawNonce),
    );
    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    await user.reauthenticateWithCredential(credential);
    final authorizationCode = appleCredential.authorizationCode.trim();
    return authorizationCode.isEmpty ? null : authorizationCode;
  }

  /// Krypto-sicherer Nonce für Apple Sign-In (Replay-Schutz). Roh-Nonce geht
  /// an Firebase (`rawNonce`), der SHA-256-Hash an Apple (`nonce`).
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
