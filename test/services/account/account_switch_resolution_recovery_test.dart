import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/account_switch_resolution_harness.dart';

String _hash(String char) => List.filled(64, char).join();

AccountSwitchResolutionConsent _consent() => AccountSwitchResolutionConsent(
  side: AccountSwitchResolutionSide.cloud,
  selectedPlacementLevel: 'a2',
  catalogFingerprint: _hash('a'),
  deviceFingerprint: AccountSwitchResolutionFingerprint.hash({
    'fields': _hash('b'),
    'courseMastery': _hash('b'),
  }),
  cloudFingerprint: AccountSwitchResolutionFingerprint.hash({
    'fields': _hash('c'),
    'courseMastery': _hash('c'),
  }),
  candidateFingerprint: AccountSwitchResolutionFingerprint.hash({
    'fields': _hash('d'),
    'courseMastery': _hash('d'),
  }),
  deviceComponents: {'fields': _hash('b'), 'courseMastery': _hash('b')},
  cloudComponents: {'fields': _hash('c'), 'courseMastery': _hash('c')},
  candidateComponents: {'fields': _hash('d'), 'courseMastery': _hash('d')},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final tagged in ['root', 'membership', 'pack']) {
    test(
      'raw $tagged same-operation receipt prevents a no-commit evidence result',
      () async {
        final h = _PartialCommitHarness('never');
        await h.prepare();
        final data = switch (tagged) {
          'root' => h.root,
          'membership' => h.membership,
          _ => h.pack,
        };
        data['reconciliation_operation_id'] = 'switch-resolution-op';
        expect(
          await h.adapter().readResolutionCommitEvidence(
            operationId: 'switch-resolution-op',
          ),
          AccountSwitchCommitEvidence.sameOperationObserved,
        );
        expect(h.rootCommits + h.packCommits + h.localCommits, 0);
      },
    );
  }

  test(
    'raw receipt absence is a distinct observation, never an inferred committed result',
    () async {
      final h = _PartialCommitHarness('never');
      await h.prepare();
      expect(
        await h.adapter().readResolutionCommitEvidence(
          operationId: 'switch-resolution-op',
        ),
        AccountSwitchCommitEvidence.notObserved,
      );
      expect(h.rootCommits + h.packCommits + h.localCommits, 0);
    },
  );

  test(
    'malformed raw receipt metadata denies commit evidence admission',
    () async {
      final h = _PartialCommitHarness('never');
      await h.prepare();
      h.root['reconciliation_operation_id'] = 17;
      expect(
        await h.adapter().readResolutionCommitEvidence(
          operationId: 'switch-resolution-op',
        ),
        AccountSwitchCommitEvidence.unavailable,
      );
    },
  );

  test(
    'unavailable raw evidence cannot be reported as receipt absence',
    () async {
      final h = _PartialCommitHarness('never');
      await h.prepare();
      h.failCompositeRead = true;
      expect(
        await h.adapter().readResolutionCommitEvidence(
          operationId: 'switch-resolution-op',
        ),
        AccountSwitchCommitEvidence.unavailable,
      );
    },
  );

  for (final withConsent in [false, true]) {
    test(
      'durable operation latch precedes root CAS withConsent=$withConsent',
      () async {
        final h = _PartialCommitHarness('never')..verifyStartedLatch = true;
        await h.prepare();
        if (!withConsent) {
          final raw = jsonDecode(h.journals.raw!) as Map<String, dynamic>;
          raw.remove('switchResolutionConsent');
          h.journals.raw = jsonEncode(raw);
        }
        final result = await h.owner().resume(
          liveUid: 'target-owner',
          catalog: h.catalog,
        );
        expect(result.status, AccountSwitchStatus.completed);
        expect(h.observedStartedLatch, isTrue);
        expect(h.rootCommits, 1);
      },
    );
  }

  test(
    'failed durable write-attempt latch prevents every root and pack CAS invocation',
    () async {
      final h = _PartialCommitHarness('never');
      await h.prepare();
      h.journals.rejectWriteStarted = true;
      final result = await h.owner().resume(
        liveUid: 'target-owner',
        catalog: h.catalog,
      );
      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect(h.rootCalls, 0);
      expect(h.rootCommits + h.packCommits + h.localCommits + h.backfills, 0);
      expect((await h.journals.read())!.resolutionRemoteWriteStarted, isFalse);
    },
  );

  test(
    'startup preserves stale never-attempted consent without retirement',
    () async {
      final h = _PartialCommitHarness('never');
      await h.prepare();
      h.local = h.snapshot(placement: 'a1', xp: 99, learned: 1, remote: false);
      final raw = h.journals.raw;
      h.sessions = CloudWriteSessionController();
      final result = await h.owner().resume(
        liveUid: 'target-owner',
        catalog: h.catalog,
      );
      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect(h.journals.raw, raw);
      expect(h.rootCalls + h.backfills, 0);
    },
  );

  for (final checkpoint in [
    ReconciliationCheckpoint.merged,
    ReconciliationCheckpoint.remoteWritten,
    ReconciliationCheckpoint.localWritten,
  ]) {
    test(
      'persisted consent survives fresh store at ${checkpoint.name}',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final writer = SharedPreferencesAccountTransitionJournalStore(
          prefs,
          storageKey: AccountTransitionJournal.switchReconciliationStorageKey,
        );
        final original = AccountTransitionJournal.fromSession(
          const CloudWriteSession(
            uid: 'owned-target',
            epoch: 7,
            mode: CloudWriteMode.reconciling,
          ),
          reconciliationOperationId: 'owned-switch-op',
          reconciliationCheckpoint: checkpoint,
          remoteRevision: 23,
          reconciliationLocalCustomPackBaseIds: {'retained-pack'},
          switchResolutionConsent: _consent(),
        );
        await writer.write(original);
        final fresh = SharedPreferencesAccountTransitionJournalStore(
          prefs,
          storageKey: AccountTransitionJournal.switchReconciliationStorageKey,
        );
        final restored = (await fresh.read())!;
        expect(restored.session, original.session);
        expect(
          restored.reconciliationOperationId,
          original.reconciliationOperationId,
        );
        expect(restored.reconciliationCheckpoint, checkpoint);
        expect(restored.remoteRevision, 23);
        expect(restored.reconciliationLocalCustomPackBaseIds, {
          'retained-pack',
        });
        final consent = restored.switchResolutionConsent;
        expect(consent, isNotNull);
        expect(consent!.side, AccountSwitchResolutionSide.cloud);
        expect(consent.selectedPlacementLevel, 'a2');
        expect(consent.candidateFingerprint, _consent().candidateFingerprint);
        expect(
          consent.deviceComponents,
          original.switchResolutionConsent!.deviceComponents,
        );
        expect(
          consent.cloudComponents,
          original.switchResolutionConsent!.cloudComponents,
        );
        expect(
          consent.candidateComponents,
          original.switchResolutionConsent!.candidateComponents,
        );
        final progressed = restored.copyWith(
          reconciliationCheckpoint: ReconciliationCheckpoint.completed,
        );
        expect(
          jsonEncode(progressed.toJson()['switchResolutionConsent']),
          jsonEncode(restored.toJson()['switchResolutionConsent']),
        );
      },
    );
  }

  for (final invalid in <Object?>[
    null,
    'opaque',
    {'side': 'third'},
    {
      'side': 'cloud',
      'selectedPlacementLevel': 'a2',
      'candidateFingerprint': 'token-canary',
    },
  ]) {
    test(
      'present malformed consent is rejected, never silently dropped: ${invalid.runtimeType}',
      () {
        final journal = AccountTransitionJournal.fromSession(
          const CloudWriteSession(
            uid: 'owned-target',
            epoch: 7,
            mode: CloudWriteMode.reconciling,
          ),
          reconciliationOperationId: 'owned-switch-op',
          reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        );
        final encoded = <String, Object?>{...journal.toJson()}
          ..['switchResolutionConsent'] = invalid;
        expect(
          () => AccountTransitionJournal.fromJson(encoded),
          throwsFormatException,
        );
      },
    );
  }

  test('consent cannot be attached to a ready session', () {
    expect(
      () => AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'owned-target',
          epoch: 7,
          mode: CloudWriteMode.ready,
        ),
        reconciliationOperationId: 'owned-switch-op',
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        switchResolutionConsent: _consent(),
      ),
      throwsFormatException,
    );
  });

  for (final stopAfter in ['root', 'packs', 'local']) {
    test(
      'fresh owner resumes real adapter after $stopAfter commit without duplicate commits',
      () async {
        final h = _PartialCommitHarness(stopAfter);
        await h.prepare();
        final first = await h.owner().resume(
          liveUid: 'target-owner',
          catalog: h.catalog,
        );
        expect(first.status, AccountSwitchStatus.mergeDeferred);
        expect((await h.journals.read())?.switchResolutionConsent, isNotNull);
        expect(h.backfills, 0);
        // A fresh process must restore the persisted exact session; it does not
        // inherit the first controller's in-memory epoch or a fake result.
        h.sessions = CloudWriteSessionController();
        final resumed = await h.owner().resume(
          liveUid: 'target-owner',
          catalog: h.catalog,
        );
        expect(resumed.status, AccountSwitchStatus.completed);
        expect(h.local, h.candidate);
        expect(h.local.fields['app'], {
          'last_open': '2026-10-30',
          'streak_days': 2,
          'best_streak': 12,
        });
        expect(h.local.packProgress['a1-test']!.wordsLearned, 1);
        expect(h.rootCommits, 1);
        expect(h.packCommits, 1);
        expect(h.localCommits, 1);
        expect(h.backfills, 1);
        final repeat = await h.owner().resume(
          liveUid: 'target-owner',
          catalog: h.catalog,
        );
        expect(repeat.status, AccountSwitchStatus.failed);
        expect(h.rootCommits + h.packCommits + h.localCommits, 3);
        expect(h.backfills, 1);
      },
    );
  }

  test(
    'owned durable consent offers resume without reading snapshots or writing',
    () async {
      final h = _PartialCommitHarness('root');
      await h.prepare();
      final rawBefore = h.journals.raw;
      final writesBefore = h.journals.writes;
      final result = await h.owner().previewPendingSwitchResolution();
      expect(
        result.status,
        AccountSwitchResolutionPreviewStatus.resumeRequired,
      );
      expect(result.preview, isNull);
      expect(h.journals.raw, rawBefore);
      expect(h.journals.writes, writesBefore);
      expect(h.rootCommits + h.packCommits + h.localCommits + h.backfills, 0);
    },
  );

  test(
    'candidate bytes without same-operation root receipt do not authorize recovery',
    () async {
      final h = _PartialCommitHarness('root');
      await h.prepare();
      await h.owner().resume(liveUid: 'target-owner', catalog: h.catalog);
      h.root['reconciliation_operation_id'] = 'unrelated-operation';
      h.sessions = CloudWriteSessionController();
      final result = await h.owner().resume(
        liveUid: 'target-owner',
        catalog: h.catalog,
      );
      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect(h.packCommits + h.localCommits + h.backfills, 0);
      expect((await h.journals.read())?.switchResolutionConsent, isNotNull);
    },
  );

  test(
    'new local learning after interrupted root commit stays blocked and retained',
    () async {
      final h = _PartialCommitHarness('root');
      await h.prepare();
      await h.owner().resume(liveUid: 'target-owner', catalog: h.catalog);
      h.local = h.snapshot(placement: 'a1', xp: 99, learned: 1, remote: false);
      h.sessions = CloudWriteSessionController();
      final result = await h.owner().resume(
        liveUid: 'target-owner',
        catalog: h.catalog,
      );
      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect((h.local.fields['progress'] as Map)['xp'], 99);
      expect(h.packCommits + h.localCommits + h.backfills, 0);
    },
  );

  test(
    'real native multi-date study apply accepts its own intermediate dates and rejects new proof',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_study_log_v1_2026-10-28': <String>['device-a'],
        'kl_study_log_v1_2026-10-29': <String>['device-b'],
      });
      await Storage.init();
      final original = AccountReconciliationSnapshot(
        fields: CloudSync.captureReconciliationFields(),
        srsCards: {},
        customPacks: {},
        packProgress: {},
      );
      final remote = AccountReconciliationSnapshot(
        fields: {
          'study_log_json': jsonEncode({
            '2026-10-28': ['cloud-a'],
            '2026-10-29': ['cloud-b'],
            '2026-10-30': ['cloud-c'],
          }),
        },
        srsCards: {},
        customPacks: {},
        packProgress: {},
      );
      final candidate = AccountReconciliationMerger.merge(
        local: original,
        remote: remote,
        catalog: {},
      ).merged!;
      final consent = AccountSwitchResolutionConsent(
        side: AccountSwitchResolutionSide.cloud,
        selectedPlacementLevel: 'a2',
        catalogFingerprint: _hash('a'),
        deviceFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          original,
        ),
        cloudFingerprint: AccountSwitchResolutionFingerprint.snapshot(remote),
        candidateFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          candidate,
        ),
        deviceComponents: AccountSwitchResolutionFingerprint.components(
          original,
        ),
        cloudComponents: AccountSwitchResolutionFingerprint.components(remote),
        candidateComponents: AccountSwitchResolutionFingerprint.components(
          candidate,
        ),
      );
      final sessions = CloudWriteSessionController()..acquire('native-owner');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var sawConfirmedIntermediateDate = false;
      void guard() {
        if (Storage.studyLogIdsFor('2026-10-28').contains('cloud-a') &&
            !Storage.studyLogIdsFor('2026-10-29').contains('cloud-b')) {
          sawConfirmedIntermediateDate = true;
        }
        if (!consent.acceptsLocalFields(
          CloudSync.captureReconciliationFields(),
        )) {
          throw const LocalReconciliationGenerationConflict();
        }
      }

      try {
        await CloudSync.applyReconciledRestorePayload(
          Map.from(candidate.fields),
          uid: 'native-owner',
          session: session,
          sessions: sessions,
          assertCurrentLocalSource: guard,
        );
      } finally {
        expect(
          sawConfirmedIntermediateDate,
          isTrue,
          reason:
              'The guard must observe a real completed date write before the next date.',
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      expect(
        preferences.getStringList('kl_study_log_v1_2026-10-28'),
        unorderedEquals(['device-a', 'cloud-a']),
      );
      expect(
        preferences.getStringList('kl_study_log_v1_2026-10-29'),
        unorderedEquals(['device-b', 'cloud-b']),
      );
      expect(preferences.getStringList('kl_study_log_v1_2026-10-30'), [
        'cloud-c',
      ]);
      await CloudSync.applyReconciledRestorePayload(
        Map.from(candidate.fields),
        uid: 'native-owner',
        session: session,
        sessions: sessions,
        assertCurrentLocalSource: guard,
      );
      expect(Storage.xp, 0);
      await preferences.setStringList('kl_study_log_v1_2026-10-29', [
        ...Storage.studyLogIdsFor('2026-10-29'),
        'new-attempt',
      ]);
      await expectLater(
        CloudSync.applyReconciledRestorePayload(
          Map.from(candidate.fields),
          uid: 'native-owner',
          session: session,
          sessions: sessions,
          assertCurrentLocalSource: guard,
        ),
        throwsA(isA<LocalReconciliationGenerationConflict>()),
      );
      expect(Storage.studyLogIdsFor('2026-10-29'), contains('new-attempt'));
      Storage.resetForTesting();
    },
  );

  test(
    'real native multi-field apply resumes its own partial writes under the immutable source guard',
    () async {
      Storage.resetForTesting();
      await Storage.init();
      await Storage.setLastOpenDate('2026-10-29');
      await Storage.setStreakDays(12);
      final original = AccountReconciliationSnapshot(
        fields: CloudSync.captureReconciliationFields(),
        srsCards: {},
        customPacks: {},
        packProgress: {},
      );
      final remote = AccountReconciliationSnapshot(
        fields: {
          'chosung': {'correct': 3, 'wrong': 2},
          'app': {
            'last_open': '2026-10-30',
            'streak_days': 2,
            'best_streak': 12,
          },
          'progress': {
            'xp': 17,
            'earned_stamps': ['one', 'two'],
            'owned_decor': ['retained'],
          },
        },
        srsCards: {},
        customPacks: {},
        packProgress: {},
      );
      final candidate = AccountReconciliationMerger.merge(
        local: original,
        remote: remote,
        catalog: {},
      ).merged!;
      final consent = AccountSwitchResolutionConsent(
        side: AccountSwitchResolutionSide.cloud,
        selectedPlacementLevel: 'a2',
        catalogFingerprint: _hash('a'),
        deviceFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          original,
        ),
        cloudFingerprint: AccountSwitchResolutionFingerprint.snapshot(remote),
        candidateFingerprint: AccountSwitchResolutionFingerprint.snapshot(
          candidate,
        ),
        deviceComponents: AccountSwitchResolutionFingerprint.components(
          original,
        ),
        cloudComponents: AccountSwitchResolutionFingerprint.components(remote),
        candidateComponents: AccountSwitchResolutionFingerprint.components(
          candidate,
        ),
      );
      final sessions = CloudWriteSessionController()..acquire('native-owner');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var interrupted = false;
      void guard() {
        if (!consent.acceptsLocalFields(
          CloudSync.captureReconciliationFields(),
        )) {
          throw const LocalReconciliationGenerationConflict();
        }
        if (!interrupted && Storage.chosungCorrect == 3) {
          interrupted = true;
          throw StateError('stop after confirmed native counter write');
        }
      }

      await expectLater(
        CloudSync.applyReconciledRestorePayload(
          Map.from(candidate.fields),
          uid: 'native-owner',
          session: session,
          sessions: sessions,
          assertCurrentLocalSource: guard,
        ),
        throwsStateError,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      expect(Storage.chosungCorrect, 3);
      expect(Storage.xp, 0);
      await CloudSync.applyReconciledRestorePayload(
        Map.from(candidate.fields),
        uid: 'native-owner',
        session: session,
        sessions: sessions,
        assertCurrentLocalSource: guard,
      );
      expect(Storage.chosungWrong, 2);
      expect(Storage.xp, 17);
      expect(Storage.lastOpenDate, '2026-10-30');
      expect(Storage.streakDays, 2);
      expect(Storage.earnedStamps, containsAll(['one', 'two']));
      expect(Storage.ownedDecor, contains('retained'));
      expect(
        consent.acceptsLocalFields(CloudSync.captureReconciliationFields()),
        isTrue,
      );
      // A real learner write is not one of this operation's intermediate values.
      await Storage.setChosungCorrect(4);
      await expectLater(
        CloudSync.applyReconciledRestorePayload(
          Map.from(candidate.fields),
          uid: 'native-owner',
          session: session,
          sessions: sessions,
          assertCurrentLocalSource: guard,
        ),
        throwsA(isA<LocalReconciliationGenerationConflict>()),
      );
      expect(Storage.chosungCorrect, 4);
      Storage.resetForTesting();
    },
  );
}

