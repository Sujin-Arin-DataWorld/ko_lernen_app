import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import 'sheet.dart';
import 'tokens.dart';
import 'week_progress.dart';

/// 스트릭 칩 탭 — 주간 디딤돌 + 오늘 목표 시트 (§6.1: 구 _StatChipRow·
/// _DailyGoalCard 블록의 자리. 수치 전체 상세는 /stats).
///
/// 2026-08-14 Phase 2a: `home_screen.dart` 의 `_showWeekSheet` 본문을 공용화.
/// 시트가 닫힌 뒤의 갱신(setState)은 호출부 소관이다.
Future<void> showSoriWeekSheet(BuildContext context) {
  return showSoriSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DailyGoalCard(xpToday: Storage.xpToday, goal: Storage.dailyGoalXp),
          const SizedBox(height: Spacing.md),
          WeekSteppingStonesRow(
            streak: Storage.streakDays,
            xpToday: Storage.xpToday,
            goal: Storage.dailyGoalXp,
          ),
        ],
      ),
    ),
  );
}
