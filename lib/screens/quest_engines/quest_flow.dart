import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';

enum SoriAnswerState { idle, selected, correct, wrong }

enum SoriWordTileState { idle, selected, correct, wrong, disabled }

class SoriAnswerTray extends StatelessWidget {
  const SoriAnswerTray({
    super.key,
    required this.child,
    this.accent = SoriColors.primary,
    this.minHeight = 88,
  });

  final Widget child;
  final Color accent;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: surfaces.surface,
        borderRadius: BorderRadius.circular(SoriRadius.lg),
        border: Border(bottom: BorderSide(color: accent, width: 2.5)),
      ),
      child: child,
    );
  }
}

/// Shared tile for productive word and jamo assembly tasks.
class SoriWordTile extends StatelessWidget {
  const SoriWordTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.scale = 1,
    this.compact = false,
  });

  final String label;
  final SoriWordTileState state;
  final VoidCallback? onTap;
  final double scale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final (border, background, foreground) = switch (state) {
      SoriWordTileState.idle => (
        surfaces.surfaceAlt,
        surfaces.surface,
        surfaces.text,
      ),
      SoriWordTileState.selected => (
        SoriColors.primary,
        SoriColors.primary.withAlpha(22),
        surfaces.text,
      ),
      SoriWordTileState.correct => (
        SoriColors.success,
        SoriColors.success.withAlpha(32),
        SoriColors.success,
      ),
      SoriWordTileState.wrong => (
        SoriColors.danger,
        SoriColors.danger.withAlpha(32),
        SoriColors.danger,
      ),
      SoriWordTileState.disabled => (
        surfaces.surfaceAlt,
        surfaces.surface,
        surfaces.textDim,
      ),
    };
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: state == SoriWordTileState.selected,
      child: SoriPressable(
        onTap: onTap,
        haptic: null,
        pressScale: 0.97,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(SoriRadius.sm),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: 48 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: (compact ? 12 : 18) * scale,
              vertical: (compact ? 9 : 12) * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoriRadius.sm),
              border: Border.all(color: border, width: 1.5),
              boxShadow: state == SoriWordTileState.idle
                  ? null
                  : [
                      BoxShadow(
                        color: border.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: (compact ? 16 : 18) * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared, accessible answer row used by scenario choice engines.
/// State is communicated by icon and semantics as well as color.
class SoriAnswerTile extends StatelessWidget {
  const SoriAnswerTile({
    super.key,
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final int index;
  final SoriAnswerState state;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final (accent, icon, status) = switch (state) {
      SoriAnswerState.idle => (surfaces.surfaceAlt, null, ''),
      SoriAnswerState.selected => (
        SoriColors.primary,
        Icons.check_circle_outline_rounded,
        t.questAnswerSelected,
      ),
      SoriAnswerState.correct => (
        SoriColors.success,
        Icons.check_circle_rounded,
        t.questCorrect,
      ),
      SoriAnswerState.wrong => (
        SoriColors.danger,
        Icons.cancel_rounded,
        t.questWrong,
      ),
    };
    final selected = state != SoriAnswerState.idle;

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: status.isEmpty ? label : '$label, $status',
      child: SoriPressable(
        onTap: onTap,
        haptic: null,
        pressScale: 0.98,
        child: AnimatedScale(
          scale: selected ? 0.99 : 1,
          duration: duration,
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              color: selected ? accent.withAlpha(24) : surfaces.surface,
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(color: accent, width: selected ? 2 : 1.5),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.1),
                        blurRadius: 9,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: compact ? Spacing.sm : 12,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withAlpha(selected ? 36 : 18),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: selected ? accent : surfaces.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        style: SoriTextTheme.of(context).body.copyWith(
                          color: surfaces.text,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: Spacing.sm),
                      Icon(icon, color: accent, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single action area for scenario quests.
class ScenarioQuestAction extends StatelessWidget {
  const ScenarioQuestAction({
    super.key,
    required this.canSubmit,
    required this.onSubmit,
    this.resolved,
    this.onContinue,
    this.isLast = false,
    this.hint,
    this.pendingHint,
    this.onDontKnow,
  });

  final bool canSubmit;
  final VoidCallback? onSubmit;
  final bool? resolved;
  final VoidCallback? onContinue;
  final bool isLast;
  final String? hint;
  final String? pendingHint;
  final VoidCallback? onDontKnow;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final result = resolved;
    if (result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingHint?.trim().isNotEmpty == true) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: SoriColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      pendingHint!,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: SoriColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          SoriButton.filled(
            key: const ValueKey('quest-submit'),
            label: t.questCheckAnswer,
            fullWidth: true,
            onTap: canSubmit ? onSubmit : null,
          ),
          if (onDontKnow != null) ...[
            const SizedBox(height: Spacing.xs),
            SoriButton.ghost(
              key: const ValueKey('quest-dont-know'),
              label: t.questDontKnowYet,
              fullWidth: true,
              onTap: onDontKnow,
            ),
          ],
        ],
      );
    }

    final accent = result ? SoriColors.success : SoriColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  hint?.trim().isNotEmpty == true
                      ? hint!
                      : (result ? t.questCorrect : t.questAnswerRevealed),
                  style: SoriTextTheme.of(
                    context,
                  ).bodySmall.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton.filled(
          key: const ValueKey('quest-continue'),
          label: isLast ? t.questViewResult : t.questNext,
          fullWidth: true,
          onTap: onContinue,
        ),
      ],
    );
  }
}
