import 'package:flutter_test/flutter_test.dart';
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

  group('FirestoreProgressService.loadAllTyped', () {
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
              return const FirestorePackCasResult.committed({'pack-a': 3});
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
              return const FirestorePackCasResult.committed({'pack-a': 3});
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
              required expectedMembershipRevision,
              required expectedMembershipPackIds,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes += 1;
              return const FirestorePackCasResult.committed({'pack-a': 3});
            },
      );

      expect(result.status, FirestorePackCasStatus.revisionConflict);
      expect(writes, 0);
    },
  );
}
