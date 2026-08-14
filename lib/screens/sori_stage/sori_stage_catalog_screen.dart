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

    // §C-1-11: Learn 탭은 단어팩(핵심 학습 경로)을 그리드 타일이 아니라
    // **대형 진입 카드**로 승격한다 — 그리드에서는 빼서 중복을 피한다.
    ActivityCatalogEntry? heroEntry;
    if (!isGames) {
      for (final entry in entries) {
        if (entry.id == 'vocab_packs') {
          heroEntry = entry;
          break;
        }
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
                final columns = soriGridColumns(
                  constraints.maxWidth - padding.horizontal,
                  target: 160,
                  min: 2,
                  outerPadding: 0,
                  spacing: Spacing.md,
                );
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
                                    childAspectRatio: 0.78,
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

    return SoriIllustratedCard(
      title: title,
      subtitle: t.soriStageMinutes(entry.minutes),
      state: unlocked
          ? SoriIllustratedCardState.normal
          : SoriIllustratedCardState.locked,
      shrinkWrap: hero,
      imageAspectRatio: hero ? 21 / 9 : 16 / 10,
      illustrationAsset: activityIllustrationAsset(entry.id),
      fallback: ActivityIconFallback(
        iconName: entry.iconName,
        colorRole: entry.colorRole,
      ),
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
