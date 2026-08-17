import 'package:flutter/material.dart';

import '../../data/a1_hanok_construction_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_growth.dart';
import 'tokens.dart';

/// QA-only 4:3 A1 construction renderer.
///
/// The only progress input is [HanokExperienceProjection.a1ConstructionStep].
/// Production routes must not import this widget until the PR6/PR7 cutover.
class A1HanokConstructionMap extends StatefulWidget {
  const A1HanokConstructionMap({
    super.key,
    required this.projection,
    this.semanticsLabel,
  });

  final HanokExperienceProjection projection;
  final String? semanticsLabel;

  @override
  State<A1HanokConstructionMap> createState() => A1HanokConstructionMapState();
}

class A1HanokConstructionMapState extends State<A1HanokConstructionMap> {
  final Map<String, ResizeImage> _providers = <String, ResizeImage>{};
  final Set<int> _seenCacheWidths = <int>{};
  int? _cacheWidth;

  @visibleForTesting
  List<String> get residentAssetPaths {
    final step = widget.projection.a1ConstructionStep;
    if (step < kA1HanokMinStep || step > kA1HanokMaxStep) {
      return const [];
    }
    return [
      for (final residentStep in a1HanokResidentSteps(step))
        a1HanokConstructionState(residentStep).assetPath,
    ];
  }

  @visibleForTesting
  List<ResizeImage> get residentProviders => [
    for (final path in residentAssetPaths)
      if (_providers[path] != null) _providers[path]!,
  ];

  @visibleForTesting
  int? get decodeCacheWidth => _cacheWidth;

  @override
  void dispose() {
    final step = widget.projection.a1ConstructionStep;
    final cacheWidth = _cacheWidth;
    if (cacheWidth != null) {
      _evictCatalogTargets(step: step, cacheWidth: cacheWidth);
    }
    for (final provider in _providers.values) {
      provider.evict();
    }
    _providers.clear();
    super.dispose();
  }

  void _evictCatalogTargets({
    required int step,
    required int cacheWidth,
  }) {
    if (step < kA1HanokMinStep || step > kA1HanokMaxStep) {
      return;
    }
    _seenCacheWidths.add(cacheWidth);
    final targets = a1HanokEvictionTargets(
      currentStep: step,
      seenCacheWidths: Set<int>.from(_seenCacheWidths),
      currentCacheWidth: cacheWidth,
    );
    for (final spec in targets) {
      _providerForSpec(spec).evict();
    }
  }

  ImageProvider _providerForSpec(A1HanokEvictionSpec spec) {
    final image = AssetImage(spec.path);
    final width = spec.cacheWidth;
    if (width == null) {
      return image;
    }
    return ResizeImage(image, width: width);
  }

  ResizeImage _resize(String path, int cacheWidth) {
    final existing = _providers[path];
    if (existing != null && _cacheWidth == cacheWidth) {
      return existing;
    }
    return ResizeImage(AssetImage(path), width: cacheWidth);
  }

  Map<String, ResizeImage> _providersFor(List<String> paths, int cacheWidth) {
    return {for (final path in paths) path: _resize(path, cacheWidth)};
  }

  void _scheduleProviderSync({
    required List<String> paths,
    required int cacheWidth,
    required Map<String, ResizeImage> next,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final stale = _providers.keys.where((path) => !paths.contains(path)).toList();
      final sizeChanged = _cacheWidth != cacheWidth;
      if (stale.isEmpty && !sizeChanged && _providers.length == next.length) {
        return;
      }
      if (_cacheWidth != null) {
        _seenCacheWidths.add(_cacheWidth!);
      }
      _seenCacheWidths.add(cacheWidth);
      _evictCatalogTargets(
        step: widget.projection.a1ConstructionStep,
        cacheWidth: cacheWidth,
      );
      for (final path in stale) {
        _providers.remove(path)?.evict();
      }
      if (sizeChanged) {
        for (final provider in _providers.values) {
          provider.evict();
        }
        _providers.clear();
      }
      _providers.addAll(next);
      _cacheWidth = cacheWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.projection.a1ConstructionStep;
    if (step < kA1HanokMinStep || step > kA1HanokMaxStep) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: _A1FailVisibleFallback(),
      );
    }

    final state = a1HanokConstructionState(step);
    final reduceMotion = SoriMotion.reduceMotion(context);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cacheWidth = a1HanokDecodeCacheWidth(
            displayWidth: width,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          );
          final paths = residentAssetPaths;
          final providers = _providersFor(paths, cacheWidth);
          _scheduleProviderSync(
            paths: paths,
            cacheWidth: cacheWidth,
            next: providers,
          );

          return Semantics(
            // Never fall back to state.id — TalkBack would read the raw asset
            // key ("08_purlins_sangnyang") aloud.
            label: widget.semanticsLabel ?? AppL10n.of(context).hanokA1MapLabel,
            image: true,
            child: ClipRRect(
              borderRadius: SoriRadius.brLg,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final path in paths)
                      if (path != state.assetPath)
                        Offstage(
                          child: Image(
                            image: providers[path]!,
                            fit: BoxFit.cover,
                            gaplessPlayback: false,
                            errorBuilder: (context, _, __) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                    AnimatedSwitcher(
                      duration: SoriMotion.respect(context, SoriMotion.medium),
                      switchInCurve: SoriMotion.gentle,
                      switchOutCurve: SoriMotion.gentle,
                      transitionBuilder: (child, animation) {
                        if (reduceMotion) {
                          return child;
                        }
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Image(
                        key: ValueKey('a1-hanok-state-${state.id}'),
                        image: providers[state.assetPath]!,
                        fit: BoxFit.cover,
                        width: width.isFinite ? width : null,
                        gaplessPlayback: false,
                        errorBuilder: (context, _, __) =>
                            const _A1FailVisibleFallback(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _A1FailVisibleFallback extends StatelessWidget {
  const _A1FailVisibleFallback();

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      label: AppL10n.of(context).hanokA1MapUnavailable,
      image: true,
      child: ColoredBox(
        color: surfaces.surfaceAlt,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            color: surfaces.textMuted,
            size: 48,
          ),
        ),
      ),
    );
  }
}
