import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pack_progress_service.dart';
import 'account_operation_client.dart';
import 'account_reconciliation.dart';
import 'account_transition_journal.dart';
import 'cloud_write_session.dart';

enum AccountLinkProvider { google, apple }

sealed class AnonymousCredentialLinkResult {
  const AnonymousCredentialLinkResult();
}

@immutable
class AnonymousCredentialLinked<T> extends AnonymousCredentialLinkResult {
  const AnonymousCredentialLinked(this.value);

  final T value;
}

@immutable
class ExistingAccountLinkConflict extends AnonymousCredentialLinkResult
    implements Exception {
  const ExistingAccountLinkConflict(this.provider);

  final AccountLinkProvider provider;

  @override
  String toString() =>
      'The ${provider.name} credential belongs to an existing account.';
}

class DurableAccountTransitionNotSupported implements Exception {
  const DurableAccountTransitionNotSupported();

  @override
  String toString() => 'Switching between connected accounts is not supported.';
}

class AccountLinkSafetyFailure implements Exception {
  const AccountLinkSafetyFailure();

  @override
  String toString() => 'The authenticated account changed unexpectedly.';
}

/// Attempts only a Firebase credential link. A collision is data, not a
/// request to sign the primary FirebaseAuth instance into another account.
Future<AnonymousCredentialLinkResult> attemptAnonymousCredentialLink<T>({
  required AccountLinkProvider provider,
  required String sourceUid,
  bool sourceIsAnonymous = true,
  required String? Function() currentUid,
  required Future<T> Function() linkCredential,
}) {
  if (!sourceIsAnonymous) {
    throw const DurableAccountTransitionNotSupported();
  }
  if (sourceUid.trim().isEmpty || currentUid() != sourceUid) {
    throw const AccountLinkSafetyFailure();
  }
  return _attemptAnonymousCredentialLink(
    provider: provider,
    sourceUid: sourceUid,
    currentUid: currentUid,
    linkCredential: linkCredential,
  );
}

Future<AnonymousCredentialLinkResult> _attemptAnonymousCredentialLink<T>({
  required AccountLinkProvider provider,
  required String sourceUid,
  required String? Function() currentUid,
  required Future<T> Function() linkCredential,
}) async {
  try {
    final value = await linkCredential();
    if (currentUid() != sourceUid) {
      throw const AccountLinkSafetyFailure();
    }
    return AnonymousCredentialLinked<T>(value);
  } on FirebaseAuthException catch (error) {
    if (error.code != 'credential-already-in-use' &&
        error.code != 'email-already-in-use' &&
        error.code != 'account-exists-with-different-credential') {
      rethrow;
    }
    if (currentUid() != sourceUid) {
      throw const AccountLinkSafetyFailure();
    }
    return ExistingAccountLinkConflict(provider);
  }
}

abstract interface class AccountTransitionIdentity {
  String? get currentUid;
  bool get currentIsAnonymous;

  /// Acquires a fresh provider credential and activates it in the primary auth
  /// context. It is called only after source cleanup is terminal-successful.
  Future<void> activateTarget(
    AccountLinkProvider provider, {
    required String expectedTargetUid,
    required CloudWriteSession expectedSourceSession,
    required CloudWriteSessionController sessions,
    required bool allowMissingSource,
  });
}

abstract interface class VerifiedTargetContext {
  String get uid;
  bool get isAnonymous;
  Future<void> dispose();
}

abstract interface class AccountOperationTargetContext
    implements VerifiedTargetContext {
  AccountOperationGateway get operationGateway;
}

abstract interface class AccountReconciliationTargetContext
    implements VerifiedTargetContext {
  FirebaseAccountReconciliationRemote reconciliationRemote({
    required String fenceUid,
  });
}

class FirebaseTargetReconciliationFactory {
  const FirebaseTargetReconciliationFactory._();

