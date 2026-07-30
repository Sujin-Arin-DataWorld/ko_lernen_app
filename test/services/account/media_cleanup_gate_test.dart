import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/media_cleanup_gate.dart';

void main() {
  group('MediaCleanupGate', () {
    test('restart before journal rehydration cannot delete media', () async {
      final sessions = CloudWriteSessionController();
      final unresolved = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'uid-a',
          epoch: 2,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.localWritten,
      );
      var deletes = 0;

      final result = await MediaCleanupGate(sessions).run(
        uid: 'uid-a',
        readJournal: () async => unresolved,
        provenLocalOnly: true,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.blocked);
      expect(deletes, 0);
    });

    test('proven local-only state with no journal can delete media', () async {
      final sessions = CloudWriteSessionController();
      var deletes = 0;

      final result = await MediaCleanupGate(sessions).run(
        readJournal: () async => null,
        provenLocalOnly: true,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.completed);
      expect(deletes, 1);
    });

    test('unresolved checkpoint blocks current reconciling session', () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final reconciling = sessions.transition(CloudWriteMode.reconciling);
      final unresolved = AccountTransitionJournal.fromSession(
        reconciling,
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.localWritten,
      );
      var deletes = 0;

      final result = await MediaCleanupGate(sessions).run(
        uid: 'uid-a',
        session: reconciling,
        readJournal: () async => unresolved,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.blocked);
      expect(deletes, 0);
    });

    test('exact completed checkpoint authorizes reconciling session', () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final reconciling = sessions.transition(CloudWriteMode.reconciling);
      final completed = AccountTransitionJournal.fromSession(
        reconciling,
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.completed,
      );
      var deletes = 0;

      final result = await MediaCleanupGate(sessions).run(
        uid: 'uid-a',
        session: reconciling,
        readJournal: () async => completed,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.completed);
      expect(deletes, 1);
    });

    test('completed checkpoint for a different session is blocked', () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final reconciling = sessions.transition(CloudWriteMode.reconciling);
      final mismatched = AccountTransitionJournal.fromSession(
        CloudWriteSession(
          uid: reconciling.uid,
          epoch: reconciling.epoch + 1,
          mode: reconciling.mode,
        ),
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.completed,
      );
      var deletes = 0;

      final result = await MediaCleanupGate(sessions).run(
        uid: 'uid-a',
        session: reconciling,
        readJournal: () async => mismatched,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.blocked);
      expect(deletes, 0);
    });

    test(
      'journal appearing during preparation blocks local-only delete',
      () async {
        final sessions = CloudWriteSessionController();
        AccountTransitionJournal? journal;
        var deletes = 0;

        final result = await MediaCleanupGate(sessions).run(
          readJournal: () async => journal,
          provenLocalOnly: true,
          prepare: () async {
            journal = AccountTransitionJournal.fromSession(
              const CloudWriteSession(
                uid: 'uid-a',
                epoch: 1,
                mode: CloudWriteMode.reconciling,
              ),
              reconciliationOperationId: 'operation-a',
              reconciliationCheckpoint: ReconciliationCheckpoint.remoteRead,
            );
          },
          delete: () async => deletes += 1,
        );

        expect(result, CloudWriteResult.blocked);
        expect(deletes, 0);
      },
    );
  });
}
