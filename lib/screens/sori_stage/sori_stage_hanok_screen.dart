import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_hanok.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/hanok_stage_service.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/personal_hanok_map.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/updating_scene.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../bojagi_screen.dart' show kBojagiClosed;
import '../hanok_world_screen.dart';

class SoriStageHanokScreen extends StatefulWidget {
  const SoriStageHanokScreen({
    super.key,
    this.loadSnapshot,
    this.active = true,
    this.worldForTesting,
    this.worldLoadRatios,
    this.worldLoadProjection,
  });

  /// Test seam; production uses the shared Stage progression snapshot.
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  /// The shell keeps every tab alive. Refresh progression whenever this tab
  /// becomes visible so work completed in Today/Learn is reflected here.
  final bool active;

  /// Keeps shortcut tests independent from the production world's async
  /// unlock-reveal layer. Production callers always render [HanokWorldScreen].
  @visibleForTesting
  final Widget? worldForTesting;

  /// Test seams forwarded straight to the embedded [HanokWorldScreen]'s own
  /// `loadRatios`/`loadProjection`, so a fold test can drive its place list
  /// and detail panel deterministically without going through [Storage]
  /// (§W-F F4). Ignored when [worldForTesting] is supplied.
  @visibleForTesting
  final Future<LevelRatios> Function()? worldLoadRatios;

  @visibleForTesting
  final Future<PersonalHanokProjection> Function(LevelRatios ratios)?
  worldLoadProjection;

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
        (!oldWidget.active || oldWidget.loadSnapshot != widget.loadSnapshot)) {
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
    // `HanokWorldScreen(embedded: true)` builds itself as a sliver (§W-F F2);
    // the test seam substitutes a plain box widget, so that one alone needs
    // wrapping to satisfy the surrounding `CustomScrollView`'s sliver contract.
    Widget world() {
      final override = widget.worldForTesting;
      return override == null
          ? HanokWorldScreen(
              embedded: true,
              loadRatios: widget.worldLoadRatios,
              loadProjection: widget.worldLoadProjection,
            )
          : SliverToBoxAdapter(child: override);
    }

    // §W-F F1: a single continuous `CustomScrollView` replaces the previous
    // fixed-chrome `Column` (header/`Expanded` map/shortcuts) — the map no
    // longer claims all leftover height and hides the place list below 640dp.
    // The large-text (≥1.6) `ListView` fallback is gone too: this sliver
    // structure already reflows for any text scale, so `SoriStageSafeViewport`
    // is no longer needed on this tab.
    //
    // §W-F2 J11: the header wraps exactly like
    // `sori_stage_catalog_screen.dart`'s — a clamp builder feeding a
    // `SliverPadding(left/right)` around the header, so its text shares the
    // same edges as the shortcut row and place list instead of touching the
    // screen edge. `maxWidth`/`base.left`/`base.right` (960 / 20) are the
    // same clamp inputs `buildEmbeddedSlivers` uses for the place list, so
    // all three stay aligned at any width, phone or tablet.
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
                    eyebrow: t.soriStageNavHanok,
                    title: t.soriStageHanokTitle,
                    body: t.soriStageHanokBody,
                    // 접힌 56dp 크롬 바용 짧은 제목 — 없으면 title 전체가
                    // ellipsis 로 잘린다.
                    collapsedTitle: t.soriStageNavHanok,
                    trailing: const CulturalHelpButton(termId: 'hanok'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
                FutureBuilder<SoriStageProgressionSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    final ready =
                        snapshot.connectionState == ConnectionState.done &&
                        !snapshot.hasError;
                    final data = ready ? snapshot.data : null;
                    return _HanokMapSliver(projection: data?.hanok);
                  },
                ),
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
                        child: _ShortcutTiles(
                          snapshot: data,
                          onOpen: _openShortcut,
                        ),
                      ),
                    );
                  },
                ),
                world(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// §W-F F1.2/F3: a pinned, shrinking preview of the personal Hanok map.
///
/// Purely decorative (no per-zone hotspots) — a tap anywhere opens the same
/// `/hanok` (`IlDuWorldScreen`) destination as the Today tab's Hanok card, so
/// the map and that card now agree on a single place to keep browsing the
/// estate (§W-F F3). The zone-by-zone place list and its detail panel remain
/// in [HanokWorldScreen.buildEmbeddedSlivers] below.
class _HanokMapSliver extends StatelessWidget {
  const _HanokMapSliver({required this.projection});

  final PersonalHanokProjection? projection;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = SoriMotion.reduceMotion(context);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.crossAxisExtent;
        // §W-F F1.2 — 진행은 장소: 지도가 이 탭의 주인공이다. 확장 높이 =
        // min(w×3/4, 320)(태블릿 상한), 축소 높이 = max(w×0.25, 88).clamp(88,
        // expandedHeight). 390dp → 292/98, 320dp → 240/88. fold 기준(§W-F F4):
        // 헤더·지도·바로가기 행은 전부 뷰포트 안, 첫 장소 카드는 상단 24dp만
        // 보이면 된다(스크롤 단서, test/sori_stage_hanok_fold_test.dart와 동일
        // 기준). reduce-motion은 두 상태를 즉시 스냅한다.
        final expandedHeight = math.min(w * 3 / 4, 320.0);
        final collapsedHeight = math
            .max(w * 0.25, 88.0)
            .clamp(88.0, expandedHeight);
        return SliverPersistentHeader(
          pinned: true,
          delegate: _HanokMapHeaderDelegate(
            width: w,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            projection: projection,
            reduceMotion: reduceMotion,
          ),
        );
      },
    );
  }
}