  static AccountReconciliationCoordinator create({
    required VerifiedTargetContext target,
    required CloudWriteSession sourceSession,
    required CloudWriteSessionController sessions,
    required AccountTransitionJournalStore journalStore,
    AccountLocalReader? loadLocal,
    AccountLocalWriter? writeLocal,
  }) {
    if (target is! AccountReconciliationTargetContext ||
        sourceSession.mode != CloudWriteMode.reconciling) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.authenticationRequired,
        retryable: false,
      );
    }
    final adapter = FirebaseAccountReconciliationAdapter(
      uid: target.uid,
      fenceUid: sourceSession.uid,
      session: sourceSession,
      sessions: sessions,
      remote: target.reconciliationRemote(fenceUid: sourceSession.uid),
    );
    return adapter.coordinator(
      journalStore: journalStore,
      loadLocal: loadLocal,
      writeLocal: writeLocal,
    );
  }
}

abstract interface class IsolatedTargetVerifier {
  /// Acquires a fresh provider credential inside a temporary auth context.
  /// Implementations must not authenticate the primary FirebaseAuth instance.
  Future<VerifiedTargetContext> verify(AccountLinkProvider provider);
}

abstract interface class ReplacementAccountOperations {
  Future<AccountOperationResult> prepare({
    required String targetUid,
    required String requestKey,
  });

  Future<AccountOperationResult> attachTarget({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  });

  Future<AccountOperationResult> commitReconciliation({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  });

  Future<AccountOperationResult> startSourceCleanup({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  });

  Future<AccountOperationResult> getStatus({
    required VerifiedTargetContext target,
    required String operationId,
  });
}

class CallableReplacementAccountOperations
    implements ReplacementAccountOperations {
  const CallableReplacementAccountOperations({required this.source});

  final AccountOperationGateway source;

  AccountOperationGateway _target(VerifiedTargetContext target) {
    if (target is! AccountOperationTargetContext) {
      throw const AccountOperationFailure(
        AccountOperationFailureCode.authenticationRequired,
        retryable: false,
      );
    }
    return target.operationGateway;
  }

  @override
  Future<AccountOperationResult> prepare({
    required String targetUid,
    required String requestKey,
  }) {
    return source.prepareAnonymousReplacement(
      AnonymousReplacementPrepareRequest(
        targetUid: targetUid,
        requestKey: requestKey,
      ),
    );
  }

  @override
  Future<AccountOperationResult> attachTarget({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) {
    return _target(target).attachReplacementTarget(
      ReplacementAdvanceRequest(
        operationId: operationId,
        expectedVersion: expectedVersion,
      ),
    );
  }

  @override
  Future<AccountOperationResult> commitReconciliation({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) {
    return _target(target).commitReplacementReconciliation(
      ReplacementAdvanceRequest(
        operationId: operationId,
        expectedVersion: expectedVersion,
      ),
    );
  }

  @override
  Future<AccountOperationResult> startSourceCleanup({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) {
    return _target(target).startSourceCleanup(
      ReplacementAdvanceRequest(
        operationId: operationId,
        expectedVersion: expectedVersion,
      ),
    );
  }

  @override
  Future<AccountOperationResult> getStatus({
    required VerifiedTargetContext target,
    required String operationId,
  }) {
    return _target(target).getAccountOperation(
      AccountOperationStatusRequest(operationId: operationId),
    );
  }
}

abstract interface class ReplacementTransitionJournalStore
    implements AccountTransitionJournalStore {
  Future<bool> deleteIfCurrent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  });
}

class SharedPreferencesReplacementTransitionJournalStore
    implements
        ReplacementTransitionJournalStore,
        AccountTransitionJournalStore {
  SharedPreferencesReplacementTransitionJournalStore(
    SharedPreferences preferences,
  ) : _store = SharedPreferencesAccountTransitionJournalStore(preferences);

  final SharedPreferencesAccountTransitionJournalStore _store;

  @override
  Future<AccountTransitionJournal?> read() => _store.read();

  @override
  Future<void> write(AccountTransitionJournal journal) => _store.write(journal);

  @override
  Future<bool> deleteIfCurrent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) => _store.deleteIfCurrent(expected: expected, isCurrent: isCurrent);

  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) => _store.restoreIfAbsent(expected: expected, isCurrent: isCurrent);
}

