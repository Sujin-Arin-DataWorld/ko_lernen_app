import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' show AuthCredential;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../pack_progress_service.dart';
import 'account_failure_diagnostics.dart';
import 'account_reconciliation.dart';
import 'account_transition_coordinator.dart' show AccountLinkProvider;
import 'account_transition_journal.dart';
import 'cloud_write_session.dart';

/// Outcome of an [AccountSwitchCoordinator] operation.
enum AccountSwitchStatus { completed, mergeDeferred, failed }

@immutable
class AccountSwitchResult {
  const AccountSwitchResult(this.status, {this.targetUid});

  final AccountSwitchStatus status;
  final String? targetUid;
}

/// Non-secret marker written immediately after the primary auth switched to
/// an existing durable account. It survives a process kill between the
/// sign-in and the reconciliation merge so [AccountSwitchCoordinator.resume]
/// can finish the merge on next launch — it never carries the credential
/// itself.
@immutable
class AccountSwitchJournal {
  const AccountSwitchJournal({
    required this.version,
    required this.sourceUid,
    required this.targetUid,
    required this.provider,
    required this.operationId,
    required this.createdAtMillis,
  });

  static const currentVersion = 1;
  static const storageKey = 'kl_account_switch_journal_v1';

  /// Storage key for the [AccountReconciliationCoordinator]'s own journal
  /// while it merges into the target account. Kept separate from the legacy
  /// [AccountTransitionJournal.storageKey] via
  /// `SharedPreferencesAccountTransitionJournalStore(storageKey: ...)` so an
  /// account switch never collides with a leftover replacement journal.
  /// `MediaCleanupGate` and `Storage`'s reset fence read the same key.
  static const reconciliationStorageKey =
      AccountTransitionJournal.switchReconciliationStorageKey;

  final int version;
  final String sourceUid;
  final String targetUid;

  /// [AccountLinkProvider.name] — `'google'` or `'apple'`.
  final String provider;

  /// A uuid v4 generated locally; must match the reconciliation coordinator's
  /// `_validOperationId` allowlist (`^[A-Za-z0-9][A-Za-z0-9._:-]*$`).
  final String operationId;
  final int createdAtMillis;

  Map<String, Object?> toJson() => {
    'version': version,
    'sourceUid': sourceUid,
    'targetUid': targetUid,
    'provider': provider,
    'operationId': operationId,
    'createdAtMillis': createdAtMillis,
  };

  /// Strict decode — any missing/mistyped/invalid field throws
  /// [FormatException] rather than silently coercing bad data.
  factory AccountSwitchJournal.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != AccountSwitchJournal.currentVersion) {
      throw const FormatException(
        'Unsupported account switch journal version.',
      );
    }
    final sourceUid = json['sourceUid'];
    if (sourceUid is! String || sourceUid.isEmpty) {
      throw const FormatException(
        'Invalid account switch journal sourceUid.',
      );
    }
    final targetUid = json['targetUid'];
    if (targetUid is! String || targetUid.isEmpty) {
      throw const FormatException(
        'Invalid account switch journal targetUid.',
      );
    }
    final provider = json['provider'];
    if (provider is! String || provider.isEmpty) {
      throw const FormatException(
        'Invalid account switch journal provider.',
      );
    }
    final operationId = json['operationId'];
    if (operationId is! String || operationId.isEmpty) {
      throw const FormatException(
        'Invalid account switch journal operationId.',
      );
    }
    final createdAtMillis = json['createdAtMillis'];
    if (createdAtMillis is! int) {
      throw const FormatException(
        'Invalid account switch journal createdAtMillis.',
      );
    }
    return AccountSwitchJournal(
      version: version,
      sourceUid: sourceUid,
      targetUid: targetUid,
      provider: provider,
      operationId: operationId,
      createdAtMillis: createdAtMillis,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AccountSwitchJournal &&
      other.version == version &&
      other.sourceUid == sourceUid &&
      other.targetUid == targetUid &&
      other.provider == provider &&
      other.operationId == operationId &&
      other.createdAtMillis == createdAtMillis;

  @override
  int get hashCode => Object.hash(
    version,
    sourceUid,
    targetUid,
    provider,
    operationId,
    createdAtMillis,
  );
}

abstract interface class AccountSwitchJournalStore {
  /// Corrupt JSON is treated as absent: the key is removed and `null` is
  /// returned rather than throwing.
  Future<AccountSwitchJournal?> read();
  Future<void> write(AccountSwitchJournal journal);
  Future<void> clear();
}

