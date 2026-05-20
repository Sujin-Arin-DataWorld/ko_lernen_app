import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriProgressBar** — Duolingo 식 두꺼운 라운드 progress.
///
/// 사용:
/// ```dart
/// SoriProgressBar(value: 0.6, thickness: 10)  // linear
/// SoriProgressBar(value: 0.6, thickness: 10, color: SoriColors.success, animated: true)
/// ```
class SoriProgressBar extends StatelessWidget {
  final double value;          // 0.0 - 1.0
  final double thickness;
  final Color? color;
  final Color? trackColor;
  final bool animated;
  final Duration duration;

  const SoriProgressBar({
    super.key,
    required this.value,
    this.thickness = 8,
    this.color,
    this.trackColor,
    this.animated = false,
    this.duration = SoriMotion.verySlow,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final fg = color ?? SoriColors.primary;
    final bg = trackColor ?? s.surfaceAlt;

    return ClipRRect(
      borderRadius: BorderRadius.circular(thickness),
      child: SizedBox(
        height: thickness,
        child: Stack(
          children: [
            Container(color: bg),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: animated
                  ? AnimatedContainer(
                      duration: duration,
                      curve: SoriMotion.gentle,
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(thickness),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(thickness),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// XP-style progress with label.
class SoriXpProgress extends StatelessWidget {
  final int currentXp;
  final int level;
  final int xpPerLevel;
  final String? trailingLabel;

  const SoriXpProgress({
    super.key,
    required this.currentXp,
    required this.level,
    this.xpPerLevel = 100,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final progress = ((currentXp % xpPerLevel) / xpPerLevel).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lv $level',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: s.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: s.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SoriProgressBar(value: progress, thickness: 10, animated: true),
      ],
    );
  }
}
