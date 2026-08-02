import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

enum SoriChipVariant { soft, filled, outlined }

/// **SoriChip** — pill-shaped 라벨/태그. choice / status / stat 모두 커버.
///
/// 사용:
/// ```dart
/// SoriChip(label: 'A1', accent: SoriColors.success)
/// SoriChip(label: '🔥 5', accent: SoriColors.warning, variant: SoriChipVariant.filled)
/// SoriChip(label: '오늘 fällig', selected: true, onTap: () => ...)
/// ```
class SoriChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? accent; // 모드별 색
  final bool selected; // choice mode
  final SoriChipVariant variant;
  final VoidCallback? onTap;
  final double fontSize;

  /// Optional minimum hit-target height for an interactive chip.
  ///
  /// These targets keep their intrinsic width so they can remain inline in a
  /// [Wrap] on wider layouts.
  final double? minInteractiveHeight;

  const SoriChip({
    super.key,
    required this.label,
    this.icon,
    this.accent,
    this.selected = false,
    this.variant = SoriChipVariant.soft,
    this.onTap,
    this.fontSize = 12,
    this.minInteractiveHeight,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final color = accent ?? SoriColors.primary;
    final isLight = s.brightness == Brightness.light;

    final (Color bg, Color fg, Color border) = switch (variant) {
      SoriChipVariant.filled => (
        selected ? color : color.withValues(alpha: isLight ? 0.15 : 0.2),
        selected ? Colors.white : color,
        Colors.transparent,
      ),
      SoriChipVariant.soft => (
        selected ? color : color.withValues(alpha: isLight ? 0.10 : 0.16),
        selected ? Colors.white : color,
        Colors.transparent,
      ),
      SoriChipVariant.outlined => (
        Colors.transparent,
        selected ? color : s.text,
        selected ? color : s.border,
      ),
    };

    final chip = AnimatedContainer(
      duration: SoriMotion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 12 : 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SoriRadius.brPill,
        border: variant == SoriChipVariant.outlined
            ? Border.all(color: border, width: 1.2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    final minimumHeight = minInteractiveHeight;
    final content = onTap != null && minimumHeight != null
        ? IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumHeight),
              child: Center(child: chip),
            ),
          )
        : chip;

    if (onTap == null) {
      return Semantics(label: label, child: content);
    }
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: SoriPressable(onTap: onTap, child: content),
    );
  }
}