class _PartialCommitHarness {
  _PartialCommitHarness(this.stopAfter);
  final String stopAfter;
  bool stopped = false;
  CloudWriteSessionController sessions = CloudWriteSessionController();
  final journals = ResolutionTransitionStore();
  final switches = ResolutionSwitchStore();
  final identity = ResolutionIdentity();
  final catalog = const {
    'a1-test': PackCatalogEntry(packId: 'a1-test', level: 'A1', wordsTotal: 2),
  };
  late AccountReconciliationSnapshot local;
  late AccountReconciliationSnapshot candidate;
  Map<String, dynamic> root = {};
  Map<String, dynamic> membership = {};
  Map<String, dynamic> pack = {};
  int rootCommits = 0;
  int rootCalls = 0;
  bool verifyStartedLatch = false;
  bool observedStartedLatch = false;
  bool failCompositeRead = false;
  int packCommits = 0;
  int localCommits = 0;
  int backfills = 0;
  String get catalogHash => AccountSwitchResolutionFingerprint.hash('catalog');

  AccountReconciliationSnapshot snapshot({
    required String placement,
    required int xp,
    required int learned,
    required bool remote,
  }) => AccountReconciliationSnapshot(
    fields: {
      'progress': {'xp': xp},
      'app': remote
          ? {'last_open': '2026-10-30', 'streak_days': 2, 'best_streak': 2}
          : {'last_open': '2026-10-29', 'streak_days': 12, 'best_streak': 12},
    },
    srsCards: {},
    customPacks: {},
    packProgress: {
      'a1-test':
          PackProgress.fresh(
            packId: 'a1-test',
            level: 'A1',
            wordsTotal: 2,
          ).copyWith(
            wordsLearned: learned,
            status: learned == 0 ? PackStatus.available : PackStatus.inProgress,
          ),
    },
    courseMastery: CourseMasterySnapshot(placementLevel: placement),
  );