class _HanokMapHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HanokMapHeaderDelegate({
    required this.width,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.projection,
    required this.reduceMotion,
  });

  /// The sliver's own cross-axis extent — used to lay the map out at its
  /// real display width (below) instead of a scaled-up nominal box.
  final double width;
  final double expandedHeight;
  final double collapsedHeight;
  final PersonalHanokProjection? projection;
  final bool reduceMotion;

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
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final clampedShrink = shrinkOffset.clamp(0.0, range);
    final rawProgress = clampedShrink / range;
    // reduce-motion: 중간 보간 없이 두 상태를 즉시 스냅한다(WCAG 2.3.3) —
    // 패럴랙스도 함께 스냅해 진행에 따라 계속 흘러가는 움직임을 없앤다.
    final progress = reduceMotion
        ? (rawProgress < 0.5 ? 0.0 : 1.0)
        : rawProgress;
    final currentExtent = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final hintOpacity = (1 - progress).clamp(0.0, 1.0);
    final translateY = -(progress * range * 0.5);

    final projection = this.projection;
    Widget mapArt;
    if (kHanokWorldUpdating) {
      // Jin 2026-09-03: compound map(항공 부감 합성)이 "지저분하고 이미
      // 안 쓰는 이미지"라 판단돼, 새 지도가 착지할 때까지 단일 스틸 +
      // 베일로 대체한다. 베일 자체는 전체 한옥 화면으로 여는 접근점을 유지하고,
      // 힌트 스크림·고스트 예고만 끈다.
      mapArt = Semantics(
        button: true,
        label: t.hanokWorldTitle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pushNamed('/hanok'),
          child: SoriUpdatingScene(
            asset: 'assets/illustrations/hanok/estate_overview.webp',
            message: t.soriStageHanokUpdating,
            alignment: Alignment.center,
          ),
        ),
      );
    } else if (projection == null) {
      mapArt = ColoredBox(color: s.surfaceAlt);
    } else {
      mapArt = PersonalHanokMap(
        projection: projection,
        zoneLabel: (_) => '',
        showTargets: false,
        onTap: () => Navigator.of(context).pushNamed('/hanok'),
      );
    }

    return ClipRect(
      child: SizedBox(
        key: const ValueKey('hanok-map-header'),
        height: currentExtent,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: FittedBox(
                  fit: BoxFit.cover,
                  // 실폭 배치(§W-F F2 개선) — PersonalHanokMap을 이 슬리버의
                  // 실제 crossAxisExtent(4:3)로 레이아웃한다. FittedBox(cover)는
                  // 확장 상태에서 스케일 1(그대로), 축소 상태에서만 가운데
                  // 크롭한다. 이전엔 32×24 참조 박스를 ~12배 확대해 라벨·마커·
                  // 패딩까지 함께 스케일됐다(showTargets:false라 우연히 안
                  // 보였을 뿐) — 실폭이면 향후 오버레이도 정상 크기로 그려진다.
                  child: SizedBox(
                    width: width,
                    height: width * 3 / 4,
                    child: mapArt,
                  ),
                ),
              ),
            ),
            if (!kHanokWorldUpdating)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Visibility(
                  visible: hintOpacity > 0,
                  maintainState: false,
                  child: Opacity(
                    opacity: hintOpacity,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.md,
                          Spacing.lg,
                          Spacing.md,
                          Spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        // §16 타이포 가드: 화면 콘텐츠를 ellipsis 로 숨기지 않는다 —
                        // 잘림 대신 자연 줄바꿈(컨테이너에 고정 높이가 없어
                        // 오버플로 위험 없음).
                        child: Text(
                          t.hanokWorldMapHint,
                          style: tt.meta.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HanokMapHeaderDelegate oldDelegate) {
    return width != oldDelegate.width ||
        expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        projection != oldDelegate.projection ||
        reduceMotion != oldDelegate.reduceMotion;
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
      questsCount = '$done / $total';
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
        label: t.soriStageQuests,
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
        label: t.soriStageDojang,
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
        label: t.soriStageBojagi,
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
                  style: tt.cardTitle,
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
