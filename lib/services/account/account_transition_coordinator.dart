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

abstract interface class ReplacementTransitionJournalStore {
  Future<AccountTransitionJournal?> read();
  Future<void> write(AccountTransitionJournal journal);
  Future<void> delete();
}

class SharedPreferencesReplacementTransitionJournalStore
    implements
        ReplacementTransitionJournalStore,
        AccountTransitionJournalStore {
  const SharedPreferencesReplacementTransitionJournalStore(this.preferences);

  final SharedPreferences preferences;

  @override
  Future<AccountTransitionJournal?> read() async {
    await preferences.reload();
    final raw = preferences.getString(AccountTransitionJournal.storageKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid account transition journal.');
    }
    return AccountTransitionJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<void> write(AccountTransitionJournal journal) async {
    final written = await preferences.setString(
      AccountTransitionJournal.storageKey,
      jsonEncode(journal.toJson()),
    );
    if (!written) {
      throw StateError('Account transition journal write failed.');
    }
  }

  @override
  Future<void> delete() async {
    final removed = await preferences.remove(
      AccountTransitionJournal.storageKey,
    );
    if (!removed &&
        preferences.containsKey(AccountTransitionJournal.storageKey)) {
      throw StateError('Account transition journal delete failed.');
    }
  }
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
  }) : assert(maxStatusPolls > 0);

  final CloudWriteSessionController sessions;
  final AccountTransitionIdentity identity;
  final IsolatedTargetVerifier verifier;
  final ReplacementAccountOperations operations;
  final ReplacementTransitionJournalStore journalStore;
  final String Function() createRequestKey;
  final ReplacementReconciler reconcile;
  final int maxStatusPolls;

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
      await journalStore.write(journal);
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
    final journal = await journalStore.read();
    if (!_validResumeSource(journal)) {
      return const AccountTransitionResult(AccountTransitionStatus.blocked);
    }
    final provider = _provider(journal!.replacementProvider);
    if (provider == null) {
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

  Future<bool> cancel() async {
    final journal = await journalStore.read();
    if (!_validResumeSource(journal) ||
        journal!.replacementPhase == AccountReplacementPhase.cleanupPending) {
      return false;
    }
    await journalStore.delete();
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
    var phase = journal.replacementPhase!;
    var operationId = journal.replacementOperationId;
    var operationVersion = journal.replacementOperationVersion;

    if (phase == AccountReplacementPhase.targetVerified) {
      if (!_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final prepared = await operations.prepare(
        targetUid: target.uid,
        requestKey: journal.replacementRequestKey!,
      );
      if (!_validOperation(prepared, AccountOperationPhase.prepared) ||
          !_isExactSource(journal.session)) {
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
      await journalStore.write(journal);
      phase = AccountReplacementPhase.prepared;
    }

    if (phase == AccountReplacementPhase.prepared) {
      final attached = await operations.attachTarget(
        target: target,
        operationId: operationId!,
        expectedVersion: operationVersion!,
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
      await journalStore.write(journal);
      phase = AccountReplacementPhase.attached;
    }

    if (phase == AccountReplacementPhase.attached ||
        phase == AccountReplacementPhase.reconciling) {
      journal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.reconciling,
      );
      await journalStore.write(journal);
      if (!_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final reconciliation = await reconcile(
        target: target,
        session: journal.session,
        operationId: operationId!,
        catalog: catalog,
      );
      if (reconciliation.status != AccountReconciliationStatus.completed) {
        return const AccountTransitionResult(
          AccountTransitionStatus.reconciliationPending,
        );
      }
      if (!_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final refreshedJournal = await journalStore.read();
      if (refreshedJournal == null ||
          refreshedJournal.session != journal.session ||
          refreshedJournal.replacementOperationId != operationId ||
          refreshedJournal.reconciliationOperationId != operationId) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = refreshedJournal;
      final committed = await operations.commitReconciliation(
        target: target,
        operationId: operationId,
        expectedVersion: operationVersion!,
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
      await journalStore.write(journal);
      phase = AccountReplacementPhase.reconciled;
    }

    if (phase == AccountReplacementPhase.reconciled) {
      if (!_isExactSource(journal.session)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final cleanupSession = sessions.transition(CloudWriteMode.cleanupPending);
      journal = journal.copyWith(
        session: cleanupSession,
        replacementPhase: AccountReplacementPhase.cleanupPending,
      );
      await journalStore.write(journal);
      final cleanup = await operations.startSourceCleanup(
        target: target,
        operationId: operationId!,
        expectedVersion: operationVersion!,
      );
      if (!_validSameOperation(
        cleanup,
        operationId,
        AccountOperationPhase.sourceCleanupPending,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationVersion = cleanup.version;
      journal = journal.copyWith(replacementOperationVersion: operationVersion);
      await journalStore.write(journal);
    }

    for (var poll = 0; poll < maxStatusPolls; poll += 1) {
      final status = await operations.getStatus(
        target: target,
        operationId: operationId!,
      );
      if (!_validSameOperation(status, operationId, status.phase)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (status.phase == AccountOperationPhase.completed) {
        final provider = _provider(journal.replacementProvider)!;
        await disposeTarget();
        await identity.activateTarget(
          provider,
          expectedTargetUid: journal.replacementTargetUid!,
        );
        if (identity.currentUid != journal.replacementTargetUid) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        sessions.acquire(journal.replacementTargetUid!);
        await journalStore.delete();
        return const AccountTransitionResult(AccountTransitionStatus.completed);
      }
      if (status.phase == AccountOperationPhase.blocked) {
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

  bool _validResumeSource(AccountTransitionJournal? journal) {
    if (journal == null ||
        journal.replacementPhase == null ||
        identity.currentUid != journal.session.uid ||
        !identity.currentIsAnonymous ||
        sessions.current != journal.session) {
      return false;
    }
    return true;
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
