import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/activity_sheet.dart';
import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/collapsing_header.dart';
import '../../widgets/sori/illustrated_card.dart';
import '../../widgets/sori/illustrated_card_grid.dart';
import '../../widgets/sori/motion.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/section_header.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';

// W10 T-H1: `cellAspectRatioCacheKey` moved to `illustrated_card_grid.dart`
// (shared with the listening hub grid). Re-exported so existing callers of
// this library (e.g. test/sori_stage_cell_aspect_ratio_cache_test.dart) keep
// resolving it from the same import path — a frozen assertion, not touched.
export '../../widgets/sori/illustrated_card_grid.dart'
    show cellAspectRatioCacheKey;

class SoriStageCatalogScreen extends StatefulWidget {
  const SoriStageCatalogScreen({
    super.key,
    required this.tab,
    this.loadSnapshot,
    this.active = true,
  });

  final SoriStageTab tab;
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final bool active;

  @override
  State<SoriStageCatalogScreen> createState() => _SoriStageCatalogScreenState();
}

class _SoriStageCatalogScreenState extends State<SoriStageCatalogScreen> {
  Future<SoriStageProgressionSnapshot>? _progress;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _progress = _load();
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        ((!oldWidget.active && widget.active) ||
            oldWidget.loadSnapshot != widget.loadSnapshot ||
            oldWidget.tab != widget.tab)) {
      _progress = _load();
    }
  }

  void _reload() => setState(() {
    _progress = _load();
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final entries = soriActivityCatalog
        .where((entry) => entry.tab == widget.tab)
        .toList();
    final isGames = widget.tab == SoriStageTab.games;

    // §C-1-11: Learn 탭은 단어팩(핵심 학습 경로)을 그리드 타일이 아니라
    // **대형 진입 카드**로 승격한다 — 그리드에서는 빼서 중복을 피한다.
    // §P4-4: Games 탭도 대칭 — daily_game(오늘의 게임)을 히어로로 승격.
    // §E4: 마지막으로 연 활동이 이 탭에 있으면 그 활동을 "이어하기" 히어로로
    // 승격한다 — 이 탭에 없으면(다른 탭 활동이었거나 기록이 없으면) 기존
    // 기본(vocab_packs/daily_game)으로 되돌아간다.
    // §W10 T-L1: Learn 탭은 여기서 한 걸음 더 좁힌다 — 마지막 활동이 "오늘"
    // 섹션 소속일 때만 이어하기 히어로로 승격한다. 탐색/복습 활동은 여전히
    // 기록되고(다음에 열 때 유용) 그 활동 자체는 자기 섹션의 평범한 카드로
    // 보이지만, 히어로 자리(오늘 섹션 최상단)는 항상 "오늘" 활동만 차지한다
    // — Games 탭은 섹션이 없으므로 기존 규칙 그대로.
    final defaultHeroId = isGames ? 'daily_game' : 'vocab_packs';
    final lastActivityId = Storage.lastActivityId;
    ActivityCatalogEntry? lastActivityEntry;
    for (final entry in entries) {
      if (entry.id == lastActivityId) {
        lastActivityEntry = entry;
        break;
      }
    }
    final isContinuingHero = isGames
        ? lastActivityEntry != null
        : lastActivityEntry != null &&
              lastActivityEntry.learnSection == SoriLearnSection.today;
    final heroId = isContinuingHero ? lastActivityId : defaultHeroId;
    ActivityCatalogEntry? heroEntry;
    for (final entry in entries) {
      if (entry.id == heroId) {
        heroEntry = entry;
        break;
      }
    }
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 880,
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) {
              // W10 T-H1: column count + measured childAspectRatio now
              // live in SoriIllustratedCardGrid (a sliver) — it reads the
              // available cross-axis width from the SliverPadding below
              // itself, so this no longer needs its own box LayoutBuilder.
              return CustomScrollView(
                slivers: [
                  // §E3: 상단 여백은 접히는 헤더 앞에서 먼저 스크롤돼 사라진다
                  // — 헤더 자체는 pinned 로 56dp까지 접히며 화면에 남는다.
                  SliverToBoxAdapter(child: SizedBox(height: padding.top)),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: padding.left,
                      right: padding.right,
                    ),
                    sliver: SoriCollapsingHeader(
                      eyebrow: isGames
                          ? t.soriStageNavGames
                          : t.soriStageNavLearn,
                      title: isGames
                          ? t.soriStageGamesTitle
                          : t.soriStageLearnTitle,
                      body: isGames
                          ? t.soriStageGamesBody
                          : t.soriStageLearnBody,
                      collapsedTitle: isGames
                          ? t.soriStageNavGames
                          : t.soriStageNavLearn,
                      // §W-G2 item 4(Fable 승인, 2026-09-03): 프로필
                      // 진입 아이콘 → SoriAvatar. Gye 탭이 이미 같은
                      // 위젯으로 바꿔 뒀고(§W-G G3), Hanok 탭은 프로필
                      // 진입점 자체가 없어 손대지 않는다 — trailingSlots
                      // 기본값 1 그대로.
                      trailing: const SoriAvatar(),
                    ),
                  ),
                  // §LAYOUT-1: 헤더→첫 콘텐츠 간격은 섹션 간격(xl=24) 하나.
                  // 페이지 하단 여백(48)은 그리드 끝(아래 SliverPadding)에서만
                  // — Spacing.page.bottom 을 헤더 슬리버에도 겹쳐 더하지 않는다.
                  // §W10 T-L1: Learn 탭에서는 이 간격이 첫 섹션 제목
                  // (SoriSectionHeader) 앞으로 온다 — Games 탭은 그대로
                  // 히어로/그리드 앞.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.xl),
                  ),
                  FutureBuilder<SoriStageProgressionSnapshot>(
                    future: _progress,
                    builder: (context, snapshot) {
                      final ready =
                          snapshot.connectionState == ConnectionState.done &&
                          !snapshot.hasError;
                      final activityProgress = ready
                          ? snapshot.data?.activityProgress
                          : null;
                      Widget buildHeroCard(ActivityCatalogEntry hero) {
                        Widget card = _ActivityGridCard(
                          entry: hero,
                          hero: true,
                          progress: activityProgress?[hero.id],
                          loadSnapshot:
                              widget.loadSnapshot ??
                              SoriStageProgressionService.load,
                          onActivityReturned: _reload,
                        );
                        if (isContinuingHero) {
                          card = SoriPulse(child: card);
                        }
                        return card;
                      }

                      if (isGames) {
                        final gridEntries = heroEntry == null
                            ? entries
                            : entries
                                  .where((entry) => entry.id != heroEntry!.id)
                                  .toList();
                        return SliverMainAxisGroup(
                          slivers: [
                            if (heroEntry case final hero?)
                              _heroSectionSliver(
                                context: context,
                                padding: padding,
                                isContinuingHero: isContinuingHero,
                                t: t,
                                heroCard: buildHeroCard(hero),
                              ),
                            _sectionGridSliver(
                              context: context,
                              t: t,
                              entries: gridEntries,
                              activityProgress: activityProgress,
                              padding: padding,
                              bottomPadding: padding.bottom,
                              loadSnapshot:
                                  widget.loadSnapshot ??
                                  SoriStageProgressionService.load,
                              onActivityReturned: _reload,
                            ),
                          ],
                        );
                      }

                      // §W10 T-L1: Learn 탭 — 오늘/탐색/복습 세 섹션을
                      // 순서대로 렌더한다. 히어로는 항상 "오늘" 섹션 안,
                      // 그 섹션 제목 바로 아래에 온다 — 다른 섹션은 그리드
                      // 카드만 있다. 각 섹션의 카드 종횡비는 그 섹션의
                      // 타이틀/서브타이틀/풋터만으로 실측한다(섹션 간에
                      // 서로 다른 카드 높이를 강제하지 않는다).
                      const sectionOrder = <SoriLearnSection>[
                        SoriLearnSection.today,
                        SoriLearnSection.explore,
                        SoriLearnSection.review,
                      ];
                      final sectionTitles = <SoriLearnSection, String>{
                        SoriLearnSection.today: t.soriStageLearnSectionToday,
                        SoriLearnSection.explore:
                            t.soriStageLearnSectionExplore,
                        SoriLearnSection.review:
                            t.soriStageLearnSectionReview,
                      };
                      final slivers = <Widget>[];
                      for (var i = 0; i < sectionOrder.length; i++) {
                        final section = sectionOrder[i];
                        final sectionEntries = entries
                            .where((entry) => entry.learnSection == section)
                            .toList();
                        final sectionHero =
                            heroEntry != null &&
                                heroEntry.learnSection == section
                            ? heroEntry
                            : null;
                        final sectionGridEntries = sectionHero == null
                            ? sectionEntries
                            : sectionEntries
                                  .where(
                                    (entry) => entry.id != sectionHero.id,
                                  )
                                  .toList();
                        if (i > 0) {
                          slivers.add(
                            const SliverToBoxAdapter(
                              child: SizedBox(height: Spacing.xl),
                            ),
                          );
                        }
                        slivers.add(
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: padding.left,
                              right: padding.right,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: SoriSectionHeader(sectionTitles[section]!),
                            ),
                          ),
                        );
                        slivers.add(
                          const SliverToBoxAdapter(
                            child: SizedBox(height: Spacing.md),
                          ),
                        );
                        if (sectionHero != null) {
                          slivers.add(
                            _heroSectionSliver(
                              context: context,
                              padding: padding,
                              isContinuingHero: isContinuingHero,
                              t: t,
                              heroCard: buildHeroCard(sectionHero),
                            ),
                          );
                        }
                        final isLastSection = i == sectionOrder.length - 1;
                        slivers.add(
                          _sectionGridSliver(
                            context: context,
                            t: t,
                            entries: sectionGridEntries,
                            activityProgress: activityProgress,
                            padding: padding,
                            bottomPadding: isLastSection ? padding.bottom : 0,
                            loadSnapshot:
                                widget.loadSnapshot ??
                                SoriStageProgressionService.load,
                            onActivityReturned: _reload,
                          ),
                        );
                      }
                      return SliverMainAxisGroup(slivers: slivers);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// §W10 T-L1: the hero card band — the optional "CONTINUE WITH" eyebrow plus
/// the hero card itself. Shared by the Games tab's single hero slot and the
/// Learn tab's "today" section hero slot.
Widget _heroSectionSliver({
  required BuildContext context,
  required EdgeInsets padding,
  required bool isContinuingHero,
  required AppL10n t,
  required Widget heroCard,
}) => SliverPadding(
  padding: EdgeInsets.only(
    left: padding.left,
    right: padding.right,
    bottom: Spacing.md,
  ),
  sliver: SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isContinuingHero) ...[
          Text(
            t.soriStageContinueEyebrow.toUpperCase(),
            style: SoriTextTheme.of(context).eyebrow,
          ),
          const SizedBox(height: Spacing.xs),
        ],
        heroCard,
      ],
    ),
  ),
);

