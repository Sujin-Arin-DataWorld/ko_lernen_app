import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'scenario_player_screen.dart';

/// Szenarien-Hub. Listet alle Szenarien gruppiert nach CEFR-Level.
/// Gesperrte Level (über `Storage.userLevelCode`) erscheinen ausgegraut.
class ScenariosListScreen extends StatefulWidget {
  const ScenariosListScreen({super.key});

  @override
  State<ScenariosListScreen> createState() => _ScenariosListScreenState();
}

class _ScenariosListScreenState extends State<ScenariosListScreen> {
  List<Scenario> _all = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
      _loadFailed = list.isEmpty && ScenarioLoader.lastError != null;
    });
  }

  LearnerLevel get _userLevel =>
      LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;

  bool _isLocked(LearnerLevel level) => level.rank > _userLevel.rank;

  /// Level별 accent 컬러 매핑
  Color _levelColor(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1:
        return SoriColors.success;
      case LearnerLevel.a2:
        return SoriColors.primary;
      case LearnerLevel.b1:
        return SoriColors.warning;
      case LearnerLevel.b2:
        return SoriColors.hangul;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(body: AppLoading(message: t.scenariosListTitle));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.scenariosListTitle)),
        body: SoriEmptyState(
          asset: 'assets/illustrations/error/lost_magpie.png',
          icon: Icons.signal_wifi_statusbar_null_rounded,
          title: t.scenariosLoadFailedTitle,
          body: ScenarioLoader.lastError,
          ctaLabel: t.btnRetry,
          onCta: () {
            ScenarioLoader.reset();
            _load();
          },
          accent: SoriColors.accent,
        ),
      );
    }

    final stars = Storage.scenarioStars;
    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.scenariosListTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: soriClampPadding(
            MediaQuery.sizeOf(context).width,
            base: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.xl,
            ),
          ),
          children: [
            // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
            const HanokHeader(
              asset: 'assets/illustrations/hanok/madang(light).png',
              fallbackIcon: Icons.travel_explore_outlined,
            ),
            const SizedBox(height: Spacing.md),
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(
                bottom: Spacing.md,
                left: 2,
              ),
              child: Text(
                t.scenariosListSubtitle,
                style: TextStyle(
                  color: s.textMuted,
                  fontSize: 13,
                ),
              ),
            ),

            // Lesson Path header (Phase 3 — visible lesson path)
            _LessonPathHeader(
              all: _all,
              userLevel: _userLevel,
              stars: stars,
              lang: lang,
              levelColor: _levelColor,
            ),
            const SizedBox(height: Spacing.lg),

            // Per-Level Sections
            for (final level in LearnerLevel.values) ...[
              _LevelSection(
                level: level,
                accent: _levelColor(level),
                locked: _isLocked(level),
                scenarios: _all.where((sc) => sc.level == level).toList(),
                lang: lang,
                stars: stars,
                onLockedTap: (sc) {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.scenariosLocked(sc.level.display)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Level Section ────────────────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final LearnerLevel level;
  final Color accent;
  final bool locked;
  final List<Scenario> scenarios;
  final String lang;
  final Map<String, int> stars;
  final void Function(Scenario) onLockedTap;

  const _LevelSection({
    required this.level,
    required this.accent,
    required this.locked,
    required this.scenarios,
    required this.lang,
    required this.stars,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final effectiveAccent = locked ? s.textDim : accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            SoriBadge.level(
              level.display,
              color: locked ? s.surfaceAlt : accent,
              size: 26,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.scenariosLevelBadge(level.display),
              style: TextStyle(
                color: locked ? s.textDim : s.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: s.textDim),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    t.scenariosLocked(level.display),
                    style: TextStyle(color: s.textDim, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),

        // Cards or empty placeholder (Faceted Minhwa empty card)
        if (scenarios.isEmpty)
          _EmptyLevelCard(accent: accent, locked: locked)
        else
          ...scenarios.map(
            (sc) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: locked
                  ? _LockedScenarioCard(
                      scenario: sc,
                      accent: effectiveAccent,
                      stars: stars[sc.id] ?? 0,
                      lang: lang,
                      onTap: () => onLockedTap(sc),
                    )
                  : _OpenScenarioCard(
                      scenario: sc,
                      accent: accent,
                      stars: stars[sc.id] ?? 0,
                      lang: lang,
                    ),
            ),
          ),
      ],
    );
  }
}

// ─── Unlocked card (OpenContainer) ────────────────────────────────────────────

class _OpenScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;

  const _OpenScenarioCard({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);

    return OpenContainer<void>(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fade,
      closedShape: const RoundedRectangleBorder(
        borderRadius: SoriRadius.brMd,
      ),
      closedColor: s.surface,
      closedElevation: 0,
      openColor: s.bg,
      openElevation: 0,
      closedBuilder: (ctx, openContainer) => _ScenarioCardBody(
        scenario: scenario,
        accent: accent,
        stars: stars,
        lang: lang,
        locked: false,
        onTap: openContainer,
      ),
      openBuilder: (ctx, _) =>
          ScenarioPlayerScreen(scenarioId: scenario.id),
    );
  }
}

