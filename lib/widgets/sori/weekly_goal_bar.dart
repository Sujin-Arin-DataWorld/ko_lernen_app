import 'package:flutter/material.dart';

import 'tokens.dart';

/// 계 주간 공동 목표 진행 바 (`32 / 50 팩`). plan §8.1.
class WeeklyGoalBar extends StatelessWidget {
  final int progress;
  final int goal;
  final String label;

  const WeeklyGoalBar({
    super.key,
    required this.progress,
    required this.goal,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final frac = goal <= 0 ? 0.0 : (progress / goal).clamp(0.0, 1.0);
    final done = goal > 0 && progress >= goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.emoji_events_rounded : Icons.flag_outlined,
              size: 16,
              color: done ? SoriColors.gold : SoriColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: s.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$progress / $goal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: done ? SoriColors.gold : s.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(SoriRadius.pill),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: s.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? SoriColors.gold : SoriColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
