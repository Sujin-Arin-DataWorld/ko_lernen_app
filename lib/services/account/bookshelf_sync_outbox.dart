import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_write_session.dart';

class BookshelfSyncPending {
  BookshelfSyncPending({
    required this.uid,
    required this.operationId,
    Set<String> deletedIds = const {},
    this.allowParentOnlyLegacy = false,
  }) : deletedIds = Set.unmodifiable(deletedIds);

  final String uid;
  final String operationId;
  final Set<String> deletedIds;
  final bool allowParentOnlyLegacy;

  String get token => operationId;

  Set<String> tombstonesAbsentFrom(Iterable<String> liveIds) {
    final live = liveIds.toSet();
    return Set.unmodifiable(deletedIds.difference(live));
  }

  @override
  bool operator ==(Object other) =>
      other is BookshelfSyncPending &&
      other.uid == uid &&
      other.operationId == operationId &&
      other.allowParentOnlyLegacy == allowParentOnlyLegacy &&
      other.deletedIds.length == deletedIds.length &&
      other.deletedIds.containsAll(deletedIds);

  @override
  int get hashCode => Object.hash(
    uid,
    operationId,
    allowParentOnlyLegacy,
    Object.hashAllUnordered(deletedIds),
  );
}

abstract interface class BookshelfSyncOutboxStore {
  Future<BookshelfSyncPending?> read();
  Future<void> write(BookshelfSyncPending pending);
  Future<bool> clearIfMatches(BookshelfSyncPending pending);
}

class SharedPreferencesBookshelfSyncOutboxStore
    implements BookshelfSyncOutboxStore {
  const SharedPreferencesBookshelfSyncOutboxStore();

  static const key = 'kl_bookshelf_sync_outbox_v1';

  @override
  Future<BookshelfSyncPending?> read() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final raw = preferences.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        (decoded['version'] != 1 && decoded['version'] != 2) ||
        decoded['uid'] is! String ||
        (decoded['operation_id'] ?? decoded['token']) is! String) {
      throw const FormatException('Invalid bookshelf sync outbox.');
    }
    final uid = decoded['uid'] as String;
    final operationId = (decoded['operation_id'] ?? decoded['token']) as String;
    final rawDeletedIds = decoded['deleted_ids'] ?? const <Object>[];
    final allowParentOnlyLegacy = decoded['allow_parent_only_legacy'] ?? false;
    if (uid.trim().isEmpty ||
        uid.length > 256 ||
        operationId.trim().isEmpty ||
        operationId.length > 256 ||
        rawDeletedIds is! List ||
        allowParentOnlyLegacy is! bool) {
      throw const FormatException('Invalid bookshelf sync outbox.');
    }
    final deletedIds = <String>{};
    for (final value in rawDeletedIds) {
      if (value is! String || !deletedIds.add(value)) {
        throw const FormatException('Invalid bookshelf sync outbox.');
      }
    }
    _requireRecordIds(deletedIds);
    return BookshelfSyncPending(
      uid: uid,
      operationId: operationId,
      deletedIds: deletedIds,
      allowParentOnlyLegacy: allowParentOnlyLegacy,
    );
  }

  @override
  Future<void> write(BookshelfSyncPending pending) async {
    _requireRecordIds(pending.deletedIds);
    final preferences = await SharedPreferences.getInstance();
    final written = await preferences.setString(
      key,
      jsonEncode({
        'version': 2,
        'uid': pending.uid,
        'operation_id': pending.operationId,
        'deleted_ids': pending.deletedIds.toList()..sort(),
        'allow_parent_only_legacy': pending.allowParentOnlyLegacy,
      }),
    );
    if (!written) throw StateError('Bookshelf sync outbox write failed.');
  }

  @override
  Future<bool> clearIfMatches(BookshelfSyncPending pending) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final current = await read();
    if (current != pending) return false;
    final removed = await preferences.remove(key);
    if (!removed) throw StateError('Bookshelf sync outbox clear failed.');
    return true;
  }
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

  Future<void> enqueue(
    String uid, {
    Set<String> deletedIds = const {},
    Set<String> revivedIds = const {},
    bool? allowParentOnlyLegacy,
  }) async {
    await markPending(
      uid,
      deletedIds: deletedIds,
      revivedIds: revivedIds,
      allowParentOnlyLegacy: allowParentOnlyLegacy,
    );
    unawaited(drain());
  }

  Future<void> markPending(
    String uid, {
    Set<String> deletedIds = const {},
    Set<String> revivedIds = const {},
    bool? allowParentOnlyLegacy,
  }) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }
    final token = tokenFactory();
    if (token.trim().isEmpty) {
      throw StateError('Bookshelf sync token is empty.');
    }
    _requireRecordIds(deletedIds);
    _requireRecordIds(revivedIds);
    await _runStoreMutation(() async {
      final current = await store.read();
      final carriedDeletedIds = current?.uid == uid
          ? current!.deletedIds
          : const <String>{};
      final nextDeletedIds = <String>{...carriedDeletedIds, ...deletedIds}
        ..removeAll(revivedIds);
      final pending = BookshelfSyncPending(
        uid: uid,
        operationId: token,
        deletedIds: nextDeletedIds,
        allowParentOnlyLegacy:
            allowParentOnlyLegacy ??
            (current?.uid == uid && current!.allowParentOnlyLegacy),
      );
      await store.write(pending);
    });
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

void _requireRecordIds(Set<String> ids) {
  if (ids.length > 400) {
    throw const FormatException('Bookshelf outbox has too many deleted IDs.');
  }
  for (final id in ids) {
    if (id.isEmpty ||
        id.length > 256 ||
        id.contains('/') ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(id)) {
      throw const FormatException('Bookshelf outbox has an invalid record ID.');
    }
  }
}
