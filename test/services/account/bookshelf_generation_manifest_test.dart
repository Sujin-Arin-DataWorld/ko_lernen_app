import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/bookshelf_generation_manifest.dart';

void main() {
  test('reader restores only records named by the active manifest', () async {
    final repository = _MemoryBookshelfRepository()
      ..active = BookshelfGenerationManifest(
        generationId: 'generation-old',
        revision: 4,
        recordIds: const {'book-old'},
      )
      ..generations['generation-old'] = {
        'book-old': BookshelfGenerationRecord.live(
          id: 'book-old',
          revision: 4,
          portable: const {'note': 'visible'},
        ).toJson(),
      }
      ..generations['generation-incomplete'] = {
        'book-new': BookshelfGenerationRecord.live(
          id: 'book-new',
          revision: 5,
          portable: const {'note': 'must stay hidden'},
        ).toJson(),
      };

    final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');

    expect(snapshot.source, BookshelfSnapshotSource.activeGeneration);
    expect(snapshot.entries, {
      'book-old': {'note': 'visible'},
    });
  });

  test('entry failure leaves the prior manifest visible', () async {
    final repository = _MemoryBookshelfRepository()
      ..active = BookshelfGenerationManifest(
        generationId: 'generation-old',
        revision: 2,
        recordIds: const {'book-old'},
      )
      ..generations['generation-old'] = {
        'book-old': BookshelfGenerationRecord.live(
          id: 'book-old',
          revision: 2,
          portable: const {'note': 'visible'},
        ).toJson(),
      }
      ..failRecordId = 'book-b';

    await expectLater(
      BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-new',
        entries: const {
          'book-a': {'note': 'first staged'},
          'book-b': {'note': 'write fails'},
        },
        beforeWrite: () {},
      ),
      throwsStateError,
    );

    expect(repository.active?.generationId, 'generation-old');
    final visible = await BookshelfGenerationSync.read(repository, 'uid-a');
    expect(visible.entries.keys, ['book-old']);
  });

  test('interrupted manifest flip preserves the prior generation', () async {
    final repository = _MemoryBookshelfRepository()
      ..active = BookshelfGenerationManifest(
        generationId: 'generation-old',
        revision: 7,
        recordIds: const {'book-old'},
      )
      ..generations['generation-old'] = {
        'book-old': BookshelfGenerationRecord.live(
          id: 'book-old',
          revision: 7,
          portable: const {'note': 'visible'},
        ).toJson(),
      }
      ..failManifestFlip = true;

    await expectLater(
      BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-new',
        entries: const {
          'book-new': {'note': 'staged but not active'},
        },
        beforeWrite: () {},
      ),
      throwsStateError,
    );

    expect(repository.active?.generationId, 'generation-old');
    final visible = await BookshelfGenerationSync.read(repository, 'uid-a');
    expect(visible.entries, {
      'book-old': {'note': 'visible'},
    });
  });

  test(
    'reader uses legacy parent and per-book data before first manifest',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..legacyParent = {
          'parent-only': {'note': 'parent'},
          'shared': {'note': 'stale parent'},
        }
        ..legacyEntries = {
          'shared': {'note': 'newer per-book'},
          'entry-only': {'note': 'entry'},
        };

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');

      expect(snapshot.source, BookshelfSnapshotSource.legacy);
      expect(snapshot.entries, {
        'parent-only': {'note': 'parent'},
        'shared': {'note': 'newer per-book'},
        'entry-only': {'note': 'entry'},
      });
    },
  );

  test(
    'oversized legacy input blocks migration before any generation write',
    () {
      final repository = _MemoryBookshelfRepository()
        ..legacyParent = {
          for (var index = 0; index < 401; index += 1)
            'book-$index': {'note': 'legacy'},
        };

      expect(
        BookshelfGenerationSync.read(repository, 'uid-a'),
        throwsFormatException,
      );
    },
  );

  test(
    'an active tombstone prevents a stale device from resurrecting a book',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..active = BookshelfGenerationManifest(
          generationId: 'generation-old',
          revision: 3,
          recordIds: const {'book-deleted'},
        )
        ..generations['generation-old'] = {
          'book-deleted': BookshelfGenerationRecord.tombstone(
            id: 'book-deleted',
            revision: 3,
          ).toJson(),
        };

      final result = await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-new',
        entries: const {
          'book-deleted': {'note': 'stale local copy'},
        },
        beforeWrite: () {},
      );

      expect(result.status, BookshelfGenerationWriteStatus.activated);
      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries, isEmpty);
      expect(
        repository.generations['generation-new']?['book-deleted']?['deleted'],
        isTrue,
      );
    },
  );
}

class _MemoryBookshelfRepository implements BookshelfGenerationRepository {
  BookshelfGenerationManifest? active;
  final generations = <String, Map<String, Map<String, dynamic>>>{};
  Map<String, Map<String, dynamic>> legacyParent = {};
  Map<String, Map<String, dynamic>> legacyEntries = {};
  String? failRecordId;
  bool failManifestFlip = false;

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) async {
    if (failManifestFlip) {
      throw StateError('manifest flip interrupted');
    }
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
  ) async => legacyEntries;

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyParent(
    String uid,
  ) async => legacyParent;

  @override
  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (recordId == failRecordId) {
      throw StateError('record write interrupted');
    }
    generations.putIfAbsent(generationId, () => {})[recordId] = data;
  }
}
