import 'package:flutter/material.dart';

import 'character_clip.dart';
import 'mascot.dart';
import 'tokens.dart';

/// Compact greeting whose lower edge is the next learning card's surface.
/// Place immediately before that card, including loading and failure states.
class SoriLearningCompanion extends StatefulWidget {
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

  // The sitting2 source is 640 square. Every one of its 121 frames has the
  // last body pixel at y=552. Only empty lower matte is outside this viewport.
  static const double clipSize = 144;
  static const double sittingViewport = 125;

  @override
  State<SoriLearningCompanion> createState() => _SoriLearningCompanionState();
}

class _SoriLearningCompanionState extends State<SoriLearningCompanion> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant SoriLearningCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    const clipSize = SoriLearningCompanion.clipSize;
    const sittingViewport = SoriLearningCompanion.sittingViewport;
    final character = widget.kind;
    final greetingText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.greeting, style: text.bodySmall),
        const SizedBox(height: Spacing.xs),
        Text(widget.title, style: text.h1),
      ],
    );
    if (character == null) {
      return Padding(
        key: const ValueKey('sori-today-companion-hidden'),
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: greetingText,
      );
    }

    final useStatic =
        widget.forceStatic ||
        _failed ||
        CharacterClipPlayer.videoUnavailable(context);
    final isTiger = character == MascotKind.tiger;
    final viewportHeight = isTiger ? sittingViewport : clipSize;
    final clip = useStatic
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Mascot(kind: character, size: viewportHeight),
          )
        : ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: clipSize,
              maxHeight: clipSize,
              child: CharacterClipPlayer(
                key: ValueKey('learning-companion-${character.name}'),
                asset: isTiger
                    ? HomeHeroClips.tigerSitting2
                    : HomeHeroClips.magpieWalkingFront,
                size: clipSize,
                loop: true,
                applyMultiplyFilter: false,
                staticFallback: CharacterClipPlayer.videoUnavailable(context),
                fallbackKind: character,
                onFailure: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && widget.kind == character) {
                      setState(() => _failed = true);
                    }
                  });
                },
              ),
            ),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
        final stacked = constraints.maxWidth < 300 || largeText;
        // Paint the external texture first and the text last. This also keeps
        // the greeting outside the texture layer on Android compositors.
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: SizedBox(
                key: const ValueKey('learning-companion-ground'),
                width: clipSize,
                height: viewportHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: RepaintBoundary(child: clip)),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: surfaces.text.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(
                              SoriRadius.pill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: surfaces.text.withValues(alpha: 0.08),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
