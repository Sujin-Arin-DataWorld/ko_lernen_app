import 'package:flutter/material.dart';

/// User-approved, byte-preserved poses. Learning state chooses the pose;
/// the artwork itself never creates a completion or a reward.
enum PracticeDokkaebiPose {
  inviting('assets/illustrations/tactile/dokkaebi/dokkaebi_inviting.png'),
  ready('assets/illustrations/tactile/dokkaebi/dokkaebi_ready.png'),
  helping('assets/illustrations/tactile/dokkaebi/dokkaebi_helping.png'),
  review('assets/illustrations/tactile/dokkaebi/dokkaebi_review.png'),
  celebrate('assets/illustrations/tactile/dokkaebi/dokkaebi_celebrate.png'),
  magical('assets/illustrations/tactile/dokkaebi/dokkaebi_magical.png');

  const PracticeDokkaebiPose(this.asset);
  final String asset;
}

class PracticeDokkaebiArt extends StatelessWidget {
  const PracticeDokkaebiArt({super.key, required this.pose});
  final PracticeDokkaebiPose pose;

  @override
  Widget build(BuildContext context) => Image.asset(
    pose.asset,
    // Keep one Image state across pose changes, including the hint's scroll
    // transition, so gaplessPlayback can hold the already decoded artwork.
    fit: BoxFit.contain,
    cacheWidth: 512,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: (_, __, ___) => Image.asset(
      'assets/illustrations/tactile/dokkaebi.png',
      fit: BoxFit.contain,
      cacheWidth: 512,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    ),
  );
}