typedef ReplacementReconciler =
    Future<AccountReconciliationResult> Function({
      required VerifiedTargetContext target,
      required CloudWriteSession session,
      required String operationId,
      required Map<String, PackCatalogEntry> catalog,
    });

enum AccountTransitionStatus {
  completed,
  targetVerificationFailed,
  reconciliationPending,
  cleanupPending,
  activationPending,
  blocked,
}

@immutable
class AccountTransitionResult {
  const AccountTransitionResult(this.status);

  final AccountTransitionStatus status;
}

/// Coordinates the only supported replacement: anonymous source to an
/// existing durable target. Target credentials live only in the isolated
/// context and are disposed before a fresh credential activates the target.
class AccountTransitionCoordinator {
  const AccountTransitionCoordinator({
    required this.sessions,
    required this.identity,
    required this.verifier,
    required this.operations,
    required this.journalStore,
    required this.createRequestKey,
    required this.reconcile,
    this.maxStatusPolls = 30,
    this.pollDelay = _noPollDelay,
  }) : assert(maxStatusPolls > 0);

  final CloudWriteSessionController sessions;
  final AccountTransitionIdentity identity;
  final IsolatedTargetVerifier verifier;
  final ReplacementAccountOperations operations;
  final ReplacementTransitionJournalStore journalStore;
  final String Function() createRequestKey;
  final ReplacementReconciler reconcile;
  final int maxStatusPolls;
  final Future<void> Function() pollDelay;

  static Future<void> _noPollDelay() async {}

