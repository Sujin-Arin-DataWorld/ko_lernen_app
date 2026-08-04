import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

enum SoriButtonVariant { filled, outlined, ghost }

enum SoriButtonSize { lg, md, sm }

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
  final int maxLines;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final SoriButtonVariant variant;
  final SoriButtonSize size;
  final Color? accent; // primary 대신 다른 색 강조 가능
  final bool fullWidth;
  final bool destructive; // danger color 강제

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
    this.maxLines = 1,
  }) : assert(maxLines > 0);

  const SoriButton.filled({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.lg,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
    this.maxLines = 1,
  }) : variant = SoriButtonVariant.filled,
       assert(maxLines > 0);

  const SoriButton.outlined({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.md,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
    this.maxLines = 1,
  }) : variant = SoriButtonVariant.outlined,
       assert(maxLines > 0);

  const SoriButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.size = SoriButtonSize.md,
    this.accent,
    this.fullWidth = false,
    this.destructive = false,
    this.maxLines = 1,
  }) : variant = SoriButtonVariant.ghost,
       assert(maxLines > 0);

  double get _height => switch (size) {
    SoriButtonSize.lg => 56,
    SoriButtonSize.md => 48,
    SoriButtonSize.sm => 40,
  };

  double get _fontSize => switch (size) {
    SoriButtonSize.lg => 18,
    SoriButtonSize.md => 16,
    SoriButtonSize.sm => 14,
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
    final isLight = s.brightness == Brightness.light;
    final disabled = onTap == null;
    final comfortScale = soriComfortScale(MediaQuery.sizeOf(context).width);
    final visualHeight = _height * comfortScale;
    final visualFontSize = _fontSize * comfortScale;
    final visualHorizontalPadding = _hpad * comfortScale;
    final color = destructive
        ? SoriColors.danger
        : (accent ?? SoriColors.primary);

    // outlined·ghost용 텍스트 색: accent 미지정 시 light 한지 위 대비 보강
    // (primary `#1F7A6B` 5.8:1 → primaryOnLight `#0E443B` 12.6:1).
    final fgAccent = destructive
        ? SoriColors.danger
        : (accent ??
              (isLight ? SoriColors.primaryOnLight : SoriColors.primaryOnDark));

    // filled 채움이 배경에서 3:1로 안 떨어지면(예: tiger 2.14:1) 같은 색상의
    // 어두운 테두리를 자동으로 붙인다 — SC 1.4.11. 충분하면 null.
    final Color? fillEdge = (variant == SoriButtonVariant.filled && !disabled)
        ? SoriColors.fillOutline(color, s.bg)
        : null;

    final (Color bg, Color fg, BoxBorder? border) = switch (variant) {
      SoriButtonVariant.filled => (
        // §4.4-3: 비활성은 "죽은 회색 벽"이 아니라 저채도 한지톤 —
        // surfaceAlt 채움 + 모티프 색 15% 알파로 색상 정체성을 남긴다.
        disabled
            ? Color.alphaBlend(color.withValues(alpha: 0.15), s.surfaceAlt)
            : color,
        // 흰 글씨 고정 금지 — 밝은 채움(tiger/gold/warning)에선 먹색으로 자동 전환.
        disabled ? s.textDim : SoriColors.onFill(color),
        fillEdge == null ? null : Border.all(color: fillEdge, width: 1.5),
      ),
      SoriButtonVariant.outlined => (
        Colors.transparent,
        disabled ? s.textDim : fgAccent,
        Border.all(
          color: disabled ? s.border : fgAccent.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      SoriButtonVariant.ghost => (
        Colors.transparent,
        disabled ? s.textDim : fgAccent,
        null,
      ),
    };

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: visualFontSize + 3 * comfortScale, color: fg),
          SizedBox(width: Spacing.sm * comfortScale),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: visualFontSize,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
        ),
      ],
    );

    final box = Container(
      constraints: BoxConstraints(minHeight: visualHeight),
      padding: EdgeInsets.symmetric(
        horizontal: visualHorizontalPadding,
        vertical: maxLines > 1 ? Spacing.xs * comfortScale : 0,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(_radius * comfortScale),
      ),
      alignment: Alignment.center,
      child: content,
    );

    final wrapped = fullWidth
        ? SizedBox(width: double.infinity, child: box)
        : box;

    if (disabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: label,
        child: wrapped,
      );
    }

    return Semantics(
      button: true,
      enabled: true,
      label: label,
      child: SoriPressable(
        onTap: onTap,
        haptic: variant == SoriButtonVariant.filled
            ? SoriHaptic.light
            : SoriHaptic.selection,
        child: wrapped,
      ),
    );
  }
}
