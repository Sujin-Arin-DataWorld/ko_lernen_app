import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

AccountReconciliationSnapshot resolutionSnapshot(
  String placement, {
  int xp = 0,
}) => AccountReconciliationSnapshot(
  fields: {
    'progress': {'xp': xp},
  },
  srsCards: {},
  customPacks: {},
  packProgress: {},
  courseMastery: CourseMasterySnapshot(placementLevel: placement),
);

class ResolutionIdentity implements AccountSwitchIdentity {
  @override
  String? currentUid = 'target-owner';
  @override
  bool currentIsAnonymous = false;
  @override
  Future<String> signInWithCredential(AuthCredential credential) =>
      throw StateError('Resolution must never sign in.');
}

class ResolutionSwitchStore implements AccountSwitchJournalStore {
  AccountSwitchJournal? value = const AccountSwitchJournal(
    version: 1,
    sourceUid: 'device-owner',
    targetUid: 'target-owner',
    provider: 'google',
    operationId: 'switch-resolution-op',
    createdAtMillis: 1,
  );
  int writes = 0;
  int clears = 0;
  @override
  Future<AccountSwitchJournal?> read() async => value;
  @override
  Future<void> write(AccountSwitchJournal journal) async {
    writes++;
    value = journal;
  }

  @override
  Future<void> clear() async {
    clears++;
    value = null;
  }
}

class ResolutionTransitionStore implements AccountTransitionJournalStore {
  String? raw;
  int writes = 0;
  bool rejectWriteStarted = false;
  Future<void> Function()? beforeCompareAndSwap;
  @override
  Future<AccountTransitionJournal?> read() async => raw == null
      ? null
      : AccountTransitionJournal.fromJson(
          jsonDecode(raw!) as Map<String, dynamic>,
        );
  @override
  Future<void> write(AccountTransitionJournal journal) async {
    if (rejectWriteStarted && journal.resolutionRemoteWriteStarted == true) {
      throw StateError('Native latch persistence failed.');
    }
    writes++;
    raw = jsonEncode(journal.toJson());
  }

  @override
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) async {
    await beforeCompareAndSwap?.call();
    if (!isCurrent() || raw != jsonEncode(expected.toJson())) {
      return false;
    }
    await write(next);
    return true;
  }

  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent() || raw != null) {
      return false;
    }
    await write(expected);
    return true;
  }
}

/// Tests the real owner coordinator; native I/O and the separately tested
/// pure domain candidate builder are deterministic seams, not account policy.
class ResolutionHarness {
  ResolutionHarness({
    AccountSwitchResolutionCandidateBuilder? candidateBuilder,
    bool? initialWriteStarted = false,
  }) {
    sessions.acquire('target-owner');
    sessions.transition(CloudWriteMode.reconciling);
    transitions.raw = jsonEncode(
      AccountTransitionJournal.fromSession(
        sessions.current!,
        reconciliationOperationId: 'switch-resolution-op',
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        resolutionRemoteWriteStarted: initialWriteStarted,
      ).toJson(),
    );
    coordinator = AccountSwitchCoordinator(
      sessions: sessions,
      identity: identity,
      journalStore: switches,
      isSwitchMarkerCurrent: (marker) => switches.value == marker,
      reconciliationJournalStore: transitions,
      readCommitEvidence: ({required operationId}) async {
        evidenceReads++;
        await beforeEvidenceRead?.call();
        return commitEvidence;
      },
      readResolutionInputs: () async {
        reads++;
        await beforeRead?.call();
        return AccountSwitchResolutionInputs(
          device: device,
          cloud: cloud,
          catalogFingerprint: catalogFingerprint,
          remoteRevision: remoteRevision,
        );
      },
      buildResolutionCandidate:
          candidateBuilder ??
          ({required inputs, required side}) {
            if ((side == AccountSwitchResolutionSide.device && !allowDevice) ||
                (side == AccountSwitchResolutionSide.cloud && !allowCloud)) {
              return null;
            }
            return resolutionSnapshot(
              side == AccountSwitchResolutionSide.device
                  ? inputs.device.courseMastery!.placementLevel!
                  : inputs.cloud.courseMastery!.placementLevel!,
              xp: 17,
            );
          },
      localPreflight: () async {
        throw StateError('Preview must not migrate.');
      },
      ownershipTransition: ({required oldUid, required transition}) async {
        throw StateError('Resolution must retain current identity.');
      },
      rebindPush: () async {
        throw StateError('No preview push rebind.');
      },
      reconcile:
          ({
            required targetUid,
            required session,
            required operationId,
            required catalog,
          }) async {
            reconciles++;
            consentAtReconcile =
                (await transitions.read())?.switchResolutionConsent;
            writeStartedAtReconcile =
                (await transitions.read())?.resolutionRemoteWriteStarted;
            return reconcileResult;
          },
      activateBackfill: (_) async {
        backfills++;
      },
      clearReconciliationJournal: () async {
        transitions.raw = null;
        clears++;
      },
    );
  }
  final sessions = CloudWriteSessionController();
  final identity = ResolutionIdentity();
  final switches = ResolutionSwitchStore();
  final transitions = ResolutionTransitionStore();
  late final AccountSwitchCoordinator coordinator;
  AccountReconciliationSnapshot device = resolutionSnapshot('a1');
  AccountReconciliationSnapshot cloud = resolutionSnapshot('a2', xp: 17);
  String catalogFingerprint = AccountSwitchResolutionFingerprint.hash(
    'catalog-v1',
  );
  int remoteRevision = 8;
  bool allowDevice = true;
  bool allowCloud = true;
  Future<void> Function()? beforeRead;
  int reads = 0;
  int reconciles = 0;
  int backfills = 0;
  int clears = 0;
  AccountSwitchResolutionConsent? consentAtReconcile;
  bool? writeStartedAtReconcile;
  AccountReconciliationResult reconcileResult =
      const AccountReconciliationResult(AccountReconciliationStatus.completed);
  AccountSwitchCommitEvidence commitEvidence =
      AccountSwitchCommitEvidence.notObserved;
  int evidenceReads = 0;
  Future<void> Function()? beforeEvidenceRead;
}
