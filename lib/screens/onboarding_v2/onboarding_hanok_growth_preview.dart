import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/tokens.dart';

const _courtyardAsset = 'assets/illustrations/onboarding/ildu_v3_courtyard.png';
const _sarangchaeAsset =
    'assets/illustrations/onboarding/ildu_v3_sarangchae.png';

/// Onboarding-only illustration using the selected PR #293 Sarangchae master.
///
/// The reveal illustrates the learning/building connection, not an awarded
/// construction stage. This scene does not register the building on the world
/// map or change the checkpoint's pending map-scale and generation approvals.
class OnboardingHanokGrowthPreview extends StatelessWidget {
  const OnboardingHanokGrowthPreview({
    super.key,
    this.complete = false,
    this.showDestination = false,
  });

  final bool complete;
  final bool showDestination;

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
        final aspectRatio = showDestination ? 3 / 2 : 2.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth / aspectRatio;
        final nativeWidth = showDestination ? 1536.0 : 1774.0;
        final width = math
            .min(
              math.min(availableWidth, availableHeight * aspectRatio),
              nativeWidth / MediaQuery.devicePixelRatioOf(context),
            )
            .toDouble();
        final height = width / aspectRatio;
        return Center(
          child: SizedBox(
            key: const ValueKey('onboarding-v2-hanok-growth-preview'),
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: SoriRadius.brMd,
              child: Semantics(
                key: ValueKey(
                  showDestination
                      ? 'onboarding-v3-hanok-destination'
                      : complete
                      ? 'onboarding-v2-hanok-growth-after'
                      : 'onboarding-v2-hanok-growth-before',
                ),
                image: true,
                label: showDestination || complete
                    ? t.onboardingV2HanokGrowthAfterSemantics
                    : t.onboardingV2HanokGrowthBeforeSemantics,
                excludeSemantics: true,
                child: showDestination
                    ? Image.asset(_sarangchaeAsset, fit: BoxFit.contain)
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(_courtyardAsset, fit: BoxFit.contain),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: .7,
                              heightFactor: 1,
                              child: AnimatedOpacity(
                                opacity: complete ? 1 : .16,
                                duration: duration,
                                curve: Curves.easeOutCubic,
                                child: Image.asset(
                                  _sarangchaeAsset,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
