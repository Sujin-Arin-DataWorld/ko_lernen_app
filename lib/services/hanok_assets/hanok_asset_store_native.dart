import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'hanok_asset_failure.dart';
import 'hanok_asset_manifest.dart';
import 'hanok_asset_store.dart';

HanokAssetStore createHanokAssetStore() => NativeHanokAssetStore();

/// Only immutable hash filenames directly inside the dedicated directory are owned.
class NativeHanokAssetStore implements HanokAssetStore {
  final Future<Directory> Function() directory;
  final int capacity;
  Future<Directory>? _directory;
  bool _recovered = false;
  final Map<String, FileStat> _verified = {};
  static final Map<String, Future<void>> _locks = {};
  static final _ownedFilename = RegExp(r'^[0-9a-f]{64}\.(png|webp)$');
  static int _sequence = 0;
  NativeHanokAssetStore({
    Future<Directory> Function()? directory,
    this.capacity = hanokCacheCapacity,
  }) : directory = directory ?? _defaultDirectory;
  static Future<Directory> _defaultDirectory() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/hanok_art/v1',
  );

  Future<T> _locked<T>(Future<T> Function(Directory) action) async {
    final pendingDirectory = _directory ??= Future<Directory>.sync(directory);
    late final Directory dir;
    try {
      dir = await pendingDirectory;
    } catch (_) {
      if (identical(_directory, pendingDirectory)) {
        _directory = null;
      }
      rethrow;
    }
    final key = dir.absolute.path;
    final previous = _locks[key] ?? Future<void>.value();
    final task = previous.then((_) async {
      if (!_recovered) {
        // All writers for this application directory hold this same lock.
        // Exact temporary names left by an interrupted prior write are safe
        // to reclaim; never touch arbitrary .tmp files or linked paths.
        if (await dir.exists()) {
          await for (final item in dir.list(followLinks: false)) {
            if (item is File &&
                RegExp(
                  r'^[0-9a-f]{64}\.(png|webp)\.\d+_\d+_\d+\.tmp$',
                ).hasMatch(item.uri.pathSegments.last)) {
              await item.delete();
            }
          }
        }
        _recovered = true;
      }
      return action(dir);
    });
    final settled = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _locks[key] = settled;
    try {
      return await task;
    } on HanokAssetFailure {
      rethrow;
    } on FileSystemException {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    } finally {
      if (identical(_locks[key], settled)) {
        _locks.remove(key);
      }
    }
  }

  @override
  Future<void> reconcile(HanokAssetManifest manifest) => _locked((dir) async {
    if (!await dir.exists()) {
      return;
    }
    final current = manifest.assets.values
        .map((asset) => asset.filename)
        .toSet();
    await for (final item in dir.list(followLinks: false)) {
      final filename = item.uri.pathSegments.last;
      if (item is File &&
          _ownedFilename.hasMatch(filename) &&
          !current.contains(filename)) {
        await item.delete();
        _verified.remove(filename);
      }
    }
  });

  @override
  Future<Uint8List?> read(HanokAsset asset) =>
      _locked((dir) => _read(dir, asset));

  Future<Uint8List?> _read(Directory dir, HanokAsset asset) async {
    _verified.remove(asset.filename);
    final file = File('${dir.path}/${asset.filename}');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    if (await file.length() != asset.bytes) {
      await file.delete();
      return null;
    }
    final bytes = await file.readAsBytes();
    if (!verifiesHanokAsset(asset, bytes)) {
      await file.delete();
      return null;
    }
    _verified[asset.filename] = await file.stat();
    return bytes;
  }

  @override
  Future<bool> containsVerified(HanokAsset asset) => _locked((dir) async {
    final file = File('${dir.path}/${asset.filename}');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      _verified.remove(asset.filename);
      return false;
    }
    final current = await file.stat();
    final prior = _verified[asset.filename];
    if (prior != null &&
        current.size == asset.bytes &&
        current.size == prior.size &&
        current.modified == prior.modified &&
        current.changed == prior.changed) {
      return true;
    }
    return await _read(dir, asset) != null;
  });

  @override
  Future<void> write(HanokAsset asset, Uint8List bytes) => _locked((dir) async {
    _verified.remove(asset.filename);
    if (!verifiesHanokAsset(asset, bytes)) {
      throw const HanokAssetFailure(HanokAssetFailureKind.corrupt);
    }
    await dir.create(recursive: true);
    final target = File('${dir.path}/${asset.filename}');
    var used = 0;
    await for (final item in dir.list(followLinks: false)) {
      if (item is File && _ownedFilename.hasMatch(item.uri.pathSegments.last)) {
        used += await item.length();
      }
    }
    final type = await FileSystemEntity.type(target.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    }
    final oldSize = type == FileSystemEntityType.file
        ? await target.length()
        : 0;
    // A verified immutable file already satisfies the request. Avoid writing
    // another full-sized temporary copy, especially near the cache limit.
    if (oldSize == asset.bytes &&
        verifiesHanokAsset(asset, await target.readAsBytes())) {
      _verified[asset.filename] = await target.stat();
      return;
    }
    if (used - oldSize + bytes.length > capacity) {
      throw const HanokAssetFailure(HanokAssetFailureKind.cacheFull);
    }
    if (type == FileSystemEntityType.file) {
      // The existing bytes failed verification, so they are not an offline
      // asset to preserve. Reclaim them before reserving the temporary copy.
      await target.delete();
    }
    final temporary = File(
      '${target.path}.${pid}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (!verifiesHanokAsset(asset, await temporary.readAsBytes())) {
        throw const HanokAssetFailure(HanokAssetFailureKind.corrupt);
      }
      await temporary.rename(target.path);
      _verified[asset.filename] = await target.stat();
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  });

  @override
  Future<void> remove(HanokAsset asset) => _locked((dir) async {
    _verified.remove(asset.filename);
    final file = File('${dir.path}/${asset.filename}');
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.file) {
      await file.delete();
    }
  });

  static final _releaseName = RegExp(
    r'^\.released-([a-z0-9]+(?:-[a-z0-9]+)*)$',
  );

  @override
  Future<Set<String>> releasedPacks() => _locked((dir) async {
    final result = <String>{};
    if (await dir.exists()) {
      await for (final item in dir.list(followLinks: false)) {
        if (item is File) {
          final match = _releaseName.firstMatch(item.uri.pathSegments.last);
          if (match != null) {
            result.add(match.group(1)!);
          }
        }
      }
    }
    return result;
  });

  @override
  Future<void> setPackReleased(String packId, bool released) => _locked((
    dir,
  ) async {
    final name = '.released-$packId';
    if (!_releaseName.hasMatch(name)) {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    }
    final marker = File('${dir.path}/$name');
    final type = await FileSystemEntity.type(marker.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    }
    if (released) {
      await dir.create(recursive: true);
      await marker.writeAsBytes(const [], flush: true);
    } else if (type == FileSystemEntityType.file) {
      await marker.delete();
    }
  });
}
