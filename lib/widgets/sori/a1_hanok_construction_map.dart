import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/a1_hanok_construction_catalog.dart';
import '../../models/hanok_growth.dart';
import 'tokens.dart';

typedef A1HanokImageProviderBuilder =
    ImageProvider<Object> Function(
      A1HanokConstructionState state,
      int cacheWidth,
      int cacheHeight,
    );

/// Renders the cumulative A1 construction state from the canonical Hanok
/// experience projection.
///
/// This widget owns no progress or reward state. It retains only the previous,
/// current, and next decoded image providers and evicts providers outside that
/// window. Production navigation adopts it only after the complete cutover.
class A1HanokConstructionMap extends StatefulWidget {
  const A1HanokConstructionMap({
    super.key,
    required this.projection,
    required this.semanticsLabel,
    required this.missingAssetLabel,
    this.imageProviderBuilder = _defaultImageProviderBuilder,
    this.transitionDuration = const Duration(milliseconds: 280),
  });

  final HanokExperienceProjection projection;
  final String semanticsLabel;
  final String missingAssetLabel;
  final A1HanokImageProviderBuilder imageProviderBuilder;
  final Duration transitionDuration;

  @override
  State<A1HanokConstructionMap> createState() => _A1HanokConstructionMapState();
}

class _A1HanokConstructionMapState extends State<A1HanokConstructionMap> {
  final Map<int, ImageProvider<Object>> _providersByStep = {};
  String? _scheduledWindowSignature;
  int _cacheGeneration = 0;
  int? _cacheWidth;
  int? _cacheHeight;

  @override
  void didUpdateWidget(covariant A1HanokConstructionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProviderBuilder != widget.imageProviderBuilder) {
      _evictAllProviders();
      _scheduledWindowSignature = null;
    }
  }

  @override
  void dispose() {
    _cacheGeneration += 1;
    _evictAllProviders();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = a1HanokConstructionStateForStep(
      widget.projection.a1ConstructionStep,
    );
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cacheSize = _cacheSizeFor(context, constraints);
          _ensureCacheDimensions(cacheSize.$1, cacheSize.$2);
          _scheduleDecodeWindow(
            context,
            state.step,
            cacheSize.$1,
            cacheSize.$2,
          );
          final provider = _providerFor(state, cacheSize.$1, cacheSize.$2);
          final transitionDuration = MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : widget.transitionDuration;
          return Semantics(
            key: const ValueKey('a1-hanok-construction-semantics'),
            label: widget.semanticsLabel,
            image: true,
            child: ClipRRect(
              borderRadius: SoriRadius.brLg,
              child: AnimatedSwitcher(
                duration: transitionDuration,
                reverseDuration: transitionDuration,
                child: Image(
                  key: ValueKey('a1-hanok-construction-${state.id}'),
                  image: provider,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return ColoredBox(
                          color: SoriSurfaces.of(context).surfaceAlt,
                        );
                      },
                  errorBuilder: (context, error, stackTrace) {
                    return _MissingConstructionAsset(
                      label: widget.missingAssetLabel,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  (int, int) _cacheSizeFor(BuildContext context, BoxConstraints constraints) {
    final logicalWidth =
        constraints.maxWidth.isFinite && constraints.maxWidth > 0
        ? constraints.maxWidth
        : kA1HanokCanvasWidth.toDouble();
    final physicalWidth =
        (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
    final cacheWidth = math.min(
      kA1HanokCanvasWidth,
      math.max(1, physicalWidth),
    );
    final cacheHeight = math.min(
      kA1HanokCanvasHeight,
      math.max(1, (cacheWidth * 3 / 4).round()),
    );
    return (cacheWidth, cacheHeight);
  }

  ImageProvider<Object> _providerFor(
    A1HanokConstructionState state,
    int cacheWidth,
    int cacheHeight,
  ) {
    return _providersByStep.putIfAbsent(
      state.step,
      () => widget.imageProviderBuilder(state, cacheWidth, cacheHeight),
    );
  }

  void _ensureCacheDimensions(int cacheWidth, int cacheHeight) {
    if (_cacheWidth == cacheWidth && _cacheHeight == cacheHeight) {
      return;
    }
    _evictAllProviders();
    _cacheWidth = cacheWidth;
    _cacheHeight = cacheHeight;
  }

  void _scheduleDecodeWindow(
    BuildContext context,
    int step,
    int cacheWidth,
    int cacheHeight,
  ) {
    final signature = '$step:$cacheWidth:$cacheHeight';
    if (_scheduledWindowSignature == signature) {
      return;
    }
    _scheduledWindowSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledWindowSignature != signature) {
        return;
      }
      unawaited(_refreshDecodeWindow(context, step, cacheWidth, cacheHeight));
    });
  }

  Future<void> _refreshDecodeWindow(
    BuildContext context,
    int step,
    int cacheWidth,
    int cacheHeight,
  ) async {
    final generation = ++_cacheGeneration;
    final desiredStates = a1HanokDecodeWindowForStep(step);
    final desiredSteps = desiredStates.map((state) => state.step).toSet();

    final staleSteps = _providersByStep.keys
        .where((candidate) => !desiredSteps.contains(candidate))
        .toList(growable: false);
    for (final staleStep in staleSteps) {
      final staleProvider = _providersByStep.remove(staleStep);
      if (staleProvider != null) {
        unawaited(staleProvider.evict());
      }
    }

    final providers = <MapEntry<int, ImageProvider<Object>>>[];
    for (final desiredState in desiredStates) {
      providers.add(
        MapEntry(
          desiredState.step,
          _providerFor(desiredState, cacheWidth, cacheHeight),
        ),
      );
    }

    await Future.wait(
      providers.map(
        (entry) => precacheImage(
          entry.value,
          context,
          onError: (error, stackTrace) {},
        ),
      ),
    );
    if (!mounted || generation != _cacheGeneration) {
      for (final entry in providers) {
        if (!_providersByStep.containsKey(entry.key)) {
          unawaited(entry.value.evict());
        }
      }
    }
  }

  void _evictAllProviders() {
    _cacheGeneration += 1;
    final providers = _providersByStep.values.toList(growable: false);
    _providersByStep.clear();
    for (final provider in providers) {
      unawaited(provider.evict());
    }
  }
}

class _MissingConstructionAsset extends StatelessWidget {
  const _MissingConstructionAsset({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return ColoredBox(
      key: const ValueKey('a1-hanok-construction-missing-asset'),
      color: surfaces.surfaceAlt,
      child: Center(
        child: Semantics(
          label: label,
          child: Icon(
            Icons.broken_image_outlined,
            color: surfaces.textMuted,
            size: 40,
          ),
        ),
      ),
    );
  }
}

ImageProvider<Object> _defaultImageProviderBuilder(
  A1HanokConstructionState state,
  int cacheWidth,
  int cacheHeight,
) {
  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    AssetImage(state.assetPath),
  );
}