/// §W10 T-L1: one grid of activity cards, measured and laid out from just
/// its own [entries] — extracted from the previous single whole-tab grid so
/// each Learn-tab section can size its cards independently (§LAYOUT-2(J12)
/// measurement contract unchanged, just scoped per call).
///
/// §W10 T-H1: the column count + measured `childAspectRatio` are computed
/// by [SoriIllustratedCardGrid] itself (a `SliverLayoutBuilder` reading the
/// cross-axis extent this sliver is given) — shared with the listening hub
/// grid, same target/min/max and `Spacing.md` gaps, same output.
Widget _sectionGridSliver({
  required BuildContext context,
  required AppL10n t,
  required List<ActivityCatalogEntry> entries,
  required Map<String, SoriActivityProgress>? activityProgress,
  required EdgeInsets padding,
  required double bottomPadding,
  required Future<SoriStageProgressionSnapshot> Function() loadSnapshot,
  required VoidCallback onActivityReturned,
}) {
  final gridTitles = entries.map((entry) => localCopy(context, entry.title));
  // §E2: 메타 라인(분)도 title/footer 처럼 카드 높이에 들어가므로 같이 잰다.
  final gridSubtitles = entries.map(
    (entry) => t.soriStageMinutes(entry.minutes),
  );
  final footerLabels = <String>[
    t.soriStageActivityNew,
    t.soriStageActivityInProgress,
    t.soriStageActivityCompleted,
    for (final entry in entries)
      if (entry.unlock.explanation case final explanation?)
        localCopy(context, explanation),
  ];
  // §LAYOUT-2(J12): once the snapshot resolves, measure each entry's
  // *actual* rendered state string (label + real progress suffix) instead
  // of the three bare state labels above — a worst-case constant ('999 /
  // 999' always) would pad every card's white space (L4); this instead
  // grows the cell height by exactly what the FutureBuilder's second frame
  // draws. The cache in _cellAspectRatio keys on footerLabels content, so
  // this list changing between the optimistic first frame and the resolved
  // frame invalidates the cache automatically (one height jump, not
  // per-frame recomputation).
  final progressFooterLabels = activityProgress == null
      ? const <String>[]
      : [
          for (final entry in entries)
            if (activityProgress[entry.id] case final progress?)
              activityStateText(
                activityStateLabel(context, t, progress.state, entry),
                progress.current,
                progress.target,
              ),
        ];
  return SliverPadding(
    padding: EdgeInsets.only(
      left: padding.left,
      right: padding.right,
      bottom: bottomPadding,
    ),
    sliver: SoriIllustratedCardGrid(
      itemCount: entries.length,
      titles: gridTitles,
      subtitles: gridSubtitles,
      footerLabels: [...footerLabels, ...progressFooterLabels],
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _ActivityGridCard(
          entry: entry,
          progress: activityProgress?[entry.id],
          loadSnapshot: loadSnapshot,
          onActivityReturned: onActivityReturned,
        );
      },
    ),
  );
}

