import '../../widgets/sori/yeopjeon_wallet_card.dart';
import '../../features/dancheong/dancheong_connections.dart';
import '../../features/dancheong/dancheong_store.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/top_chrome.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../bojagi_screen.dart' show kBojagiClosed;
import '../../widgets/sori/ildu_r16_estate_artwork.dart';
import 'c_stage_chrome.dart';

class SoriStageHanokScreen extends StatefulWidget {
  const SoriStageHanokScreen({
    super.key,
    this.loadSnapshot,
    this.loadConstruction,
    this.active = true,
    this.refreshGeneration = 0,
  });

  /// Test seam; production uses the shared Stage progression snapshot.
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  /// Test seam; production loads the approved bundled catalog.
  final Future<SarangchaeConstruction> Function()? loadConstruction;

  /// The shell keeps every tab alive. Refresh progression whenever this tab
  /// becomes visible so work completed in Today/Learn is reflected here.
  final bool active;
  final int refreshGeneration;

  @override
  State<SoriStageHanokScreen> createState() => _SoriStageHanokScreenState();
}

class _SoriStageHanokScreenState extends State<SoriStageHanokScreen> {
  Future<SoriStageProgressionSnapshot>? _future;
  late Future<SarangchaeConstruction> _constructionFuture;
  int? _selectedSequence;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  Future<SarangchaeConstruction> _loadConstruction() =>
      (widget.loadConstruction ?? SarangchaeConstruction.load)();

