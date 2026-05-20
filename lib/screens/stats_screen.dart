import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    final vokTotal    = Storage.vokCorrect + Storage.vokWrong;
    final vokAccuracy = vokTotal == 0 ? 0 : (Storage.vokCorrect * 100 ~/ vokTotal);
    final chosungTotal = Storage.chosungCorrect + Storage.chosungWrong;
    final chosungAccuracy = chosungTotal == 0 ? 0 : (Storage.chosungCorrect * 100 ~/ chosungTotal);
    final wordleTotal = Storage.wordleWins + Storage.wordleLosses;
    final wordleRate  = wordleTotal == 0 ? 0 : (Storage.wordleWins * 100 ~/ wordleTotal);

    return Scaffold(
      appBar: AppBar(title: Text(t.statsHeader, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Streak Hero
          _StreakHero(streak: Storage.streakDays, best: Storage.bestStreak, label: t.statsStreak, bestLabel: t.statsBestStreak),
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
            toNextLabel: t.statsToNextLevel(Storage.xpToNext, Storage.xpLevel + 1),
            scenariosLabel: t.statsScenariosCompleted,
            badgesTitle: t.statsBadgesTitle,
            noBadges: t.statsNoBadges,
          ),
          const SizedBox(height: 12),

          // Vocab
          _StatCard(
            icon:   Icons.style_outlined,
            title:  t.moduleVocabTitle,
            color:  AppColors.vocab,
            rows: [
              _MetricRow(label: '✅ ${t.statsGotIt}', value: '${Storage.vokCorrect}'),
              _MetricRow(label: '❌ ${t.statsNotGotIt}', value: '${Storage.vokWrong}'),
              _MetricRow(label: '⏭ ${t.statsSkipped}', value: '${Storage.vokSkipped}'),
              _MetricRow(label: '📚 ${t.statsCardsLearned}', value: '${Storage.vokSeenIds.length}'),
              _MetricRow(label: '🎯 ${t.statsAccuracy}', value: '$vokAccuracy %', accent: true),
            ],
          ),
          const SizedBox(height: 12),

          // Chosung
          _StatCard(
            icon:   Icons.spellcheck,
            title:  t.gameChosungTitle,
            color:  AppColors.primary,
            rows: [
              _MetricRow(label: '✅ ${t.statsCorrect}', value: '${Storage.chosungCorrect}'),
              _MetricRow(label: '❌ ${t.statsWrong}',  value: '${Storage.chosungWrong}'),
              _MetricRow(label: '🎯 ${t.statsAccuracy}', value: '$chosungAccuracy %', accent: true),
            ],
          ),
          const SizedBox(height: 12),

          // Wordle
          _StatCard(
            icon:   Icons.grid_4x4,
            title:  t.gameWordleTitle,
            color:  AppColors.listen,
            rows: [
              _MetricRow(label: '🏆 ${t.statsWordleWins}', value: '${Storage.wordleWins}'),
              _MetricRow(label: '💔 ${t.statsLosses}', value: '${Storage.wordleLosses}'),
              _MetricRow(label: '🔥 ${t.statsWordleStreak}', value: '${Storage.wordleStreak}'),
              _MetricRow(label: '⭐ ${t.statsBestShort}',  value: '${Storage.wordleBestStreak}'),
              _MetricRow(label: '🎯 ${t.statsWinRate}',  value: '$wordleRate %', accent: true),
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
  final String label;
  final String bestLabel;
  const _StreakHero({required this.streak, required this.best, required this.label, required this.bestLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE64980), Color(0xFF845EF7), Color(0xFF339AF0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('🔥', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
                Text('$streak', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 2),
                Text('$bestLabel: $best', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
  const _StatCard({required this.icon, required this.title, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const Divider(height: 18, color: AppColors.surfaceAlt),
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
    'cafe_starter':       {'emoji': '☕', 'label': 'Café Starter'},
    'airport_arrival':    {'emoji': '✈️', 'label': 'Flughafen Pro'},
    'introduce_yourself': {'emoji': '👋', 'label': 'Smooth Intro'},
    'warm_encouragement': {'emoji': '💗', 'label': 'Heart Healer'},
    'couple_argument':    {'emoji': '💢', 'label': 'Repair Master'},
  };

  @override
  Widget build(BuildContext context) {
    final progress = ((xp % 100) / 100.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.hangul.withValues(alpha: 0.06),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                levelLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(AppColors.primary, AppColors.text, 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // XP big number + progress bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$xp',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text('XP', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎬 $scenariosDone $scenariosLabel',
                  style: const TextStyle(fontSize: 11, color: AppColors.text, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            toNextLabel,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const Divider(height: 22, color: AppColors.surfaceAlt),

          // Badges
          Text(
            badgesTitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (badges.isEmpty)
            Text(
              noBadges,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((id) {
                final meta = _badgeMeta[id] ?? {'emoji': '🏅', 'label': id};
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(meta['emoji']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        meta['label']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
  const _MetricRow({required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.text, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: accent ? AppColors.primary : AppColors.text,
              fontSize: accent ? 18 : 15,
              fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