  CourseMasteryMergeResult courseMerge({
    required CourseMasterySnapshot? local,
    required CourseMasterySnapshot? remote,
  }) => const CourseMasteryMergeResult.merged(
    CourseMasterySnapshot(placementLevel: 'a1'),
  );

  Future<void> prepare() async {
    sessions.acquire('target-owner');
    sessions.transition(CloudWriteMode.reconciling);
    local = snapshot(placement: 'a1', xp: 0, learned: 1, remote: false);
    final cloud = snapshot(placement: 'a2', xp: 17, learned: 0, remote: true);
    root = {...cloud.toCloudDocument(), 'sync_revision': 4};
    pack = {...cloud.packProgress['a1-test']!.toJson(), 'sync_revision': 3};
    membership = {
      'revision': 2,
      'pack_ids': ['a1-test'],
    };
    final read = await adapter().readRemote();
    candidate = AccountReconciliationMerger.merge(
      local: local,
      remote: read.value!,
      catalog: catalog,
      courseMasteryMerger: courseMerge,
    ).merged!;
    final consent = AccountSwitchResolutionConsent(
      side: AccountSwitchResolutionSide.device,
      selectedPlacementLevel: 'a1',
      catalogFingerprint: catalogHash,
      deviceFingerprint: AccountSwitchResolutionFingerprint.snapshot(local),
      cloudFingerprint: AccountSwitchResolutionFingerprint.snapshot(
        read.value!,
      ),
      candidateFingerprint: AccountSwitchResolutionFingerprint.snapshot(
        candidate,
      ),
      deviceComponents: AccountSwitchResolutionFingerprint.components(local),
      cloudComponents: AccountSwitchResolutionFingerprint.components(
        read.value!,
      ),
      candidateComponents: AccountSwitchResolutionFingerprint.components(
        candidate,
      ),
      cloudFences: AccountSwitchResolutionFingerprint.fences(
        read.value!,
        read.revision,
      ),
    );
    await journals.write(
      AccountTransitionJournal.fromSession(
        sessions.current!,
        reconciliationOperationId: 'switch-resolution-op',
        resolutionRemoteWriteStarted: false,
        switchResolutionConsent: consent,
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
      ),
    );
  }

