import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/hanok_assets/hanok_asset_delivery.dart';
import 'sori/button.dart';
import 'sori/tokens.dart';

/// Displays bundled Hanok artwork immediately and falls back to verified
/// downloaded bytes when a hybrid build omits the source asset.
class HanokAssetImage extends StatefulWidget {
  const HanokAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.errorBuilder,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.prefetchPack = true,
    this.delivery,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final int? cacheWidth;
  final int? cacheHeight;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final ImageErrorWidgetBuilder? errorBuilder;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final bool prefetchPack;
  final HanokAssetDelivery? delivery;

  @override
  State<HanokAssetImage> createState() => _HanokAssetImageState();
}

enum _HanokImageState { bundled, loading, explicitAction, failed, ready }

typedef _HanokCachedListener = void Function(Uint8List bytes);

final HashMap<HanokAssetDelivery, _HanokCacheMonitor> _hanokCacheMonitors =
    HashMap<HanokAssetDelivery, _HanokCacheMonitor>.identity();

VoidCallback _watchHanokCache(
  HanokAssetDelivery delivery,
  String assetPath,
  _HanokCachedListener listener,
) {
  final monitor = _hanokCacheMonitors.putIfAbsent(
    delivery,
    () => _HanokCacheMonitor(delivery),
  );
  monitor.add(assetPath, listener);
  return () {
    monitor.remove(assetPath, listener);
    if (monitor.isEmpty && identical(_hanokCacheMonitors[delivery], monitor)) {
      _hanokCacheMonitors.remove(delivery);
      monitor.dispose();
    }
  };
}

/// Coalesces delivery notifications and probes only paths currently waiting
/// for an externally completed, verified cache entry.
class _HanokCacheMonitor {
  _HanokCacheMonitor(this.delivery) {
    delivery.addListener(_deliveryChanged);
  }

  final HanokAssetDelivery delivery;
  final Map<String, Set<_HanokCachedListener>> _listeners =
      <String, Set<_HanokCachedListener>>{};
  Future<void>? _refreshJob;
  bool _refreshPending = false;
  bool _disposed = false;

  bool get isEmpty => _listeners.isEmpty;

  void add(String assetPath, _HanokCachedListener listener) {
    (_listeners[assetPath] ??= <_HanokCachedListener>{}).add(listener);
    unawaited(_refresh());
  }

  void remove(String assetPath, _HanokCachedListener listener) {
    final listeners = _listeners[assetPath];
    listeners?.remove(listener);
    if (listeners?.isEmpty ?? false) {
      _listeners.remove(assetPath);
    }
  }

  void _deliveryChanged() => unawaited(_refresh());

  Future<void> _refresh() {
    if (_disposed) {
      return Future<void>.value();
    }
    _refreshPending = true;
    final active = _refreshJob;
    if (active != null) {
      return active;
    }
    final job = _drainRefreshes();
    _refreshJob = job;
    return job.whenComplete(() {
      if (identical(_refreshJob, job)) {
        _refreshJob = null;
      }
    });
  }

  Future<void> _drainRefreshes() async {
    while (_refreshPending && !_disposed) {
      _refreshPending = false;
      final paths = _listeners.keys.toList(growable: false);
      for (final assetPath in paths) {
        Uint8List? bytes;
        try {
          bytes = await delivery.readCached(assetPath);
        } catch (_) {
          // Removal races and storage failures remain ordinary cache misses.
        }
        if (_disposed) {
          return;
        }
        if (bytes == null) {
          continue;
        }
        final listeners = _listeners[assetPath]?.toList(growable: false);
        if (listeners == null) {
          continue;
        }
        for (final listener in listeners) {
          listener(bytes);
          if (_disposed) {
            return;
          }
        }
      }
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    delivery.removeListener(_deliveryChanged);
    _listeners.clear();
  }
}

class _HanokAssetImageState extends State<HanokAssetImage> {
  _HanokImageState _state = _HanokImageState.bundled;
  Uint8List? _bytes;
  Object? _error;
  StackTrace? _stackTrace;
  int _generation = 0;
  bool _loadScheduled = false;
  bool _allowMobileData = false;
  VoidCallback? _stopWatchingCache;

  HanokAssetDelivery get _delivery =>
      widget.delivery ?? HanokAssetDelivery.shared;

  @override
  void didUpdateWidget(covariant HanokAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.delivery != widget.delivery ||
        oldWidget.prefetchPack != widget.prefetchPack) {
      _stopWatchingExternalCompletion();
      _generation++;
      _loadScheduled = false;
      _allowMobileData = false;
      _bytes = null;
      _error = null;
      _stackTrace = null;
      _state = _HanokImageState.bundled;
    }
  }

  @override
  void dispose() {
    _stopWatchingExternalCompletion();
    super.dispose();
  }

