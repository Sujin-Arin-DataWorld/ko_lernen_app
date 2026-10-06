import 'package:flutter/material.dart';
import 'practice_dokkaebi_art.dart';
import 'practice_scholar_clip.dart';
import 'practice_scholar_art.dart';
import 'sori/tokens.dart';

/// Approved original artwork. Information stays in text, with no idle motion.
class PracticeGuide extends StatelessWidget {
  const PracticeGuide({
    super.key,
    required this.dokkaebi,
    required this.child,
    this.scholarExplaining = false,
    this.scholarPlay = false,
    this.onScholarRequested,
    this.dokkaebiPose = PracticeDokkaebiPose.review,
    this.scholarPose = PracticeScholarPose.calm,
  });
  final bool dokkaebi;
  final PracticeDokkaebiPose dokkaebiPose;
  final PracticeScholarPose scholarPose;
  final Widget child;
  final bool scholarExplaining;
  final bool scholarPlay;
  final VoidCallback? onScholarRequested;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack =
          constraints.maxWidth < SoriBreakpoints.contentActionStack ||
          MediaQuery.textScalerOf(context).scale(16) > 24;
      final figure = SizedBox(
        width: dokkaebi ? 64 : (scholarExplaining ? 90 : 64),
        height: dokkaebi ? 96 : (scholarExplaining ? 160 : 114),
        child: dokkaebi
            ? PracticeDokkaebiArt(pose: dokkaebiPose)
            : scholarExplaining || scholarPlay
            ? PracticeScholarClip(
                play: scholarPlay,
                explaining: scholarExplaining,
                onRequested: onScholarRequested,
              )
            : PracticeScholarArt(pose: scholarPose),
      );
      if (stack) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: figure),
            const SizedBox(height: Spacing.md),
            child,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          figure,
          const SizedBox(width: Spacing.md),
          Expanded(child: child),
        ],
      );
    },
  );
}
