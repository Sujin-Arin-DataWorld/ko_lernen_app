import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_store_native.dart';

import 'hanok_asset_delivery_test.dart'
    show entry, pack, document, original, second, MissingBundle, failure;

class _PreparationStore extends MemoryHanokAssetStore {
  int calls = 0;
  bool failFirst = false;
  Completer<void>? gate;

  @override
  Future<void> reconcile(HanokAssetManifest manifest) {
    calls++;
    if (failFirst && calls == 1) {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    }
    return (gate?.future ?? Future<void>.value()).then(
      (_) => super.reconcile(manifest),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final replacement = Uint8List.fromList([10, 11, 12, 13]);
  final oldCatalog = HanokAssetManifest.parse(
    jsonEncode(
      document([
        pack('house', [entry('old', original), entry('retained', second)]),
      ]),
    ),
  );
  final nextDocument = document([
    pack('house', [
      entry('retained', second),
      entry('replacement', replacement),
    ]),
  ]);
  final nextCatalog = HanokAssetManifest.parse(jsonEncode(nextDocument));
  final capacity = original.length + second.length;
  final bytesByPath = {
    'assets/art/old.png': original,
    'assets/art/retained.png': second,
    'assets/art/replacement.png': replacement,
  };

  for (final injected in [true, false]) {
    test(
      'catalog upgrade reclaims obsolete hashes before new downloads, injected=$injected',
      () async {
        final dir = await Directory.systemTemp.createTemp('hanok_upgrade_');
        addTearDown(() => dir.delete(recursive: true));
        NativeHanokAssetStore store() => NativeHanokAssetStore(
          directory: () async => dir,
          capacity: capacity,
        );
        final first = HanokAssetDelivery(
          manifest: oldCatalog,
          store: store(),
          bundle: MissingBundle(),
          bundledPaths: () async => {},
          connectivity: () async => HanokNetwork.unmetered,
          fetch: (asset) async => bytesByPath[asset.asset]!,
        );
        await first.downloadPack('house');
        expect((await first.statuses()).single.storedBytes, capacity);
        first.dispose();
        final oldFile = File(
          '${dir.path}/${oldCatalog.assets['assets/art/old.png']!.filename}',
        );
        final retainedFile = File(
          '${dir.path}/${nextCatalog.assets['assets/art/retained.png']!.filename}',
        );
        final note = File('${dir.path}/notes.txt');
        await note.writeAsString('user file');
        final nested = Directory('${dir.path}/${'f' * 64}.png');
        await nested.create();
        final nestedFile = File('${nested.path}/keep.txt');
        await nestedFile.writeAsString('nested file');
        final requests = <String>[];
        final next = HanokAssetDelivery(
          manifest: injected ? nextCatalog : null,
          store: store(),
          bundle: MissingBundle({
            'assets/data/hanok_download_manifest.json': Uint8List.fromList(
              utf8.encode(jsonEncode(nextDocument)),
            ),
          }),
          bundledPaths: () async => {},
          connectivity: () async => HanokNetwork.unmetered,
          fetch: (asset) async {
            requests.add(asset.asset);
            return bytesByPath[asset.asset]!;
          },
        );
        addTearDown(next.dispose);
        // Merely opening Downloads reconciles local files, without a transfer.
        expect((await next.statuses()).single.storedBytes, second.length);
        expect(requests, isEmpty);
        expect(await oldFile.exists(), false);
        expect(await retainedFile.readAsBytes(), second);
        expect(await note.readAsString(), 'user file');
        expect(await nestedFile.readAsString(), 'nested file');
        await next.downloadPack('house');
        expect((await next.statuses()).single.isComplete, true);
        expect(requests, ['assets/art/replacement.png']);
        await next.removePack('house');
        expect((await next.statuses()).single.storedBytes, 0);
        expect(await note.readAsString(), 'user file');
      },
    );
  }

  test(
    'direct download after a catalog change frees capacity in memory',
    () async {
      final store = MemoryHanokAssetStore(capacity: capacity);
      final oldAsset = oldCatalog.assets['assets/art/old.png']!;
      final retained = nextCatalog.assets['assets/art/retained.png']!;
      await store.write(oldAsset, original);
      await store.write(retained, second);
      final next = HanokAssetDelivery(
        manifest: nextCatalog,
        store: store,
        bundle: MissingBundle(),
        bundledPaths: () async => {},
        connectivity: () async => HanokNetwork.unmetered,
        fetch: (asset) async => bytesByPath[asset.asset]!,
      );
      addTearDown(next.dispose);
      await next.downloadPack('house');
      expect(await store.read(oldAsset), null);
      expect(await store.read(retained), second);
      expect((await next.statuses()).single.isComplete, true);
    },
  );

  test('simultaneous first operations await one cache preparation', () async {
    final store = _PreparationStore()..gate = Completer<void>();
    final requests = <String>[];
    final delivery = HanokAssetDelivery(
      manifest: nextCatalog,
      store: store,
      bundle: MissingBundle(),
      bundledPaths: () async => {},
      connectivity: () async => HanokNetwork.unmetered,
      fetch: (asset) async {
        requests.add(asset.asset);
        return bytesByPath[asset.asset]!;
      },
    );
    addTearDown(delivery.dispose);
    final operations = Future.wait<Object?>([
      delivery.statuses(),
      delivery.readCached('assets/art/retained.png'),
      delivery.downloadPack('house'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(store.calls, 1);
    expect(requests, isEmpty);
    store.gate!.complete();
    await operations;
    await delivery.statuses();
    expect(store.calls, 1);
    expect(requests.length, 2);
  });

  test(
    'temporary preparation failure can be retried in the same service',
    () async {
      final store = _PreparationStore()..failFirst = true;
      final delivery = HanokAssetDelivery(
        manifest: nextCatalog,
        store: store,
        bundle: MissingBundle(),
        bundledPaths: () async => {},
      );
      addTearDown(delivery.dispose);
      await expectLater(
        delivery.statuses(),
        throwsA(failure(HanokAssetFailureKind.storage)),
      );
      expect((await delivery.statuses()).single.storedBytes, 0);
      await delivery.statuses();
      expect(store.calls, 2);
    },
  );

  test('invalid catalog never authorizes cache reclamation', () async {
    final store = _PreparationStore();
    final oldAsset = oldCatalog.assets['assets/art/old.png']!;
    await store.write(oldAsset, original);
    final delivery = HanokAssetDelivery(
      store: store,
      bundle: MissingBundle({
        'assets/data/hanok_download_manifest.json': Uint8List.fromList(
          utf8.encode(jsonEncode(document([]))),
        ),
      }),
      bundledPaths: () async => {},
    );
    addTearDown(delivery.dispose);
    await expectLater(delivery.statuses(), throwsFormatException);
    expect(store.calls, 0);
    expect(await store.read(oldAsset), original);
  });

  test(
    'native directory acquisition retries after a transient failure',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'hanok_directory_retry_',
      );
      addTearDown(() => dir.delete(recursive: true));
      var calls = 0;
      final store = NativeHanokAssetStore(
        directory: () async {
          calls++;
          if (calls == 1) {
            throw const FileSystemException(
              'directory temporarily unavailable',
            );
          }
          return dir;
        },
      );
      final delivery = HanokAssetDelivery(
        manifest: nextCatalog,
        store: store,
        bundle: MissingBundle(),
        bundledPaths: () async => {},
      );
      addTearDown(delivery.dispose);
      await expectLater(
        delivery.statuses(),
        throwsA(isA<FileSystemException>()),
      );
      expect((await delivery.statuses()).single.storedBytes, 0);
      await delivery.statuses();
      expect(calls, 2);
    },
  );

  test(
    'reclamation does not follow links to files outside the cache',
    () async {
      final parent = await Directory.systemTemp.createTemp('hanok_link_');
      addTearDown(() => parent.delete(recursive: true));
      final dir = await Directory('${parent.path}/cache').create();
      final outside = File('${parent.path}/keep.png');
      await outside.writeAsBytes(original);
      final link = Link('${dir.path}/${'f' * 64}.png');
      try {
        await link.create(outside.path);
      } on FileSystemException catch (error) {
        if (Platform.isWindows && error.osError?.errorCode == 1314) {
          markTestSkipped('Host does not grant Windows symlink creation.');
          return;
        }
        rethrow;
      }
      final store = NativeHanokAssetStore(directory: () async => dir);
      await store.reconcile(nextCatalog);
      expect(await link.exists(), true);
      expect(await outside.readAsBytes(), original);
    },
  );
}
