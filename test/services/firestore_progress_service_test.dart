import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';

void main() {
  test('ready pack writes advance and retain manifest membership', () {
    final next = const FirestorePackMembership(
      revision: 4,
      packIds: {'pack-a'},
    ).afterWriting(const {'pack-b'});

    expect(next.revision, 5);
    expect(next.packIds, {'pack-a', 'pack-b'});
  });

  test(
    'observed manifest override cannot hide a versioned pack from CAS',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var writes = 0;
      final result = await FirestoreProgressService.saveManyReconciled(
        uid: 'uid-a',
        progresses: [
          PackProgress.fresh(packId: 'pack-a', level: 'A1', wordsTotal: 10),
          PackProgress.fresh(packId: 'pack-b', level: 'A1', wordsTotal: 10),
        ],
        expectedRevisions: {'pack-a': 1, 'pack-b': 1},
        expectedMembershipRevision: 3,
        expectedMembershipPackIds: {'pack-b'},
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedLegacyDocuments,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes++;
              return const FirestorePackCasResult.committed(
                {'pack-a': 2, 'pack-b': 2},
                membershipRevision: 4,
                membershipPackIds: {'pack-a', 'pack-b'},
              );
            },
      );
      expect(result.status, FirestorePackCasStatus.revisionConflict);
      expect(writes, 0);
    },
  );

  group('FirestoreProgressService.loadAllTyped', () {
    for (final change in [
      'learning',
      'operation tag',
      'revision',
      'nested metadata',
      'timestamp',
    ]) {
      test(
        'legacy adoption retries concurrent $change without overwriting it',
        () async {
          final data = {
            ...PackProgress.fresh(
              packId: 'pack-a',
              level: 'A1',
              wordsTotal: 10,
            ).copyWith(wordsLearned: 7, status: PackStatus.inProgress).toJson(),
            'updatedAt': Timestamp(100, 0),
            'extra': {
              'items': [1, 2],
            },
          };
          final read = await FirestoreProgressService.loadAllTyped(
            uid: 'uid-a',
            reader: (_) async => [
              FirestorePackDocument(id: 'pack-a', data: data),
            ],
            membershipReader: (_) async =>
                const FirestorePackMembership(revision: 3, packIds: {}),
          );
          expect(read.state, CloudReadState.present);
          switch (change) {
            case 'learning':
              data['wordsLearned'] = 8;
            case 'operation tag':
              data['reconciliation_operation_id'] = 'other-operation';
            case 'revision':
              data['sync_revision'] = 1;
            case 'nested metadata':
              ((data['extra'] as Map)['items'] as List).add(3);
            case 'timestamp':
              data['updatedAt'] = Timestamp(100, 1);
          }
          final sessions = CloudWriteSessionController()..acquire('uid-a');
          final session = sessions.transition(CloudWriteMode.reconciling);
          var writes = 0;
          final snapshot = read.value!;
          final result = await FirestoreProgressService.saveManyReconciled(
            uid: 'uid-a',
            progresses: snapshot.progress.values,
            expectedRevisions: snapshot.revisions,
            expectedMembershipRevision: snapshot.membershipRevision,
            expectedMembershipPackIds: snapshot.membershipPackIds,
            expectedLegacyDocuments: snapshot.legacyDocuments,
            operationId: 'operation-1',
            session: session,
            sessions: sessions,
            writer:
                ({
                  required uid,
                  required progresses,
                  required expectedRevisions,
                  required expectedLegacyDocuments,
                  required expectedMembershipRevision,
                  required expectedMembershipPackIds,
                  required operationId,
                  required session,
                  required sessions,
                }) async {
                  // Replace only Firestore I/O. Exercise the transaction's production
                  // precondition against the latest document, still lacking a revision
                  // in the learning/metadata cases.
                  if (!FirestoreProgressService.legacyDocumentsUnchanged(
                    expectedLegacyDocuments,
                    {'pack-a': data},
                  )) {
                    return const FirestorePackCasResult.revisionConflict();
                  }
                  writes++;
                  return const FirestorePackCasResult.committed(
                    {'pack-a': 1},
                    membershipRevision: 4,
                    membershipPackIds: {'pack-a'},
                  );
                },
          );
          expect(result.status, FirestorePackCasStatus.revisionConflict);
          expect(writes, 0);
          if (change == 'learning') {
            expect(data['wordsLearned'], 8);
          }
          if (change == 'nested metadata') {
            expect((data['extra'] as Map)['items'], [1, 2, 3]);
          }
        },
      );
    }

    test(
      'legacy transaction precondition compares timestamp and nested values by value',
      () {
        Map<String, dynamic> sameValue() => {
          'updatedAt': Timestamp(100, 0),
          'extra': {
            'items': [1, 2],
          },
        };
        expect(
          FirestoreProgressService.legacyDocumentsUnchanged(
            {'pack-a': sameValue()},
            {'pack-a': sameValue()},
          ),
          isTrue,
        );
        expect(
          FirestoreProgressService.legacyDocumentsUnchanged(
            {'pack-a': sameValue()},
            {'pack-a': null},
          ),
          isFalse,
        );
      },
    );

    test(
      'retains legacy packs omitted by the first ready-write manifest',
      () async {
        // A was backed up before membership tracking. The existing ready writer
        // seeds an absent manifest from empty, then adds only the pack it saves.
        final firstManifest = const FirestorePackMembership(
          revision: 0,
          packIds: {},
        ).afterWriting({'pack-b'});
        expect(firstManifest.packIds, {'pack-b'});
        final result = await FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) async => [
            FirestorePackDocument(
              id: 'pack-a',
              data:
                  PackProgress.fresh(
                        packId: 'pack-a',
                        level: 'A1',
                        wordsTotal: 10,
                      )
                      .copyWith(wordsLearned: 7, status: PackStatus.inProgress)
                      .toJson(),
            ),
            FirestorePackDocument(
              id: 'pack-b',
              data: {
                ...PackProgress.fresh(
                  packId: 'pack-b',
                  level: 'A1',
                  wordsTotal: 10,
                ).toJson(),
                'sync_revision': 1,
              },
            ),
          ],
          membershipReader: (_) async => firstManifest,
        );

        expect(result.state, CloudReadState.present);
        expect(
          result.value!.progress.keys,
          unorderedEquals(['pack-a', 'pack-b']),
        );
        expect(result.value!.progress['pack-a']!.wordsLearned, 7);
        expect(result.value!.revisions, {'pack-a': null, 'pack-b': 1});
      },
    );

    for (final extraMetadata in [
      {'sync_revision': null},
      {'sync_revision': 1},
      {'reconciliation_operation_id': 'operation-1'},
    ]) {
      test(
        'does not treat tagged unexpected packs as legacy: $extraMetadata',
        () async {
          final result = await FirestoreProgressService.loadAllTyped(
            uid: 'uid-a',
            reader: (_) async => [
              FirestorePackDocument(
                id: 'pack-a',
                data: {
                  ...PackProgress.fresh(
                    packId: 'pack-a',
                    level: 'A1',
                    wordsTotal: 10,
                  ).toJson(),
                  ...extraMetadata,
                },
              ),
            ],
            membershipReader: (_) async =>
                const FirestorePackMembership(revision: 1, packIds: {}),
          );
          expect(result.state, CloudReadState.invalid);
        },
      );
    }

    test('does not collapse a query failure to an empty map', () async {
      final result = await FirestoreProgressService.loadAllTyped(
        uid: 'uid-a',
        reader: (_) async => throw StateError('permission denied'),
      );

      expect(result.state, CloudReadState.unavailable);
    });

    test('returns absent only when the query is explicitly empty', () async {
      final result = await FirestoreProgressService.loadAllTyped(
        uid: 'uid-a',
        reader: (_) async => const [],
      );

      expect(result.state, CloudReadState.absent);
    });

    test(
      'rejects malformed pack progress instead of defaulting fields',
      () async {
        final result = await FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) async => const [
            FirestorePackDocument(
              id: 'pack-a',
              data: {
                'level': 'A1',
                'status': 'not-a-status',
                'wordsLearned': 1,
                'wordsTotal': 10,
                'bossAccuracy': 0.0,
                'attempts': 0,
                'clearedAt': null,
              },
            ),
          ],
        );

        expect(result.state, CloudReadState.invalid);
      },
    );

    test('rejects fractional attempt counters instead of truncating', () async {
      final result = await FirestoreProgressService.loadAllTyped(
        uid: 'uid-a',
        reader: (_) async => const [
          FirestorePackDocument(
            id: 'pack-a',
            data: {
              'level': 'A1',
              'status': 'inProgress',
              'wordsLearned': 1,
              'wordsTotal': 10,
              'bossAccuracy': 0.4,
              'attempts': 1.5,
              'clearedAt': null,
            },
          ),
        ],
      );

      expect(result.state, CloudReadState.invalid);
    });

    test('rejects an oversized query snapshot', () async {
      final result = await FirestoreProgressService.loadAllTyped(
        uid: 'uid-a',
        maxBytes: 16,
        reader: (_) async => const [
          FirestorePackDocument(
            id: 'pack-a',
            data: {
              'level': 'A1',
              'status': 'available',
              'wordsLearned': 0,
              'wordsTotal': 100000,
              'bossAccuracy': 0.0,
              'attempts': 0,
              'clearedAt': null,
            },
          ),
        ],
      );

      expect(result.state, CloudReadState.tooLarge);
    });

    test(
      'rejects a pack query observed across membership generations',
      () async {
        var membershipReads = 0;
        final result = await FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) async => [
            FirestorePackDocument(
              id: 'pack-a',
              data: {
                ...PackProgress.fresh(
                  packId: 'pack-a',
                  level: 'A1',
                  wordsTotal: 10,
                ).toJson(),
                'sync_revision': 2,
              },
            ),
          ],
          membershipReader: (_) async {
            membershipReads += 1;
            return FirestorePackMembership(
              revision: membershipReads == 1 ? 4 : 5,
              packIds: const {'pack-a'},
            );
          },
        );

        expect(result.state, CloudReadState.unavailable);
        expect(membershipReads, 2);
      },
    );

    for (final fixture in [
      (
        name: 'missing manifest document',
        manifestIds: const {'pack-a', 'pack-b'},
        documentIds: const ['pack-a'],
      ),
      (
        name: 'unexpected query document',
        manifestIds: const {'pack-a'},
        documentIds: const ['pack-a', 'pack-b'],
      ),
    ]) {
      test('rejects a stable manifest with ${fixture.name}', () async {
        final result = await FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) async => [
            for (final id in fixture.documentIds)
              FirestorePackDocument(
                id: id,
                data: {
                  ...PackProgress.fresh(
                    packId: id,
                    level: 'A1',
                    wordsTotal: 10,
                  ).toJson(),
                  'sync_revision': 2,
                },
              ),
          ],
          membershipReader: (_) async => FirestorePackMembership(
            revision: 4,
            packIds: fixture.manifestIds,
          ),
        );

        expect(result.state, CloudReadState.invalid);
      });
    }
  });

  group('FirestoreProgressService.loadPackTyped', () {
    test('keeps unavailable distinct from an absent document', () async {
      final unavailable = await FirestoreProgressService.loadPackTyped(
        uid: 'uid-a',
        packId: 'pack-a',
        reader: (_, _) async => throw StateError('offline'),
      );
      final absent = await FirestoreProgressService.loadPackTyped(
        uid: 'uid-a',
        packId: 'pack-a',
        reader: (_, _) async => null,
      );

      expect(unavailable.state, CloudReadState.unavailable);
      expect(absent.state, CloudReadState.absent);
    });
  });

  test(
    'pack CAS forwards revisions and operation through the fenced seam',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var writes = 0;
      final progress = PackProgress.fresh(
        packId: 'pack-a',
        level: 'A1',
        wordsTotal: 10,
      );

      final result = await FirestoreProgressService.saveManyReconciled(
        uid: 'uid-a',
        progresses: [progress],
        expectedRevisions: const {'pack-a': 2},
        expectedMembershipRevision: 7,
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedLegacyDocuments,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes += 1;
              expect(expectedRevisions, {'pack-a': 2});
              expect(expectedMembershipRevision, 7);
              expect(expectedMembershipPackIds, {'pack-a'});
              expect(operationId, 'operation-1');
              return const FirestorePackCasResult.committed(
                {'pack-a': 3},
                membershipRevision: 8,
                membershipPackIds: {'pack-a'},
              );
            },
      );

      expect(result.status, FirestorePackCasStatus.committed);
      expect(result.revisions, {'pack-a': 3});
      expect(writes, 1);
    },
  );

  test(
    'new pack creation changes membership and prevents stale reconciliation',
    () async {
      var membershipRevision = 4;
      var committedWrites = 0;
      final remote = <String, PackProgress>{
        'pack-a': PackProgress.fresh(
          packId: 'pack-a',
          level: 'A1',
          wordsTotal: 10,
        ),
      };
      final initial = await FirestoreProgressService.loadAllTyped(
        uid: 'uid-a',
        reader: (_) async => [
          for (final progress in remote.values)
            FirestorePackDocument(
              id: progress.packId,
              data: {...progress.toJson(), 'sync_revision': 2},
            ),
        ],
        membershipReader: (_) async => FirestorePackMembership(
          revision: membershipRevision,
          packIds: remote.keys.toSet(),
        ),
      );
      expect(initial.state, CloudReadState.present);
      expect(initial.value!.membershipRevision, 4);

      remote['pack-b'] = PackProgress.fresh(
        packId: 'pack-b',
        level: 'A2',
        wordsTotal: 12,
      );
      membershipRevision += 1;

      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final result = await FirestoreProgressService.saveManyReconciled(
        uid: 'uid-a',
        progresses: initial.value!.progress.values,
        expectedRevisions: initial.value!.revisions,
        expectedMembershipRevision: initial.value!.membershipRevision,
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedLegacyDocuments,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              if (expectedMembershipRevision != membershipRevision) {
                return const FirestorePackCasResult.revisionConflict();
              }
              committedWrites += 1;
              return const FirestorePackCasResult.committed(
                {'pack-a': 3},
                membershipRevision: 8,
                membershipPackIds: {'pack-a'},
              );
            },
      );

      expect(result.status, FirestorePackCasStatus.revisionConflict);
      expect(committedWrites, 0);
      expect(remote.keys, containsAll(<String>['pack-a', 'pack-b']));
    },
  );

  test(
    'pack CAS cannot replace a complete manifest with an incomplete set',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      var writes = 0;

      final result = await FirestoreProgressService.saveManyReconciled(
        uid: 'uid-a',
        progresses: [
          PackProgress.fresh(packId: 'pack-a', level: 'A1', wordsTotal: 10),
        ],
        expectedRevisions: const {'pack-a': 2, 'pack-b': 3},
        expectedMembershipRevision: 7,
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required expectedLegacyDocuments,
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes += 1;
              return const FirestorePackCasResult.committed(
                {'pack-a': 3},
                membershipRevision: 8,
                membershipPackIds: {'pack-a'},
              );
            },
      );

      expect(result.status, FirestorePackCasStatus.revisionConflict);
      expect(writes, 0);
    },
  );
}
