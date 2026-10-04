import 'package:flutter/material.dart';
import '../features/scenarios/scenario_quest_stock.dart';
import '../features/personas/persona_people_screen.dart';

import '../features/scenarios/scenario_browse_query.dart';
import '../models/guide_contract.dart';
import '../models/scenario.dart';
import '../data/chaekgado_shelf.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/button.dart';
import '../motion/transitions.dart';
import '../services/scenario_loader.dart';
import '../services/scene_asset_resolver.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/persona_card_motion.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/media_phrase_link.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../l10n/generated/app_localizations.dart';
import 'scenario_player_screen.dart';

/// Scenario hub: visible level choices, topic picker, then one topic at a time.
/// Every bundled level is directly playable; the learner level only informs
/// the recommendation shown in the path header.
class ScenariosListScreen extends StatefulWidget {
  /// Optional source for deterministic previews and widget tests. Production
  /// keeps the bundled [ScenarioLoader] by leaving this null.
  final Future<List<Scenario>> Function()? loadScenarios;

  /// Notebook matches narrow the visible lessons after full-corpus assessment
  /// eligibility is calculated. A small selection is not a sparse corpus.
  final Set<String>? scenarioIds;

  /// Optional guide/library browse intent. Unlike course placement, this only
  /// narrows the catalog to one exact level + shelf and never changes learner
  /// progress.
  final ScenarioBrowseDestination? browseDestination;

