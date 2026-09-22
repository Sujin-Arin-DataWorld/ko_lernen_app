import 'dart:async';

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
import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/catalog_card.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/learning_focus.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/toast.dart';
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
    _opening = true;
    final generation = ++_openGeneration;
    final lease = CatalogHistoryLease.capture();
    try {
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
          constraints.maxWidth < SoriBreakpoints.grid &&
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
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 880,
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) => CustomScrollView(
              key: _viewport,
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  sliver: Builder(
                    builder: (context) {
                      return SoriCollapsingHeader(
                        title: title,
                        titleStyle: text.h1.copyWith(
                          fontSize: 26,
                          height: 1.35,
                        ),
                        collapsedTitle: title,
                        trailing: const SoriAvatar(),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (!isGames)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left),
                    sliver: SliverToBoxAdapter(
                      child: LearningFocusScope.maybeOf(context) != null
                          ? const SoriLearningFocus()
                          : TextButton(
                              onPressed: () => _start(
                                entries.firstWhere((e) => e.id == 'course'),
                              ),
                              child: Text(
                                localCopy(
                                  context,
                                  entries
                                      .firstWhere((e) => e.id == 'course')
                                      .title,
                                ),
                              ),
                            ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                  for (final section in SoriLearnSection.values)
                                    ChoiceChip(
                                      key: ValueKey(
                                        'learn-category-${section.name}',
                                      ),
                                      selected: _selected == section,
                                      showCheckmark: false,
                                      selectedColor: SoriColors.primary,
                                      backgroundColor:
                                          SoriCard.resolvedBackground(context),
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
                                      labelPadding: const EdgeInsets.symmetric(
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
                                              : Theme.of(context).brightness ==
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
