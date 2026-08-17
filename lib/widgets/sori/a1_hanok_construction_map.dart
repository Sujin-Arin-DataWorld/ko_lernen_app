import 'package:flutter/material.dart';

import '../../data/a1_hanok_construction_catalog.dart';
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
  int? get decodeCacheWidth => _cacheWidth;

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
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final cacheWidth = a1HanokDecodeCacheWidth(
            displayWidth: width,
            devicePixelRatio: dpr,
          );
          _cacheWidth = cacheWidth;

          return Semantics(
            label: widget.semanticsLabel ?? state.id,
            image: true,
            child: ClipRRect(
              borderRadius: SoriRadius.brLg,
              child: RepaintBoundary(
                child: AnimatedSwitcher(
                  duration: SoriMotion.respect(context, SoriMotion.medium),
                  switchInCurve: SoriMotion.gentle,
                  switchOutCurve: SoriMotion.gentle,
                  transitionBuilder: (child, animation) {
                    if (reduceMotion) {
                      return child;
                    }
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Image.asset(
                    key: ValueKey('a1-hanok-state-${state.id}'),
                    state.assetPath,
                    fit: BoxFit.cover,
                    width: width.isFinite ? width : null,
                    cacheWidth: cacheWidth,
                    gaplessPlayback: false,
                    errorBuilder: (context, _, __) =>
                        const _A1FailVisibleFallback(),
                  ),
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
    return ColoredBox(
      color: surfaces.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          color: surfaces.textMuted,
          size: 48,
        ),
      ),
    );
  }
}
