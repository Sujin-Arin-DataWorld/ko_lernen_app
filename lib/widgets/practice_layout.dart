import 'package:flutter/material.dart';
import 'sori/card.dart';
import 'sori/tokens.dart';

/// Reserves room for the shared button's lower edge. The button alone owns
/// pressure, focus, keyboard and haptics; a second wrapper must not move it.
class PracticeRaisedAction extends StatelessWidget {
  const PracticeRaisedAction({
    super.key,
    required this.child,
    this.primary = false,
  });
  final Widget child;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: primary ? Spacing.sm : Spacing.xs),
      child: child,
    );
  }
}

/// Read first, act second: keep the action group apart from lesson copy.
class PracticeActionArea extends StatelessWidget {
  const PracticeActionArea({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Spacing.xxl, bottom: Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.md),
          children[i],
        ],
      ],
    ),
  );
}

class PracticeDialogueBubble extends StatelessWidget {
  const PracticeDialogueBubble({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: Spacing.xs,
        top: Spacing.xl,
        child: Transform.rotate(
          angle: .785398,
          child: ColoredBox(
            color: SoriCard.resolvedBackground(context),
            child: const SizedBox.square(dimension: Spacing.lg),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: Spacing.md),
        child: SoriCard(
          padding: const EdgeInsets.all(Spacing.xl),
          child: child,
        ),
      ),
    ],
  );
}
