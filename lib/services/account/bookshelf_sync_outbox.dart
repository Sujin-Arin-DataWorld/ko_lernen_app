import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_write_session.dart';

class BookshelfSyncPending {
  BookshelfSyncPending({
    required this.uid,
    required this.operationId,
    Set<String> deletedIds = const {},
    Set<String> preparedDeletedIds = const {},
    Set<String> revivedIds = const {},
    Set<String> preparedRevivedIds = const {},
    this.allowParentOnlyLegacy = false,
  }) : deletedIds = Set.unmodifiable(deletedIds),
       preparedDeletedIds = Set.unmodifiable(preparedDeletedIds),
       revivedIds = Set.unmodifiable(revivedIds),
       preparedRevivedIds = Set.unmodifiable(preparedRevivedIds) {
    final allIds = {
      ...deletedIds,
      ...preparedDeletedIds,
      ...revivedIds,
      ...preparedRevivedIds,
    };
    if (allIds.length !=
        deletedIds.length +
            preparedDeletedIds.length +
            revivedIds.length +
            preparedRevivedIds.length) {
      throw ArgumentError(
        'Bookshelf deletion and revival intents must be disjoint.',
      );
    }
    if (allIds.length > 400) {
      throw const FormatException('Bookshelf outbox has too many intents.');
    }
  }

  final String uid;
  final String operationId;
  final Set<String> deletedIds;
  final Set<String> preparedDeletedIds;
  final Set<String> revivedIds;
  final Set<String> preparedRevivedIds;
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
      other.deletedIds.containsAll(deletedIds) &&
      other.preparedDeletedIds.length == preparedDeletedIds.length &&
      other.preparedDeletedIds.containsAll(preparedDeletedIds) &&
      other.revivedIds.length == revivedIds.length &&
      other.revivedIds.containsAll(revivedIds) &&
      other.preparedRevivedIds.length == preparedRevivedIds.length &&
      other.preparedRevivedIds.containsAll(preparedRevivedIds);

