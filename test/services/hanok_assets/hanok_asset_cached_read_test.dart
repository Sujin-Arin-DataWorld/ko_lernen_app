import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';

import 'hanok_asset_delivery_test.dart'
    show catalog, original, MissingBundle, failure;

class _PausedReadStore extends MemoryHanokAssetStore {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<Uint8List?> read(HanokAsset asset) async {
    final snapshot = await super.read(asset);
    entered.complete();
    await release.future;
    return snapshot;
  }
}

class _PausedRemovalStore extends MemoryHanokAssetStore {
  final entered = Completer<void>();
  final release = Completer<void>();
  int reads = 0;

  @override
  Future<Uint8List?> read(HanokAsset asset) {
    reads++;
    return super.read(asset);
  }

  @override
  Future<void> remove(HanokAsset asset) async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    await super.remove(asset);
  }
}

class _CorruptReadStore extends MemoryHanokAssetStore {
  @override
  Future<Uint8List?> read(HanokAsset asset) async =>
      Uint8List.fromList([4, 3, 2, 1]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = catalog();
  final asset = manifest.assets['assets/art/first.png']!;
  late int connectivityChecks;
  late int fetches;
  late int notifications;

  HanokAssetDelivery deliveryFor(HanokAssetStore store) {
    final delivery = HanokAssetDelivery(
      manifest: manifest,
      bundle: MissingBundle(),
      store: store,
      bundledPaths: () async => {},
      connectivity: () async {
        connectivityChecks++;
        return HanokNetwork.unmetered;
      },
      fetch: (_) async {
        fetches++;
        return original;
      },
    );
    delivery.addListener(() => notifications++);
    addTearDown(delivery.dispose);
    return delivery;
  }

  setUp(() {
    connectivityChecks = 0;
    fetches = 0;
    notifications = 0;
  });

  test('cache probes never request network or emit delivery changes', () async {
    final store = MemoryHanokAssetStore();
    final delivery = deliveryFor(store);
    expect(await delivery.readCached('assets/art/unknown.png'), isNull);
    expect(await delivery.readCached(asset.asset), isNull);
    await store.write(asset, original);
    final first = await delivery.readCached(asset.asset);
    expect(first, orderedEquals(original));
    first![0] = 255;
    expect(await delivery.readCached(asset.asset), orderedEquals(original));
    expect(connectivityChecks, 0);
    expect(fetches, 0);
    expect(notifications, 0);
  });

  test(
    'cache probe rejects same-length corrupt bytes without repair fetch',
    () async {
      final delivery = deliveryFor(_CorruptReadStore());
      expect(await delivery.readCached(asset.asset), isNull);
      expect(connectivityChecks, 0);
      expect(fetches, 0);
      expect(notifications, 0);
    },
  );

  test(
    'removal invalidates bytes already being read by a cache probe',
    () async {
      final store = _PausedReadStore();
      await store.write(asset, original);
      final delivery = deliveryFor(store);
      final pending = delivery.readCached(asset.asset);
      final rejected = expectLater(
        pending,
        throwsA(failure(HanokAssetFailureKind.removed)),
      );
      await store.entered.future;
      await delivery.removePack('house');
      store.release.complete();
      await rejected;
      expect(connectivityChecks, 0);
      expect(fetches, 0);
    },
  );

  test(
    'cache probe waits for active removal and sees the resulting miss',
    () async {
      final store = _PausedRemovalStore();
      await store.write(asset, original);
      final delivery = deliveryFor(store);
      final removal = delivery.removePack('house');
      await store.entered.future;
      final pending = delivery.readCached(asset.asset);
      await Future<void>.delayed(Duration.zero);
      expect(store.reads, 0);
      store.release.complete();
      await removal;
      expect(await pending, isNull);
      expect(connectivityChecks, 0);
      expect(fetches, 0);
    },
  );
}
