import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_sync_outbox.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

/// A [Random] stub that always returns [value] from [nextDouble] — lets a
/// test assert an exact backoff delay instead of a jittered range.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

class _MemoryOutboxStore implements BookshelfSyncOutboxStore {
  BookshelfSyncPending? value;

  @override
  Future<bool> clearIfMatches(BookshelfSyncPending pending) async {
    if (value != pending) {
      return false;
    }
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

void main() {
  test('3 immediate attempts back off exactly 400ms then 800ms with no 4th '
      'attempt (zero jitter)', () {
    fakeAsync((async) {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      var attempts = 0;
      final attemptElapsedMs = <int>[];
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (_) async {
          attempts += 1;
          attemptElapsedMs.add(async.elapsed.inMilliseconds);
          return CloudWriteResult.blocked;
        },
        random: _FixedRandom(0.5), // jitterFraction == 0
      );

      unawaited(queue.enqueue('uid-a'));
      async.elapse(const Duration(seconds: 10));

      expect(attempts, 3);
      expect(attemptElapsedMs, [0, 400, 1200]);
    });
  });

  test(
    '3 immediate attempts respect the +/-25% jitter band around 400ms/800ms',
    () {
      fakeAsync((async) {
        final store = _MemoryOutboxStore();
        var tokens = 0;
        final attemptElapsedMs = <int>[];
        final queue = BookshelfSyncQueue(
          store: store,
          tokenFactory: () => 'token-${++tokens}',
          attempt: (_) async {
            attemptElapsedMs.add(async.elapsed.inMilliseconds);
            return CloudWriteResult.blocked;
          },
          random: Random(42),
        );

        unawaited(queue.enqueue('uid-a'));
        async.elapse(const Duration(seconds: 10));

        expect(attemptElapsedMs.length, 3);
        final firstGap = attemptElapsedMs[1] - attemptElapsedMs[0];
        final secondGap = attemptElapsedMs[2] - attemptElapsedMs[1];
        expect(firstGap, inInclusiveRange(300, 500));
        expect(secondGap, inInclusiveRange(600, 1000));
      });
    },
  );

  test('no delay before the first attempt and none after success', () {
    fakeAsync((async) {
      final store = _MemoryOutboxStore();
      var tokens = 0;
      final attemptElapsedMs = <int>[];
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'token-${++tokens}',
        attempt: (_) async {
          attemptElapsedMs.add(async.elapsed.inMilliseconds);
          return CloudWriteResult.completed;
        },
        random: _FixedRandom(0.5),
      );

      unawaited(queue.enqueue('uid-a'));
      async.elapse(const Duration(seconds: 10));

      expect(attemptElapsedMs, [0]);
    });
  });

  test('a default-constructed queue uses a real Random (no crash)', () {
    final store = _MemoryOutboxStore();
    final queue = BookshelfSyncQueue(
      store: store,
      tokenFactory: () => 'token-1',
      attempt: (_) async => CloudWriteResult.blocked,
    );
    expect(queue, isNotNull);
  });
}