  void interrupt(String point) {
    if (!stopped && point == stopAfter) {
      stopped = true;
      throw StateError('simulated process termination');
    }
  }

  FirebaseAccountReconciliationAdapter
  adapter() => FirebaseAccountReconciliationAdapter(
    uid: 'target-owner',
    session: sessions.current!,
    sessions: sessions,
    remote: FirebaseAccountReconciliationRemote(
      rootReader: (_) async => CloudSyncDocument.present(Map.from(root)),
      packReader: (_) async => [
        FirestorePackDocument(id: 'a1-test', data: Map.from(pack)),
      ],
      membershipReader: (_) async => FirestorePackMembership(
        revision: membership['revision'] as int,
        packIds: {'a1-test'},
      ),
      compositeReader: (_) async {
        if (failCompositeRead) {
          throw StateError('offline receipt read');
        }
        return CloudSyncCompositeDocuments(
          root: CloudSyncDocument.present(Map.from(root)),
          packMembership: CloudSyncDocument.present(Map.from(membership)),
        );
      },
      rootWriter:
          ({
            required uid,
            required data,
            required expectedRevision,
            required operationId,
            required session,
            required sessions,
          }) async {
            rootCalls++;
            if (verifyStartedLatch) {
              observedStartedLatch =
                  (await journals.read())?.resolutionRemoteWriteStarted == true;
              if (!observedStartedLatch) {
                throw StateError(
                  'Root CAS invoked before durable attempt latch.',
                );
              }
            }
            final hash = AccountSwitchResolutionFingerprint.hash(data);
            if (root['reconciliation_operation_id'] == operationId &&
                root['reconciliation_payload_hash'] == hash) {
              return CloudSyncCasResult.committed(root['sync_revision'] as int);
            }
            if (root['sync_revision'] != expectedRevision) {
              return const CloudSyncCasResult.revisionConflict();
            }
            root = {
              ...data,
              'sync_revision': expectedRevision! + 1,
              'reconciliation_operation_id': operationId,
              'reconciliation_payload_hash': hash,
            };
            rootCommits++;
            interrupt('root');
            return CloudSyncCasResult.committed(root['sync_revision'] as int);
          },
      packWriter:
          ({
            required uid,
            required progresses,
            required expectedRevisions,
            required expectedMembershipRevision,
            required expectedMembershipPackIds,
            required expectedLegacyDocuments,
            required operationId,
            required session,
            required sessions,
          }) async {
            if (membership['reconciliation_operation_id'] != operationId) {
              if (membership['revision'] != expectedMembershipRevision ||
                  pack['sync_revision'] != expectedRevisions['a1-test']) {
                return const FirestorePackCasResult.revisionConflict();
              }
              pack = {
                ...progresses.single.toJson(),
                'sync_revision': (pack['sync_revision'] as int) + 1,
                'reconciliation_operation_id': operationId,
              };
              membership = {
                'revision': (membership['revision'] as int) + 1,
                'pack_ids': ['a1-test'],
                'reconciliation_operation_id': operationId,
              };
              packCommits++;
              interrupt('packs');
            }
            return FirestorePackCasResult.committed(
              {'a1-test': pack['sync_revision'] as int},
              membershipRevision: membership['revision'] as int,
              membershipPackIds: {'a1-test'},
            );
          },
    ),
  );

