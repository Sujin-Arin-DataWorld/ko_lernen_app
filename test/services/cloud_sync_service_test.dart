import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';

void main() {
  group('CloudSyncService.readAccountDocument', () {
    test('returns absent only for an explicit missing document', () async {
      final result = await CloudSyncService.readAccountDocument(
        uid: 'uid-a',
        reader: (_) async => const CloudSyncDocument.missing(),
      );

      expect(result.state, CloudReadState.absent);
    });

    test('maps transport failure to unavailable', () async {
      final result = await CloudSyncService.readAccountDocument(
        uid: 'uid-a',
        reader: (_) async => throw StateError('offline'),
      );

      expect(result.state, CloudReadState.unavailable);
    });

    test('rejects malformed document revision', () async {
      final result = await CloudSyncService.readAccountDocument(
        uid: 'uid-a',
        reader: (_) async =>
            const CloudSyncDocument.present({'sync_revision': -1}),
      );

      expect(result.state, CloudReadState.invalid);
    });

    test('rejects a document beyond the byte limit', () async {
      final result = await CloudSyncService.readAccountDocument(
        uid: 'uid-a',
        maxBytes: 8,
        reader: (_) async =>
            const CloudSyncDocument.present({'payload': 'too large'}),
      );

      expect(result.state, CloudReadState.tooLarge);
    });

    test('returns a valid document with its CAS revision', () async {
      final result = await CloudSyncService.readAccountDocument(
        uid: 'uid-a',
        reader: (_) async => const CloudSyncDocument.present({
          'sync_revision': 4,
          'progress': {'xp': 12},
        }),
      );

      expect(result.state, CloudReadState.present);
      expect(result.revision, 4);
      expect(result.value?['progress'], {'xp': 12});
    });

    test(
      'accepts Firestore timestamps while enforcing the byte limit',
      () async {
        final result = await CloudSyncService.readAccountDocument(
          uid: 'uid-a',
          reader: (_) async => CloudSyncDocument.present({
            'sync_revision': 4,
            'updated_at': Timestamp.fromMillisecondsSinceEpoch(1000),
          }),
        );

        expect(result.state, CloudReadState.present);
      },
    );
  });

  test('reconciliation CAS forwards one current fenced operation', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final session = sessions.transition(CloudWriteMode.reconciling);
    var writes = 0;

    final result = await CloudSyncService.writeReconciledAccountDocument(
      uid: 'uid-a',
      data: const {
        'progress': {'xp': 2},
      },
      expectedRevision: 4,
      operationId: 'operation-1',
      session: session,
      sessions: sessions,
      writer:
          ({
            required uid,
            required data,
            required expectedRevision,
            required operationId,
            required session,
            required sessions,
          }) async {
            writes += 1;
            expect(uid, 'uid-a');
            expect(expectedRevision, 4);
            expect(operationId, 'operation-1');
            return const CloudSyncCasResult.committed(5);
          },
    );

    expect(result.status, CloudSyncCasStatus.committed);
    expect(result.revision, 5);
    expect(writes, 1);
  });

  test(
    'reconciliation CAS rejects a non-reconciling session before writer',
    () async {
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('uid-a');
      var writes = 0;

      final result = await CloudSyncService.writeReconciledAccountDocument(
        uid: 'uid-a',
        data: const {},
        expectedRevision: null,
        operationId: 'operation-1',
        session: session,
        sessions: sessions,
        writer:
            ({
              required uid,
              required data,
              required expectedRevision,
              required operationId,
              required session,
              required sessions,
            }) async {
              writes += 1;
              return const CloudSyncCasResult.committed(1);
            },
      );

      expect(result.status, CloudSyncCasStatus.revisionConflict);
      expect(writes, 0);
    },
  );
}
