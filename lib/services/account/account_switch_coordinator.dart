import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' show AuthCredential;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/learner_level.dart';
import '../pack_progress_service.dart';
import '../local_data_lifetime.dart';
import 'account_failure_diagnostics.dart';
import 'account_reconciliation.dart';
import 'account_switch_resolution.dart';
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
      throw const FormatException('Invalid account switch journal sourceUid.');
    }
    final targetUid = json['targetUid'];
    if (targetUid is! String || targetUid.isEmpty) {
      throw const FormatException('Invalid account switch journal targetUid.');
    }
    final provider = json['provider'];
    if (provider is! String || provider.isEmpty) {
      throw const FormatException('Invalid account switch journal provider.');
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
  SharedPreferencesAccountSwitchJournalStore(
    this.preferences, {
    this.preserveMalformed = false,
  });

  final SharedPreferences preferences;
  final bool preserveMalformed;

  /// Synchronous guard after the transition store reloads shared preferences.
  /// It performs no cleanup and rejects malformed or replaced markers.
  bool isCurrent(AccountSwitchJournal expected) {
    try {
      final raw = preferences.getString(AccountSwitchJournal.storageKey);
      if (raw == null) {
        return false;
      }
      final decoded = jsonDecode(raw);
      return decoded is Map &&
          AccountSwitchJournal.fromJson(
                decoded.map((key, value) => MapEntry(key.toString(), value)),
              ) ==
              expected;
    } catch (_) {
      return false;
    }
  }

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
      if (preserveMalformed) {
        rethrow;
      }
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
    this.reconciliationJournalStore,
    this.readResolutionInputs,
    this.buildResolutionCandidate,
    this.readCommitEvidence,
    this.isSwitchMarkerCurrent,
    this.resolutionCatalog = const {},
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
  final AccountTransitionJournalStore? reconciliationJournalStore;
  final AccountSwitchResolutionInputsReader? readResolutionInputs;
  final AccountSwitchResolutionCandidateBuilder? buildResolutionCandidate;
  final AccountSwitchCommitEvidenceReader? readCommitEvidence;
  final bool Function(AccountSwitchJournal marker)? isSwitchMarkerCurrent;
  final Map<String, PackCatalogEntry> resolutionCatalog;
  final AccountSwitchLocalPreflight localPreflight;
  final AccountSwitchOwnershipTransition ownershipTransition;
  final AccountSwitchPushRebind rebindPush;
  final AccountSwitchReconciler reconcile;
  final AccountSwitchBackfill activateBackfill;
  final AccountSwitchJournalCleaner clearReconciliationJournal;

  final String Function() _newOperationId;
  final int Function() _nowMillis;

  bool _confirmingResolution = false;

  /// Only this explicit user action may retire stale, provably unattempted
  /// consent. Startup and preview retain their read/resume-only contracts.
  Future<AccountSwitchResolutionOutcome> resumePendingSwitchResolution() async {
    final session = sessions.current;
    final epoch = sessions.identityEpoch;
    final lifetime = LocalDataLifetime.capture();
    if (session == null ||
        session.mode != CloudWriteMode.reconciling ||
        identity.currentUid != session.uid ||
        identity.currentIsAnonymous ||
        reconciliationJournalStore == null) {
      return AccountSwitchResolutionOutcome.blocked;
    }
    bool owned() =>
        lifetime.isCurrent &&
        sessions.current == session &&
        sessions.identityEpoch == epoch &&
        identity.currentUid == session.uid &&
        !identity.currentIsAnonymous;
    try {
      final marker = await journalStore.read();
      final journal = await reconciliationJournalStore!.read();
      if (!owned()) {
        return AccountSwitchResolutionOutcome.stale;
      }
      final consent = journal?.switchResolutionConsent;
      if (marker == null ||
          marker.targetUid != session.uid ||
          journal == null ||
          journal.session != session ||
          journal.reconciliationOperationId != marker.operationId ||
          consent == null ||
          journal.replacementProvider != null) {
        return AccountSwitchResolutionOutcome.blocked;
      }
      final expectedJournal = jsonEncode(journal.toJson());
      Future<bool> stillOwned() async =>
          owned() &&
          await journalStore.read() == marker &&
          owned() &&
          jsonEncode((await reconciliationJournalStore!.read())?.toJson()) ==
              expectedJournal &&
          owned();
      if (!await stillOwned()) {
        return AccountSwitchResolutionOutcome.stale;
      }
      if (journal.resolutionRemoteWriteStarted == false) {
        if (readResolutionInputs == null ||
            readCommitEvidence == null ||
            isSwitchMarkerCurrent == null ||
            journal.reconciliationCheckpoint ==
                ReconciliationCheckpoint.remoteWritten ||
            journal.reconciliationCheckpoint ==
                ReconciliationCheckpoint.localWritten ||
            journal.reconciliationCheckpoint ==
                ReconciliationCheckpoint.completed) {
          return AccountSwitchResolutionOutcome.blocked;
        }
        final inputs = await readResolutionInputs!();
        if (!await stillOwned()) {
          return AccountSwitchResolutionOutcome.stale;
        }
        final drifted =
            inputs.catalogFingerprint != consent.catalogFingerprint ||
            AccountSwitchResolutionFingerprint.snapshot(inputs.device) !=
                consent.deviceFingerprint ||
            AccountSwitchResolutionFingerprint.snapshot(inputs.cloud) !=
                consent.cloudFingerprint ||
            !mapEquals(
              AccountSwitchResolutionFingerprint.fences(
                inputs.cloud,
                inputs.remoteRevision,
              ),
              consent.cloudFences,
            );
        if (drifted) {
          final evidence = await readCommitEvidence!(
            operationId: marker.operationId,
          );
          if (!await stillOwned()) {
            return AccountSwitchResolutionOutcome.stale;
          }
          if (evidence != AccountSwitchCommitEvidence.notObserved) {
            return AccountSwitchResolutionOutcome.blocked;
          }
          final retired = await reconciliationJournalStore!.writeIfCurrent(
            expected: journal,
            next: journal.copyWith(clearSwitchResolutionConsent: true),
            isCurrent: () => owned() && isSwitchMarkerCurrent!(marker),
          );
          // Retirement leaves the operation and ready-write fence intact.
          if (!retired || !owned()) {
            return AccountSwitchResolutionOutcome.stale;
          }
          return AccountSwitchResolutionOutcome.stale;
        }
      }
      // Attempted and legacy-unknown operations only use exact durable resume.
      if (!await stillOwned()) {
        return AccountSwitchResolutionOutcome.stale;
      }
      final result = await resume(
        liveUid: session.uid,
        catalog: resolutionCatalog,
      );
      return result.status == AccountSwitchStatus.completed
          ? AccountSwitchResolutionOutcome.completed
          : AccountSwitchResolutionOutcome.blocked;
    } on FormatException {
      return AccountSwitchResolutionOutcome.blocked;
    } catch (_) {
      return AccountSwitchResolutionOutcome.unavailable;
    }
  }

  Future<AccountSwitchResolutionPreviewResult>
  previewPendingSwitchResolution() async {
    final epoch = sessions.identityEpoch;
    final session = sessions.current;
    final lifetime = LocalDataLifetime.capture();
    bool owned() =>
        lifetime.isCurrent &&
        sessions.identityEpoch == epoch &&
        sessions.current == session &&
        session != null &&
        session.mode == CloudWriteMode.reconciling &&
        identity.currentUid == session.uid &&
        !identity.currentIsAnonymous;
    if (!owned() ||
        readResolutionInputs == null ||
        buildResolutionCandidate == null) {
      return const AccountSwitchResolutionPreviewResult(
        AccountSwitchResolutionPreviewStatus.blocked,
      );
    }
    try {
      final marker = await journalStore.read();
      final journal = await reconciliationJournalStore?.read();
      if (!owned()) {
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.stale,
        );
      }
      if (marker == null ||
          marker.targetUid != session!.uid ||
          journal == null ||
          journal.session != session ||
          journal.reconciliationOperationId != marker.operationId ||
          journal.replacementProvider != null) {
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.blocked,
        );
      }
      if (journal.switchResolutionConsent != null) {
        journal.switchResolutionConsent!.validate();
        if (await journalStore.read() != marker || !owned()) {
          return const AccountSwitchResolutionPreviewResult(
            AccountSwitchResolutionPreviewStatus.stale,
          );
        }
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.resumeRequired,
        );
      }
      final inputs = await readResolutionInputs!();
      if (!owned() ||
          await journalStore.read() != marker ||
          !owned() ||
          jsonEncode((await reconciliationJournalStore!.read())?.toJson()) !=
              jsonEncode(journal.toJson()) ||
          !owned()) {
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.stale,
        );
      }
      final deviceLevel = LearnerLevel.fromCode(
        inputs.device.courseMastery?.placementLevel,
      );
      final cloudLevel = LearnerLevel.fromCode(
        inputs.cloud.courseMastery?.placementLevel,
      );
      if (deviceLevel == null ||
          cloudLevel == null ||
          deviceLevel == cloudLevel) {
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.blocked,
        );
      }
      final candidates = <AccountSwitchResolutionSide, String>{};
      for (final side in AccountSwitchResolutionSide.values) {
        final candidate = buildResolutionCandidate!(inputs: inputs, side: side);
        if (candidate != null) {
          candidates[side] = AccountSwitchResolutionFingerprint.snapshot(
            candidate,
          );
        }
      }
      if (candidates.isEmpty) {
        return const AccountSwitchResolutionPreviewResult(
          AccountSwitchResolutionPreviewStatus.blocked,
        );
      }
      final binding = _ResolutionBinding(
        owner: this,
        marker: marker,
        journal: jsonEncode(journal.toJson()),
        session: session,
        identityEpoch: epoch,
        lifetime: lifetime,
        exactInputs: AccountSwitchResolutionFingerprint.exact(inputs),
        candidates: candidates,
      );
      final preview = AccountSwitchResolutionPreview(
        devicePlacementLevel: deviceLevel.code,
        cloudPlacementLevel: cloudLevel.code,
        deviceCompletedUnitCount:
            inputs.device.courseMastery!.completedUnitIds.length,
        cloudCompletedUnitCount:
            inputs.cloud.courseMastery!.completedUnitIds.length,
        canChooseDevice: candidates.containsKey(
          AccountSwitchResolutionSide.device,
        ),
        canChooseCloud: candidates.containsKey(
          AccountSwitchResolutionSide.cloud,
        ),
        binding: binding,
      );
      binding.preview = preview;
      return AccountSwitchResolutionPreviewResult(
        AccountSwitchResolutionPreviewStatus.ready,
        preview: preview,
      );
    } on FormatException {
      return const AccountSwitchResolutionPreviewResult(
        AccountSwitchResolutionPreviewStatus.blocked,
      );
    } catch (_) {
      return const AccountSwitchResolutionPreviewResult(
        AccountSwitchResolutionPreviewStatus.unavailable,
      );
    }
  }

  Future<AccountSwitchResolutionOutcome> confirmPendingSwitchResolution({
    required AccountSwitchResolutionPreview preview,
    required AccountSwitchResolutionSide side,
  }) async {
    final binding = preview.binding;
    if (binding is! _ResolutionBinding ||
        !identical(binding.owner, this) ||
        !identical(binding.preview, preview) ||
        !binding.candidates.containsKey(side)) {
      return AccountSwitchResolutionOutcome.blocked;
    }
    bool owned() =>
        !binding.consumed &&
        binding.lifetime.isCurrent &&
        sessions.identityEpoch == binding.identityEpoch &&
        sessions.current == binding.session &&
        identity.currentUid == binding.session.uid &&
        !identity.currentIsAnonymous;
    if (_confirmingResolution || !owned()) {
      return AccountSwitchResolutionOutcome.stale;
    }
    _confirmingResolution = true;
    try {
      final marker = await journalStore.read();
      final journal = await reconciliationJournalStore?.read();
      if (!owned() ||
          marker != binding.marker ||
          journal == null ||
          jsonEncode(journal.toJson()) != binding.journal) {
        return AccountSwitchResolutionOutcome.stale;
      }
      final inputs = await readResolutionInputs!();
      if (!owned() ||
          AccountSwitchResolutionFingerprint.exact(inputs) !=
              binding.exactInputs ||
          await journalStore.read() != marker ||
          !owned()) {
        return AccountSwitchResolutionOutcome.stale;
      }
      final candidate = buildResolutionCandidate!(inputs: inputs, side: side);
      if (candidate == null ||
          AccountSwitchResolutionFingerprint.snapshot(candidate) !=
              binding.candidates[side]) {
        return AccountSwitchResolutionOutcome.stale;
      }
      final consent = AccountSwitchResolutionConsent(
        side: side,
        selectedPlacementLevel: side == AccountSwitchResolutionSide.device
            ? preview.devicePlacementLevel
            : preview.cloudPlacementLevel,
        catalogFingerprint: inputs.catalogFingerprint,
        deviceFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          inputs.device,
        ),
        cloudFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          inputs.cloud,
        ),
        candidateFingerprint: binding.candidates[side]!,
        deviceComponents: AccountSwitchResolutionFingerprint.components(
          inputs.device,
        ),
        cloudComponents: AccountSwitchResolutionFingerprint.components(
          inputs.cloud,
        ),
        candidateComponents: AccountSwitchResolutionFingerprint.components(
          candidate,
        ),
        cloudFences: AccountSwitchResolutionFingerprint.fences(
          inputs.cloud,
          inputs.remoteRevision,
        ),
      );
      final written = await reconciliationJournalStore!.writeIfCurrent(
        expected: journal,
        next: journal.copyWith(switchResolutionConsent: consent),
        isCurrent: owned,
      );
      if (!written || !owned()) {
        return AccountSwitchResolutionOutcome.stale;
      }
      binding.consumed = true;
      final result = await _merge(marker!, binding.session, resolutionCatalog);
      return result.status == AccountSwitchStatus.completed
          ? AccountSwitchResolutionOutcome.completed
          : AccountSwitchResolutionOutcome.blocked;
    } on FormatException {
      return AccountSwitchResolutionOutcome.blocked;
    } catch (_) {
      return AccountSwitchResolutionOutcome.unavailable;
    } finally {
      _confirmingResolution = false;
    }
  }

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

    // Only this freshly generated operation has proven never-attempted state.
    // A missing journal for an older operation cannot acquire that knowledge.
    final reconciliationStore = reconciliationJournalStore;
    if (reconciliationStore != null) {
      final identityEpoch = sessions.identityEpoch;
      final initial = AccountTransitionJournal.fromSession(
        reconciling,
        reconciliationOperationId: journal.operationId,
        resolutionRemoteWriteStarted: false,
      );
      try {
        final recorded = await reconciliationStore.restoreIfAbsent(
          expected: initial,
          isCurrent: () =>
              sessions.current == reconciling &&
              sessions.identityEpoch == identityEpoch &&
              identity.currentUid == resolvedTargetUid &&
              !identity.currentIsAnonymous &&
              (isSwitchMarkerCurrent?.call(journal) ?? true),
        );
        if (!recorded) {
          return AccountSwitchResult(
            AccountSwitchStatus.mergeDeferred,
            targetUid: resolvedTargetUid,
          );
        }
      } catch (_) {
        return AccountSwitchResult(
          AccountSwitchStatus.mergeDeferred,
          targetUid: resolvedTargetUid,
        );
      }
    }

    return _merge(journal, reconciling, catalog);
  }

  Future<AccountSwitchResult> resume({
    required String? liveUid,
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    final identityEpoch = sessions.identityEpoch;
    final initialSession = sessions.current;
    AccountSwitchJournal? journal;
    AccountTransitionJournal? reconciliationJournal;
    bool ownsIdentity() =>
        liveUid != null &&
        identity.currentUid == liveUid &&
        !identity.currentIsAnonymous &&
        sessions.identityEpoch == identityEpoch &&
        sessions.current == initialSession;
    try {
      journal = await journalStore.read();
      if (journal == null) {
        return const AccountSwitchResult(AccountSwitchStatus.failed);
      }
      if (!ownsIdentity() || liveUid != journal.targetUid) {
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
      if (!ownsIdentity() ||
          await journalStore.read() != journal ||
          !ownsIdentity()) {
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
      if (initialSession?.mode == CloudWriteMode.ready) {
        // The pending switch still owns these local payloads. Do not leave an
        // ordinary-backup lease open while its durable session is unresolved.
        sessions.transition(CloudWriteMode.blocked);
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
      reconciliationJournal = await reconciliationJournalStore?.read();
      if (!ownsIdentity() ||
          await journalStore.read() != journal ||
          !ownsIdentity()) {
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
    } catch (_) {
      return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
    }
    if (reconciliationJournal != null) {
      final persisted = reconciliationJournal;
      if (persisted.session.uid != journal.targetUid ||
          persisted.session.mode != CloudWriteMode.reconciling ||
          persisted.reconciliationOperationId != journal.operationId ||
          persisted.replacementProvider != null ||
          persisted.replacementTargetUid != null ||
          persisted.replacementRequestKey != null ||
          persisted.replacementPhase != null ||
          persisted.replacementOperationId != null ||
          persisted.replacementOperationVersion != null) {
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
      try {
        // Restore only this validated durable operation. The controller rejects
        // a different current session or an epoch older than its own history.
        sessions.resume(persisted.session, expectedUid: journal.targetUid);
        if (sessions.current != persisted.session ||
            sessions.identityEpoch !=
                identityEpoch + (initialSession == null ? 1 : 0) ||
            identity.currentUid != liveUid ||
            identity.currentIsAnonymous) {
          return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
        }
      } catch (_) {
        return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
      }
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

    if (sessions.current != reconciling ||
        identity.currentUid != liveUid ||
        identity.currentIsAnonymous) {
      return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
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
        if (sessions.current != session ||
            identity.currentUid != journal.targetUid ||
            identity.currentIsAnonymous ||
            await journalStore.read() != journal ||
            sessions.current != session) {
          return const AccountSwitchResult(AccountSwitchStatus.mergeDeferred);
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
      case AccountReconciliationStatus.blocked:
        // A blocked merge has not applied a cloud-authoritative snapshot.
        // Keep recovery authority closed to ordinary backups until a later
        // reconciliation actually completes.
        if (result.status == AccountReconciliationStatus.blocked) {
          AccountFailureDiagnostics.log(
            'switch.mergeBlocked',
            null,
            detail: 'conflicts=${result.conflicts.length}',
          );
        }
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

class _ResolutionBinding {
  _ResolutionBinding({
    required this.owner,
    required this.marker,
    required this.journal,
    required this.session,
    required this.identityEpoch,
    required this.lifetime,
    required this.exactInputs,
    required this.candidates,
  });
  final AccountSwitchCoordinator owner;
  final AccountSwitchJournal marker;
  final String journal;
  final CloudWriteSession session;
  final int identityEpoch;
  final LocalDataLifetimeLease lifetime;
  final String exactInputs;
  final Map<AccountSwitchResolutionSide, String> candidates;
  AccountSwitchResolutionPreview? preview;
  bool consumed = false;
}
