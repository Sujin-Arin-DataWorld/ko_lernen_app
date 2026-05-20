import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

enum SoriButtonVariant { filled, outlined, ghost }
enum SoriButtonSize    { lg, md, sm }

/// **SoriButton** — 통통튀는 모션 포함 버튼.
///
/// 3 variants × 3 sizes. 자동 [SoriPressable] 래핑.
///
/// 사용:
/// ```dart
/// SoriButton.filled(label: 'Start', icon: Icons.bolt, onTap: ...)
/// SoriButton.outlined(label: 'Cancel', size: SoriButtonSize.md)
/// SoriButton.ghost(label: 'Mehr', onTap: ...)
/// ```
class SoriButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final SoriButtonVariant variant;
  final SoriButtonSize size;
  final Color? accent;       // primary 대신 다른 색 강조 가능
  final bool fullWidth;
  final bool destructive;    // danger color 강제

  const SoriButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.variant = SoriButtonVariant.filled,
    this.size = SoriButtonSize.lg,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
  });

  const SoriButton.filled({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.lg,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
  }) : variant = SoriButtonVariant.filled;

  const SoriButton.outlined({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.md,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
  }) : variant = SoriButtonVariant.outlined;

  const SoriButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.md,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
  }) : variant = SoriButtonVariant.ghost;

  double get _height => switch (size) {
    SoriButtonSize.lg => 52,
    SoriButtonSize.md => 44,
    SoriButtonSize.sm => 36,
  };

  double get _fontSize => switch (size) {
    SoriButtonSize.lg => 15,
    SoriButtonSize.md => 14,
    SoriButtonSize.sm => 12.5,
  };

  double get _hpad => switch (size) {
    SoriButtonSize.lg => 22,
    SoriButtonSize.md => 18,
    SoriButtonSize.sm => 14,
  };

  double get _radius => switch (size) {
    SoriButtonSize.lg => SoriRadius.lg,
    SoriButtonSize.md => SoriRadius.md,
    SoriButtonSize.sm => SoriRadius.sm,
  };

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final disabled = onTap == null;
    final color = destructive
        ? SoriColors.danger
        : (accent ?? SoriColors.primary);

    final (Color bg, Color fg, BoxBorder? border) = switch (variant) {
      SoriButtonVariant.filled => (
        disabled ? s.surfaceAlt : color,
        disabled ? s.textDim    : Colors.white,
        null,
      ),
      SoriButtonVariant.outlined => (
        Colors.transparent,
        disabled ? s.textDim : color,
        Border.all(color: disabled ? s.border : color.withValues(alpha: 0.6), width: 1.5),
      ),
      SoriButtonVariant.ghost => (
        Colors.transparent,
        disabled ? s.textDim : color,
        null,
      ),
    };

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _fontSize + 3, color: fg),
          const SizedBox(width: Spacing.sm),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: _fontSize,
            letterSpacing: -0.2,
            height: 1.2,
          ),
        ),
      ],
    );

    final box = Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hpad),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(_radius),
      ),
      alignment: Alignment.center,
      child: content,
    );

    final wrapped = fullWidth ? SizedBox(width: double.infinity, child: box) : box;

    if (disabled) return wrapped;

    return SoriPressable(
      onTap: onTap,
      haptic: variant == SoriButtonVariant.filled ? SoriHaptic.light : SoriHaptic.selection,
      child: wrapped,
    );
  }
}
