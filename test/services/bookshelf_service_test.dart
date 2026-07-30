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
}

class _MemoryRepository implements BookshelfGenerationRepository {
  BookshelfGenerationManifest? active;
  final generations = <String, Map<String, Map<String, dynamic>>>{};

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) async {
    if ((active?.revision ?? 0) != expectedRevision) return false;
    active = manifest;
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
    generations.putIfAbsent(generationId, () => {})[recordId] = data;
  }
}
