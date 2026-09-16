import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';

class MissingBundle extends CachingAssetBundle {
  final Map<String, Uint8List> files;
  MissingBundle([this.files = const {}]);
  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) {
      throw StateError('not bundled');
    }
    return ByteData.sublistView(bytes);
  }
}

class CountingStore extends MemoryHanokAssetStore {
  int fullReads = 0;
  @override
  Future<Uint8List?> read(HanokAsset asset) {
    fullReads++;
    return super.read(asset);
  }
}

final original = Uint8List.fromList([1, 2, 3, 4]);
final second = Uint8List.fromList([5, 6, 7]);
Map<String, Object> entry(String name, Uint8List bytes) {
  final hash = sha256.convert(bytes).toString();
  return {
    'asset': 'assets/art/$name.png',
    'sha256': hash,
    'bytes': bytes.length,
    'contentType': 'image/png',
    'storagePath': 'learning-art/v1/$hash.png',
  };
}

Map<String, Object> pack(String id, List<Map<String, Object>> assets) => {
  'id': id,
  'title': {'ko': id, 'en': id, 'de': id},
  'assets': assets,
};
Map<String, Object> document(List<Map<String, Object>> packs) => {
  'schemaVersion': 1,
  'storageBucket': HanokAssetManifest.bucket,
  'packs': packs,
};
HanokAssetManifest catalog({bool shared = false}) => HanokAssetManifest.parse(
  jsonEncode(
    document([
      pack('house', [entry('first', original), entry('second', second)]),
      pack('gate', [
        entry('gate', shared ? original : Uint8List.fromList([9])),
      ]),
    ]),
  ),
);
Matcher failure(HanokAssetFailureKind kind) =>
    isA<HanokAssetFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HanokAssetManifest manifest;
  late MemoryHanokAssetStore store;
  late List<String> requests;
  HanokAssetDelivery service({
    HanokAssetFetch? fetch,
    HanokConnectivity? connectivity,
    Set<String> included = const {},
    AssetBundle? bundle,
  }) => HanokAssetDelivery(
    manifest: manifest,
    store: store,
    bundle: bundle ?? MissingBundle(),
    bundledPaths: () async => included,
    connectivity: connectivity ?? () async => HanokNetwork.unmetered,
    fetch:
        fetch ??
        (a) async {
          requests.add(a.asset);
          return a.asset.endsWith('second.png') ? second : original;
        },
  );
  setUp(() {
    manifest = catalog();
    store = MemoryHanokAssetStore();
    requests = [];
  });

  test(
    'repeated status snapshots use verified metadata rather than full image reads',
    () async {
      final counted = CountingStore();
      store = counted;
      final delivery = service();
      await delivery.downloadPack('house');
      final before = counted.fullReads;
      for (var i = 0; i < 20; i++) {
        expect((await delivery.statuses()).first.isComplete, true);
      }
      expect(counted.fullReads, before);
      await delivery.load('assets/art/first.png', prefetchPack: false);
      expect(counted.fullReads, before + 1);
    },
  );

  test(
    'bundle resolves without catalog, connectivity, cache or token work',
    () async {
      final delivery = HanokAssetDelivery(
        bundle: MissingBundle({'bundled': original}),
        connectivity: () => throw StateError('network initialized'),
        fetch: (_) => throw StateError('fetch initialized'),
      );
      expect(await delivery.load('bundled'), original);
    },
  );
  test(
    'verified cache survives fresh service offline without connectivity',
    () async {
      await service().load('assets/art/first.png', prefetchPack: false);
      final fresh = service(connectivity: () => throw StateError('offline'));
      expect(
        await fresh.load('assets/art/first.png', prefetchPack: false),
        original,
      );
      expect(requests, ['assets/art/first.png']);
    },
  );
  test('passive image fetches just selected image', () async {
    await service().load('assets/art/first.png', prefetchPack: false);
    expect(requests, ['assets/art/first.png']);
  });
  test(
    'selected image returns before same pack preparation finishes',
    () async {
      final tail = Completer<Uint8List>();
      final started = Completer<void>();
      final delivery = service(
        fetch: (a) async {
          requests.add(a.asset);
          if (a.asset.endsWith('second.png')) {
            started.complete();
            return tail.future;
          }
          return original;
        },
      );
      expect(await delivery.load('assets/art/first.png'), original);
      await started.future;
      expect(requests, ['assets/art/first.png', 'assets/art/second.png']);
      tail.complete(second);
      await delivery.downloadPack('house');
    },
  );
  test(
    'cellular and unknown require explicit action; action targets one pack',
    () async {
      for (final network in [
        HanokNetwork.cellular,
        HanokNetwork.unknown,
        HanokNetwork.offline,
      ]) {
        await expectLater(
          service(
            connectivity: () async => network,
          ).load('assets/art/first.png', prefetchPack: false),
          throwsA(failure(HanokAssetFailureKind.explicitDownloadNeeded)),
        );
      }
      final delivery = service(connectivity: () async => HanokNetwork.cellular);
      await delivery.downloadPack('house', allowMobileData: true);
      expect(requests, ['assets/art/first.png', 'assets/art/second.png']);
      final status = await delivery.statuses();
      expect(status.first.isComplete, true);
      expect(status.last.availableBytes, 0);
    },
  );
  test(
    'full bundle index reports availability without reading images or fetching',
    () async {
      final delivery = service(
        included: manifest.assets.keys.toSet(),
        connectivity: () => throw StateError('network initialized'),
      );
      await delivery.downloadPack('house');
      final status = (await delivery.statuses()).first;
      expect(status.isBundled, true);
      expect(status.isComplete, true);
      expect(status.storedBytes, 0);
      await delivery.removePack('house');
      expect((await delivery.statuses()).first.isComplete, true);
      expect(requests, isEmpty);
    },
  );
  test(
    'concurrent loads coalesce hash and return independent byte arrays',
    () async {
      final response = Completer<Uint8List>();
      final started = Completer<void>();
      final delivery = service(
        fetch: (a) {
          requests.add(a.asset);
          started.complete();
          return response.future;
        },
      );
      final a = delivery.load('assets/art/first.png', prefetchPack: false);
      final b = delivery.load('assets/art/first.png', prefetchPack: false);
      await started.future;
      response.complete(original);
      final values = await Future.wait([a, b]);
      expect(requests.length, 1);
      values.first[0] = 99;
      expect(values.last, original);
      expect(
        await store.read(manifest.assets['assets/art/first.png']!),
        original,
      );
    },
  );
  test('at most two active fetches across packs', () async {
    final starts = StreamController<HanokAsset>();
    final pending = <String, Completer<Uint8List>>{};
    final delivery = service(
      fetch: (a) {
        final done = Completer<Uint8List>();
        pending[a.asset] = done;
        starts.add(a);
        return done.future;
      },
    );
    final iterator = StreamIterator(starts.stream);
    final loads = manifest.assets.keys
        .map((p) => delivery.load(p, prefetchPack: false))
        .toList();
    await iterator.moveNext();
    await iterator.moveNext();
    expect(pending.length, 2);
    pending['assets/art/first.png']!.complete(original);
    await iterator.moveNext();
    expect(pending.length, 3);
    pending['assets/art/second.png']!.complete(second);
    pending['assets/art/gate.png']!.complete(Uint8List.fromList([9]));
    await Future.wait(loads);
    await iterator.cancel();
    await starts.close();
  });
  test(
    'corrupt response not stored, partial progress retained and retry completes',
    () async {
      var broken = true;
      final delivery = service(
        fetch: (a) async => a.asset.endsWith('second.png')
            ? (broken ? original : second)
            : original,
      );
      await expectLater(
        delivery.downloadPack('house'),
        throwsA(failure(HanokAssetFailureKind.corrupt)),
      );
      var status = (await delivery.statuses()).first;
      expect(status.availableBytes, original.length);
      expect(status.storedBytes, original.length);
      expect(status.isDownloading, false);
      expect(status.failure!.kind, HanokAssetFailureKind.corrupt);
      broken = false;
      await delivery.downloadPack('house');
      status = (await delivery.statuses()).first;
      expect(status.isComplete, true);
      expect(status.failure, null);
    },
  );
  test('capacity does not evict already downloaded offline files', () async {
    store = MemoryHanokAssetStore(capacity: original.length);
    final delivery = service();
    await expectLater(
      delivery.downloadPack('house'),
      throwsA(failure(HanokAssetFailureKind.cacheFull)),
    );
    expect(
      await store.read(manifest.assets['assets/art/first.png']!),
      original,
    );
    expect((await delivery.statuses()).first.storedBytes, original.length);
  });
  test('removal drains pending load and prevents late recreation', () async {
    final response = Completer<Uint8List>();
    final started = Completer<void>();
    final delivery = service(
      fetch: (_) {
        started.complete();
        return response.future;
      },
    );
    final load = delivery.load('assets/art/first.png');
    final rejected = expectLater(
      load,
      throwsA(failure(HanokAssetFailureKind.removed)),
    );
    await started.future;
    final removal = delivery.removePack('house');
    response.complete(original);
    await removal;
    await rejected;
    expect((await delivery.statuses()).first.availableBytes, 0);
    expect(await store.read(manifest.assets['assets/art/first.png']!), null);
  });
  test('removal stops pending full pack before next asset', () async {
    final response = Completer<Uint8List>();
    final started = Completer<void>();
    final delivery = service(
      fetch: (a) {
        requests.add(a.asset);
        started.complete();
        return response.future;
      },
    );
    final rejected = expectLater(
      delivery.downloadPack('house'),
      throwsA(failure(HanokAssetFailureKind.removed)),
    );
    await started.future;
    final removal = delivery.removePack('house');
    response.complete(original);
    await removal;
    await rejected;
    expect(requests.length, 1);
    expect((await delivery.statuses()).first.availableBytes, 0);
  });
  test('shared hashes remain usable by another complete pack', () async {
    manifest = catalog(shared: true);
    final delivery = service();
    await delivery.downloadPack('house');
    await delivery.downloadPack('gate');
    await delivery.removePack('house');
    final status = await delivery.statuses();
    expect(status.last.isComplete, true);
    expect(status.first.storedBytes, original.length);
    expect(await store.read(manifest.assets['assets/art/second.png']!), null);
  });
  test('fetch exception is typed, settles status, permits retry', () async {
    var fail = true;
    final delivery = service(
      fetch: (_) async {
        if (fail) {
          throw StateError('unavailable');
        }
        return original;
      },
    );
    await expectLater(
      delivery.load('assets/art/first.png', prefetchPack: false),
      throwsA(failure(HanokAssetFailureKind.network)),
    );
    expect((await delivery.statuses()).first.isDownloading, false);
    fail = false;
    expect(
      await delivery.load('assets/art/first.png', prefetchPack: false),
      original,
    );
    expect((await delivery.statuses()).first.failure, null);
  });

  test(
    'a new explicit request waits for removal then can redownload',
    () async {
      final first = Completer<Uint8List>();
      final started = Completer<void>();
      var calls = 0;
      final delivery = service(
        fetch: (_) {
          calls++;
          if (calls == 1) {
            started.complete();
            return first.future;
          }
          return Future.value(original);
        },
      );
      final old = expectLater(
        delivery.load('assets/art/first.png', prefetchPack: false),
        throwsA(failure(HanokAssetFailureKind.removed)),
      );
      await started.future;
      final removal = delivery.removePack('house');
      final fresh = delivery.load(
        'assets/art/first.png',
        prefetchPack: false,
        allowMobileData: true,
      );
      expect(calls, 1);
      first.complete(original);
      await removal;
      await old;
      expect(await fresh, original);
      expect(calls, 2);
      expect(
        await store.read(manifest.assets['assets/art/first.png']!),
        original,
      );
    },
  );

  test('late background policy cannot restart a removed pack', () async {
    await store.write(manifest.assets['assets/art/first.png']!, original);
    final policy = Completer<HanokNetwork>();
    final started = Completer<void>();
    final delivery = service(
      connectivity: () {
        if (!started.isCompleted) {
          started.complete();
        }
        return policy.future;
      },
    );
    expect(await delivery.load('assets/art/first.png'), original);
    await started.future;
    await delivery.removePack('house');
    policy.complete(HanokNetwork.unmetered);
    await Future<void>.delayed(Duration.zero);
    expect(requests, isEmpty);
    expect((await delivery.statuses()).first.availableBytes, 0);
  });

  test(
    'background fetch failure is contained and visible in pack status',
    () async {
      final started = Completer<void>();
      final failed = Completer<Uint8List>();
      final delivery = service(
        fetch: (a) {
          if (a.asset.endsWith('second.png')) {
            started.complete();
            return failed.future;
          }
          return Future.value(original);
        },
      );
      expect(await delivery.load('assets/art/first.png'), original);
      await started.future;
      final settled = expectLater(
        delivery.downloadPack('house'),
        throwsA(failure(HanokAssetFailureKind.network)),
      );
      failed.completeError(StateError('disconnected'));
      await settled;
      final status = (await delivery.statuses()).first;
      expect(status.isDownloading, false);
      expect(status.failure!.kind, HanokAssetFailureKind.network);
    },
  );
}
