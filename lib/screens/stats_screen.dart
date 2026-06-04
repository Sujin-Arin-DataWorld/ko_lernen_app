import 'package:flutter/material.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/progress.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    final vokTotal = Storage.vokCorrect + Storage.vokWrong;
    final vokAccuracy = vokTotal == 0
        ? 0
        : (Storage.vokCorrect * 100 ~/ vokTotal);
    final chosungTotal = Storage.chosungCorrect + Storage.chosungWrong;
    final chosungAccuracy = chosungTotal == 0
        ? 0
        : (Storage.chosungCorrect * 100 ~/ chosungTotal);
    final wordleTotal = Storage.wordleWins + Storage.wordleLosses;
    final wordleRate = wordleTotal == 0
        ? 0
        : (Storage.wordleWins * 100 ~/ wordleTotal);

    // 첫 진입 감지 — XP 0 + 시나리오 0 + 모든 퀴즈 카운트 0.
    final isFirstEntry =
        Storage.xp == 0 &&
        Storage.completedScenarios.isEmpty &&
        vokTotal == 0 &&
        chosungTotal == 0 &&
        wordleTotal == 0 &&
        Storage.streakDays == 0;

    if (isFirstEntry) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.statsHeader,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SoriEmptyState(
          asset: 'assets/illustrations/empty/studyroom_waiting.png',
          icon: Icons.auto_stories_outlined,
          title: t.statsFirstEntryTitle,
          body: t.statsFirstEntryBody,
          ctaLabel: t.statsFirstEntryCta,
          onCta: () => Navigator.of(context).pushNamed('/scenarios'),
          illustrationMaxHeight: 220,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.statsHeader,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: soriClampPadding(
          MediaQuery.sizeOf(context).width,
          base: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        ),
        children: [
          // ── 한옥 마당 헤더 (성취 / 황혼 톤) ──
          const HanokHeader(
            asset: 'assets/illustrations/hanok/achievements.png',
            fallbackIcon: Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 12),

          // ── 친구들 hero (호랑이 + 갓 쓴 까치 — 함께 학습) ──
          const Center(
            child: SizedBox(
              width: 220,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 20,
                    bottom: 0,
                    child: Mascot.tiger(size: 156, animate: true),
                  ),
                  Positioned(
                    right: 18,
                    top: 10,
                    child: Mascot.magpie(size: 86, animate: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Streak Hero
          _StreakHero(
            streak: Storage.streakDays,
            best: Storage.bestStreak,
            shields: Storage.streakFreezes,
            label: t.statsStreak,
            bestLabel: t.statsBestStreak,
            shieldLabel: t.statsStreakShield,
            shieldHint: t.statsStreakShieldHint,
          ),
          const SizedBox(height: 12),

          // P1-4: G9 7일 heatmap
          _StreakWeekHeatmap(streak: Storage.streakDays),
          const SizedBox(height: 16),

          // ── Szenario-Fortschritt (XP/Level/Badges) ──
          _XpCard(
            xp: Storage.xp,
            level: Storage.xpLevel,
            toNext: Storage.xpToNext,
            scenariosDone: Storage.completedScenarios.length,
            badges: Storage.earnedBadges,
            title: t.statsXpTitle,
            levelLabel: t.statsLevelLabel(Storage.xpLevel),
            toNextLabel: t.statsToNextLevel(
              Storage.xpToNext,
              Storage.xpLevel + 1,
            ),
            scenariosLabel: t.statsScenariosCompleted,
            badgesTitle: t.statsBadgesTitle,
            noBadges: t.statsNoBadges,
          ),
          const SizedBox(height: 12),

          // Vocab
          _StatCard(
            icon: Icons.style_outlined,
            title: t.moduleVocabTitle,
            color: SoriColors.info,
            rows: [
              _MetricRow(
                label: '✅ ${t.statsGotIt}',
                value: '${Storage.vokCorrect}',
              ),
              _MetricRow(
                label: '❌ ${t.statsNotGotIt}',
                value: '${Storage.vokWrong}',
              ),
              _MetricRow(
                label: '⏭ ${t.statsSkipped}',
                value: '${Storage.vokSkipped}',
              ),
              _MetricRow(
                label: '📚 ${t.statsCardsLearned}',
                value: '${Storage.vokSeenIds.length}',
              ),
              _MetricRow(
                label: '🎯 ${t.statsAccuracy}',
                value: '$vokAccuracy %',
                accent: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chosung
          _StatCard(
            icon: Icons.spellcheck,
            title: t.gameChosungTitle,
            color: SoriColors.primary,
            rows: [
              _MetricRow(
                label: '✅ ${t.statsCorrect}',
                value: '${Storage.chosungCorrect}',
              ),
              _MetricRow(
                label: '❌ ${t.statsWrong}',
                value: '${Storage.chosungWrong}',
              ),
              _MetricRow(
                label: '🎯 ${t.statsAccuracy}',
                value: '$chosungAccuracy %',
                accent: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wordle
          _StatCard(
            icon: Icons.grid_4x4,
            title: t.gameWordleTitle,
            color: SoriColors.success,
            rows: [
              _MetricRow(
                label: '🏆 ${t.statsWordleWins}',
                value: '${Storage.wordleWins}',
              ),
              _MetricRow(
                label: '💔 ${t.statsLosses}',
                value: '${Storage.wordleLosses}',
              ),
              _MetricRow(
                label: '🔥 ${t.statsWordleStreak}',
                value: '${Storage.wordleStreak}',
              ),
              _MetricRow(
                label: '⭐ ${t.statsBestShort}',
                value: '${Storage.wordleBestStreak}',
              ),
              _MetricRow(
                label: '🎯 ${t.statsWinRate}',
                value: '$wordleRate %',
                accent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  final int streak;
  final int best;
  final int shields;
  final String label;
  final String bestLabel;
  final String shieldLabel;
  final String shieldHint;
  const _StreakHero({
    required this.streak,
    required this.best,
    required this.shields,
    required this.label,
    required this.bestLabel,
    required this.shieldLabel,
    required this.shieldHint,
  });

  @override
  Widget build(BuildContext context) {
    final ss = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.warning,
      tinted: true,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SoriColors.warning.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              streak >= 1
                  ? Icons.local_fire_department_rounded
                  : Icons.local_fire_department_outlined,
              size: 38,
              color: SoriColors.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ss.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: ss.text,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$bestLabel: $best',
                  style: TextStyle(color: ss.textMuted, fontSize: 12),
                ),
                if (shields > 0) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    label: '$shieldLabel: $shields. $shieldHint',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SoriColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: SoriColors.primary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 13,
                            color: SoriColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$shieldLabel × $shields',
                            style: TextStyle(
                              color: SoriColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<_MetricRow> rows;
  const _StatCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Divider(height: 18, color: s.surfaceAlt),
          ...rows,
        ],
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  final int xp;
  final int level;
  final int toNext;
  final int scenariosDone;
  final List<String> badges;
  final String title;
  final String levelLabel;
  final String toNextLabel;
  final String scenariosLabel;
  final String badgesTitle;
  final String noBadges;

  const _XpCard({
    required this.xp,
    required this.level,
    required this.toNext,
    required this.scenariosDone,
    required this.badges,
    required this.title,
    required this.levelLabel,
    required this.toNextLabel,
    required this.scenariosLabel,
    required this.badgesTitle,
    required this.noBadges,
  });

  /// Badge id → emoji + label (de/en kombiniert da Badges Eigennamen sind)
  static const _badgeMeta = {
    'cafe_starter': {'emoji': '☕', 'label': 'Café Starter'},
    'airport_arrival': {'emoji': '✈️', 'label': 'Flughafen Pro'},
    'introduce_yourself': {'emoji': '👋', 'label': 'Smooth Intro'},
    'warm_encouragement': {'emoji': '💗', 'label': 'Heart Healer'},
    'couple_argument': {'emoji': '💢', 'label': 'Repair Master'},
  };

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final progress = ((xp % 100) / 100.0).clamp(0.0, 1.0);

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: SoriColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                levelLabel,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(SoriColors.primary, s.text, 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // XP big number + scenarios chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$xp',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: s.text,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'XP',
                        style: TextStyle(
                          color: s.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SoriChip(
                  label: '🎬 $scenariosDone $scenariosLabel',
                  accent: SoriColors.primary,
                  variant: SoriChipVariant.soft,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SoriProgressBar(value: progress, thickness: 10, animated: true),
          const SizedBox(height: 6),
          Text(
            toNextLabel,
            style: TextStyle(fontSize: 11.5, color: s.textMuted),
          ),
          Divider(height: 22, color: s.surfaceAlt),

          // Badges
          Text(
            badgesTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: s.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (badges.isEmpty)
            Text(noBadges, style: TextStyle(color: s.textDim, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((id) {
                final meta = _badgeMeta[id] ?? {'emoji': '🏅', 'label': id};
                return SoriChip(
                  label: '${meta['emoji']} ${meta['label']}',
                  accent: SoriColors.warning,
                  variant: SoriChipVariant.soft,
                  fontSize: 12,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// P1-4: G9 7일 heatmap
class _StreakWeekHeatmap extends StatelessWidget {
  final int streak;
  const _StreakWeekHeatmap({required this.streak});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final today = DateTime.now().weekday % 7; // 0=Sunday, 1=Monday...

    return SoriCard(
      variant: SoriCardVariant.compact,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final isToday = i == today;
              final isDone = streak > (6 - i);
              final color = isDone
                  ? SoriColors.success
                  : isToday
                      ? SoriColors.warning
                      : s.border;

              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: s.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDone ? 1.0 : 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday && !isDone
                          ? Border.all(color: color, width: 1.5)
                          : null,
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : isToday
                                ? const Icon(Icons.favorite_rounded, size: 10, color: SoriColors.warning)
                                : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _MetricRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: s.text, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: accent ? SoriColors.primary : s.text,
              fontSize: accent ? 18 : 15,
              fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
