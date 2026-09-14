import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../bojagi_screen.dart' show kBojagiClosed;

class SoriStageHanokScreen extends StatefulWidget {
  const SoriStageHanokScreen({
    super.key,
    this.loadSnapshot,
    this.active = true,
    this.refreshGeneration = 0,
  });

  /// Test seam; production uses the shared Stage progression snapshot.
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  /// The shell keeps every tab alive. Refresh progression whenever this tab
  /// becomes visible so work completed in Today/Learn is reflected here.
  final bool active;
  final int refreshGeneration;

  @override
  State<SoriStageHanokScreen> createState() => _SoriStageHanokScreenState();
}

class _SoriStageHanokScreenState extends State<SoriStageHanokScreen> {
  Future<SoriStageProgressionSnapshot>? _future;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
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
            oldWidget.refreshGeneration != widget.refreshGeneration)) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _future = _load();
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
    // One scroll surface: verified learning, current portrait, then collections.
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: SoriMaxWidth.world,
            // top=20 (§W-F3 §1) — matches the catalog screen
            // (sori_stage_catalog_screen.dart:~144) so every Stage tab
            // starts the same distance below SafeArea; Lernen/Spiele/Gye all
            // use this same rhythm, and Hanok diverging at 0 broke it.
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                  ),
                  sliver: SoriCollapsingHeader(
                    title: t.soriStageNavHanok,
                    titleStyle: SoriTextTheme.of(
                      context,
                    ).h1.copyWith(fontSize: 26, height: 1.35),
                    // 접힌 56dp 크롬 바용 짧은 제목 — 없으면 title 전체가
                    // ellipsis 로 잘린다.
                    collapsedTitle: t.soriStageNavHanok,
                    trailingSlots: 2,
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CulturalHelpButton(termId: 'hanok'),
                        SizedBox(width: Spacing.xs),
                        SoriAvatar(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
                FutureBuilder<SoriStageProgressionSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    final ready =
                        snapshot.connectionState == ConnectionState.done &&
                        !snapshot.hasError;
                    final data = ready ? snapshot.data : null;
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        8,
                        padding.right,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t.soriStageHanokLearningSummary,
                              style: SoriTextTheme.of(context).cardTitle,
                            ),
                            const SizedBox(height: Spacing.sm),
                            if (data != null)
                              Text(
                                data.hanokCompetence.totalUnitCount == 0
                                    ? t.soriStageHanokNoUnits
                                    : t.soriStageConfirmedUnits(
                                        data.hanokCompetence.completedUnitCount,
                                        data.hanokCompetence.totalUnitCount,
                                      ),
                                key: const ValueKey('hanok-confirmed-units'),
                                style: SoriTextTheme.of(context).body,
                              )
                            else if (snapshot.hasError) ...[
                              Text(
                                t.soriStageHanokProgressUnavailable,
                                key: const ValueKey('hanok-progress-error'),
                              ),
                              TextButton(
                                onPressed: _refresh,
                                child: Text(t.btnRetry),
                              ),
                            ] else
                              const LinearProgressIndicator(),
                            const SizedBox(height: Spacing.lg),
                            LayoutBuilder(
                              builder: (context, constraints) => Center(
                                child: SizedBox(
                                  key: const ValueKey('hanok-full-preview'),
                                  width: constraints.maxWidth,
                                  height: (constraints.maxWidth * 1376 / 768)
                                      .clamp(0.0, 400.0),
                                  child: HanokV3Preview(
                                    message: t.soriStageHanokUpdating,
                                    showOverlay: false,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              t.soriStageHanokUpdating,
                              key: const ValueKey('hanok-preview-status'),
                              textAlign: TextAlign.center,
                              style: SoriTextTheme.of(context).bodySmall,
                            ),
                            const SizedBox(height: Spacing.xl),
                            _ShortcutTiles(
                              snapshot: data,
                              onOpen: _openShortcut,
                            ),
                            const SizedBox(height: Spacing.xl),
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
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked =
            constraints.maxWidth < SoriAdaptiveWidth.shortcutRow ||
            textScale >= 1.6;
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
        // §W-J2 item 3: one label (e.g. "Dojang-Heft") can wrap to 2 lines
        // while its siblings stay on 1 — without a shared height the middle
        // tile alone grows taller. `IntrinsicHeight` + a stretch cross-axis
        // makes all three tiles match the tallest one instead.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                Expanded(child: tiles[index]),
                if (index != tiles.length - 1)
                  const SizedBox(width: Spacing.md),
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
          child: SoriCard(
            variant: SoriCardVariant.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 40, child: Center(child: thumb)),
                const SizedBox(height: Spacing.xs),
                Text(
                  label,
                  key: ValueKey('hanok-shortcut-label-$id'),
                  textAlign: TextAlign.center,
                  style: tt.label.copyWith(fontSize: 15, height: 1.35),
                ),
                if (count != null)
                  Text(
                    count!,
                    key: ValueKey('hanok-shortcut-count-$id'),
                    // 자릿수 정렬(progress_meter.dart:191과 동일 패턴) — 이
                    // 카운트는 갱신마다 자릿수가 바뀔 수 있어(0/1 → 1/1 등)
                    // 폭이 흔들리지 않게 tabular figures 를 쓴다.
                    style: tt.caption.copyWith(
                      color: s.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
