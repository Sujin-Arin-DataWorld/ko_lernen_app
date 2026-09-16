import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'hanok_asset_failure.dart';
import 'hanok_asset_manifest.dart';

const hanokCacheCapacity = 300 * 1024 * 1024;

bool verifiesHanokAsset(HanokAsset asset, List<int> bytes) =>
    bytes.length == asset.bytes &&
    crypto.sha256.convert(bytes).toString() == asset.sha256;

abstract class HanokAssetStore {
  /// Returns only verified original bytes. Corrupt entries are discarded.
  Future<Uint8List?> read(HanokAsset asset);

  /// A lightweight status check for previously verified, unchanged objects.
  /// Actual image loads still call [read] and verify their bytes.
  Future<bool> containsVerified(HanokAsset asset);
  Future<void> write(HanokAsset asset, Uint8List bytes);
  Future<void> remove(HanokAsset asset);

  /// Explicit removal intent survives restart even while another pack keeps
  /// shared bytes. Otherwise identical packs can protect each other forever.
  Future<Set<String>> releasedPacks();
  Future<void> setPackReleased(String packId, bool released);
}

class MemoryHanokAssetStore implements HanokAssetStore {
  final int capacity;
  final Map<String, Uint8List> _files = {};
  final Set<String> _released = {};
  MemoryHanokAssetStore({this.capacity = hanokCacheCapacity});
  @override
  Future<bool> containsVerified(HanokAsset asset) async =>
      _files.containsKey(asset.filename);
  @override
  Future<Uint8List?> read(HanokAsset asset) async {
    final bytes = _files[asset.filename];
    if (bytes == null) {
      return null;
    }
    if (!verifiesHanokAsset(asset, bytes)) {
      _files.remove(asset.filename);
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> write(HanokAsset asset, Uint8List bytes) async {
    if (!verifiesHanokAsset(asset, bytes)) {
      throw const HanokAssetFailure(HanokAssetFailureKind.corrupt);
    }
    final used = _files.values.fold<int>(0, (sum, data) => sum + data.length);
    if (used - (_files[asset.filename]?.length ?? 0) + bytes.length >
        capacity) {
      throw const HanokAssetFailure(HanokAssetFailureKind.cacheFull);
    }
    _files[asset.filename] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> remove(HanokAsset asset) async {
    _files.remove(asset.filename);
  }

  @override
  Future<Set<String>> releasedPacks() async => Set.of(_released);

  @override
  Future<void> setPackReleased(String packId, bool released) async {
    if (released) {
      _released.add(packId);
    } else {
      _released.remove(packId);
    }
  }
}
