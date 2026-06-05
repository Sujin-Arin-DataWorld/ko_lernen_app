import 'package:flutter/material.dart';

import 'tokens.dart';

/// **HubProgressHeader** — 허브 화면의 진행도 헤더.
///
/// 아이콘, 제목(레벨), 부제(다음 목표), 진행도바를 표시.
/// 단청 색상으로 악센트.
class HubProgressHeader extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final double progress; // 0.0 ~ 1.0

  const HubProgressHeader({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 아이콘 + 제목 행 ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(SoriRadius.md),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: s.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // ── 진행도 바 ──
        ClipRRect(
          borderRadius: BorderRadius.circular(SoriRadius.sm),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: accentColor.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        ),
      ],
    );
  }
}