// ─── Locked card (SoriPressable + SnackBar) ───────────────────────────────────

class _LockedScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;
  final VoidCallback onTap;

  const _LockedScenarioCard({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: _ScenarioCardBody(
        scenario: scenario,
        accent: accent,
        stars: stars,
        lang: lang,
        locked: true,
      ),
    );
  }
}

// ─── Shared card body ─────────────────────────────────────────────────────────

class _ScenarioCardBody extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;
  final bool locked;
  final VoidCallback? onTap;

  const _ScenarioCardBody({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    required this.locked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final title = scenario.title.pick(lang);

    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: locked
              ? s.surface
              : Color.alphaBlend(
                  accent.withValues(alpha: 0.07),
                  s.surface,
                ),
          borderRadius: SoriRadius.brMd,
          border: Border.all(
            color: locked
                ? s.border
                : accent.withValues(alpha: 0.28),
            width: 1,
          ),
          boxShadow: locked ? null : SoriElevation.low,
        ),
        child: Row(
          children: [
            // Scene + sidekick thumbnail (Phase 5)
            _ScenarioThumbnail(
              scenario: scenario,
              accent: accent,
              locked: locked,
              size: 56,
            ),
            const SizedBox(width: Spacing.md),

            // Centre: title + badges + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: locked ? s.textDim : s.text,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      SoriBadge.level(
                        scenario.level.display,
                        color: locked ? s.textDim : accent,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        '5–7 min · +${scenario.xpReward} XP',
                        style: TextStyle(
                          color: s.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  SoriStars(filled: stars, total: 3, size: 16),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),

            // Trailing icon
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: locked
                  ? s.textDim
                  : accent.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lesson Path Header (Phase 3) ─────────────────────────────────────────────
// Holistic "where am I in the path?" snapshot above the per-level sections:
//   • per-level ★ progress chips (done / total)
//   • next-recommended hero card with direct CTA
// Picks the next scenario: first unlocked scenario at the user's level with
// fewer than 3 stars, falling back to the first unlocked across all levels.

class _LessonPathHeader extends StatelessWidget {
  final List<Scenario> all;
  final LearnerLevel userLevel;
  final Map<String, int> stars;
  final String lang;
  final Color Function(LearnerLevel) levelColor;

  const _LessonPathHeader({
    required this.all,
    required this.userLevel,
    required this.stars,
    required this.lang,
    required this.levelColor,
  });

  Scenario? _pickNext() {
    final unlocked = all.where((sc) => sc.level.rank <= userLevel.rank).toList();
    if (unlocked.isEmpty) return null;

    Scenario? bestAtUserLevel;
    Scenario? anyUnder3;
    for (final sc in unlocked) {
      final st = stars[sc.id] ?? 0;
      if (st < 3) {
        anyUnder3 ??= sc;
        if (sc.level == userLevel) {
          bestAtUserLevel ??= sc;
        }
      }
    }
    return bestAtUserLevel ?? anyUnder3;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final next = _pickNext();

    final totalUnlocked =
        all.where((sc) => sc.level.rank <= userLevel.rank).length;
    final totalAll = all.length;

    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + overall progress
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 18, color: SoriColors.primary),
              const SizedBox(width: Spacing.sm),
              Text(
                t.scenariosPathTitle,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: s.text,
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              Text(
                t.scenariosPathProgress(totalUnlocked, totalAll),
                style: TextStyle(
                  fontSize: 11.5,
                  color: s.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // Per-level ★ progress chips
          Wrap(
            spacing: Spacing.xs + 2,
            runSpacing: Spacing.xs,
            children: [
              for (final lvl in LearnerLevel.values)
                _LevelProgressChip(
                  level: lvl,
                  scenarios: all.where((sc) => sc.level == lvl).toList(),
                  stars: stars,
                  accent: levelColor(lvl),
                  locked: lvl.rank > userLevel.rank,
                  label: t.scenariosPathLevelProgress(
                    lvl.display,
                    all
                        .where((sc) => sc.level == lvl)
                        .where((sc) => (stars[sc.id] ?? 0) > 0)
                        .length,
                    all.where((sc) => sc.level == lvl).length,
                  ),
                ),
            ],
          ),

          // Next-recommended hero
          if (next != null) ...[
            const SizedBox(height: Spacing.md),
            _NextRecommended(scenario: next, lang: lang, accent: levelColor(next.level)),
          ] else ...[
            const SizedBox(height: Spacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.celebration_outlined,
                      size: 16, color: SoriColors.success),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      t.scenariosPathAllDone,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: s.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelProgressChip extends StatelessWidget {
  final LearnerLevel level;
  final List<Scenario> scenarios;
  final Map<String, int> stars;
  final Color accent;
  final bool locked;
  final String label;

  const _LevelProgressChip({
    required this.level,
    required this.scenarios,
    required this.stars,
    required this.accent,
    required this.locked,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final tint = locked ? s.textDim : accent;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tint.withValues(alpha: 0.32), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(Icons.lock_outline_rounded, size: 11, color: tint),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tint,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextRecommended extends StatelessWidget {
  final Scenario scenario;
  final String lang;
  final Color accent;
  const _NextRecommended({
    required this.scenario,
    required this.lang,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScenarioPlayerScreen(scenarioId: scenario.id),
          ),
        );
      },
      haptic: SoriHaptic.selection,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withValues(alpha: 0.10), s.surface),
          borderRadius: SoriRadius.brSm,
          border: Border.all(
            color: accent.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _ScenarioThumbnail(
              scenario: scenario,
              accent: accent,
              locked: false,
              size: 44,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.scenariosPathNextLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.title.pick(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: s.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.scenariosPathStartCta,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Level Card ─────────────────────────────────────────────────────────
// 시나리오 0개인 레벨에 자는 호랑이 일러스트 + "곧 만나요" 안내.
// 자산이 없으면 errorBuilder가 아이콘+그라데이션 fallback으로 대체한다.

class _EmptyLevelCard extends StatelessWidget {
  final Color accent;
  final bool locked;

  const _EmptyLevelCard({required this.accent, required this.locked});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final mutedAccent = locked ? s.textDim : accent;

    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: mutedAccent,
      semanticLabel: '${t.scenariosEmptyTitle}. ${t.scenariosEmptyBody}',
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              locked
                  ? 'assets/illustrations/mascot/tiger_sleepy.png'
                  : 'assets/illustrations/mascot/tiger_blink.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: mutedAccent.withValues(alpha: 0.14),
                  borderRadius: SoriRadius.brSm,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.bedtime_outlined,
                  color: mutedAccent,
                  size: 28,
                ),
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
                  t.scenariosEmptyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.scenariosEmptyBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: s.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scenario Thumbnail (Phase 5) ─────────────────────────────────────────────
// Replaces the per-tile emoji box with a backdrop scene (location identity)
// + sidekick mascot overlay (character identity). Falls back to a tinted
// accent gradient + emoji when no backdrop matches.

class _ScenarioThumbnail extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final bool locked;
  final double size;

  const _ScenarioThumbnail({
    required this.scenario,
    required this.accent,
    required this.locked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final key = scenario.backdropKey;
    final mascotSize = size * 0.62;

    final base = ClipRRect(
      borderRadius: SoriRadius.brSm,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (key != null)
              Image.asset(
                'assets/illustrations/scenes/$key.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _gradient(s),
              )
            else
              _gradient(s),
            // Subtle vignette so mascot reads regardless of backdrop brightness.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            // Sidekick mascot — fall back to tiger for unknown speakers so
            // every tile shows a character.
            Positioned(
              right: -2,
              bottom: -2,
              child: SizedBox(
                width: mascotSize,
                height: mascotSize,
                child: Mascot.forSpeaker(
                      scenario.sidekick ?? '',
                      size: mascotSize,
                      emotion: MascotEmotion.smile,
                    ) ??
                    Mascot.tiger(
                      emotion: MascotEmotion.smile,
                      size: mascotSize,
                    ),
              ),
            ),
            // No backdrop? show the emoji small in the top-left so the tile
            // still carries the scenario's own identity glyph.
            if (key == null)
              Positioned(
                left: 4,
                top: 2,
                child: Text(
                  scenario.emoji,
                  style: TextStyle(fontSize: size * 0.32),
                ),
              ),
          ],
        ),
      ),
    );

    if (!locked) return base;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: base,
    );
  }

  Widget _gradient(SoriSurfaces s) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.10),
          ],
        ),
      ),
    );
  }
}
