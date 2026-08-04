import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
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

    test(
      'merges disjoint typed course evidence with the curriculum merger',
      () {
        final courseService = CourseMasteryService(_courseCatalog());
        final localEvidence = _courseEvidence(id: 'local-evidence', second: 1);
        final remoteEvidence = _courseEvidence(
          id: 'remote-evidence',
          second: 2,
        );

        final result = AccountReconciliationMerger.merge(
          local: _snapshot(
            courseMastery: CourseMasterySnapshot(
              placementLevel: 'a1',
              currentCourseUnitId: 'unit-root',
              evidence: [localEvidence],
            ),
          ),
          remote: _snapshot(
            courseMastery: CourseMasterySnapshot(
              placementLevel: 'A1',
              currentCourseUnitId: 'unit-root',
              evidence: [remoteEvidence],
            ),
          ),
          catalog: catalog,
          courseMasteryMerger: courseService.mergeForReconciliation,
        );

        expect(result.conflicts, isEmpty);
        expect(result.merged!.courseMastery!.evidence.map((item) => item.id), [
          'local-evidence',
          'remote-evidence',
        ]);
      },
    );

    test('maps course placement mismatch to a typed account conflict', () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot(
          courseMastery: const CourseMasterySnapshot(placementLevel: 'a1'),
        ),
        remote: _snapshot(
          courseMastery: const CourseMasterySnapshot(placementLevel: 'a2'),
        ),
        catalog: catalog,
        courseMasteryMerger: CourseMasteryService(
          _courseCatalog(),
        ).mergeForReconciliation,
      );

      expect(result.merged, isNull);
      expect(
        result.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.courseMasteryPlacement,
            id: 'placementLevel',
          ),
        ),
      );
      expect(
        result.conflicts.where(
          (conflict) =>
              conflict.kind == AccountReconciliationConflictKind.documentField,
        ),
        isEmpty,
      );
    });

    test('maps every course conflict kind to its typed account kind', () {
      const expectedKinds =
          <CourseMasteryMergeConflictKind, AccountReconciliationConflictKind>{
            CourseMasteryMergeConflictKind.placement:
                AccountReconciliationConflictKind.courseMasteryPlacement,
            CourseMasteryMergeConflictKind.version:
                AccountReconciliationConflictKind.courseMasteryVersion,
            CourseMasteryMergeConflictKind.evidence:
                AccountReconciliationConflictKind.courseMasteryEvidence,
            CourseMasteryMergeConflictKind.checkpoint:
                AccountReconciliationConflictKind.courseMasteryCheckpoint,
            CourseMasteryMergeConflictKind.progression:
                AccountReconciliationConflictKind.courseMasteryProgression,
          };

      for (final entry in expectedKinds.entries) {
        final result = AccountReconciliationMerger.merge(
          local: _snapshot(courseMastery: const CourseMasterySnapshot()),
          remote: AccountReconciliationSnapshot.empty,
          catalog: catalog,
          courseMasteryMerger: ({required local, required remote}) =>
              CourseMasteryMergeResult.conflicted([
                CourseMasteryMergeConflict(kind: entry.key, id: 'typed-id'),
              ]),
        );

        expect(result.conflicts, [
          AccountReconciliationConflict(kind: entry.value, id: 'typed-id'),
        ], reason: entry.key.name);
      }
    });

    test(
      'blocks typed course data without a merger instead of raw fallback',
      () {
        final result = AccountReconciliationMerger.merge(
          local: _snapshot(
            courseMastery: const CourseMasterySnapshot(placementLevel: 'a1'),
          ),
          remote: AccountReconciliationSnapshot.empty,
          catalog: catalog,
        );

        expect(result.merged, isNull);
        expect(
          result.conflicts,
          contains(
            const AccountReconciliationConflict(
              kind: AccountReconciliationConflictKind.courseMasteryVersion,
              id: 'merger',
            ),
          ),
        );
      },
    );

    test('strips manually injected raw course fields before generic merge', () {
      final local = _snapshot(
        fields: const {
          'course_mastery_json': '{"version":1}',
          'profile': {'xp': 4},
        },
      );
      final remote = _snapshot(
        fields: const {
          'course_mastery_json': '{"version":2}',
          'profile': {'xp': 4},
        },
      );

      final result = AccountReconciliationMerger.merge(
        local: local,
        remote: remote,
        catalog: catalog,
      );

      expect(local.fields, isNot(contains('course_mastery_json')));
      expect(remote.fields, isNot(contains('course_mastery_json')));
      expect(result.conflicts, isEmpty);
      expect(
        result.merged!.toCloudDocument(),
        isNot(contains('course_mastery_json')),
      );
    });

    test(
      'raw field injection cannot dilute a missing typed course merger conflict',
      () {
        final result = AccountReconciliationMerger.merge(
          local: _snapshot(
            fields: const {'course_mastery_json': '{"version":1}'},
            courseMastery: const CourseMasterySnapshot(placementLevel: 'a1'),
          ),
          remote: _snapshot(
            fields: const {'course_mastery_json': '{"version":2}'},
          ),
          catalog: catalog,
        );

        expect(result.merged, isNull);
        expect(result.conflicts, const [
          AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.courseMasteryVersion,
            id: 'merger',
          ),
        ]);
      },
    );
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

    test(
      'decodes course mastery separately and serializes canonical typed JSON',
      () {
        final result = AccountReconciliationSnapshot.decodeCloudDocument({
          'course_mastery_json': jsonEncode({
            'placementLevel': 'a1',
            'currentCourseUnitId': 'unit-root',
            'completedUnitIds': <String>[],
            'bypassedPrerequisiteUnitIds': <String>[],
            'evidence': <Object?>[],
            'scenarioCheckpoints': <Object?>[],
          }),
          'profile': {'xp': 4},
        });

        expect(result.state, CloudReadState.present);
        expect(result.value!.fields, {
          'profile': {'xp': 4},
        });
        expect(result.value!.fields, isNot(contains('course_mastery_json')));
        expect(result.value!.courseMastery!.version, 2);
        expect(result.value!.courseMastery!.currentCourseUnitId, 'unit-root');
        expect(
          jsonDecode(
            result.value!.toCloudDocument()['course_mastery_json'] as String,
          ),
          {
            'version': 2,
            'placementLevel': 'a1',
            'currentCourseUnitId': 'unit-root',
            'completedUnitIds': <Object?>[],
            'bypassedPrerequisiteUnitIds': <Object?>[],
            'evidence': <Object?>[],
            'scenarioCheckpoints': <Object?>[],
          },
        );
      },
    );

    test('rejects every unsupported course payload shape', () {
      final malformedV2 = {
        'version': 2,
        'evidence': [
          {'id': 42},
        ],
      };
      final cases = <String, Object?>{
        'non-string': 42,
        'non-object': '[]',
        'future-version': jsonEncode({'version': 3}),
        'malformed-json': '{not-json',
        'malformed-v2': jsonEncode(malformedV2),
      };

      for (final entry in cases.entries) {
        final result = AccountReconciliationSnapshot.decodeCloudDocument({
          'course_mastery_json': entry.value,
        });

        expect(result.state, CloudReadState.invalid, reason: entry.key);
        expect(result.value, isNull, reason: entry.key);
      }
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
        writeLocal: (_, {required session, required sessions}) async =>
            localWrites += 1,
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
          writeLocal: (_, {required session, required sessions}) async =>
              writes += 1,
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
        writeLocal: (_, {required session, required sessions}) async {},
      );

      final result = await coordinator.reconcile(
        session: ready,
        operationId: 'operation-1',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.blocked);
      expect(reads, 0);
    });

    test(
      'session switch during async local capture prevents remote and local effects',
      () async {
        var remoteWrites = 0;
        var localWrites = 0;
        final coordinator = AccountReconciliationCoordinator(
          sessions: sessions,
          journalStore: journalStore,
          readRemote: () async =>
              const CloudReadResult<AccountReconciliationSnapshot>.absent(),
          loadLocal: () async {
            await Future<void>.value();
            sessions.transition(CloudWriteMode.cleanupPending);
            return _snapshot(fields: {'xp': 1});
          },
          writeRemote:
              (_, {required expectedRevision, required operationId}) async {
                remoteWrites += 1;
                return const ReconciliationWriteResult.committed(revision: 1);
              },
          writeLocal: (_, {required session, required sessions}) async {
            localWrites += 1;
          },
        );

        final result = await coordinator.reconcile(
          session: reconciling,
          operationId: 'operation-async-local-capture',
          catalog: const {},
        );

        expect(result.status, AccountReconciliationStatus.stale);
        expect(remoteWrites, 0);
        expect(localWrites, 0);
      },
    );

    test(
      'session switch during delayed local write prevents the stale effect',
      () async {
        SharedPreferences.setMockInitialValues({});
        Storage.resetForTesting();
        Storage.resetPackProgressForTesting();
        await Storage.init();
        final localWriteStarted = Completer<void>();
        final finishLocalWrite = Completer<void>();
        final coordinator = AccountReconciliationCoordinator(
          sessions: sessions,
          journalStore: journalStore,
          readRemote: () async => CloudReadResult.present(
            _snapshot(srs: {'word-a': _srs(reviewCount: 1)}),
            revision: 1,
          ),
          loadLocal: () => AccountReconciliationSnapshot.empty,
          writeRemote:
              (_, {required expectedRevision, required operationId}) async =>
                  const ReconciliationWriteResult.committed(revision: 1),
          writeLocal: (snapshot, {required session, required sessions}) async {
            localWriteStarted.complete();
            await finishLocalWrite.future;
            await LocalAccountReconciliationStore.write(
              snapshot,
              session: session,
              sessions: sessions,
            );
          },
        );

        final reconciliation = coordinator.reconcile(
          session: reconciling,
          operationId: 'operation-1',
          catalog: const {},
        );
        await localWriteStarted.future;
        sessions.acquire('uid-b');
        finishLocalWrite.complete();
        final result = await reconciliation;

        expect(result.status, AccountReconciliationStatus.stale);
        expect(Storage.srsRawJson, isEmpty);
      },
    );

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
        writeLocal: (_, {required session, required sessions}) async {},
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
              writeLocal: (_, {required session, required sessions}) async {},
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
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              packWrites += 1;
              expect(expectedMembershipRevision, 4);
              expect(expectedMembershipPackIds, const <String>{});
              return const FirestorePackCasResult.revisionConflict();
            },
      );

      expect(result.status, ReconciliationWriteStatus.revisionConflict);
      expect(rootWrites, 1);
      expect(packWrites, 1);
    },
  );

  test(
    'secondary target adapter keeps the source fence distinct from remote UID',
    () async {
      final sessions = CloudWriteSessionController()
        ..acquire('anonymous-source');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var rootWrites = 0;
      var packWrites = 0;
      var compositeChecks = 0;
      final adapter = FirebaseAccountReconciliationAdapter(
        uid: 'durable-target',
        fenceUid: 'anonymous-source',
        session: session,
        sessions: sessions,
      );

      final result = await adapter.writeRemote(
        _snapshot(packMembershipRevision: 0),
        expectedRevision: null,
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
              expect(uid, 'durable-target');
              expect(session.uid, 'anonymous-source');
              return const CloudSyncCasResult.committed(1);
            },
        packWriter:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              packWrites += 1;
              expect(uid, 'durable-target');
              expect(session.uid, 'anonymous-source');
              return const FirestorePackCasResult.committed(
                {},
                membershipRevision: 1,
                membershipPackIds: {},
              );
            },
        compositeValidator:
            ({
              required uid,
              required data,
              required expectedRevision,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              compositeChecks += 1;
              expect(uid, 'durable-target');
              expect(session.uid, 'anonymous-source');
              return true;
            },
      );

      expect(result.status, ReconciliationWriteStatus.committed);
      expect(rootWrites, 1);
      expect(packWrites, 1);
      expect(compositeChecks, 1);
      expect(sessions.current, session);
    },
  );

  test(
    'post-pack root advance is re-read before any stale local effect',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final adapter = FirebaseAccountReconciliationAdapter(
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      );
      var remote = _snapshot(srs: {'word-a': _srs(reviewCount: 1)});
      var remoteRevision = 1;
      var remoteReads = 0;
      var rootWrites = 0;
      var packWrites = 0;
      var compositeValidations = 0;
      var localWrites = 0;
      Map<String, dynamic>? lastRootData;
      AccountReconciliationSnapshot? persistedLocal;
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: _MemoryJournalStore(),
        readRemote: () async {
          remoteReads += 1;
          return CloudReadResult.present(remote, revision: remoteRevision);
        },
        loadLocal: () => AccountReconciliationSnapshot.empty,
        writeRemote:
            (snapshot, {required expectedRevision, required operationId}) =>
                adapter.writeRemote(
                  snapshot,
                  expectedRevision: expectedRevision,
                  operationId: operationId,
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
                        expect(expectedRevision, remoteRevision);
                        lastRootData = Map<String, dynamic>.from(data);
                        remote = snapshot;
                        remoteRevision += 1;
                        return CloudSyncCasResult.committed(remoteRevision);
                      },
                  packWriter:
                      ({
                        required uid,
                        required progresses,
                        required expectedRevisions,
                        required expectedMembershipRevision,
                        required expectedMembershipPackIds,
                        required operationId,
                        required session,
                        required sessions,
                      }) async {
                        packWrites += 1;
                        if (packWrites == 1) {
                          remote = _snapshot(
                            srs: {'word-a': _srs(reviewCount: 2)},
                          );
                          remoteRevision += 1;
                        }
                        return const FirestorePackCasResult.committed(
                          {},
                          membershipRevision: 1,
                          membershipPackIds: {},
                        );
                      },
                  compositeValidator:
                      ({
                        required uid,
                        required data,
                        required expectedRevision,
                        required expectedMembershipRevision,
                        required expectedMembershipPackIds,
                        required operationId,
                        required session,
                        required sessions,
                      }) async {
                        compositeValidations += 1;
                        expect(uid, 'uid-a');
                        expect(data, lastRootData);
                        expect(expectedMembershipRevision, 1);
                        expect(expectedMembershipPackIds, isEmpty);
                        expect(operationId, 'operation-1');
                        return expectedRevision == remoteRevision;
                      },
                ),
        writeLocal: (snapshot, {required session, required sessions}) async {
          localWrites += 1;
          persistedLocal = snapshot;
        },
      );

      final result = await coordinator.reconcile(
        session: session,
        operationId: 'operation-1',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(remoteReads, 2);
      expect(rootWrites, 2);
      expect(packWrites, 2);
      expect(compositeValidations, 2);
      expect(localWrites, 1);
      expect(persistedLocal?.srsCards['word-a'], _srs(reviewCount: 2));
    },
  );

  test(
    'post-pack membership advance is re-read before stale pack local effect',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final adapter = FirebaseAccountReconciliationAdapter(
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      );
      final oldProgress = _progressForLocalStore();
      final newProgress = oldProgress.copyWith(
        status: PackStatus.inProgress,
        wordsLearned: 2,
      );
      var remote = _snapshot(
        packs: {'pack-a': oldProgress},
        packRevisions: const {'pack-a': 1},
        packMembershipRevision: 1,
      );
      var remoteRevision = 1;
      var remoteReads = 0;
      var rootWrites = 0;
      var packWrites = 0;
      var compositeValidations = 0;
      var localWrites = 0;
      AccountReconciliationSnapshot? persistedLocal;
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: _MemoryJournalStore(),
        readRemote: () async {
          remoteReads += 1;
          return CloudReadResult.present(remote, revision: remoteRevision);
        },
        loadLocal: () => AccountReconciliationSnapshot.empty,
        writeRemote:
            (snapshot, {required expectedRevision, required operationId}) =>
                adapter.writeRemote(
                  snapshot,
                  expectedRevision: expectedRevision,
                  operationId: operationId,
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
                        expect(expectedRevision, remoteRevision);
                        remote = snapshot;
                        remoteRevision += 1;
                        return CloudSyncCasResult.committed(remoteRevision);
                      },
                  packWriter:
                      ({
                        required uid,
                        required progresses,
                        required expectedRevisions,
                        required expectedMembershipRevision,
                        required expectedMembershipPackIds,
                        required operationId,
                        required session,
                        required sessions,
                      }) async {
                        packWrites += 1;
                        if (packWrites == 1) {
                          remote = _snapshot(
                            packs: {'pack-a': newProgress},
                            packRevisions: const {'pack-a': 3},
                            packMembershipRevision: 3,
                          );
                          return const FirestorePackCasResult.committed(
                            {'pack-a': 2},
                            membershipRevision: 2,
                            membershipPackIds: {'pack-a'},
                          );
                        }
                        remote = _snapshot(
                          packs: {'pack-a': newProgress},
                          packRevisions: const {'pack-a': 4},
                          packMembershipRevision: 4,
                        );
                        return const FirestorePackCasResult.committed(
                          {'pack-a': 4},
                          membershipRevision: 4,
                          membershipPackIds: {'pack-a'},
                        );
                      },
                  compositeValidator:
                      ({
                        required uid,
                        required data,
                        required expectedRevision,
                        required expectedMembershipRevision,
                        required expectedMembershipPackIds,
                        required operationId,
                        required session,
                        required sessions,
                      }) async {
                        compositeValidations += 1;
                        return expectedRevision == remoteRevision &&
                            expectedMembershipRevision ==
                                remote.packMembershipRevision &&
                            expectedMembershipPackIds.length ==
                                remote.packProgress.length &&
                            expectedMembershipPackIds.containsAll(
                              remote.packProgress.keys,
                            );
                      },
                ),
        writeLocal: (snapshot, {required session, required sessions}) async {
          localWrites += 1;
          persistedLocal = snapshot;
        },
      );

      final result = await coordinator.reconcile(
        session: session,
        operationId: 'operation-1',
        catalog: const {
          'pack-a': PackCatalogEntry(
            packId: 'pack-a',
            level: 'A1',
            wordsTotal: 10,
          ),
        },
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(remoteReads, 2);
      expect(rootWrites, 2);
      expect(packWrites, 2);
      expect(compositeValidations, 2);
      expect(localWrites, 1);
      expect(
        persistedLocal?.packProgress['pack-a']?.toJson(),
        newProgress.toJson(),
      );
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
        fields: {
          'progress': {
            'owned_decor': ['decoration_soban', 'decoration_munbangsau'],
          },
        },
        srs: {'word-a': _srs(reviewCount: 1)},
        customPacks: {'cp-a': _pack(name: 'Local')},
        packs: {'pack-a': _progressForLocalStore()},
      );

      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      await LocalAccountReconciliationStore.write(
        snapshot,
        session: session,
        sessions: sessions,
      );
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final restored = await LocalAccountReconciliationStore.load();

      expect(restored.srsCards, snapshot.srsCards);
      expect(restored.customPacks, snapshot.customPacks);
      expect(
        restored.packProgress['pack-a']?.toJson(),
        snapshot.packProgress['pack-a']?.toJson(),
      );
      expect(
        Storage.ownedDecor,
        ['decoration_soban', 'decoration_munbangsau'],
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

      await expectLater(
        LocalAccountReconciliationStore.load(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'local reconciliation capture migrates retained v1 course state before merge',
    () async {
      final legacy = jsonEncode({
        ...CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit-root',
        ).toJson(),
        'version': 1,
      });
      await _initializeLocalReconciliationStorage({
        Storage.legacyCourseMasteryPreferenceKey: legacy,
        Storage.browseLevelPreferenceKey: 'b2',
        'kl_user_level': 'a2',
      });

      final local = await LocalAccountReconciliationStore.load(
        courseProgress: _courseProgressForLocalCapture(),
      );

      expect(local.courseMastery?.version, 2);
      expect(local.courseMastery?.currentCourseUnitId, 'unit-root');
      expect(
        local.localCourseMasteryGeneration,
        Storage.courseMasterySnapshotRawJson,
      );
      expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
      expect(Storage.legacyCourseMasteryRawJson, legacy);
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.userLevelCode, 'a2');
    },
  );

  test(
    'local reconciliation capture migrates dedicated scalar course state',
    () async {
      await _initializeLocalReconciliationStorage({
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: 'unit-root',
        Storage.browseLevelPreferenceKey: 'b2',
        'kl_user_level': 'a2',
      });

      final local = await LocalAccountReconciliationStore.load(
        courseProgress: _courseProgressForLocalCapture(),
      );

      expect(local.courseMastery?.version, 2);
      expect(local.courseMastery?.placementLevel, 'a1');
      expect(local.courseMastery?.currentCourseUnitId, 'unit-root');
      expect(
        local.localCourseMasteryGeneration,
        Storage.courseMasterySnapshotRawJson,
      );
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.userLevelCode, 'a2');
    },
  );

  test(
    'local reconciliation rejects invalid legacy and catalog-invalid canonical course state',
    () async {
      const malformedLegacy = '{not-json';
      await _initializeLocalReconciliationStorage({
        Storage.legacyCourseMasteryPreferenceKey: malformedLegacy,
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: 'unit-root',
        Storage.browseLevelPreferenceKey: 'b2',
      });

      await expectLater(
        LocalAccountReconciliationStore.load(
          courseProgress: _courseProgressForLocalCapture(),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      expect(Storage.legacyCourseMasteryRawJson, malformedLegacy);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
      expect(Storage.courseUnitId, 'unit-root');
      expect(Storage.browseLevelCode, 'b2');

      final invalidV2 = jsonEncode(
        CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unknown-course-unit',
        ).toJson(),
      );
      await _initializeLocalReconciliationStorage({
        Storage.courseMasterySnapshotPreferenceKey: invalidV2,
        Storage.browseLevelPreferenceKey: 'b2',
      });

      await expectLater(
        LocalAccountReconciliationStore.load(
          courseProgress: _courseProgressForLocalCapture(),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(Storage.courseMasterySnapshotRawJson, invalidV2);
      expect(Storage.browseLevelCode, 'b2');
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

  test(
    'media edit finishing during remote write is not overwritten by stale local commit',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final original = ExtractedWord.manual(
        korean: '?덈뀞',
        translationDe: 'Hallo',
      );
      final pack = CustomPack.manual(
        id: 'cp-a',
        name: 'Pack',
        words: [original],
        createdAt: DateTime.utc(2026, 7, 30),
      );
      await Storage.setCustomPacksRawJsonStrict(
        jsonEncode({'cp-a': pack.toLocalJson()}),
      );

      final sandbox = await Directory.systemTemp.createTemp(
        'account_reconciliation_media_',
      );
      final documents = Directory(
        '${sandbox.path}${Platform.pathSeparator}docs',
      )..createSync();
      final temporary = Directory(
        '${sandbox.path}${Platform.pathSeparator}cache',
      )..createSync();
      final mediaStore = ManagedMediaStore(
        documentsDirectory: documents,
        temporaryDirectory: temporary,
        nonce: () => 'edited-photo',
      );
      BookImageService.setStoreForTesting(mediaStore);
      try {
        final source = File(
          '${sandbox.path}${Platform.pathSeparator}replacement.jpg',
        )..writeAsBytesSync([1, 2, 3]);
        final pending = await mediaStore.stage(source, ManagedMediaKind.word);
        final sessions = CloudWriteSessionController()..acquire('uid-a');
        final session = sessions.transition(CloudWriteMode.reconciling);
        final journalStore = _MemoryJournalStore();
        var remote = _snapshot(fields: {'cloudOnly': 1});
        var remoteRevision = 1;
        var remoteWrites = 0;
        var localReads = 0;
        final remoteWriteStarted = Completer<void>();
        final finishRemoteWrite = Completer<void>();
        final coordinator = AccountReconciliationCoordinator(
          sessions: sessions,
          journalStore: journalStore,
          readRemote: () async =>
              CloudReadResult.present(remote, revision: remoteRevision),
          loadLocal: () {
            localReads += 1;
            return LocalAccountReconciliationStore.load();
          },
          writeRemote:
              (
                snapshot, {
                required expectedRevision,
                required operationId,
              }) async {
                remoteWrites += 1;
                remote = snapshot;
                remoteRevision += 1;
                remoteWriteStarted.complete();
                await finishRemoteWrite.future;
                return ReconciliationWriteResult.committed(
                  revision: remoteRevision,
                );
              },
          writeLocal: LocalAccountReconciliationStore.write,
        );

        final reconciliation = coordinator.reconcile(
          session: session,
          operationId: 'operation-1',
          catalog: const {},
        );
        await remoteWriteStarted.future;
        final edited = await CustomPackService.updateWordWithMedia(
          packId: 'cp-a',
          index: 0,
          expectedOriginal: original,
          word: original.copyWithEditable(translationDe: 'Neu'),
          pendingLease: pending,
        );
        final editedImagePath = edited!.words.single.imagePath;
        expect(editedImagePath, isNotEmpty);

        finishRemoteWrite.complete();
        final result = await reconciliation;
        final persisted = CustomPackService.getById('cp-a')!.words.single;

        expect(result.status, AccountReconciliationStatus.blocked);
        expect(
          result.conflicts,
          contains(
            const AccountReconciliationConflict(
              kind: AccountReconciliationConflictKind.customPackId,
              id: 'cp-a',
            ),
          ),
        );
        expect(remoteWrites, 1);
        expect(localReads, 2);
        expect(persisted.translationDe, 'Neu');
        expect(persisted.imagePath, editedImagePath);
      } finally {
        BookImageService.setStoreForTesting(null);
        await sandbox.delete(recursive: true);
      }
    },
  );

  test(
    'SRS review finishing during remote write is not overwritten by stale local commit',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      await Storage.setSrsRawJsonStrict(
        jsonEncode({'word-a': _srs(reviewCount: 1)}),
      );
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var remote = _snapshot(fields: {'cloudOnly': 1});
      var remoteRevision = 1;
      var remoteWrites = 0;
      var localReads = 0;
      final remoteWriteStarted = Completer<void>();
      final finishRemoteWrite = Completer<void>();
      final journalStore = _MemoryJournalStore();
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: journalStore,
        readRemote: () async =>
            CloudReadResult.present(remote, revision: remoteRevision),
        loadLocal: () {
          localReads += 1;
          return LocalAccountReconciliationStore.load();
        },
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async {
              remoteWrites += 1;
              remote = snapshot;
              remoteRevision += 1;
              remoteWriteStarted.complete();
              await finishRemoteWrite.future;
              return ReconciliationWriteResult.committed(
                revision: remoteRevision,
              );
            },
        writeLocal: LocalAccountReconciliationStore.write,
      );

      final reconciliation = coordinator.reconcile(
        session: session,
        operationId: 'operation-1',
        catalog: const {},
      );
      await remoteWriteStarted.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError('remote SRS write did not start'),
      );
      await Storage.srsReview('word-a', gotIt: true).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError('local SRS review did not finish'),
      );
      finishRemoteWrite.complete();
      final result = await reconciliation;
      final persisted =
          (jsonDecode(Storage.srsRawJson) as Map)['word-a'] as Map;

      expect(result.status, AccountReconciliationStatus.blocked);
      expect(
        result.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.srsCardHistory,
            id: 'word-a',
          ),
        ),
      );
      expect(remoteWrites, 1);
      expect(localReads, 2);
      expect(persisted['r'], 2);
    },
  );

  test(
    'pack progress finishing during remote write survives stale local commit',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      final initial = _progressForLocalStore();
      await Storage.setPackProgressJson('pack-a', initial.toJson());
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var remote = _snapshot(fields: {'cloudOnly': 1});
      var remoteRevision = 1;
      var remoteWrites = 0;
      var localReads = 0;
      final remoteWriteStarted = Completer<void>();
      final finishRemoteWrite = Completer<void>();
      final journalStore = _MemoryJournalStore();
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: journalStore,
        readRemote: () async =>
            CloudReadResult.present(remote, revision: remoteRevision),
        loadLocal: () {
          localReads += 1;
          return LocalAccountReconciliationStore.load();
        },
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async {
              remoteWrites += 1;
              remote = snapshot;
              remoteRevision += 1;
              if (remoteWrites == 1) {
                remoteWriteStarted.complete();
                await finishRemoteWrite.future;
              }
              return ReconciliationWriteResult.committed(
                revision: remoteRevision,
              );
            },
        writeLocal: LocalAccountReconciliationStore.write,
      );

      final reconciliation = coordinator.reconcile(
        session: session,
        operationId: 'operation-1',
        catalog: const {
          'pack-a': PackCatalogEntry(
            packId: 'pack-a',
            level: 'A1',
            wordsTotal: 10,
          ),
        },
      );
      await remoteWriteStarted.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError('remote pack write did not start'),
      );
      await Storage.setPackProgressJson(
        'pack-a',
        initial
            .copyWith(status: PackStatus.inProgress, wordsLearned: 2)
            .toJson(),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError('local pack update did not finish'),
      );
      finishRemoteWrite.complete();
      final result = await reconciliation;
      final persisted = PackProgressService.get('pack-a')!;

      expect(result.status, AccountReconciliationStatus.completed);
      expect(remoteWrites, 2);
      expect(localReads, 2);
      expect(persisted.status, PackStatus.inProgress);
      expect(persisted.wordsLearned, 2);
    },
  );

  test(
    'local custom-pack delete during remote write is not resurrected on retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final pack = CustomPack.manual(
        id: 'cp-a',
        name: 'Local',
        words: const [],
        createdAt: DateTime.utc(2026, 7, 30),
      );
      await CustomPackService.save(pack);
      final preferences = await SharedPreferences.getInstance();
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var remote = _snapshot(fields: {'cloudOnly': 1});
      var remoteRevision = 1;
      var remoteWrites = 0;
      var localReads = 0;
      final remoteWriteStarted = Completer<void>();
      final finishRemoteWrite = Completer<void>();
      final journalStore = SharedPreferencesAccountTransitionJournalStore(
        preferences,
      );
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: journalStore,
        readRemote: () async =>
            CloudReadResult.present(remote, revision: remoteRevision),
        loadLocal: () {
          localReads += 1;
          return LocalAccountReconciliationStore.load();
        },
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async {
              remoteWrites += 1;
              remote = snapshot;
              remoteRevision += 1;
              remoteWriteStarted.complete();
              await finishRemoteWrite.future;
              return ReconciliationWriteResult.committed(
                revision: remoteRevision,
              );
            },
        writeLocal: LocalAccountReconciliationStore.write,
      );

      final reconciliation = coordinator.reconcile(
        session: session,
        operationId: 'operation-1',
        catalog: const {},
      );
      await remoteWriteStarted.future;
      await CustomPackService.delete('cp-a');
      finishRemoteWrite.complete();
      final result = await reconciliation;

      expect(result.status, AccountReconciliationStatus.blocked);
      expect(
        result.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.customPackId,
            id: 'cp-a',
          ),
        ),
      );
      expect(remoteWrites, 1);
      expect(localReads, 2);
      expect(CustomPackService.getById('cp-a'), isNull);

      final resumed =
          await AccountReconciliationCoordinator(
            sessions: sessions,
            journalStore: journalStore,
            readRemote: () async =>
                CloudReadResult.present(remote, revision: remoteRevision),
            loadLocal: LocalAccountReconciliationStore.load,
            writeRemote:
                (_, {required expectedRevision, required operationId}) async {
                  remoteWrites += 1;
                  return ReconciliationWriteResult.committed(
                    revision: remoteRevision + 1,
                  );
                },
            writeLocal: LocalAccountReconciliationStore.write,
          ).reconcile(
            session: session,
            operationId: 'operation-1',
            catalog: const {},
          );

      expect(resumed.status, AccountReconciliationStatus.blocked);
      expect(
        resumed.conflicts,
        contains(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.customPackId,
            id: 'cp-a',
          ),
        ),
      );
      expect(remoteWrites, 1);
      expect(CustomPackService.getById('cp-a'), isNull);
    },
  );

  test(
    'remote change before no-op local persistence is re-read before any local effect',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      final oldProgress = _progressForLocalStore();
      final newProgress = oldProgress.copyWith(
        status: PackStatus.inProgress,
        wordsLearned: 2,
      );
      var remote = _snapshot(
        srs: {'word-a': _srs(reviewCount: 1)},
        packs: {'pack-a': oldProgress},
        packRevisions: const {'pack-a': 2},
        packMembershipRevision: 4,
      );
      var remoteRevision = 1;
      var remoteValidations = 0;
      var localWrites = 0;
      final validationStarted = Completer<void>();
      final localWriteStarted = Completer<void>();
      final resume = Completer<void>();
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final reconciliation =
          AccountReconciliationCoordinator(
            sessions: sessions,
            journalStore: _MemoryJournalStore(),
            readRemote: () async =>
                CloudReadResult.present(remote, revision: remoteRevision),
            loadLocal: () => AccountReconciliationSnapshot.empty,
            writeRemote:
                (
                  snapshot, {
                  required expectedRevision,
                  required operationId,
                }) async {
                  remoteValidations += 1;
                  if (remoteValidations == 1) {
                    validationStarted.complete();
                    await resume.future;
                  }
                  if (expectedRevision != remoteRevision ||
                      snapshot.packMembershipRevision !=
                          remote.packMembershipRevision) {
                    return const ReconciliationWriteResult.revisionConflict();
                  }
                  remote = snapshot;
                  remoteRevision += 1;
                  return ReconciliationWriteResult.committed(
                    revision: remoteRevision,
                  );
                },
            writeLocal:
                (snapshot, {required session, required sessions}) async {
                  localWrites += 1;
                  if (!localWriteStarted.isCompleted) {
                    localWriteStarted.complete();
                    await resume.future;
                  }
                  await LocalAccountReconciliationStore.write(
                    snapshot,
                    session: session,
                    sessions: sessions,
                  );
                },
          ).reconcile(
            session: session,
            operationId: 'operation-1',
            catalog: const {
              'pack-a': PackCatalogEntry(
                packId: 'pack-a',
                level: 'A1',
                wordsTotal: 10,
              ),
            },
          );

      await Future.any<void>([
        validationStarted.future,
        localWriteStarted.future,
      ]);
      remote = _snapshot(
        srs: {'word-a': _srs(reviewCount: 2)},
        packs: {'pack-a': newProgress},
        packRevisions: const {'pack-a': 3},
        packMembershipRevision: 5,
      );
      remoteRevision = 2;
      resume.complete();
      final result = await reconciliation;
      final persistedSrs =
          (jsonDecode(Storage.srsRawJson) as Map)['word-a'] as Map;
      final persistedProgress = PackProgressService.get('pack-a')!;

      expect(result.status, AccountReconciliationStatus.completed);
      expect(remoteValidations, 2);
      expect(localWrites, 1);
      expect(persistedSrs['r'], 2);
      expect(persistedProgress.wordsLearned, 2);
    },
  );

  test(
    'course write after local load retries instead of overwriting the learner action',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      Storage.resetCourseMasteryForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      final catalog = _courseCatalog();
      final initial = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit-root',
        evidence: [_courseEvidence(id: 'initial', second: 1)],
      );
      await Storage.setCourseMasterySnapshotRawJson(
        jsonEncode(initial.toJson()),
      );
      final courseProgress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      var remote = _snapshot(
        courseMastery: CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit-root',
          evidence: [_courseEvidence(id: 'remote', second: 2)],
        ),
      );
      var remoteRevision = 1;
      var remoteWrites = 0;
      var localReads = 0;
      final remoteWriteStarted = Completer<void>();
      final finishRemoteWrite = Completer<void>();
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: _MemoryJournalStore(),
        readRemote: () async =>
            CloudReadResult.present(remote, revision: remoteRevision),
        loadLocal: () {
          localReads += 1;
          return LocalAccountReconciliationStore.load(
            courseProgress: courseProgress,
          );
        },
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async {
              remoteWrites += 1;
              remote = snapshot;
              remoteRevision += 1;
              if (remoteWrites == 1) {
                remoteWriteStarted.complete();
                await finishRemoteWrite.future;
              }
              return ReconciliationWriteResult.committed(
                revision: remoteRevision,
              );
            },
        writeLocal: (snapshot, {required session, required sessions}) =>
            LocalAccountReconciliationStore.write(
              snapshot,
              session: session,
              sessions: sessions,
              courseProgress: courseProgress,
            ),
        courseMasteryMerger: CourseMasteryService(
          catalog,
        ).mergeForReconciliation,
      );

      final reconciliation = coordinator.reconcile(
        session: session,
        operationId: 'operation-course',
        catalog: const {},
      );
      await remoteWriteStarted.future;
      final generation = Storage.courseMasterySnapshotRawJson;
      final late = initial.copyWith(
        evidence: [
          ...initial.evidence,
          _courseEvidence(id: 'late-learner-action', second: 3),
        ],
      );
      await courseProgress.applyReconciledSnapshot(
        late,
        expectedGeneration: generation,
      );
      finishRemoteWrite.complete();

      final result = await reconciliation;
      final persisted = CourseMasterySnapshot.fromJson(
        (jsonDecode(Storage.courseMasterySnapshotRawJson) as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(remoteWrites, 2);
      expect(localReads, 2);
      expect(persisted.evidence.map((item) => item.id), [
        'initial',
        'remote',
        'late-learner-action',
      ]);
    },
  );

  test(
    'queued production course write rechecks the session at canonical persistence',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      Storage.resetCourseMasteryForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      final catalog = _courseCatalog();
      final initial = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit-root',
        evidence: [_courseEvidence(id: 'initial', second: 1)],
      );
      final initialRaw = jsonEncode(initial.toJson());
      await Storage.setCourseMasterySnapshotRawJson(initialRaw);
      final loaderStarted = Completer<void>();
      final releaseLoader = Completer<void>();
      final courseProgress = CourseProgressService(() async {
        loaderStarted.complete();
        await releaseLoader.future;
        return CourseMasteryService(catalog);
      });
      final localCaptureProgress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      final remote = _snapshot(
        courseMastery: CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit-root',
          evidence: [_courseEvidence(id: 'remote', second: 2)],
        ),
      );
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: _MemoryJournalStore(),
        readRemote: () async => CloudReadResult.present(remote, revision: 1),
        loadLocal: () => LocalAccountReconciliationStore.load(
          courseProgress: localCaptureProgress,
        ),
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async => const ReconciliationWriteResult.committed(revision: 2),
        writeLocal: (snapshot, {required session, required sessions}) =>
            LocalAccountReconciliationStore.write(
              snapshot,
              session: session,
              sessions: sessions,
              courseProgress: courseProgress,
            ),
        courseMasteryMerger: CourseMasteryService(
          catalog,
        ).mergeForReconciliation,
      );

      final reconciliation = coordinator.reconcile(
        session: session,
        operationId: 'operation-session-race',
        catalog: const {},
      );
      await loaderStarted.future;
      sessions.transition(CloudWriteMode.cleanupPending);
      releaseLoader.complete();

      final result = await reconciliation;

      expect(result.status, AccountReconciliationStatus.stale);
      expect(Storage.courseMasterySnapshotRawJson, initialRaw);
    },
  );

  test(
    'strict preparation session switch blocks the underlying canonical set',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      Storage.resetCourseMasteryForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      await Storage.setDedicatedCoursePlacementLevelCode('a2');
      await Storage.setCourseUnitId('old-unit');
      final catalog = _courseCatalog();
      final initial = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit-root',
        evidence: [_courseEvidence(id: 'initial', second: 1)],
      );
      final initialRaw = jsonEncode(initial.toJson());
      await Storage.setCourseMasterySnapshotRawJson(initialRaw);
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final canonicalStore = _SessionSwitchingCourseStore(
        initialRaw: initialRaw,
        onPreparationRead: () =>
            sessions.transition(CloudWriteMode.cleanupPending),
      );
      final courseProgress = CourseProgressService(
        () async =>
            CourseMasteryService(catalog, snapshotPreferences: canonicalStore),
      );
      final localCaptureProgress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      final remote = _snapshot(
        courseMastery: CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit-root',
          evidence: [_courseEvidence(id: 'remote', second: 2)],
        ),
      );
      final coordinator = AccountReconciliationCoordinator(
        sessions: sessions,
        journalStore: _MemoryJournalStore(),
        readRemote: () async => CloudReadResult.present(remote, revision: 1),
        loadLocal: () => LocalAccountReconciliationStore.load(
          courseProgress: localCaptureProgress,
        ),
        writeRemote:
            (
              snapshot, {
              required expectedRevision,
              required operationId,
            }) async => const ReconciliationWriteResult.committed(revision: 2),
        writeLocal: (snapshot, {required session, required sessions}) =>
            LocalAccountReconciliationStore.write(
              snapshot,
              session: session,
              sessions: sessions,
              courseProgress: courseProgress,
            ),
        courseMasteryMerger: CourseMasteryService(
          catalog,
        ).mergeForReconciliation,
      );

      final result = await coordinator.reconcile(
        session: session,
        operationId: 'operation-storage-preparation-race',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.stale);
      expect(canonicalStore.setStringCalls, 0);
      expect(canonicalStore.canonicalRaw, initialRaw);
      expect(Storage.courseMasterySnapshotRawJson, initialRaw);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a2');
      expect(Storage.courseUnitId, 'old-unit');
    },
  );
}

