import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/media_cleanup_gate.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test(
    'bookshelf production journal reader blocks pre-rehydration GC',
    () async {
      final pending = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'uid-a',
          epoch: 3,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.localWritten,
      );
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAccountTransitionJournalReader.key: jsonEncode(
          pending.toJson(),
        ),
      });
      var deletes = 0;

      final result = await BookshelfService.collectGarbageWithSession(
        sessions: CloudWriteSessionController(),
        provenLocalOnly: true,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.blocked);
      expect(deletes, 0);
    },
  );

  test(
    'custom-pack production journal reader blocks pre-rehydration GC',
    () async {
      final pending = AccountTransitionJournal.fromSession(
        const CloudWriteSession(
          uid: 'uid-a',
          epoch: 3,
          mode: CloudWriteMode.reconciling,
        ),
        reconciliationOperationId: 'operation-a',
        reconciliationCheckpoint: ReconciliationCheckpoint.remoteWritten,
      );
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAccountTransitionJournalReader.key: jsonEncode(
          pending.toJson(),
        ),
      });
      var deletes = 0;

      final result = await CustomPackService.collectGarbageWithSession(
        sessions: CloudWriteSessionController(),
        provenLocalOnly: true,
        prepare: () async {},
        delete: () async => deletes += 1,
      );

      expect(result, CloudWriteResult.blocked);
      expect(deletes, 0);
    },
  );
}
