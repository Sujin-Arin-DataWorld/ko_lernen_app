import 'package:flutter/material.dart';
import 'sori/tokens.dart';

/// Approved original artwork. Information stays in text, with no idle motion.
class PracticeGuide extends StatelessWidget {
  const PracticeGuide({super.key, required this.dokkaebi, required this.child});
  final bool dokkaebi;
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Image.asset(
          dokkaebi
              ? 'assets/illustrations/tactile/dokkaebi.png'
              : 'assets/illustrations/tactile/hahoe_scholar.png',
          width: 64,
          height: 96,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(width: Spacing.md),
      Expanded(child: child),
    ],
  );
}
