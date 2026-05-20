import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriBadge** — level / XP / streak / stars 등 작은 상태 표시.
///
/// 사용:
/// ```dart
/// SoriBadge.level('A2', color: SoriColors.success)
/// SoriBadge.xp(240)
/// SoriBadge.streak(5)
/// SoriBadge.stars(filled: 2, total: 3)
/// ```
class SoriBadge extends StatelessWidget {
  final Widget content;
  final Color color;
  final double size;

  const SoriBadge._({
    required this.content,
    required this.color,
    this.size = 22,
  });

  factory SoriBadge.level(String level, {Color color = SoriColors.primary, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      content: Text(
        level,
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  factory SoriBadge.xp(int xp, {Color color = SoriColors.primary, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.55),
          const SizedBox(width: 2),
          Text(
            '$xp',
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ),
    );
  }

  factory SoriBadge.streak(int days, {Color color = SoriColors.warning, double size = 22}) {
    return SoriBadge._(
      color: color,
      size: size,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: SoriRadius.brPill,
      ),
      alignment: Alignment.center,
      child: content,
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
