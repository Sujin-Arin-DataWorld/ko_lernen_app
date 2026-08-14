import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/learner_motivation.dart';
import '../../data/quest_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/quest.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/pack_access.dart';
import '../../services/palette_service.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_navigation.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/character_clip.dart';
import '../../widgets/sori/home_hero.dart';
import '../../widgets/sori/mascot_preference.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/section_header.dart';
import '../../widgets/sori/spotlight_coach.dart';
import '../../widgets/sori/stats_top_bar.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/week_sheet.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';

/// **SoriStage Today** — 마스코트 히어로가 이끄는 오늘 화면.
///
/// 2026-08-14 Phase 2b: 2026-08-13 롤백의 유일한 결함("텍스트-우선 홈이
/// 마스코트 주도 진입을 잃었다")을 수리 — 홈의 [SoriStatsTopBar] +
/// [SoriCharacterHero] 를 이식하고, 텍스트 RootHeader 는 이 탭에서 제거했다
/// (인사말이 곧 헤더다).
///
/// ⚠️ **배경 계약 (홈과 동일)**: 라이트 = [HomeHeroClips.matte] 평면 단색.
/// 히어로 클립이 한지색 매트를 미리 합성한 불투명 mp4 라, 배경이 이 값이
/// 아니거나 균일하지 않으면 영상 사각형이 액자처럼 뜬다 (2026-08-12 실측,
/// 상세는 home_hero.dart 와 홈 build 주석). 그라데이션·한지 그레인 금지.
class SoriStageTodayScreen extends StatefulWidget {
  const SoriStageTodayScreen({
    super.key,
    this.loadSnapshot,
    this.replayHomeTour,
    this.now,
  });

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final ValueListenable<int>? replayHomeTour;

  /// 테스트/골든용 시계 주입 — 인사말(시간대)이 실제 시각에 묶이지 않게.
  final DateTime Function()? now;

  @override
  State<SoriStageTodayScreen> createState() => _SoriStageTodayScreenState();
}

