import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/tokens.dart';

/// Read-only onboarding preview of one visible Hanok construction change.
///
/// This widget does not read or write progression, grants, or lesson evidence.
class OnboardingHanokGrowthPreview extends StatelessWidget {
  const OnboardingHanokGrowthPreview({super.key, this.complete = false});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth * 3 / 4;
        final width = math
            .min(math.min(availableWidth, availableHeight * 4 / 3), 360.0)
            .toDouble();
        return Center(
          child: SizedBox(
            key: const ValueKey('onboarding-v2-hanok-growth-preview'),
            width: width,
            height: width * 3 / 4,
            child: ClipRRect(
              borderRadius: SoriRadius.brMd,
              child: KeyedSubtree(
                key: ValueKey(
                  complete
                      ? 'onboarding-v2-hanok-growth-after'
                      : 'onboarding-v2-hanok-growth-before',
                ),
                child: HanokV3Preview(message: t.soriStageHanokUpdating),
              ),
            ),
          ),
        );
      },
    );
  }
}
