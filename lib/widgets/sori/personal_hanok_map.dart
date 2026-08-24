import 'package:flutter/material.dart';

import '../../data/personal_hanok_catalog.dart';
import '../../models/personal_hanok.dart';
import 'madang_background.dart';
import 'tokens.dart';

/// Renders the user's personal Hanok as a pure projection of earned progress.
///
/// It owns no storage, rewards, or navigation policy. Callers supply localized
/// zone labels and decide what a location opens. Before B1 25% it deliberately
/// preserves the existing portrait [MadangBackground] experience.
class PersonalHanokMap extends StatelessWidget {
  final PersonalHanokProjection projection;
  final String Function(PersonalHanokZone zone) zoneLabel;
  final String Function(PersonalHanokZone zone)? mapPlaceLabel;
  final ValueChanged<PersonalHanokZone>? onTapZone;
  final bool showTargets;
  final PersonalHanokZone? selectedZone;
  final PersonalHanokZone? todayZone;
  final String? todayMarkerLabel;

  /// Allows a one-off construction reveal to paint its active layer itself.
  /// The map remains a pure projection and performs no persistence or timing.
  final Set<PersonalHanokMilestone> suppressedMilestones;

  const PersonalHanokMap({
    super.key,
    required this.projection,
    required this.zoneLabel,
    this.mapPlaceLabel,
    this.onTapZone,
    this.showTargets = true,
    this.selectedZone,
    this.todayZone,
    this.todayMarkerLabel,
    this.suppressedMilestones = const <PersonalHanokMilestone>{},
  });

  @override
  Widget build(BuildContext context) {
    if (!projection.usesCompoundMap) {
      // The legacy stage art is portrait, but this public map widget is also
      // embedded in scrolling/zooming views. Give that fallback the same
      // finite 4:3 viewport contract as the compound map so `Stack.expand`
      // never receives an unbounded ListView height.
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: MadangBackground(stage: projection.structureStage),
      );
    }

