import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// Accessible controls for the four Sori Deck directions.
///
/// The artwork paths are an optional art drop: missing files intentionally
/// fall back to Material glyphs while keeping the interaction contract live.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.dontKnowLabel,
    required this.skipLabel,
    required this.saveLabel,
    required this.knowLabel,
    required this.onDontKnow,
    required this.onSkip,
    required this.onSave,
    required this.onKnow,
    this.showSave = true,
  });

  final String dontKnowLabel;
  final String skipLabel;
  final String saveLabel;
  final String knowLabel;
  final VoidCallback? onDontKnow;
  final VoidCallback? onSkip;
  final VoidCallback? onSave;
  final VoidCallback? onKnow;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('deck-action-bar'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckAction(
          semanticLabel: dontKnowLabel,
          asset: 'assets/illustrations/deck/action_dontknow.webp',
          fallback: Icons.question_mark_rounded,
          size: 64,
          foreground: SoriColors.danger,
          background: SoriSurfaces.of(context).surface,
          border: SoriColors.danger,
          onTap: onDontKnow,
        ),
        const SizedBox(width: Spacing.md),
        _DeckAction(
          semanticLabel: skipLabel,
          asset: 'assets/illustrations/deck/action_skip.webp',
          fallback: Icons.arrow_downward_rounded,
          size: 48,
          foreground: SoriSurfaces.of(context).text,
          background: SoriSurfaces.of(context).surfaceAlt,
          onTap: onSkip,
        ),
        if (showSave) ...[
          const SizedBox(width: Spacing.md),
          _DeckAction(
            semanticLabel: saveLabel,
            asset: 'assets/illustrations/deck/action_save.webp',
            fallback: Icons.redeem_rounded,
            size: 48,
            foreground: SoriColors.gold,
            background: SoriColors.gold.withValues(alpha: 0.18),
            border: SoriColors.gold,
            onTap: onSave,
          ),
        ],
        const SizedBox(width: Spacing.md),
        _DeckAction(
          semanticLabel: knowLabel,
          asset: 'assets/illustrations/deck/action_know.webp',
          fallback: Icons.check_rounded,
          size: 64,
          foreground: Colors.white,
          background: SoriColors.primary,
          onTap: onKnow,
        ),
      ],
    );
  }
}

class _DeckAction extends StatelessWidget {
  const _DeckAction({
    required this.semanticLabel,
    required this.asset,
    required this.fallback,
    required this.size,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.border,
  });

  final String semanticLabel;
  final String asset;
  final IconData fallback;
  final double size;
  final Color foreground;
  final Color background;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.selection,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: border == null
                  ? null
                  : Border.all(color: border!, width: 1.5),
            ),
            child: Image.asset(
              asset,
              width: size == 64 ? 32 : 24,
              height: size == 64 ? 32 : 24,
              errorBuilder: (_, _, _) => Icon(
                fallback,
                color: foreground,
                size: size == 64 ? 32 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
