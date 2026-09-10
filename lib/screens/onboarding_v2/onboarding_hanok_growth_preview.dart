import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/tokens.dart';

const _courtyardAsset = 'assets/illustrations/onboarding/ildu_v3_courtyard.png';
const _sarangchaeAsset =
    'assets/illustrations/onboarding/ildu_v3_sarangchae.png';

/// Onboarding-only illustration using the selected PR #293 Sarangchae master.
///
/// This is a static construction goal, never a before/after reward. The
/// approved master needs twelve separately authored construction stages;
/// onboarding answers must not reveal it as a completed learner building.
/// This scene does not register the building on the world map.
class OnboardingHanokGrowthPreview extends StatelessWidget {
  const OnboardingHanokGrowthPreview({super.key, this.showDestination = false});

  final bool showDestination;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
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
                key: const ValueKey('onboarding-v3-hanok-destination'),
                image: true,
                label: t.onboardingV2HanokGrowthAfterSemantics,
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
                              child: Image.asset(
                                _sarangchaeAsset,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
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
