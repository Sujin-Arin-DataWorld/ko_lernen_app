import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// SoriCard variant.
enum SoriCardVariant {
  /// 큰 hero card (24 padding, radius 20, 강조 색상 + 살짝 elevation).
  hero,
  /// 기본 카드 (16 padding, radius 16).
  base,
  /// 작은 compact 카드 (12 padding, radius 12).
  compact,
}

/// **SoriCard** — 통합 카드 컴포넌트.
///
/// 그라데이션 폐지. 단색 surface + accent border (옵션). tap 가능하면
/// 자동으로 [SoriPressable] 래핑되어 spring scale 모션.
///
/// 사용:
/// ```dart
/// SoriCard(
///   variant: SoriCardVariant.hero,
///   accent: SoriColors.primary,
///   onTap: () => ...,
///   child: Column(...),
/// )
/// ```
class SoriCard extends StatelessWidget {
  final Widget child;
  final SoriCardVariant variant;

  /// border + 살짝 tint accent. null이면 brand-neutral.
  final Color? accent;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  /// surface 배경 대신 accent 채움(아주 옅게). hero 카드에 권장.
  final bool tinted;

  const SoriCard({
    super.key,
    required this.child,
    this.variant = SoriCardVariant.base,
    this.accent,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.width,
    this.height,
    this.tinted = false,
  });

  double get _radius => switch (variant) {
    SoriCardVariant.hero    => SoriRadius.lg,
    SoriCardVariant.base    => SoriRadius.md,
    SoriCardVariant.compact => SoriRadius.sm,
  };

  EdgeInsetsGeometry get _defaultPadding => switch (variant) {
    SoriCardVariant.hero    => const EdgeInsets.all(Spacing.xl),
    SoriCardVariant.base    => const EdgeInsets.all(Spacing.lg),
    SoriCardVariant.compact => const EdgeInsets.all(Spacing.md),
  };

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    final accentColor = accent ?? SoriColors.primary;

    final bgColor = tinted
        ? Color.alphaBlend(accentColor.withValues(alpha: isLight ? 0.08 : 0.14), s.surface)
        : s.surface;

    final borderColor = accent != null
        ? accentColor.withValues(alpha: isLight ? 0.25 : 0.35)
        : s.border;

    final card = Container(
      width: width,
      height: height,
      padding: padding ?? _defaultPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isLight ? SoriElevation.low : null,
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) return card;

    return SoriPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      pressScale: variant == SoriCardVariant.hero ? 0.97 : 0.96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: card,
      ),
    );
  }
}
