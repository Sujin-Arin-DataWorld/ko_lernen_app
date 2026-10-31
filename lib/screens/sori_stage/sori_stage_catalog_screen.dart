import 'dart:async';
import 'dart:math' as math;
import '../../widgets/sori/window_class.dart';

import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/catalog_history_lease.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../widgets/sori/activity_sheet.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/top_chrome.dart';
import '../../widgets/sori/study_library_button.dart';
import '../../widgets/sori/book_capture_choice.dart';
import '../../widgets/sori/media_phrase_link.dart';
import '../../widgets/sori/catalog_card.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/learning_focus.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/toast.dart';
import 'c_stage_chrome.dart';
import 'c5_catalog_overview.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';

// Compatibility for the unchanged shared pack/listening grid cache contract.
export '../../widgets/sori/illustrated_card_grid.dart'
    show cellAspectRatioCacheKey;

class SoriStageCatalogScreen extends StatefulWidget {
  const SoriStageCatalogScreen({
    super.key,
    required this.tab,
    this.loadSnapshot,
    this.refreshGeneration = 0,
    this.active = true,
    this.initialShowAll = false,
  });
  final SoriStageTab tab;
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final bool active;
  final bool initialShowAll;
  final int refreshGeneration;

  @override
  State<SoriStageCatalogScreen> createState() => _SoriStageCatalogScreenState();
}

class _SoriStageCatalogScreenState extends State<SoriStageCatalogScreen> {
  Future<SoriStageProgressionSnapshot>? _progress;
  final _fallbackScroll = ScrollController();
  ScrollController? _shellScroll;
  ScrollController get _scroll => _shellScroll ?? _fallbackScroll;
  final _viewport = GlobalKey();
  final _sectionKeys = {
    for (final section in SoriLearnSection.values) section: GlobalKey(),
  };
  SoriLearnSection _selected = SoriLearnSection.words;
  bool _jumping = false;
  bool _selectionScheduled = false;
  bool _opening = false;
  late bool _showAll;
  double _overviewOffset = 0;
  double _catalogOffset = 0;

  double get _catalogHeaderInset {
    final viewport = _viewport.currentContext?.findRenderObject();
    final width = viewport is RenderBox && viewport.hasSize
        ? viewport.size.width
        : MediaQuery.sizeOf(context).width;
    return kToolbarHeight +
        SoriTopChrome.metrics(
          context,
          math.max(1, math.min(880, width - 40)),
        ).height +
        8;
  }

