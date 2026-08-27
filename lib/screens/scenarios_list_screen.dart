import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/scenarios/scenario_browse_query.dart';
import '../models/guide_contract.dart';
import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/scene_asset_resolver.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../l10n/generated/app_localizations.dart';
import 'scenario_player_screen.dart';

/// Szenarien-Hub. Listet alle Szenarien gruppiert nach CEFR-Level.
/// Gesperrte Level (über `Storage.userLevelCode`) erscheinen ausgegraut.
class ScenariosListScreen extends StatefulWidget {
  /// `hanok_jongga.mp4` is 1280x720. Keep the viewport matched to the
  /// original media so [SoriPosterLoop]'s cover fit never crops the scene.
  static const double heroAspectRatio = 16 / 9;

  /// Optional source for deterministic previews and widget tests. Production
  /// keeps the bundled [ScenarioLoader] by leaving this null.
  final Future<List<Scenario>> Function()? loadScenarios;

  /// Notebook studio keeps matching scenes playable regardless of CEFR lock.
  final bool ignoreLevelLock;

  /// Optional guide/library browse intent. Unlike course placement, this only
  /// narrows the catalog to one exact level + shelf and never changes learner
  /// progress.
  final ScenarioBrowseDestination? browseDestination;

  const ScenariosListScreen({
    super.key,
    this.loadScenarios,
    this.ignoreLevelLock = false,
    this.browseDestination,
  });

  /// Named-route boundary: only the typed guide destination is interpreted.
  /// Legacy callers with no arguments (or unrelated arguments) keep the
  /// generic catalog behavior.
  factory ScenariosListScreen.fromRouteArguments(Object? arguments) =>
      ScenariosListScreen(
        browseDestination: arguments is ScenarioBrowseDestination
            ? arguments
            : null,
      );

  @override
  State<ScenariosListScreen> createState() => _ScenariosListScreenState();
}

