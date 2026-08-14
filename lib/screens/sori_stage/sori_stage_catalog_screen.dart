import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/activity_sheet.dart';
import '../../widgets/sori/illustrated_card.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';

class SoriStageCatalogScreen extends StatefulWidget {
  const SoriStageCatalogScreen({
    super.key,
    required this.tab,
    this.loadSnapshot,
  });

  final SoriStageTab tab;
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  @override
  State<SoriStageCatalogScreen> createState() => _SoriStageCatalogScreenState();
}

class _SoriStageCatalogScreenState extends State<SoriStageCatalogScreen> {
  late Future<SoriStageProgressionSnapshot> _progress;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
    _progress = _load();
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

    // §C-1-11: 각 탭의 핵심 진입점을 그리드 타일이 아니라 **대형 진입
    // 카드**로 승격한다 — 그리드에서는 빼서 중복을 피한다. Learn 은
    // 단어팩, Games 는 오늘의 게임이 그 자리다(탭 간 대칭).
    final String heroId = isGames ? 'daily_game' : 'vocab_packs';
    ActivityCatalogEntry? heroEntry;
    for (final entry in entries) {
      if (entry.id == heroId) {
        heroEntry = entry;
        break;
      }
    }
    final gridEntries = heroEntry == null
        ? entries
        : entries.where((entry) => entry.id != heroEntry!.id).toList();
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 880,
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) => LayoutBuilder(
              builder: (context, constraints) {
                // §C-1-4: 패딩 뺀 실제 가용폭으로 컬럼 산출 —
                // discover_screen.dart:349 패턴. 기존은 클램프 전 전체 폭이
                // 들어가 1280dp에서 880px 안에 6열 → 18px 오버플로.
                final double available =
                    constraints.maxWidth - padding.horizontal;
                final columns = soriGridColumns(
                  available,
                  target: 160,
                  min: 2,
                  outerPadding: 0,
                  spacing: Spacing.md,
                );
                final double cellWidth =
                    (available - Spacing.md * (columns - 1)) / columns;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: padding,
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SoriStageRootHeader(
                              eyebrow: isGames
                                  ? t.soriStageNavGames
                                  : t.soriStageNavLearn,
                              title: isGames
                                  ? t.soriStageGamesTitle
                                  : t.soriStageLearnTitle,
                              body: isGames
                                  ? t.soriStageGamesBody
                                  : t.soriStageLearnBody,
                            ),
                            const SizedBox(height: Spacing.xl),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<SoriStageProgressionSnapshot>(
                      future: _progress,
                      builder: (context, snapshot) => SliverMainAxisGroup(
                        slivers: [
                          if (heroEntry case final hero?)
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: padding.left,
                                right: padding.right,
                                bottom: Spacing.md,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _ActivityGridCard(
                                  entry: hero,
                                  hero: true,
                                  progress:
                                      snapshot.data?.activityProgress[hero.id],
                                  loadSnapshot:
                                      widget.loadSnapshot ??
                                      SoriStageProgressionService.load,
                                  onActivityReturned: _reload,
                                ),
                              ),
                            ),
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: padding.left,
                              right: padding.right,
                              bottom: padding.bottom,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: Spacing.md,
                                    crossAxisSpacing: Spacing.md,
                                    childAspectRatio: _cellAspectRatio(
                                      context,
                                      cellWidth,
                                    ),
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final entry = gridEntries[index];
                                return _ActivityGridCard(
                                  entry: entry,
                                  progress:
                                      snapshot.data?.activityProgress[entry.id],
                                  loadSnapshot:
                                      widget.loadSnapshot ??
                                      SoriStageProgressionService.load,
                                  onActivityReturned: _reload,
                                );
                              }, childCount: gridEntries.length),
                            ),
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

    // 상태 신호가 "지금 바로 할 수 있음" 하나뿐이면 footer 를 접는다 —
    // 전 카드가 똑같이 "Jetzt verfügbar" 를 다는 건 정보가 아니라 노이즈다.
    // (잠금·진행 중·완료는 카드마다 다르므로 계속 표시한다.)
    final bool footerIsNoise =
        state == SoriActivityState.ready &&
        (progress?.current == null || progress!.current! <= 0);

    return SoriIllustratedCard(
      title: title,
      state: unlocked
          ? SoriIllustratedCardState.normal
          : SoriIllustratedCardState.locked,
      shrinkWrap: hero,
      // 활동 아트는 800×600(4:3)이다. 16:10 슬롯은 높이의 16.7% 를 잘라내
      // 중앙 오브젝트를 더 확대했다 — "거대 아이콘 벽"의 절반은 이 크롭이
      // 원인이었다. 원본 비율로 되돌리면 크롭 0, 체감 크기 ~17% 감소.
      imageAspectRatio: hero ? 21 / 9 : 4 / 3,
      illustrationAsset: activityIllustrationAsset(entry.id),
      fallback: ActivityIconFallback(
        iconName: entry.iconName,
        colorRole: entry.colorRole,
      ),
      // 소요 시간은 제목 아래 한 줄을 통째로 먹을 만큼 중요하지 않다 →
      // 이미지 우하단 미니 필로 내린다.
      imageOverlay: _MinutesPill(label: t.soriStageMinutes(entry.minutes)),
      footer: footerIsNoise
          ? null
          : _StateLabel(state: state, progress: progress, entry: entry),
      onTap: unlocked ? start : openSheet,
      onLongPress: unlocked ? openSheet : null,
      semanticsLabel: unlocked
          ? t.soriStageOpenActivity(title)
          : t.soriStageActivityDetails(title),
    );
  }
}

