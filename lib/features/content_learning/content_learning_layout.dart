import 'package:flutter/material.dart';

import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';

/// Balances one finite learning step within its actual available viewport.
///
/// The header, body, and actions form one centered reading flow on tall
/// windows. Long text keeps its natural height and scrolls with the actions.
/// No intrinsic layout is requested, so buttons and other LayoutBuilder-based
/// Sori widgets remain safe at large text sizes and narrow widths.
class ContentLearningLayout extends StatelessWidget {
  const ContentLearningLayout({
    super.key,
    required this.body,
    required this.actions,
    this.header,
  });

  final List<Widget> body;
  final List<Widget> actions;
  final Widget? header;

  @override
  Widget build(BuildContext context) => SoriAdaptiveStudyBody(
    minHeight: 0,
    fillViewport: true,
    intrinsic: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        header ?? const SizedBox.shrink(),
        if (header != null) const SizedBox(height: Spacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      ],
    ),
  );
}
