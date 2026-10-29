import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';

void main() {
  test(
    'legacy pack recovery preserves observed manifest through merge and CAS',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);
      final adapter = FirebaseAccountReconciliationAdapter(
        uid: 'uid-a',
        session: session,
        sessions: sessions,
        remote: FirebaseAccountReconciliationRemote(
          rootReader: (_) async => const CloudSyncDocument.present({
            'sync_revision': 2,
            'progress': {'xp': 37},
          }),
          packReader: (_) async => [
            FirestorePackDocument(
              id: 'a2_daily_1',
              data:
                  PackProgress.fresh(
                        packId: 'a2_daily_1',
                        level: 'A2',
                        wordsTotal: 8,
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
          membershipReader: (_) async =>
              const FirestorePackMembership(revision: 3, packIds: {'pack-b'}),
          rootWriter:
              ({
                required uid,
                required data,
                required expectedRevision,
                required operationId,
                required session,
                required sessions,
              }) async {
                expect(expectedRevision, 2);
                expect(data['progress'], {'xp': 37});
                return const CloudSyncCasResult.committed(3);
              },
          packWriter:
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
                // The transaction must compare the manifest actually read, while also
                // checking the original revision of every retained legacy document.
                expect(expectedMembershipRevision, 3);
                expect(expectedMembershipPackIds, {'pack-b'});
                expect(expectedRevisions, {'a2_daily_1': null, 'pack-b': 1});
                expect(expectedLegacyDocuments.keys, ['a2_daily_1']);
                expect(expectedLegacyDocuments['a2_daily_1']!['wordsTotal'], 8);
                expect(
                  expectedLegacyDocuments['a2_daily_1']!['wordsLearned'],
                  7,
                );
                expect(
                  progresses.map((p) => p.packId),
                  unorderedEquals(['a2_daily_1', 'pack-b']),
                );
                expect(
                  progresses
                      .singleWhere((p) => p.packId == 'a2_daily_1')
                      .wordsLearned,
                  7,
                );
                expect(
                  progresses
                      .singleWhere((p) => p.packId == 'a2_daily_1')
                      .wordsTotal,
                  12,
                );
                return const FirestorePackCasResult.committed(
                  {'a2_daily_1': 1, 'pack-b': 2},
                  membershipRevision: 4,
                  membershipPackIds: {'a2_daily_1', 'pack-b'},
                );
              },
          compositeReader: (_) async =>
              throw StateError('injected validator used'),
        ),
      );
      final remote = await adapter.readRemote();
      expect(remote.state, CloudReadState.present);
      final merged = AccountReconciliationMerger.merge(
        local: AccountReconciliationSnapshot(
          fields: {
            'progress': {'xp': 0},
          },
          srsCards: {},
          customPacks: {},
          packProgress: {},
        ),
        remote: remote.value!,
        catalog: const {
          'a2_daily_1': PackCatalogEntry(
            packId: 'a2_daily_1',
            level: 'A2',
            wordsTotal: 12,
          ),
          'pack-b': PackCatalogEntry(
            packId: 'pack-b',
            level: 'A1',
            wordsTotal: 10,
          ),
        },
      );
      expect(merged.conflicts, isEmpty);
      final written = await adapter.writeRemote(
        merged.merged!,
        expectedRevision: remote.revision,
        operationId: 'operation-1',
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
              expect(expectedMembershipRevision, 4);
              expect(expectedMembershipPackIds, {'a2_daily_1', 'pack-b'});
              return true;
            },
      );
      expect(written.status, ReconciliationWriteStatus.committed);
      final nextReadyWrite = const FirestorePackMembership(
        revision: 4,
        packIds: {'a2_daily_1', 'pack-b'},
      ).afterWriting({'pack-c'});
      expect(nextReadyWrite.packIds, {'a2_daily_1', 'pack-b', 'pack-c'});
    },
  );
}