  @override
  int get hashCode => Object.hash(
    uid,
    operationId,
    allowParentOnlyLegacy,
    Object.hashAllUnordered(deletedIds),
    Object.hashAllUnordered(preparedDeletedIds),
    Object.hashAllUnordered(revivedIds),
    Object.hashAllUnordered(preparedRevivedIds),
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
        (decoded['version'] != 1 &&
            decoded['version'] != 2 &&
            decoded['version'] != 3 &&
            decoded['version'] != 4) ||
        decoded['uid'] is! String ||
        (decoded['operation_id'] ?? decoded['token']) is! String) {
      throw const FormatException('Invalid bookshelf sync outbox.');
    }
    final uid = decoded['uid'] as String;
    final operationId = (decoded['operation_id'] ?? decoded['token']) as String;
    final rawDeletedIds = decoded['deleted_ids'] ?? const <Object>[];
    final rawPreparedDeletedIds =
        decoded['prepared_deleted_ids'] ?? const <Object>[];
    final rawRevivedIds = decoded['revived_ids'] ?? const <Object>[];
    final rawPreparedRevivedIds =
        decoded['prepared_revived_ids'] ?? const <Object>[];
    final allowParentOnlyLegacy = decoded['allow_parent_only_legacy'] ?? false;
    if (uid.trim().isEmpty ||
        uid.length > 256 ||
        operationId.trim().isEmpty ||
        operationId.length > 256 ||
        rawDeletedIds is! List ||
        rawPreparedDeletedIds is! List ||
        rawRevivedIds is! List ||
        rawPreparedRevivedIds is! List ||
        allowParentOnlyLegacy is! bool) {
      throw const FormatException('Invalid bookshelf sync outbox.');
    }
    final deletedIds = <String>{};
    for (final value in rawDeletedIds) {
      if (value is! String || !deletedIds.add(value)) {
        throw const FormatException('Invalid bookshelf sync outbox.');
      }
    }
    final preparedDeletedIds = <String>{};
    for (final value in rawPreparedDeletedIds) {
      if (value is! String ||
          !preparedDeletedIds.add(value) ||
          deletedIds.contains(value)) {
        throw const FormatException('Invalid bookshelf sync outbox.');
      }
    }
    final revivedIds = <String>{};
    for (final value in rawRevivedIds) {
      if (value is! String ||
          !revivedIds.add(value) ||
          deletedIds.contains(value) ||
          preparedDeletedIds.contains(value)) {
        throw const FormatException('Invalid bookshelf sync outbox.');
      }
    }
    final preparedRevivedIds = <String>{};
    for (final value in rawPreparedRevivedIds) {
      if (value is! String ||
          !preparedRevivedIds.add(value) ||
          deletedIds.contains(value) ||
          preparedDeletedIds.contains(value) ||
          revivedIds.contains(value)) {
        throw const FormatException('Invalid bookshelf sync outbox.');
      }
    }
    _requireRecordIds(deletedIds);
    _requireRecordIds(preparedDeletedIds);
    _requireRecordIds(revivedIds);
    _requireRecordIds(preparedRevivedIds);
    return BookshelfSyncPending(
      uid: uid,
      operationId: operationId,
      deletedIds: deletedIds,
      preparedDeletedIds: preparedDeletedIds,
      revivedIds: revivedIds,
      preparedRevivedIds: preparedRevivedIds,
      allowParentOnlyLegacy: allowParentOnlyLegacy,
    );
  }

  @override
  Future<void> write(BookshelfSyncPending pending) async {
    _requireRecordIds(pending.deletedIds);
    _requireRecordIds(pending.preparedDeletedIds);
    _requireRecordIds(pending.revivedIds);
    _requireRecordIds(pending.preparedRevivedIds);
    final preferences = await SharedPreferences.getInstance();
    final written = await preferences.setString(
      key,
      jsonEncode({
        'version': 4,
        'uid': pending.uid,
        'operation_id': pending.operationId,
        'deleted_ids': pending.deletedIds.toList()..sort(),
        'prepared_deleted_ids': pending.preparedDeletedIds.toList()..sort(),
        'revived_ids': pending.revivedIds.toList()..sort(),
        'prepared_revived_ids': pending.preparedRevivedIds.toList()..sort(),
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
    if (deletedIds.any(revivedIds.contains)) {
      throw ArgumentError('Bookshelf delete and revive intents overlap.');
    }
    await _runStoreMutation(() async {
      final current = await store.read();
      final sameUid = current?.uid == uid;
      final nextDeletedIds = <String>{if (sameUid) ...current!.deletedIds};
      final nextPreparedDeletedIds = <String>{
        if (sameUid) ...current!.preparedDeletedIds,
      };
      final nextRevivedIds = <String>{if (sameUid) ...current!.revivedIds};
      final nextPreparedRevivedIds = <String>{
        if (sameUid) ...current!.preparedRevivedIds,
      };
      void replaceIntent(String id, Set<String> target) {
        nextDeletedIds.remove(id);
        nextPreparedDeletedIds.remove(id);
        nextRevivedIds.remove(id);
        nextPreparedRevivedIds.remove(id);
        target.add(id);
      }

      for (final id in deletedIds) {
        replaceIntent(id, nextDeletedIds);
      }
      for (final id in revivedIds) {
        replaceIntent(id, nextRevivedIds);
      }
      final pending = BookshelfSyncPending(
        uid: uid,
        operationId: token,
        deletedIds: nextDeletedIds,
        preparedDeletedIds: nextPreparedDeletedIds,
        revivedIds: nextRevivedIds,
        preparedRevivedIds: nextPreparedRevivedIds,
        allowParentOnlyLegacy:
            allowParentOnlyLegacy ??
            (sameUid && current!.allowParentOnlyLegacy),
      );
      await store.write(pending);
    });
  }

  Future<void> prepareDeletion(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) return;
    final token = _newToken();
    await _runStoreMutation(() async {
      final current = await store.read();
      final sameUid = current?.uid == uid;
      final nextPreparedDeletedIds = <String>{
        if (sameUid) ...current!.preparedDeletedIds,
        ...ids,
      };
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: {
            if (sameUid)
              ...current!.deletedIds.where((id) => !ids.contains(id)),
          },
          preparedDeletedIds: nextPreparedDeletedIds,
          revivedIds: {
            if (sameUid)
              ...current!.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            if (sameUid)
              ...current!.preparedRevivedIds.where((id) => !ids.contains(id)),
          },
          allowParentOnlyLegacy: sameUid && current!.allowParentOnlyLegacy,
        ),
      );
    });
  }

  Future<void> commitDeletion(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) return;
    final token = _newToken();
    await _runStoreMutation(() async {
      final current = await store.read();
      if (current != null && current.uid != uid) {
        throw StateError('Bookshelf deletion account changed before commit.');
      }
      final nextPreparedDeletedIds = <String>{...?current?.preparedDeletedIds}
        ..removeAll(ids);
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: {
            ...?current?.deletedIds.where((id) => !ids.contains(id)),
            ...ids,
          },
          preparedDeletedIds: nextPreparedDeletedIds,
          revivedIds: {
            ...?current?.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            ...?current?.preparedRevivedIds.where((id) => !ids.contains(id)),
          },
          allowParentOnlyLegacy: current?.allowParentOnlyLegacy ?? false,
        ),
      );
    });
  }

  Future<void> prepareRevival(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) return;
    final token = _newToken();
    await _runStoreMutation(() async {
      final current = await store.read();
      final sameUid = current?.uid == uid;
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: {
            if (sameUid)
              ...current!.deletedIds.where((id) => !ids.contains(id)),
          },
          preparedDeletedIds: {
            if (sameUid)
              ...current!.preparedDeletedIds.where((id) => !ids.contains(id)),
          },
          revivedIds: {
            if (sameUid)
              ...current!.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            if (sameUid) ...current!.preparedRevivedIds,
            ...ids,
          },
          allowParentOnlyLegacy: sameUid && current!.allowParentOnlyLegacy,
        ),
      );
    });
  }

  Future<void> commitRevival(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) return;
    final token = _newToken();
    await _runStoreMutation(() async {
      final current = await store.read();
      if (current != null && current.uid != uid) {
        throw StateError('Bookshelf revival account changed before commit.');
      }
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: {
            ...?current?.deletedIds.where((id) => !ids.contains(id)),
          },
          preparedDeletedIds: {
            ...?current?.preparedDeletedIds.where((id) => !ids.contains(id)),
          },
          revivedIds: {
            ...?current?.revivedIds.where((id) => !ids.contains(id)),
            ...ids,
          },
          preparedRevivedIds: {
            ...?current?.preparedRevivedIds.where((id) => !ids.contains(id)),
          },
          allowParentOnlyLegacy: current?.allowParentOnlyLegacy ?? false,
        ),
      );
    });
  }

  Future<void> reconcilePrepared(String uid, Iterable<String> liveIds) async {
    _requireUid(uid);
    final live = liveIds.toSet();
    await _runStoreMutation(() async {
      final current = await store.read();
      if (current == null ||
          current.uid != uid ||
          (current.preparedDeletedIds.isEmpty &&
              current.preparedRevivedIds.isEmpty)) {
        return;
      }
      final committedAfterCrash = current.preparedDeletedIds.difference(live);
      final revivedAfterCrash = current.preparedRevivedIds.intersection(live);
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: _newToken(),
          deletedIds: {...current.deletedIds, ...committedAfterCrash},
          revivedIds: {...current.revivedIds, ...revivedAfterCrash},
          allowParentOnlyLegacy: current.allowParentOnlyLegacy,
        ),
      );
    });
  }

  Future<void> cancelPrepared(
    String uid, {
    Set<String> deletedIds = const {},
    Set<String> revivedIds = const {},
  }) async {
    _requireUid(uid);
    _requireRecordIds(deletedIds);
    _requireRecordIds(revivedIds);
    await _runStoreMutation(() async {
      final current = await store.read();
      if (current == null || current.uid != uid) return;
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: _newToken(),
          deletedIds: current.deletedIds,
          preparedDeletedIds: {
            ...current.preparedDeletedIds.where(
              (id) => !deletedIds.contains(id),
            ),
          },
          revivedIds: current.revivedIds,
          preparedRevivedIds: {
            ...current.preparedRevivedIds.where(
              (id) => !revivedIds.contains(id),
            ),
          },
          allowParentOnlyLegacy: current.allowParentOnlyLegacy,
        ),
      );
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
      if (initial.preparedDeletedIds.isNotEmpty ||
          initial.preparedRevivedIds.isNotEmpty) {
        return CloudWriteResult.blocked;
      }
      var pending = initial;

      CloudWriteResult result = CloudWriteResult.blocked;
      for (var index = 0; index < maxImmediateAttempts; index += 1) {
        final latest = await store.read();
        if (latest == null) return CloudWriteResult.completed;
        if (latest.preparedDeletedIds.isNotEmpty ||
            latest.preparedRevivedIds.isNotEmpty) {
          return CloudWriteResult.blocked;
        }
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

  String _newToken() {
    final token = tokenFactory();
    if (token.trim().isEmpty) {
      throw StateError('Bookshelf sync token is empty.');
    }
    return token;
  }
}

class BookshelfDeletionWorkflow {
  const BookshelfDeletionWorkflow(this.queue);

  final BookshelfSyncQueue queue;

  Future<void> run({
    required String uid,
    required Set<String> ids,
    required Future<void> Function() deleteLocal,
    required Set<String> Function() readStrictLiveIds,
    required bool Function() localWriteWasAttempted,
  }) async {
    await queue.prepareDeletion(uid, ids);
    try {
      await deleteLocal();
      await queue.commitDeletion(uid, ids);
    } on Object catch (error, stackTrace) {
      await _recover(
        uid: uid,
        ids: ids,
        readStrictLiveIds: readStrictLiveIds,
        localWriteWasAttempted: localWriteWasAttempted,
      );
      unawaited(queue.drain());
      Error.throwWithStackTrace(error, stackTrace);
    }
    unawaited(queue.drain());
  }

  Future<void> _recover({
    required String uid,
    required Set<String> ids,
    required Set<String> Function() readStrictLiveIds,
    required bool Function() localWriteWasAttempted,
  }) async {
    try {
      await queue.reconcilePrepared(uid, readStrictLiveIds());
    } on Object {
      if (!localWriteWasAttempted()) {
        await queue.cancelPrepared(uid, deletedIds: ids);
      }
    }
  }
}

class BookshelfRevivalWorkflow {
  const BookshelfRevivalWorkflow(this.queue);

  final BookshelfSyncQueue queue;

  Future<void> run({
    required String uid,
    required Set<String> ids,
    required Future<void> Function() saveLocal,
    required Set<String> Function() readStrictLiveIds,
    required bool Function() localWriteWasAttempted,
  }) async {
    await queue.prepareRevival(uid, ids);
    try {
      await saveLocal();
      await queue.commitRevival(uid, ids);
    } on Object catch (error, stackTrace) {
      try {
        await queue.reconcilePrepared(uid, readStrictLiveIds());
      } on Object {
        if (!localWriteWasAttempted()) {
          await queue.cancelPrepared(uid, revivedIds: ids);
        }
      }
      unawaited(queue.drain());
      Error.throwWithStackTrace(error, stackTrace);
    }
    unawaited(queue.drain());
  }
}

void _requireUid(String uid) {
  if (uid.trim().isEmpty) {
    throw ArgumentError.value(uid, 'uid', 'must not be empty');
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
