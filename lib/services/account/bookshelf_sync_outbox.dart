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
    Map<String, String> preparedDeletionLeases = const {},
    Set<String> revivedIds = const {},
    Set<String> preparedRevivedIds = const {},
    Map<String, String> preparedRevivalLeases = const {},
    this.allowParentOnlyLegacy = false,
  }) : deletedIds = Set.unmodifiable(deletedIds),
       preparedDeletedIds = Set.unmodifiable(preparedDeletedIds),
       preparedDeletionLeases = Map.unmodifiable(
         _normalizePreparedLeases(
           operationId,
           preparedDeletedIds,
           preparedDeletionLeases,
         ),
       ),
       revivedIds = Set.unmodifiable(revivedIds),
       preparedRevivedIds = Set.unmodifiable(preparedRevivedIds),
       preparedRevivalLeases = Map.unmodifiable(
         _normalizePreparedLeases(
           operationId,
           preparedRevivedIds,
           preparedRevivalLeases,
         ),
       ) {
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
  final Map<String, String> preparedDeletionLeases;
  final Set<String> revivedIds;
  final Set<String> preparedRevivedIds;
  final Map<String, String> preparedRevivalLeases;
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
      _stringMapEquals(other.preparedDeletionLeases, preparedDeletionLeases) &&
      other.revivedIds.length == revivedIds.length &&
      other.revivedIds.containsAll(revivedIds) &&
      other.preparedRevivedIds.length == preparedRevivedIds.length &&
      other.preparedRevivedIds.containsAll(preparedRevivedIds) &&
      _stringMapEquals(other.preparedRevivalLeases, preparedRevivalLeases);

  @override
  int get hashCode => Object.hash(
    uid,
    operationId,
    allowParentOnlyLegacy,
    Object.hashAllUnordered(deletedIds),
    Object.hashAllUnordered(preparedDeletedIds),
    Object.hashAllUnordered(
      preparedDeletionLeases.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
    Object.hashAllUnordered(revivedIds),
    Object.hashAllUnordered(preparedRevivedIds),
    Object.hashAllUnordered(
      preparedRevivalLeases.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}

abstract interface class BookshelfSyncOutboxStore {
  Future<BookshelfSyncPending?> read();
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  });
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
            decoded['version'] != 4 &&
            decoded['version'] != 5) ||
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
    final rawPreparedDeletionLeases = decoded['prepared_deletion_leases'];
    final rawPreparedRevivalLeases = decoded['prepared_revival_leases'];
    final allowParentOnlyLegacy = decoded['allow_parent_only_legacy'] ?? false;
    if (uid.trim().isEmpty ||
        uid.length > 256 ||
        operationId.trim().isEmpty ||
        operationId.length > 256 ||
        rawDeletedIds is! List ||
        rawPreparedDeletedIds is! List ||
        rawRevivedIds is! List ||
        rawPreparedRevivedIds is! List ||
        (decoded['version'] == 5 && rawPreparedDeletionLeases is! Map) ||
        (decoded['version'] == 5 && rawPreparedRevivalLeases is! Map) ||
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
    final preparedDeletionLeases = decoded['version'] == 5
        ? _decodePreparedLeases(
            rawPreparedDeletionLeases as Map,
            preparedDeletedIds,
          )
        : {for (final id in preparedDeletedIds) id: operationId};
    final preparedRevivalLeases = decoded['version'] == 5
        ? _decodePreparedLeases(
            rawPreparedRevivalLeases as Map,
            preparedRevivedIds,
          )
        : {for (final id in preparedRevivedIds) id: operationId};
    return BookshelfSyncPending(
      uid: uid,
      operationId: operationId,
      deletedIds: deletedIds,
      preparedDeletedIds: preparedDeletedIds,
      preparedDeletionLeases: preparedDeletionLeases,
      revivedIds: revivedIds,
      preparedRevivedIds: preparedRevivedIds,
      preparedRevivalLeases: preparedRevivalLeases,
      allowParentOnlyLegacy: allowParentOnlyLegacy,
    );
  }

  @override
  Future<void> write(
    BookshelfSyncPending pending, {
    void Function()? beforeEffect,
  }) async {
    _requireRecordIds(pending.deletedIds);
    _requireRecordIds(pending.preparedDeletedIds);
    _requireRecordIds(pending.revivedIds);
    _requireRecordIds(pending.preparedRevivedIds);
    final preparedDeletionLeases = {
      for (final id in pending.preparedDeletedIds)
        id: pending.preparedDeletionLeases[id]!,
    };
    final preparedRevivalLeases = {
      for (final id in pending.preparedRevivedIds)
        id: pending.preparedRevivalLeases[id]!,
    };
    final preferences = await SharedPreferences.getInstance();
    beforeEffect?.call();
    final written = await preferences.setString(
      key,
      jsonEncode({
        'version': 5,
        'uid': pending.uid,
        'operation_id': pending.operationId,
        'deleted_ids': pending.deletedIds.toList()..sort(),
        'prepared_deleted_ids': pending.preparedDeletedIds.toList()..sort(),
        'prepared_deletion_leases': Map.fromEntries(
          preparedDeletionLeases.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)),
        ),
        'revived_ids': pending.revivedIds.toList()..sort(),
        'prepared_revived_ids': pending.preparedRevivedIds.toList()..sort(),
        'prepared_revival_leases': Map.fromEntries(
          preparedRevivalLeases.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)),
        ),
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
    void Function()? beforeWrite,
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
      final nextPreparedDeletionLeases = <String, String>{
        if (sameUid) ...current!.preparedDeletionLeases,
      };
      final nextRevivedIds = <String>{if (sameUid) ...current!.revivedIds};
      final nextPreparedRevivedIds = <String>{
        if (sameUid) ...current!.preparedRevivedIds,
      };
      final nextPreparedRevivalLeases = <String, String>{
        if (sameUid) ...current!.preparedRevivalLeases,
      };
      void replaceIntent(String id, Set<String> target) {
        nextDeletedIds.remove(id);
        nextPreparedDeletedIds.remove(id);
        nextPreparedDeletionLeases.remove(id);
        nextRevivedIds.remove(id);
        nextPreparedRevivedIds.remove(id);
        nextPreparedRevivalLeases.remove(id);
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
        preparedDeletionLeases: nextPreparedDeletionLeases,
        revivedIds: nextRevivedIds,
        preparedRevivedIds: nextPreparedRevivedIds,
        preparedRevivalLeases: nextPreparedRevivalLeases,
        allowParentOnlyLegacy:
            allowParentOnlyLegacy ??
            (sameUid && current!.allowParentOnlyLegacy),
      );
      await store.write(pending, beforeEffect: beforeWrite);
    });
  }

  Future<String> prepareDeletion(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) {
      throw ArgumentError('Bookshelf deletion intent is empty.');
    }
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
          preparedDeletionLeases: {
            if (sameUid)
              for (final entry in current!.preparedDeletionLeases.entries)
                if (!ids.contains(entry.key)) entry.key: entry.value,
            for (final id in ids) id: token,
          },
          revivedIds: {
            if (sameUid)
              ...current!.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            if (sameUid)
              ...current!.preparedRevivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivalLeases: {
            if (sameUid)
              for (final entry in current!.preparedRevivalLeases.entries)
                if (!ids.contains(entry.key)) entry.key: entry.value,
          },
          allowParentOnlyLegacy: sameUid && current!.allowParentOnlyLegacy,
        ),
      );
    });
    return token;
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
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: {...?current?.deletedIds, ...ids},
          preparedDeletedIds: {
            ...?current?.preparedDeletedIds.where((id) => !ids.contains(id)),
          },
          preparedDeletionLeases: {
            for (final entry
                in current?.preparedDeletionLeases.entries ??
                    const <MapEntry<String, String>>[])
              if (!ids.contains(entry.key)) entry.key: entry.value,
          },
          revivedIds: {
            ...?current?.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            ...?current?.preparedRevivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivalLeases: {
            for (final entry
                in current?.preparedRevivalLeases.entries ??
                    const <MapEntry<String, String>>[])
              if (!ids.contains(entry.key)) entry.key: entry.value,
          },
          allowParentOnlyLegacy: current?.allowParentOnlyLegacy ?? false,
        ),
      );
    });
  }

  Future<String> prepareRevival(String uid, Set<String> ids) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    if (ids.isEmpty) {
      throw ArgumentError('Bookshelf revival intent is empty.');
    }
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
          preparedDeletionLeases: {
            if (sameUid)
              for (final entry in current!.preparedDeletionLeases.entries)
                if (!ids.contains(entry.key)) entry.key: entry.value,
          },
          revivedIds: {
            if (sameUid)
              ...current!.revivedIds.where((id) => !ids.contains(id)),
          },
          preparedRevivedIds: {
            if (sameUid) ...current!.preparedRevivedIds,
            ...ids,
          },
          preparedRevivalLeases: {
            if (sameUid)
              for (final entry in current!.preparedRevivalLeases.entries)
                if (!ids.contains(entry.key)) entry.key: entry.value,
            for (final id in ids) id: token,
          },
          allowParentOnlyLegacy: sameUid && current!.allowParentOnlyLegacy,
        ),
      );
    });
    return token;
  }

  Future<void> commitRevival(
    String uid,
    Set<String> ids, {
    required String leaseToken,
  }) async {
    _requireUid(uid);
    _requireRecordIds(ids);
    _requireLeaseToken(leaseToken);
    if (ids.isEmpty) return;
    await _runStoreMutation(() async {
      final current = await store.read();
      if (current != null && current.uid != uid) {
        throw StateError('Bookshelf revival account changed before commit.');
      }
      if (current == null) return;
      final matchedIds = {
        for (final id in ids)
          if (current.preparedRevivalLeases[id] == leaseToken) id,
      };
      if (matchedIds.isEmpty) return;
      final token = _newToken();
      await store.write(
        BookshelfSyncPending(
          uid: uid,
          operationId: token,
          deletedIds: current.deletedIds,
          preparedDeletedIds: current.preparedDeletedIds,
          preparedDeletionLeases: current.preparedDeletionLeases,
          revivedIds: {...current.revivedIds, ...matchedIds},
          preparedRevivedIds: {
            ...current.preparedRevivedIds.where(
              (id) => !matchedIds.contains(id),
            ),
          },
          preparedRevivalLeases: {
            for (final entry in current.preparedRevivalLeases.entries)
              if (!matchedIds.contains(entry.key)) entry.key: entry.value,
          },
          allowParentOnlyLegacy: current.allowParentOnlyLegacy,
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
          preparedDeletionLeases: {
            for (final entry in current.preparedDeletionLeases.entries)
              if (!deletedIds.contains(entry.key)) entry.key: entry.value,
          },
          revivedIds: current.revivedIds,
          preparedRevivedIds: {
            ...current.preparedRevivedIds.where(
              (id) => !revivedIds.contains(id),
            ),
          },
          preparedRevivalLeases: {
            for (final entry in current.preparedRevivalLeases.entries)
              if (!revivedIds.contains(entry.key)) entry.key: entry.value,
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
    final leaseToken = await queue.prepareRevival(uid, ids);
    try {
      await saveLocal();
      await queue.commitRevival(uid, ids, leaseToken: leaseToken);
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

class BookshelfParentOnlyLegacyApprovalWorkflow {
  const BookshelfParentOnlyLegacyApprovalWorkflow(this.queue);

  final BookshelfSyncQueue queue;

  Future<void> run({
    required String uid,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) async {
    if (session.mode != CloudWriteMode.reconciling) {
      throw StateError(
        'Parent-only legacy approval requires a reconciling session.',
      );
    }
    sessions.assertCurrent(session);
    if (session.uid != uid) {
      throw StateError('Validated bookshelf restore UID does not match.');
    }
    await queue.markPending(
      uid,
      allowParentOnlyLegacy: true,
      beforeWrite: () {
        if (session.mode != CloudWriteMode.reconciling) {
          throw StateError(
            'Parent-only legacy approval requires a reconciling session.',
          );
        }
        sessions.assertCurrent(session);
      },
    );
  }
}

Map<String, String> _normalizePreparedLeases(
  String fallbackToken,
  Set<String> preparedIds,
  Map<String, String> leases,
) {
  if (leases.isEmpty) {
    _requireLeaseToken(fallbackToken);
    return {for (final id in preparedIds) id: fallbackToken};
  }
  if (leases.length != preparedIds.length ||
      !preparedIds.containsAll(leases.keys)) {
    throw ArgumentError('Prepared bookshelf leases must match prepared IDs.');
  }
  for (final token in leases.values) {
    _requireLeaseToken(token);
  }
  return Map<String, String>.from(leases);
}

Map<String, String> _decodePreparedLeases(
  Map<dynamic, dynamic> raw,
  Set<String> preparedIds,
) {
  final leases = <String, String>{};
  for (final entry in raw.entries) {
    if (entry.key is! String ||
        entry.value is! String ||
        leases.containsKey(entry.key)) {
      throw const FormatException('Invalid bookshelf sync outbox.');
    }
    _requireLeaseToken(entry.value as String);
    leases[entry.key as String] = entry.value as String;
  }
  if (leases.length != preparedIds.length ||
      !preparedIds.containsAll(leases.keys)) {
    throw const FormatException('Invalid bookshelf sync outbox.');
  }
  return leases;
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

void _requireLeaseToken(String token) {
  if (token.trim().isEmpty || token.length > 256) {
    throw const FormatException('Invalid bookshelf intent lease.');
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
