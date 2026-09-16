import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'hanok_asset_failure.dart';
import 'hanok_asset_manifest.dart';
import 'hanok_asset_store.dart';
import 'hanok_asset_store_web.dart'
    if (dart.library.io) 'hanok_asset_store_native.dart'
    as platform;
import 'hanok_asset_transport.dart';

export 'hanok_asset_failure.dart';
export 'hanok_asset_manifest.dart';
export 'hanok_asset_store.dart';
export 'hanok_asset_transport.dart';

enum HanokNetwork { unmetered, cellular, offline, unknown }

typedef HanokConnectivity = Future<HanokNetwork> Function();
typedef HanokBundledPaths = Future<Set<String>> Function();

class HanokPackStatus {
  final HanokAssetPack pack;
  final int availableBytes;
  final int storedBytes;
  final bool isBundled;
  final bool isDownloading;
  final HanokAssetFailure? failure;
  bool get isComplete => availableBytes == pack.totalBytes;
  const HanokPackStatus({
    required this.pack,
    required this.availableBytes,
    required this.storedBytes,
    required this.isBundled,
    required this.isDownloading,
    this.failure,
  });
}

/// Bundle -> verified offline copy -> policy-gated immutable media request.
/// Constructing this service does not initialize connectivity or Firebase.
class HanokAssetDelivery extends ChangeNotifier {
  static final shared = HanokAssetDelivery();
  final AssetBundle _bundle;
  final HanokAssetStore _store;
  final HanokAssetFetch _fetch;
  final HanokConnectivity _connectivity;
  final HanokBundledPaths _bundledPaths;
  final Duration networkTimeout;
  Future<HanokAssetManifest>? _manifest;
  Future<void>? _cachePreparation;
  Future<Set<String>>? _bundled;
  final Map<String, Future<Uint8List>> _inflight = {};
  final Map<String, Future<void>> _packJobs = {};
  final Map<String, int> _epochs = {};
  final Map<String, HanokAssetFailure> _failures = {};
  final List<Completer<void>> _queue = [];
  int _active = 0;
  Future<void>? _removal;
  bool _disposed = false;

  HanokAssetDelivery({
    HanokAssetManifest? manifest,
    AssetBundle? bundle,
    HanokAssetStore? store,
    HanokAssetFetch? fetch,
    HanokConnectivity? connectivity,
    HanokBundledPaths? bundledPaths,
    this.networkTimeout = const Duration(seconds: 50),
  }) : _bundle = bundle ?? rootBundle,
       _store = store ?? platform.createHanokAssetStore(),
       _fetch = fetch ?? HanokAssetTransport().fetch,
       _connectivity = connectivity ?? _defaultConnectivity,
       _bundledPaths =
           bundledPaths ??
           (() async => (await AssetManifest.loadFromAssetBundle(
             bundle ?? rootBundle,
           )).listAssets().toSet()) {
    if (manifest != null) {
      _manifest = Future.value(manifest);
    }
  }