Future<void> _initializeLocalReconciliationStorage(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues({
    'kl_custom_packs_v1': '{}',
    ...values,
  });
  Storage.resetForTesting();
  Storage.resetPackProgressForTesting();
  await Storage.init();
}

AccountReconciliationSnapshot _snapshot({
  Map<String, Object?> fields = const {},
  Map<String, Map<String, Object?>> srs = const {},
  Map<String, Map<String, Object?>> customPacks = const {},
  Map<String, PackProgress> packs = const {},
  Map<String, int?> packRevisions = const {},
  int? packMembershipRevision,
  CourseMasterySnapshot? courseMastery,
}) {
  return AccountReconciliationSnapshot(
    fields: fields,
    srsCards: srs,
    customPacks: customPacks,
    packProgress: packs,
    packRevisions: packRevisions,
    packMembershipRevision: packMembershipRevision,
    courseMastery: courseMastery,
  );
}

MasteryEvidence _courseEvidence({required String id, required int second}) =>
    MasteryEvidence(
      id: id,
      conceptId: 'concept-greeting',
      contentKind: CurriculumContentKind.grammar,
      contentId: 'grammar-greeting',
      courseUnitId: 'unit-root',
      isCorrect: true,
      occurredAt: DateTime.utc(2026, 8, 3, 0, 0, second),
      courseEligible: true,
    );

