import 'package:flutter/material.dart';

import 'hanok/eaves_corner.dart';
import 'hanok/hanji_texture.dart';
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
  /// 한지 텍스처 배경 카드 (v4 한옥 skin). hero급 padding, hanji bg, eaves corner 자동.
  hanji,
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

  /// v4 한옥 skin — 카드 상단 모서리를 처마(eaves)처럼 살짝 더 큰 곡선으로.
  /// hero/hanji variant에 자연스러움. base/compact엔 보통 false.
  final bool eaves;

  /// 접근성 라벨 — null이면 child의 Semantics를 그대로 사용.
  /// tappable card는 button 역할로 트리에 등록된다.
  final String? semanticLabel;

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
    this.eaves = false,
    this.semanticLabel,
  });

  double get _radius => switch (variant) {
    SoriCardVariant.hero    => SoriRadius.lg,
    SoriCardVariant.base    => SoriRadius.md,
    SoriCardVariant.compact => SoriRadius.sm,
    SoriCardVariant.hanji   => SoriRadius.lg,
  };

  EdgeInsetsGeometry get _defaultPadding => switch (variant) {
    SoriCardVariant.hero    => const EdgeInsets.all(Spacing.xl),
    SoriCardVariant.base    => const EdgeInsets.all(Spacing.lg),
    SoriCardVariant.compact => const EdgeInsets.all(Spacing.md),
    SoriCardVariant.hanji   => const EdgeInsets.all(Spacing.lg),
  };

  /// hanji variant + 처마 옵션은 자동 eaves 처리.
  bool get _useEaves => eaves || variant == SoriCardVariant.hanji;

  /// hanji variant는 항상 HanjiTexture wrapping.
  bool get _useHanji => variant == SoriCardVariant.hanji;

  BorderRadius get _borderRadius => _useEaves
      ? EavesCorner.borderRadius(base: _radius, boost: 6)
      : BorderRadius.circular(_radius);

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

    // hanji variant — HanjiTexture가 배경, padding은 child에 적용
    final Widget cardContent = _useHanji
        ? HanjiTexture(
            borderRadius: _borderRadius,
            child: Container(
              padding: padding ?? _defaultPadding,
              decoration: BoxDecoration(
                borderRadius: _borderRadius,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: child,
            ),
          )
        : Container(
            padding: padding ?? _defaultPadding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: _borderRadius,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isLight ? SoriElevation.low : null,
            ),
            child: child,
          );

    final card = SizedBox(
      width: width,
      height: height,
      child: cardContent,
    );

    if (onTap == null && onLongPress == null) {
      return semanticLabel == null
          ? card
          : Semantics(label: semanticLabel, container: true, child: card);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SoriPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        pressScale: (variant == SoriCardVariant.hero || variant == SoriCardVariant.hanji) ? 0.97 : 0.96,
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: card,
        ),
      ),
    );
  }
}
