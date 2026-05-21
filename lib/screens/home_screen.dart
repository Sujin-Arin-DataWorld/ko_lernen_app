import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/daily_char_service.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import 'daily_char_sheet.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/flying_magpie.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
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
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── 한옥 마당 배경 — 아주 느린 Ken Burns 줌으로 "숨쉬는" 배경 ──
          // 직접 제작한 madang 일러스트 — 낮(light)/밤(dark) 한옥 마당.
          Positioned.fill(
            child: SoriKenBurns(
              child: Image.asset(
                isDark
                    ? 'assets/illustrations/hanok/madang(dark).png'
                    : 'assets/illustrations/hanok/madang(light).png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // ── Ambient 입자 — 라이트: 매화 꽃잎 / 다크: 따뜻한 불씨 ──
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 13)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header (PNG 로고 — HanLogo 갓+한 brand) ─────────
                  _Header(logoAsset: 'assets/icons/icon-192.png'),
                  const SizedBox(height: Spacing.lg),

                  // ── Stats peek ──────────────────────────────────────
                  _StatsPeek(
                    streak: Storage.streakDays,
                    xp: Storage.xp,
                    level: Storage.xpLevel,
                    xpToNext: Storage.xpToNext,
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── Daily Calligraphy (오늘의 글자) ─────────────────
                  _DailyCharCard(
                    char: DailyCharService.today(),
                    doneToday: Storage.calligraphyDoneToday,
                    onTap: () => showDailyCharSheet(context).then((_) {
                      if (mounted) setState(() {}); // refresh "done" state
                    }),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // ── Heute (Hero Szenario) ───────────────────────────
                  _SectionLabel(label: 'Heute'),
                  const SizedBox(height: Spacing.sm),
                  SoriEntrance(
                    delay: const Duration(milliseconds: 60),
                    child: _TodayScenarioCard(
                      scenario: _today,
                      loading: _loadingScenario,
                      lang: lang,
                      // 시나리오 완료 후 복귀 시 XP·streak·추천을 갱신.
                      onTap: _today == null
                          ? null
                          : () async {
                              await Navigator.pushNamed(
                                context,
                                '/scenario',
                                arguments: _today!.id,
                              );
                              if (mounted) await _loadToday();
                            },
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // ── Lernmodule grid (2×2) ───────────────────────────
                  _SectionLabel(label: t.sectionModules),
                  const SizedBox(height: Spacing.sm),
                  SoriEntrance(
                    delay: const Duration(milliseconds: 160),
                    child: _ModulesGrid(t: t),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // ── Spiele (2 cards) ────────────────────────────────
                  _SectionLabel(label: t.sectionGames),
                  const SizedBox(height: Spacing.sm),
                  SoriEntrance(
                    delay: const Duration(milliseconds: 260),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniModuleCard(
                            emoji: '🔠',
                            title: t.gameChosungTitle,
                            accent: SoriColors.primary,
                            onTap: () =>
                                Navigator.pushNamed(context, '/chosung'),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _MiniModuleCard(
                            emoji: '🟩',
                            title: t.gameWordleTitle,
                            accent: SoriColors.success,
                            onTap: () =>
                                Navigator.pushNamed(context, '/wordle'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spacing.xxxl),
                  Center(
                    child: Text(
                      t.footerCheer,
                      style: TextStyle(
                        color: s.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 좋은 소식을 물고 오는 까치 — 화면 상단을 가로질러 비행 ──
          const Positioned.fill(child: IgnorePointer(child: FlyingMagpie())),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String logoAsset;
  const _Header({required this.logoAsset});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Row(
      children: [
        // HanLogo PNG — 갓 silhouette + 한 글자 + 단청 도트 brand
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            logoAsset,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
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
        width: 40,
        height: 40,
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
  const _StatsPeek({
    required this.streak,
    required this.xp,
    required this.level,
    required this.xpToNext,
  });

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
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: s.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Tage',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: s.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        child: SizedBox(height: 120, child: const AppLoading()),
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
              _ScenarioAvatar(
                emoji: scenario!.emoji,
                sidekick: scenario!.sidekick,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
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
            Expanded(
              child: _MiniModuleCard(
                emoji: '🔤',
                title: t.moduleHangulTitle,
                subtitle: t.moduleHangulDesc,
                accent: SoriColors.hangul,
                onTap: () => Navigator.pushNamed(context, '/hangul'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                emoji: '📚',
                title: t.moduleVocabTitle,
                subtitle: t.moduleVocabDesc,
                accent: SoriColors.primary,
                onTap: () => Navigator.pushNamed(context, '/vocab'),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniModuleCard(
                emoji: '📝',
                title: t.moduleGrammarTitle,
                subtitle: t.moduleGrammarDesc,
                accent: SoriColors.warning,
                onTap: () => Navigator.pushNamed(context, '/grammar'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                emoji: '💬',
                title: t.moduleScenariosTitle,
                subtitle: t.moduleScenariosDesc,
                accent: SoriColors.accent,
                onTap: () => Navigator.pushNamed(context, '/scenarios'),
              ),
            ),
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
            width: 40,
            height: 40,
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

/// Daily Calligraphy compact card — char + "오늘의 글자" + status
class _DailyCharCard extends StatelessWidget {
  final String char;
  final bool doneToday;
  final VoidCallback onTap;

  const _DailyCharCard({
    required this.char,
    required this.doneToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.hangul,
      tinted: !doneToday,
      onTap: onTap,
      child: Row(
        children: [
          // Char display
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoriColors.hangul.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              char,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: SoriColors.hangul,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dailyCharTitle,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doneToday ? t.dailyCharDoneToday : t.dailyCharSubtitle,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11.5,
                    color: doneToday ? SoriColors.success : s.textMuted,
                    fontWeight: doneToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Done badge or chevron
          if (doneToday)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: SoriColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: SoriColors.hangul.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}

/// Hero card avatar — sidekick mascot if known, else emoji tile.
class _ScenarioAvatar extends StatelessWidget {
  final String emoji;
  final String? sidekick;
  const _ScenarioAvatar({required this.emoji, this.sidekick});

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot.forSpeaker(
      sidekick ?? '',
      size: 64,
      emotion: MascotEmotion.smile,
      animate: true,
    );
    // 마스코트 일러스트는 자체 원형 구성이 있어 박스 없이 그대로 노출.
    if (mascot != null) {
      return SizedBox(width: 64, height: 64, child: mascot);
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
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