class SharedPreferencesAccountSwitchJournalStore
    implements AccountSwitchJournalStore {
  SharedPreferencesAccountSwitchJournalStore(this.preferences);

  final SharedPreferences preferences;

  @override
  Future<AccountSwitchJournal?> read() async {
    await preferences.reload();
    final raw = preferences.getString(AccountSwitchJournal.storageKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Invalid account switch journal.');
      }
      return AccountSwitchJournal.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      await preferences.remove(AccountSwitchJournal.storageKey);
      return null;
    }
  }

  @override
  Future<void> write(AccountSwitchJournal journal) async {
    final written = await preferences.setString(
      AccountSwitchJournal.storageKey,
      jsonEncode(journal.toJson()),
    );
    if (!written) {
      throw StateError('Account switch journal write failed.');
    }
  }

  @override
  Future<void> clear() async {
    await preferences.remove(AccountSwitchJournal.storageKey);
  }
}

/// Seam over the primary `FirebaseAuth` instance. Production implementations
/// must never touch a secondary/isolated app — the whole point of this
/// coordinator is to sign the ONE primary auth context into the existing
/// account.
abstract interface class AccountSwitchIdentity {
  String? get currentUid;
  bool get currentIsAnonymous;

  /// Signs the primary `FirebaseAuth` into [credential]; returns the new uid.
  /// Throws on failure — the current user is left unchanged by Firebase in
  /// that case.
  Future<String> signInWithCredential(AuthCredential credential);
}

/// Production: `LocalAccountReconciliationStore.load`. Validates the local
/// snapshot before any cloud identity change is attempted.
typedef AccountSwitchLocalPreflight = Future<void> Function();

/// Production: the `AuthService` push-ownership coordinator's `.run`. Wraps
/// [transition] so the push token is never left owned by the stale uid; on
/// success the session lands in `CloudWriteMode.cleanupPending`, on failure
/// in `CloudWriteMode.blocked` (and the original error is rethrown).
typedef AccountSwitchOwnershipTransition =
    Future<CloudWriteResult> Function({
      required String oldUid,
      required Future<void> Function() transition,
    });

/// Production: `pushService.bindCurrentUser` — best-effort, failures are
/// logged only.
typedef AccountSwitchPushRebind = Future<void> Function();

/// Production: an [AccountReconciliationCoordinator] bound to the target
/// account (via `FirebaseAccountReconciliationAdapter`).
typedef AccountSwitchReconciler =
    Future<AccountReconciliationResult> Function({
      required String targetUid,
      required CloudWriteSession session,
      required String operationId,
      required Map<String, PackCatalogEntry> catalog,
    });

/// Production: `FirstDurableLinkActivation.activate(sourceUid: uid, linkedUid:
/// uid, linkedIsAnonymous: false)`.
typedef AccountSwitchBackfill = Future<void> Function(String targetUid);

/// Production: remove [AccountSwitchJournal.reconciliationStorageKey] from
/// `SharedPreferences`.
typedef AccountSwitchJournalCleaner = Future<void> Function();

String _defaultOperationId() => const Uuid().v4();

int _defaultNowMillis() => DateTime.now().millisecondsSinceEpoch;

/// Replaces the old isolated-app "replacement" machinery: when linking a
/// Google/Apple credential collides with an existing durable account, this
/// coordinator signs the ONE primary `FirebaseAuth` instance into that
/// existing account (the standard Firebase pattern) and then merges this
/// device's local progress into the target account's cloud data using the
/// existing [AccountReconciliationCoordinator].
///
/// Every Firebase/Firestore/Auth/SharedPreferences call reaches this class
/// only through the constructor seams above — production wiring (binding
/// those seams to real services) is a separate concern.
class AccountSwitchCoordinator {
  AccountSwitchCoordinator({
    required this.sessions,
    required this.identity,
    required this.journalStore,
    required this.localPreflight,
    required this.ownershipTransition,
    required this.rebindPush,
    required this.reconcile,
    required this.activateBackfill,
    required this.clearReconciliationJournal,
    String Function()? newOperationId,
    int Function()? nowMillis,
  }) : _newOperationId = newOperationId ?? _defaultOperationId,
       _nowMillis = nowMillis ?? _defaultNowMillis;

  final CloudWriteSessionController sessions;
  final AccountSwitchIdentity identity;
  final AccountSwitchJournalStore journalStore;
  final AccountSwitchLocalPreflight localPreflight;
  final AccountSwitchOwnershipTransition ownershipTransition;
  final AccountSwitchPushRebind rebindPush;
  final AccountSwitchReconciler reconcile;
  final AccountSwitchBackfill activateBackfill;
  final AccountSwitchJournalCleaner clearReconciliationJournal;

  final String Function() _newOperationId;
  final int Function() _nowMillis;

