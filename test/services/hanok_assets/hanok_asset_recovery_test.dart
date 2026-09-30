import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_store_native.dart';

import 'hanok_asset_delivery_test.dart'
    show entry, pack, document, original, MissingBundle, failure;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = HanokAssetManifest.parse(
    jsonEncode(
      document([
        pack('a', [entry('a', original)]),
        pack('b', [entry('b', original)]),
      ]),
    ),
  );
  HanokAssetDelivery service(HanokAssetStore store) => HanokAssetDelivery(
    manifest: manifest,
    store: store,
    bundle: MissingBundle(),
    bundledPaths: () async => {},
    connectivity: () async => HanokNetwork.unmetered,
    fetch: (_) async => original,
  );

  test(
    'removing both identical packs eventually releases their shared bytes',
    () async {
      final delivery = service(MemoryHanokAssetStore());
      await delivery.downloadPack('a');
      await delivery.downloadPack('b');
      await delivery.removePack('a');
      expect((await delivery.statuses()).last.isComplete, true);
      await delivery.removePack('b');
      expect((await delivery.statuses()).map((s) => s.storedBytes), [0, 0]);
      delivery.dispose();
    },
  );

  test(
    'redownloading a released pack restores its shared-byte protection',
    () async {
      final delivery = service(MemoryHanokAssetStore());
      await delivery.downloadPack('a');
      await delivery.downloadPack('b');
      await delivery.removePack('a');
      await delivery.downloadPack('a');
      await delivery.removePack('b');
      expect((await delivery.statuses()).first.isComplete, true);
      await delivery.removePack('a');
      expect((await delivery.statuses()).map((s) => s.storedBytes), [0, 0]);
      delivery.dispose();
    },
  );

  test(
    'shared removal intent survives a native store and service restart',
    () async {
      final dir = await Directory.systemTemp.createTemp('hanok_recovery_');
      try {
        final first = service(
          NativeHanokAssetStore(directory: () async => dir),
        );
        await first.downloadPack('a');
        await first.downloadPack('b');
        await first.removePack('a');
        first.dispose();
        final next = service(NativeHanokAssetStore(directory: () async => dir));
        expect((await next.statuses()).last.isComplete, true);
        await next.removePack('b');
        expect((await next.statuses()).map((s) => s.storedBytes), [0, 0]);
        next.dispose();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  for (final cached in [true, false]) {
    test(
      'image load restores shared protection with prefetch off, cached=$cached',
      () async {
        final delivery = service(MemoryHanokAssetStore());
        await delivery.downloadPack('a');
        await delivery.downloadPack('b');
        await delivery.removePack('a');
        if (!cached) {
          await delivery.removePack('b');
        }
        expect(
          await delivery.load(
            manifest.packs.first.assets.first.asset,
            prefetchPack: false,
          ),
          original,
        );
        await delivery.downloadPack('b');
        await delivery.removePack('b');
        expect((await delivery.statuses()).first.isComplete, true);
        await delivery.removePack('a');
        expect((await delivery.statuses()).map((s) => s.storedBytes), [0, 0]);
        delivery.dispose();
      },
    );
  }

  test(
    'reclaims only interrupted owned temporary files before enforcing cap',
    () async {
      final dir = await Directory.systemTemp.createTemp('hanok_recovery_');
      final asset = manifest.packs.first.assets.first;
      try {
        final abandoned = File(
          '${dir.path}/${asset.filename}.99999_12345_0.tmp',
        );
        final unrelated = File('${dir.path}/notes.tmp');
        await abandoned.writeAsBytes(original);
        await unrelated.writeAsBytes([]);
        final store = NativeHanokAssetStore(
          directory: () async => dir,
          capacity: original.length,
        );
        await store.write(asset, original);
        await store.write(asset, original);
        expect(await abandoned.exists(), false);
        expect(await unrelated.exists(), true);
        var bytes = 0;
        await for (final file in dir.list()) {
          if (file is File) {
            bytes += await file.length();
          }
        }
        expect(bytes, original.length);
        expect(await store.read(asset), original);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test('release markers reject path traversal', () async {
    final dir = await Directory.systemTemp.createTemp('hanok_recovery_');
    try {
      final store = NativeHanokAssetStore(directory: () async => dir);
      await expectLater(
        store.setPackReleased('../other', true),
        throwsA(failure(HanokAssetFailureKind.storage)),
      );
      expect(await dir.list().toList(), isEmpty);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
