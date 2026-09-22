import 'package:flutter/material.dart';

import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';

/// Balances one finite learning step within its actual available viewport.
///
/// The header stays near the top, the body uses the middle, and actions stay
/// near the bottom. Only surplus height becomes space between those groups;
/// long text keeps its natural height and scrolls together with the actions.
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        header ?? const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      ],
    ),
  );
}