/// 2026-08-14 Phase 3: 활동 카드 — [SoriIllustratedCard] 규격.
///
/// 상단 일러스트 슬롯(규약 `activities/{id}.webp`, 미존재 시 아이콘 원형 폴백)
/// + 타이틀 + 서브타이틀(분) + footer(상태 칩).
class _ActivityGridCard extends StatelessWidget {
  const _ActivityGridCard({
    required this.entry,
    required this.progress,
    required this.loadSnapshot,
    required this.onActivityReturned,
    this.hero = false,
  });

  final ActivityCatalogEntry entry;
  final SoriActivityProgress? progress;
  final Future<SoriStageProgressionSnapshot> Function() loadSnapshot;
  final VoidCallback onActivityReturned;

  /// §C-1-11: Learn 탭 상단 대형 진입 카드 — 와이드 배너 비율 + 비고정 높이.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final title = localCopy(context, entry.title);
    final locked = isActivityLocked(entry, progress);
    final state =
        progress?.state ??
        (locked ? SoriActivityState.locked : SoriActivityState.ready);
    final unlocked = !locked;

    // §C-3c P1-④: 리시트 캡처 플로우를 한 곳으로 — onTap/시트 양쪽이 사용.
    Future<void> start() async {
      // §E4: "이어하기" 히어로의 원천 — 실제로 연 활동만 기록한다(시트만
      // 열어본 것은 기록하지 않는다). 저장은 내비게이션을 지연시키지 않는다.
      unawaited(Storage.setLastActivityId(entry.id));
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: entry.id,
        loadSnapshot: loadSnapshot,
        openActivity: () async {
          await Navigator.of(
            context,
          ).pushNamed(entry.route, arguments: entry.arguments);
        },
      );
      if (!context.mounted || receipt == null) {
        if (context.mounted) {
          onActivityReturned();
        }
        return;
      }
      onActivityReturned();
      await showSoriStageRewardReceipt(context, receipt);
    }

    // §C-2: 잠긴 카드 탭=시트(잠금 설명), 일반 카드 롱프레스=시트(설명+보상).
    void openSheet() => showSoriActivitySheet(
      context,
      entry: entry,
      progress: progress,
      onStart: start,
    );

    return SoriIllustratedCard(
      title: title,
      // §E2: 알약 제거 — 분(分) 표기는 이미지 우하단 미니 필 대신 타이틀
      // 아래 메타 라인(cardSubtitle)으로. 분이 없으면(0 이하) 생략한다 —
      // 카탈로그 엔트리는 항상 양수 분을 갖지만 방어적으로 둔다.
      subtitle: entry.minutes > 0 ? t.soriStageMinutes(entry.minutes) : null,
      state: unlocked
          ? SoriIllustratedCardState.normal
          : SoriIllustratedCardState.locked,
      shrinkWrap: hero,
      // §P4-1: 그리드 이미지 슬롯을 원본(800×600)과 같은 4:3 으로 — 크롭 0,
      // "거대 아이콘" 체감 ~17% 축소. 히어로 카드는 와이드 배너 유지.
      imageAspectRatio: hero ? 21 / 9 : 4 / 3,
      illustrationAsset: activityIllustrationAsset(entry.id),
      fallback: ActivityIconFallback(
        iconName: entry.iconName,
        colorRole: entry.colorRole,
      ),
      // §E2: 상태 3종(신규/진행/완료)은 항상 렌더 — locked 는 잠금 설명을 표시.
      footer: _StateLabel(state: state, progress: progress, entry: entry),
      onTap: unlocked ? start : openSheet,
      onLongPress: unlocked ? openSheet : null,
      semanticsLabel: unlocked
          ? t.soriStageOpenActivity(title)
          : t.soriStageActivityDetails(title),
    );
  }
}