class _ScenariosListScreenState extends State<ScenariosListScreen>
    with ScreenCoachMixin<ScenariosListScreen> {
  List<Scenario> _all = [];
  bool _loading = true;
  bool _loadFailed = false;
  ScenarioBrowseQueryStatus? _browseStatus;

  // ── 코치마크 타겟 ──
  final GlobalKey _pathHeaderKey = GlobalKey();

  @override
  String get coachId => 'scenarios';

  // 시나리오 로드 완료 후에만 발화 (타겟 위젯이 데이터 필요).
  @override
  bool get coachReady =>
      widget.browseDestination == null &&
      !_loading &&
      !_loadFailed &&
      _all.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _pathHeaderKey,
        title: t.coachScenariosTitle,
        body: t.coachScenariosBody,
        icon: Icons.travel_explore_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final destination = widget.browseDestination;
    final list = await switch ((widget.loadScenarios, destination)) {
      (final loader?, _) => loader(),
      (null, ScenarioBrowseDestination(:final level)) =>
        ScenarioLoader.loadLevel(level),
      (null, null) => ScenarioLoader.load(),
    };
    if (!mounted) return;
    final browseResult = destination == null
        ? null
        : ScenarioBrowseQuery.resolve(destination: destination, corpus: list);
    setState(() {
      _all = browseResult?.scenarios ?? list;
      _browseStatus = browseResult?.status;
      _loading = false;
      _loadFailed = list.isEmpty && ScenarioLoader.lastError != null;
    });
  }

  LearnerLevel get _userLevel =>
      LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;

  bool _isLocked(LearnerLevel level) =>
      widget.browseDestination == null &&
      !widget.ignoreLevelLock &&
      level.rank > _userLevel.rank;

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
      case LearnerLevel.c1:
        return SoriColors.accent;
      case LearnerLevel.c2:
        return SoriColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return SoriStandardPage(
        appBarTitle: t.scenariosListTitle,
        maxWidth: SoriMaxWidth.hub,
        children: [AppLoading(message: t.scenariosListTitle)],
      );
    }
    if (_loadFailed) {
      return SoriStandardPage(
        appBarTitle: t.scenariosListTitle,
        maxWidth: SoriMaxWidth.hub,
        children: [
          SoriEmptyState(
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
        ],
      );
    }
    if (widget.browseDestination != null &&
        _browseStatus != ScenarioBrowseQueryStatus.ready) {
      return SoriStandardPage(
        appBarTitle: t.scenariosListTitle,
        maxWidth: SoriMaxWidth.hub,
        children: [
          SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_front.png',
            icon: Icons.bedtime_outlined,
            title: t.scenariosEmptyTitle,
            body: t.scenariosEmptyBody,
            accent: SoriColors.primary,
          ),
        ],
      );
    }

    final stars = Storage.scenarioStars;
    final lang = Localizations.localeOf(context).languageCode;

    return SoriStandardPage(
      appBarTitle: t.scenariosListTitle,
      headline: t.scenariosListTitle,
      description: t.scenariosListSubtitle,
      maxWidth: SoriMaxWidth.hub,
      children: [
        // 모듈 헤더 — 16:9 원본 영상과 같은 비율을 유지한다.
        // 마당 포스터 위로 종가 앰비언트 루프(굴뚝 연기·감 흔들림) 페이드인.
        const HanokHeader(
          asset: 'assets/illustrations/hanok/madang(light).png',
          fallbackIcon: Icons.travel_explore_outlined,
          loopAsset: 'assets/video/loops/hanok_jongga.mp4',
          aspectRatio: ScenariosListScreen.heroAspectRatio,
        ),
        const SizedBox(height: Spacing.xl),

        if (widget.browseDestination == null) ...[
          // Lesson Path header (Phase 3 — visible lesson path)
          KeyedSubtree(
            key: _pathHeaderKey,
            child: _LessonPathHeader(
              all: _all,
              userLevel: _userLevel,
              stars: stars,
              lang: lang,
              levelColor: _levelColor,
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],

        // Per-Level Sections
        for (final level in LearnerLevel.values.where(
          (candidate) => _all.any((scenario) => scenario.level == candidate),
        )) ...[
          _LevelSection(
            level: level,
            accent: _levelColor(level),
            locked: _isLocked(level),
            scenarios: _all.where((sc) => sc.level == level).toList(),
            lang: lang,
            stars: stars,
            onLockedTap: (sc) {
              HapticFeedback.selectionClick();
              soriNotice(
                context,
                t.scenariosLocked(sc.level.display),
                duration: const Duration(seconds: 2),
              );
            },
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ],
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
            Expanded(
              child: Text(
                t.scenariosLevelBadge(level.display),
                style: SoriTextTheme.of(context).label.copyWith(
                  color: locked ? s.textDim : s.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        if (locked) ...[
          const SizedBox(height: Spacing.xs),
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: s.textDim,
                  ),
                ),
                const WidgetSpan(child: SizedBox(width: Spacing.xs)),
                TextSpan(text: t.scenariosLocked(level.display)),
              ],
            ),
            style: SoriTextTheme.of(context).meta.copyWith(color: s.textDim),
          ),
        ],
        const SizedBox(height: Spacing.sm),

        // Cards or empty placeholder (Faceted Minhwa empty card)
        if (scenarios.isEmpty)
          _EmptyLevelCard(accent: accent, locked: locked)
        else
          ...scenarios.map(
            (sc) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: locked
                  ? _ScenarioCardBody(
                      scenario: sc,
                      accent: effectiveAccent,
                      stars: stars[sc.id] ?? 0,
                      lang: lang,
                      locked: true,
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
      closedShape: const RoundedRectangleBorder(borderRadius: SoriRadius.brMd),
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
      openBuilder: (ctx, _) => ScenarioPlayerScreen(
        scenarioId: scenario.id,
        levelHint: scenario.level,
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
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = scenario.title.pick(lang);
    final metadata = t.scenariosCardMeta(scenario.xpReward);
    final semanticLabel = locked
        ? '$title. $metadata. ${t.scenariosLocked(scenario.level.display)}'
        : '$title. $metadata';

    final card = Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: locked
              ? s.surface
              : Color.alphaBlend(accent.withValues(alpha: 0.07), s.surface),
          borderRadius: SoriRadius.brMd,
          border: Border.all(
            color: locked ? s.border : accent.withValues(alpha: 0.28),
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
                    style: SoriTextTheme.of(
                      context,
                    ).cardTitle.copyWith(color: locked ? s.textDim : s.text),
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
                      Expanded(
                        child: Text(
                          metadata,
                          style: SoriTextTheme.of(context).meta.copyWith(
                            color: s.textDim,
                            fontWeight: FontWeight.w600,
                          ),
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
              color: locked ? s.textDim : accent.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );

    final callback = onTap;
    if (callback == null) {
      return card;
    }
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: true,
      excludeSemantics: true,
      onTap: callback,
      child: SoriPressable(
        onTap: callback,
        haptic: SoriHaptic.selection,
        child: card,
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
    final unlocked = all
        .where((sc) => sc.level.rank <= userLevel.rank)
        .toList();
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

    final totalUnlocked = all
        .where((sc) => sc.level.rank <= userLevel.rank)
        .length;
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
              const Icon(
                Icons.route_rounded,
                size: 18,
                color: SoriColors.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  t.scenariosPathTitle,
                  style: SoriTextTheme.of(context).cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              t.scenariosPathProgress(totalUnlocked, totalAll),
              textAlign: TextAlign.end,
              style: SoriTextTheme.of(
                context,
              ).cardSubtitle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Per-level ★ progress chips
          Wrap(
            spacing: Spacing.xs + 2,
            runSpacing: Spacing.xs,
            children: [
              for (final lvl in LearnerLevel.values.where(
                (candidate) =>
                    all.any((scenario) => scenario.level == candidate),
              ))
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
            _NextRecommended(
              scenario: next,
              lang: lang,
              accent: levelColor(next.level),
            ),
          ] else ...[
            const SizedBox(height: Spacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration_outlined,
                    size: 16,
                    color: SoriColors.success,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      t.scenariosPathAllDone,
                      style: SoriTextTheme.of(
                        context,
                      ).label.copyWith(color: s.text),
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
          borderRadius: SoriRadius.brPill,
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
              style: SoriTextTheme.of(context).meta.copyWith(
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
    final title = scenario.title.pick(lang);
    void openScenario() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScenarioPlayerScreen(
            scenarioId: scenario.id,
            levelHint: scenario.level,
          ),
        ),
      );
    }

    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: SoriTextTheme.of(
                  context,
                ).label.copyWith(color: accent, letterSpacing: 0.6),
              ),
              const SizedBox(height: Spacing.xs),
              Text(title, style: SoriTextTheme.of(context).cardTitle),
            ],
          ),
        ),
      ],
    );
    final cta = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(color: accent, borderRadius: SoriRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.scenariosPathStartCta,
            style: SoriTextTheme.of(context).label.copyWith(
              color: SoriColors.onFill(accent),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: SoriColors.onFill(accent),
          ),
        ],
      ),
    );
    return Semantics(
      label: '${t.scenariosPathStartCta}: $title',
      button: true,
      enabled: true,
      excludeSemantics: true,
      onTap: openScenario,
      child: SoriPressable(
        onTap: openScenario,
        haptic: SoriHaptic.selection,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: Color.alphaBlend(accent.withValues(alpha: 0.10), s.surface),
            borderRadius: SoriRadius.brSm,
            border: Border.all(color: accent.withValues(alpha: 0.32), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final stack =
                  constraints.maxWidth < SoriAdaptiveWidth.shortcutRow ||
                  textScale >= 1.6;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    const SizedBox(height: Spacing.md),
                    Align(alignment: Alignment.centerRight, child: cta),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: Spacing.sm),
                  cta,
                ],
              );
            },
          ),
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
              'assets/illustrations/mascot/tiger_front.png',
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
                  style: SoriTextTheme.of(
                    context,
                  ).cardTitle.copyWith(color: s.text),
                ),
                const SizedBox(height: 2),
                Text(
                  t.scenariosEmptyBody,
                  style: SoriTextTheme.of(
                    context,
                  ).cardSubtitle.copyWith(color: s.textMuted),
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
// Replaces the per-tile emoji box with a backdrop scene (location identity).
// Falls back to a tinted accent gradient + emoji when no backdrop matches.
//
// 마스코트 오버레이는 8d4632c 에서 제거됐다 — 화자가 매칭 안 되는 시나리오가
// 전부 호랑이로 폴백돼 선택 캐릭터와 무관하게 작은 호랑이가 깔렸기 때문.
// 사이드킥을 되살릴 땐 `?? Mascot.tiger(...)` 폴백 없이 붙일 것.

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
    final poster = SceneAssetResolver.posterAsset(scenario);

    final base = ClipRRect(
      borderRadius: SoriRadius.brSm,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster != null)
              Image.asset(
                poster,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _gradient(s),
              )
            else
              _gradient(s),
            // Subtle vignette for a touch of depth over the backdrop.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.transparent, accent.withValues(alpha: 0.18)],
                ),
              ),
            ),
            // No backdrop? show the emoji small in the top-left so the tile
            // still carries the scenario's own identity glyph.
            if (poster == null)
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
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
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
