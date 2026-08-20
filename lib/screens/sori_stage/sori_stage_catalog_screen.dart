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
    this.active = true,
  });

  final SoriStageTab tab;
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final bool active;

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
    final heroId = isGames ? 'daily_game' : 'vocab_packs';
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
    final gridTitles = gridEntries.map(
      (entry) => localCopy(context, entry.title),
    );
    final footerLabels = <String>[
      t.soriStageActivityReady,
      t.soriStageActivityInProgress,
      t.soriStageActivityCompleted,
      for (final entry in gridEntries)
        if (entry.unlock.explanation case final explanation?)
          localCopy(context, explanation),
    ];
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
                final baseColumns = soriGridColumns(
                  available,
                  target: 160,
                  min: 2,
                  outerPadding: 0,
                  spacing: Spacing.md,
                );
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns =
                    textScale >= 1.6 && available < SoriBreakpoints.grid
                    ? 1
                    : baseColumns;
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
                      builder: (context, snapshot) {
                        final ready =
                            snapshot.connectionState == ConnectionState.done &&
                            !snapshot.hasError;
                        final activityProgress = ready
                            ? snapshot.data?.activityProgress
                            : null;
                        return SliverMainAxisGroup(
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
                                    progress: activityProgress?[hero.id],
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
                                        titles: gridTitles,
                                        footerLabels: footerLabels,
                                      ),
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final entry = gridEntries[index];
                                  return _ActivityGridCard(
                                    entry: entry,
                                    progress: activityProgress?[entry.id],
                                    loadSnapshot:
                                        widget.loadSnapshot ??
                                        SoriStageProgressionService.load,
                                    onActivityReturned: _reload,
                                  );
                                }, childCount: gridEntries.length),
                              ),
                            ),
                          ],
                        );
                      },
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

    // §P4-2: 상태 신호는 모델의 4값뿐 — 잠금 0 상태에서 전 카드 동일한
    // "Jetzt verfügbar" ×N 은 노이즈다. ready + 무진행이면 footer 를 없앤다
    // (locked/inProgress/completed 는 표시). ARB soriStageActivityReady 키는
    // 삭제하지 않는다.
    final bool silentReady =
        state == SoriActivityState.ready &&
        (progress?.current == null || (progress?.current ?? 0) <= 0);

    return SoriIllustratedCard(
      title: title,
      // §P4-3: 분(分) 표기는 subtitle → 이미지 우하단 미니 필로 이동.
      subtitle: null,
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
      imageOverlay: _MinutesPill(label: t.soriStageMinutes(entry.minutes)),
      footer: silentReady
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

/// Grid ratio derived from the 4:3 image plus the measured localized title and
/// status footer. Every string remains available while cards in a row keep the
/// same height.
double _cellAspectRatio(
  BuildContext context,
  double cellWidth, {
  required Iterable<String> titles,
  required Iterable<String> footerLabels,
}) {
  if (!cellWidth.isFinite || cellWidth <= 0) {
    return 0.78;
  }
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final locale = Localizations.localeOf(context);
  final tt = SoriTextTheme.of(context);
  final titleStyle = tt.cardTitle;
  final footerStyle = tt.cardSubtitle;
  const double bodyPadding = Spacing.sm + Spacing.md;
  final bodyWidth = (cellWidth - Spacing.md * 2).clamp(1.0, double.infinity);
  final title = _maxMeasuredTextHeight(
    texts: titles,
    style: titleStyle,
    maxWidth: bodyWidth,
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  final footer = _maxMeasuredTextHeight(
    texts: footerLabels,
    style: footerStyle,
    maxWidth: (bodyWidth - 14).clamp(1.0, double.infinity),
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  // Two physical border pixels plus a small rounding allowance keep the
  // fixed-height grid honest at tablet comfort scale and 200% OS text.
  const double layoutAllowance = 4;
  final double height =
      cellWidth / (4 / 3) +
      bodyPadding +
      title +
      Spacing.xs +
      footer +
      layoutAllowance;
  return cellWidth / height;
}

double _maxMeasuredTextHeight({
  required Iterable<String> texts,
  required TextStyle style,
  required double maxWidth,
  required TextScaler scaler,
  required TextDirection direction,
  required Locale locale,
}) {
  var height = scaler.scale(style.fontSize ?? 14) * (style.height ?? 1);
  for (final text in texts) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
    )..layout(maxWidth: maxWidth);
    height = height < painter.height ? painter.height : height;
    painter.dispose();
  }
  return height;
}

/// §P4-3: 이미지 슬롯 우하단 분(分) 미니 필.
class _MinutesPill extends StatelessWidget {
  const _MinutesPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        // ⚠️ withOpacity 는 deprecated — 저장소는 전부 .withValues 이관 완료.
        color: Color(0x8C000000), // black @0.55
        borderRadius: SoriRadius.brPill,
      ),
      child: Text(label, style: tt.caption.copyWith(color: Colors.white)),
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
