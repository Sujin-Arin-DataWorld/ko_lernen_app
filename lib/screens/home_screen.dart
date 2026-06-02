import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/hanok_stage.dart';
import '../models/scenario.dart';
import '../services/daily_char_service.dart';
import '../services/hanok_stage_service.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import 'daily_char_sheet.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/flying_magpie.dart';
import '../widgets/sori/hanok_cinematic.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/tokens.dart';

/// **Home — v4 (2026-05-29 완전 재구성)**
///
/// 이전 (v3)의 문제:
///   - `madang(light/dark).png` 배경에 호랑이/하녹이 baked-in 되어 BoxFit.cover 시
///     랜덤한 위치에서 잘림 (bug)
///   - Stats peek + Daily char + Hero + Modules grid → 정보 폭격, 페르소나 약함
///   - 호랑이가 hero card 한 칸에만 등장 → 안내자 페르소나 0
///
/// v4 컨셉: **"한옥 마당에 호랑이가 사용자에게 말 거는 한 장면"**
///   1. 추상 gradient + ambient 입자 + flying magpie (baked-in mascot 0)
///   2. 시간대별 인사 + 큰 호랑이 + 말풍선 (Duo의 캐릭터 페르소나를 한국식으로)
///   3. Inline stat chip row (streak · XP · shield) — 큰 카드 X
///   4. 오늘의 글자 compact
///   5. "다음 한 발" hero CTA (1개 시나리오 추천)
///   6. Modules + Games → horizontal scroll secondary
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Scenario? _today;
  bool _loadingScenario = true;

  // E2. Skill-path — 사용자 레벨 시나리오 진행 레일.
  List<Scenario> _levelPath = const [];
  Set<String> _completed = const {};

  // Phase 3 (stately-rising-jongga) — Hanok-Cinematic gating.
  HanokStage? _pendingCinematicStage;
  bool _cinematicShown = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _checkHanokCinematic();
  }

  Future<void> _checkHanokCinematic() async {
    final stage = await HanokStageService.currentStage();
    if (!mounted) return;
    final shouldShow = await HanokCinematic.shouldShow(stage);
    if (!shouldShow || !mounted) return;
    setState(() => _pendingCinematicStage = stage);
  }

  Future<void> _loadToday() async {
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completed = Storage.completedScenarios.toSet();

    Scenario? pick;
    for (final s in list.where((s) => s.level == userLevel)) {
      if (!completed.contains(s.id)) {
        pick = s;
        break;
      }
    }
    if (pick == null) {
      for (final s in list) {
        if (!completed.contains(s.id)) {
          pick = s;
          break;
        }
      }
    }
    pick ??= list.isEmpty ? null : list.first;

    final levelPath =
        list.where((s) => s.level == userLevel).toList(growable: false);

    setState(() {
      _today = pick;
      _levelPath = levelPath;
      _completed = completed;
      _loadingScenario = false;
    });
  }

  /// 시간대 — 인사 + 호랑이 emotion 결정.
  _DayPhase get _phase {
    final h = DateTime.now().hour;
    if (h < 11) return _DayPhase.morning;
    if (h < 18) return _DayPhase.afternoon;
    return _DayPhase.evening;
  }

  String _greeting(AppL10n t) {
    switch (_phase) {
      case _DayPhase.morning:
        return t.homeHeroGreetingMorning;
      case _DayPhase.afternoon:
        return t.homeHeroGreetingAfternoon;
      case _DayPhase.evening:
        return t.homeHeroGreetingEvening;
    }
  }

  /// 말풍선 텍스트 — streak·진척에 따라 회전.
  String _tigerBubble(AppL10n t) {
    final streak = Storage.streakDays;
    final xp = Storage.xp;
    if (streak == 0 && xp == 0) return t.homeTigerBubbleStart;
    if (streak >= 3) return t.homeTigerBubbleStreak;
    return t.homeTigerBubbleResume;
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
          // ── 1. 추상 gradient base — baked-in mascot 없음 ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF14201E),
                          Color(0xFF0E1815),
                          Color(0xFF0A1310),
                        ]
                      : const [
                          Color(0xFFFAF6EC),
                          Color(0xFFF4ECDA),
                          Color(0xFFEEDFC2),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. Subtle radial accent — 호랑이 뒤 따뜻한 빛 ──
          Positioned(
            top: 60,
            left: -40,
            right: -40,
            height: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      SoriColors.tiger.withValues(alpha: isDark ? 0.15 : 0.10),
                      SoriColors.tiger.withValues(alpha: 0.0),
                    ],
                    radius: 0.7,
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Ambient particles ──
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 14)),
          ),

          // ── 4. Content ──
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadToday,
              color: SoriColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── A. Compact top bar (logo + actions) ──
                    _TopBar(),
                    const SizedBox(height: Spacing.lg),

                    // ── B. Tiger hero — 시간대별 인사 + 말풍선 + 큰 호랑이 ──
                    SoriEntrance(
                      delay: const Duration(milliseconds: 40),
                      child: _TigerHero(
                        greeting: _greeting(t),
                        bubble: _tigerBubble(t),
                        subline: t.homeGreetingLearn,
                        phase: _phase,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // ── C. Inline stat chip row ──
                    SoriEntrance(
                      delay: const Duration(milliseconds: 140),
                      slideY: 14,
                      child: _StatChipRow(
                        streak: Storage.streakDays,
                        xp: Storage.xp,
                        level: Storage.xpLevel,
                        xpToNext: Storage.xpToNext,
                        shields: Storage.streakFreezes,
                        shieldLabel: t.homeShieldLabel,
                        daysLabel: t.statsDays,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    // ── D. Daily char (compact) ──
                    SoriEntrance(
                      delay: const Duration(milliseconds: 200),
                      slideY: 12,
                      child: _DailyCharCard(
                        char: DailyCharService.today(),
                        doneToday: Storage.calligraphyDoneToday,
                        onTap: () => showDailyCharSheet(context).then((_) {
                          if (mounted) setState(() {});
                        }),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // ── E. Today CTA hero ──
                    _SectionLabel(label: t.homeTodaySection),
                    const SizedBox(height: Spacing.sm),
                    SoriEntrance(
                      delay: const Duration(milliseconds: 280),
                      child: _TodayScenarioCard(
                        scenario: _today,
                        loading: _loadingScenario,
                        lang: lang,
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

                    // ── E2. Skill path — 레벨 시나리오 진행 레일 ──
                    if (_levelPath.isNotEmpty) ...[
                      _SectionLabel(label: t.scenariosPathTitle),
                      const SizedBox(height: Spacing.sm),
                      SoriEntrance(
                        delay: const Duration(milliseconds: 330),
                        slideY: 14,
                        child: _SkillPathRail(
                          scenarios: _levelPath,
                          completed: _completed,
                          currentId: _today?.id,
                          lang: lang,
                          onTapScenario: (id) async {
                            await Navigator.pushNamed(context, '/scenario',
                                arguments: id);
                            if (mounted) await _loadToday();
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                    ],

                    // ── F. Modules row ──
                    _SectionLabel(label: t.sectionModules),
                    const SizedBox(height: Spacing.sm),
                    SoriEntrance(
                      delay: const Duration(milliseconds: 380),
                      slideY: 16,
                      child: _ModulesGrid(t: t),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // ── G. Games ──
                    _SectionLabel(label: t.sectionGames),
                    const SizedBox(height: Spacing.sm),
                    SoriEntrance(
                      delay: const Duration(milliseconds: 460),
                      slideY: 16,
                      child: _GamesGrid(t: t),
                    ),

                    const SizedBox(height: Spacing.xxxl),
                    Center(
                      child: Text(
                        t.footerCheer,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
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
          ),

          // ── 5. Flying magpie overlay ──
          const Positioned.fill(child: IgnorePointer(child: FlyingMagpie())),

          // ── 6. Hanok-Cinematic — Phase 3 stage transition ──
          // Wird einmalig pro neuem Stage gezeigt (Storage gating).
          if (_pendingCinematicStage != null && !_cinematicShown)
            Positioned.fill(
              child: HanokCinematic(
                current: _pendingCinematicStage!,
                onDone: () {
                  if (!mounted) return;
                  setState(() {
                    _cinematicShown = true;
                    _pendingCinematicStage = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

enum _DayPhase { morning, afternoon, evening }

// ════════════════════════════════════════════════════════════════════════
// A. Top bar — compact, no big stats
// ════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/icons/icon-192.png',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          'Hangul Sori',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: s.text,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: s.surface.withValues(alpha: 0.62),
          shape: BoxShape.circle,
          border: Border.all(color: s.border),
        ),
        child: Icon(icon, size: 18, color: s.textMuted),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// B. Tiger hero — greeting + 큰 호랑이 + 말풍선
// ════════════════════════════════════════════════════════════════════════
class _TigerHero extends StatelessWidget {
  final String greeting;
  final String bubble;
  final String subline;
  final _DayPhase phase;
  const _TigerHero({
    required this.greeting,
    required this.bubble,
    required this.subline,
    required this.phase,
  });

  MascotEmotion get _emotion {
    switch (phase) {
      case _DayPhase.morning:
        return MascotEmotion.smile;
      case _DayPhase.afternoon:
        return MascotEmotion.smile;
      case _DayPhase.evening:
        return MascotEmotion.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    // v4 (2026-05-29): 좁은 화면(360px 미만)에서 호랑이가 잘리지 않도록
    // 화면 폭에 비례한 사이즈 + 강제 clip 처리.
    final media = MediaQuery.of(context);
    final tigerSize = media.size.width < 360 ? 124.0 : 140.0;
    final textRightInset = tigerSize + 12;

    return ClipRect(
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            // Left: greeting + subline + speech bubble
            Positioned(
              top: 8,
              left: 0,
              right: textRightInset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: s.text,
                      letterSpacing: -0.7,
                      height: 1.05,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subline,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: s.textMuted,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _SpeechBubble(text: bubble),
                ],
              ),
            ),

            // Right: 큰 호랑이 — 화면 안에 완전히 들어옴 (right: 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Mascot.tiger(
                size: tigerSize,
                emotion: _emotion,
                animate: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : Colors.white;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SoriColors.tiger.withValues(alpha: 0.30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF1F1A14) : s.text,
          height: 1.35,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// C. Inline stat chip row — streak · XP · shield
// ════════════════════════════════════════════════════════════════════════
class _StatChipRow extends StatelessWidget {
  final int streak;
  final int xp;
  final int level;
  final int xpToNext;
  final int shields;
  final String shieldLabel;
  final String daysLabel;

  const _StatChipRow({
    required this.streak,
    required this.xp,
    required this.level,
    required this.xpToNext,
    required this.shields,
    required this.shieldLabel,
    required this.daysLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.compact,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                color: SoriColors.warning,
                value: '$streak',
                label: daysLabel,
              ),
              _Divider(),
              _MiniStat(
                icon: Icons.stars_rounded,
                color: SoriColors.primary,
                value: 'Lv $level',
                label: '$xp XP',
              ),
              if (shields > 0) ...[
                _Divider(),
                _MiniStat(
                  icon: Icons.shield_rounded,
                  color: SoriColors.highlight,
                  value: '$shields',
                  label: shieldLabel,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SoriXpProgress(
            currentXp: xp,
            level: level,
            trailingLabel: null,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: s.border,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: s.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: s.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// D. Daily char (compact)
// ════════════════════════════════════════════════════════════════════════
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.hangul.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              char,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: SoriColors.hangul,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dailyCharTitle,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
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
                    fontSize: 11,
                    color: doneToday ? SoriColors.success : s.textMuted,
                    fontWeight: doneToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (doneToday)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: SoriColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
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

// ════════════════════════════════════════════════════════════════════════
// E. Today scenario hero — primary CTA
// ════════════════════════════════════════════════════════════════════════
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
        child: const SizedBox(height: 120, child: AppLoading()),
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
                      style: const TextStyle(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SoriColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(SoriRadius.pill),
                          ),
                          child: Text(
                            scenario!.level.display,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              color: SoriColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: SoriColors.primary,
                  borderRadius: SoriRadius.brPill,
                  boxShadow: [
                    BoxShadow(
                      color: SoriColors.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
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

class _ScenarioAvatar extends StatelessWidget {
  final String emoji;
  final String? sidekick;
  const _ScenarioAvatar({required this.emoji, this.sidekick});

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot.forSpeaker(
      sidekick ?? '',
      size: 60,
      emotion: MascotEmotion.smile,
      animate: true,
    );
    if (mascot != null) {
      return SizedBox(width: 60, height: 60, child: mascot);
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// F. Modules + G. Games grids
// ════════════════════════════════════════════════════════════════════════
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
                icon: Icons.text_fields_rounded,
                title: t.moduleHangulTitle,
                subtitle: t.moduleHangulDesc,
                accent: SoriColors.hangul,
                onTap: () => Navigator.pushNamed(context, '/hangul'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.menu_book_rounded,
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
                icon: Icons.edit_note_rounded,
                title: t.moduleGrammarTitle,
                subtitle: t.moduleGrammarDesc,
                accent: SoriColors.warning,
                onTap: () => Navigator.pushNamed(context, '/grammar'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.forum_rounded,
                title: t.moduleScenariosTitle,
                subtitle: t.moduleScenariosDesc,
                accent: SoriColors.accent,
                onTap: () => Navigator.pushNamed(context, '/scenarios'),
              ),
            ),
          ],
        ),
        // Phase 5.1 신규 진입로 — 책 한 컷 + 책장
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.photo_camera_outlined,
                title: t.homeBookCardTitle,
                subtitle: t.homeBookCardDesc,
                accent: SoriColors.info,
                onTap: () => Navigator.pushNamed(context, '/book'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.collections_bookmark_outlined,
                title: t.homeBookshelfCardTitle,
                subtitle: t.homeBookshelfCardDesc,
                accent: SoriColors.primary,
                onTap: () => Navigator.pushNamed(context, '/bookshelf'),
              ),
            ),
          ],
        ),
        // Phase 4 진입로 — 특별 퀘스트
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.workspace_premium_outlined,
                title: t.homeQuestsCardTitle,
                subtitle: t.homeQuestsCardDesc,
                accent: SoriColors.gold,
                onTap: () => Navigator.pushNamed(context, '/quests'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.edit_note_rounded,
                title: t.homeWordbookCardTitle,
                subtitle: t.homeWordbookCardDesc,
                accent: SoriColors.accent,
                onTap: () => Navigator.pushNamed(context, '/bookshelf'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GamesGrid extends StatelessWidget {
  final AppL10n t;
  const _GamesGrid({required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.sort_by_alpha_rounded,
                title: t.gameChosungTitle,
                subtitle: t.gameChosungDesc,
                accent: SoriColors.primary,
                onTap: () => Navigator.pushNamed(context, '/chosung'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.grid_4x4_rounded,
                title: t.gameWordleTitle,
                subtitle: t.gameWordleDesc,
                accent: SoriColors.success,
                onTap: () => Navigator.pushNamed(context, '/wordle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.link_rounded,
                title: t.gameKkeunmariTitle,
                subtitle: t.gameKkeunmariDesc,
                accent: SoriColors.accent,
                onTap: () => Navigator.pushNamed(context, '/kkeunmari'),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniModuleCard(
                icon: Icons.headphones_rounded,
                title: t.moduleListenTitle,
                subtitle: t.listeningSubtitle,
                accent: SoriColors.info,
                onTap: () => Navigator.pushNamed(context, '/listening'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _MiniModuleCard({
    required this.icon,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: s.text,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
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
                fontSize: 10.5,
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

// ════════════════════════════════════════════════════════════════════════
// E2. Skill-path rail — 레벨 시나리오 진행 (완료 ● / 현재 ◉ / 예정 ○)
// ════════════════════════════════════════════════════════════════════════
class _SkillPathRail extends StatelessWidget {
  final List<Scenario> scenarios;
  final Set<String> completed;
  final String? currentId;
  final String lang;
  final void Function(String id) onTapScenario;

  const _SkillPathRail({
    required this.scenarios,
    required this.completed,
    required this.currentId,
    required this.lang,
    required this.onTapScenario,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final doneCount =
        scenarios.where((sc) => completed.contains(sc.id)).length;

    return SoriCard(
      variant: SoriCardVariant.compact,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.scenariosPathProgress(doneCount, scenarios.length),
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: scenarios.length,
              itemBuilder: (context, i) {
                final sc = scenarios[i];
                return _PathNode(
                  index: i,
                  total: scenarios.length,
                  label: sc.title.pick(lang),
                  done: completed.contains(sc.id),
                  current: sc.id == currentId,
                  onTap: () => onTapScenario(sc.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final int index;
  final int total;
  final String label;
  final bool done;
  final bool current;
  final VoidCallback onTap;
  const _PathNode({
    required this.index,
    required this.total,
    required this.label,
    required this.done,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final Color ring = done
        ? SoriColors.primary
        : current
            ? SoriColors.tiger
            : s.border;
    final Color fill = done
        ? SoriColors.primary
        : current
            ? SoriColors.tiger.withValues(alpha: 0.18)
            : s.surface;

    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: index == 0
                      ? const SizedBox.shrink()
                      : _Connector(active: done || current),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: current ? SoriColors.tiger : s.textMuted,
                          ),
                        ),
                ),
                Expanded(
                  child: index == total - 1
                      ? const SizedBox.shrink()
                      : _Connector(active: done),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                  color: current ? s.text : s.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool active;
  const _Connector({required this.active});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: active ? SoriColors.primary.withValues(alpha: 0.5) : s.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Section label
// ════════════════════════════════════════════════════════════════════════
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
