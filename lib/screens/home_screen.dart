import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/tokens.dart';

/// Home — Bento Layout.
///
/// Aufbau:
///   1. Header (brand + actions)
///   2. Stats peek (streak, XP, level)
///   3. Hero card "Heute empfohlen" (oder All-done)
///   4. Lernmodule 2×2 grid
///   5. Spiele Sektion (2 Karten)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Scenario? _today;
  bool _loadingScenario = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    final userLevel = LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completed = Storage.completedScenarios.toSet();

    // Erste offene Szenario auf User-Level
    Scenario? pick;
    for (final s in list.where((s) => s.level == userLevel)) {
      if (!completed.contains(s.id)) {
        pick = s;
        break;
      }
    }
    // Fallback: erste offene auf irgendeinem Level
    if (pick == null) {
      for (final s in list) {
        if (!completed.contains(s.id)) {
          pick = s;
          break;
        }
      }
    }
    // Last resort: erste Szenario
    pick ??= list.isEmpty ? null : list.first;

    setState(() {
      _today = pick;
      _loadingScenario = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              _Header(svgIcon: 'assets/icons/icon.svg'),
              const SizedBox(height: Spacing.lg),

              // ── Stats peek ──────────────────────────────────────
              _StatsPeek(
                streak: Storage.streakDays,
                xp: Storage.xp,
                level: Storage.xpLevel,
                xpToNext: Storage.xpToNext,
              ),
              const SizedBox(height: Spacing.xl),

              // ── Heute (Hero Szenario) ───────────────────────────
              _SectionLabel(label: 'Heute'),
              const SizedBox(height: Spacing.sm),
              _TodayScenarioCard(
                scenario: _today,
                loading: _loadingScenario,
                lang: lang,
                onTap: _today == null
                    ? null
                    : () => Navigator.pushNamed(context, '/scenario', arguments: _today!.id),
              ),
              const SizedBox(height: Spacing.xl),

              // ── Lernmodule grid (2×2) ───────────────────────────
              _SectionLabel(label: t.sectionModules),
              const SizedBox(height: Spacing.sm),
              _ModulesGrid(t: t),
              const SizedBox(height: Spacing.xl),

              // ── Spiele (2 cards) ────────────────────────────────
              _SectionLabel(label: t.sectionGames),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(child: _MiniModuleCard(
                    emoji: '🔠',
                    title: t.gameChosungTitle,
                    accent: SoriColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/chosung'),
                  )),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: _MiniModuleCard(
                    emoji: '🟩',
                    title: t.gameWordleTitle,
                    accent: SoriColors.success,
                    onTap: () => Navigator.pushNamed(context, '/wordle'),
                  )),
                ],
              ),

              const SizedBox(height: Spacing.xxxl),
              Center(
                child: Text(
                  t.footerCheer,
                  style: TextStyle(color: s.textDim, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String svgIcon;
  const _Header({required this.svgIcon});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Row(
      children: [
        SizedBox(width: 48, height: 48, child: SvgPicture.asset(svgIcon)),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hangul Sori',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: s.text,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                t.homeGreetingLearn,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: s.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.bar_chart_rounded,
          onTap: () => Navigator.pushNamed(context, '/stats'),
        ),
        const SizedBox(width: Spacing.xs),
        _RoundIconButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: s.surface,
          shape: BoxShape.circle,
          border: Border.all(color: s.border),
        ),
        child: Icon(icon, size: 20, color: s.textMuted),
      ),
    );
  }
}

// ─── Stats Peek ──────────────────────────────────────────────────────────

class _StatsPeek extends StatelessWidget {
  final int streak;
  final int xp;
  final int level;
  final int xpToNext;
  const _StatsPeek({required this.streak, required this.xp, required this.level, required this.xpToNext});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Row(
        children: [
          // Streak
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$streak',
                        style: TextStyle(fontFamily: 'Pretendard', color: s.text, fontWeight: FontWeight.w900, fontSize: 18, height: 1)),
                    Text('Tage',
                        style: TextStyle(fontFamily: 'Pretendard', color: s.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 26, color: s.border),
          // XP progress
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: Spacing.md),
              child: SoriXpProgress(
                currentXp: xp,
                level: level,
                trailingLabel: '$xp XP',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today's Scenario Hero Card ──────────────────────────────────────────

class _TodayScenarioCard extends StatelessWidget {
  final Scenario? scenario;
  final bool loading;
  final String lang;
  final VoidCallback? onTap;

  const _TodayScenarioCard({
    required this.scenario,
    required this.loading,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    if (loading) {
      return SoriCard(
        variant: SoriCardVariant.hero,
        accent: SoriColors.primary,
        tinted: true,
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: SoriColors.primary,
            ),
          ),
        ),
      );
    }

    if (scenario == null) {
      return SoriCard(
        variant: SoriCardVariant.hero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Center(
            child: Text(
              t.homeNoScenario,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: s.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final title = scenario!.title.pick(lang);

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScenarioAvatar(emoji: scenario!.emoji, sidekick: scenario!.sidekick),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.homeRecommended,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: SoriColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: s.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        SoriBadge.level(scenario!.level.display, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '5–7 min · +${scenario!.xpReward} XP',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            color: s.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: SoriColors.primary,
                  borderRadius: SoriRadius.brPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.scenarioStartBtn,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Modules Grid (2×2) ──────────────────────────────────────────────────

class _ModulesGrid extends StatelessWidget {
  final AppL10n t;
  const _ModulesGrid({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MiniModuleCard(
              emoji: '🔤',
              title: t.moduleHangulTitle,
              subtitle: t.moduleHangulDesc,
              accent: SoriColors.hangul,
              onTap: () => Navigator.pushNamed(context, '/hangul'),
            )),
            const SizedBox(width: Spacing.md),
            Expanded(child: _MiniModuleCard(
              emoji: '📚',
              title: t.moduleVocabTitle,
              subtitle: t.moduleVocabDesc,
              accent: SoriColors.primary,
              onTap: () => Navigator.pushNamed(context, '/vocab'),
            )),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(child: _MiniModuleCard(
              emoji: '📝',
              title: t.moduleGrammarTitle,
              subtitle: t.moduleGrammarDesc,
              accent: SoriColors.warning,
              onTap: () => Navigator.pushNamed(context, '/grammar'),
            )),
            const SizedBox(width: Spacing.md),
            Expanded(child: _MiniModuleCard(
              emoji: '🎧',
              title: t.moduleListenTitle,
              subtitle: t.moduleListenDesc,
              accent: SoriColors.info,
              onTap: () => Navigator.pushNamed(context, '/listening'),
            )),
          ],
        ),
      ],
    );
  }
}

class _MiniModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _MiniModuleCard({
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: s.text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: s.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────

/// Hero card avatar — sidekick mascot if known, else emoji tile.
class _ScenarioAvatar extends StatelessWidget {
  final String emoji;
  final String? sidekick;
  const _ScenarioAvatar({required this.emoji, this.sidekick});

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot.forSpeaker(sidekick ?? '', size: 56, emotion: MascotEmotion.smile);
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      alignment: Alignment.center,
      child: mascot ?? Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: s.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
