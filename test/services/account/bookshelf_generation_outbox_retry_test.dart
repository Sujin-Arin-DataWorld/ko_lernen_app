import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_generation_manifest.dart';
import 'package:ko_lernen_app/services/account/bookshelf_sync_outbox.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  test(
    'manifest CAS loss retries under a fresh immutable generation',
    () async {
      final repository = _RetryRepository()..casConflictsRemaining = 1;
      final store = _OutboxStore();
      var operations = 0;
      var generations = 0;
      final queue = BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++operations}',
        attempt: (pending) => _syncAttempt(
          pending,
          repository,
          generationId: 'generation-${++generations}',
        ),
      );

      await queue.enqueue('uid-a');

      expect(await queue.drain(), CloudWriteResult.completed);
      expect(await store.read(), isNull);
      expect(repository.active?.generationId, 'generation-2');
      expect(repository.generations.keys, {'generation-1', 'generation-2'});
      expect(repository.generations['generation-1'], isNotEmpty);
    },
  );

  test(
    'ambiguous activation is detected exactly after queue restart',
    () async {
      final repository = _RetryRepository()..throwAfterFirstActivation = true;
      final store = _OutboxStore();
      var operations = 0;
      var generations = 0;
      BookshelfSyncQueue queue() => BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-${++operations}',
        attempt: (pending) => _syncAttempt(
          pending,
          repository,
          generationId: 'generation-${++generations}',
        ),
      );

      final firstProcess = queue();
      await firstProcess.enqueue('uid-a');
      expect(await firstProcess.drain(), CloudWriteResult.blocked);
      expect(await store.read(), isNotNull);
      expect(repository.active?.generationId, 'generation-1');

      final restarted = queue();
      expect(await restarted.drain(), CloudWriteResult.completed);
      expect(await store.read(), isNull);
      expect(repository.active?.generationId, 'generation-1');
      expect(repository.generations.keys, {'generation-1'});
    },
  );

  test(
    'operation ID alone cannot clear a marker with mismatched content',
    () async {
      final repository = _RetryRepository()..throwAfterFirstActivation = true;
      final store = _OutboxStore();
      var generations = 0;
      BookshelfSyncQueue queue() => BookshelfSyncQueue(
        store: store,
        tokenFactory: () => 'operation-1',
        attempt: (pending) => _syncAttempt(
          pending,
          repository,
          generationId: 'generation-${++generations}',
        ),
      );

      final firstProcess = queue();
      await firstProcess.enqueue('uid-a');
      expect(await firstProcess.drain(), CloudWriteResult.blocked);
      final activated = repository.active!;
      repository.active = BookshelfGenerationManifest(
        generationId: activated.generationId,
        revision: activated.revision,
        recordIds: activated.recordIds,
        operationId: activated.operationId,
        contentHash: 'f' * 64,
      );

      expect(await queue().drain(), CloudWriteResult.blocked);
      expect(await store.read(), isNotNull);
      expect(repository.generations.keys, {'generation-1'});
    },
  );
}

Future<CloudWriteResult> _syncAttempt(
  BookshelfSyncPending pending,
  _RetryRepository repository, {
  required String generationId,
}) async {
  final result = await BookshelfGenerationSync.stageAndActivate(
    repository: repository,
    uid: pending.uid,
    generationId: generationId,
    operationId: pending.operationId,
    entries: const {
      'book-a': {'note': 'latest'},
    },
    deletedIds: pending.deletedIds,
    beforeWrite: () {},
  );
  return result.status == BookshelfGenerationWriteStatus.activated
      ? CloudWriteResult.completed
      : CloudWriteResult.blocked;
}

class _OutboxStore implements BookshelfSyncOutboxStore {
  BookshelfSyncPending? value;

  @override
  Future<bool> clearIfMatches(BookshelfSyncPending pending) async {
    if (value != pending) return false;
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

class _RetryRepository implements BookshelfGenerationRepository {
  BookshelfGenerationManifest? active;
  final generations = <String, Map<String, Map<String, dynamic>>>{};
  int casConflictsRemaining = 0;
  bool throwAfterFirstActivation = false;

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) async {
    if (casConflictsRemaining > 0) {
      casConflictsRemaining -= 1;
      active = BookshelfGenerationManifest(
        generationId: 'competing-generation',
        revision: expectedRevision + 1,
        recordIds: const {},
      );
      return false;
    }
    if ((active?.revision ?? 0) != expectedRevision) return false;
    active = manifest;
    if (throwAfterFirstActivation) {
      throwAfterFirstActivation = false;
      throw StateError('activation response lost');
    }
    return true;
  }

  @override
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid) async =>
      active;

  @override
  Future<Map<String, dynamic>?> readGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
  }) async => generations[generationId]?[recordId];

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyEntries(
    String uid,
  ) async => {};

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyParent(
    String uid,
  ) async => {};

  @override
  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final records = generations.putIfAbsent(generationId, () => {});
    final existing = records[recordId];
    if (existing != null && existing.toString() != data.toString()) {
      throw StateError('immutable generation collision');
    }
    records[recordId] = data;
  }
}
