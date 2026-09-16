import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_restore_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';

const _readDeadline = Duration(seconds: 8);

const _remoteBackup = CloudSyncDocument.present({
  'sync_revision': 4,
  'progress': {'xp': 12},
});

Future<CloudRestoreResult> _restore(
  CloudWriteSessionController sessions,
  CloudSyncDocumentReader reader,
  List<String> events,
) => CloudSync.restoreWithSessionResult(
  sessions: sessions,
  uid: 'uid-a',
  readAccount: () =>
      CloudSyncService.readAccountDocument(uid: 'uid-a', reader: reader),
  applyAccount: (data, beforeWrite) async {
    beforeWrite();
    events.add('apply');
  },
  restoreBookshelf: (_) async {
    events.add('bookshelf');
    return const CloudRestoreComponentResult(
      status: CloudWriteResult.completed,
      hasRemoteData: false,
    );
  },
  restorePacks: (_) async {
    events.add('packs');
    return const CloudRestoreComponentResult(
      status: CloudWriteResult.completed,
      hasRemoteData: false,
    );
  },
);

void main() {
  test(
    'hung account read becomes unavailable at eight seconds, without retry',
    () {
      fakeAsync((clock) {
        final pending = Completer<CloudSyncDocument>();
        var reads = 0;
        CloudReadResult<Map<String, dynamic>>? result;

        unawaited(
          CloudSyncService.readAccountDocument(
            uid: 'uid-a',
            reader: (_) {
              reads += 1;
              return pending.future;
            },
          ).then((value) => result = value),
        );

        clock.elapse(_readDeadline - const Duration(milliseconds: 1));
        expect(result, isNull);
        clock.elapse(const Duration(milliseconds: 1));
        expect(result?.state, CloudReadState.unavailable);
        expect(reads, 1);

        pending.complete(_remoteBackup);
        clock.flushMicrotasks();
        clock.elapse(_readDeadline);
        expect(result?.state, CloudReadState.unavailable);
        expect(reads, 1);
      });
    },
  );

  test(
    'account read just before the deadline retains its data and revision',
    () {
      fakeAsync((clock) {
        final pending = Completer<CloudSyncDocument>();
        CloudReadResult<Map<String, dynamic>>? result;
        unawaited(
          CloudSyncService.readAccountDocument(
            uid: 'uid-a',
            reader: (_) => pending.future,
          ).then((value) => result = value),
        );

        clock.elapse(_readDeadline - const Duration(milliseconds: 1));
        pending.complete(_remoteBackup);
        clock.flushMicrotasks();
        clock.elapse(_readDeadline);
        expect(result?.state, CloudReadState.present);
        expect(result?.revision, 4);
        expect(result?.value?['progress'], {'xp': 12});
      });
    },
  );

  test('a late read error does not escape after an unavailable result', () {
    fakeAsync((clock) {
      final pending = Completer<CloudSyncDocument>();
      CloudReadResult<Map<String, dynamic>>? result;
      unawaited(
        CloudSyncService.readAccountDocument(
          uid: 'uid-a',
          reader: (_) => pending.future,
        ).then((value) => result = value),
      );

      clock.elapse(_readDeadline);
      expect(result?.state, CloudReadState.unavailable);
      pending.completeError(StateError('late transport failure'));
      clock.flushMicrotasks();
      expect(result?.state, CloudReadState.unavailable);
    });
  });

  test(
    'timed-out restore applies nothing and a new explicit restore can recover',
    () {
      fakeAsync((clock) {
        final sessions = CloudWriteSessionController()..acquire('uid-a');
        final pending = Completer<CloudSyncDocument>();
        final events = <String>[];
        var reads = 0;
        CloudRestoreResult? result;

        unawaited(
          _restore(sessions, (_) {
            reads += 1;
            return pending.future;
          }, events).then((value) => result = value),
        );
        clock.elapse(_readDeadline);
        expect(result, CloudRestoreResult.blocked);
        expect(events, isEmpty);

        pending.complete(_remoteBackup);
        clock.flushMicrotasks();
        expect(result, CloudRestoreResult.blocked);
        expect(events, isEmpty);
        expect(reads, 1);

        unawaited(
          _restore(sessions, (_) async {
            reads += 1;
            return _remoteBackup;
          }, events).then((value) => result = value),
        );
        clock.flushMicrotasks();
        expect(result, CloudRestoreResult.completed);
        expect(events, ['apply', 'bookshelf', 'packs']);
        expect(reads, 2);
      });
    },
  );

  for (final invalidation in ['account switch', 'quiesce', 'local reset']) {
    test(
      'timeout after $invalidation is stale and never applies a late backup',
      () {
        fakeAsync((clock) {
          final sessions = CloudWriteSessionController()..acquire('uid-a');
          final pending = Completer<CloudSyncDocument>();
          final events = <String>[];
          CloudRestoreResult? result;
          unawaited(
            _restore(
              sessions,
              (_) => pending.future,
              events,
            ).then((value) => result = value),
          );
          clock.elapse(const Duration(seconds: 1));
          switch (invalidation) {
            case 'account switch':
              sessions.acquire('uid-b');
            case 'quiesce':
              sessions.transition(CloudWriteMode.quiesced);
            case 'local reset':
              LocalDataLifetime.invalidate();
          }
          clock.elapse(_readDeadline);
          expect(result, CloudRestoreResult.stale);
          pending.complete(_remoteBackup);
          clock.flushMicrotasks();
          expect(result, CloudRestoreResult.stale);
          expect(events, isEmpty);
        });
      },
    );
  }
}
