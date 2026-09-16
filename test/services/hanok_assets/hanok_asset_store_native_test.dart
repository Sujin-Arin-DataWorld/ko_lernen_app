import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_store_native.dart';
import 'hanok_asset_delivery_test.dart' show catalog, failure, original, second;

void main() {
  late Directory directory;
  late NativeHanokAssetStore store;
  final asset = catalog().packs.first.assets.first;
  final next = catalog().packs.first.assets.last;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hanok_store_test_');
    store = NativeHanokAssetStore(directory: () async => directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test(
    'shipped manifest strictly parses and every entry resolves official URI',
    () async {
      final manifest = HanokAssetManifest.parse(
        await File('assets/data/hanok_download_manifest.json').readAsString(),
      );
      expect(manifest.packs, isNotEmpty);
      for (final asset in manifest.assets.values) {
        expect(asset.mediaUri.pathSegments.last, asset.storagePath);
      }
    },
  );
  test('malformed manifest types fail with FormatException', () {
    for (final value in [
      null,
      1,
      [],
      {},
      {
        'schemaVersion': 1,
        'storageBucket': HanokAssetManifest.bucket,
        'packs': [null],
      },
    ]) {
      expect(
        () => HanokAssetManifest.parse(jsonEncode(value)),
        throwsFormatException,
      );
    }
  });
  test('verified bytes persist across service/store restarts', () async {
    await store.write(asset, original);
    final restarted = NativeHanokAssetStore(directory: () async => directory);
    expect(await restarted.read(asset), original);
    expect((await directory.list().toList()).length, 1);
  });
  test('corrupt cache discarded rather than returned', () async {
    final file = File('${directory.path}/${asset.filename}');
    await file.writeAsBytes([1, 2, 3, 9]);
    expect(await store.read(asset), null);
    expect(await file.exists(), false);
    await store.write(asset, original);
    expect(await store.read(asset), original);
  });

  test(
    'status fingerprints invalidate on file change and resolve directory once',
    () async {
      var directoryCalls = 0;
      store = NativeHanokAssetStore(
        directory: () async {
          directoryCalls++;
          return directory;
        },
      );
      await store.write(asset, original);
      for (var i = 0; i < 20; i++) {
        expect(await store.containsVerified(asset), true);
      }
      expect(directoryCalls, 1);
      final file = File('${directory.path}/${asset.filename}');
      await file.writeAsBytes([9, 9, 9, 9]);
      await file.setLastModified(DateTime(2001));
      expect(await store.containsVerified(asset), false);
      expect(await file.exists(), false);
    },
  );
  test('bad write never promotes temporary data', () async {
    await expectLater(
      store.write(asset, Uint8List.fromList([1])),
      throwsA(failure(HanokAssetFailureKind.corrupt)),
    );
    expect(await directory.list().toList(), isEmpty);
  });
  test('capacity checks serialize concurrent instances; no eviction', () async {
    store = NativeHanokAssetStore(
      directory: () async => directory,
      capacity: original.length,
    );
    final other = NativeHanokAssetStore(
      directory: () async => directory,
      capacity: original.length,
    );
    await store.write(asset, original);
    await expectLater(
      other.write(next, second),
      throwsA(failure(HanokAssetFailureKind.cacheFull)),
    );
    expect(await other.read(asset), original);
    expect((await directory.list().toList()).length, 1);
  });
  test(
    'removal affects exact owned file, leaves unrelated files intact',
    () async {
      final unrelated = File('${directory.path}/notes.txt');
      await unrelated.writeAsString('keep');
      await store.write(asset, original);
      await store.remove(asset);
      expect(await store.read(asset), null);
      expect(await unrelated.readAsString(), 'keep');
    },
  );
}
