import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/net/sori_net.dart';

const _confirmation = CloudSyncCompositeDocuments(
  root: CloudSyncDocument.present({
    'sync_revision': 1,
    'reconciliation_operation_id': 'operation-1',
    'reconciliation_payload_hash':
        '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a',
  }),
  packMembership: CloudSyncDocument.present({
    'revision': 1,
    'reconciliation_operation_id': 'operation-1',
    'pack_ids': <String>[],
  }),
);

void main() {
  group('composite confirmation deadline', () {
    for (final sessionChange in ['none', 'account switch', 'quiesce']) {
      test('read before deadline preserves the $sessionChange fence', () {
        fakeAsync((clock) {
          final sessions = CloudWriteSessionController()..acquire('uid-a');
          final session = sessions.transition(CloudWriteMode.reconciling);
          final pending = Completer<CloudSyncCompositeDocuments>();
          bool? result;
          unawaited(
            CloudSyncService.validateReconciledAccountComposite(
              uid: 'uid-a',
              data: const {},
              expectedRevision: 1,
              expectedMembershipRevision: 1,
              expectedMembershipPackIds: const {},
              operationId: 'operation-1',
              session: session,
              sessions: sessions,
              reader: (_) => pending.future,
            ).then((value) {
              result = value;
            }),
          );
          clock.elapse(const Duration(milliseconds: 7999));
          if (sessionChange == 'account switch') {
            sessions.acquire('uid-b');
          } else if (sessionChange == 'quiesce') {
            sessions.transition(CloudWriteMode.quiesced);
          }
          pending.complete(_confirmation);
          clock.flushMicrotasks();
          expect(result, sessionChange == 'none');
          clock.elapse(const Duration(seconds: 8));
          expect(result, sessionChange == 'none');
        });
      });
    }
    for (final lateError in [false, true]) {
      test(
        'times out once and ignores late ${lateError ? 'error' : 'success'}',
        () {
          fakeAsync((clock) {
            final sessions = CloudWriteSessionController()..acquire('uid-a');
            final session = sessions.transition(CloudWriteMode.reconciling);
            final pending = Completer<CloudSyncCompositeDocuments>();
            var reads = 0;
            Object? failure;
            bool? result;
            unawaited(
              CloudSyncService.validateReconciledAccountComposite(
                uid: 'uid-a',
                data: const {},
                expectedRevision: 1,
                expectedMembershipRevision: 1,
                expectedMembershipPackIds: const {},
                operationId: 'operation-1',
                session: session,
                sessions: sessions,
                reader: (_) {
                  reads += 1;
                  return pending.future;
                },
              ).then(
                (value) {
                  result = value;
                },
                onError: (Object error) {
                  failure = error;
                },
              ),
            );
            clock.elapse(const Duration(milliseconds: 7999));
            expect(failure, isNull);
            clock.elapse(const Duration(milliseconds: 1));
            expect(failure, isA<SoriNetTimeout>());
            expect(result, isNull);
            expect(reads, 1);
            if (lateError) {
              pending.completeError(StateError('late transport error'));
            } else {
              pending.complete(_confirmation);
            }
            clock.flushMicrotasks();
            clock.elapse(const Duration(seconds: 8));
            expect(failure, isA<SoriNetTimeout>());
            expect(result, isNull);
            expect(reads, 1);
          });
        },
      );
    }
  });

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

  test(
    'composite validation requires exact root revision operation and payload',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      const data = {'srs_json': '{}', 'custom_packs_json': '{}'};
      const payloadHash =
          'fba91bf00be691c5c9f38c58bead1858754527bc90d01adce07de8d410b6e4ab';
      const membership = CloudSyncDocument.present({
        'revision': 1,
        'pack_ids': <String>[],
        'reconciliation_operation_id': 'operation-1',
      });

      Future<bool> validate(Map<String, dynamic> remote) =>
          CloudSyncService.validateReconciledAccountComposite(
            uid: 'uid-a',
            data: data,
            expectedRevision: 5,
            expectedMembershipRevision: 1,
            expectedMembershipPackIds: const {},
            operationId: 'operation-1',
            session: session,
            sessions: sessions,
            reader: (_) async => CloudSyncCompositeDocuments(
              root: CloudSyncDocument.present(remote),
              packMembership: membership,
            ),
          );

      expect(
        await validate({
          ...data,
          'sync_revision': 5,
          'reconciliation_operation_id': 'operation-1',
          'reconciliation_payload_hash': payloadHash,
        }),
        isTrue,
      );
      expect(
        await validate({
          ...data,
          'sync_revision': 6,
          'reconciliation_operation_id': 'operation-1',
          'reconciliation_payload_hash': payloadHash,
        }),
        isFalse,
      );
      expect(
        await validate({
          ...data,
          'sync_revision': 5,
          'reconciliation_operation_id': 'operation-2',
          'reconciliation_payload_hash': payloadHash,
        }),
        isFalse,
      );
      expect(
        await validate({
          ...data,
          'sync_revision': 5,
          'reconciliation_operation_id': 'operation-1',
          'reconciliation_payload_hash': 'wrong',
        }),
        isFalse,
      );
    },
  );

  test(
    'composite validation requires exact root and pack membership snapshot',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      const data = {'srs_json': '{}', 'custom_packs_json': '{}'};
      const root = CloudSyncDocument.present({
        ...data,
        'sync_revision': 5,
        'reconciliation_operation_id': 'operation-1',
        'reconciliation_payload_hash':
            'fba91bf00be691c5c9f38c58bead1858754527bc90d01adce07de8d410b6e4ab',
      });

      Future<bool> validate(Map<String, dynamic> membership) =>
          CloudSyncService.validateReconciledAccountComposite(
            uid: 'uid-a',
            data: data,
            expectedRevision: 5,
            expectedMembershipRevision: 7,
            expectedMembershipPackIds: const {'pack-a'},
            operationId: 'operation-1',
            session: session,
            sessions: sessions,
            reader: (_) async => CloudSyncCompositeDocuments(
              root: root,
              packMembership: CloudSyncDocument.present(membership),
            ),
          );

      expect(
        await validate(const {
          'revision': 7,
          'pack_ids': ['pack-a'],
          'reconciliation_operation_id': 'operation-1',
        }),
        isTrue,
      );
      expect(
        await validate(const {
          'revision': 8,
          'pack_ids': ['pack-a'],
          'reconciliation_operation_id': 'operation-1',
        }),
        isFalse,
      );
      expect(
        await validate(const {
          'revision': 7,
          'pack_ids': ['pack-a', 'pack-b'],
          'reconciliation_operation_id': 'operation-1',
        }),
        isFalse,
      );
    },
  );
}
