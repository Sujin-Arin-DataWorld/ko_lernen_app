import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CloudReadResult', () {
    test('distinguishes every remote read state', () {
      expect(
        CloudReadResult<int>.present(7, revision: 3).state,
        CloudReadState.present,
      );
      expect(CloudReadResult<int>.absent().state, CloudReadState.absent);
      expect(
        CloudReadResult<int>.unavailable().state,
        CloudReadState.unavailable,
      );
      expect(CloudReadResult<int>.invalid().state, CloudReadState.invalid);
      expect(CloudReadResult<int>.tooLarge().state, CloudReadState.tooLarge);
      expect(CloudReadResult<int>.present(7, revision: 3).value, 7);
      expect(CloudReadResult<int>.present(7, revision: 3).revision, 3);
    });
  });

  group('AccountReconciliationMerger', () {
    const catalog = {
      'pack-a': PackCatalogEntry(packId: 'pack-a', level: 'A1', wordsTotal: 10),
    };

    test('preserves local-only data', () {
      final local = _snapshot(srs: {'word-a': _srs(reviewCount: 1)});

      final result = AccountReconciliationMerger.merge(
        local: local,
        remote: AccountReconciliationSnapshot.empty,
        catalog: catalog,
      );

      expect(result.conflicts, isEmpty);
      expect(result.merged?.srsCards, local.srsCards);
    });

    test('preserves remote-only data', () {
      final remote = _snapshot(customPacks: {'cp-a': _pack(name: 'Remote')});

      final result = AccountReconciliationMerger.merge(
        local: AccountReconciliationSnapshot.empty,
        remote: remote,
        catalog: catalog,
      );

      expect(result.conflicts, isEmpty);
      expect(result.merged?.customPacks, remote.customPacks);
    });

    test('accepts equal same-id histories without inventing a conflict', () {
      final snapshot = _snapshot(
        srs: {'word-a': _srs(reviewCount: 2)},
        customPacks: {'cp-a': _pack(name: 'Same')},
      );

      final result = AccountReconciliationMerger.merge(
        local: snapshot,
        remote: snapshot,
        catalog: catalog,
      );

      expect(result.conflicts, isEmpty);
      expect(result.merged, snapshot);
    });

    test('blocks divergent SRS-card histories', () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot(srs: {'word-a': _srs(reviewCount: 2)}),
        remote: _snapshot(srs: {'word-a': _srs(reviewCount: 3)}),
        catalog: catalog,
      );

      expect(result.merged, isNull);
      expect(
        result.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.srsCardHistory,
            id: 'word-a',
          ),
        ),
      );
    });

    test('blocks divergent custom packs with the same id', () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot(customPacks: {'cp-a': _pack(name: 'Local')}),
        remote: _snapshot(customPacks: {'cp-a': _pack(name: 'Remote')}),
        catalog: catalog,
      );

      expect(result.merged, isNull);
      expect(
        result.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.customPackId,
            id: 'cp-a',
          ),
        ),
      );
    });

    test(
      'normalizes equal numeric and instant fields independent of argument order',
      () {
        final first = _snapshot(
          fields: {
            'count': 1,
            'updated': '2026-07-30T12:00:00.000+02:00',
            'latest': '2026-07-30T09:00:00.000Z',
          },
        );
        final second = _snapshot(
          fields: {
            'count': 1.0,
            'updated': '2026-07-30T10:00:00.000Z',
            'latest': '2026-07-30T11:00:00.000+01:00',
          },
        );

        final forward = AccountReconciliationMerger.merge(
          local: first,
          remote: second,
          catalog: catalog,
        );
        final reverse = AccountReconciliationMerger.merge(
          local: second,
          remote: first,
          catalog: catalog,
        );

        expect(forward.conflicts, isEmpty);
        expect(reverse.conflicts, isEmpty);
        expect(
          jsonEncode(forward.merged!.toCloudDocument()),
          jsonEncode(reverse.merged!.toCloudDocument()),
        );
        expect(forward.merged!.fields, {
          'count': 1,
          'updated': '2026-07-30T10:00:00.000Z',
          'latest': '2026-07-30T10:00:00.000Z',
        });
        expect(forward.merged!.fields['count'], isA<int>());
      },
    );

    test('canonically orders and normalizes mixed-type collection values', () {
      final first = _snapshot(
        fields: {
          'items': [
            1,
            '1',
            {'value': 1.0},
            [1.0, '1'],
          ],
        },
      );
      final second = _snapshot(
        fields: {
          'items': [
            [1, '1'],
            {'value': 1},
            '1',
            1.0,
            true,
          ],
        },
      );

      final forward = AccountReconciliationMerger.merge(
        local: first,
        remote: second,
        catalog: catalog,
      );
      final reverse = AccountReconciliationMerger.merge(
        local: second,
        remote: first,
        catalog: catalog,
      );

      expect(forward.conflicts, isEmpty);
      expect(reverse.conflicts, isEmpty);
      expect(
        jsonEncode(forward.merged!.toCloudDocument()),
        jsonEncode(reverse.merged!.toCloudDocument()),
      );
      expect(forward.merged!.fields['items'], [
        true,
        1,
        '1',
        [1, '1'],
        {'value': 1},
      ]);
    });
  });

  group('AccountReconciliationSnapshot decoding', () {
    test('rejects malformed remote SRS history', () {
      final result = AccountReconciliationSnapshot.decodeCloudDocument({
        'srs_json': '{"word-a":{"e":2.5,"i":1,"n":"bad","r":1}}',
      });

      expect(result.state, CloudReadState.invalid);
    });

    test('rejects malformed portable custom-pack data', () {
      final result = AccountReconciliationSnapshot.decodeCloudDocument({
        'srs_json': '{}',
        'custom_packs_json': '{"cp-a":{"name":"missing fields"}}',
      });

      expect(result.state, CloudReadState.invalid);
    });
  });

  group('AccountReconciliationCoordinator', () {
    late CloudWriteSessionController sessions;
    late CloudWriteSession reconciling;
    late _MemoryJournalStore journalStore;

    setUp(() {
      sessions = CloudWriteSessionController()..acquire('uid-a');
      reconciling = sessions.transition(CloudWriteMode.reconciling);
      journalStore = _MemoryJournalStore();
    });

    test('unavailable remote data never writes either side', () async {
      var remoteWrites = 0;
      var localWrites = 0;
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: journalStore,
        readRemote: () async =>
            CloudReadResult<AccountReconciliationSnapshot>.unavailable(),
        loadLocal: () => _snapshot(srs: {'word-a': _srs(reviewCount: 1)}),
        writeRemote:
            (_, {required expectedRevision, required operationId}) async {
              remoteWrites += 1;
              return const ReconciliationWriteResult.committed(revision: 1);
            },
        writeLocal: (_) async => localWrites += 1,
      );

      final result = await coordinator.reconcile(
        session: reconciling,
        operationId: 'operation-1',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.unavailable);
      expect(remoteWrites, 0);
      expect(localWrites, 0);
    });

    for (final state in [CloudReadState.invalid, CloudReadState.tooLarge]) {
      test('$state remote data never becomes an empty remote', () async {
        var writes = 0;
        final coordinator = AccountReconciliationCoordinator(
          sessions: sessions,
          journalStore: journalStore,
          readRemote: () async => state == CloudReadState.invalid
              ? CloudReadResult<AccountReconciliationSnapshot>.invalid()
              : CloudReadResult<AccountReconciliationSnapshot>.tooLarge(),
          loadLocal: () =>
              _snapshot(customPacks: {'cp-a': _pack(name: 'Local')}),
          writeRemote:
              (_, {required expectedRevision, required operationId}) async {
                writes += 1;
                return const ReconciliationWriteResult.committed(revision: 1);
              },
          writeLocal: (_) async => writes += 1,
        );

        final result = await coordinator.reconcile(
          session: reconciling,
          operationId: 'operation-1',
          catalog: const {},
        );

        expect(
          result.status,
          state == CloudReadState.invalid
              ? AccountReconciliationStatus.invalid
              : AccountReconciliationStatus.tooLarge,
        );
        expect(writes, 0);
      });
    }

    test('requires the exact current reconciling session', () async {
      final readySessions = CloudWriteSessionController();
      final ready = readySessions.acquire('uid-a');
      var reads = 0;
      final coordinator = AccountReconciliationCoordinator(
        sessions: readySessions,
        journalStore: journalStore,
        readRemote: () async {
          reads += 1;
          return CloudReadResult<AccountReconciliationSnapshot>.absent();
        },
        loadLocal: () => AccountReconciliationSnapshot.empty,
        writeRemote: (_, {required expectedRevision, required operationId}) =>
            Future.value(
              const ReconciliationWriteResult.committed(revision: 1),
            ),
        writeLocal: (_) async {},
      );

      final result = await coordinator.reconcile(
        session: ready,
        operationId: 'operation-1',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.blocked);
      expect(reads, 0);
    });

    test('a CAS conflict re-reads and re-merges before writing', () async {
      var reads = 0;
      final expectedRevisions = <int?>[];
      final membershipRevisions = <int?>[];
      final writtenPackIds = <Set<String>>[];
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: journalStore,
        readRemote: () async {
          reads += 1;
          return CloudReadResult.present(
            reads == 1
                ? _snapshot(fields: {'xp': 1}, packMembershipRevision: 4)
                : _snapshot(
                    fields: {'xp': 2},
                    packs: {'pack-b': _progress(packId: 'pack-b', level: 'A2')},
                    packRevisions: const {'pack-b': 1},
                    packMembershipRevision: 5,
                  ),
            revision: reads,
          );
        },
        loadLocal: () => _snapshot(fields: {'xp': 3}),
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async {
              expectedRevisions.add(expectedRevision);
              membershipRevisions.add(snapshot.packMembershipRevision);
              writtenPackIds.add(snapshot.packProgress.keys.toSet());
              return expectedRevision == 1
                  ? const ReconciliationWriteResult.revisionConflict()
                  : const ReconciliationWriteResult.committed(revision: 3);
            },
        writeLocal: (_) async {},
      );

      final result = await coordinator.reconcile(
        session: reconciling,
        operationId: 'operation-1',
        catalog: const {
          'pack-b': PackCatalogEntry(
            packId: 'pack-b',
            level: 'A2',
            wordsTotal: 10,
          ),
        },
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(reads, 2);
      expect(expectedRevisions, [1, 2]);
      expect(membershipRevisions, [4, 5]);
      expect(writtenPackIds, [
        <String>{},
        {'pack-b'},
      ]);
    });

    test(
      'retry after an interrupted remote write keeps one operation id',
      () async {
        var remote = AccountReconciliationSnapshot.empty;
        var remoteExists = false;
        var failAfterCommit = true;
        final operationIds = <String>[];

        AccountReconciliationCoordinator coordinator() =>
            AccountReconciliationCoordinator(
              sessions: sessions,
              journalStore: journalStore,
              readRemote: () async => remoteExists
                  ? CloudReadResult.present(remote, revision: 1)
                  : CloudReadResult<AccountReconciliationSnapshot>.absent(),
              loadLocal: () => _snapshot(srs: {'word-a': _srs(reviewCount: 1)}),
              writeRemote:
                  (
                    value, {
                    required expectedRevision,
                    required operationId,
                  }) async {
                    operationIds.add(operationId);
                    remote = value;
                    remoteExists = true;
                    if (failAfterCommit) {
                      failAfterCommit = false;
                      throw StateError('response lost');
                    }
                    return const ReconciliationWriteResult.committed(
                      revision: 1,
                    );
                  },
              writeLocal: (_) async {},
            );

        final first = await coordinator().reconcile(
          session: reconciling,
          operationId: 'operation-1',
          catalog: const {},
        );
        final second = await coordinator().reconcile(
          session: reconciling,
          operationId: 'operation-1',
          catalog: const {},
        );

        expect(first.status, AccountReconciliationStatus.unavailable);
        expect(second.status, AccountReconciliationStatus.completed);
        expect(remote.srsCards['word-a'], _srs(reviewCount: 1));
        expect(operationIds, ['operation-1']);
        expect(
          journalStore.value?.reconciliationCheckpoint,
          ReconciliationCheckpoint.completed,
        );
      },
    );
  });

  test(
    'concrete adapter surfaces a pack conflict after the root write succeeds',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final adapter = FirebaseAccountReconciliationAdapter(
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      );
      var rootWrites = 0;
      var packWrites = 0;

      final result = await adapter.writeRemote(
        _snapshot(packMembershipRevision: 4),
        expectedRevision: 2,
        operationId: 'operation-1',
        rootWriter:
            ({
              required uid,
              required data,
              required expectedRevision,
              required operationId,
              required session,
              required sessions,
            }) async {
              rootWrites += 1;
              return const CloudSyncCasResult.committed(3);
            },
        packWriter:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedMembershipRevision,
              required operationId,
              required session,
              required sessions,
            }) async {
              packWrites += 1;
              expect(expectedMembershipRevision, 4);
              return const FirestorePackCasResult.revisionConflict();
            },
      );

      expect(result.status, ReconciliationWriteStatus.revisionConflict);
      expect(rootWrites, 1);
      expect(packWrites, 1);
    },
  );

  test(
    'SharedPreferences journal store durably round-trips safe metadata',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAccountTransitionJournalStore(preferences);
      final journal = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'uid-a',
          epoch: 2,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'operation-1',
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        remoteRevision: 4,
      );

      await store.write(journal);
      final restored = await store.read();

      expect(restored?.session, journal.session);
      expect(restored?.reconciliationOperationId, 'operation-1');
      expect(
        restored?.reconciliationCheckpoint,
        ReconciliationCheckpoint.merged,
      );
      expect(
        preferences.getString(
          SharedPreferencesAccountTransitionJournalStore.key,
        ),
        isNot(contains('credential')),
      );
    },
  );

  test(
    'concrete local store round-trips reconciliation-owned domains',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final snapshot = _snapshot(
        srs: {'word-a': _srs(reviewCount: 1)},
        customPacks: {'cp-a': _pack(name: 'Local')},
        packs: {'pack-a': _progressForLocalStore()},
      );

      await LocalAccountReconciliationStore.write(snapshot);
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final restored = LocalAccountReconciliationStore.load();

      expect(restored.srsCards, snapshot.srsCards);
      expect(restored.customPacks, snapshot.customPacks);
      expect(
        restored.packProgress['pack-a']?.toJson(),
        snapshot.packProgress['pack-a']?.toJson(),
      );
      expect(jsonDecode(Storage.srsRawJson), snapshot.srsCards);
    },
  );

  test(
    'malformed local custom packs never become an empty local snapshot',
    () async {
      SharedPreferences.setMockInitialValues({
        'kl_custom_packs_v1': '{bad-json',
      });
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();

      expect(
        LocalAccountReconciliationStore.load,
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'reconciled portable packs preserve matching local media references',
    () async {
      final portablePack = {
        'name': 'Pack',
        'sourcePageId': '',
        'words': [
          {
            'korean': '안녕',
            'romanization': 'annyeong',
            'posDe': '',
            'translationDe': 'Hallo',
            'translationEn': 'Hello',
            'exampleKorean': '',
            'exampleDe': '',
            'definitionKo': '',
            'savedToPackId': null,
          },
        ],
        'createdAt': '2026-07-30T00:00:00.000Z',
      };
      final localPack =
          jsonDecode(jsonEncode(portablePack)) as Map<String, dynamic>;
      ((localPack['words'] as List).first
              as Map<String, dynamic>)['imagePath'] =
          'word:photo.png';
      SharedPreferences.setMockInitialValues({
        'kl_custom_packs_v1': jsonEncode({'cp-a': localPack}),
      });
      Storage.resetForTesting();
      await Storage.init();

      await CustomPackService.writeReconciledPortable({'cp-a': portablePack});

      final saved =
          jsonDecode(Storage.customPacksRawJson) as Map<String, dynamic>;
      expect(
        (((saved['cp-a'] as Map)['words'] as List).first as Map)['imagePath'],
        'word:photo.png',
      );
    },
  );

  test(
    'reconciliation serializes with a concurrent custom-pack media mutation',
    () async {
      final portablePack = {
        'name': 'Pack',
        'sourcePageId': '',
        'words': [
          {
            'korean': '?덈뀞',
            'romanization': 'annyeong',
            'posDe': '',
            'translationDe': 'Hallo',
            'translationEn': 'Hello',
            'exampleKorean': '',
            'exampleDe': '',
            'definitionKo': '',
            'savedToPackId': null,
          },
        ],
        'createdAt': '2026-07-30T00:00:00.000Z',
      };
      SharedPreferences.setMockInitialValues({
        'kl_custom_packs_v1': jsonEncode({'cp-a': portablePack}),
      });
      Storage.resetForTesting();
      await Storage.init();

      final reconciliationAtWrite = Completer<void>();
      final allowReconciliationWrite = Completer<void>();
      final reconciliation = CustomPackService.writeReconciledPortable(
        {'cp-a': portablePack},
        writer: (output) async {
          reconciliationAtWrite.complete();
          await allowReconciliationWrite.future;
          await Storage.setCustomPacksRawJsonStrict(jsonEncode(output));
        },
      );
      await reconciliationAtWrite.future;

      final localWithMedia =
          jsonDecode(jsonEncode(portablePack)) as Map<String, dynamic>;
      ((localWithMedia['words'] as List).first
              as Map<String, dynamic>)['imagePath'] =
          'word:photo.png';
      var mutationCompleted = false;
      final mutation = CustomPackService.save(
        CustomPack.fromJson('cp-a', localWithMedia),
      ).then((_) => mutationCompleted = true);
      await Future<void>.delayed(Duration.zero);
      final completedBeforeReconciliation = mutationCompleted;

      allowReconciliationWrite.complete();
      await Future.wait<void>([reconciliation, mutation]);

      expect(completedBeforeReconciliation, isFalse);
      expect(
        CustomPackService.getById('cp-a')!.words.single.imagePath,
        'word:photo.png',
      );
    },
  );
}

AccountReconciliationSnapshot _snapshot({
  Map<String, Object?> fields = const {},
  Map<String, Map<String, Object?>> srs = const {},
  Map<String, Map<String, Object?>> customPacks = const {},
  Map<String, PackProgress> packs = const {},
  Map<String, int?> packRevisions = const {},
  int? packMembershipRevision,
}) {
  return AccountReconciliationSnapshot(
    fields: fields,
    srsCards: srs,
    customPacks: customPacks,
    packProgress: packs,
    packRevisions: packRevisions,
    packMembershipRevision: packMembershipRevision,
  );
}

Map<String, Object?> _srs({required int reviewCount}) => {
  'e': 2.5,
  'i': reviewCount,
  'n': '2026-08-01',
  'r': reviewCount,
};

Map<String, Object?> _pack({required String name}) => {
  'name': name,
  'sourcePageId': '',
  'words': <Object?>[],
  'createdAt': '2026-07-30T00:00:00.000Z',
};

PackProgress _progressForLocalStore() =>
    PackProgress.fresh(packId: 'pack-a', level: 'A1', wordsTotal: 10);

PackProgress _progress({required String packId, required String level}) =>
    PackProgress.fresh(packId: packId, level: level, wordsTotal: 10);

class _MemoryJournalStore implements AccountTransitionJournalStore {
  AccountTransitionJournal? value;

  @override
  Future<AccountTransitionJournal?> read() async => value;

  @override
  Future<void> write(AccountTransitionJournal journal) async {
    value = journal;
  }
}