  static Future<HanokNetwork> _defaultConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.mobile)) {
      return HanokNetwork.cellular;
    }
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return HanokNetwork.unmetered;
    }
    if (results.contains(ConnectivityResult.none)) {
      return HanokNetwork.offline;
    }
    return HanokNetwork.unknown;
  }

  Future<HanokAssetManifest> _catalog() async {
    final catalog = await (_manifest ??= _bundle
        .loadString('assets/data/hanok_download_manifest.json')
        .then(HanokAssetManifest.parse));
    // A catalog is immutable for this service's lifetime. Finish reclamation
    // once, before cache reads/status/downloads; bundled loads bypass this path.
    await (_cachePreparation ??= _reconcile(catalog));
    return catalog;
  }

  Future<void> _reconcile(HanokAssetManifest catalog) async {
    try {
      await Future<void>.sync(() => _store.reconcile(catalog));
    } catch (_) {
      // A temporary storage failure must remain retryable in this session.
      _cachePreparation = null;
      rethrow;
    }
  }

  Future<Set<String>> _included() => _bundled ??= _bundledPaths();
  void _changed() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  int _epoch(String pack) => _epochs[pack] ?? 0;
  void _checkEpoch(String pack, int epoch) {
    if (_epoch(pack) != epoch) {
      throw const HanokAssetFailure(HanokAssetFailureKind.removed);
    }
  }

  Future<void> _waitRemoval() async {
    while (_removal != null) {
      await _removal;
    }
  }

  Future<void> _policy(bool allowMobileData) async {
    if (allowMobileData) {
      return;
    }
    HanokNetwork network;
    try {
      network = await _connectivity().timeout(const Duration(seconds: 5));
    } catch (_) {
      network = HanokNetwork.unknown;
    }
    if (network != HanokNetwork.unmetered) {
      throw const HanokAssetFailure(
        HanokAssetFailureKind.explicitDownloadNeeded,
      );
    }
  }

  Future<Uint8List> load(
    String assetPath, {
    AssetBundle? bundle,
    bool allowMobileData = false,
    bool prefetchPack = true,
  }) async {
    final requestedEpochs = Map<String, int>.of(_epochs);
    try {
      final data = await (bundle ?? _bundle).load(assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      /* Deferred files deliberately miss the Flutter bundle. */
    }
    await _waitRemoval();
    final catalog = await _catalog();
    await _waitRemoval();
    final asset = catalog.assets[assetPath];
    final pack = catalog.packsByAsset[assetPath];
    if (asset == null || pack == null) {
      throw const HanokAssetFailure(HanokAssetFailureKind.unknownAsset);
    }
    final epoch = requestedEpochs[pack.id] ?? 0;
    _checkEpoch(pack.id, epoch);
    try {
      final result = await _resolve(asset, pack.id, epoch, allowMobileData);
      _checkEpoch(pack.id, epoch);
      await _store.setPackReleased(pack.id, false);
      _checkEpoch(pack.id, epoch);
      if (_failures.remove(pack.id) != null) {
        _changed();
      }
      if (prefetchPack) {
        // Cached/offline display is immediate; background failures are contained.
        unawaited(_prepare(pack.id, epoch, allowMobileData));
      }
      return result;
    } on HanokAssetFailure catch (error) {
      if (_epoch(pack.id) == epoch) {
        _failures[pack.id] = error;
        _changed();
      }
      rethrow;
    }
  }

  /// Reads a verified downloaded copy without consulting connectivity or
  /// starting a transfer. Returns null when the path is unknown or uncached.
  Future<Uint8List?> readCached(String assetPath) async {
    await _waitRemoval();
    final catalog = await _catalog();
    await _waitRemoval();
    final asset = catalog.assets[assetPath];
    final pack = catalog.packsByAsset[assetPath];
    if (asset == null || pack == null) {
      return null;
    }
    final epoch = _epoch(pack.id);
    final cached = await _store.read(asset);
    _checkEpoch(pack.id, epoch);
    if (cached == null || !verifiesHanokAsset(asset, cached)) {
      return null;
    }
    return Uint8List.fromList(cached);
  }

  Future<void> _prepare(String packId, int epoch, bool allowMobileData) async {
    try {
      await _policy(allowMobileData);
      _checkEpoch(packId, epoch);
      await _downloadPack(
        packId,
        allowMobileData: allowMobileData,
        expectedEpoch: epoch,
      );
    } catch (_) {
      /* Download jobs retain meaningful failures; policy is passive. */
    }
  }

  Future<Uint8List> _resolve(
    HanokAsset asset,
    String packId,
    int epoch,
    bool allowMobileData,
  ) async {
    final cached = await _store.read(asset);
    _checkEpoch(packId, epoch);
    if (cached != null && verifiesHanokAsset(asset, cached)) {
      return cached;
    }
    await _policy(allowMobileData);
    _checkEpoch(packId, epoch);
    final existing = _inflight[asset.sha256];
    if (existing != null) {
      return Uint8List.fromList(await existing);
    }
    // Another caller can finish while this caller checks connectivity.
    final warmed = await _store.read(asset);
    _checkEpoch(packId, epoch);
    if (warmed != null && verifiesHanokAsset(asset, warmed)) {
      return warmed;
    }
    final underway = _inflight[asset.sha256];
    if (underway != null) {
      return Uint8List.fromList(await underway);
    }
    final job = _transfer(asset);
    _inflight[asset.sha256] = job;
    _changed();
    try {
      return Uint8List.fromList(await job);
    } finally {
      if (identical(_inflight[asset.sha256], job)) {
        _inflight.remove(asset.sha256);
      }
      _changed();
    }
  }

  Future<Uint8List> _transfer(HanokAsset asset) async {
    if (_active >= 2) {
      final turn = Completer<void>();
      _queue.add(turn);
      await turn.future;
    } else {
      _active++;
    }
    try {
      final bytes = await _fetch(asset).timeout(networkTimeout);
      if (!verifiesHanokAsset(asset, bytes)) {
        throw const HanokAssetFailure(HanokAssetFailureKind.corrupt);
      }
      await _store.write(asset, bytes);
      return bytes;
    } on HanokAssetFailure {
      rethrow;
    } catch (_) {
      throw const HanokAssetFailure(HanokAssetFailureKind.network);
    } finally {
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      } else {
        _active--;
      }
    }
  }

  Future<void> downloadPack(String packId, {bool allowMobileData = false}) =>
      _downloadPack(packId, allowMobileData: allowMobileData);

  Future<void> _downloadPack(
    String packId, {
    required bool allowMobileData,
    int? expectedEpoch,
  }) async {
    final epoch = expectedEpoch ?? _epoch(packId);
    await _waitRemoval();
    final catalog = await _catalog();
    await _waitRemoval();
    _checkEpoch(packId, epoch);
    final pack = catalog.packs.where((p) => p.id == packId).firstOrNull;
    if (pack == null) {
      throw const HanokAssetFailure(HanokAssetFailureKind.unknownAsset);
    }
    final existing = _packJobs[packId];
    if (existing != null) {
      return existing;
    }
    _failures.remove(packId);
    final job = _download(pack, epoch, allowMobileData);
    _packJobs[packId] = job;
    _changed();
    try {
      await job;
    } on HanokAssetFailure catch (error) {
      if (_epoch(packId) == epoch) {
        _failures[packId] = error;
      }
      rethrow;
    } finally {
      if (identical(_packJobs[packId], job)) {
        _packJobs.remove(packId);
      }
      _changed();
    }
  }

  Future<void> _download(
    HanokAssetPack pack,
    int epoch,
    bool allowMobileData,
  ) async {
    final included = await _included();
    _checkEpoch(pack.id, epoch);
    if (pack.assets.any((asset) => !included.contains(asset.asset))) {
      await _store.setPackReleased(pack.id, false);
    }
    for (final asset in pack.assets) {
      _checkEpoch(pack.id, epoch);
      if (!included.contains(asset.asset)) {
        await _resolve(asset, pack.id, epoch, allowMobileData);
      }
    }
    _checkEpoch(pack.id, epoch);
  }

  Future<List<HanokPackStatus>> statuses() async {
    final catalog = await _catalog();
    final included = await _included();
    final result = <HanokPackStatus>[];
    final verified = <String, bool>{};
    for (final pack in catalog.packs) {
      var available = 0;
      var stored = 0;
      final counted = <String>{};
      for (final asset in pack.assets) {
        final cached = verified[asset.sha256] ??= await _store.containsVerified(
          asset,
        );
        if (included.contains(asset.asset) || cached) {
          available += asset.bytes;
        }
        if (cached && counted.add(asset.sha256)) {
          stored += asset.bytes;
        }
      }
      result.add(
        HanokPackStatus(
          pack: pack,
          availableBytes: available,
          storedBytes: stored,
          isBundled: pack.assets.every((a) => included.contains(a.asset)),
          isDownloading:
              _packJobs.containsKey(pack.id) ||
              pack.assets.any((a) => _inflight.containsKey(a.sha256)),
          failure: _failures[pack.id],
        ),
      );
    }
    return result;
  }

  Future<void> removePack(String packId) {
    // Publish the barrier synchronously, before any cache reads or network waits.
    final prior = _removal;
    _epochs[packId] = _epoch(packId) + 1;
    final job = _remove(packId, prior);
    _removal = job;
    return job.whenComplete(() {
      if (identical(_removal, job)) {
        _removal = null;
      }
      _changed();
    });
  }

  Future<void> _remove(String packId, Future<void>? prior) async {
    if (prior != null) {
      await prior;
    }
    final catalog = await _catalog();
    final pack = catalog.packs.where((p) => p.id == packId).firstOrNull;
    if (pack == null) {
      throw const HanokAssetFailure(HanokAssetFailureKind.unknownAsset);
    }
    await _store.setPackReleased(packId, true);
    // Every transfer that could write is registered; stale queued pack steps fail
    // their epoch check. New public downloads wait for this removal barrier.
    await Future.wait(
      _inflight.values.map(
        (f) => f.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      ),
    );
    final packJob = _packJobs[packId];
    if (packJob != null) {
      await packJob.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    }
    final protected = <String>{};
    final released = await _store.releasedPacks();
    for (final status in await statuses()) {
      if (status.pack.id != packId &&
          status.isComplete &&
          !released.contains(status.pack.id)) {
        protected.addAll(status.pack.assets.map((a) => a.sha256));
      }
    }
    for (final asset in pack.assets) {
      if (!protected.contains(asset.sha256)) {
        await _store.remove(asset);
      }
    }
    _failures.remove(packId);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
