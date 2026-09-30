import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/pack_sync_queue.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

const _pack = PackProgress(
  packId: 'a1_greetings_1',
  level: 'A1',
  status: PackStatus.inProgress,
  wordsLearned: 3,
  wordsTotal: 10,
  bossAccuracy: 0,
  attempts: 0,
  clearedAtIso: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setPackProgressJson(_pack.packId, _pack.toJson());
  });

  test('blocked session retains the recoverable backup until ready', () async {
    final sessions = CloudWriteSessionController()..acquire('user');
    sessions.transition(CloudWriteMode.quiesced);
    var writes = 0;
    final queue = PackSyncQueue(
      canMirror: () => true,
      sessions: sessions,
      backupUid: () => sessions.current?.uid,
      savePack: (pack) => FirestoreProgressService.savePackWithSession(
        pack,
        sessions: sessions,
        uid: 'user',
        prepare: () async {},
        write: () async {
          writes++;
        },
      ),
    );
    queue.enqueue(_pack);
    await queue.flush();
    expect(writes, 0);
    expect(Storage.packProgressJson(_pack.packId), _pack.toJson());
    expect(queue.pendingCount, 1);
    expect(Storage.pendingPackSyncIds, contains(_pack.packId));
    sessions.transition(CloudWriteMode.ready);
    await queue.flush();
    expect(writes, 1);
    expect(queue.pendingCount, 0);
    expect(Storage.pendingPackSyncIds, isEmpty);
  });

  test('stale result is not a backup acknowledgement', () async {
    final queue = PackSyncQueue(
      canMirror: () => true,
      savePack: (_) async => CloudWriteResult.stale,
    );
    queue.enqueue(_pack);
    await queue.flush();
    expect(queue.pendingCount, 1);
    expect(Storage.pendingPackSyncIds, contains(_pack.packId));
  });

  test('8 second caller bound retains the original write without retry', () {
    fakeAsync((async) {
      final ack = Completer<CloudWriteResult>();
      var writes = 0;
      var returned = false;
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (_) {
          writes++;
          return ack.future;
        },
      );
      queue.enqueue(_pack);
      queue.flush().then((_) {
        returned = true;
      });
      async.elapse(const Duration(seconds: 8));
      expect(returned, isTrue);
      expect(writes, 1);
      expect(queue.pendingCount, 1);
      expect(Storage.pendingPackSyncIds, contains(_pack.packId));
      queue.flush();
      async.elapse(const Duration(seconds: 8));
      expect(writes, 1);
      ack.complete(CloudWriteResult.completed);
      async.flushMicrotasks();
      expect(queue.pendingCount, 0);
      expect(Storage.pendingPackSyncIds, isEmpty);
    });
  });

  test('late acknowledgement cannot remove newer progress', () {
    fakeAsync((async) {
      final first = Completer<CloudWriteResult>();
      final second = Completer<CloudWriteResult>();
      final saved = <PackProgress>[];
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (pack) {
          saved.add(pack);
          return saved.length == 1 ? first.future : second.future;
        },
      );
      queue.enqueue(_pack);
      queue.flush();
      async.elapse(const Duration(seconds: 8));
      final newer = PackProgress.fromJson(_pack.packId, {
        ..._pack.toJson(),
        'wordsLearned': 4,
      });
      queue.enqueue(newer);
      queue.flush();
      async.flushMicrotasks();
      expect(saved, hasLength(1));
      first.complete(CloudWriteResult.completed);
      async.flushMicrotasks();
      expect(saved, [_pack, newer]);
      expect(queue.pendingCount, 1);
      expect(Storage.pendingPackSyncIds, contains(_pack.packId));
      second.complete(CloudWriteResult.completed);
      async.flushMicrotasks();
      expect(saved, [_pack, newer]);
      expect(queue.pendingCount, 0);
      expect(Storage.pendingPackSyncIds, isEmpty);
    });
  });

  for (final trigger in ['idle', 'status change', 'terminal']) {
    test('$trigger during a retained write backs up newer progress', () {
      fakeAsync((async) {
        final first = Completer<CloudWriteResult>();
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (pack) {
            saved.add(pack);
            return saved.length == 1
                ? first.future
                : Future.value(CloudWriteResult.completed);
          },
        );
        queue.enqueue(_pack);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        final newer = PackProgress.fromJson(_pack.packId, {
          ..._pack.toJson(),
          'wordsLearned': 8,
          if (trigger == 'terminal') 'status': PackStatus.cleared.name,
        });
        queue.enqueue(
          newer,
          previousStatus: trigger == 'status change'
              ? PackStatus.available
              : _pack.status,
        );
        async.elapse(const Duration(seconds: 40));
        expect(saved, [_pack]);
        first.complete(CloudWriteResult.completed);
        async.flushMicrotasks();
        expect(saved, [_pack, newer]);
        expect(queue.pendingCount, 0);
        expect(Storage.pendingPackSyncIds, isEmpty);
      });
    });
  }

  test('joined triggers coalesce and a blocked retry does not spin', () {
    fakeAsync((async) {
      final first = Completer<CloudWriteResult>();
      var calls = 0;
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (_) => ++calls == 1
            ? first.future
            : Future.value(CloudWriteResult.blocked),
      );
      queue.enqueue(_pack);
      queue.flush();
      async.elapse(const Duration(seconds: 8));
      queue.enqueue(
        PackProgress.fromJson(_pack.packId, {
          ..._pack.toJson(),
          'wordsLearned': 8,
        }),
      );
      queue.flush();
      queue.flushAll();
      first.complete(CloudWriteResult.blocked);
      async.flushMicrotasks();
      expect(calls, 2);
      async.elapse(const Duration(minutes: 2));
      expect(calls, 2);
      expect(queue.pendingCount, 1);
      expect(Storage.pendingPackSyncIds, contains(_pack.packId));
    });
  });

  for (final failsWithError in [false, true]) {
    test('new pack passes a retained failure (error: $failsWithError)', () {
      fakeAsync((async) {
        final first = Completer<CloudWriteResult>();
        final saved = <PackProgress>[];
        final newer = PackProgress.fromJson('a1_new_pack', _pack.toJson());
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (pack) {
            saved.add(pack);
            if (saved.length == 1) {
              return first.future;
            }
            if (pack.packId == _pack.packId) {
              return Completer<CloudWriteResult>().future;
            }
            return Future.value(CloudWriteResult.completed);
          },
        );
        queue.enqueue(_pack);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        queue.enqueue(newer);
        async.elapse(const Duration(seconds: 40));
        expect(saved, [_pack]);
        if (failsWithError) {
          first.completeError(StateError('server rejected'));
        } else {
          first.complete(CloudWriteResult.blocked);
        }
        async.flushMicrotasks();
        expect(saved, [_pack, newer]);
        expect(queue.pendingCount, 1);
        expect(Storage.pendingPackSyncIds, [_pack.packId]);
        async.elapse(const Duration(minutes: 2));
        expect(saved, [_pack, newer]);
      });
    });
  }

  test('settled late failure retries only at the next explicit trigger', () {
    fakeAsync((async) {
      final first = Completer<CloudWriteResult>();
      var calls = 0;
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (_) => ++calls == 1
            ? first.future
            : Future.value(CloudWriteResult.completed),
      );
      queue.enqueue(_pack);
      queue.flush();
      async.elapse(const Duration(seconds: 8));
      first.completeError(StateError('server rejected'));
      async.flushMicrotasks();
      expect(calls, 1);
      expect(queue.pendingCount, 1);
      expect(Storage.pendingPackSyncIds, contains(_pack.packId));
      queue.flush();
      async.flushMicrotasks();
      expect(calls, 2);
      expect(Storage.pendingPackSyncIds, isEmpty);
    });
  });

  test('late acknowledgement after local reset does not restore markers', () {
    fakeAsync((async) {
      final ack = Completer<CloudWriteResult>();
      var calls = 0;
      final queue = PackSyncQueue(
        canMirror: () => true,
        savePack: (_) {
          calls++;
          return ack.future;
        },
      );
      queue.enqueue(_pack);
      queue.flush();
      async.elapse(const Duration(seconds: 8));
      var reset = false;
      Storage.resetAll().then((_) {
        reset = true;
      });
      async.flushMicrotasks();
      expect(reset, isTrue);
      expect(Storage.pendingPackSyncIds, isEmpty);
      ack.complete(CloudWriteResult.completed);
      async.flushMicrotasks();
      queue.flush();
      async.flushMicrotasks();
      expect(calls, 1);
      expect(queue.pendingCount, 0);
      expect(Storage.pendingPackSyncIds, isEmpty);
      expect(Storage.packProgressJson(_pack.packId), isNull);
    });
  });

  test(
    'account change discards old memory without clearing durable recovery',
    () {
      fakeAsync((async) {
        var uid = 'a';
        final ack = Completer<CloudWriteResult>();
        var calls = 0;
        final queue = PackSyncQueue(
          canMirror: () => true,
          backupUid: () => uid,
          savePack: (_) {
            calls++;
            return ack.future;
          },
        );
        queue.enqueue(_pack);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        uid = 'b';
        ack.complete(CloudWriteResult.completed);
        async.flushMicrotasks();
        queue.flush();
        async.flushMicrotasks();
        expect(calls, 1);
        expect(queue.pendingCount, 0);
        expect(Storage.pendingPackSyncIds, contains(_pack.packId));
      });
    },
  );

  test(
    'stale local entry cannot overwrite a new lifetime with the same id',
    () {
      fakeAsync((async) {
        final ack = Completer<CloudWriteResult>();
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (pack) {
            saved.add(pack);
            return saved.length == 1
                ? ack.future
                : Future.value(CloudWriteResult.completed);
          },
        );
        queue.enqueue(_pack);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        LocalDataLifetime.invalidate();
        final newer = PackProgress.fromJson(_pack.packId, {
          ..._pack.toJson(),
          'wordsLearned': 5,
        });
        queue.enqueue(newer);
        ack.complete(CloudWriteResult.completed);
        async.flushMicrotasks();
        expect(queue.pendingCount, 1);
        queue.flush();
        async.flushMicrotasks();
        expect(saved, [_pack, newer]);
        expect(Storage.pendingPackSyncIds, isEmpty);
      });
    },
  );

  test(
    'A to B to A cannot revive a pre-reconciliation memory snapshot',
    () async {
      final sessions = CloudWriteSessionController()..acquire('a');
      final saved = <PackProgress>[];
      final queue = PackSyncQueue(
        canMirror: () => true,
        sessions: sessions,
        backupUid: () => sessions.current?.uid,
        savePack: (pack) async {
          saved.add(pack);
          return CloudWriteResult.completed;
        },
      );
      queue.enqueue(_pack);
      sessions.clear();
      sessions.acquire('b');
      sessions.acquire('a');
      final newer = PackProgress.fromJson(_pack.packId, {
        ..._pack.toJson(),
        'wordsLearned': 7,
      });
      await Storage.setPackProgressJson(_pack.packId, newer.toJson());
      await queue.flushPendingFromStorage();
      expect(saved.map((pack) => pack.toJson()), [newer.toJson()]);
      expect(queue.pendingCount, 0);
      expect(Storage.pendingPackSyncIds, isEmpty);
    },
  );

  test('an old owner pending forever does not block new owner or reset', () {
    for (final resetLocal in [false, true]) {
      fakeAsync((async) {
        final sessions = CloudWriteSessionController()..acquire('a');
        final first = Completer<CloudWriteResult>();
        final saved = <PackProgress>[];
        final queue = PackSyncQueue(
          canMirror: () => true,
          sessions: sessions,
          backupUid: () => sessions.current?.uid,
          savePack: (pack) {
            saved.add(pack);
            return saved.length == 1
                ? first.future
                : Future.value(CloudWriteResult.completed);
          },
        );
        queue.enqueue(_pack);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        if (resetLocal) {
          LocalDataLifetime.invalidate();
        } else {
          sessions.acquire('b');
        }
        final newer = PackProgress.fromJson(_pack.packId, {
          ..._pack.toJson(),
          'wordsLearned': 8,
        });
        queue.enqueue(newer);
        queue.flush();
        async.flushMicrotasks();
        expect(saved, [_pack, newer]);
        expect(queue.pendingCount, 0);
        expect(Storage.pendingPackSyncIds, isEmpty);
        first.complete(CloudWriteResult.completed);
        async.flushMicrotasks();
        expect(Storage.pendingPackSyncIds, isEmpty);
      });
    }
  });

  test(
    'packs keep serial membership transactions while caller wait is bounded',
    () {
      fakeAsync((async) {
        final first = Completer<CloudWriteResult>();
        final saved = <PackProgress>[];
        final second = PackProgress.fromJson('a1_other', _pack.toJson());
        final queue = PackSyncQueue(
          canMirror: () => true,
          savePack: (pack) {
            saved.add(pack);
            return saved.length == 1
                ? first.future
                : Future.value(CloudWriteResult.completed);
          },
        );
        queue.enqueue(_pack);
        queue.enqueue(second);
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        queue.flush();
        async.elapse(const Duration(seconds: 8));
        expect(saved, [_pack]);
        expect(
          Storage.pendingPackSyncIds,
          containsAll([_pack.packId, second.packId]),
        );
        first.complete(CloudWriteResult.completed);
        async.flushMicrotasks();
        expect(saved, [_pack, second]);
        expect(Storage.pendingPackSyncIds, isEmpty);
      });
    },
  );

  test('explicit recovery removes only ids with no local progress', () async {
    await Storage.setPendingPackSyncIds([_pack.packId, 'deleted-pack']);
    final queue = PackSyncQueue(
      canMirror: () => true,
      savePack: (_) async => CloudWriteResult.blocked,
    );
    await queue.flushPendingFromStorage();
    expect(Storage.pendingPackSyncIds, [_pack.packId]);
    expect(Storage.packProgressJson(_pack.packId), _pack.toJson());
  });

  test(
    'permission transitions retain identity but clear and reacquire retire it',
    () {
      final sessions = CloudWriteSessionController()..acquire('a');
      final original = sessions.identityEpoch;
      sessions.transition(CloudWriteMode.quiesced);
      sessions.transition(CloudWriteMode.ready);
      expect(sessions.identityEpoch, original);
      sessions.clear();
      expect(sessions.identityEpoch, greaterThan(original));
      final cleared = sessions.identityEpoch;
      sessions.acquire('a');
      expect(sessions.identityEpoch, greaterThan(cleared));
    },
  );
}
