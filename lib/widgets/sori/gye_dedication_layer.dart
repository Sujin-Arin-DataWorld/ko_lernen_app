import 'package:flutter/material.dart';

import '../../data/gye_dedication_catalog.dart';
import '../../models/gye_dedication.dart';
import 'placed_decoration.dart';

/// Passive foreground layer for the shared Gye exhibition.
///
/// It does not read local ownership, route, or mutate anything. The Gye
/// screen owns the stream and the callable-only confirmation flow.
class GyeDedicationLayer extends StatelessWidget {
  final Iterable<GyeDedication> dedications;

  const GyeDedicationLayer({super.key, required this.dedications});

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeGyeDedications(dedications);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          children: [
            for (final dedication in normalized)
              _exhibit(
                dedication,
                kGyeDedicationSlots[dedication.slotIndex],
                width,
                height,
              ),
          ],
        );
      },
    );
  }

  Widget _exhibit(
    GyeDedication dedication,
    GyeDedicationSlot slot,
    double canvasWidth,
    double canvasHeight,
  ) {
    final size = canvasWidth * slot.width;
    return Positioned(
      left: canvasWidth * slot.left,
      bottom: canvasHeight * slot.bottom,
      width: size,
      height: size,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SoriDecorationImage(
              slug: dedication.decorationSlug,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