  int _openGeneration = 0;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
    _showAll = widget.initialShowAll;
    _scroll.addListener(_sectionChanged);
    cloudWriteSessionController.changes.addListener(_accountChanged);
    Storage.catalogHistoryChanges.addListener(_historyChanged);
    if (widget.active) {
      _progress = _load();
      unawaited(Storage.initializeCatalogHistory());
      unawaited(Storage.visitCatalog(widget.tab));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shellScroll = PrimaryScrollController.maybeOf(context);
    if (shellScroll != _shellScroll) {
      _scroll.removeListener(_sectionChanged);
      _shellScroll = shellScroll;
      _scroll.addListener(_sectionChanged);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_sectionChanged);
    _fallbackScroll.dispose();
    cloudWriteSessionController.changes.removeListener(_accountChanged);
    Storage.catalogHistoryChanges.removeListener(_historyChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SoriStageCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active ||
            oldWidget.loadSnapshot != widget.loadSnapshot ||
            oldWidget.tab != widget.tab ||
            oldWidget.refreshGeneration != widget.refreshGeneration)) {
      _progress = _load();
      unawaited(Storage.initializeCatalogHistory());
      unawaited(Storage.visitCatalog(widget.tab));
    }
  }

  void _historyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _accountChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = widget.active ? _load() : null;
      _openGeneration++;
      _opening = false;
    });
    if (widget.active) {
      unawaited(Storage.visitCatalog(widget.tab));
    }
  }

  void _reload() {
    if (mounted && widget.active) {
      setState(() {
        _progress = _load();
      });
    }
  }

  void _sectionChanged() {
    if (_jumping || _selectionScheduled) {
      return;
    }
    _selectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionScheduled = false;
      if (mounted) {
        _updateSelectedSection();
      }
    });
  }

  void _updateSelectedSection() {
    if (_jumping || widget.tab != SoriStageTab.learn) {
      return;
    }
    final viewport = _viewport.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) {
      return;
    }
    final threshold =
        viewport.localToGlobal(Offset.zero).dy + _catalogHeaderInset;
    var current = SoriLearnSection.words;
    for (final section in SoriLearnSection.values) {
      final box = _sectionKeys[section]!.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          box.localToGlobal(Offset.zero).dy <= threshold) {
        current = section;
      }
    }
    if (_scroll.hasClients &&
        _scroll.position.maxScrollExtent > 0 &&
        _scroll.offset >= _scroll.position.maxScrollExtent - .5) {
      current = SoriLearnSection.review;
    }
    if (current != _selected && mounted) {
      setState(() => _selected = current);
    }
  }

  Future<void> _jump(SoriLearnSection section) async {
    if (!_showAll) {
      _toggleCatalog(true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
    }
    final target = _sectionKeys[section]!.currentContext;
    if (target == null || !target.mounted) {
      return;
    }
    setState(() => _selected = section);
    _jumping = true;
    try {
      await Scrollable.ensureVisible(
        target,
        alignment: (_catalogHeaderInset / _scroll.position.viewportDimension)
            .clamp(0.0, 1.0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
      );
      // A pinned brand/wallet row grows at large text. Keep the entire target
      // heading below its actual obstruction after the first scroll layout.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !target.mounted) {
        return;
      }
      final box = target.findRenderObject();
      final viewport = _viewport.currentContext?.findRenderObject();
      if (mounted &&
          box is RenderBox &&
          viewport is RenderBox &&
          _scroll.hasClients) {
        final missing =
            viewport.localToGlobal(Offset.zero).dy +
            _catalogHeaderInset -
            box.localToGlobal(Offset.zero).dy;
        if (missing > .5) {
          _scroll.jumpTo(
            (_scroll.offset - missing).clamp(
              0.0,
              _scroll.position.maxScrollExtent,
            ),
          );
        }
      }
    } finally {
      _jumping = false;
    }
  }

  Future<void> _start(ActivityCatalogEntry entry) async {
    if (_opening) {
      return;
    }
    _opening = true;
    final generation = ++_openGeneration;
    final lease = CatalogHistoryLease.capture();
    try {
      // Capture does not award progress. Keep it usable even when the shared
      // learning/reward snapshot is still loading or has failed.
      if (entry.id == 'book_capture') {
        final route = await showBookCaptureChoice(context);
        if (route == entry.route) {
          await Storage.recordCatalogActivity(entry.id, lease: lease);
        }
        return;
      }
      final shared = LearningFocusScope.maybeOf(context);
      if (shared != null) {
        await shared.open(
          context,
          TodayLearningDestination(
            route: entry.route,
            arguments: entry.arguments,
          ),
          activityId: entry.id,
        );
        return;
      }
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: entry.id,
        loadSnapshot: widget.loadSnapshot ?? SoriStageProgressionService.load,
        openActivity: () async {
          if (!mounted || !lease.isCurrent) {
            return;
          }
          final returned = Navigator.of(
            context,
          ).pushNamed(entry.route, arguments: entry.arguments);
          unawaited(Storage.recordCatalogActivity(entry.id, lease: lease));
          await returned;
        },
      );
      if (mounted && lease.isCurrent && receipt != null) {
        await showSoriStageRewardReceipt(context, receipt);
      }
    } catch (_) {
      if (mounted && lease.isCurrent) {
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
    } finally {
      if (generation == _openGeneration) {
        _opening = false;
        if (lease.isCurrent) {
          _reload();
        }
      }
    }
  }

  Widget _card(
    ActivityCatalogEntry entry,
    SoriStageProgressionSnapshot? data, {
    bool featured = false,
  }) {
    final progress = data?.activityProgress[entry.id];
    void details() => showSoriActivitySheet(
      context,
      entry: entry,
      progress: progress,
      onStart: () => _start(entry),
    );
    return SoriCatalogCard(
      key: ValueKey('catalog-card-${entry.id}'),
      entry: entry,
      featured: featured,
      status: catalogActivityStatus(context, entry, data),
      recent: Storage.recentCatalogActivityId(widget.tab) == entry.id,
      onStart: isActivityLocked(entry, progress)
          ? details
          : () => _start(entry),
      onDetails: details,
    );
  }

  Widget _grid(
    List<ActivityCatalogEntry> entries,
    SoriStageProgressionSnapshot? data,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < SoriBreakpoints.grid ||
              MediaQuery.textScalerOf(context).scale(16) >= 24
          ? 1
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in entries)
            SizedBox(width: width, child: _card(entry, data)),
        ],
      );
    },
  );

  Widget _quick(SoriStageProgressionSnapshot? data) {
    final t = AppL10n.of(context);
    final entries = soriActivityCatalog
        .where((e) => e.tab == widget.tab)
        .toList();
    final now = DateTime.now();
    final history = Storage.catalogRecommendations(now: now);
    final allowed = entries.map((e) => e.id).toList();
    final ids = history.quickIds(
      widget.tab.name,
      allowed,
      Storage.catalogQuickDefaults(widget.tab),
      now,
    );
    final discover = history.discover(allowed, ids, now);
    void start(ActivityCatalogEntry entry) {
      final progress = data?.activityProgress[entry.id];
      if (isActivityLocked(entry, progress)) {
        showSoriActivitySheet(
          context,
          entry: entry,
          progress: progress,
          onStart: () => _start(entry),
        );
      } else {
        _start(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            t.catalogQuickStart,
            key: const ValueKey('catalog-quick-heading'),
            style: SoriTextTheme.of(context).h3,
          ),
        ),
        const SizedBox(height: Spacing.md),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns =
                MediaQuery.textScalerOf(context).scale(16) >= 24 ||
                    bounds.maxWidth < SoriAdaptiveWidth.catalogShortcutGrid
                ? 1
                : 2;
            final width =
                (bounds.maxWidth - (columns - 1) * Spacing.md) / columns;
            return Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: [
                for (final id in ids)
                  SizedBox(
                    width: width,
                    child: SoriCatalogShortcut(
                      key: ValueKey('catalog-quick-$id'),
                      entry: entries.firstWhere((e) => e.id == id),
                      onTap: () => start(entries.firstWhere((e) => e.id == id)),
                    ),
                  ),
              ],
            );
          },
        ),
        if (discover != null) ...[
          const SizedBox(height: Spacing.lg),
          Text(t.catalogDiscover, style: SoriTextTheme.of(context).h3),
          const SizedBox(height: Spacing.sm),
          SoriCatalogShortcut(
            key: ValueKey('catalog-discover-$discover'),
            entry: entries.firstWhere((e) => e.id == discover),
            onTap: () => start(entries.firstWhere((e) => e.id == discover)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Storage.dismissCatalogSuggestion(discover),
              child: Text(t.catalogNotNow),
            ),
          ),
        ],
        const SizedBox(height: Spacing.xl),
      ],
    );
  }

  void _toggleCatalog(bool showAll) {
    if (_showAll == showAll) {
      return;
    }
    if (_scroll.hasClients) {
      if (_showAll) {
        _catalogOffset = _scroll.offset;
      } else {
        _overviewOffset = _scroll.offset;
      }
    }
    setState(() => _showAll = showAll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      _scroll.jumpTo(
        (showAll ? _catalogOffset : _overviewOffset).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        ),
      );
    });
  }

  /// C5 artwork binds only to existing catalog launches, locks and details.
  Widget _approvedOverview(
    SoriStageProgressionSnapshot? data,
    bool games, {
    double? maxHeight,
  }) {
    final t = AppL10n.of(context);
    ActivityCatalogEntry? entry(String id) => soriActivityCatalog
        .where((item) => item.tab == widget.tab && item.id == id)
        .firstOrNull;
    void open(ActivityCatalogEntry item, {bool details = false}) {
      if (details || isActivityLocked(item, data?.activityProgress[item.id])) {
        showSoriActivitySheet(
          context,
          entry: item,
          progress: data?.activityProgress[item.id],
          onStart: () => _start(item),
        );
      } else {
        _start(item);
      }
    }

    final course = entry('course');
    final hero = entry('syllable_cross');
    const gameIds = [
      'daily_game',
      'chosung',
      'cloze',
      'speed_match',
      'sentence_arcade',
      'kkeunmari',
    ];
    final ownEntry = entry('custom_practice');
    CGameReferencePart partFor(String? id) => switch (id) {
      'daily_game' => CGameReferencePart.daily,
      'chosung' => CGameReferencePart.firstSounds,
      'cloze' => CGameReferencePart.cloze,
      'speed_match' => CGameReferencePart.pairs,
      'sentence_arcade' => CGameReferencePart.sentence,
      'kkeunmari' => CGameReferencePart.wordChain,
      'custom_practice' => CGameReferencePart.yourWords,
      _ => CGameReferencePart.hero,
    };
    final heroPart = partFor(hero?.id);
    final brief = LearningFocusScope.maybeOf(context)?.notifier?.value?.brief;
    final unit = brief?.unit.title.pick(
      Localizations.localeOf(context).languageCode,
    );
    return C5CatalogOverview(
      key: const ValueKey('c5-catalog-overview'),
      games: games,
      maxHeight: maxHeight,
      primaryLabel: games ? t.catalogStartSession : t.learningFocusViewCourse,
      heroLabel: games
          ? localCopy(context, hero!.title)
          : unit ?? localCopy(context, course!.title),
      hero: games
          ? CGameReferenceArt(heroPart)
          : const CReferenceArt(CReferencePart.book),
      onPrimary: _opening ? null : () => open(games ? hero! : course!),
      detailsLabel: t.catalogDetails,
      onDetails: games && hero != null ? () => open(hero, details: true) : null,
      unitMeta: games || brief == null
          ? null
          : t.learningFocusCoursePosition(
              brief.unit.level.toUpperCase(),
              brief.unit.order,
            ),
      tiles: games
          ? [
              for (final id in gameIds)
                if (entry(id) case final item?)
                  C5OverviewTile(
                    key: ValueKey('c5-game-$id'),
                    label: localCopy(context, item.title),
                    art: CGameReferenceArt(partFor(id)),
                    onTap: () => open(item, details: true),
                  ),
            ]
          : [
              for (final (i, section) in SoriLearnSection.values.indexed)
                C5OverviewTile(
                  key: ValueKey('c5-category-${section.name}'),
                  label: [
                    t.catalogWords,
                    t.catalogListen,
                    t.catalogHangul,
                    t.catalogReview,
                  ][i],
                  art: CReferenceArt(
                    [
                      CReferencePart.words,
                      CReferencePart.listening,
                      CReferencePart.hangul,
                      CReferencePart.review,
                    ][i],
                    opticalFit: true,
                  ),
                  onTap: () => _jump(section),
                ),
            ],
      footer: games && ownEntry != null
          ? C5OverviewTile(
              key: const ValueKey('c5-game-custom_practice'),
              label: localCopy(context, ownEntry.title),
              art: CGameReferenceArt(partFor(ownEntry.id)),
              onTap: () => open(ownEntry, details: true),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final isGames = widget.tab == SoriStageTab.games;
    final entries = soriActivityCatalog
        .where((entry) => entry.tab == widget.tab)
        .toList();
    final recent = Storage.recentCatalogActivityId(widget.tab);
    final featured = isGames
        ? entries.firstWhere(
            (e) => e.id == recent,
            orElse: () => entries.firstWhere((e) => e.id == 'daily_game'),
          )
        : null;
    final title = isGames ? t.soriStageNavGames : t.soriStageNavLearn;
    final sectionTitles = {
      SoriLearnSection.words: t.catalogWordsSection,
      SoriLearnSection.listen: t.catalogListenSection,
      SoriLearnSection.hangul: t.catalogHangulSection,
      SoriLearnSection.review: t.catalogReviewSection,
    };
    final sectionLabels = {
      SoriLearnSection.words: t.catalogWords,
      SoriLearnSection.listen: t.catalogListen,
      SoriLearnSection.hangul: t.catalogHangul,
      SoriLearnSection.review: t.catalogReview,
    };
    Widget heading(String value) => Semantics(
      header: true,
      child: Text(value, style: text.h2.copyWith(fontSize: 20, height: 1.35)),
    );
    return PopScope(
      canPop: !widget.active || !_showAll,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.active && _showAll) {
          _toggleCatalog(false);
        }
      },
      child: Scaffold(
        body: CStageBackground(
          child: SafeArea(
            child: SoriContentClamp(
              maxWidth: 880,
              base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              builder: (context, padding) => CustomScrollView(
                key: _viewport,
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: _showAll ? padding.top : 8),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left),
                    sliver: Builder(
                      builder: (context) {
                        final compactActions =
                            MediaQuery.textScalerOf(context).scale(16) > 22.4;
                        return SoriRootHeader(
                          title: title,
                          foreground: CPalette.paper,
                          background: CPalette.jade,
                          trailingSlots: _showAll || compactActions
                              ? (isGames ? 1 : 2)
                              : (isGames ? 3 : 4),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_showAll && compactActions)
                                IconButton(
                                  key: const ValueKey('c5-catalog-all'),
                                  tooltip: isGames
                                      ? t.c5AllGames
                                      : t.c5AllLearningActivities,
                                  onPressed: () => _toggleCatalog(true),
                                  icon: const Icon(
                                    Icons.grid_view_rounded,
                                    color: CPalette.paper,
                                  ),
                                ),
                              if (!_showAll && !compactActions)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 152,
                                  ),
                                  child: SoriTextAction(
                                    key: const ValueKey('c5-catalog-all'),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      foregroundColor: CPalette.paper,
                                      textStyle: text.body.copyWith(
                                        fontSize: 16,
                                        height: 1.15,
                                      ),
                                    ),
                                    onPressed: () => _toggleCatalog(true),
                                    label: isGames
                                        ? t.c5AllGames
                                        : t.c5AllLearningActivities,
                                  ),
                                ),
                              if (_showAll)
                                IconButton(
                                  key: const ValueKey('c5-catalog-close'),
                                  tooltip: t.btnClose,
                                  onPressed: () => _toggleCatalog(false),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: CPalette.paper,
                                  ),
                                ),
                              if (!isGames)
                                const IconTheme(
                                  data: IconThemeData(color: CPalette.paper),
                                  child: SoriStudyLibraryButton(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: _showAll ? 16 : 4),
                  ),
                  FutureBuilder<SoriStageProgressionSnapshot>(
                    future: _progress,
                    builder: (context, snapshot) {
                      final data =
                          snapshot.connectionState == ConnectionState.done &&
                              !snapshot.hasError
                          ? snapshot.data
                          : null;
                      if (!_showAll) {
                        return SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final normal =
                                MediaQuery.textScalerOf(context).scale(16) <=
                                16.1;
                            final available =
                                constraints.viewportMainAxisExtent -
                                constraints.precedingScrollExtent -
                                Spacing.sm;
                            return SliverPadding(
                              padding: const EdgeInsets.only(bottom: 8),
                              sliver: SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: SoriMaxWidth.focus,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _approvedOverview(
                                          data,
                                          isGames,
                                          maxHeight:
                                              normal &&
                                                  available >= 280 &&
                                                  MediaQuery.viewInsetsOf(
                                                        context,
                                                      ).bottom ==
                                                      0
                                              ? available.clamp(280.0, 900.0)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          0,
                          padding.right,
                          padding.bottom,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _quick(data),
                              if (!isGames) ...[
                                LearningFocusScope.maybeOf(context) != null
                                    ? const SoriLearningFocus()
                                    : TextButton(
                                        onPressed: () => _start(
                                          entries.firstWhere(
                                            (e) => e.id == 'course',
                                          ),
                                        ),
                                        child: Text(
                                          localCopy(
                                            context,
                                            entries
                                                .firstWhere(
                                                  (e) => e.id == 'course',
                                                )
                                                .title,
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: Spacing.lg),
                              ],
                              if (snapshot.hasError) ...[
                                Text(
                                  t.catalogProgressUnavailable,
                                  style: text.bodySmall,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _reload,
                                    child: Text(t.btnRetry),
                                  ),
                                ),
                              ],
                              if (featured != null) ...[
                                _card(featured, data, featured: true),
                                const SizedBox(height: 24),
                                heading(t.catalogAnotherRound),
                                const SizedBox(height: 12),
                                _grid(
                                  entries
                                      .where((e) => e.id != featured.id)
                                      .toList(),
                                  data,
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                heading(t.catalogChoosePractice),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final section
                                        in SoriLearnSection.values)
                                      ChoiceChip(
                                        key: ValueKey(
                                          'learn-category-${section.name}',
                                        ),
                                        selected: _selected == section,
                                        showCheckmark: false,
                                        selectedColor: SoriColors.primary,
                                        backgroundColor:
                                            SoriCard.resolvedBackground(
                                              context,
                                            ),
                                        side: BorderSide(
                                          color: _selected == section
                                              ? SoriColors.primary
                                              : SoriColors.primary.withValues(
                                                  alpha: .6,
                                                ),
                                        ),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        onSelected: (_) => _jump(section),
                                        label: Text(
                                          sectionLabels[section]!,
                                          style: text.bodySmall.copyWith(
                                            fontSize: 15,
                                            height: 1.35,
                                            fontWeight: _selected == section
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: _selected == section
                                                ? Colors.white
                                                : Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                ? SoriColors.primaryOnDark
                                                : SoriColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                for (final section
                                    in SoriLearnSection.values) ...[
                                  Padding(
                                    key: _sectionKeys[section],
                                    padding: EdgeInsets.only(
                                      top: section == SoriLearnSection.words
                                          ? 8
                                          : 24,
                                      bottom: 8,
                                    ),
                                    child: heading(sectionTitles[section]!),
                                  ),
                                  if (section == SoriLearnSection.listen)
                                    const SoriMediaPhraseLink(),
                                  _grid(
                                    entries
                                        .where((e) => e.learnSection == section)
                                        .toList(),
                                    data,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Only durable measurements are shown. Ready/unmeasured is neutral; seen
/// words and an arbitrary pronunciation target are never session completion.
String? catalogActivityStatus(
  BuildContext context,
  ActivityCatalogEntry entry,
  SoriStageProgressionSnapshot? snapshot,
) {
  final t = AppL10n.of(context);
  final progress = snapshot?.activityProgress[entry.id];
  if (isActivityLocked(entry, progress)) {
    return entry.unlock.explanation == null
        ? t.soriStageActivityLocked
        : localCopy(context, entry.unlock.explanation!);
  }
  if (snapshot == null) {
    return null;
  }
  final bestKeys = <String, List<String>>{
    'daily_game': ['daily'],
    'chosung': ['chosung'],
    'syllable_cross': ['skz_a1', 'skz_a2', 'skz_b1', 'skz_b2'],
    'cloze': ['cloze'],
    'speed_match': ['speed_match'],
    'sentence_arcade': ['satz_arcade'],
    'kkeunmari': ['kkeunmari'],
    'custom_practice': ['cp_quiz', 'cp_matching', 'cp_typing'],
  };
  final keys = bestKeys[entry.id];
  if (keys != null) {
    // Composite games have different scoring scales; don't combine their bests.
    if (keys.length != 1) {
      return null;
    }
    final best = snapshot.gameBests[keys.single];
    return best != null && best > 0 ? t.catalogBestScore(best) : null;
  }
  final current = progress?.current;
  if (current == null || current <= 0) {
    return null;
  }
  return switch (entry.id) {
    'vocab_packs' => t.catalogPacksCompleted(current),
    'scenarios' => t.catalogScenesCompleted(current),
    'pronunciation' => t.catalogPronunciationPassed(current),
    'calligraphy' => t.catalogDaysPracticed(current),
    _ => null,
  };
}

// Shared string helpers retained for compatibility with external callers.
String activityStateLabel(
  BuildContext context,
  AppL10n t,
  SoriActivityState state,
  ActivityCatalogEntry entry,
) => switch (state) {
  SoriActivityState.ready => t.packStateAvailable,
  SoriActivityState.inProgress => t.soriStageActivityInProgress,
  SoriActivityState.completed => t.soriStageActivityCompleted,
  SoriActivityState.locked => localCopy(context, entry.unlock.explanation!),
};
String activityStateText(String label, int? current, int? target) {
  final suffix = current == null || current <= 0
      ? ''
      : target == null
      ? ' · $current'
      : ' · $current / $target';
  return '$label$suffix';
}