CurriculumCatalog _courseCatalog() {
  final grammar = Grammar(
    id: 'grammar-greeting',
    pattern: 'greeting',
    level: 'a1',
    typeDe: 'Test',
    explanationDe: '',
    exampleKorean: '',
    exampleGerman: '',
    note: '',
  );
  return CurriculumCatalog.fromDataForTesting(
    manifestJson: const {
      'version': 2,
      'courseUnits': [
        {
          'id': 'unit-root',
          'level': 'a1',
          'order': 1,
          'title': {'ko': 'root', 'de': 'root', 'en': 'root'},
          'canDo': {'ko': 'root', 'de': 'root', 'en': 'root'},
          'requiredConceptIds': ['concept-greeting'],
        },
      ],
      'concepts': [
        {
          'id': 'concept-greeting',
          'level': 'a1',
          'kind': 'speechStyle',
          'title': {'ko': 'greeting', 'de': 'greeting', 'en': 'greeting'},
          'explanation': {'ko': 'greeting', 'de': 'greeting', 'en': 'greeting'},
        },
      ],
      'surfaceForms': <Map<String, dynamic>>[],
      'formFamilies': <Map<String, dynamic>>[],
      'contentLinks': <Map<String, dynamic>>[],
      'vocabPackUnitMap': <String, String>{},
      'smalltalkCategoryUnitMap': <String, String>{},
      'clozeTopicUnitMap': <String, String>{},
      'grammarRuleMap': {
        'grammar-greeting': {
          'courseUnitId': 'unit-root',
          'conceptIds': ['concept-greeting'],
        },
      },
    },
    vocab: const [],
    grammar: [grammar],
    smalltalk: const [],
    cloze: const [],
    satz: const [],
    scenarios: const [],
  );
}

