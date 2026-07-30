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
    'reader treats an existing per-book legacy set as authoritative',
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

  test('durable explicit revival overrides an active tombstone', () async {
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

    await BookshelfGenerationSync.stageAndActivate(
      repository: repository,
      uid: 'uid-a',
      generationId: 'generation-new',
      entries: const {
        'book-deleted': {'note': 'intentional new save'},
      },
      revivedIds: const {'book-deleted'},
      beforeWrite: () {},
    );

    final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
    expect(snapshot.entries, {
      'book-deleted': {'note': 'intentional new save'},
    });
    expect(snapshot.tombstoneIds, isEmpty);
  });

  test(
    'first generation merges a stale local edit with every legacy survivor',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..legacyEntries = {
          'book-a': {'note': 'legacy A'},
          'book-b': {'note': 'legacy B'},
        };

      await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-first',
        entries: const {
          'book-a': {'note': 'edited locally'},
        },
        beforeWrite: () {},
      );

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries, {
        'book-a': {'note': 'edited locally'},
        'book-b': {'note': 'legacy B'},
      });
    },
  );

  test('partial local snapshot preserves active remote live records', () async {
    final repository = _MemoryBookshelfRepository()
      ..active = BookshelfGenerationManifest(
        generationId: 'generation-active',
        revision: 1,
        recordIds: const {'book-a', 'book-b'},
      )
      ..generations['generation-active'] = {
        'book-a': BookshelfGenerationRecord.live(
          id: 'book-a',
          revision: 1,
          portable: const {'note': 'remote A'},
        ).toJson(),
        'book-b': BookshelfGenerationRecord.live(
          id: 'book-b',
          revision: 1,
          portable: const {'note': 'remote B'},
        ).toJson(),
      };

    await BookshelfGenerationSync.stageAndActivate(
      repository: repository,
      uid: 'uid-a',
      generationId: 'generation-next',
      entries: const {
        'book-a': {'note': 'edited locally'},
      },
      beforeWrite: () {},
    );

    final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
    expect(snapshot.entries, {
      'book-a': {'note': 'edited locally'},
      'book-b': {'note': 'remote B'},
    });
    expect(snapshot.tombstoneIds, isEmpty);
  });

  test(
    'explicit durable deletion tombstones an active remote live record',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..active = BookshelfGenerationManifest(
          generationId: 'generation-active',
          revision: 1,
          recordIds: const {'book-a', 'book-b'},
        )
        ..generations['generation-active'] = {
          'book-a': BookshelfGenerationRecord.live(
            id: 'book-a',
            revision: 1,
            portable: const {'note': 'remote A'},
          ).toJson(),
          'book-b': BookshelfGenerationRecord.live(
            id: 'book-b',
            revision: 1,
            portable: const {'note': 'remote B'},
          ).toJson(),
        };

      await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-next',
        entries: const {
          'book-a': {'note': 'local A'},
        },
        deletedIds: const {'book-b'},
        beforeWrite: () {},
      );

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries, {
        'book-a': {'note': 'local A'},
      });
      expect(snapshot.tombstoneIds, {'book-b'});
    },
  );

  test(
    'legacy per-document survivor set suppresses deleted parent-only records',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..legacyParent = {
          'book-deleted': {'note': 'stale parent'},
          'book-live': {'note': 'old parent'},
        }
        ..legacyEntries = {
          'book-live': {'note': 'authoritative survivor'},
        };

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');

      expect(snapshot.entries, {
        'book-live': {'note': 'authoritative survivor'},
      });
      expect(snapshot.entries, isNot(contains('book-deleted')));
    },
  );

  test(
    'first generation persists a local legacy deletion as a tombstone',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..legacyEntries = {
          'book-a': {'note': 'legacy A'},
          'book-b': {'note': 'legacy B'},
        };

      await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-first',
        operationId: 'operation-first',
        entries: const {
          'book-b': {'note': 'legacy B'},
        },
        deletedIds: const {'book-a'},
        beforeWrite: () {},
      );

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries.keys, ['book-b']);
      expect(snapshot.tombstoneIds, {'book-a'});
    },
  );

  test('empty per-document legacy with stale parent fails closed', () async {
    final repository = _MemoryBookshelfRepository()
      ..legacyParent = {
        'book-a': {'note': 'stale parent A'},
        'book-b': {'note': 'stale parent B'},
      };

    await expectLater(
      BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-first',
        operationId: 'operation-first',
        entries: const {},
        deletedIds: const {'book-a', 'book-b'},
        beforeWrite: () {},
      ),
      throwsFormatException,
    );

    expect(repository.active, isNull);
    expect(repository.generations, isEmpty);
  });

  test(
    'explicit parent-only legacy policy preserves a known safe source',
    () async {
      final repository = _MemoryBookshelfRepository()
        ..legacyParent = {
          'book-a': {'note': 'known parent-only'},
        };

      await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-first',
        operationId: 'operation-first',
        entries: const {},
        allowParentOnlyLegacy: true,
        beforeWrite: () {},
      );

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries, {
        'book-a': {'note': 'known parent-only'},
      });
    },
  );

  test('manifest idempotency compares the complete record id set', () {
    final first = BookshelfGenerationManifest(
      generationId: 'generation-a',
      revision: 4,
      recordIds: const {'book-a'},
    );
    final different = BookshelfGenerationManifest(
      generationId: 'generation-a',
      revision: 4,
      recordIds: const {'book-a', 'book-b'},
    );

    expect(first.hasSameContent(different), isFalse);
    expect(first.hasSameContent(first), isTrue);
  });

  test('portable records reject oversized strings before hashing', () {
    expect(
      () => BookshelfGenerationRecord.live(
        id: 'book-a',
        revision: 1,
        portable: {'note': 'x' * (128 * 1024 + 1)},
      ),
      throwsFormatException,
    );
  });

  test('portable records reject oversized collections before hashing', () {
    expect(
      () => BookshelfGenerationRecord.live(
        id: 'book-a',
        revision: 1,
        portable: {'words': List<Object?>.filled(513, null)},
      ),
      throwsFormatException,
    );
  });

  test('portable records reject excessive nesting before hashing', () {
    Object? nested = 'leaf';
    for (var depth = 0; depth < 18; depth += 1) {
      nested = {'child': nested};
    }

    expect(
      () => BookshelfGenerationRecord.live(
        id: 'book-a',
        revision: 1,
        portable: {'root': nested},
      ),
      throwsFormatException,
    );
  });

  test('portable records reject non-finite and unsupported values', () {
    for (final value in <Object>[double.nan, double.infinity, DateTime(2026)]) {
      expect(
        () => BookshelfGenerationRecord.live(
          id: 'book-a',
          revision: 1,
          portable: {'value': value},
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'aggregate node budget rejects large graphs before canonicalization',
    () {
      final tooManyNodes = {
        'groups': List.generate(512, (_) => List<Object?>.filled(16, null)),
      };

      expect(
        () => BookshelfGenerationRecord.live(
          id: 'book-a',
          revision: 1,
          portable: tooManyNodes,
        ),
        throwsFormatException,
      );
      expect(
        BookshelfGenerationRecord.live(
          id: 'book-b',
          revision: 1,
          portable: const {
            'title': 'normal',
            'words': [
              {'korean': '한글', 'translation': 'Korean'},
            ],
          },
        ).canonicalHash,
        hasLength(64),
      );
    },
  );

  test('aggregate byte budget rejects multiple individually valid strings', () {
    expect(
      () => BookshelfGenerationRecord.live(
        id: 'book-a',
        revision: 1,
        portable: {'first': 'x' * (128 * 1024), 'second': 'y' * (128 * 1024)},
      ),
      throwsFormatException,
    );
  });

  test(
    'portable records and complete generations enforce byte bounds',
    () async {
      expect(
        () => BookshelfGenerationRecord.live(
          id: 'book-a',
          revision: 1,
          portable: {'text': 'x' * (256 * 1024)},
        ),
        throwsFormatException,
      );

      final repository = _MemoryBookshelfRepository();
      final entries = {
        for (var index = 0; index < 20; index += 1)
          'book-$index': {'text': 'x' * (220 * 1024)},
      };
      await expectLater(
        BookshelfGenerationSync.stageAndActivate(
          repository: repository,
          uid: 'uid-a',
          generationId: 'generation-large',
          entries: entries,
          beforeWrite: () {},
        ),
        throwsFormatException,
      );
      expect(repository.active, isNull);
      expect(repository.generations, isEmpty);
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
