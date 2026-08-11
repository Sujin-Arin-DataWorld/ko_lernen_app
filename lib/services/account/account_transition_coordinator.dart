import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/course_mastery.dart';
import '../pack_progress_service.dart';
import 'account_failure_diagnostics.dart';
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

/// 계정 연동을 시도조차 할 수 없는 상태 — Firebase 가 초기화되지 않았다.
///
/// ⚠️ 이 타입이 존재하는 이유: 예전에는 이 경우와 **사용자가 직접 취소한 경우**가
/// 둘 다 `null` 로 반환돼, UI 가 "취소"로 오인하고 **아무 메시지도 띄우지
/// 않았다**. 사용자에게는 그냥 "아무 일도 일어나지 않는 버튼"이었고, 실제 원인
/// (google-services 설정 누락, Firebase init 실패)은 어디에도 드러나지 않았다.
///
/// 사용자 취소는 계속 `null` 이고, 시스템 불가는 이 예외다.
class AccountLinkUnavailable implements Exception {
  const AccountLinkUnavailable();

  @override
  String toString() =>
      'Account linking is unavailable because Firebase is not initialised.';
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

  /// Acquires a provider-appropriate activation credential and activates it in
  /// the primary auth context. Google may reuse only the immediately verified
  /// silent session; Apple remains fresh and explicit. It is called only after
  /// source cleanup is terminal-successful.
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
    required CourseMasteryReconciliationMerger courseMasteryMerger,
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
      courseMasteryMerger: courseMasteryMerger,
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
    required CloudWriteSession sourceSession,
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