  const ScenariosListScreen({
    super.key,
    this.loadScenarios,
    this.scenarioIds,
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
  String? _selectedLevel;

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
    final stock = ScenarioQuestStock.fromCorpus(list);
    final selectedIds = widget.scenarioIds;
    final assessable = list
        .where(stock.allowsScenario)
        .where(
          (scenario) =>
              selectedIds == null || selectedIds.contains(scenario.id),
        )
        .toList(growable: false);
    final browseResult = destination == null
        ? null
        : ScenarioBrowseQuery.resolve(
            destination: destination,
            corpus: assessable,
          );
    setState(() {
      _all = browseResult?.scenarios ?? assessable;
      if (_all.isNotEmpty) {
        _selectedLevel = _all.any((sc) => sc.level.code == _selectedLevel)
            ? _selectedLevel
            : _all.any((sc) => sc.level == _userLevel)
            ? _userLevel.code
            : _all.first.level.code;
      }
      _browseStatus = browseResult?.status;
      _loading = false;
      _loadFailed = list.isEmpty && ScenarioLoader.lastError != null;
    });
  }

  LearnerLevel get _userLevel =>
      LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;

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

  void _refreshScenarioProgress() {
    if (!mounted) {
      return;
    }
    setState(() {});
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
    if (_all.isEmpty ||
        (widget.browseDestination != null &&
            _browseStatus != ScenarioBrowseQueryStatus.ready)) {
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
      maxWidth: SoriMaxWidth.hub,
      children: [
        const SoriMediaPhraseLink(),
        PersonaPeopleEntry(loadScenarios: widget.loadScenarios, compact: true),
        const SizedBox(height: Spacing.lg),
        if (widget.browseDestination == null && widget.scenarioIds == null) ...[
          Text(t.scenariosLevelFilter, style: SoriTextTheme.of(context).label),
          const SizedBox(height: Spacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.textScalerOf(context).scale(24) + 24;
              final columns = constraints.maxWidth >= width * 6 + 20 ? 6 : 3;
              return SizedBox(
                width: width * columns + (columns - 1) * Spacing.xs,
                child: Wrap(
                  key: const ValueKey('scenario-level-grid'),
                  spacing: Spacing.xs,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final level in LearnerLevel.values)
                      SizedBox(
                        width: width,
                        child: SoriPersonaCardMotion(
                          interactive: _all.any((sc) => sc.level == level),
                          entrance: false,
                          borderRadius: SoriRadius.brPill,
                          child: SoriChip(
                            key: ValueKey('scenario-level-${level.code}'),
                            label: level.display,
                            selected: _selectedLevel == level.code,
                            minInteractiveHeight: 48,
                            horizontalPadding: 8,
                            maxLines: null,
                            semanticLabel: t.scenariosLevelBadge(level.display),
                            onTap: _all.any((sc) => sc.level == level)
                                ? () => setState(
                                    () => _selectedLevel = level.code,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.lg),
        ],
        for (final level in LearnerLevel.values.where(
          (candidate) =>
              (widget.browseDestination != null ||
                  widget.scenarioIds != null ||
                  candidate.code == _selectedLevel) &&
              _all.any((scenario) => scenario.level == candidate),
        )) ...[
          _LevelSection(
            key: ValueKey(level),
            level: level,
            accent: _levelColor(level),
            scenarios: _all.where((sc) => sc.level == level).toList(),
            lang: lang,
            stars: stars,
            directBrowse:
                widget.browseDestination != null || widget.scenarioIds != null,
            onScenarioClosed: _refreshScenarioProgress,
          ),
          const SizedBox(height: Spacing.xl),
        ],
        if (widget.browseDestination == null) ...[
          KeyedSubtree(
            key: _pathHeaderKey,
            child: _LessonPathHeader(
              all: _all,
              userLevel: _userLevel,
              stars: stars,
              lang: lang,
              levelColor: _levelColor,
              onScenarioClosed: _refreshScenarioProgress,
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ],
    );
  }
}

// ─── Level Section ────────────────────────────────────────────────────────────

class _LevelSection extends StatefulWidget {
  final LearnerLevel level;
  final Color accent;
  final List<Scenario> scenarios;
  final String lang;
  final Map<String, int> stars;
  final bool directBrowse;
  final VoidCallback onScenarioClosed;

  const _LevelSection({
    super.key,
    required this.level,
    required this.accent,
    required this.scenarios,
    required this.lang,
    required this.stars,
    required this.directBrowse,
    required this.onScenarioClosed,
  });

  @override
  State<_LevelSection> createState() => _LevelSectionState();
}

class _LevelSectionState extends State<_LevelSection>
    with AutomaticKeepAliveClientMixin<_LevelSection> {
  String? _shelf;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppL10n.of(context);
    final groups = <String, List<Scenario>>{};
    for (final slot in kChaekgadoSlots[widget.level] ?? <ChaekgadoSlot>[]) {
      final id = chaekgadoShelfId(widget.level, slot.slug);
      final matches = widget.scenarios.where((sc) => sc.shelf == id).toList();
      if (matches.isNotEmpty) groups[id] = matches;
    }
    for (final scenario in widget.scenarios) {
      groups.putIfAbsent(
        scenario.shelf,
        () =>
            widget.scenarios.where((sc) => sc.shelf == scenario.shelf).toList(),
      );
    }
    String label(String shelf) {
      final art = chaekgadoImageKeyForShelf(shelf);
      return art == null ? t.scenariosListTitle : chaekgadoSlotLabel(t, art);
    }

    String countLabel(int count) => count == 1
        ? t.scenariosOneConversation
        : t.scenariosConversationCount(count);
    final showPicker = !widget.directBrowse && _shelf == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.directBrowse) ...[
          SoriBadge.level(widget.level.display, color: widget.accent, size: 26),
          const SizedBox(height: Spacing.md),
        ],
        if (showPicker) ...[
          Semantics(
            header: true,
            child: Text(
              t.scenariosChooseTopic,
              style: SoriTextTheme.of(context).h3,
            ),
          ),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
              final columns =
                  largeText ||
                      constraints.maxWidth <
                          SoriAdaptiveWidth.scenarioTopicTwoColumns
                  ? 1
                  : constraints.maxWidth >= SoriBreakpoints.grid
                  ? 3
                  : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * Spacing.md) / columns;
              return Wrap(
                key: const ValueKey('scenario-category-grid'),
                spacing: Spacing.md,
                runSpacing: Spacing.md,
                children: [
                  for (final group in groups.entries)
                    SizedBox(
                      width: width,
                      child: SoriPersonaCardMotion(
                        interactive: true,
                        entrance: false,
                        child: SoriCard(
                          key: ValueKey('scenario-category-${group.key}'),
                          onTap: () => setState(() => _shelf = group.key),
                          semanticLabel:
                              '${label(group.key)} · ${countLabel(group.value.length)}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (chaekgadoImageKeyForShelf(group.key)
                                  case final art?)
                                Image.asset(
                                  'assets/illustrations/listening/$art.webp',
                                  width: double.infinity,
                                  height: largeText ? 112 : 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.chat_bubble_outline),
                                ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                label(group.key),
                                style: SoriTextTheme.of(context).bodySmall,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      countLabel(group.value.length),
                                      style: SoriTextTheme.of(context).caption,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  const Icon(Icons.chevron_right, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ] else ...[
          if (!widget.directBrowse) ...[
            SoriButton.ghost(
              key: const ValueKey('scenario-category-back'),
              label: t.scenariosChangeTopic,
              onTap: () => setState(() => _shelf = null),
            ),
            const SizedBox(height: Spacing.md),
          ],
          for (final group in groups.entries.where(
            (g) => widget.directBrowse || _shelf == g.key,
          )) ...[
            Semantics(
              header: true,
              child: Text(
                label(group.key),
                style: SoriTextTheme.of(context).h3,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              countLabel(group.value.length),
              style: SoriTextTheme.of(context).caption,
            ),
            const SizedBox(height: Spacing.md),
            for (final entry in group.value.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: _OpenScenarioCard(
                  scenario: entry.value,
                  motionIndex: entry.key,
                  accent: widget.accent,
                  stars: widget.stars[entry.value.id] ?? 0,
                  lang: widget.lang,
                  onScenarioClosed: widget.onScenarioClosed,
                ),
              ),
          ],
        ],
      ],
    );
  }
}

// ─── Playable scenario card ───────────────────────────────────────────────────

class _OpenScenarioCard extends StatelessWidget {
  final int motionIndex;
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;
  final VoidCallback onScenarioClosed;

  const _OpenScenarioCard({
    this.motionIndex = 0,
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    required this.onScenarioClosed,
  });

  @override
  Widget build(BuildContext context) {
    return SoriPersonaCardMotion(
      index: motionIndex,
      interactive: true,
      entrance: false,
      child: _ScenarioCardBody(
        scenario: scenario,
        accent: accent,
        stars: stars,
        lang: lang,
        onTap: () => Navigator.of(context)
            .push<void>(
              SoriTransitions.page<void>(
                (_) => ScenarioPlayerScreen(
                  scenarioId: scenario.id,
                  levelHint: scenario.level,
                ),
              ),
            )
            .then((_) => onScenarioClosed()),
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
  final VoidCallback? onTap;

  const _ScenarioCardBody({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = scenario.title.pick(lang);
    final metadata = t.scenariosCardMeta(scenario.xpReward);
    final semanticLabel = '$title. $metadata';

    final card = Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.07), s.surface),
        borderRadius: SoriRadius.brMd,
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
        boxShadow: SoriElevation.low,
      ),
      child: Row(
        children: [
          // Scene + sidekick thumbnail (Phase 5)
          _ScenarioThumbnail(scenario: scenario, accent: accent, size: 56),
          const SizedBox(width: Spacing.md),

          // Centre: title + badges + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: SoriTextTheme.of(context).cardTitle),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    SoriBadge.level(
                      scenario.level.display,
                      color: accent,
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

          Icon(
            Icons.chevron_right_rounded,
            color: accent.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );

    final callback = onTap;
    if (callback == null) {
      return card;
    }
    return Semantics(
      label: semanticLabel,
      container: true,
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
// Picks the next unfinished scenario at the user's level, falling back across
// the complete directly available catalog.

class _LessonPathHeader extends StatelessWidget {
  final List<Scenario> all;
  final LearnerLevel userLevel;
  final Map<String, int> stars;
  final String lang;
  final Color Function(LearnerLevel) levelColor;
  final VoidCallback onScenarioClosed;

  const _LessonPathHeader({
    required this.all,
    required this.userLevel,
    required this.stars,
    required this.lang,
    required this.levelColor,
    required this.onScenarioClosed,
  });

  Scenario? _pickNext() {
    if (all.isEmpty) return null;

    Scenario? bestAtUserLevel;
    Scenario? anyUnder3;
    for (final sc in all) {
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
              t.scenariosPathProgress(totalAll, totalAll),
              textAlign: TextAlign.end,
              style: SoriTextTheme.of(
                context,
              ).cardSubtitle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Per-level ★ progress badges are passive status, not filter chips.
          Wrap(
            spacing: Spacing.xs + 2,
            runSpacing: Spacing.xs,
            children: [
              for (final lvl in LearnerLevel.values.where(
                (candidate) =>
                    all.any((scenario) => scenario.level == candidate),
              ))
                _LevelProgressBadge(
                  level: lvl,
                  scenarios: all.where((sc) => sc.level == lvl).toList(),
                  stars: stars,
                  accent: levelColor(lvl),
                  label: t.scenariosPathLevelProgress(
                    lvl.display,
                    // 완료 여부는 별 개수(>0)가 아니라 키 존재로 셈 — 0성
                    // 최초 완료도 Storage.setScenarioStars()가 반드시 키로
                    // 기록한다(코스 체크포인트 "0/2→1/2" 판정의 입력, 지시서
                    // 4.15). 여기서 stars[id] > 0 만 세면 퀘스트 과반 미만
                    // (0성)으로 끝낸 정상 완료가 이 배지에서 영원히
                    // "미완료"로 남는다.
                    all
                        .where((sc) => sc.level == lvl)
                        .where((sc) => stars.containsKey(sc.id))
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
              onScenarioClosed: onScenarioClosed,
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

class _LevelProgressBadge extends StatelessWidget {
  final LearnerLevel level;
  final List<Scenario> scenarios;
  final Map<String, int> stars;
  final Color accent;
  final String label;

  const _LevelProgressBadge({
    required this.level,
    required this.scenarios,
    required this.stars,
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: SoriRadius.brPill,
          border: Border.all(color: tint.withValues(alpha: 0.32), width: 1),
        ),
        // §W-A2: 레벨 칩(고정폭 배지) — 본문이 아니라 크롬성 배지라
        // FittedBox(scaleDown) 이 허용된다(200% 배율에서 214dp 폭을
        // 넘던 자리).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
      ),
    );
  }
}

class _NextRecommended extends StatelessWidget {
  final Scenario scenario;
  final String lang;
  final Color accent;
  final VoidCallback onScenarioClosed;
  const _NextRecommended({
    required this.scenario,
    required this.lang,
    required this.accent,
    required this.onScenarioClosed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = scenario.title.pick(lang);
    void openScenario() {
      Navigator.of(context)
          .push(
            SoriTransitions.page(
              (_) => ScenarioPlayerScreen(
                scenarioId: scenario.id,
                levelHint: scenario.level,
              ),
            ),
          )
          .then((_) => onScenarioClosed());
    }

    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScenarioThumbnail(scenario: scenario, accent: accent, size: 44),
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
      // §W-A2: CTA 필(크롬성 배지) — 200% 배율에서 214dp 폭을 넘던 자리.
      // FittedBox(scaleDown) 은 크롬·칩에 허용된다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
    return SoriPersonaCardMotion(
      interactive: true,
      entrance: false,
      borderRadius: SoriRadius.brSm,
      child: Semantics(
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
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                s.surface,
              ),
              borderRadius: SoriRadius.brSm,
              border: Border.all(
                color: accent.withValues(alpha: 0.32),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
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
  final double size;

  const _ScenarioThumbnail({
    required this.scenario,
    required this.accent,
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

    return base;
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
