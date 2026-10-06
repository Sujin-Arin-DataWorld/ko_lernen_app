import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/companion_art.dart';
import 'mascot.dart';
import 'tokens.dart';
import 'window_class.dart';

/// Compact greeting whose lower edge is the next learning card's surface.
/// Place immediately before that card, including loading and failure states.
class SoriLearningCompanion extends StatelessWidget {
  const SoriLearningCompanion({
    super.key,
    required this.greeting,
    required this.title,
    required this.kind,
    this.forceStatic = false,
  });

  final String greeting;
  final String title;
  final MascotKind? kind;
  final bool forceStatic;

  // The entire canonical image stays inside the viewport in every state.
  static const double clipSize = 144;
  static const double sittingViewport = clipSize;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    const clipSize = SoriLearningCompanion.clipSize;
    final character = kind;
    final greetingText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(greeting, style: text.bodySmall),
        const SizedBox(height: Spacing.xs),
        Text(title, style: text.h1),
      ],
    );
    if (character == null) {
      return Padding(
        key: const ValueKey('sori-today-companion-hidden'),
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: greetingText,
      );
    }

    const viewportHeight = clipSize;
    final clip = Image.asset(
      character == MascotKind.magpie
          ? CompanionArt.joyGuide
          : CompanionArt.taegoSeated,
      fit: BoxFit.contain,
      cacheWidth: (clipSize * MediaQuery.devicePixelRatioOf(context)).ceil(),
      semanticLabel: character == MascotKind.magpie
          ? AppL10n.of(context).characterRomanMagpie
          : AppL10n.of(context).characterRomanTiger,
      errorBuilder: (_, _, _) => Mascot(kind: character, size: clipSize),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
        final stacked =
            constraints.maxWidth < SoriAdaptiveWidth.learningCompanionRow ||
            largeText;
        // Keep the inward-facing companion beside the readable greeting.
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: SizedBox(
                key: const ValueKey('learning-companion-ground'),
                width: clipSize,
                height: viewportHeight,
                child: RepaintBoundary(child: clip),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                Spacing.lg,
                stacked ? 0 : clipSize + Spacing.lg,
                stacked ? viewportHeight + Spacing.sm : Spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: stacked ? 0 : 100),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: greetingText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
