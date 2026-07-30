import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_sync_outbox.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'rapid saves coalesce and retry a CAS loss with the latest snapshot',
    () async {
      final store = _MemoryOutboxStore();
      final firstAttemptStarted = Completer<void>();
      final releaseFirstAttempt = Completer<void>();
      var latest = 'first';
      final attempted = <String>[];
      var attempts = 0;
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (_) async {
          final captured = latest;
          attempted.add(captured);
          attempts += 1;
          if (attempts == 1) {
            firstAttemptStarted.complete();
            await releaseFirstAttempt.future;
            return CloudWriteResult.blocked;
          }
          return CloudWriteResult.completed;
        },
      );

      await queue.enqueue('uid-a');
      await firstAttemptStarted.future;
      latest = 'second';
      await queue.enqueue('uid-a');
      releaseFirstAttempt.complete();

      expect(await queue.drain(), CloudWriteResult.completed);
      expect(attempted, ['first', 'second']);
      expect(await store.read(), isNull);
    },
  );

  test(
    'offline enqueue survives a queue reconstruction and resumes later',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final offline = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (_) async => throw StateError('offline'),
      );

      await offline.enqueue('uid-a');
      expect(await offline.drain(), CloudWriteResult.blocked);
      expect((await store.read())?.uid, 'uid-a');

      var resumed = 0;
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (_) async {
          resumed += 1;
          return CloudWriteResult.completed;
        },
      );

      expect(await restarted.drain(), CloudWriteResult.completed);
      expect(resumed, 1);
      expect(await store.read(), isNull);
    },
  );

  test('outbox read failures are retained as blocked work', () async {
    final store = _MemoryOutboxStore();
    final queue = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'token-1',
      attempt: (_) async => CloudWriteResult.completed,
    );

    await queue.enqueue('uid-a');
    store.failReads = true;

    expect(await queue.drain(), CloudWriteResult.blocked);
    store.failReads = false;
    expect((await store.read())?.token, 'token-1');
  });

  test(
    'enqueue racing compare-and-clear cannot lose the newer marker',
    () async {
      final store = _RacyOutboxStore();
      var tokens = 0;
      final attempted = <String>[];
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending.token);
          return CloudWriteResult.completed;
        },
      );

      await queue.enqueue('uid-a');
      await store.clearStarted.future;
      final secondEnqueue = queue.enqueue('uid-a');
      store.releaseClear.complete();
      await secondEnqueue;

      expect(await queue.drain(), CloudWriteResult.completed);
      expect(attempted, ['token-1', 'token-2']);
      expect(await store.read(), isNull);
    },
  );

  test(
    'deleted IDs survive coalescing and a later save revives its ID',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );

      await queue.enqueue('uid-a', deletedIds: {'book-a'});
      await queue.enqueue('uid-a', deletedIds: {'book-b'});
      expect((await store.read())?.deletedIds, {'book-a', 'book-b'});

      await queue.enqueue('uid-a', revivedIds: {'book-a'});
      expect((await store.read())?.deletedIds, {'book-b'});
    },
  );

  test(
    'v2 SharedPreferences marker restores deletion and legacy policy',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesBookshelfSyncOutboxStore.key: jsonEncode({
          'version': 2,
          'uid': 'uid-a',
          'operation_id': 'operation-1',
          'deleted_ids': ['book-a'],
          'allow_parent_only_legacy': true,
        }),
      });
      const store = SharedPreferencesBookshelfSyncOutboxStore();
      var captured = <BookshelfSyncPending>[];
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-2',
        attempt: (pending) async {
          captured = [pending];
          return CloudWriteResult.completed;
        },
      );
      expect(await restarted.drain(), CloudWriteResult.completed);

      expect(captured.single.operationId, 'operation-1');
      expect(captured.single.deletedIds, {'book-a'});
      expect(captured.single.allowParentOnlyLegacy, isTrue);
      expect(await store.read(), isNull);
    },
  );

  test(
    'markPending durably records work without starting an attempt',
    () async {
      final store = _MemoryOutboxStore();
      var attempts = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-1',
        attempt: (_) async {
          attempts += 1;
          return CloudWriteResult.completed;
        },
      );

      await queue.markPending('uid-a', deletedIds: {'book-a'});

      expect(attempts, 0);
      expect(store.value?.deletedIds, {'book-a'});

      expect(await queue.drain(), CloudWriteResult.completed);
      expect(attempts, 1);
      expect(store.value, isNull);
    },
  );

  test('a still-live local record suppresses a pre-delete tombstone', () {
    final pending = BookshelfSyncPending(
      uid: 'uid-a',
      operationId: 'operation-1',
      deletedIds: {'deleted', 'still-live'},
    );

    expect(pending.tombstonesAbsentFrom({'still-live'}), {'deleted'});
  });

  test(
    'running drain cannot consume a prepared deletion before commit',
    () async {
      final store = _MemoryOutboxStore()
        ..value = BookshelfSyncPending(
          uid: 'uid-a',
          operationId: 'operation-old',
        );
      final firstAttemptStarted = Completer<void>();
      final releaseFirstAttempt = Completer<void>();
      final attempted = <BookshelfSyncPending>[];
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          if (pending.operationId == 'operation-old') {
            firstAttemptStarted.complete();
            await releaseFirstAttempt.future;
          }
          return CloudWriteResult.completed;
        },
      );

      final firstDrain = queue.drain();
      await firstAttemptStarted.future;
      await queue.prepareDeletion('uid-a', {'book-a'});
      releaseFirstAttempt.complete();

      expect(await firstDrain, CloudWriteResult.blocked);
      expect(attempted.map((pending) => pending.operationId), [
        'operation-old',
      ]);
      expect(store.value?.preparedDeletedIds, {'book-a'});
      expect(store.value?.deletedIds, isEmpty);

      await queue.commitDeletion('uid-a', {'book-a'});
      expect(await queue.drain(), CloudWriteResult.completed);
      expect(attempted.last.deletedIds, {'book-a'});
      expect(attempted.last.preparedDeletedIds, isEmpty);
      expect(store.value, isNull);
    },
  );

  test(
    'restart cancels a prepared deletion when the local record is live',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final preparing = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.completed,
      );
      await preparing.prepareDeletion('uid-a', {'book-a'});

      final attempted = <BookshelfSyncPending>[];
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          return CloudWriteResult.completed;
        },
      );
      await restarted.reconcilePrepared('uid-a', {'book-a'});

      expect(await restarted.drain(), CloudWriteResult.completed);
      expect(attempted.single.deletedIds, isEmpty);
      expect(attempted.single.preparedDeletedIds, isEmpty);
      expect(store.value, isNull);
    },
  );

  test(
    'restart commits a prepared deletion when the local record is absent',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final preparing = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.completed,
      );
      await preparing.prepareDeletion('uid-a', {'book-a'});

      final attempted = <BookshelfSyncPending>[];
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          return CloudWriteResult.completed;
        },
      );
      await restarted.reconcilePrepared('uid-a', const {});

      expect(await restarted.drain(), CloudWriteResult.completed);
      expect(attempted.single.deletedIds, {'book-a'});
      expect(attempted.single.preparedDeletedIds, isEmpty);
      expect(store.value, isNull);
    },
  );

  test(
    'committed local delete recreates work after a concurrent revive',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.completed,
      );
      await queue.prepareDeletion('uid-a', {'book-a'});
      await queue.enqueue('uid-a', revivedIds: {'book-a'});
      expect(await queue.drain(), CloudWriteResult.completed);
      expect(store.value, isNull);

      await queue.commitDeletion('uid-a', {'book-a'});

      expect(store.value?.deletedIds, {'book-a'});
      expect(store.value?.preparedDeletedIds, isEmpty);
    },
  );

  test(
    'v3 SharedPreferences preserves prepared deletion across restart',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesBookshelfSyncOutboxStore.key: jsonEncode({
          'version': 3,
          'uid': 'uid-a',
          'operation_id': 'operation-1',
          'deleted_ids': <String>[],
          'prepared_deleted_ids': ['book-a'],
          'allow_parent_only_legacy': false,
        }),
      });
      const store = SharedPreferencesBookshelfSyncOutboxStore();
      var tokens = 0;
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );
      expect((await store.read())?.preparedDeletedIds, {'book-a'});

      await restarted.reconcilePrepared('uid-a', const {});

      expect((await store.read())?.preparedDeletedIds, isEmpty);
      expect((await store.read())?.deletedIds, {'book-a'});
    },
  );

  test('v4 restart preserves explicit revival and later delete wins', () async {
    SharedPreferences.setMockInitialValues({});
    const store = SharedPreferencesBookshelfSyncOutboxStore();
    var tokens = 0;
    final firstProcess = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'operation-${++tokens}',
      attempt: (_) async => CloudWriteResult.blocked,
    );
    await firstProcess.markPending('uid-a', deletedIds: {'book-a'});
    await firstProcess.markPending('uid-a', revivedIds: {'book-a'});

    final afterRestart = await store.read();
    expect(afterRestart?.deletedIds, isEmpty);
    expect(afterRestart?.revivedIds, {'book-a'});

    final restarted = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'operation-${++tokens}',
      attempt: (_) async => CloudWriteResult.blocked,
    );
    await restarted.prepareDeletion('uid-a', {'book-a'});
    await restarted.commitDeletion('uid-a', {'book-a'});

    final afterDelete = await store.read();
    expect(afterDelete?.deletedIds, {'book-a'});
    expect(afterDelete?.revivedIds, isEmpty);
  });

  test(
    'v4 prepared revival marker synthesizes a restart-compatible lease',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesBookshelfSyncOutboxStore.key: jsonEncode({
          'version': 4,
          'uid': 'uid-a',
          'operation_id': 'legacy-operation',
          'deleted_ids': <String>[],
          'prepared_deleted_ids': <String>[],
          'revived_ids': <String>[],
          'prepared_revived_ids': ['book-a'],
          'allow_parent_only_legacy': false,
        }),
      });
      const store = SharedPreferencesBookshelfSyncOutboxStore();
      final restored = await store.read();
      expect(restored?.preparedRevivalLeases, {'book-a': 'legacy-operation'});

      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-next',
        attempt: (_) async => CloudWriteResult.blocked,
      );
      await restarted.reconcilePrepared('uid-a', {'book-a'});

      expect((await store.read())?.revivedIds, {'book-a'});
      expect((await store.read())?.preparedRevivalLeases, isEmpty);
    },
  );

  test(
    'write-ahead revival blocks drain until strict local save commits',
    () async {
      final store = _MemoryOutboxStore();
      final attempted = <BookshelfSyncPending>[];
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          return CloudWriteResult.blocked;
        },
      );
      final workflow = BookshelfRevivalWorkflow(queue);
      final releaseSave = Completer<void>();
      final saveStarted = Completer<void>();
      var writeAttempted = false;
      final liveIds = <String>{};

      final saving = workflow.run(
        uid: 'uid-a',
        ids: const {'book-a'},
        saveLocal: () async {
          expect(store.value?.preparedRevivedIds, {'book-a'});
          saveStarted.complete();
          await releaseSave.future;
          writeAttempted = true;
          liveIds.add('book-a');
        },
        readStrictLiveIds: () => liveIds,
        localWriteWasAttempted: () => writeAttempted,
      );
      await saveStarted.future;

      expect(await queue.drain(), CloudWriteResult.blocked);
      expect(attempted, isEmpty);
      releaseSave.complete();
      await saving;

      expect(store.value?.preparedRevivedIds, isEmpty);
      expect(store.value?.revivedIds, {'book-a'});
    },
  );

  test(
    'restart reconciles prepared revival from strict local presence',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );
      await queue.prepareRevival('uid-a', {'book-a'});

      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );
      await restarted.reconcilePrepared('uid-a', {'book-a'});

      expect(store.value?.preparedRevivedIds, isEmpty);
      expect(store.value?.revivedIds, {'book-a'});
    },
  );

  test(
    'restart cancels prepared revival when strict local save is absent',
    () async {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );
      await queue.prepareRevival('uid-a', {'book-a'});

      await queue.reconcilePrepared('uid-a', const {});

      expect(store.value?.preparedRevivedIds, isEmpty);
      expect(store.value?.revivedIds, isEmpty);
    },
  );

  test(
    'late revival commit cannot erase a newer durable delete intent',
    () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPreferencesBookshelfSyncOutboxStore();
      var tokens = 0;
      final firstProcess = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (_) async => CloudWriteResult.blocked,
      );

      final revivalLease = await firstProcess.prepareRevival('uid-a', {
        'book-a',
      });
      expect((await store.read())?.preparedRevivalLeases, {
        'book-a': revivalLease,
      });
      await firstProcess.prepareDeletion('uid-a', {'book-a'});
      await firstProcess.commitRevival('uid-a', {
        'book-a',
      }, leaseToken: revivalLease);

      final afterLateCommit = await store.read();
      expect(afterLateCommit?.preparedDeletedIds, {'book-a'});
      expect(afterLateCommit?.revivedIds, isEmpty);
      expect(afterLateCommit?.preparedRevivedIds, isEmpty);

      final attempted = <BookshelfSyncPending>[];
      final restarted = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          return CloudWriteResult.completed;
        },
      );
      // The crash happened before the newer deletion could remove local data.
      // Recovery cancels that prepared delete, but must never infer a revival.
      await restarted.reconcilePrepared('uid-a', {'book-a'});
      expect((await store.read())?.revivedIds, isEmpty);
      await restarted.drain();

      expect(attempted.single.revivedIds, isEmpty);
      expect(await store.read(), isNull);
    },
  );

  for (final switchKind in ['uid', 'epoch', 'mode']) {
    test(
      'approval store write is fenced against stale $switchKind session',
      () async {
        final store = _DelayedReadOutboxStore();
        final sessions = CloudWriteSessionController();
        sessions.acquire('uid-a');
        final session = sessions.transition(CloudWriteMode.reconciling);
        final queue = BookshelfSyncQueue(
          store: store,
          tokenFactory: () => 'operation',
          attempt: (_) async => CloudWriteResult.blocked,
        );

        final approval = BookshelfParentOnlyLegacyApprovalWorkflow(
          queue,
        ).run(uid: 'uid-a', session: session, sessions: sessions);
        await store.readStarted.future;
        if (switchKind == 'uid') {
          sessions.acquire('uid-b');
        } else if (switchKind == 'epoch') {
          sessions.transition(CloudWriteMode.reconciling);
        } else {
          sessions.transition(CloudWriteMode.ready);
        }
        store.releaseRead.complete();

        await expectLater(approval, throwsStateError);
        expect(store.writeCount, 0);
        expect(store.value, isNull);
      },
    );
  }

  test('parse failure rolls back prepared deletion without restart', () async {
    final store = _MemoryOutboxStore();
    final queue = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'operation',
      attempt: (_) async => CloudWriteResult.completed,
    );
    final workflow = BookshelfDeletionWorkflow(queue);
    var writeAttempted = false;

    await expectLater(
      workflow.run(
        uid: 'uid-a',
        ids: const {'book-a'},
        deleteLocal: () async => throw const FormatException('bad local JSON'),
        readStrictLiveIds: () => throw const FormatException('bad local JSON'),
        localWriteWasAttempted: () => writeAttempted,
      ),
      throwsFormatException,
    );

    expect(await queue.drain(), CloudWriteResult.completed);
    expect(store.value, isNull);
  });

  test('local write failure reconciles live record without restart', () async {
    final store = _MemoryOutboxStore();
    final queue = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'operation',
      attempt: (_) async => CloudWriteResult.completed,
    );
    final workflow = BookshelfDeletionWorkflow(queue);
    var writeAttempted = false;

    await expectLater(
      workflow.run(
        uid: 'uid-a',
        ids: const {'book-a'},
        deleteLocal: () async {
          writeAttempted = true;
          throw StateError('strict write failed');
        },
        readStrictLiveIds: () => {'book-a'},
        localWriteWasAttempted: () => writeAttempted,
      ),
      throwsStateError,
    );

    expect(await queue.drain(), CloudWriteResult.completed);
    expect(store.value, isNull);
  });

  test(
    'commit failure reconciles absent record and resumes without restart',
    () async {
      final store = _FailOnceOutboxStore();
      final attempted = <BookshelfSyncPending>[];
      var tokens = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++tokens}',
        attempt: (pending) async {
          attempted.add(pending);
          return CloudWriteResult.completed;
        },
      );
      final workflow = BookshelfDeletionWorkflow(queue);
      final liveIds = <String>{'book-a'};
      var writeAttempted = false;

      await expectLater(
        workflow.run(
          uid: 'uid-a',
          ids: const {'book-a'},
          deleteLocal: () async {
            writeAttempted = true;
            liveIds.remove('book-a');
            store.failNextWrite = true;
          },
          readStrictLiveIds: () => liveIds,
          localWriteWasAttempted: () => writeAttempted,
        ),
        throwsStateError,
      );

      expect(await queue.drain(), CloudWriteResult.completed);
      expect(attempted.single.deletedIds, {'book-a'});
      expect(store.value, isNull);
    },
  );
}

