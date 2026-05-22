// ignore_for_file: prefer_initializing_formals
//
// 명명된 파라미터 이름이 `_label:`처럼 underscore로 시작하면 Dart에서 금지된다.
// 따라서 private 필드 (`_label` 등)에 public 별칭(label) 파라미터를 매핑해야 하므로
// initializing formal을 쓸 수 없다.

import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriBadge** — level / XP / streak / stars 등 작은 상태 표시.
///
/// 텍스트 색은 배경 luminance로 자동 결정 (white ↔ 먹 ink). warning 같은
/// 밝은 톤 배경에서 white 텍스트 대비 부족 문제 자동 해소.
///
/// 사용:
/// ```dart
/// SoriBadge.level('A2', color: SoriColors.success)
/// SoriBadge.xp(240)
/// SoriBadge.streak(5)
/// SoriBadge.stars(filled: 2, total: 3)
/// ```
class SoriBadge extends StatelessWidget {
  final Color color;
  final double size;
  final String _label;
  final IconData? _icon;
  final String? _emoji;
  final String _semanticLabel;

  const SoriBadge._({
    required this.color,
    required this.size,
    required String label,
    required String semanticLabel,
    IconData? icon,
    String? emoji,
  })  : _label = label,
        _icon = icon,
        _emoji = emoji,
        _semanticLabel = semanticLabel;

  factory SoriBadge.level(String level, {Color color = SoriColors.primary, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      label: level,
      semanticLabel: 'Level $level',
    );
  }

  factory SoriBadge.xp(int xp, {Color color = SoriColors.primary, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      label: '$xp',
      icon: Icons.bolt_rounded,
      semanticLabel: '$xp XP',
    );
  }

  factory SoriBadge.streak(int days, {Color color = SoriColors.warning, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      label: '$days',
      emoji: '🔥',
      semanticLabel: 'Streak $days Tage',
    );
  }

  /// 배경 luminance 기준 텍스트 색 자동 선택.
  /// `#D4A22E` (warning) luminance ≈ 0.43 → 먹 ink (light), 충분한 대비.
  Color _fgFor(BuildContext ctx) {
    final lum = color.computeLuminance();
    if (lum > 0.55) {
      return SoriColors.lightText; // dark ink on bright bg
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fgFor(context);
    final textStyle = TextStyle(
      fontFamily: 'Pretendard',
      color: fg,
      fontWeight: FontWeight.w900,
      fontSize: size * 0.5,
      letterSpacing: 0.3,
      height: 1.1,
    );

    final children = <Widget>[
      if (_emoji != null) ...[
        Text(_emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
      ],
      if (_icon != null) ...[
        Icon(_icon, color: fg, size: size * 0.55),
        const SizedBox(width: 2),
      ],
      Text(_label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
    ];

    return Semantics(
      label: _semanticLabel,
      excludeSemantics: true,
      child: Container(
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: SoriRadius.brPill,
        ),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// 별 0–3 표시. accent 또는 default warning 색.
class SoriStars extends StatelessWidget {
  final int filled;
  final int total;
  final double size;
  final Color? color;

  const SoriStars({
    super.key,
    required this.filled,
    this.total = 3,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? SoriColors.warning;
    final s = SoriSurfaces.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < filled ? c : s.textDim,
            ),
          ),
      ],
    );
  }
}