/// 카드 footer: 상태 라벨 (텍스트만, 간결).
///
/// §E2: 3상태(신규/진행/완료)는 항상 렌더한다 — 잠금 0 상태에서 전 카드
/// 동일한 "Jetzt verfügbar" ×N 노이즈였던 이전 규칙(ready+무진행이면 footer
/// 생략)을 없앴다: ready 는 이제 "Neu" 로 표시해 그 자체로 신호가 된다.
/// locked 는 4번째(별도) 상태로 잠금 설명을 계속 보여준다.
/// §LAYOUT-2(J12): the single source of the *base* state-label text — both
/// `_StateLabel` (render) and the footer-height measurement in
/// `_cellAspectRatio` call this so the two can never name a different string
/// for the same state.
String activityStateLabel(
  BuildContext context,
  AppL10n t,
  SoriActivityState state,
  ActivityCatalogEntry entry,
) => switch (state) {
  SoriActivityState.ready => t.soriStageActivityNew,
  SoriActivityState.inProgress => t.soriStageActivityInProgress,
  SoriActivityState.completed => t.soriStageActivityCompleted,
  SoriActivityState.locked => localCopy(context, entry.unlock.explanation!),
};

/// §LAYOUT-2(J12): the single source of the *rendered* state-label string —
/// `label` plus the numeric progress suffix (` · current` / ` · current /
/// target`). `_StateLabel` calls this to render, and `_cellAspectRatio`'s
/// footer-height measurement calls it with the same arguments to measure —
/// "measured == rendered" is enforced by sharing this function rather than
/// by two hand-kept-in-sync string templates.
String activityStateText(String label, int? current, int? target) {
  final suffix = current == null || current <= 0
      ? ''
      : target == null
      ? ' · $current'
      : ' · $current / $target';
  return '$label$suffix';
}

class _StateLabel extends StatelessWidget {
  const _StateLabel({
    required this.state,
    required this.progress,
    required this.entry,
  });

  final SoriActivityState state;
  final SoriActivityProgress? progress;
  final ActivityCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);

    final label = activityStateLabel(context, t, state, entry);

    // §E2: 점 색은 상태별로 분리한다 — 신규는 무채색, 진행은 활동 컬러,
    // 완료는 브랜드 primary. locked 는 기존과 동일(muted @0.4).
    final dotColor = switch (state) {
      SoriActivityState.locked => s.textMuted.withValues(alpha: 0.4),
      SoriActivityState.ready => s.textMuted,
      SoriActivityState.inProgress => soriActivityColor(entry.colorRole),
      SoriActivityState.completed => SoriColors.primary,
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Text(
            activityStateText(label, progress?.current, progress?.target),
            // §C-1-9: raw TextStyle → 토큰. "작아서 예외"는 없다.
            style: tt.cardSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: s.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
