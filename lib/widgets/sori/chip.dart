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
  final String? semanticLabel;
  final IconData? icon;
  final Color? accent; // 모드별 색
  final bool selected; // choice mode
  final SoriChipVariant variant;
  final VoidCallback? onTap;
  final double fontSize;

  /// Optional idle boundary for an unselected outlined choice.
  ///
  /// The default preserves existing consumers. App-owned filters that need a
  /// directly measurable 3:1 boundary can opt into the established strong
  /// surface-border token without creating a parallel chip implementation.
  final Color? idleBorderColor;

  /// Maximum visible label lines. Interactive filters default to one compact
  /// line; pass `null` when the full localized label must wrap at large text.
  final int? maxLines;

  /// Overrides the default 12/10 horizontal padding so dense rows (six TTS
  /// speed presets) can stay on one line inside a 480dp content column.
  final double? horizontalPadding;

  /// Optional minimum row height for a choice chip.
  ///
  /// The height remains in force when the current or zero-count choice is
  /// disabled. Otherwise a selected 48dp filter row collapses to its 35dp
  /// visual pill and the sheet jumps vertically. The chip keeps its intrinsic
  /// width so it can remain inline in a [Wrap] on wider layouts.
  final double? minInteractiveHeight;

  const SoriChip({
    super.key,
    required this.label,
    this.semanticLabel,
    this.icon,
    this.accent,
    this.selected = false,
    this.variant = SoriChipVariant.soft,
    this.onTap,
    this.fontSize = 13.5,
    this.idleBorderColor,
    this.maxLines = 1,
    this.horizontalPadding,
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
        selected ? color : (idleBorderColor ?? s.border),
      ),
    };

    final chip = AnimatedContainer(
      duration: SoriMotion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? (icon == null ? 12 : 10),
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
              maxLines: maxLines,
              overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SoriFonts.sans,
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
    final content = minimumHeight != null
        ? IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumHeight),
              child: Center(child: chip),
            ),
          )
        : chip;

    // majority 패턴(_Stamp content_feed.dart:593-599, _ChromeSlot,
    // SoriHomeAction, _DeckActionButton) — 명시적 Semantics(onTap:) +
    // 전용 ExcludeSemantics 로 내부 Text 의 자동 라벨을 지운다. semanticLabel
    // 이 없는(=대다수) 칩도 예외 없이 이 패턴을 타야 한다: 예전엔 override가
    // 없으면 excludeSemantics 도 꺼져(내부 Text 가 라벨을 한 번 더 냄) onTap
    // 도 null 로 떨궈(탭 시맨틱 액션 자체가 사라짐) SoriLevelFilterBar 의
    // 모든 칩이 이중 안내 + 탭 불가 상태였다.
    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? label,
        selected: selected,
        child: ExcludeSemantics(child: content),
      );
    }
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(onTap: onTap, child: content),
      ),
    );
  }
}