class _MemoryOutboxStore implements BookshelfSyncOutboxStore {
  BookshelfSyncPending? value;
  bool failReads = false;

  @override
  Future<bool> clearIfMatches(BookshelfSyncPending pending) async {
    if (value != pending) return false;
    value = null;
    return true;
  }

  @override
  Future<BookshelfSyncPending?> read() async {
    if (failReads) throw StateError('read unavailable');
    return value;
  }

  @override
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  }) async {
    beforeEffect?.call();
    value = pending;
  }
}

class _RacyOutboxStore implements BookshelfSyncOutboxStore {
  BookshelfSyncPending? value;
  final clearStarted = Completer<void>();
  final releaseClear = Completer<void>();
  var clearCalls = 0;

  @override
  Future<bool> clearIfMatches(BookshelfSyncPending pending) async {
    final matches = value == pending;
    clearCalls += 1;
    if (clearCalls == 1) {
      clearStarted.complete();
      await releaseClear.future;
    }
    if (!matches) return false;
    value = null;
    return true;
  }

  @override
  Future<BookshelfSyncPending?> read() async => value;

  @override
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  }) async {
    beforeEffect?.call();
    value = pending;
  }
}

class _FailOnceOutboxStore extends _MemoryOutboxStore {
  bool failNextWrite = false;

  @override
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  }) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('outbox write failed');
    }
    await super.write(pending, beforeEffect: beforeEffect);
  }
}

class _DelayedReadOutboxStore extends _MemoryOutboxStore {
  final readStarted = Completer<void>();
  final releaseRead = Completer<void>();
  var writeCount = 0;

  @override
  Future<BookshelfSyncPending?> read() async {
    if (!readStarted.isCompleted) readStarted.complete();
    await releaseRead.future;
    return super.read();
  }

  @override
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  }) async {
    beforeEffect?.call();
    writeCount += 1;
    await super.write(pending);
  }
}
