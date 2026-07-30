import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_sync_outbox.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

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
    final store = _MemoryOutboxStore()..failReads = true;
    final queue = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'token-1',
      attempt: (_) async => CloudWriteResult.completed,
    );

    await queue.enqueue('uid-a');

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
  Future<void> write(BookshelfSyncPending pending) async {
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
  Future<void> write(BookshelfSyncPending pending) async {
    value = pending;
  }
}