  @override
  void initState() {
    super.initState();
    _constructionFuture = _loadConstruction();
    if (widget.active) {
      _future = _load();
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageHanokScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active ||
            oldWidget.loadSnapshot != widget.loadSnapshot ||
            oldWidget.loadConstruction != widget.loadConstruction ||
            oldWidget.refreshGeneration != widget.refreshGeneration)) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _future = _load();
      _constructionFuture = _loadConstruction();
      _selectedSequence = null;
    });
  }

  Future<void> _openShortcut(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      // Quest completion, stamp awards, and Bojagi claims can all change the
      // three captions. Refresh only after returning so no stale count is
      // presented by this long-lived tab in the shell's IndexedStack.
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final shortPhone =
        MediaQuery.sizeOf(context).height < 750 &&
        MediaQuery.textScalerOf(context).scale(1) < 1.6;
    // One scroll surface: verified learning, current portrait, then collections.
    return Scaffold(
      body: CStageBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: SoriMaxWidth.world,
            base: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            builder: (context, padding) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                  ),
                  sliver: Builder(
                    builder: (context) {
                      return SoriRootHeader(
                        title: t.soriStageNavHanok,
                        foreground: CPalette.paper,
                        background: CPalette.jade,
                        trailing: const CulturalHelpButton(
                          termId: 'hanok',
                          foregroundColor: CPalette.paper,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: shortPhone ? 4 : 8)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      _HanokMapSliver(
                        progressionFuture: _future,
                        constructionFuture: _constructionFuture,
                        selectedSequence: _selectedSequence,
                      ),
                      FutureBuilder<SoriStageProgressionSnapshot>(
                        future: _future,
                        builder: (context, snapshot) {
                          final ready =
                              snapshot.connectionState ==
                                  ConnectionState.done &&
                              !snapshot.hasError;
                          final data = ready ? snapshot.data : null;
                          return SliverPadding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            sliver: SliverToBoxAdapter(
                              child: CPaperPanel(
                                key: const ValueKey('hanok-progress-panel'),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      key: const ValueKey('c-hanok-board'),
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (data != null &&
                                              !data.walletUnavailable) ...[
                                            Text(
                                              '${data.ownedSarangchaeStage} / ${SarangchaeConstruction.stageCount}',
                                              key: const ValueKey(
                                                'hanok-owned-stages',
                                              ),
                                              style: SoriTextTheme.of(context)
                                                  .body
                                                  .copyWith(
                                                    fontSize: 16,
                                                    color: CPalette.ink,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                for (
                                                  var stage = 1;
                                                  stage <=
                                                      SarangchaeConstruction
                                                          .stageCount;
                                                  stage++
                                                )
                                                  DecoratedBox(
                                                    key: ValueKey(
                                                      'hanok-owned-dot-$stage',
                                                    ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          stage <=
                                                              data.ownedSarangchaeStage
                                                          ? CPalette.jade
                                                          : CPalette.ink
                                                                .withValues(
                                                                  alpha: .16,
                                                                ),
                                                    ),
                                                    child:
                                                        const SizedBox.square(
                                                          dimension: 8,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            FutureBuilder<
                                              SarangchaeConstruction
                                            >(
                                              future: _constructionFuture,
                                              builder: (context, catalog) {
                                                if (!catalog.hasData) {
                                                  return const SizedBox.shrink();
                                                }
                                                final next = catalog.data!.stage(
                                                  (data.ownedSarangchaeStage +
                                                          1)
                                                      .clamp(
                                                        1,
                                                        SarangchaeConstruction
                                                            .stageCount,
                                                      ),
                                                );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: Text(
                                                    next.text(
                                                      'title',
                                                      Localizations.localeOf(
                                                        context,
                                                      ).languageCode,
                                                    ),
                                                    key: const ValueKey(
                                                      'hanok-next-stage-title',
                                                    ),
                                                    style:
                                                        SoriTextTheme.of(
                                                          context,
                                                        ).body.copyWith(
                                                          fontSize: 16,
                                                          color: CPalette.ink,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                          CMaterialAction(
                                            key: const ValueKey(
                                              'hanok-construction-entry',
                                            ),
                                            label: t.ilduConstructionTitle,
                                            onTap: () => _openShortcut(
                                              '/hanok/construction',
                                            ),
                                            compact: true,
                                          ),
                                          const SizedBox(height: 8),
                                          _ShortcutTiles(
                                            snapshot: data,
                                            onOpen: _openShortcut,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ExpansionTile(
                                      key: const ValueKey('hanok-how-to-build'),
                                      tilePadding: EdgeInsets.zero,
                                      title: Text(t.hanokHowTitle),
                                      children: [
                                        Text(
                                          t.hanokHowBody,
                                          style: SoriTextTheme.of(context).body,
                                        ),
                                        const SizedBox(height: Spacing.sm),
                                        SoriButton.outlined(
                                          label: t.hanokHowAction,
                                          onTap: () => _openShortcut('/path'),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      t.soriStageHanokLearningSummary,
                                      style: SoriTextTheme.of(
                                        context,
                                      ).cardTitle,
                                    ),
                                    const SizedBox(height: Spacing.sm),
                                    if (data != null)
                                      Text(
                                        data.hanokCompetence.totalUnitCount == 0
                                            ? t.soriStageHanokNoUnits
                                            : t.soriStageConfirmedUnits(
                                                data
                                                    .hanokCompetence
                                                    .completedUnitCount,
                                                data
                                                    .hanokCompetence
                                                    .totalUnitCount,
                                              ),
                                        key: const ValueKey(
                                          'hanok-confirmed-units',
                                        ),
                                        style: SoriTextTheme.of(context).body,
                                      )
                                    else if (snapshot.hasError) ...[
                                      Text(
                                        t.soriStageHanokProgressUnavailable,
                                        key: const ValueKey(
                                          'hanok-progress-error',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _refresh,
                                        child: Text(t.btnRetry),
                                      ),
                                    ] else
                                      const LinearProgressIndicator(),
                                    const SizedBox(height: Spacing.lg),
                                    DancheongEntryCard(
                                      store: DancheongStore(),
                                      compact: true,
                                      onOpen: () =>
                                          _openShortcut('/dancheong-studio'),
                                    ),
                                    const SizedBox(height: Spacing.lg),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: Spacing.md,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: YeopjeonWalletCard(
                            key: ObjectKey(_future),
                            onBuilt: _refresh,
                          ),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverToBoxAdapter(child: IlDuR16EstateEntry()),
                      ),
                      _SarangchaeConstructionSliver(
                        progressionFuture: _future,
                        constructionFuture: _constructionFuture,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onRetry: _refresh,
                        onStageSelected: (sequence) =>
                            setState(() => _selectedSequence = sequence),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HanokMapSliver extends StatelessWidget {
  const _HanokMapSliver({
    required this.progressionFuture,
    required this.constructionFuture,
    required this.selectedSequence,
  });

  final Future<SoriStageProgressionSnapshot>? progressionFuture;
  final Future<SarangchaeConstruction> constructionFuture;
  final int? selectedSequence;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = SoriMotion.reduceMotion(context);
    return FutureBuilder<SoriStageProgressionSnapshot>(
      future: progressionFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (!snapshot.hasError &&
            data != null &&
            !data.walletUnavailable &&
            (selectedSequence ?? data.ownedSarangchaeStage) <= 1) {
          // R16 stage 1 contains zero meshes. Do not substitute a future house
          // or reserve a large empty illustration plate for an unbuilt site.
          return SliverToBoxAdapter(
            child: _EmptySarangchaeSite(locked: data.ownedSarangchaeStage == 0),
          );
        }
        return SliverLayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.crossAxisExtent;
            final compact =
                MediaQuery.sizeOf(context).height < 750 &&
                MediaQuery.textScalerOf(context).scale(1) < 1.6;
            final expandedHeight = compact
                ? math.min(w * .55, 176.0)
                : math.min(w * .75, 320.0);
            final collapsedHeight = math
                .max(w * .30, 104.0)
                .clamp(104.0, expandedHeight);
            return SliverPersistentHeader(
              pinned: true,
              delegate: _HanokMapHeaderDelegate(
                expandedHeight: expandedHeight,
                collapsedHeight: collapsedHeight,
                reduceMotion: reduceMotion,
                child: _CurrentSarangchaeArtwork(
                  progressionFuture: progressionFuture,
                  constructionFuture: constructionFuture,
                  selectedSequence: selectedSequence,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptySarangchaeSite extends StatelessWidget {
  const _EmptySarangchaeSite({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Semantics(
      label: locked ? t.sarangchaeStageLocked(1) : t.sarangchaeStageUnlocked(1),
      child: Padding(
        key: const ValueKey('hanok-map-header'),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                locked ? Icons.lock_outline_rounded : Icons.check_rounded,
                color: CPalette.brass,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.ilduConstructionEmptyTitle,
                    key: const ValueKey('hanok-empty-site'),
                    style: text.cardTitle.copyWith(color: CPalette.paper),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.ilduConstructionEmptyBody,
                    style: text.bodySmall.copyWith(color: CPalette.paper),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HanokMapHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HanokMapHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.reduceMotion,
    required this.child,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final bool reduceMotion;
  final Widget child;

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final clampedShrink = shrinkOffset.clamp(0.0, range);
    final rawProgress = clampedShrink / range;
    final currentExtent = reduceMotion
        ? (rawProgress < 0.5 ? maxExtent : minExtent)
        : (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    // The sliver's layout extent follows scroll continuously. Snapping that
    // extent for reduced motion can make paintExtent smaller than layoutExtent.
    // Snap only the artwork inside the continuously sized, clipped viewport.
    final layoutExtent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    return ClipRect(
      child: SizedBox(
        key: const ValueKey('hanok-map-header'),
        height: layoutExtent,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (overlapsContent) ...[
              // Transparent foreground must not reveal scrolling text/cards.
              // Keep the pinned scene on the same opaque jade material.
              const ColoredBox(
                key: ValueKey('hanok-pinned-jade-backing'),
                color: CPalette.jade,
              ),
              const CTexture(CMaterial.jade, opacity: .48),
            ],
            OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: currentExtent,
              maxHeight: currentExtent,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HanokMapHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        reduceMotion != oldDelegate.reduceMotion ||
        child != oldDelegate.child;
  }
}

class _CurrentSarangchaeArtwork extends StatelessWidget {
  const _CurrentSarangchaeArtwork({
    required this.progressionFuture,
    required this.constructionFuture,
    required this.selectedSequence,
  });

  final Future<SoriStageProgressionSnapshot>? progressionFuture;
  final Future<SarangchaeConstruction> constructionFuture;
  final int? selectedSequence;

  @override
  Widget build(BuildContext context) => FutureBuilder<SarangchaeConstruction>(
    future: constructionFuture,
    builder: (context, constructionSnapshot) {
      if (constructionSnapshot.hasError) {
        return Semantics(
          label: AppL10n.of(context).loadErrorTryAgain,
          child: const Center(
            child: Icon(Icons.error_outline_rounded, color: CPalette.paper),
          ),
        );
      }
      if (!constructionSnapshot.hasData) {
        return const AppLoading();
      }
      return FutureBuilder<SoriStageProgressionSnapshot>(
        future: progressionFuture,
        builder: (context, progressionSnapshot) {
          if (progressionSnapshot.hasError ||
              (progressionSnapshot.data?.walletUnavailable ?? false)) {
            return Semantics(
              label: AppL10n.of(context).loadErrorTryAgain,
              child: const Center(
                child: Icon(Icons.error_outline_rounded, color: CPalette.paper),
              ),
            );
          }
          final data = progressionSnapshot.data;
          final earned = data?.ownedSarangchaeStage;
          if (earned == null && progressionFuture != null) {
            return const AppLoading();
          }
          return SarangchaeStageArtwork(
            construction: constructionSnapshot.data!,
            earnedStageCount: earned ?? 0,
            sequence: selectedSequence,
          );
        },
      );
    },
  );
}

class _SarangchaeConstructionSliver extends StatelessWidget {
  const _SarangchaeConstructionSliver({
    required this.progressionFuture,
    required this.constructionFuture,
    required this.padding,
    required this.onRetry,
    required this.onStageSelected,
  });

  final Future<SoriStageProgressionSnapshot>? progressionFuture;
  final Future<SarangchaeConstruction> constructionFuture;
  final EdgeInsets padding;
  final VoidCallback onRetry;
  final ValueChanged<int> onStageSelected;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 24),
    sliver: SliverToBoxAdapter(
      child: FutureBuilder<SarangchaeConstruction>(
        future: constructionFuture,
        builder: (context, constructionSnapshot) =>
            FutureBuilder<SoriStageProgressionSnapshot>(
              future: progressionFuture,
              builder: (context, progressionSnapshot) {
                if (constructionSnapshot.hasError ||
                    progressionSnapshot.hasError ||
                    (progressionSnapshot.data?.walletUnavailable ?? false)) {
                  final t = AppL10n.of(context);
                  return SoriCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.loadErrorTryAgain),
                        const SizedBox(height: Spacing.md),
                        SoriButton(
                          label: t.btnRetry,
                          onTap: onRetry,
                          fullWidth: true,
                        ),
                      ],
                    ),
                  );
                }
                if (!constructionSnapshot.hasData ||
                    (progressionFuture != null &&
                        !progressionSnapshot.hasData)) {
                  return const SizedBox.shrink();
                }
                return SarangchaeConstructionExperience(
                  key: ObjectKey(progressionFuture),
                  construction: constructionSnapshot.data!,
                  earnedStageCount:
                      progressionSnapshot.data?.ownedSarangchaeStage ?? 0,
                  showArtwork: false,
                  onStageSelected: onStageSelected,
                );
              },
            ),
      ),
    ),
  );
}

class _ShortcutTiles extends StatelessWidget {
  const _ShortcutTiles({required this.snapshot, required this.onOpen});

  final SoriStageProgressionSnapshot? snapshot;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    String? questsCount;
    if (snapshot != null) {
      final quests = snapshot!.quests;
      final done = quests.where((quest) => quest.completed).length;
      final total = quests
          .where((quest) => quest.active || quest.completed)
          .length;
      questsCount = total == 0 ? t.soriStageNoQuests : '$done / $total';
    }

    const motifs = DancheongMotif.values;
    final earned = Storage.earnedStamps.toSet();
    final got = motifs.where((motif) => earned.contains(motif.name)).length;
    final dojangCount = '$got / ${motifs.length}';

    final bojagiCount = snapshot == null
        ? null
        : '${snapshot!.pendingBojagiCount}';

    final tiles = <Widget>[
      _ShortcutTile(
        id: 'quests',
        label: t.soriStageHanokTasks,
        count: questsCount,
        thumb: const SoriRewardThumb(
          // 대표 마당 장식 1장 — 실재 화이트리스트 슬러그.
          slug: 'decoration_maehwa',
          earned: true,
          size: 40,
          semantic: '',
        ),
        onTap: () => onOpen('/quests'),
      ),
      _ShortcutTile(
        id: 'dojang',
        label: t.soriStageHanokStamps,
        count: dojangCount,
        thumb: Image.asset(
          'assets/illustrations/stamps/stamp_lotus.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.approval_rounded,
            size: 32,
            color: SoriColors.accent,
          ),
        ),
        onTap: () => onOpen('/dojangcheop'),
      ),
      _ShortcutTile(
        id: 'bojagi',
        label: t.soriStageHanokGifts,
        count: bojagiCount,
        thumb: Image.asset(
          kBojagiClosed,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.redeem_rounded,
            size: 32,
            color: SoriColors.goldOnLight,
          ),
        ),
        onTap: () => onOpen('/bojagi'),
      ),
      _ShortcutTile(
        id: 'furnish',
        label: t.sarangbangFurnishTitle,
        count: null,
        thumb: const SoriRewardThumb(
          slug: 'decoration_soban',
          earned: true,
          size: 40,
          semantic: '',
        ),
        onTap: () => onOpen('/sarangbang/furnish'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked = textScale >= 1.6;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                tiles[index],
                if (index != tiles.length - 1)
                  const SizedBox(height: Spacing.sm),
              ],
            ],
          );
        }
        if (MediaQuery.sizeOf(context).width < SoriBreakpoints.narrowPhone) {
          return Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[row * 2]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[row * 2 + 1]),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
        // Keep all four first-action shortcuts in one row at the standard
        // phone text scale. A second row pushes the actions under the bottom
        // navigation on a 390 x 844 viewport. Larger text still uses the
        // stacked branch above, where the page can scroll normally.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                Expanded(child: tiles[index]),
                if (index != tiles.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 숏컷 타일 — 썸네일 → 라벨 → 카운트 세로 구성, 전체가 탭타깃.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.id,
    required this.label,
    required this.count,
    required this.thumb,
    required this.onTap,
  });

  final String id;
  final String label;
  final String? count;
  final Widget thumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final horizontal =
        MediaQuery.sizeOf(context).width < SoriBreakpoints.narrowPhone &&
        MediaQuery.textScalerOf(context).scale(1) < 1.6;
    final labelText = Text(
      label,
      key: ValueKey('hanok-shortcut-label-$id'),
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: tt.label.copyWith(fontSize: 16, height: 1.2, color: CPalette.ink),
    );
    return KeyedSubtree(
      key: ValueKey('hanok-shortcut-$id'),
      child: Semantics(
        // A count change replaces the semantic annotation as well as its
        // visible Text. This avoids an old cached label surviving a
        // FutureBuilder refresh in accessibility mode.
        key: ValueKey('hanok-shortcut-semantics-$id-${count ?? 'loading'}'),
        button: true,
        label: count == null ? label : '$label, $count',
        onTap: onTap,
        child: ExcludeSemantics(
          child: CImageTap(
            label: count == null ? label : '$label, $count',
            onTap: onTap,
            child: CPaperPanel(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal ? 8 : 2,
                vertical: 8,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Flex(
                  direction: horizontal ? Axis.horizontal : Axis.vertical,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: horizontal ? 24 : null,
                      height: MediaQuery.sizeOf(context).height < 750 ? 24 : 40,
                      child: Center(child: thumb),
                    ),
                    SizedBox(
                      height: horizontal ? 0 : 4,
                      width: horizontal ? 6 : 0,
                    ),
                    if (horizontal)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelText,
                            if (count != null)
                              Text(
                                count!,
                                key: ValueKey('hanok-shortcut-count-$id'),
                                style: tt.caption.copyWith(
                                  fontSize: 16,
                                  color: s.textMuted,
                                ),
                              ),
                          ],
                        ),
                      )
                    else ...[
                      labelText,
                      if (count != null)
                        Text(
                          count!,
                          key: ValueKey('hanok-shortcut-count-$id'),
                          // 자릿수 정렬(progress_meter.dart:191과 동일 패턴) — 이
                          // 카운트는 갱신마다 자릿수가 바뀔 수 있어(0/1 → 1/1 등)
                          // 폭이 흔들리지 않게 tabular figures 를 쓴다.
                          style: tt.caption.copyWith(
                            fontSize: 16,
                            color: s.textMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
