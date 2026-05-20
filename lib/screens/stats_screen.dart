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
