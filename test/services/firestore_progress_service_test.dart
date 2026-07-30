import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';

void main() {
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
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required progresses,
              required expectedRevisions,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes += 1;
              expect(expectedRevisions, {'pack-a': 2});
              expect(operationId, 'operation-1');
              return const FirestorePackCasResult.committed({'pack-a': 3});
            },
      );

      expect(result.status, FirestorePackCasStatus.committed);
      expect(result.revisions, {'pack-a': 3});
      expect(writes, 1);
    },
  );
}
