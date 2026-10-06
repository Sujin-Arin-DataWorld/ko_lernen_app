import '../../widgets/sori/yeopjeon_wallet_card.dart';
import '../../features/dancheong/dancheong_connections.dart';
import '../../features/dancheong/dancheong_store.dart';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/home_navigation_art.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'c_stage_chrome.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';

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
    return Scaffold(
      body: CStageBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 600,
            base: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            builder: (context, padding) =>
                FutureBuilder<SoriStageProgressionSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    final data =
                        snapshot.connectionState == ConnectionState.done &&
                            !snapshot.hasError
                        ? snapshot.data
                        : null;
                    final owned = data?.ownedSarangchaeStage;
                    return ListView(
                      padding: padding,
                      children: [
                        CStageHeader(
                          title: t.onboardingJourneyHanokShort,
                          balance: data?.walletUnavailable == false
                              ? data?.wallet?.balance
                              : null,
                          onWalletReturned: _refresh,
                        ),
                        CPaperPanel(
                          key: const ValueKey('c-hanok-board'),
                          radius: 18,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                child: CHanokScene(),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.hanokWorldProgress,
                                style: cStageCardTitle.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 10),
                              if (owned != null &&
                                  data?.walletUnavailable == false) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    for (final stage in [0, 4, 8, 12, 16])
                                      Semantics(
                                        label: t.sarangchaeConstructionProgress(
                                          stage,
                                          SarangchaeConstruction.stageCount,
                                        ),
                                        child: CWaxSeal(
                                          size: 32,
                                          active: owned >= stage,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t.sarangchaeConstructionProgress(
                                    owned,
                                    SarangchaeConstruction.stageCount,
                                  ),
                                  style: cStageBody,
                                ),
                              ] else if (snapshot.hasError ||
                                  data?.walletUnavailable == true) ...[
                                Text(
                                  t.soriStageHanokProgressUnavailable,
                                  key: const ValueKey('hanok-progress-error'),
                                  style: cStageBody,
                                ),
                                CMaterialAction(
                                  label: t.btnRetry,
                                  compact: true,
                                  onTap: _refresh,
                                ),
                              ] else
                                const LinearProgressIndicator(),
                              const SizedBox(height: 12),
                              CMaterialAction(
                                key: const ValueKey('hanok-construction-entry'),
                                label: t.ilduConstructionTitle,
                                onTap: () =>
                                    _openShortcut('/hanok/construction'),
                              ),
                              const SizedBox(height: 14),
                              CPaperPanel(
                                radius: 12,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/illustrations/concept_c/dancheong_preview_v3.png',
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            t.dancheongTitle,
                                            style: cStageCardTitle.copyWith(
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          CMaterialAction(
                                            label: t.dancheongEntryAction,
                                            gold: false,
                                            compact: true,
                                            onTap: () => _openShortcut(
                                              '/dancheong-studio',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ShortcutTiles(
                                snapshot: data,
                                onOpen: _openShortcut,
                              ),
                              const SizedBox(height: 12),
                              DancheongDraftResume(
                                store: DancheongStore(),
                                onOpen: (arguments) =>
                                    Navigator.of(context).pushNamed(
                                      '/dancheong-studio/edit',
                                      arguments: arguments,
                                    ),
                              ),
                              ExpansionTile(
                                key: const ValueKey('hanok-how-to-build'),
                                tilePadding: EdgeInsets.zero,
                                trailing: const CArrow(down: true, dark: true),
                                title: Text(t.hanokHowTitle, style: cStageBody),
                                children: [
                                  Text(t.hanokHowBody, style: cStageBody),
                                  CulturalGlossaryBuilder(
                                    builder: (context, glossary) {
                                      final entry = glossary?.entry('hanok');
                                      if (entry == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return TextButton(
                                        key: const Key('cultural_help_hanok'),
                                        onPressed: () => showCulturalTermSheet(
                                          context,
                                          entry,
                                        ),
                                        child: Text(
                                          t.culturalMeaningLabel,
                                          style: cStageBody,
                                        ),
                                      );
                                    },
                                  ),
                                  CMaterialAction(
                                    label: t.hanokHowAction,
                                    compact: true,
                                    gold: false,
                                    onTap: () => _openShortcut('/path'),
                                  ),
                                ],
                              ),
                              if (data != null)
                                Text(
                                  data.hanokCompetence.totalUnitCount == 0
                                      ? t.soriStageHanokNoUnits
                                      : t.soriStageConfirmedUnits(
                                          data
                                              .hanokCompetence
                                              .completedUnitCount,
                                          data.hanokCompetence.totalUnitCount,
                                        ),
                                  key: const ValueKey('hanok-confirmed-units'),
                                  style: cStageBody,
                                ),
                              const SizedBox(height: 12),
                              YeopjeonWalletCard(
                                conceptC: true,
                                key: ObjectKey(_future),
                                onBuilt: _refresh,
                              ),
                              ExpansionTile(
                                key: const ValueKey('c-hanok-stage-details'),
                                trailing: const CArrow(down: true, dark: true),
                                title: Text(
                                  t.sarangchaeConstructionStages,
                                  style: cStageBody,
                                ),
                                children: [
                                  SizedBox(
                                    height: 300,
                                    child: _CurrentSarangchaeArtwork(
                                      progressionFuture: _future,
                                      constructionFuture: _constructionFuture,
                                      selectedSequence: _selectedSequence,
                                    ),
                                  ),
                                  FutureBuilder<SarangchaeConstruction>(
                                    future: _constructionFuture,
                                    builder: (context, construction) {
                                      if (construction.hasError ||
                                          snapshot.hasError ||
                                          data?.walletUnavailable == true) {
                                        return CMaterialAction(
                                          label: t.btnRetry,
                                          compact: true,
                                          onTap: _refresh,
                                        );
                                      }
                                      if (!construction.hasData ||
                                          data == null) {
                                        return const LinearProgressIndicator();
                                      }
                                      return SarangchaeConstructionExperience(
                                        key: ObjectKey(_future),
                                        construction: construction.data!,
                                        earnedStageCount: owned ?? 0,
                                        showArtwork: false,
                                        onStageSelected: (sequence) => setState(
                                          () => _selectedSequence = sequence,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
          child: const Center(child: Icon(Icons.error_outline_rounded)),
        );
      }
      if (!constructionSnapshot.hasData) {
        return const AppLoading();
      }
      return FutureBuilder<SoriStageProgressionSnapshot>(
        future: progressionFuture,
        builder: (context, progressionSnapshot) {
          if (progressionFuture != null &&
              progressionSnapshot.connectionState != ConnectionState.done) {
            return const AppLoading();
          }
          if (progressionSnapshot.hasError ||
              (progressionSnapshot.data?.walletUnavailable ?? false)) {
            return Semantics(
              label: AppL10n.of(context).loadErrorTryAgain,
              child: const Center(child: Icon(Icons.error_outline_rounded)),
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
        : snapshot!.hasPendingDecorationReceipt
        ? t.rewardChestReplay
        : '${snapshot!.pendingBojagiCount}';

    final tiles = <_ShortcutTile>[
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
        thumb: const CObjectArt(CObject.stampbook, size: 40),
        onTap: () => onOpen('/dojangcheop'),
      ),
      _ShortcutTile(
        id: 'bojagi',
        label: t.soriStageHanokGifts,
        count: bojagiCount,
        thumb: Image.asset(
          HomeNavigationArt.treasureChest,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        onTap: () => onOpen('/bojagi'),
      ),
      _ShortcutTile(
        id: 'furnish',
        label: t.sarangbangStudyFurnish,
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
        final width = (constraints.maxWidth - 10) / 2;
        // A compound German word must fit beside the thumbnail without being
        // split in the middle. Use full rows when the real font needs more room.
        final labelFits = tiles.every((tile) {
          for (final word in tile.label.split(RegExp(r'\s+'))) {
            final measure = TextPainter(
              text: TextSpan(
                text: word,
                style: cStageBody.copyWith(fontWeight: FontWeight.w600),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final fits = measure.width <= width - 68;
            measure.dispose();
            if (!fits) return false;
          }
          return true;
        });
        final stacked =
            constraints.maxWidth < SoriAdaptiveWidth.shortcutRow ||
            textScale >= 1.6 ||
            !labelFits;
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
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
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
  final String id, label;
  final String? count;
  final Widget thumb;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey('hanok-shortcut-$id'),
    child: CImageTap(
      key: ValueKey('hanok-shortcut-semantics-$id-${count ?? 'loading'}'),
      label: count == null ? label : '$label, $count',
      onTap: onTap,
      child: CPaperPanel(
        radius: 10,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(width: 40, height: 48, child: thumb),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    key: ValueKey('hanok-shortcut-label-$id'),
                    style: cStageBody.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (count != null)
                    Text(
                      count!,
                      key: ValueKey('hanok-shortcut-count-$id'),
                      style: cStageBody.copyWith(fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
