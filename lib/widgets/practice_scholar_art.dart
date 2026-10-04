import 'package:flutter/material.dart';

/// Static learning gestures preserve the supplied original pixels.
enum PracticeScholarPose {
  welcome('assets/illustrations/tactile/scholar/scholar_welcome.png'),
  point('assets/illustrations/tactile/scholar/scholar_point.png'),
  bow('assets/illustrations/tactile/scholar/scholar_bow.png'),
  calm('assets/illustrations/tactile/scholar/scholar_calm.png'),
  thinking('assets/illustrations/tactile/scholar/scholar_thinking.png'),
  inviting('assets/illustrations/tactile/scholar/scholar_inviting.png');

  const PracticeScholarPose(this.asset);
  final String asset;
}

class PracticeScholarArt extends StatelessWidget {
  const PracticeScholarArt({super.key, required this.pose});
  final PracticeScholarPose pose;

  @override
  Widget build(BuildContext context) => Image.asset(
    pose.asset,
    key: ValueKey('scholar-pose-${pose.name}'),
    fit: BoxFit.contain,
    cacheWidth: 512,
    excludeFromSemantics: true,
    errorBuilder: (_, __, ___) => Image.asset(
      'assets/illustrations/tactile/hahoe_scholar.png',
      fit: BoxFit.contain,
      cacheWidth: 512,
      excludeFromSemantics: true,
    ),
  );
}
