import 'dart:async';

import 'cloud_write_session.dart';

class BookshelfSyncPending {
  const BookshelfSyncPending({required this.uid, required this.token});

  final String uid;
  final String token;

  @override
  bool operator ==(Object other) =>
      other is BookshelfSyncPending && other.uid == uid && other.token == token;

  @override
  int get hashCode => Object.hash(uid, token);
}

abstract interface class BookshelfSyncOutboxStore {
  Future<BookshelfSyncPending?> read();
  Future<void> write(BookshelfSyncPending pending);
  Future<bool> clearIfMatches(BookshelfSyncPending pending);
}

typedef BookshelfSyncAttempt =
    Future<CloudWriteResult> Function(BookshelfSyncPending pending);

/// A durable single-flight queue. The outbox stores identity and a monotonic
/// token only; the attempt always reads the latest local bookshelf snapshot.
class BookshelfSyncQueue {
  BookshelfSyncQueue({
    required this.store,
    required this.tokenFactory,
    required this.attempt,
    this.maxImmediateAttempts = 3,
  }) : assert(maxImmediateAttempts > 0);

  final BookshelfSyncOutboxStore store;
  final String Function() tokenFactory;
  final BookshelfSyncAttempt attempt;
  final int maxImmediateAttempts;

  Future<CloudWriteResult>? _draining;
  Future<void> _mutationTail = Future<void>.value();

  Future<void> enqueue(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }
    final token = tokenFactory();
    if (token.trim().isEmpty) {
      throw StateError('Bookshelf sync token is empty.');
    }
    final pending = BookshelfSyncPending(uid: uid, token: token);
    await _runStoreMutation(() => store.write(pending));
    unawaited(drain());
  }

  Future<CloudWriteResult> drain() {
    final current = _draining;
    if (current != null) return current;
    final next = _drainSafely();
    _draining = next;
    return next.whenComplete(() {
      if (identical(_draining, next)) _draining = null;
    });
  }

  Future<CloudWriteResult> _drainSafely() async {
    try {
      return await _drainLoop();
    } on Object {
      return CloudWriteResult.blocked;
    }
  }

  Future<CloudWriteResult> _drainLoop() async {
    while (true) {
      final initial = await store.read();
      if (initial == null) return CloudWriteResult.completed;
      var pending = initial;

      CloudWriteResult result = CloudWriteResult.blocked;
      for (var index = 0; index < maxImmediateAttempts; index += 1) {
        final latest = await store.read();
        if (latest == null) return CloudWriteResult.completed;
        pending = latest;
        try {
          result = await attempt(pending);
        } on Object {
          return CloudWriteResult.blocked;
        }
        if (result == CloudWriteResult.completed ||
            result == CloudWriteResult.stale) {
          break;
        }
      }
      if (result != CloudWriteResult.completed) return result;

      final cleared = await _runStoreMutation(
        () => store.clearIfMatches(pending),
      );
      if (!cleared) {
        // A newer enqueue won the token race. Loop and sync the latest local
        // snapshot before clearing that newer durable marker.
        continue;
      }
    }
  }

  Future<T> _runStoreMutation<T>(Future<T> Function() mutation) {
    final result = _mutationTail.then((_) => mutation());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
