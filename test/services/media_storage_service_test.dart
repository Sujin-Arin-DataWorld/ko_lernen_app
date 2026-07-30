import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';

void main() {
  test('media cleanup is blocked before reconciliation completes', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final reconciling = sessions.transition(CloudWriteMode.reconciling);
    var deletes = 0;

    final result = await BookshelfService.collectGarbageWithSession(
      sessions: sessions,
      uid: 'uid-a',
      session: reconciling,
      journal: AccountTransitionJournal.fromSession(
        reconciling,
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.localWritten,
      ),
      prepare: () async {},
      delete: () async => deletes += 1,
    );

    expect(result, CloudWriteResult.blocked);
    expect(deletes, 0);
  });

  test('media cleanup runs after the exact reconciliation completes', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final reconciling = sessions.transition(CloudWriteMode.reconciling);
    var deletes = 0;

    final result = await BookshelfService.collectGarbageWithSession(
      sessions: sessions,
      uid: 'uid-a',
      session: reconciling,
      journal: AccountTransitionJournal.fromSession(
        reconciling,
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.completed,
      ),
      prepare: () async {},
      delete: () async => deletes += 1,
    );

    expect(result, CloudWriteResult.completed);
    expect(deletes, 1);
  });

  test('completed checkpoint cannot authorize a newer session', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final reconciling = sessions.transition(CloudWriteMode.reconciling);
    final completed = AccountTransitionJournal.fromSession(
      reconciling,
      reconciliationOperationId: 'operation-a',
      reconciliationCheckpoint: ReconciliationCheckpoint.completed,
    );
    sessions.transition(CloudWriteMode.cleanupPending);
    var deletes = 0;

    final result = await BookshelfService.collectGarbageWithSession(
      sessions: sessions,
      uid: 'uid-a',
      session: reconciling,
      journal: completed,
      prepare: () async {},
      delete: () async => deletes += 1,
    );

    expect(result, CloudWriteResult.stale);
    expect(deletes, 0);
  });
}
