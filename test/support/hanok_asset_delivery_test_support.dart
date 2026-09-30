import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';

/// Resolves checked-in artwork through the production bundle/cache/download
/// order while replacing the remote transport with the exact local source.
final class HanokAssetDeliveryTestSupport {
  HanokAssetDeliveryTestSupport._(
    this._fetchedPaths, {
    required this.manifest,
    required this.bundledPaths,
    required this.delivery,
  });

  final HanokAssetManifest manifest;
  final Set<String> bundledPaths;
  final HanokAssetDelivery delivery;
  final Set<String> _fetchedPaths;

  Set<String> get fetchedPaths => Set<String>.unmodifiable(_fetchedPaths);

  Set<String> get deliveryPaths => <String>{
    ...bundledPaths,
    ...manifest.assets.keys,
  };

  static Future<HanokAssetDeliveryTestSupport> create() async {
    final manifest = HanokAssetManifest.parse(
      await rootBundle.loadString('assets/data/hanok_download_manifest.json'),
    );
    final bundledPaths = Set<String>.unmodifiable(
      (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets(),
    );
    final fetchedPaths = <String>{};
    final delivery = HanokAssetDelivery(
      manifest: manifest,
      bundle: rootBundle,
      store: MemoryHanokAssetStore(),
      bundledPaths: () async => bundledPaths,
      connectivity: () async => HanokNetwork.unmetered,
      fetch: (asset) async {
        final bytes = await File(asset.asset).readAsBytes();
        expect(bytes.length, asset.bytes, reason: asset.asset);
        expect(
          sha256.convert(bytes).toString(),
          asset.sha256,
          reason: asset.asset,
        );
        fetchedPaths.add(asset.asset);
        return bytes;
      },
    );
    return HanokAssetDeliveryTestSupport._(
      fetchedPaths,
      manifest: manifest,
      bundledPaths: bundledPaths,
      delivery: delivery,
    );
  }

  bool isBundled(String assetPath) => bundledPaths.contains(assetPath);

  Future<Uint8List> load(String assetPath) async {
    final localBytes = await File(assetPath).readAsBytes();
    if (!isBundled(assetPath)) {
      final manifestAsset = manifest.assets[assetPath];
      expect(
        manifestAsset,
        isNotNull,
        reason: '$assetPath is neither bundled nor in the shipped manifest',
      );
      expect(manifestAsset!.bytes, localBytes.length, reason: assetPath);
      expect(
        manifestAsset.sha256,
        sha256.convert(localBytes).toString(),
        reason: assetPath,
      );
    }

    final bytes = await delivery.load(assetPath, prefetchPack: false);
    expect(bytes, localBytes, reason: assetPath);
    if (isBundled(assetPath)) {
      expect(_fetchedPaths, isNot(contains(assetPath)), reason: assetPath);
    } else {
      expect(_fetchedPaths, contains(assetPath), reason: assetPath);
    }
    return bytes;
  }

  void dispose() => delivery.dispose();
}
