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
  final ValueChanged<PersonalHanokZone>? onTapZone;

  const PersonalHanokMap({
    super.key,
    required this.projection,
    required this.zoneLabel,
    this.onTapZone,
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
        child: MadangBackground(stage: projection.legacyStage),
      );
    }

    final layers = kPersonalHanokLayers
        .where(
          (layer) =>
              layer.opaque ||
              (layer.milestone != null && projection.isUnlocked(layer.milestone!)),
        )
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: SoriRadius.brLg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final layer in layers)
                  Image.asset(
                    layer.assetPath,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, _, __) => layer.opaque
                        ? ColoredBox(color: SoriSurfaces.of(ctx).surfaceAlt)
                        : const SizedBox.expand(),
                  ),
                for (final definition in kPersonalHanokZones)
                  if (_isVisible(definition))
                    _ZoneTarget(
                      definition: definition,
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

  bool _isVisible(PersonalHanokZoneDefinition definition) {
    final required = definition.requires;
    return definition.isInteractive &&
        required != null &&
        projection.isUnlocked(required);
  }
}

class _ZoneTarget extends StatelessWidget {
  final PersonalHanokZoneDefinition definition;
  final Size canvasSize;
  final String label;
  final VoidCallback? onTap;

  const _ZoneTarget({
    required this.definition,
    required this.canvasSize,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rect = definition.bounds;
    final width =
        (canvasSize.width * rect.width).clamp(44.0, canvasSize.width).toDouble();
    final height =
        (canvasSize.height * rect.height).clamp(44.0, canvasSize.height).toDouble();
    final left = (canvasSize.width * rect.left)
        .clamp(0.0, canvasSize.width - width)
        .toDouble();
    final top = (canvasSize.height * rect.top)
        .clamp(0.0, canvasSize.height - height)
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: onTap != null,
        label: label,
        child: GestureDetector(
          key: ValueKey('personal-hanok-zone-${definition.zone.name}'),
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
