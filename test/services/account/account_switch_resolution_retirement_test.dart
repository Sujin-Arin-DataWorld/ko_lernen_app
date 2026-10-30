import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'support/account_switch_resolution_harness.dart';

Future<ResolutionHarness> _pending({bool? started = false}) async {
  final h = ResolutionHarness(initialWriteStarted: started)
    ..reconcileResult = const AccountReconciliationResult(
      AccountReconciliationStatus.unavailable,
    );
  final initial = (await h.transitions.read())!;
  await h.transitions.write(
    initial.copyWith(
      reconciliationLocalCustomPackBaseIds: {'retained-source-pack'},
    ),
  );
  final preview = await h.coordinator.previewPendingSwitchResolution();
  expect(preview.status, AccountSwitchResolutionPreviewStatus.ready);
  await h.coordinator.confirmPendingSwitchResolution(
    preview: preview.preview!,
    side: AccountSwitchResolutionSide.cloud,
  );
  expect((await h.transitions.read())?.switchResolutionConsent, isNotNull);
  return h;
}

void main() {
  test(
    'attempted and legacy unknown latches cannot be downgraded by journal copying',
    () {
      final attempted = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'target-owner',
          epoch: 2,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'switch-resolution-op',
        resolutionRemoteWriteStarted: true,
      );
      expect(
        () => attempted.copyWith(resolutionRemoteWriteStarted: false),
        throwsFormatException,
      );
      final legacy = AccountTransitionJournal.fromJson(
        attempted.toJson()..remove('resolutionRemoteWriteStarted'),
      );
      expect(legacy.resolutionRemoteWriteStarted, isNot(false));
      expect(
        () => legacy.copyWith(resolutionRemoteWriteStarted: false),
        throwsFormatException,
      );
    },
  );

  test(
    'a malformed persisted write-attempt latch is rejected rather than treated as false',
    () {
      final journal = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'target-owner',
          epoch: 2,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'switch-resolution-op',
      );
      final raw = journal.toJson()..['resolutionRemoteWriteStarted'] = 'false';
      expect(
        () => AccountTransitionJournal.fromJson(raw),
        throwsFormatException,
      );
    },
  );

  test(
    'a genuinely new switch durably records never attempted before a failed first read',
    () async {
      final sessions = CloudWriteSessionController()..acquire('device-owner');
      final identity = _NewSwitchIdentity();
      final markers = ResolutionSwitchStore()..value = null;
      final journals = ResolutionTransitionStore();
      var remoteWrites = 0;
      final coordinator = AccountSwitchCoordinator(
        sessions: sessions,
        identity: identity,
        journalStore: markers,
        reconciliationJournalStore: journals,
        localPreflight: () async {},
        ownershipTransition: ({required oldUid, required transition}) async {
          await transition();
          return CloudWriteResult.completed;
        },
        rebindPush: () async {},
        activateBackfill: (_) async {
          fail('No ready activation.');
        },
        clearReconciliationJournal: () async {
          fail('Journal must remain.');
        },
        reconcile:
            ({
              required targetUid,
              required session,
              required operationId,
              required catalog,
            }) =>
                AccountReconciliationCoordinator(
                  sessions: sessions,
                  journalStore: journals,
                  readRemote: () async {
                    throw StateError('offline before any CAS');
                  },
                  loadLocal: () =>
                      throw StateError('Read failure must stop first'),
                  writeRemote:
                      (
                        snapshot, {
                        required expectedRevision,
                        required operationId,
                      }) async {
                        remoteWrites++;
                        return const ReconciliationWriteResult.committed(
                          revision: 1,
                        );
                      },
                  writeLocal: (_, {required session, required sessions}) async {
                    fail('No local apply.');
                  },
                ).reconcile(
                  session: session,
                  operationId: operationId,
                  catalog: catalog,
                ),
      );
      final result = await coordinator.switchToExisting(
        provider: AccountLinkProvider.google,
        credential: GoogleAuthProvider.credential(
          idToken: 'offline-fixture-token',
        ),
        sourceUid: 'device-owner',
        catalog: {},
      );
      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect(remoteWrites, 0);
      expect((await journals.read())!.resolutionRemoteWriteStarted, isFalse);
      expect(jsonDecode(journals.raw!)['resolutionRemoteWriteStarted'], false);
    },
  );

  for (final started in <bool?>[false, true, null]) {
    test(
      'issuing consent preserves operation attempt knowledge started=$started',
      () async {
        final h = await _pending(started: started);
        final journal = (await h.transitions.read())!;
        if (started == false) {
          expect(journal.resolutionRemoteWriteStarted, isFalse);
        } else {
          expect(journal.resolutionRemoteWriteStarted, isNot(false));
        }
        expect(journal.reconciliationOperationId, 'switch-resolution-op');
        expect(h.backfills + h.clears, 0);
      },
    );
  }

  for (final drift in ['device', 'cloud', 'catalog']) {
    test(
      'explicit resume retires only never-attempted stale consent after $drift drift',
      () async {
        final h = await _pending();
        final before = (await h.transitions.read())!;
        final marker = h.switches.value;
        final session = h.sessions.current;
        if (drift == 'device') {
          h.device = resolutionSnapshot('a1', xp: 1);
        }
        if (drift == 'cloud') {
          h.cloud = resolutionSnapshot('a2', xp: 18);
          h.remoteRevision++;
        }
        if (drift == 'catalog') {
          h.catalogFingerprint = AccountSwitchResolutionFingerprint.hash(
            'new-catalog',
          );
        }
        final result = await h.coordinator.resumePendingSwitchResolution();
        expect(result, AccountSwitchResolutionOutcome.stale);
        final after = (await h.transitions.read())!;
        expect(after.switchResolutionConsent, isNull);
        expect(after.resolutionRemoteWriteStarted, isFalse);
        expect(after.session, before.session);
        expect(
          after.reconciliationOperationId,
          before.reconciliationOperationId,
        );
        expect(
          after.reconciliationLocalCustomPackBaseIds,
          before.reconciliationLocalCustomPackBaseIds,
        );
        expect(h.switches.value, marker);
        expect(h.sessions.current, session);
        expect(h.sessions.current?.mode, CloudWriteMode.reconciling);
        expect(
          h.reconciles,
          1,
          reason: 'Retirement must not merge or apply either snapshot.',
        );
        expect(h.backfills + h.clears + h.switches.clears, 0);
        final fresh = await h.coordinator.previewPendingSwitchResolution();
        expect(fresh.status, AccountSwitchResolutionPreviewStatus.ready);
      },
    );
  }

  for (final started in <bool?>[true, null]) {
    test(
      'attempted or legacy unknown operation is never retired started=$started',
      () async {
        final h = await _pending(started: started);
        h.device = resolutionSnapshot('a1', xp: 1);
        final raw = h.transitions.raw;
        final result = await h.coordinator.resumePendingSwitchResolution();
        expect(result, AccountSwitchResolutionOutcome.blocked);
        expect(h.transitions.raw, raw);
        expect(h.backfills + h.clears, 0);
      },
    );
  }

  for (final evidence in [
    AccountSwitchCommitEvidence.sameOperationObserved,
    AccountSwitchCommitEvidence.unavailable,
  ]) {
    test(
      'receipt evidence $evidence denies retirement even with durable false',
      () async {
        final h = await _pending();
        h.device = resolutionSnapshot('a1', xp: 1);
        h.commitEvidence = evidence;
        final raw = h.transitions.raw;
        expect(
          await h.coordinator.resumePendingSwitchResolution(),
          AccountSwitchResolutionOutcome.blocked,
        );
        expect(h.transitions.raw, raw);
        expect(h.evidenceReads, 1);
        expect(h.backfills + h.clears, 0);
      },
    );
  }

  for (final drift in [
    'uid',
    'sameUid',
    'aba',
    'permission',
    'reset',
    'marker',
  ]) {
    test('$drift during fresh read denies stale-consent retirement', () async {
      final h = await _pending();
      h.device = resolutionSnapshot('a1', xp: 1);
      final raw = h.transitions.raw;
      h.beforeRead = () async {
        switch (drift) {
          case 'uid':
            h.identity.currentUid = 'foreign-owner';
          case 'sameUid':
            h.sessions.acquire('target-owner');
          case 'aba':
            h.sessions.acquire('other');
            h.sessions.acquire('target-owner');
          case 'permission':
            h.sessions.transition(CloudWriteMode.quiesced);
          case 'reset':
            LocalDataLifetime.invalidate();
          case 'marker':
            h.switches.value = null;
        }
      };
      expect(
        await h.coordinator.resumePendingSwitchResolution(),
        AccountSwitchResolutionOutcome.stale,
      );
      expect(h.transitions.raw, raw);
      expect(h.reconciles, 1);
      expect(h.backfills + h.clears, 0);
    });
  }

  test(
    'preview never retires stale never-attempted consent or reads commit evidence',
    () async {
      final h = await _pending();
      h.device = resolutionSnapshot('a1', xp: 1);
      final raw = h.transitions.raw;
      final reads = h.reads;
      final result = await h.coordinator.previewPendingSwitchResolution();
      expect(
        result.status,
        AccountSwitchResolutionPreviewStatus.resumeRequired,
      );
      expect(h.transitions.raw, raw);
      expect(h.reads, reads);
      expect(h.evidenceReads, 0);
    },
  );

  test(
    'journal replacement during commit-evidence read denies retirement',
    () async {
      final h = await _pending();
      h.device = resolutionSnapshot('a1', xp: 1);
      h.beforeEvidenceRead = () async {
        final journal = (await h.transitions.read())!;
        await h.transitions.write(journal.copyWith(remoteRevision: 999));
      };
      expect(
        await h.coordinator.resumePendingSwitchResolution(),
        AccountSwitchResolutionOutcome.stale,
      );
      final journal = (await h.transitions.read())!;
      expect(journal.switchResolutionConsent, isNotNull);
      expect(journal.remoteRevision, 999);
      expect(h.reconciles, 1);
    },
  );

  test(
    'marker replacement at journal CAS admission denies retirement',
    () async {
      final h = await _pending();
      h.device = resolutionSnapshot('a1', xp: 1);
      final raw = h.transitions.raw;
      h.transitions.beforeCompareAndSwap = () async {
        h.switches.value = null;
      };
      expect(
        await h.coordinator.resumePendingSwitchResolution(),
        AccountSwitchResolutionOutcome.stale,
      );
      expect(h.transitions.raw, raw);
      expect(h.reconciles, 1);
      expect(h.backfills + h.clears, 0);
    },
  );
}

class _NewSwitchIdentity implements AccountSwitchIdentity {
  @override
  String? currentUid = 'device-owner';
  @override
  bool currentIsAnonymous = true;
  @override
  Future<String> signInWithCredential(AuthCredential credential) async {
    currentUid = 'target-owner';
    currentIsAnonymous = false;
    return currentUid!;
  }
}