  Future<AccountTransitionResult> confirm(
    ExistingAccountLinkConflict conflict, {
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    final source = _readyAnonymousSource();
    if (source == null) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }

    VerifiedTargetContext? target;
    var targetDisposed = false;
    try {
      target = await verifier.verify(conflict.provider);
    } catch (_) {
      return const AccountTransitionResult(
        AccountTransitionStatus.targetVerificationFailed,
      );
    }

    try {
      if (!_isExactSource(source) ||
          target.isAnonymous ||
          target.uid.trim().isEmpty ||
          target.uid == source.uid) {
        return const AccountTransitionResult(
          AccountTransitionStatus.targetVerificationFailed,
        );
      }
      final quiesced = sessions.transition(CloudWriteMode.quiesced);
      final journal = AccountTransitionJournal.fromSession(
        quiesced,
        replacementProvider: conflict.provider.name,
        replacementTargetUid: target.uid,
        replacementRequestKey: createRequestKey(),
        replacementPhase: AccountReplacementPhase.targetVerified,
      );
      try {
        await journalStore.write(journal);
      } catch (_) {
        if (await _rollbackInitialJournal(journal) &&
            _isExactSource(quiesced)) {
          sessions.transition(CloudWriteMode.ready);
        }
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (!_isExactSource(quiesced)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      return await _continue(
        journal,
        target,
        catalog,
        disposeTarget: () async {
          await target!.dispose();
          targetDisposed = true;
        },
      );
    } finally {
      if (!targetDisposed) {
        await target.dispose();
      }
    }
  }

  Future<AccountTransitionResult> resume({
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    AccountTransitionJournal? journal;
    try {
      journal = await journalStore.read();
      journal?.toJson();
    } catch (_) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    if (journal == null) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    final provider = _provider(journal.replacementProvider);
    final recovery = _isRecoveryPhase(journal.replacementPhase);
    final hasRestoredSession = sessions.current == journal.session;
    final canRestoreDeletedSource =
        recovery && sessions.current == null && identity.currentUid == null;
    final alreadyActivated =
        journal.replacementPhase == AccountReplacementPhase.activationPending &&
        identity.currentUid == journal.replacementTargetUid &&
        !identity.currentIsAnonymous;
    final activatedTargetSession =
        alreadyActivated &&
            sessions.current?.uid == journal.replacementTargetUid &&
            sessions.current?.mode == CloudWriteMode.ready
        ? sessions.current
        : null;
    if (provider == null ||
        (!hasRestoredSession &&
            !canRestoreDeletedSource &&
            activatedTargetSession == null) ||
        (hasRestoredSession &&
            !_hasExpectedIdentity(
              journal,
              allowMissingSource: recovery,
              allowActivatedTarget: alreadyActivated,
            ))) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }

    VerifiedTargetContext? target;
    var targetDisposed = false;
    try {
      target = await verifier.verify(provider);
    } catch (_) {
      return const AccountTransitionResult(
        AccountTransitionStatus.targetVerificationFailed,
      );
    }
    try {
      if (target.isAnonymous || target.uid != journal.replacementTargetUid) {
        return const AccountTransitionResult(
          AccountTransitionStatus.targetVerificationFailed,
        );
      }
      if (activatedTargetSession != null) {
        return _completeActivatedRecovery(
          journal,
          target,
          activatedTargetSession,
          disposeTarget: () async {
            await target!.dispose();
            targetDisposed = true;
          },
        );
      }
      if (canRestoreDeletedSource) {
        try {
          sessions.resume(journal.session, expectedUid: journal.session.uid);
        } on StateError {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
      }
      if (!_journalFence(
        journal,
        allowMissingSource: recovery,
        allowActivatedTarget: alreadyActivated,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      return await _continue(
        journal,
        target,
        catalog,
        disposeTarget: () async {
          await target!.dispose();
          targetDisposed = true;
        },
      );
    } finally {
      if (!targetDisposed) {
        await target.dispose();
      }
    }
  }

  Future<AccountTransitionResult> _completeActivatedRecovery(
    AccountTransitionJournal journal,
    VerifiedTargetContext target,
    CloudWriteSession targetSession, {
    required Future<void> Function() disposeTarget,
  }) async {
    final operationId = journal.replacementOperationId;
    final targetUid = journal.replacementTargetUid;
    if (journal.replacementPhase != AccountReplacementPhase.activationPending ||
        operationId == null ||
        targetUid == null ||
        target.uid != targetUid ||
        !_activatedTargetFence(targetSession, targetUid)) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    final status = await operations.getStatus(
      target: target,
      operationId: operationId,
    );
    if (!_activatedTargetFence(targetSession, targetUid) ||
        !_validSameOperation(status, operationId, status.phase)) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    if (status.phase == AccountOperationPhase.blocked) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    if (status.phase != AccountOperationPhase.completed) {
      return const AccountTransitionResult(
        AccountTransitionStatus.activationPending,
      );
    }
    await disposeTarget();
    if (!_activatedTargetFence(targetSession, targetUid)) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    bool deleted;
    try {
      deleted = await journalStore.deleteIfCurrent(
        expected: journal,
        isCurrent: () => _activatedTargetFence(targetSession, targetUid),
      );
    } catch (_) {
      return const AccountTransitionResult(
        AccountTransitionStatus.activationPending,
      );
    }
    if (!deleted || !_activatedTargetFence(targetSession, targetUid)) {
      return const AccountTransitionResult(
        AccountTransitionStatus.activationPending,
      );
    }
    return const AccountTransitionResult(AccountTransitionStatus.completed);
  }

  Future<bool> cancel() async {
    AccountTransitionJournal? journal;
    try {
      journal = await journalStore.read();
      journal?.toJson();
    } catch (_) {
      return false;
    }
    if (journal == null ||
        _isRecoveryPhase(journal.replacementPhase) ||
        !_journalFence(journal)) {
      return false;
    }
    final expectedJournal = journal;
    bool deleted;
    try {
      deleted = await journalStore.deleteIfCurrent(
        expected: expectedJournal,
        isCurrent: () => _journalFence(expectedJournal),
      );
    } catch (_) {
      return false;
    }
    if (!deleted) return false;
    if (!_journalFence(expectedJournal)) {
      try {
        await journalStore.restoreIfAbsent(
          expected: expectedJournal,
          isCurrent: () => !_journalFence(expectedJournal),
        );
      } catch (_) {}
      return false;
    }
    sessions.transition(CloudWriteMode.ready);
    return true;
  }

  Future<AccountTransitionResult> _continue(
    AccountTransitionJournal initial,
    VerifiedTargetContext target,
    Map<String, PackCatalogEntry> catalog, {
    required Future<void> Function() disposeTarget,
  }) async {
    var journal = initial;
    try {
      journal.toJson();
    } catch (_) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    var phase = journal.replacementPhase;
    var operationId = journal.replacementOperationId;
    var operationVersion = journal.replacementOperationVersion;
    if (phase == null ||
        target.isAnonymous ||
        target.uid != journal.replacementTargetUid ||
        !_journalFence(
          journal,
          allowMissingSource: _isRecoveryPhase(phase),
          allowActivatedTarget:
              phase == AccountReplacementPhase.activationPending,
        )) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }

    if (phase == AccountReplacementPhase.targetVerified) {
      final requestKey = journal.replacementRequestKey;
      if (requestKey == null || !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final prepared = await operations.prepare(
        targetUid: target.uid,
        requestKey: requestKey,
      );
      if (!_validOperation(prepared, AccountOperationPhase.prepared) ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationId = prepared.operationId;
      operationVersion = prepared.version;
      final reconciling = sessions.transition(CloudWriteMode.reconciling);
      journal = journal.copyWith(
        session: reconciling,
        reconciliationOperationId: operationId,
        replacementPhase: AccountReplacementPhase.prepared,
        replacementOperationId: operationId,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      phase = AccountReplacementPhase.prepared;
    }

    if (phase == AccountReplacementPhase.prepared) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final attached = await operations.attachTarget(
        target: target,
        operationId: operationId,
        expectedVersion: operationVersion,
      );
      if (!_validSameOperation(
            attached,
            operationId,
            AccountOperationPhase.targetVerified,
          ) ||
          !_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationVersion = attached.version;
      journal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.attached,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      phase = AccountReplacementPhase.attached;
    }

    if (phase == AccountReplacementPhase.attached ||
        phase == AccountReplacementPhase.reconciling) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.reconciling,
      );
      if (!await _writeJournalFenced(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final reconciliation = await reconcile(
        target: target,
        session: journal.session,
        operationId: operationId,
        catalog: catalog,
      );
      if (!_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (reconciliation.status != AccountReconciliationStatus.completed) {
        return const AccountTransitionResult(
          AccountTransitionStatus.reconciliationPending,
        );
      }
      AccountTransitionJournal? refreshedJournal;
      try {
        refreshedJournal = await journalStore.read();
      } catch (_) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (refreshedJournal == null ||
          !_journalFence(journal) ||
          refreshedJournal.session != journal.session ||
          refreshedJournal.replacementOperationId != operationId ||
          refreshedJournal.reconciliationOperationId != operationId ||
          refreshedJournal.reconciliationCheckpoint !=
              ReconciliationCheckpoint.completed) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = refreshedJournal;
      if (!_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final committed = await operations.commitReconciliation(
        target: target,
        operationId: operationId,
        expectedVersion: operationVersion,
      );
      if (!_validSameOperation(
            committed,
            operationId,
            AccountOperationPhase.reconciling,
          ) ||
          !_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationVersion = committed.version;
      journal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.reconciled,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      phase = AccountReplacementPhase.reconciled;
    }

    if (phase == AccountReplacementPhase.reconciled) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final cleanupSession = sessions.transition(CloudWriteMode.cleanupPending);
      journal = journal.copyWith(
        session: cleanupSession,
        replacementPhase: AccountReplacementPhase.cleanupPending,
      );
      if (!await _writeJournalFenced(journal, allowMissingSource: true)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (!_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final cleanup = await operations.startSourceCleanup(
        target: target,
        operationId: operationId,
        expectedVersion: operationVersion,
      );
      if (!_validSameOperation(
            cleanup,
            operationId,
            AccountOperationPhase.sourceCleanupPending,
          ) ||
          !_journalFence(journal, allowMissingSource: true)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationVersion = cleanup.version;
      journal = journal.copyWith(replacementOperationVersion: operationVersion);
      if (!await _writeJournalFenced(journal, allowMissingSource: true)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      phase = AccountReplacementPhase.cleanupPending;
    }

    if (!_isRecoveryPhase(phase) ||
        operationId == null ||
        operationVersion == null) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    for (var poll = 0; poll < maxStatusPolls; poll += 1) {
      if (!_journalFence(
        journal,
        allowMissingSource: true,
        allowActivatedTarget:
            phase == AccountReplacementPhase.activationPending,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      await pollDelay();
      if (!_journalFence(
        journal,
        allowMissingSource: true,
        allowActivatedTarget:
            phase == AccountReplacementPhase.activationPending,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final status = await operations.getStatus(
        target: target,
        operationId: operationId,
      );
      if (!_validSameOperation(status, operationId, status.phase) ||
          !_journalFence(
            journal,
            allowMissingSource: true,
            allowActivatedTarget:
                phase == AccountReplacementPhase.activationPending,
          )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (status.phase == AccountOperationPhase.completed) {
        final provider = _provider(journal.replacementProvider);
        final targetUid = journal.replacementTargetUid;
        if (provider == null || targetUid == null) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        if (phase != AccountReplacementPhase.activationPending) {
          journal = journal.copyWith(
            replacementPhase: AccountReplacementPhase.activationPending,
            replacementOperationVersion: status.version,
          );
          if (!await _writeJournalFenced(journal, allowMissingSource: true)) {
            return const AccountTransitionResult(
              AccountTransitionStatus.blocked,
            );
          }
          phase = AccountReplacementPhase.activationPending;
        }
        final alreadyActivated =
            identity.currentUid == targetUid && !identity.currentIsAnonymous;
        if (!_journalFence(
          journal,
          allowMissingSource: true,
          allowActivatedTarget: alreadyActivated,
        )) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        await disposeTarget();
        if (!_journalFence(
          journal,
          allowMissingSource: true,
          allowActivatedTarget: alreadyActivated,
        )) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        if (!alreadyActivated) {
          try {
            await identity.activateTarget(
              provider,
              expectedTargetUid: targetUid,
              expectedSourceSession: journal.session,
              sessions: sessions,
              allowMissingSource: true,
            );
          } catch (_) {
            if (!_journalFence(journal, allowMissingSource: true)) {
              return const AccountTransitionResult(
                AccountTransitionStatus.blocked,
              );
            }
            return const AccountTransitionResult(
              AccountTransitionStatus.activationPending,
            );
          }
        }
        if (identity.currentUid != targetUid ||
            identity.currentIsAnonymous ||
            !_isSessionCurrent(journal.session)) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        bool deleted;
        try {
          deleted = await journalStore.deleteIfCurrent(
            expected: journal,
            isCurrent: () =>
                identity.currentUid == targetUid &&
                !identity.currentIsAnonymous &&
                _isSessionCurrent(journal.session),
          );
        } catch (_) {
          return const AccountTransitionResult(
            AccountTransitionStatus.activationPending,
          );
        }
        if (!deleted ||
            identity.currentUid != targetUid ||
            identity.currentIsAnonymous ||
            !_isSessionCurrent(journal.session)) {
          return const AccountTransitionResult(
            AccountTransitionStatus.activationPending,
          );
        }
        sessions.acquire(targetUid);
        return const AccountTransitionResult(AccountTransitionStatus.completed);
      }
      if (status.phase == AccountOperationPhase.blocked) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (status.phase != AccountOperationPhase.sourceCleanupPending) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
    }
    return const AccountTransitionResult(
      AccountTransitionStatus.cleanupPending,
    );
  }

  CloudWriteSession? _readyAnonymousSource() {
    final current = sessions.current;
    if (current == null ||
        current.mode != CloudWriteMode.ready ||
        identity.currentUid != current.uid ||
        !identity.currentIsAnonymous) {
      return null;
    }
    return current;
  }

  bool _isExactSource(CloudWriteSession session) {
    if (identity.currentUid != session.uid || !identity.currentIsAnonymous) {
      return false;
    }
    try {
      sessions.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }

  bool _isSessionCurrent(CloudWriteSession session) {
    try {
      sessions.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }

  bool _activatedTargetFence(CloudWriteSession session, String targetUid) {
    return session.uid == targetUid &&
        session.mode == CloudWriteMode.ready &&
        identity.currentUid == targetUid &&
        !identity.currentIsAnonymous &&
        _isSessionCurrent(session);
  }

  bool _hasExpectedIdentity(
    AccountTransitionJournal journal, {
    required bool allowMissingSource,
    required bool allowActivatedTarget,
  }) {
    if (identity.currentUid == journal.session.uid) {
      return identity.currentIsAnonymous;
    }
    if (allowMissingSource && identity.currentUid == null) return true;
    return allowActivatedTarget &&
        identity.currentUid == journal.replacementTargetUid &&
        !identity.currentIsAnonymous;
  }

  bool _journalFence(
    AccountTransitionJournal journal, {
    bool allowMissingSource = false,
    bool allowActivatedTarget = false,
  }) {
    return _isSessionCurrent(journal.session) &&
        _hasExpectedIdentity(
          journal,
          allowMissingSource: allowMissingSource,
          allowActivatedTarget: allowActivatedTarget,
        );
  }

  Future<bool> _writeJournalFenced(
    AccountTransitionJournal journal, {
    bool allowMissingSource = false,
  }) async {
    if (!_journalFence(journal, allowMissingSource: allowMissingSource)) {
      return false;
    }
    try {
      await journalStore.write(journal);
    } catch (_) {
      return false;
    }
    return _journalFence(journal, allowMissingSource: allowMissingSource);
  }

  Future<bool> _rollbackInitialJournal(
    AccountTransitionJournal expected,
  ) async {
    if (!_journalFence(expected)) return false;
    try {
      final current = await journalStore.read();
      if (!_journalFence(expected)) return false;
      if (current == null) return true;
      if (jsonEncode(current.toJson()) != jsonEncode(expected.toJson())) {
        return false;
      }
      return journalStore.deleteIfCurrent(
        expected: current,
        isCurrent: () => _journalFence(expected),
      );
    } catch (_) {
      return false;
    }
  }

  static bool _isRecoveryPhase(AccountReplacementPhase? phase) =>
      phase == AccountReplacementPhase.cleanupPending ||
      phase == AccountReplacementPhase.activationPending;

  static bool _validOperation(
    AccountOperationResult result,
    AccountOperationPhase phase,
  ) => result.kind == AccountOperationKind.replacement && result.phase == phase;

  static bool _validSameOperation(
    AccountOperationResult result,
    String operationId,
    AccountOperationPhase phase,
  ) => result.operationId == operationId && _validOperation(result, phase);

  static AccountLinkProvider? _provider(String? value) => switch (value) {
    'google' => AccountLinkProvider.google,
    'apple' => AccountLinkProvider.apple,
    _ => null,
  };
}
