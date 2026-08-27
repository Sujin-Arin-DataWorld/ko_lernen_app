import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_generation_manifest.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('bookshelf service activates a complete immutable generation', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final repository = _MemoryRepository();

    final result = await BookshelfService.syncGenerationWithSession(
      sessions: sessions,
      uid: 'uid-a',
      generationId: 'generation-a',
      entries: const {
        'book-a': {'note': 'portable'},
      },
      repository: repository,
    );

    expect(result, CloudWriteResult.completed);
    expect(repository.active?.generationId, 'generation-a');
    expect(
      repository.generations['generation-a']?['book-a']?['deleted'],
      isFalse,
    );
  });

  test(
    'first-link upload derives the cloud owner from its exact session',
    () async {
      await Storage.setBookshelfRawJsonStrict(
        '{"book-a":{"note":"local","words":[],"grammar":[],"sentences":[],"capturedAt":"2026-07-30T00:00:00.000Z"}}',
      );
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      final repository = _MemoryRepository();

      final result =
          await BookshelfService.uploadLocalGenerationForFirstDurableLink(
            session: session,
            sessions: sessions,
            generationId: 'generation-first',
            operationId: 'first-link:receipt-token',
            repository: repository,
          );

      expect(result, CloudWriteResult.completed);
      expect(repository.active?.generationId, 'generation-first');
      expect(repository.active?.operationId, 'first-link:receipt-token');
      expect(repository.seenUids, {'source'});
    },
  );

  test('first-link upload rejects a newer session for the same UID', () async {
    final sessions = CloudWriteSessionController();
    final session = sessions.acquire('source');
    sessions.acquire('source');
    final repository = _MemoryRepository();

    final result =
        await BookshelfService.uploadLocalGenerationForFirstDurableLink(
          session: session,
          sessions: sessions,
          generationId: 'generation-first',
          repository: repository,
        );

    expect(result, CloudWriteResult.stale);
    expect(repository.seenUids, isEmpty);
  });

  test(
    'bookshelf service restores the active generation into local data',
    () async {
      final repository = _MemoryRepository()
        ..active = BookshelfGenerationManifest(
          generationId: 'generation-a',
          revision: 1,
          recordIds: const {'book-a'},
        )
        ..generations['generation-a'] = {
          'book-a': BookshelfGenerationRecord.live(
            id: 'book-a',
            revision: 1,
            portable: const {
              'note': 'restored',
              'words': <Object>[],
              'grammar': <Object>[],
              'sentences': <Object>[],
            },
          ).toJson(),
        };

      final restored = await BookshelfService.restoreRemoteWithRepository(
        uid: 'uid-a',
        repository: repository,
      );

      expect(restored, isTrue);
      expect(BookshelfService.getById('book-a')?.note, 'restored');
    },
  );

  test(
    'typed bookshelf restore reports an active generation as restorable',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.current!;
      final repository = _MemoryRepository()
        ..active = BookshelfGenerationManifest(
          generationId: 'generation-a',
          revision: 1,
          recordIds: const {'book-a'},
        )
        ..generations['generation-a'] = {
          'book-a': BookshelfGenerationRecord.live(
            id: 'book-a',
            revision: 1,
            portable: const {
              'note': 'restored',
              'words': <Object>[],
              'grammar': <Object>[],
              'sentences': <Object>[],
            },
          ).toJson(),
        };

      final result = await BookshelfService.restoreRemoteForSessionWithResult(
        uid: 'uid-a',
        expectedSession: session,
        sessions: sessions,
        repository: repository,
      );

      expect(result.status, CloudWriteResult.completed);
      expect(result.hasRemoteData, isTrue);
      expect(BookshelfService.getById('book-a')?.note, 'restored');
    },
  );

  test(
    'typed bookshelf restore fails closed when the active generation is malformed',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.current!;
      final repository = _MemoryRepository()
        ..active = BookshelfGenerationManifest(
          generationId: 'generation-a',
          revision: 1,
          recordIds: const {'missing-record'},
        );

      final result = await BookshelfService.restoreRemoteForSessionWithResult(
        uid: 'uid-a',
        expectedSession: session,
        sessions: sessions,
        repository: repository,
      );

      expect(result.status, CloudWriteResult.blocked);
      expect(result.hasRemoteData, isFalse);
      expect(BookshelfService.getById('missing-record'), isNull);
    },
  );

  test(
    'typed bookshelf restore reports stale when a malformed read finishes after an account switch',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final session = sessions.current!;
      final manifest = Completer<BookshelfGenerationManifest?>();
      final repository = _DelayedManifestRepository(manifest.future);

      final result = BookshelfService.restoreRemoteForSessionWithResult(
        uid: 'uid-a',
        expectedSession: session,
        sessions: sessions,
        repository: repository,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      manifest.completeError(const FormatException('malformed remote record'));

      expect((await result).status, CloudWriteResult.stale);
    },
  );

  test('active tombstone removes a stale local bookshelf entry', () async {
    await Storage.setBookshelfRawJsonStrict(
      '{"book-deleted":{"note":"stale local","words":[],"grammar":[],"sentences":[]}}',
    );
    final repository = _MemoryRepository()
      ..active = BookshelfGenerationManifest(
        generationId: 'generation-a',
        revision: 2,
        recordIds: const {'book-deleted'},
      )
      ..generations['generation-a'] = {
        'book-deleted': BookshelfGenerationRecord.tombstone(
          id: 'book-deleted',
          revision: 2,
        ).toJson(),
      };

    await BookshelfService.restoreRemoteWithRepository(
      uid: 'uid-a',
      repository: repository,
    );

    expect(BookshelfService.getById('book-deleted'), isNull);
  });

  test(
    'manual bookshelf restore cannot persist after the session changes',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final expectedSession = sessions.current!;
      final manifest = Completer<BookshelfGenerationManifest?>();
      final repository = _DelayedManifestRepository(manifest.future)
        ..generations['generation-a'] = {
          'book-a': BookshelfGenerationRecord.live(
            id: 'book-a',
            revision: 1,
            portable: const {
              'note': 'must-not-cross-account',
              'words': <Object>[],
              'grammar': <Object>[],
              'sentences': <Object>[],
            },
          ).toJson(),
        };

      final result = BookshelfService.restoreRemoteForSession(
        uid: 'uid-a',
        expectedSession: expectedSession,
        sessions: sessions,
        repository: repository,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      manifest.complete(
        BookshelfGenerationManifest(
          generationId: 'generation-a',
          revision: 1,
          recordIds: {'book-a'},
        ),
      );

      expect(await result, CloudWriteResult.stale);
      expect(BookshelfService.getById('book-a'), isNull);
    },
  );

  test(
    'manual bookshelf restore cannot persist when its remote read finishes after local reset',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final expectedSession = sessions.current!;
      final manifest = Completer<BookshelfGenerationManifest?>();
      final repository = _DelayedManifestRepository(manifest.future)
        ..generations['generation-a'] = {
          'book-a': BookshelfGenerationRecord.live(
            id: 'book-a',
            revision: 1,
            portable: const {
              'note': 'must-not-repopulate-reset-data',
              'words': <Object>[],
              'grammar': <Object>[],
              'sentences': <Object>[],
            },
          ).toJson(),
        };

      final result = BookshelfService.restoreRemoteForSessionWithResult(
        uid: 'uid-a',
        expectedSession: expectedSession,
        sessions: sessions,
        repository: repository,
      );
      await Future<void>.delayed(Duration.zero);
      await Storage.resetAll();
      manifest.complete(
        BookshelfGenerationManifest(
          generationId: 'generation-a',
          revision: 1,
          recordIds: {'book-a'},
        ),
      );

      expect((await result).status, CloudWriteResult.stale);
      expect(BookshelfService.getById('book-a'), isNull);
    },
  );
}

class _MemoryRepository implements BookshelfGenerationRepository {
  BookshelfGenerationManifest? active;
  final generations = <String, Map<String, Map<String, dynamic>>>{};
  final seenUids = <String>{};

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) async {
    seenUids.add(uid);
    if ((active?.revision ?? 0) != expectedRevision) return false;
    active = manifest;
    return true;
  }

  @override
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid) async {
    seenUids.add(uid);
    return active;
  }

  @override
  Future<Map<String, dynamic>?> readGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
  }) async {
    seenUids.add(uid);
    return generations[generationId]?[recordId];
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyEntries(
    String uid,
  ) async {
    seenUids.add(uid);
    return {};
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyParent(String uid) async {
    seenUids.add(uid);
    return {};
  }

  @override
  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    seenUids.add(uid);
    generations.putIfAbsent(generationId, () => {})[recordId] = data;
  }
}

class _DelayedManifestRepository extends _MemoryRepository {
  _DelayedManifestRepository(this.manifest);

  final Future<BookshelfGenerationManifest?> manifest;

  @override
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid) {
    return manifest;
  }
}