  AccountSwitchCoordinator owner() => AccountSwitchCoordinator(
    sessions: sessions,
    identity: identity,
    journalStore: switches,
    reconciliationJournalStore: journals,
    readResolutionInputs: () async {
      throw StateError('Durable hint must not read snapshots.');
    },
    buildResolutionCandidate: ({required inputs, required side}) {
      throw StateError('Durable hint must not rebuild candidates.');
    },
    localPreflight: () async {},
    ownershipTransition: ({required oldUid, required transition}) async =>
        CloudWriteResult.blocked,
    rebindPush: () async {},
    activateBackfill: (_) async {
      backfills++;
    },
    clearReconciliationJournal: () async {
      journals.raw = null;
    },
    reconcile:
        ({
          required targetUid,
          required session,
          required operationId,
          required catalog,
        }) async {
          final remote = adapter();
          return remote
              .coordinator(
                journalStore: journals,
                courseMasteryMerger: courseMerge,
                resolutionCatalogFingerprint: catalogHash,
                validateResolutionRemote: remote.validateResolutionReceipt,
                loadLocal: () => local,
                writeLocal:
                    (value, {required session, required sessions}) async {
                      if (!stopped && stopAfter == 'local') {
                        local = AccountReconciliationSnapshot(
                          fields: {
                            ...local.fields,
                            'app': {
                              ...local.fields['app'] as Map,
                              'last_open': '2026-10-30',
                            },
                          },
                          srsCards: local.srsCards,
                          customPacks: local.customPacks,
                          packProgress: local.packProgress,
                          courseMastery: local.courseMastery,
                        );
                        interrupt('local');
                      }
                      local = value;
                      localCommits++;
                    },
              )
              .reconcile(
                session: session,
                operationId: operationId,
                catalog: catalog,
              );
        },
  );
}
