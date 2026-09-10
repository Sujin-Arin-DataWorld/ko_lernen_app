import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/tokens.dart';

const _beforeAsset =
    'assets/illustrations/personal_hanok_v2/a1/states/14_ondol_maru.webp';
const _afterAsset =
    'assets/illustrations/personal_hanok_v2/a1/states/15_changho_finish.webp';

/// Read-only onboarding preview of one visible Hanok construction change.
///
/// This widget does not read or write progression, grants, or lesson evidence.
class OnboardingHanokGrowthPreview extends StatelessWidget {
  const OnboardingHanokGrowthPreview({super.key, this.complete = false});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 420),
    );
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
        final height = width * 3 / 4;
        return Center(
          child: SizedBox(
            key: const ValueKey('onboarding-v2-hanok-growth-preview'),
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: SoriRadius.brMd,
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: .985, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: Semantics(
                  key: ValueKey(
                    complete
                        ? 'onboarding-v2-hanok-growth-after'
                        : 'onboarding-v2-hanok-growth-before',
                  ),
                  image: true,
                  label: complete
                      ? t.onboardingV2HanokGrowthAfterSemantics
                      : t.onboardingV2HanokGrowthBeforeSemantics,
                  child: Image.asset(
                    complete ? _afterAsset : _beforeAsset,
                    key: ValueKey(complete ? _afterAsset : _beforeAsset),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
