import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import 'card.dart';
import 'progress.dart';
import 'tokens.dart';

/// 주간 진행 위젯 묶음 — 홈 스트릭 칩 시트가 사용 (§6.1 블록 1·5).
/// 2026-08-04 감사 #9: home_screen 다이어트로 분리(자기완결 위젯 3종).

// ════════════════════════════════════════════════════════════════════════
// C. Inline stat chip row — streak · XP · shield
// ════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════
// C2. Daily goal progress — 오늘 XP / 목표 (모멘텀·리텐션)
// ════════════════════════════════════════════════════════════════════════
/// **디딤돌** — 첫 주(또는 스트릭이 끊긴 뒤)의 진행 표시.
///
/// 0%짜리 진행바 두 개로 첫 화면을 시작하지 않기 위한 대체물.
/// 이번 주 7칸 중 오늘 칸을 밝히고, 스트릭에 해당하는 지난 칸을 채운다.
/// 주 시작(월/일)과 요일 약칭은 [MaterialLocalizations] 를 따라 로케일별로
/// 자동 정렬된다 — 독일어는 월요일 시작, 영어는 일요일 시작.
class WeekSteppingStonesRow extends StatelessWidget {
  final int streak;
  final int xpToday;
  final int goal;
  const WeekSteppingStonesRow({
    super.key,
    required this.streak,
    required this.xpToday,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final ml = MaterialLocalizations.of(context);
    final now = DateTime.now();
    // 이번 주 첫 날 (로케일의 주 시작 요일 기준).
    final firstDayIdx = ml.firstDayOfWeekIndex; // 0 = 일요일
    final todayIdx = now.weekday % 7; // DateTime: 월=1..일=7 → 일=0
    final offset = (todayIdx - firstDayIdx + 7) % 7;
    final locale = Localizations.localeOf(context).toString();
    // §7.1: 요일 디딤돌은 2글자 축약(Mo Di Mi …) — narrow 1글자는 월/수(M/M)·
    // 토/일(S/S)이 구분 불가. 스크린리더 라벨은 전체 요일명(EEEE).
    DateTime dayOf(int slot) => now.add(Duration(days: slot - offset));
    String short2(int slot) {
      final abbr = DateFormat.E(locale).format(dayOf(slot)).replaceAll('.', '');
      return abbr.length <= 2 ? abbr : abbr.substring(0, 2);
    }

    return SoriCard(
      variant: SoriCardVariant.compact,
      semanticLabel: t.homeFirstWeekTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.homeFirstWeekTitle,
            style: SoriTextTheme.of(context).cardTitle,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _Stone(
                    label: short2(i),
                    fullDayName: DateFormat.EEEE(locale).format(dayOf(i)),
                    isToday: i == offset,
                    // 오늘 이전 칸 중 스트릭 안에 드는 날은 채운다.
                    isDone: i < offset && (offset - i) <= streak,
                  ),
                ),
            ],
          ),
          if (goal > 0) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '$xpToday / $goal XP',
              style: SoriTextTheme.of(context).caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  final String label;

  /// 스크린리더용 전체 요일명 (§7.1 — 시각 라벨은 2글자 축약).
  final String fullDayName;
  final bool isToday;
  final bool isDone;
  const _Stone({
    required this.label,
    required this.fullDayName,
    required this.isToday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final Color fill;
    final Color border;
    final Color fg;
    if (isToday) {
      fill = SoriColors.gold.withValues(alpha: 0.18);
      border = SoriColors.goldOnLight;
      fg = SoriColors.goldOnLight;
    } else if (isDone) {
      fill = SoriColors.primarySoft;
      border = SoriColors.primary;
      fg = SoriColors.primaryOnLight;
    } else {
      fill = Colors.transparent;
      border = SoriColors.lightBorderStrong;
      fg = s.textMuted;
    }
    final stone = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(SoriRadius.xs),
              border: Border.all(color: border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDone
                  ? Icons.check_rounded
                  : (isToday ? Icons.circle : Icons.remove),
              size: isToday ? 9 : 13,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: SoriFonts.sans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isToday ? SoriColors.goldOnLight : s.textMuted,
            ),
          ),
        ],
      ),
    );
    // §7.1: 시각은 2글자, 스크린리더는 전체 요일명.
    return Semantics(label: fullDayName, excludeSemantics: true, child: stone);
  }
}

class DailyGoalCard extends StatelessWidget {
  final int xpToday;
  final int goal;
  const DailyGoalCard({super.key, required this.xpToday, required this.goal});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final today = xpToday;
    final done = goal > 0 && today >= goal;
    final ratio = goal > 0 ? (today / goal).clamp(0.0, 1.0) : 0.0;
    final accent = done ? SoriColors.success : SoriColors.tiger;
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.flag_outlined,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done ? t.homeDailyGoalDone : t.homeDailyGoalLabel,
                  // §4.3: 2줄 허용.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: SoriFonts.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$today/$goal XP',
                style: TextStyle(
                  fontFamily: SoriFonts.sans,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: s.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SoriProgressBar(value: ratio, color: accent),
        ],
      ),
    );
  }
}