  void _scheduleFallback() {
    if (_loadScheduled || _state != _HanokImageState.bundled) {
      return;
    }
    _loadScheduled = true;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) {
        return;
      }
      _loadScheduled = false;
      _load(generation: generation, allowMobileData: false);
    });
  }

  Future<void> _load({
    required int generation,
    required bool allowMobileData,
  }) async {
    _stopWatchingExternalCompletion();
    final source = _delivery;
    final assetPath = widget.assetPath;
    setState(() {
      _state = _HanokImageState.loading;
      _bytes = null;
      _error = null;
      _stackTrace = null;
      _allowMobileData = allowMobileData;
    });
    try {
      final bytes = await source.load(
        assetPath,
        allowMobileData: allowMobileData,
        prefetchPack: widget.prefetchPack,
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _state = _HanokImageState.ready;
      });
    } on HanokAssetFailure catch (error, stackTrace) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
        _state = error.kind == HanokAssetFailureKind.explicitDownloadNeeded
            ? _HanokImageState.explicitAction
            : _HanokImageState.failed;
      });
      _watchExternalCompletion();
    } catch (error, stackTrace) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
        _state = _HanokImageState.failed;
      });
      _watchExternalCompletion();
    }
  }

  void _watchExternalCompletion() {
    if (_stopWatchingCache != null) {
      return;
    }
    final source = _delivery;
    final assetPath = widget.assetPath;
    final generation = _generation;
    _stopWatchingCache = _watchHanokCache(source, assetPath, (bytes) {
      if (!mounted ||
          generation != _generation ||
          !identical(source, _delivery) ||
          assetPath != widget.assetPath ||
          (_state != _HanokImageState.explicitAction &&
              _state != _HanokImageState.failed)) {
        return;
      }
      _stopWatchingExternalCompletion();
      setState(() {
        _bytes = bytes;
        _error = null;
        _stackTrace = null;
        _state = _HanokImageState.ready;
      });
    });
  }

  void _stopWatchingExternalCompletion() {
    final stop = _stopWatchingCache;
    _stopWatchingCache = null;
    stop?.call();
  }

  void _retry({bool? allowMobileData}) {
    _load(
      generation: _generation,
      allowMobileData: allowMobileData ?? _allowMobileData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _HanokImageState.bundled => Image.asset(
        widget.assetPath,
        key: ValueKey('hanok-asset-bundle-${widget.assetPath}'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.excludeFromSemantics,
        filterQuality: widget.filterQuality,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: (context, error, stackTrace) {
          _scheduleFallback();
          return _HanokImageMessage(
            width: widget.width,
            height: widget.height,
            key: ValueKey('hanok-asset-loading-${widget.assetPath}'),
            icon: Icons.downloading_rounded,
            message: AppL10n.of(context).hanokAssetsImageLoading,
          );
        },
      ),
      _HanokImageState.loading => _HanokImageMessage(
        width: widget.width,
        height: widget.height,
        key: ValueKey('hanok-asset-loading-${widget.assetPath}'),
        icon: Icons.downloading_rounded,
        message: AppL10n.of(context).hanokAssetsImageLoading,
      ),
      _HanokImageState.explicitAction => _HanokImageMessage(
        width: widget.width,
        height: widget.height,
        key: ValueKey('hanok-asset-explicit-${widget.assetPath}'),
        icon: Icons.signal_cellular_alt_rounded,
        message: AppL10n.of(context).hanokAssetsCellularNeeded,
        action: SoriButton.outlined(
          key: ValueKey('hanok-asset-download-${widget.assetPath}'),
          label: AppL10n.of(context).hanokAssetsDownloadNow,
          onTap: () => _retry(allowMobileData: true),
        ),
      ),
      _HanokImageState.failed => _failure(context),
      _HanokImageState.ready => Image.memory(
        _bytes!,
        key: ValueKey('hanok-asset-memory-${widget.assetPath}'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.excludeFromSemantics,
        filterQuality: widget.filterQuality,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.errorBuilder,
      ),
    };
  }

  Widget _failure(BuildContext context) {
    final error = _error;
    if (error is HanokAssetFailure &&
        error.kind == HanokAssetFailureKind.unknownAsset &&
        widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, _stackTrace);
    }
    return _HanokImageMessage(
      width: widget.width,
      height: widget.height,
      key: ValueKey('hanok-asset-failed-${widget.assetPath}'),
      icon: Icons.broken_image_outlined,
      message: _failureMessage(context, error),
      action: SoriButton.outlined(
        key: ValueKey('hanok-asset-retry-${widget.assetPath}'),
        label: AppL10n.of(context).hanokAssetsRetry,
        onTap: _retry,
      ),
    );
  }

  String _failureMessage(BuildContext context, Object? error) {
    final t = AppL10n.of(context);
    if (error is! HanokAssetFailure) {
      return t.hanokAssetsImageFailed;
    }
    return switch (error.kind) {
      HanokAssetFailureKind.cacheFull => t.hanokAssetsStorageFull,
      HanokAssetFailureKind.network => t.hanokAssetsNetworkFailed,
      HanokAssetFailureKind.corrupt ||
      HanokAssetFailureKind.storage ||
      HanokAssetFailureKind.removed ||
      HanokAssetFailureKind.unknownAsset ||
      HanokAssetFailureKind.explicitDownloadNeeded => t.hanokAssetsImageFailed,
    };
  }
}

class _HanokImageMessage extends StatelessWidget {
  const _HanokImageMessage({
    super.key,
    required this.icon,
    required this.message,
    this.width,
    this.height,
    this.action,
  });

  final IconData icon;
  final String message;
  final double? width;
  final double? height;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: SoriSurfaces.of(context).surfaceAlt,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.hasBoundedHeight && constraints.maxHeight < 112;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: compact ? 20 : 28),
                    if (!compact) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                    ],
                    if (action != null) ...[
                      SizedBox(height: compact ? 2 : Spacing.xs),
                      action!,
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