class _SoriStageTodayScreenState extends State<SoriStageTodayScreen> {
  late Future<SoriStageProgressionSnapshot> _future;
  final GlobalKey _missionTourKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
    widget.replayHomeTour?.addListener(_onReplayRequested);
    _future
        .then<void>((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.replayHomeTour != null &&
                mounted &&
                !Storage.tutHomeTourSeen) {
              _startHomeTour();
            }
          });
        })
        .onError((_, _) {});
  }

  @override
  void didUpdateWidget(covariant SoriStageTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayHomeTour != widget.replayHomeTour) {
      oldWidget.replayHomeTour?.removeListener(_onReplayRequested);
      widget.replayHomeTour?.addListener(_onReplayRequested);
    }
  }

  @override
  void dispose() {
    widget.replayHomeTour?.removeListener(_onReplayRequested);
    super.dispose();
  }

  void _onReplayRequested() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _missionTourKey.currentContext != null) {
        _startHomeTour();
      }
    });
  }

  void _startHomeTour() {
    final t = AppL10n.of(context);
    SpotlightCoach.show(
      context,
      steps: [
        SpotlightStep(
          targetKey: _missionTourKey,
          title: t.coachHomeMissionTitle,
          body: t.coachHomeMissionBody,
          icon: Icons.play_circle_outline,
          cutoutPadding: const EdgeInsets.all(6),
          cutoutRadius: SoriRadius.xl,
        ),
      ],
      onComplete: () => Storage.setTutHomeTourSeen(),
    );
  }

  void _reload() => setState(() {
    _future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
  });

  Future<void> _showWeekSheet() async {
    await showSoriWeekSheet(context);
    if (mounted) {
      setState(() {}); // 시트에서 돌아온 뒤 스트릭/XP 칩 최신화.
    }
  }

  SoriDayPhase get _phase =>
      soriDayPhaseFor(widget.now?.call() ?? DateTime.now());

  /// 헤더 + 히어로 블록.
  ///
  /// `verticalDirection: up` = **배치는 그대로, paint 순서만 역전** — 히어로
  /// 영상 텍스처가 자기보다 먼저 그려진 형제(로고·칩·인사말)를 지우는 Android
  /// 컴포지터 문제의 구조적 차단. 홈 build 의 동일 주석 참조. 시각 결과는
  /// [톱바 → 인사 → 말풍선 → 밴드] 그대로다.
  Widget _header(BuildContext context, AppL10n t) {
    final topBar = SoriStatsTopBar(
      streak: Storage.streakDays,
      level: Storage.xpLevel,
      xp: Storage.xp,
      onStreakTap: () {
        // ignore: discarded_futures
        _showWeekSheet();
      },
      onStatsTap: () => Navigator.pushNamed(context, '/stats'),
      onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      profileTooltip: t.soriStageProfileTooltip,
    );

    final hero = ValueListenableBuilder<CompanionPreference>(
      valueListenable: MascotPreference.preference,
      builder: (context, preference, _) {
        final kind = MascotPreference.mascotKindFor(preference);
        if (kind == null) {
          return const SizedBox.shrink(
            key: ValueKey('sori-today-companion-hidden'),
          );
        }
        return SoriCharacterHero(
          greeting: soriHeroGreeting(t, _phase),
          bubble: homeTigerBubble(
            t,
            streak: Storage.streakDays,
            xp: Storage.xp,
            motivation: learnerMotivationFromId(Storage.motivation),
            kind: kind,
          ),
          phase: _phase,
          kind: kind,
          // teal kill-switch: 흰 배경 위 한지 매트 클립은 액자가 된다 →
          // 다크와 같은 정적 마스코트 경로로.
          forceStatic: paletteVariantNotifier.value == PaletteVariant.teal,
        );
      },
    );

    return Column(
      verticalDirection: VerticalDirection.up,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [hero, topBar],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // 배경 계약: 클래스 doc-comment 참조. 라이트 = 매트 평면 단색.
          Positioned.fill(
            child: ColoredBox(
              key: const ValueKey('sori-today-bg'),
              color: isDark ? s.bg : HomeHeroClips.matte,
            ),
          ),
          SafeArea(
            child: FutureBuilder<SoriStageProgressionSnapshot>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _TodayContent(
                    snapshot: snapshot.requireData,
                    onRefresh: _reload,
                    missionTourKey: _missionTourKey,
                    header: _header(context, t),
                  );
                }
                // 로딩/오류에도 헤더(톱바+히어로)는 즉시 보인다 — 홈과 같은
                // "캐릭터가 먼저 맞이하는" 진입이자, 셸 테스트의 Profile 툴팁
                // 계약(스냅샷 로드와 무관)이기도 하다. ListView 인 이유:
                // 낮은 높이(가로 폰·분할 화면 360dp)에서 헤더+스피너가 화면을
                // 넘칠 수 있어 스크롤로 받는다.
                final bool waiting =
                    snapshot.connectionState == ConnectionState.waiting;
                return SoriContentClamp(
                  maxWidth: 880,
                  base: Spacing.page,
                  builder: (context, padding) => ListView(
                    padding: padding,
                    children: [
                      _header(context, t),
                      const SizedBox(height: Spacing.xxl),
                      if (waiting)
                        const AppLoading()
                      else
                        _TodayError(onRetry: _reload),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.snapshot,
    required this.onRefresh,
    required this.missionTourKey,
    required this.header,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onRefresh;
  final GlobalKey missionTourKey;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriContentClamp(
      maxWidth: 880,
      base: Spacing.page,
      builder: (context, padding) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            header,
            const SizedBox(height: Spacing.sm),
            _TodayMissionStage(
              key: missionTourKey,
              snapshot: snapshot,
              onActivityReturned: onRefresh,
            ),
            if (snapshot.pendingBojagiCount > 0) ...[
              const SizedBox(height: Spacing.lg),
              _PendingBojagi(count: snapshot.pendingBojagiCount),
            ],
            const SizedBox(height: Spacing.xl),
            _HanokProgress(snapshot: snapshot),
            if (snapshot.closestQuests.isNotEmpty) ...[
              const SizedBox(height: Spacing.xl),
              // §D: 섹션 제목은 SoriSectionHeader(골드 hairline) 규격 —
              // 자체 하단 여백(Spacing.sm)을 갖는다.
              SoriSectionHeader(t.soriStageClosestQuests),
              for (final quest in snapshot.closestQuests)
                _QuestProgressRow(progress: quest),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayMissionStage extends StatelessWidget {
  const _TodayMissionStage({
    super.key,
    required this.snapshot,
    required this.onActivityReturned,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onActivityReturned;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final destination = snapshot.today.destination;
    final contract = snapshot.todayReward;
    final rewardText =
        contract?.items
            .map((item) => localCopy(context, item.label))
            .join(' · ') ??
        '';
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: SoriActivityColors.hanokStage,
        borderRadius: BorderRadius.circular(SoriRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.soriStageBrandLabel,
            // §D: eyebrow 토큰 — 짙은 한옥 스테이지 위라 석간주 대신 골드.
            style: tt.eyebrow.copyWith(color: SoriColors.gold),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            destination == null
                ? t.soriStageTodayEmpty
                : t.soriStageMissionAction,
            // §D: 카드 내부 헤드라인은 h1 상한 — hero(38)는 페이지 헤더 전용.
            style: tt.h1.copyWith(color: Colors.white),
          ),
          if (rewardText.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.roofing_rounded, color: SoriColors.gold),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    '${t.soriStagePossibleReward}: $rewardText',
                    style: tt.label.copyWith(
                      color: SoriActivityColors.onHanokStage,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.xl),
          SoriButton(
            label: t.soriStageMissionAction,
            onTap: () async {
              final activityId =
                  contract?.activityId ?? destination?.route ?? 'today';
              final receipt = await SoriStageRewardReceiptService.capture(
                activityId: activityId,
                loadSnapshot: SoriStageProgressionService.load,
                openActivity: () async {
                  if (destination == null) {
                    await Navigator.of(context).pushNamed('/path');
                    return;
                  }
                  await TodayLearningNavigation.open(
                    destination,
                    ensurePackAccess: (level) =>
                        ensurePackAccess(context, level: level),
                    openRoute: (route, arguments) async {
                      await Navigator.of(
                        context,
                      ).pushNamed(route, arguments: arguments);
                    },
                  );
                },
              );
              if (!context.mounted) {
                return;
              }
              onActivityReturned();
              if (receipt != null) {
                await showSoriStageRewardReceipt(context, receipt);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PendingBojagi extends StatelessWidget {
  const _PendingBojagi({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/bojagi'),
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: SoriColors.gold.withValues(alpha: .18),
          border: Border.all(color: SoriColors.gold),
          borderRadius: BorderRadius.circular(SoriRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.redeem_rounded,
              size: 36,
              color: SoriColors.goldOnLight,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.soriStageBojagiTitle} · $count', style: tt.h3),
                  Text(t.soriStageBojagiBody, style: tt.bodySmall),
                ],
              ),
            ),
            Text(t.soriStageOpenBojagi, style: tt.label),
          ],
        ),
      ),
    );
  }
}

class _HanokProgress extends StatelessWidget {
  const _HanokProgress({required this.snapshot});
  final SoriStageProgressionSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final built = snapshot.hanok.unlocked.length;
    const total = 7;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/hanok'),
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: SoriColors.primarySoft,
          borderRadius: BorderRadius.circular(SoriRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 34,
                  color: SoriColors.primaryDark,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(child: Text(t.soriStageHanokNow, style: tt.h3)),
                Text(
                  '$built / $total',
                  // §D: 진행 수치는 tabular — 조각이 늘어도 자리 흔들림 없음.
                  style: tt.h3.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            LinearProgressIndicator(
              value: snapshot.hanok.constructionFraction,
              minHeight: 12,
              borderRadius: BorderRadius.circular(SoriRadius.sm),
              color: SoriColors.primaryDark,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '${t.soriStageNextPiece}: ${snapshot.hanok.structureStage.name}',
              style: tt.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({required this.progress});
  final QuestProgress progress;
  @override
  Widget build(BuildContext context) {
    final definition = kQuestCatalog.firstWhere(
      (quest) => quest.id == progress.questId,
    );
    final language = Localizations.localeOf(context).languageCode;
    final tt = SoriTextTheme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: Spacing.sm,
      title: Text(
        language == 'de' ? definition.name.de : definition.name.en,
        style: tt.cardTitle,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LinearProgressIndicator(
          value: progress.fraction,
          minHeight: 8,
          borderRadius: BorderRadius.circular(SoriRadius.xs),
        ),
      ),
      trailing: Text(
        '${progress.current} / ${progress.target}',
        style: tt.label.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: () => Navigator.of(context).pushNamed('/quests'),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: Spacing.md),
          Text(
            AppL10n.of(context).soriStageTodayEmpty,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(
            label: AppL10n.of(context).btnRetry,
            onTap: onRetry,
          ),
        ],
      ),
    ),
  );
}