    final layers =
        kPersonalHanokLayers
            .where(
              (layer) =>
                  layer.opaque ||
                  (layer.milestone != null &&
                      projection.isUnlocked(layer.milestone!) &&
                      !suppressedMilestones.contains(layer.milestone!)),
            )
            .toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 레이어 PNG 를 맵 표시 폭으로만 디코드하되, 마스터 캔버스와 디코드
          // 메모리 예산 둘 다로 상한을 건다. 예산 상한이 없으면 큰 화면·높은
          // dpr 에서 8 레이어가 runtimeLimits.decodedMemoryMaxBytes 를 넘긴다
          // (태블릿 620dp·dpr2 에서 35.2 MiB, 캡 32 MiB).
          // 리빌 중에는 억제된 레이어를 리빌 위젯이 따로 그리므로 그 몫까지
          // 예산에 넣는다.
          final w = constraints.maxWidth;
          final cacheW = personalHanokDecodeCacheWidth(
            displayWidth: w,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            layerCount: layers.length + suppressedMilestones.length,
          );
          return ClipRRect(
            borderRadius: SoriRadius.brLg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final layer in layers)
                  _MapLayerImage(
                    layer: layer,
                    cacheWidth: cacheW,
                    canvasHeight: constraints.maxHeight,
                  ),
                if (selectedZone != null &&
                    visiblePersonalHanokZones(
                      projection,
                    ).any((definition) => definition.zone == selectedZone))
                  _ZoneFocus(
                    rect: zoneFor(selectedZone!).bounds,
                    canvasSize: constraints.biggest,
                  ),
                if (todayZone != null &&
                    todayMarkerLabel != null &&
                    visiblePersonalHanokZones(
                      projection,
                    ).any((definition) => definition.zone == todayZone))
                  _TodayStudyMarker(
                    rect: zoneFor(todayZone!).bounds,
                    canvasSize: constraints.biggest,
                    label: todayMarkerLabel!,
                  ),
                if (mapPlaceLabel != null)
                  for (final definition in visiblePersonalHanokZones(
                    projection,
                  ))
                    _MapPlaceLabel(
                      zone: definition.zone,
                      canvasSize: constraints.biggest,
                      label: mapPlaceLabel!(definition.zone),
                    ),
                if (showTargets)
                  for (final definition in visiblePersonalHanokZones(
                    projection,
                  ))
                    for (
                      var targetIndex = 0;
                      targetIndex < definition.hitRegions.length;
                      targetIndex++
                    )
                      _ZoneTarget(
                        definition: definition,
                        rect: definition.hitRegions[targetIndex],
                        targetIndex: targetIndex,
                        canvasSize: constraints.biggest,
                        label: zoneLabel(definition.zone),
                        onTap: onTapZone == null
                            ? null
                            : () => onTapZone!(definition.zone),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapPlaceLabel extends StatelessWidget {
  final PersonalHanokZone zone;
  final Size canvasSize;
  final String label;

  const _MapPlaceLabel({
    required this.zone,
    required this.canvasSize,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final anchor = switch (zone) {
      PersonalHanokZone.huwon => const Offset(.18, .11),
      PersonalHanokZone.anchae => const Offset(.31, .35),
      PersonalHanokZone.daecheongmaru => const Offset(.57, .23),
      PersonalHanokZone.sadang => const Offset(.84, .28),
      PersonalHanokZone.sarangbang => const Offset(.50, .59),
      PersonalHanokZone.haengrangchae => const Offset(.23, .84),
      PersonalHanokZone.gyeRoad => const Offset(.91, .77),
    };
    final width = (canvasSize.width * .27).clamp(72.0, 112.0).toDouble();
    const height = 38.0;
    final left = (canvasSize.width * anchor.dx - width / 2)
        .clamp(2.0, canvasSize.width - width - 2)
        .toDouble();
    final top = (canvasSize.height * anchor.dy - height / 2)
        .clamp(2.0, canvasSize.height - height - 2)
        .toDouble();
    final surfaces = SoriSurfaces.of(context);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Container(
            key: ValueKey('personal-hanok-map-label-${zone.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surfaces.surface.withValues(alpha: .92),
              borderRadius: SoriRadius.brSm,
              border: Border.all(
                color: SoriColors.primary.withValues(alpha: .48),
              ),
              boxShadow: SoriElevation.low,
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: surfaces.text,
                fontSize: 9,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneFocus extends StatelessWidget {
  final PersonalHanokRect rect;
  final Size canvasSize;

  const _ZoneFocus({required this.rect, required this.canvasSize});

  @override
  Widget build(BuildContext context) {
    final left = canvasSize.width * rect.left;
    final top = canvasSize.height * rect.top;
    final width = canvasSize.width * rect.width;
    final height = canvasSize.height * rect.height;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SoriColors.primary.withValues(alpha: 0.05),
            border: Border.all(
              color: SoriColors.primary.withValues(alpha: 0.84),
              width: 2,
            ),
            borderRadius: SoriRadius.brSm,
          ),
        ),
      ),
    );
  }
}

class _TodayStudyMarker extends StatelessWidget {
  final PersonalHanokRect rect;
  final Size canvasSize;
  final String label;

  const _TodayStudyMarker({
    required this.rect,
    required this.canvasSize,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const markerSize = 24.0;
    final left = (canvasSize.width * (rect.left + rect.width) - markerSize / 2)
        .clamp(0.0, canvasSize.width - markerSize)
        .toDouble();
    final top = (canvasSize.height * rect.top - markerSize / 2)
        .clamp(0.0, canvasSize.height - markerSize)
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: markerSize,
      height: markerSize,
      child: IgnorePointer(
        child: Semantics(
          label: label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SoriColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: SoriElevation.low,
            ),
            child: const Center(
              child: SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneTarget extends StatelessWidget {
  final PersonalHanokZoneDefinition definition;
  final PersonalHanokRect rect;
  final int targetIndex;
  final Size canvasSize;
  final String label;
  final VoidCallback? onTap;

  const _ZoneTarget({
    required this.definition,
    required this.rect,
    required this.targetIndex,
    required this.canvasSize,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawWidth = canvasSize.width * rect.width;
    final rawHeight = canvasSize.height * rect.height;
    final width = rawWidth.clamp(48.0, canvasSize.width).toDouble();
    final height = rawHeight.clamp(48.0, canvasSize.height).toDouble();
    // The right Anchae wing sits between Daecheongmaru and Sadang. Grow its
    // narrow target equally in both directions to keep clearance on both sides.
    final growsAroundCenter =
        definition.zone == PersonalHanokZone.anchae && targetIndex > 0;
    final leftExpansion = growsAroundCenter ? (rawWidth - width) / 2 : 0.0;
    final left = (canvasSize.width * rect.left + leftExpansion)
        .clamp(0.0, canvasSize.width - width)
        .toDouble();
    // On the narrow estate map Sarangbang and Huwon each sit directly above
    // another place. Grow those 48dp targets upward so all targets stay full
    // sized without stealing taps from the place below.
    final growsUpward =
        definition.zone == PersonalHanokZone.sarangbang ||
        definition.zone == PersonalHanokZone.huwon;
    final topExpansion = growsUpward ? rawHeight - height : 0.0;
    final top = (canvasSize.height * rect.top + topExpansion)
        .clamp(0.0, canvasSize.height - height)
        .toDouble();

    final target = GestureDetector(
      key: ValueKey(
        targetIndex == 0
            ? 'personal-hanok-zone-${definition.zone.name}'
            : 'personal-hanok-zone-${definition.zone.name}-$targetIndex',
      ),
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: const SizedBox.expand(),
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: targetIndex == 0
          ? Semantics(
              button: onTap != null,
              label: label,
              onTap: onTap,
              child: ExcludeSemantics(child: target),
            )
          : ExcludeSemantics(child: target),
    );
  }
}

/// One estate art layer, optionally nudged on the master canvas.
///
/// [PersonalHanokMapLayer.canvasOffsetY] is expressed in 1536 × 1152
/// master-canvas pixels, so it has to be scaled to whatever height the map
/// is actually drawn at. A zero offset builds the plain [Image.asset] with
/// no wrapper, keeping the render path identical for every layer that does
/// not opt in.
class _MapLayerImage extends StatelessWidget {
  final PersonalHanokMapLayer layer;
  final int? cacheWidth;
  final double canvasHeight;

  const _MapLayerImage({
    required this.layer,
    required this.cacheWidth,
    required this.canvasHeight,
  });

  static const double _masterCanvasHeight = 1152;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      key: ValueKey('personal-hanok-layer-${layer.id}'),
      layer.assetPath,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (ctx, _, __) => layer.opaque
          ? ColoredBox(color: SoriSurfaces.of(ctx).surfaceAlt)
          : const SizedBox.expand(),
    );
    if (layer.canvasOffsetY == 0 ||
        !canvasHeight.isFinite ||
        canvasHeight <= 0) {
      return image;
    }
    final dy = layer.canvasOffsetY * canvasHeight / _masterCanvasHeight;
    return Transform.translate(offset: Offset(0, dy), child: image);
  }
}
