import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// 덱 하단 미니 원형 아이콘 바 — 모름 / 스킵 / 저장 / 앎 (2026-08-14 P2).
///
/// 판정 2개(모름·앎)는 [judgmentEnabled] 가 false 면 흐리고, 탭은
/// [onBlockedJudgment] 힌트만 낸다. 스킵·저장은 항상 활성.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.dontKnowLabel,
    required this.skipLabel,
    required this.saveLabel,
    required this.knowLabel,
    required this.onDontKnow,
    required this.onSkip,
    required this.onKnow,
    this.onSave,
    this.showSave = true,
    this.judgmentEnabled = true,
    this.onBlockedJudgment,
  });

  final String dontKnowLabel;
  final String skipLabel;
  final String saveLabel;
  final String knowLabel;
  final VoidCallback onDontKnow;
  final VoidCallback onSkip;
  final VoidCallback onKnow;
  final VoidCallback? onSave;
  final bool showSave;
  final bool judgmentEnabled;
  final VoidCallback? onBlockedJudgment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckIconButton(
          diameter: 64,
          asset: 'assets/illustrations/deck/action_dontknow.webp',
          fallback: Icons.question_mark_rounded,
          label: dontKnowLabel,
          background: SoriSurfaces.of(context).raised,
          border: SoriColors.accent,
          iconColor: SoriColors.accent,
          enabled: judgmentEnabled,
          dimmed: !judgmentEnabled,
          onTap: judgmentEnabled ? onDontKnow : (onBlockedJudgment ?? () {}),
        ),
        const SizedBox(width: Spacing.lg),
        _DeckIconButton(
          diameter: 48,
          asset: 'assets/illustrations/deck/action_skip.webp',
          fallback: Icons.arrow_downward_rounded,
          label: skipLabel,
          background: SoriSurfaces.of(context).alt,
          iconColor: SoriSurfaces.of(context).text,
          onTap: onSkip,
        ),
        if (showSave) ...[
          const SizedBox(width: Spacing.lg),
          _DeckIconButton(
            diameter: 48,
            asset: 'assets/illustrations/deck/action_save.webp',
            fallback: Icons.redeem_rounded,
            label: saveLabel,
            background: SoriColors.gold.withValues(alpha: 0.18),
            border: SoriColors.gold,
            iconColor: SoriColors.goldOnLight,
            onTap: onSave ?? () {},
          ),
        ],
        const SizedBox(width: Spacing.lg),
        _DeckIconButton(
          diameter: 64,
          asset: 'assets/illustrations/deck/action_know.webp',
          fallback: Icons.check_rounded,
          label: knowLabel,
          background: SoriColors.primary,
          iconColor: SoriColors.lightBg,
          enabled: judgmentEnabled,
          dimmed: !judgmentEnabled,
          onTap: judgmentEnabled ? onKnow : (onBlockedJudgment ?? () {}),
        ),
      ],
    );
  }
}

class _DeckIconButton extends StatefulWidget {
  const _DeckIconButton({
    required this.diameter,
    required this.asset,
    required this.fallback,
    required this.label,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.border,
    this.enabled = true,
    this.dimmed = false,
  });

  final double diameter;
  final String asset;
  final IconData fallback;
  final String label;
  final Color background;
  final Color iconColor;
  final Color? border;
  final VoidCallback onTap;
  final bool enabled;
  final bool dimmed;

  @override
  State<_DeckIconButton> createState() => _DeckIconButtonState();
}

class _DeckIconButtonState extends State<_DeckIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.diameter >= 64 ? 32.0 : 24.0;
    final child = AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: SoriAnimation.tap,
      curve: _pressed ? SoriAnimation.tapOut : SoriAnimation.tapOut,
      child: Opacity(
        opacity: widget.dimmed ? 0.38 : 1,
        child: Container(
          width: widget.diameter,
          height: widget.diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.background,
            shape: BoxShape.circle,
            border: widget.border == null
                ? null
                : Border.all(color: widget.border!, width: 1.5),
          ),
          child: Image.asset(
            widget.asset,
            width: iconSize,
            height: iconSize,
            errorBuilder: (_, __, ___) =>
                Icon(widget.fallback, color: widget.iconColor, size: iconSize),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: true,
      label: widget.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: child,
        ),
      ),
    );
  }
}