/// 그리드 셀의 가로:세로 비.
///
/// 고정 상수(예전 0.78)로는 못 맞춘다 — 셀 높이는 **이미지(폭 비례) + 본문
/// (글자 크기 비례)** 이라 좁은 셀일수록 본문 비중이 커지고, 시스템 글자
/// 확대에서는 본문만 커진다. 그래서 실측 합에서 도출한다:
///
///   이미지 = cellWidth ÷ (4/3)                        (활동 아트 원본 비율)
///   본문   = 패딩 sm(8)+md(16)
///          + 제목 cardTitle 15sp × height 1.3 × 2줄
///          + footer 간격 xs(4) + cardSubtitle 13sp × height 1.3
///
/// (`illustrated_card.dart` 의 body 구성과 `SoriTextTheme` 값에서 온 숫자다.
/// 그쪽을 바꾸면 여기도 같이 바꾼다.) footer 는 상태에 따라 접히지만 **있을
/// 때를 기준**으로 잡아야 한 그리드 안에서 카드 높이가 들쭉날쭉하지 않는다.
double _cellAspectRatio(BuildContext context, double cellWidth) {
  if (!cellWidth.isFinite || cellWidth <= 0) {
    return 0.78;
  }
  final scaler = MediaQuery.textScalerOf(context);
  const double padding = Spacing.sm + Spacing.md;
  final double title = scaler.scale(15) * 1.3 * 2;
  final double footer = Spacing.xs + scaler.scale(13) * 1.3;
  final double height = cellWidth / (4 / 3) + padding + title + footer;
  return cellWidth / height;
}

/// 이미지 우하단의 소요 시간 필.
class _MinutesPill extends StatelessWidget {
  const _MinutesPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        // ⚠️ withOpacity 는 deprecated — 저장소는 .withValues 로 이관 완료.
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: SoriRadius.brPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, style: tt.caption.copyWith(color: Colors.white)),
      ),
    );
  }
}

/// 카드 footer: 상태 라벨 (텍스트만, 간결).
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
    final color = soriActivityColor(entry.colorRole);

    final label = switch (state) {
      SoriActivityState.ready => t.soriStageActivityReady,
      SoriActivityState.inProgress => t.soriStageActivityInProgress,
      SoriActivityState.completed => t.soriStageActivityCompleted,
      SoriActivityState.locked => localCopy(context, entry.unlock.explanation!),
    };

    final current = progress?.current;
    final target = progress?.target;
    final suffix = current == null || current <= 0
        ? ''
        : target == null
        ? ' · $current'
        : ' · $current / $target';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: state == SoriActivityState.locked
                ? s.textMuted.withValues(alpha: 0.4)
                : color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label$suffix',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
