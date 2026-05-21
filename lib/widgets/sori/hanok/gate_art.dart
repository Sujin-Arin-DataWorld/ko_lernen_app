import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layered sotdae-mun gate art.
///
/// The three PNGs share the 1080 x 1920 registration space described in
/// docs/living-hanok-assets.md. Door transforms are applied around their hinge
/// edges so the same widget can be used as a static preview or as the intro
/// opening animation.
class HanokGateArt extends StatelessWidget {
  final double openAmount;
  final FilterQuality filterQuality;

  const HanokGateArt({
    super.key,
    this.openAmount = 0,
    this.filterQuality = FilterQuality.medium,
  });

  static const frameAsset = 'assets/illustrations/hanok/gate_frame.png';
  static const leftDoorAsset = 'assets/illustrations/hanok/gate_door_left.png';
  static const rightDoorAsset =
      'assets/illustrations/hanok/gate_door_right.png';

  static const _sourceW = 1080.0;
  static const _sourceH = 1920.0;
  static const _doorLeft = 195.0 / _sourceW;
  static const _doorTop = 615.0 / _sourceH;
  static const _doorW = 345.0 / _sourceW;
  static const _doorH = 1000.0 / _sourceH;
  static const _doorRightLeft = 540.0 / _sourceW;

  @override
  Widget build(BuildContext context) {
    final open = openAmount.clamp(0.0, 1.0);
    final angle = open * math.pi * 0.48;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: w * _doorLeft,
              top: h * _doorTop,
              width: w * _doorW,
              height: h * _doorH,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateY(-angle),
                child: Image.asset(
                  leftDoorAsset,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                ),
              ),
            ),
            Positioned(
              left: w * _doorRightLeft,
              top: h * _doorTop,
              width: w * _doorW,
              height: h * _doorH,
              child: Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateY(angle),
                child: Image.asset(
                  rightDoorAsset,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                frameAsset,
                fit: BoxFit.fill,
                filterQuality: filterQuality,
              ),
            ),
          ],
        );
      },
    );
  }
}