  Future<AccountSwitchResult> switchToExisting({
    required AccountLinkProvider provider,
    required AuthCredential credential,
    required String sourceUid,
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    if (sourceUid.isEmpty) {
      AccountFailureDiagnostics.log(
        'switch.guard',
        null,
        detail: 'sourceUid.empty',
      );
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }
    if (identity.currentUid != sourceUid || !identity.currentIsAnonymous) {
      AccountFailureDiagnostics.log(
        'switch.guard',
        null,
        detail: 'identity.mismatch',
      );
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }
    final sourceSession = sessions.current;
    if (sourceSession == null ||
        sourceSession.uid != sourceUid ||
        sourceSession.mode != CloudWriteMode.ready) {
      AccountFailureDiagnostics.log(
        'switch.guard',
        null,
        detail: 'session.notReady',
      );
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }
    final existingJournal = await journalStore.read();
    if (existingJournal != null) {
      AccountFailureDiagnostics.log(
        'switch.guard',
        null,
        detail: 'journal.pending',
      );
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }

    try {
      await localPreflight();
    } on FormatException {
      AccountFailureDiagnostics.log('switch.localPreflight.invalid', null);
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }

    String? targetUid;
    final CloudWriteResult ownershipResult;
    try {
      ownershipResult = await ownershipTransition(
        oldUid: sourceUid,
        transition: () async {
          targetUid = await identity.signInWithCredential(credential);
        },
      );
    } catch (error, stackTrace) {
      if (identity.currentUid == sourceUid) {
        sessions.acquire(sourceUid);
        try {
          await rebindPush();
        } catch (rebindError) {
          AccountFailureDiagnostics.log(
            'switch.rebindPush.failed',
            rebindError,
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (ownershipResult != CloudWriteResult.completed) {
      AccountFailureDiagnostics.log(
        'switch.ownership.${ownershipResult.name}',
        null,
      );
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }

    final resolvedTargetUid = targetUid;
    if (resolvedTargetUid == null ||
        resolvedTargetUid.isEmpty ||
        resolvedTargetUid == sourceUid ||
        identity.currentUid != resolvedTargetUid ||
        identity.currentIsAnonymous) {
      AccountFailureDiagnostics.log('switch.targetInvalid', null);
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }

    final journal = AccountSwitchJournal(
      version: AccountSwitchJournal.currentVersion,
      sourceUid: sourceUid,
      targetUid: resolvedTargetUid,
      provider: provider.name,
      operationId: _newOperationId(),
      createdAtMillis: _nowMillis(),
    );
    await journalStore.write(journal);

    sessions.acquire(resolvedTargetUid);
    final reconciling = sessions.transition(CloudWriteMode.reconciling);

    return _merge(journal, reconciling, catalog);
  }

  Future<AccountSwitchResult> resume({
    required String? liveUid,
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    final journal = await journalStore.read();
    if (journal == null) {
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }
    if (liveUid == null ||
        liveUid != journal.targetUid ||
        identity.currentIsAnonymous) {
      await clearReconciliationJournal();
      await journalStore.clear();
      AccountFailureDiagnostics.log('switch.resume.discarded', null);
      return const AccountSwitchResult(AccountSwitchStatus.failed);
    }

    final current = sessions.current;
    final CloudWriteSession reconciling;
    if (current != null &&
        current.uid == journal.targetUid &&
        current.mode == CloudWriteMode.reconciling) {
      reconciling = current;
    } else if (current == null || current.uid != journal.targetUid) {
      sessions.acquire(journal.targetUid);
      reconciling = sessions.transition(CloudWriteMode.reconciling);
    } else {
      reconciling = sessions.transition(CloudWriteMode.reconciling);
    }

    return _merge(journal, reconciling, catalog);
  }

  Future<AccountSwitchResult> _merge(
    AccountSwitchJournal journal,
    CloudWriteSession session,
    Map<String, PackCatalogEntry> catalog,
  ) async {
    AccountReconciliationResult result;
    try {
      result = await reconcile(
        targetUid: journal.targetUid,
        session: session,
        operationId: journal.operationId,
        catalog: catalog,
      );
    } catch (error) {
      AccountFailureDiagnostics.log('switch.reconcile.threw', error);
      result = const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    }

    switch (result.status) {
      case AccountReconciliationStatus.completed:
      case AccountReconciliationStatus.blocked:
        if (result.status == AccountReconciliationStatus.blocked) {
          AccountFailureDiagnostics.log(
            'switch.mergeBlocked',
            null,
            detail: 'conflicts=${result.conflicts.length}',
          );
        }
        if (sessions.current == session) {
          sessions.transition(CloudWriteMode.ready);
        }
        await clearReconciliationJournal();
        await journalStore.clear();
        try {
          await activateBackfill(journal.targetUid);
        } catch (error) {
          AccountFailureDiagnostics.log('switch.backfill.failed', error);
        }
        return AccountSwitchResult(
          AccountSwitchStatus.completed,
          targetUid: journal.targetUid,
        );
      case AccountReconciliationStatus.unavailable:
      case AccountReconciliationStatus.invalid:
      case AccountReconciliationStatus.tooLarge:
      case AccountReconciliationStatus.stale:
        AccountFailureDiagnostics.log(
          'switch.mergeDeferred',
          null,
          detail: result.status.name,
        );
        return AccountSwitchResult(
          AccountSwitchStatus.mergeDeferred,
          targetUid: journal.targetUid,
        );
    }
  }
}
