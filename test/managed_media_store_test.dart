import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/word_image_service.dart';

void main() {
  late Directory sandbox;
  late Directory documents;
  late Directory temporary;
  late ManagedMediaStore store;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('managed_media_test_');
    documents = Directory('${sandbox.path}${Platform.pathSeparator}documents')
      ..createSync();
    temporary = Directory('${sandbox.path}${Platform.pathSeparator}cache')
      ..createSync();
    store = ManagedMediaStore(
      documentsDirectory: documents,
      temporaryDirectory: temporary,
      now: () => DateTime.utc(2026, 7, 29, 12),
      nonce: () => 'fixed',
    );
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test(
    'opaque refs reject traversal, absolute, UNC, separators, and kinds',
    () {
      expect(ManagedMediaRef.tryParse('book:page.jpg'), isNotNull);
      expect(ManagedMediaRef.tryParse('../page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse('/tmp/page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse(r'C:\tmp\page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse(r'\\server\share\page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse('book:nested/page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse(r'book:nested\page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse('video:page.jpg'), isNull);
      expect(ManagedMediaRef.tryParse('book:page.exe'), isNull);
    },
  );

  test(
    'stage copies external source and discard removes only pending copy',
    () async {
      final external = File(
        '${sandbox.path}${Platform.pathSeparator}gallery.jpg',
      )..writeAsBytesSync([1, 2, 3]);

      final lease = await store.stage(external, ManagedMediaKind.word);
      expect(await store.pendingFile(lease).readAsBytes(), [1, 2, 3]);

      await store.discard(lease);

      expect(await external.exists(), isTrue);
      expect(await store.pendingFile(lease).exists(), isFalse);
    },
  );

  test(
    'promote rollback deletes new commit while preserving prior commit',
    () async {
      final oldSource = File('${sandbox.path}${Platform.pathSeparator}old.jpg')
        ..writeAsBytesSync([1]);
      final newSource = File('${sandbox.path}${Platform.pathSeparator}new.jpg')
        ..writeAsBytesSync([2]);
      final oldLease = await store.stage(oldSource, ManagedMediaKind.word);
      final oldPromotion = await store.promote(oldLease);
      await store.finalize(oldPromotion);
      final newLease = await store.stage(newSource, ManagedMediaKind.word);
      final newPromotion = await store.promote(newLease);

      await store.rollback(newPromotion);

      expect(await store.resolve(oldPromotion.reference), isNotNull);
      expect(await store.resolve(newPromotion.reference), isNull);
    },
  );

  test(
    'symlink escape cannot be resolved or deleted where links are supported',
    () async {
      final sentinel = File(
        '${sandbox.path}${Platform.pathSeparator}sentinel.jpg',
      )..writeAsBytesSync([9, 9]);
      final ref = ManagedMediaRef.parse('word:escape.jpg');
      final link = Link(store.pathForTesting(ref));
      await link.parent.create(recursive: true);
      try {
        await link.create(sentinel.path);
      } on FileSystemException {
        return;
      }

      expect(await store.resolve(ref), isNull);
      await store.deleteCommitted(ref);
      expect(await sentinel.exists(), isTrue);
    },
  );

  test(
    'pending TTL and crash-orphan reconciliation are reference aware',
    () async {
      final pendingSource = File(
        '${sandbox.path}${Platform.pathSeparator}pending.jpg',
      )..writeAsBytesSync([1]);
      final orphanSource = File(
        '${sandbox.path}${Platform.pathSeparator}orphan.jpg',
      )..writeAsBytesSync([2]);
      final pending = await store.stage(pendingSource, ManagedMediaKind.book);
      final orphanLease = await store.stage(
        orphanSource,
        ManagedMediaKind.word,
      );
      final orphan = await store.promote(orphanLease);
      await store.finalize(orphan);
      await store
          .pendingFile(pending)
          .setLastModified(DateTime.utc(2026, 7, 20));

      await store.reconcile(
        snapshot: const ManagedMediaReferenceSnapshot.valid({}),
        pendingTtl: const Duration(days: 2),
      );

      expect(await store.pendingFile(pending).exists(), isFalse);
      expect(await store.resolve(orphan.reference), isNull);
    },
  );

  test('malformed reference snapshot disables committed-file GC', () async {
    final source = File('${sandbox.path}${Platform.pathSeparator}kept.jpg')
      ..writeAsBytesSync([1]);
    final lease = await store.stage(source, ManagedMediaKind.word);
    final promotion = await store.promote(lease);
    await store.finalize(promotion);

    final snapshot = ManagedMediaReferenceSnapshot.fromJson(
      bookshelfJson: '{not-json',
      customPacksJson: '{}',
    );
    await store.reconcile(snapshot: snapshot);

    expect(snapshot.isComplete, isFalse);
    expect(await store.resolve(promotion.reference), isNotNull);
  });

  test(
    'shared refs across words, packs, and bookshelf delete only when last',
    () async {
      final source = File('${sandbox.path}${Platform.pathSeparator}shared.jpg')
        ..writeAsBytesSync([7]);
      final lease = await store.stage(source, ManagedMediaKind.word);
      final promotion = await store.promote(lease);
      await store.finalize(promotion);
      final encoded = promotion.reference.encoded;
      String bookshelf(Object? image) => jsonEncode({
        'page': {
          'localThumbnailPath': null,
          'words': [
            {'korean': '책', 'imagePath': image},
          ],
        },
      });
      String packs(List<Object?> refs) => jsonEncode({
        'a': {
          'words': [
            {'korean': '가', 'imagePath': refs[0]},
            {'korean': '나', 'imagePath': refs[1]},
          ],
        },
        'b': {
          'words': [
            {'korean': '다', 'imagePath': refs[2]},
          ],
        },
      });

      await store.deleteIfUnreferenced(
        promotion.reference,
        ManagedMediaReferenceSnapshot.fromJson(
          bookshelfJson: bookshelf(encoded),
          customPacksJson: packs([encoded, encoded, encoded]),
        ),
      );
      expect(await store.resolve(promotion.reference), isNotNull);

      await store.deleteIfUnreferenced(
        promotion.reference,
        ManagedMediaReferenceSnapshot.fromJson(
          bookshelfJson: bookshelf(null),
          customPacksJson: packs(const [null, null, null]),
        ),
      );
      expect(await store.resolve(promotion.reference), isNull);
    },
  );

  test('wrong-kind references make the GC snapshot incomplete', () {
    final snapshot = ManagedMediaReferenceSnapshot.fromJson(
      bookshelfJson: jsonEncode({
        'page': {
          'localThumbnailPath': 'word:wrong.jpg',
          'words': [
            {'imagePath': 'book:wrong.jpg'},
          ],
        },
      }),
      customPacksJson: '{}',
    );

    expect(snapshot.isComplete, isFalse);
  });

  test(
    'managed root symlink alias is rejected by writes and strict cleanup',
    () async {
      final aliased = Directory(
        '${documents.path}${Platform.pathSeparator}unrelated',
      )..createSync();
      final sentinel = File(
        '${aliased.path}${Platform.pathSeparator}sentinel.txt',
      )..writeAsStringSync('keep');
      try {
        await Link(store.root.path).create(aliased.path);
      } on FileSystemException {
        return;
      }
      final source = File('${sandbox.path}${Platform.pathSeparator}new.jpg')
        ..writeAsBytesSync([1]);

      await expectLater(
        store.stage(source, ManagedMediaKind.word),
        throwsStateError,
      );
      await expectLater(store.deleteAllStrict(), throwsStateError);
      expect(await sentinel.readAsString(), 'keep');
    },
  );

  test('trusted migration accepts the current legacy documents path', () async {
    final legacy = Directory(
      '${documents.path}${Platform.pathSeparator}wordbook_images',
    )..createSync();
    final trusted = File('${legacy.path}${Platform.pathSeparator}current.jpg')
      ..writeAsBytesSync([4]);

    final migrated = await store.migrateTrustedLegacy(
      trusted.path,
      ManagedMediaKind.word,
    );

    expect(migrated, isNotNull);
    expect(await store.resolve(migrated!), isNotNull);
    expect(await trusted.exists(), isTrue);
  });

  test('strict cleanup aggregates managed and both legacy aliases', () async {
    final targets = <Directory>[];
    final links = <Link>[];
    for (final name in const [
      'hangul_sori_media',
      'wordbook_images',
      'book_images',
    ]) {
      final target = Directory(
        '${documents.path}${Platform.pathSeparator}unrelated_$name',
      )..createSync();
      targets.add(target);
      links.add(Link('${documents.path}${Platform.pathSeparator}$name'));
    }
    try {
      for (var index = 0; index < links.length; index++) {
        await links[index].create(targets[index].path);
        File(
          '${targets[index].path}${Platform.pathSeparator}sentinel.txt',
        ).writeAsStringSync('keep');
      }
    } on FileSystemException {
      return;
    }

    try {
      await WordImageService.deleteAllStrict(
        documentsDirectory: () async => documents,
      );
      fail('Strict cleanup should aggregate all unsafe aliases.');
    } on ManagedMediaCleanupException catch (error) {
      expect(error.causes, hasLength(3));
    }
    for (final target in targets) {
      expect(
        await File(
          '${target.path}${Platform.pathSeparator}sentinel.txt',
        ).readAsString(),
        'keep',
      );
    }
  });

  test(
    'trusted legacy migration ignores arbitrary and stale absolute paths',
    () async {
      final legacy = Directory(
        '${documents.path}${Platform.pathSeparator}wordbook_images',
      )..createSync();
      final trusted = File('${legacy.path}${Platform.pathSeparator}trusted.jpg')
        ..writeAsBytesSync([5]);
      final outside = File(
        '${sandbox.path}${Platform.pathSeparator}outside.jpg',
      )..writeAsBytesSync([6]);

      final migrated = await store.migrateTrustedLegacy(
        r'/private/var/mobile/Containers/Data/Application/OLD/Documents/'
        'wordbook_images/trusted.jpg',
        ManagedMediaKind.word,
      );
      final migratedWithoutPrivate = await store.migrateTrustedLegacy(
        r'/var/mobile/Containers/Data/Application/OLD/Documents/'
        'wordbook_images/trusted.jpg',
        ManagedMediaKind.word,
      );
      final rejected = await store.migrateTrustedLegacy(
        outside.path,
        ManagedMediaKind.word,
      );

      expect(migrated, isNotNull);
      expect(migratedWithoutPrivate, isNotNull);
      expect(await store.resolve(migrated!), isNotNull);
      expect(rejected, isNull);
      expect(await outside.exists(), isTrue);
      expect(await trusted.exists(), isTrue);
    },
  );

  test('trusted migration rejects a legacy symlink alias', () async {
    final aliased = Directory(
      '${documents.path}${Platform.pathSeparator}unrelated_migration',
    )..createSync();
    final sentinel = File('${aliased.path}${Platform.pathSeparator}photo.jpg')
      ..writeAsBytesSync([7]);
    final link = Link(
      '${documents.path}${Platform.pathSeparator}wordbook_images',
    );
    try {
      await link.create(aliased.path);
    } on FileSystemException {
      return;
    }

    final migrated = await store.migrateTrustedLegacy(
      '${link.path}${Platform.pathSeparator}photo.jpg',
      ManagedMediaKind.word,
    );

    expect(migrated, isNull);
    expect(await sentinel.exists(), isTrue);
  });

  test('pending and kind-directory symlink aliases reject writes', () async {
    await store.root.create();
    final pendingTarget = Directory(
      '${documents.path}${Platform.pathSeparator}unrelated_pending',
    )..createSync();
    final pendingLink = Link(
      '${store.root.path}${Platform.pathSeparator}pending',
    );
    try {
      await pendingLink.create(pendingTarget.path);
    } on FileSystemException {
      return;
    }
    final source = File('${sandbox.path}${Platform.pathSeparator}source.jpg')
      ..writeAsBytesSync([1]);
    await expectLater(
      store.stage(source, ManagedMediaKind.book),
      throwsStateError,
    );
    await pendingLink.delete();

    final lease = await store.stage(source, ManagedMediaKind.book);
    final wordDirectory = Directory(
      '${store.root.path}${Platform.pathSeparator}word',
    )..createSync();
    final sentinel = File(
      '${wordDirectory.path}${Platform.pathSeparator}sentinel.txt',
    )..writeAsStringSync('keep');
    final bookLink = Link('${store.root.path}${Platform.pathSeparator}book');
    await bookLink.create(wordDirectory.path);

    await expectLater(store.promote(lease), throwsStateError);
    expect(await sentinel.readAsString(), 'keep');
  });

  test(
    'failed legacy promotion cleans migration-owned pending media',
    () async {
      final legacy = Directory(
        '${documents.path}${Platform.pathSeparator}wordbook_images',
      )..createSync();
      final source = File('${legacy.path}${Platform.pathSeparator}photo.jpg')
        ..writeAsBytesSync([3]);
      final failing = _FailingMigrationStore(
        documentsDirectory: documents,
        temporaryDirectory: temporary,
      );

      await expectLater(
        failing.migrateTrustedLegacy(source.path, ManagedMediaKind.word),
        throwsStateError,
      );

      final pending = Directory(
        '${failing.root.path}${Platform.pathSeparator}pending',
      );
      expect(
        await pending.exists()
            ? await pending.list().toList()
            : const <FileSystemEntity>[],
        isEmpty,
      );
      expect(await failing.listCommitted(ManagedMediaKind.word), isEmpty);
      expect(await source.exists(), isTrue);
    },
  );
}

class _FailingMigrationStore extends ManagedMediaStore {
  _FailingMigrationStore({
    required super.documentsDirectory,
    required super.temporaryDirectory,
  });

  @override
  Future<ManagedMediaPromotion> promote(PendingMediaLease lease) {
    throw StateError('migration promotion failed');
  }
}