  Future<AccountOperationResult> cancel({
    required CloudWriteSession sourceSession,
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

  final FreshAnonymousAccountOperationGateway source;

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
    required CloudWriteSession sourceSession,
    required String targetUid,
    required String requestKey,
  }) {
    return source.prepareAnonymousReplacement(
      expectedSession: sourceSession,
      request: AnonymousReplacementPrepareRequest(
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
  Future<AccountOperationResult> cancel({
    required CloudWriteSession sourceSession,
    required String operationId,
    required int expectedVersion,
  }) {
    return source.cancelAnonymousReplacement(
      expectedSession: sourceSession,
      request: ReplacementAdvanceRequest(
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
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) => _store.writeIfCurrent(
    expected: expected,
    next: next,
    isCurrent: isCurrent,
  );

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
    required this.maxStatusPolls,
    required this.pollDelay,
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
    var activatedTargetSession =
        alreadyActivated &&
            sessions.current?.uid == journal.replacementTargetUid &&
            sessions.current?.mode == CloudWriteMode.ready
        ? sessions.current
        : null;
    final canAcquireActivatedTargetSession =
        alreadyActivated && sessions.current == null;
    if (provider == null ||
        (!hasRestoredSession &&
            !canRestoreDeletedSource &&
            activatedTargetSession == null &&
            !canAcquireActivatedTargetSession) ||
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
      if (activatedTargetSession == null && canAcquireActivatedTargetSession) {
        // A crash can land after Firebase has durably activated the target but
        // before the process acquired its ready cloud-write session. Restore
        // only the exact non-anonymous target, only for the terminal
        // activationPending checkpoint, and only while no competing session
        // appeared during isolated target verification.
        if (sessions.current != null ||
            identity.currentUid != journal.replacementTargetUid ||
            identity.currentIsAnonymous) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        activatedTargetSession = sessions.acquire(target.uid);
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
        !_isLocallyCancellablePhase(journal.replacementPhase) ||
        !_journalFence(journal)) {
      return false;
    }
    final expectedJournal = journal;
    var operationId = expectedJournal.replacementOperationId;
    var operationVersion = expectedJournal.replacementOperationVersion;
    if ((operationId == null) != (operationVersion == null)) return false;
    if (operationId == null && operationVersion == null) {
      final targetUid = expectedJournal.replacementTargetUid;
      final requestKey = expectedJournal.replacementRequestKey;
      if (targetUid == null || requestKey == null) return false;
      AccountOperationResult prepared;
      try {
        if (!_journalFence(expectedJournal)) return false;
        prepared = await operations.prepare(
          sourceSession: expectedJournal.session,
          targetUid: targetUid,
          requestKey: requestKey,
        );
      } on AccountOperationFailure catch (failure) {
        // The callable gateway decides these before the operation handler
        // runs, so no server operation can exist for this request key and the
        // journal is purely local state. Keeping it would leave linking and
        // deletion permanently blocked with no in-app way back.
        if (!_isRejectedBeforeServerOperation(failure.code)) return false;
        return _discardUnpreparedJournal(expectedJournal);
      } catch (_) {
        return false;
      }
      if (!_journalFence(expectedJournal) ||
          prepared.kind != AccountOperationKind.replacement) {
        return false;
      }
      if (prepared.phase == AccountOperationPhase.cancelled) {
        operationId = prepared.operationId;
      } else if (_isServerCancellablePhase(prepared.phase)) {
        operationId = prepared.operationId;
        operationVersion = prepared.version;
      } else {
        return false;
      }
    }
    if (operationId != null && operationVersion != null) {
      AccountOperationResult cancelled;
      try {
        if (!_journalFence(expectedJournal)) return false;
        cancelled = await operations.cancel(
          sourceSession: expectedJournal.session,
          operationId: operationId,
          expectedVersion: operationVersion,
        );
      } catch (_) {
        return false;
      }
      if (!_journalFence(expectedJournal) ||
          !_validSameOperation(
            cancelled,
            operationId,
            AccountOperationPhase.cancelled,
          ) ||
          cancelled.version != operationVersion + 1) {
        return false;
      }
    } else if (operationId == null) {
      return false;
    }
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

  /// Drops a journal whose replacement never reached the server.
  ///
  /// Only a `targetVerified` journal that carries no operation id qualifies:
  /// past that point the server owns state that a local delete would orphan.
  /// The delete stays fenced exactly like the normal cancel path so a
  /// concurrent transition cannot lose a journal it just wrote.
  Future<bool> _discardUnpreparedJournal(
    AccountTransitionJournal expected,
  ) async {
    if (expected.replacementPhase != AccountReplacementPhase.targetVerified ||
        expected.replacementOperationId != null ||
        expected.replacementOperationVersion != null) {
      return false;
    }
    bool deleted;
    try {
      deleted = await journalStore.deleteIfCurrent(
        expected: expected,
        isCurrent: () => _journalFence(expected),
      );
    } catch (_) {
      return false;
    }
    if (!deleted) return false;
    if (!_journalFence(expected)) {
      try {
        await journalStore.restoreIfAbsent(
          expected: expected,
          isCurrent: () => !_journalFence(expected),
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
      // ⚠️ 실기기에서 여기서 막혔다(2026-08-07). journal 이 `targetVerified` +
      // `replacementOperationId` 없음으로 고착됐는데, 이 블록의 세 갈래가
      // **전부 예외 없이 조용히 `blocked` 를 반환**해서 어느 갈래인지 알 수
      // 없었다. `runConfirmedAccountLink` 의 catch 는 예외만 보므로 여기 실패는
      // 잡지 못한다. 로그만 남기고 제어 흐름은 그대로 둔다.
      final requestKey = journal.replacementRequestKey;
      if (requestKey == null || !_journalFence(journal)) {
        AccountFailureDiagnostics.log(
          'link.prepare.skipped',
          null,
          detail:
              'requestKey=${requestKey == null ? 'null' : 'present'} '
              'fence=${_journalFence(journal)}',
        );
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      AccountFailureDiagnostics.log('link.prepare.start', null);
      final AccountOperationResult prepared;
      try {
        prepared = await operations.prepare(
          sourceSession: journal.session,
          targetUid: target.uid,
          requestKey: requestKey,
        );
      } catch (error) {
        // 서버가 operation 을 만들기 전에 거부하면 여기로 온다
        // (appCheckRequired·authenticationRequired·permissionDenied 등).
        AccountFailureDiagnostics.log('link.prepare.threw', error);
        rethrow;
      }
      if (!_validOperation(prepared, AccountOperationPhase.prepared) ||
          !_journalFence(journal)) {
        // 응답은 왔지만 기대한 phase 가 아니거나 fence 가 깨진 경우.
        AccountFailureDiagnostics.log(
          'link.prepare.rejected',
          null,
          detail:
              'phase=${prepared.phase.name} retryable=${prepared.retryable} '
              'blockedReason=${prepared.blockedReason?.name ?? 'none'} '
              'fence=${_journalFence(journal)}',
        );
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      AccountFailureDiagnostics.log(
        'link.prepare.ok',
        null,
        detail: 'version=${prepared.version}',
      );
      operationId = prepared.operationId;
      operationVersion = prepared.version;
      final reconciling = sessions.transition(CloudWriteMode.reconciling);
      final preparedJournal = journal.copyWith(
        session: reconciling,
        reconciliationOperationId: operationId,
        replacementPhase: AccountReplacementPhase.prepared,
        replacementOperationId: operationId,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal, preparedJournal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = preparedJournal;
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
      final attachedJournal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.attached,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal, attachedJournal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = attachedJournal;
      phase = AccountReplacementPhase.attached;
    }

    if (phase == AccountReplacementPhase.attached ||
        phase == AccountReplacementPhase.reconciling) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final reconcilingJournal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.reconciling,
      );
      if (!await _writeJournalFenced(journal, reconcilingJournal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = reconcilingJournal;
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
        // ⚠️ 이 지점이 무한 루프의 정체였다. 조정 러너가 돌려주는
        // {blocked, unavailable, invalid, tooLarge, stale} 다섯 상태를 예전에는
        // 전부 하나의 `reconciliationPending` 으로 뭉개 반환해, 실기기에서
        // **어느 하위 단계가 왜 실패했는지 전혀 알 수 없었다**. 상태·충돌 종류만
        // 안전하게 남긴다(러너 내부의 `link.reconcile.*` 로그와 짝을 이룬다).
        AccountFailureDiagnostics.log(
          'link.reconcile.pending',
          null,
          detail:
              'status=${reconciliation.status.name} '
              '${_summarizeReconciliationConflicts(reconciliation.conflicts)}',
        );
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
      final reconciledJournal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.reconciled,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(journal, reconciledJournal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = reconciledJournal;
      phase = AccountReplacementPhase.reconciled;
    }

    var cleanupWasJustStarted = false;
    if (phase == AccountReplacementPhase.reconciled) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final cleanupSession = sessions.transition(CloudWriteMode.cleanupPending);
      final cleanupStartingJournal = journal.copyWith(
        session: cleanupSession,
        replacementPhase: AccountReplacementPhase.cleanupStarting,
      );
      if (!await _writeJournalFenced(
        journal,
        cleanupStartingJournal,
        allowMissingSource: true,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = cleanupStartingJournal;
      phase = AccountReplacementPhase.cleanupStarting;
      cleanupWasJustStarted = true;
    }

    if (phase == AccountReplacementPhase.cleanupStarting) {
      if (operationId == null ||
          operationVersion == null ||
          !_journalFence(journal, allowMissingSource: true)) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      AccountOperationResult? cleanupState;
      var cleanupRequestFailed = false;
      if (!cleanupWasJustStarted) {
        try {
          cleanupState = await operations.getStatus(
            target: target,
            operationId: operationId,
          );
        } catch (_) {
          return const AccountTransitionResult(
            AccountTransitionStatus.cleanupPending,
          );
        }
        if (!_validCleanupState(cleanupState, operationId, operationVersion) ||
            !_journalFence(journal, allowMissingSource: true)) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
      }
      if (cleanupWasJustStarted ||
          cleanupState?.phase == AccountOperationPhase.reconciling) {
        try {
          cleanupState = await operations.startSourceCleanup(
            target: target,
            operationId: operationId,
            expectedVersion: operationVersion,
          );
        } catch (_) {
          cleanupRequestFailed = true;
          if (!_journalFence(journal, allowMissingSource: true)) {
            return const AccountTransitionResult(
              AccountTransitionStatus.blocked,
            );
          }
          try {
            cleanupState = await operations.getStatus(
              target: target,
              operationId: operationId,
            );
          } catch (_) {
            return const AccountTransitionResult(
              AccountTransitionStatus.cleanupPending,
            );
          }
        }
        if (!_journalFence(journal, allowMissingSource: true) ||
            !_validCleanupState(cleanupState, operationId, operationVersion)) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
      }
      if (cleanupState?.phase == AccountOperationPhase.reconciling &&
          cleanupRequestFailed) {
        if (identity.currentUid != journal.session.uid ||
            !identity.currentIsAnonymous) {
          return const AccountTransitionResult(
            AccountTransitionStatus.cleanupPending,
          );
        }
        final reconcilingSession = sessions.transition(
          CloudWriteMode.reconciling,
        );
        final retryableJournal = journal.copyWith(
          session: reconcilingSession,
          replacementPhase: AccountReplacementPhase.reconciled,
        );
        if (!await _writeJournalFenced(journal, retryableJournal)) {
          return const AccountTransitionResult(AccountTransitionStatus.blocked);
        }
        return const AccountTransitionResult(
          AccountTransitionStatus.cleanupPending,
        );
      }
      if (cleanupState?.phase == AccountOperationPhase.blocked) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      if (cleanupState?.phase != AccountOperationPhase.sourceCleanupPending &&
          cleanupState?.phase != AccountOperationPhase.completed) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      operationVersion = cleanupState?.version;
      if (operationVersion == null) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      final cleanupPendingJournal = journal.copyWith(
        replacementPhase: AccountReplacementPhase.cleanupPending,
        replacementOperationVersion: operationVersion,
      );
      if (!await _writeJournalFenced(
        journal,
        cleanupPendingJournal,
        allowMissingSource: true,
      )) {
        return const AccountTransitionResult(AccountTransitionStatus.blocked);
      }
      journal = cleanupPendingJournal;
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
          final activationJournal = journal.copyWith(
            replacementPhase: AccountReplacementPhase.activationPending,
            replacementOperationVersion: status.version,
          );
          if (!await _writeJournalFenced(
            journal,
            activationJournal,
            allowMissingSource: true,
          )) {
            return const AccountTransitionResult(
              AccountTransitionStatus.blocked,
            );
          }
          journal = activationJournal;
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
    AccountTransitionJournal expected,
    AccountTransitionJournal next, {
    bool allowMissingSource = false,
  }) async {
    if (!_journalFence(next, allowMissingSource: allowMissingSource)) {
      return false;
    }
    try {
      final written = await journalStore.writeIfCurrent(
        expected: expected,
        next: next,
        isCurrent: () =>
            _journalFence(next, allowMissingSource: allowMissingSource),
      );
      if (!written) return false;
    } catch (_) {
      return false;
    }
    return _journalFence(next, allowMissingSource: allowMissingSource);
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
      phase == AccountReplacementPhase.cleanupStarting ||
      phase == AccountReplacementPhase.cleanupPending ||
      phase == AccountReplacementPhase.activationPending;

  /// Failures the callable gateway raises before the operation handler runs,
  /// which proves no server-side operation was created for the request.
  static bool _isRejectedBeforeServerOperation(
    AccountOperationFailureCode code,
  ) =>
      code == AccountOperationFailureCode.appCheckRequired ||
      code == AccountOperationFailureCode.authenticationRequired;

  static bool _isLocallyCancellablePhase(AccountReplacementPhase? phase) =>
      phase == AccountReplacementPhase.targetVerified ||
      phase == AccountReplacementPhase.prepared ||
      phase == AccountReplacementPhase.attached ||
      phase == AccountReplacementPhase.reconciling ||
      phase == AccountReplacementPhase.reconciled;

  static bool _isServerCancellablePhase(AccountOperationPhase phase) =>
      phase == AccountOperationPhase.prepared ||
      phase == AccountOperationPhase.targetVerified ||
      phase == AccountOperationPhase.reconciling;

  static bool _validOperation(
    AccountOperationResult result,
    AccountOperationPhase phase,
  ) => result.kind == AccountOperationKind.replacement && result.phase == phase;

  static bool _validSameOperation(
    AccountOperationResult result,
    String operationId,
    AccountOperationPhase phase,
  ) => result.operationId == operationId && _validOperation(result, phase);

  static bool _validCleanupState(
    AccountOperationResult result,
    String operationId,
    int expectedVersion,
  ) {
    if (!_validSameOperation(result, operationId, result.phase)) return false;
    return switch (result.phase) {
      AccountOperationPhase.reconciling => result.version == expectedVersion,
      AccountOperationPhase.sourceCleanupPending =>
        result.version == expectedVersion + 1,
      AccountOperationPhase.completed => result.version > expectedVersion,
      AccountOperationPhase.blocked => true,
      _ => false,
    };
  }

  static AccountLinkProvider? _provider(String? value) => switch (value) {
    'google' => AccountLinkProvider.google,
    'apple' => AccountLinkProvider.apple,
    _ => null,
  };

  /// 조정 실패를 **상태·충돌 종류**로만 요약한다. 충돌 id 는 사용자가 지은
  /// 커스텀 팩 이름을 담을 수 있어 로그에 원문을 남기지 않는다(러너의
  /// `_summarizeConflicts` 와 같은 방침).
  static String _summarizeReconciliationConflicts(
    List<AccountReconciliationConflict> conflicts,
  ) {
    if (conflicts.isEmpty) return 'conflicts=none';
    final kinds = <String>{for (final c in conflicts) c.kind.name}.toList()
      ..sort();
    return 'conflicts=${conflicts.length}:${kinds.join('/')}';
  }
}