CourseProgressService _courseProgressForLocalCapture() =>
    CourseProgressService(() async => CourseMasteryService(_courseCatalog()));

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
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) async {
    if (!identical(value, expected) || !isCurrent()) return false;
    value = next;
    return true;
  }

  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) async {
    if (value != null) return identical(value, expected);
    if (!isCurrent()) return false;
    value = expected;
    return true;
  }

  @override
  Future<void> write(AccountTransitionJournal journal) async {
    value = journal;
  }
}

class _SessionSwitchingCourseStore implements PreferenceStringStore {
  _SessionSwitchingCourseStore({
    required String initialRaw,
    required this.onPreparationRead,
  }) : _values = {Storage.courseMasterySnapshotPreferenceKey: initialRaw};

  final Map<String, String> _values;
  final void Function() onPreparationRead;
  bool _switched = false;
  int setStringCalls = 0;

  String? get canonicalRaw =>
      _values[Storage.courseMasterySnapshotPreferenceKey];

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  String? getString(String key) {
    if (key == Storage.courseMasterySnapshotPreferenceKey && !_switched) {
      _switched = true;
      onPreparationRead();
    }
    return _values[key];
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;

  @override
  Future<bool> setString(String key, String value) async {
    setStringCalls += 1;
    _values[key] = value;
    return true;
  }
}
