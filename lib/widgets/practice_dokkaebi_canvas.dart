import 'package:flutter/material.dart';

import 'practice_dokkaebi_art.dart';

/// One stable coordinate system for the approved posters and both MP4s.
/// The crop removes only empty matte: every measured foreground frame from
/// both provenance manifests fits inside this rectangle with a safety inset.
class PracticeDokkaebiCanvas extends StatelessWidget {
  const PracticeDokkaebiCanvas({super.key, required this.child});
  final Widget child;

  static const sourceSize = 1200.0;
  static const viewport = Rect.fromLTWH(120, 56, 984, 1088);
  static const aspectRatio = 984 / 1088;
  static const contact = Offset(
    (1200 * .838 - 120) / 984,
    (1200 * .921 - 56) / 1088,
  );

  @override
  Widget build(BuildContext context) => ClipRect(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: viewport.width,
        height: viewport.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -viewport.left,
              top: -viewport.top,
              width: sourceSize,
              height: sourceSize,
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Match the PNG's visible body and floor to the film's resting body, rather
/// than filling its entire motion envelope with a much larger static figure.
class PracticeDokkaebiRestingArt extends StatelessWidget {
  const PracticeDokkaebiRestingArt({super.key, required this.pose});
  final PracticeDokkaebiPose pose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned(
          top: constraints.maxHeight * .37,
          bottom: constraints.maxHeight * .022,
          left: constraints.maxWidth * .12,
          right: constraints.maxWidth * .12,
          child: PracticeDokkaebiArt(pose: pose),
        ),
      ],
    ),
  );
}
