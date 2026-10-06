import 'dart:async';
import '../../widgets/sori/window_class.dart';

import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../models/learner_level.dart';
import '../../models/course_mission_brief.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/catalog_history_lease.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../widgets/sori/activity_sheet.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/book_capture_choice.dart';
import '../../widgets/sori/media_phrase_link.dart';
import '../../widgets/sori/catalog_card.dart';
import '../../widgets/sori/learning_focus.dart';
import '../../widgets/sori/learning_entry_paths.dart';
import '../../widgets/sori/level_filter_bar.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/toast.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';
import 'c_stage_chrome.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';

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
  });
  final SoriStageTab tab;
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final bool active;
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
  int _openGeneration = 0;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
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
    final threshold = viewport.localToGlobal(Offset.zero).dy + 80;
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
    final target = _sectionKeys[section]!.currentContext;
    if (target == null) {
      return;
    }
    setState(() => _selected = section);
    _jumping = true;
    try {
      await Scrollable.ensureVisible(
        target,
        alignment: (72 / _scroll.position.viewportDimension).clamp(0.0, 1.0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
      );
    } finally {
      _jumping = false;
    }
  }

  Future<void> _start(ActivityCatalogEntry entry) async {
    if (_opening) {
      return;
    }
    setState(() => _opening = true);
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
        if (mounted) {
          setState(() => _opening = false);
        }
        if (lease.isCurrent) {
          _reload();
        }
      }
    }
  }

  Future<void> _openFoundation() async {
    if (_opening) {
      return;
    }
    final lease = CatalogHistoryLease.capture();
    final generation = ++_openGeneration;
    setState(() => _opening = true);
    try {
      await Navigator.of(context).pushNamed('/foundation');
    } catch (_) {
      if (mounted && lease.isCurrent) {
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
    } finally {
      if (mounted && generation == _openGeneration && lease.isCurrent) {
        setState(() => _opening = false);
        _reload();
      }
    }
  }

  Future<void> _chooseBrowseLevel() async {
    if (_opening) {
      return;
    }
    final lease = CatalogHistoryLease.capture();
    final generation = ++_openGeneration;
    setState(() => _opening = true);
    try {
      if (!mounted || !lease.isCurrent || generation != _openGeneration) {
        return;
      }
      final t = AppL10n.of(context);
      final selected = SoriLevelFilterBar.resolveStartLevel();
      final next = await showSoriSheet<String>(
        context: context,
        maxTextScaleFactor: 2,
        builder: (sheetContext) => CPaperPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(t.lernenFree, style: cStageCardTitle),
              ),
              const SizedBox(height: 8),
              Text(t.settingsBrowseLevelDescription, style: cStageBody),
              const SizedBox(height: 12),
              for (final level in LearnerLevel.values) ...[
                CMaterialAction(
                  key: ValueKey('c-browse-level-${level.code}'),
                  label: level.display,
                  compact: true,
                  gold: level.code == selected,
                  selected: level.code == selected,
                  onTap: () => Navigator.of(sheetContext).pop(level.code),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
      if (!mounted ||
          !lease.isCurrent ||
          generation != _openGeneration ||
          next == null) {
        return;
      }
      await Storage.setBrowseLevelCode(next);
      if (mounted && lease.isCurrent && generation == _openGeneration) {
        _reload();
      }
    } catch (_) {
      if (mounted && lease.isCurrent && generation == _openGeneration) {
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
    } finally {
      if (mounted && lease.isCurrent && generation == _openGeneration) {
        setState(() => _opening = false);
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
      conceptC: true,
    );
    return SoriCatalogCard(
      key: ValueKey('catalog-card-${entry.id}'),
      entry: entry,
      featured: featured,
      conceptC: true,
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
          conceptC: true,
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
                      conceptC: true,
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
            conceptC: true,
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

  Widget _cLearnHero() {
    final t = AppL10n.of(context);
    final labels = [
      t.catalogWords,
      t.catalogListen,
      t.catalogHangul,
      t.catalogReview,
    ];
    final parts = [
      CReferencePart.words,
      CReferencePart.listening,
      CReferencePart.hangul,
      CReferencePart.review,
    ];
    final brief = LearningFocusScope.maybeOf(context)?.notifier?.value?.brief;
    final steps = brief?.visibleSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (steps != null && steps.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final step in steps)
                Expanded(
                  child: Column(
                    children: [
                      CWaxSeal(
                        number: step.displayIndex,
                        active: step == steps.first,
                        size: 40,
                      ),
                      Text(
                        switch (step.phase) {
                          CourseMissionPhase.listen =>
                            t.courseMissionBriefListenTitle,
                          CourseMissionPhase.build =>
                            t.courseMissionBriefBuildTitle,
                          CourseMissionPhase.checkpoint =>
                            t.courseMissionBriefCheckpointTitle,
                          CourseMissionPhase.scene =>
                            t.courseMissionBriefSceneTitle,
                        },
                        textAlign: TextAlign.center,
                        style: cStageBody.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        if (LearningFocusScope.maybeOf(context) != null)
          SoriLearningFocus(
            conceptC: true,
            conceptSummary: brief == null,
            conceptCourseOverview: false,
            introduction: brief == null
                ? null
                : Text(
                    brief.unit.title.pick(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: cStageCardTitle.copyWith(fontSize: 20),
                  ),
            conceptArt: const CSceneArt(CScene.book, height: 140),
          )
        else
          const CSceneArt(CScene.book, height: 160),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns = MediaQuery.textScalerOf(context).scale(16) > 26
                ? 1
                : 2;
            final width = (bounds.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    width: width,
                    child: CImageTap(
                      key: ValueKey(
                        'c-learn-category-${SoriLearnSection.values[i].name}',
                      ),
                      label: labels[i],
                      onTap: () => _jump(SoriLearnSection.values[i]),
                      child: CPaperPanel(
                        radius: 10,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 76,
                              width: double.infinity,
                              child: CReferenceArt(parts[i]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              style: cStageBody.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
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
        const SizedBox(height: 12),
        CMaterialAction(
          key: const ValueKey('learning-focus-course-overview'),
          label: t.learningFocusViewCourse,
          gold: false,
          onTap: _opening
              ? null
              : () => _start(
                  soriActivityCatalog.firstWhere((e) => e.id == 'course'),
                ),
        ),
      ],
    );
  }

  Widget _cGames(SoriStageProgressionSnapshot? data) {
    final t = AppL10n.of(context);
    ActivityCatalogEntry entry(String id) =>
        soriActivityCatalog.firstWhere((e) => e.id == id);
    void details(String id) => showSoriActivitySheet(
      context,
      entry: entry(id),
      progress: data?.activityProgress[id],
      onStart: () => _start(entry(id)),
      conceptC: true,
    );
    Widget tile(String id, CGameReferencePart part) => CImageTap(
      key: ValueKey('catalog-card-$id'),
      label: [
        localCopy(context, entry(id).title),
        if (catalogActivityStatus(context, entry(id), data) case final status?)
          status,
      ].join('. '),
      onTap: () => details(id),
      child: CPaperPanel(
        radius: 10,
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              width: double.infinity,
              child: CGameReferenceArt(part),
            ),
            const SizedBox(height: 4),
            Text(
              localCopy(context, entry(id).title),
              textAlign: TextAlign.center,
              style: cStageBody.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (catalogActivityStatus(context, entry(id), data)
                case final status?)
              Text(
                status,
                textAlign: TextAlign.center,
                style: cStageBody.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    );
    Widget row(List<Widget> tiles) => LayoutBuilder(
      builder: (context, bounds) {
        final columns = MediaQuery.textScalerOf(context).scale(14) > 21
            ? 1
            : tiles.length;
        final width = (bounds.maxWidth - 8 * (columns - 1)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: AspectRatio(
            aspectRatio: CGameReferenceArt.heroAspectRatio,
            child: CGameReferenceArt(CGameReferencePart.hero),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localCopy(context, entry('syllable_cross').title),
          key: const ValueKey('catalog-card-syllable_cross'),
          style: cStageCardTitle,
        ),
        const SizedBox(height: 10),
        CMaterialAction(
          label: t.catalogViewGame,
          gold: false,
          onTap: () => details('syllable_cross'),
        ),
        const SizedBox(height: 12),
        row([
          tile('chosung', CGameReferencePart.firstSounds),
          tile('cloze', CGameReferencePart.cloze),
          tile('speed_match', CGameReferencePart.pairs),
        ]),
        const SizedBox(height: 10),
        row([
          tile('sentence_arcade', CGameReferencePart.sentence),
          tile('kkeunmari', CGameReferencePart.wordChain),
        ]),
        const SizedBox(height: 10),
        CImageTap(
          key: const ValueKey('catalog-card-custom_practice'),
          label: localCopy(context, entry('custom_practice').title),
          onTap: () => details('custom_practice'),
          child: CPaperPanel(
            radius: 10,
            child: Row(
              children: [
                const SizedBox(
                  width: 90,
                  height: 70,
                  child: CGameReferenceArt(CGameReferencePart.yourWords),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localCopy(context, entry('custom_practice').title),
                    style: cStageBody.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const CArrow(dark: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _card(entry('daily_game'), data),
      ],
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
      container: true,
      child: Text(
        value,
        style: cStageCardTitle.copyWith(fontSize: 20, height: 1.35),
      ),
    );
    return Scaffold(
      body: CStageBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 600,
            base: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            builder: (context, padding) => CustomScrollView(
              key: _viewport,
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  sliver: Builder(
                    builder: (context) {
                      return SliverToBoxAdapter(
                        child: FutureBuilder<SoriStageProgressionSnapshot>(
                          future: _progress,
                          builder: (context, snapshot) {
                            final data =
                                snapshot.connectionState ==
                                        ConnectionState.done &&
                                    !snapshot.hasError
                                ? snapshot.data
                                : null;
                            return CStageHeader(
                              title: isGames
                                  ? title
                                  : t.onboardingJourneyPathShort,
                              balance: data?.walletUnavailable == false
                                  ? data?.wallet?.balance
                                  : null,
                              onWalletReturned: _reload,
                              trailing: isGames
                                  ? null
                                  : CImageTap(
                                      key: const ValueKey(
                                        'c-learn-level-filter',
                                      ),
                                      label:
                                          '${t.lernenFree}: ${SoriLevelFilterBar.resolveStartLevel().toUpperCase()}',
                                      onTap: _opening
                                          ? null
                                          : _chooseBrowseLevel,
                                      child: CPaperPanel(
                                        radius: 11,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              SoriLevelFilterBar.resolveStartLevel()
                                                  .toUpperCase(),
                                              style: cStageBody.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const CArrow(
                                              down: true,
                                              dark: true,
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                FutureBuilder<SoriStageProgressionSnapshot>(
                  future: _progress,
                  builder: (context, snapshot) {
                    final data =
                        snapshot.connectionState == ConnectionState.done &&
                            !snapshot.hasError
                        ? snapshot.data
                        : null;
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        0,
                        padding.right,
                        padding.bottom,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: CPaperPanel(
                          radius: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isGames) ...[
                                _cLearnHero(),
                                const SizedBox(height: 16),
                                CLearningEntryPaths(
                                  busy: _opening,
                                  onFoundation: () =>
                                      unawaited(_openFoundation()),
                                  onCourse: () => unawaited(
                                    _start(
                                      entries.firstWhere(
                                        (entry) => entry.id == 'course',
                                      ),
                                    ),
                                  ),
                                  onFree: () => unawaited(
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/free-learning'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CImageTap(
                                  key: const ValueKey('study-library-entry'),
                                  label: t.studyLibraryAppBarTitle,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/study-library'),
                                  child: CPaperPanel(
                                    child: Row(
                                      children: [
                                        const CObjectArt(
                                          CObject.book,
                                          size: 44,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            t.studyLibraryAppBarTitle,
                                            style: cStageBody.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const CArrow(dark: true),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Spacing.lg),
                              ],
                              if (!isGames) _quick(data),
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
                                _cGames(data),
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
                                        selectedColor: CPalette.jade,
                                        backgroundColor: CPalette.paper,
                                        side: BorderSide(
                                          color: _selected == section
                                              ? CPalette.brass
                                              : CPalette.fineEdge,
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
                                          style: cStageBody.copyWith(
                                            fontSize: 15,
                                            height: 1.35,
                                            fontWeight: _selected == section
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: _selected == section
                                                ? CPalette.paper
                                                : CPalette.ink,
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
                      ),
                    );
                  },
                ),
              ],
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
