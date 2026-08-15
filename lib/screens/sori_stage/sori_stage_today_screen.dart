import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/learner_motivation.dart';
import '../../data/milestone.dart';
import '../../data/quest_catalog.dart';
import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/feedback_completion.dart';
import '../../models/quest.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/decoration_reward_service.dart';
import '../../services/pack_access.dart';
import '../../services/palette_service.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../services/today_learning_navigation.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/character_clip.dart';
import '../../widgets/sori/hanok_stage_names.dart';
import '../../widgets/sori/home_hero.dart';
import '../../widgets/sori/mascot_preference.dart';
import '../../widgets/sori/milestone_celebration.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_icon.dart';
import '../../widgets/sori/reward_thumb.dart';
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
    this.onHomeTourStarted,
    this.enableMilestoneCelebrations,
    this.active = true,
    this.forceStaticHero = false,
  });

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final ValueListenable<int>? replayHomeTour;

  /// 테스트/골든용 시계 주입 — 인사말(시간대)이 실제 시각에 묶이지 않게.
  final DateTime Function()? now;

  /// Test seam for availability-sensitive home-tour admission.
  final VoidCallback? onHomeTourStarted;

  /// Defaults to production-only (`loadSnapshot == null`) so preview and
  /// golden fixtures remain read-only. Milestone ownership tests can opt in.
  final bool? enableMilestoneCelebrations;

  /// The shell keeps Today mounted in an IndexedStack. Presentation side
  /// effects (tour and milestone sheet) are admitted only while this tab is
  /// visible.
  final bool active;

  /// Keeps the mascot frame deterministic in pixel tests.
  final bool forceStaticHero;

  @override
  State<SoriStageTodayScreen> createState() => _SoriStageTodayScreenState();
}

class _SoriStageTodayScreenState extends State<SoriStageTodayScreen> {
  late Future<SoriStageProgressionSnapshot> _future;
  final GlobalKey _missionTourKey = GlobalKey();
  int _snapshotGeneration = 0;
  bool? _todayUnavailable;
  bool _homeTourScheduled = false;
  bool _celebrating = false;
  bool _milestoneHandledThisVisit = false;
  int _presentationGeneration = 0;

  bool get _milestoneCelebrationsEnabled =>
      widget.enableMilestoneCelebrations ?? widget.loadSnapshot == null;

  @override
  void initState() {
    super.initState();
    _future = _loadSnapshot(startHomeTourWhenReady: true);
    widget.replayHomeTour?.addListener(_onReplayRequested);
  }

  @override
  void didUpdateWidget(covariant SoriStageTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayHomeTour != widget.replayHomeTour) {
      oldWidget.replayHomeTour?.removeListener(_onReplayRequested);
      widget.replayHomeTour?.addListener(_onReplayRequested);
    }
    final becameActive = !oldWidget.active && widget.active;
    final loaderChanged = oldWidget.loadSnapshot != widget.loadSnapshot;
    if (oldWidget.active != widget.active) {
      _presentationGeneration++;
    }
    if (widget.active && (becameActive || loaderChanged)) {
      // Re-entering Today is also its freshness boundary. This both avoids a
      // hidden-tab presentation and reflects rewards/progress earned elsewhere.
      _todayUnavailable = null;
      _future = _loadSnapshot(startHomeTourWhenReady: true);
    }
  }

  @override
  void dispose() {
    widget.replayHomeTour?.removeListener(_onReplayRequested);
    super.dispose();
  }

  void _onReplayRequested() {
    if (!widget.active) {
      return;
    }
    // Await the active snapshot rather than trusting a stale availability
    // flag. This covers replay requests while Today is still loading and
    // prevents an unavailable mission card from ever receiving the tour.
    final activeFuture = _future;
    activeFuture
        .then<void>((snapshot) {
          if (!mounted ||
              !identical(activeFuture, _future) ||
              snapshot.today.isUnavailable) {
            return;
          }
          _todayUnavailable = false;
          _scheduleHomeTour();
        })
        .onError((_, _) {});
  }

  Future<SoriStageProgressionSnapshot> _loadSnapshot({
    bool startHomeTourWhenReady = false,
    bool checkMilestones = true,
  }) {
    final generation = ++_snapshotGeneration;
    final future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
    future
        .then<void>((snapshot) {
          if (!mounted || generation != _snapshotGeneration) {
            return;
          }
          _todayUnavailable = snapshot.today.isUnavailable;
          if (startHomeTourWhenReady &&
              widget.active &&
              widget.replayHomeTour != null &&
              !snapshot.today.isUnavailable &&
              !Storage.tutHomeTourSeen) {
            _scheduleHomeTour(requireUnseen: true);
          }
          if (widget.active &&
              checkMilestones &&
              !snapshot.today.isUnavailable &&
              _milestoneCelebrationsEnabled &&
              !_milestoneHandledThisVisit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_canPresent(generation: generation)) {
                // ignore: discarded_futures
                _maybeCelebrateMilestone(generation: generation);
              }
            });
            WidgetsBinding.instance.scheduleFrame();
          }
        })
        .onError((_, _) {
          if (mounted && generation == _snapshotGeneration) {
            _todayUnavailable = null;
          }
        });
    return future;
  }

  void _scheduleHomeTour({bool requireUnseen = false}) {
    if (!widget.active || _homeTourScheduled || _todayUnavailable != false) {
      return;
    }

    // A replay normally arrives after Today has built, so starting directly
    // avoids depending on an unrelated future frame. Initial loading has no
    // target context yet and falls through to the post-frame path below.
    if (_missionTourKey.currentContext != null) {
      _startHomeTourIfAdmitted(requireUnseen: requireUnseen);
      return;
    }

    _homeTourScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeTourScheduled = false;
      _startHomeTourIfAdmitted(requireUnseen: requireUnseen);
    });
    // The snapshot callback can run after the current frame has completed.
    // Request one explicitly so the admission check does not wait for a
    // later, unrelated rebuild.
    WidgetsBinding.instance.scheduleFrame();
  }

  void _startHomeTourIfAdmitted({required bool requireUnseen}) {
    if (!mounted ||
        !widget.active ||
        _todayUnavailable != false ||
        _missionTourKey.currentContext == null ||
        (requireUnseen && Storage.tutHomeTourSeen)) {
      return;
    }
    _startHomeTour();
  }

  void _startHomeTour() {
    widget.onHomeTourStarted?.call();
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

  void _reload({bool checkMilestones = true}) => setState(() {
    _todayUnavailable = null;
    _future = _loadSnapshot(checkMilestones: checkMilestones);
  });

  bool _canPresent({required int generation, int? presentationGeneration}) =>
      mounted &&
      widget.active &&
      generation == _snapshotGeneration &&
      (presentationGeneration == null ||
          presentationGeneration == _presentationGeneration);

  /// Sori Stage Today owns milestone presentation after the legacy Home
  /// surface was removed. Only the highest-priority newly reached milestone
  /// is shown per visit; reward creation remains source-idempotent.
  Future<void> _maybeCelebrateMilestone({required int generation}) async {
    if (!_canPresent(generation: generation) ||
        _celebrating ||
        _milestoneHandledThisVisit ||
        !Storage.tutHomeTourSeen ||
        _todayUnavailable != false) {
      return;
    }
    final newly = newlyReachedMilestones(
      streak: Storage.streakDays,
      level: Storage.xpLevel,
      vocab: Storage.vokSeenIds.length,
      celebrated: Storage.celebratedMilestones.toSet(),
    );
    if (newly.isEmpty) {
      return;
    }
    const priority = <MilestoneType, int>{
      MilestoneType.streak: 3,
      MilestoneType.level: 2,
      MilestoneType.vocab: 1,
    };
    final top = newly.reduce((a, b) {
      final pa = priority[a.type]!;
      final pb = priority[b.type]!;
      if (pa != pb) {
        return pa > pb ? a : b;
      }
      return a.value >= b.value ? a : b;
    });

    _celebrating = true;
    final presentationGeneration = _presentationGeneration;
    try {
      if (!_canPresent(
        generation: generation,
        presentationGeneration: presentationGeneration,
      )) {
        return;
      }
      await DecorationRewardService.ensurePendingBox(
        '${DecorationRewardService.kMilestoneSourcePrefix}${top.id}',
      );
      if (!_canPresent(
        generation: generation,
        presentationGeneration: presentationGeneration,
      )) {
        return;
      }
      if (!mounted) {
        return;
      }
      final feedbackContext = FeedbackCompletion.milestone(
        milestoneId: top.id,
        milestoneType: top.type.name,
        value: top.value,
      ).context;
      _milestoneHandledThisVisit = true;
      // Opening the modal is synchronous up to route insertion. Persist only
      // after a visible presentation exists, then await its dismissal. This
      // prevents a hidden tab from consuming the milestone while preserving
      // the invariant that a currently displayed celebration is recorded.
      final presentation = showMilestoneCelebration(
        context,
        top,
        feedbackContext: feedbackContext,
      );
      await Storage.markMilestonesCelebrated([top.id]);
      await presentation;
      if (mounted) {
        // The pending Bojagi was created after the displayed snapshot. Refresh
        // once without admitting the next milestone in the same visit.
        _reload(checkMilestones: false);
      }
    } finally {
      _celebrating = false;
    }
  }

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
          forceStatic:
              widget.forceStaticHero ||
              paletteVariantNotifier.value == PaletteVariant.teal,
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
    final todayUnavailable = snapshot.today.isUnavailable;
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
            // A partial Today snapshot must not look like a complete daily
            // dashboard. In particular, neither reward collection nor
            // unrelated activity CTAs may accompany its safe retry path.
            if (!todayUnavailable) ...[
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
    // [TodayLearningSnapshotLoader] returns a partial snapshot when one of
    // its sources fails. It is useful for diagnostics, but it must never
    // become a fresh-looking mission or enter the reward-capture flow.
    if (snapshot.today.isUnavailable) {
      return _TodayUnavailableMissionStage(
        key: const ValueKey('sori-today-unavailable-mission'),
        today: snapshot.today,
        onRetry: onActivityReturned,
      );
    }

    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final destination = snapshot.today.destination;
    final contract = snapshot.todayReward;
    // §P3-1: 활동 entry 는 기존 activityForRoute 로 얻는다 (신규 조회 함수
    // 발명 금지). 가능한 라우트 4종은 전부 activities/{id}.webp 를 보유 —
    // entry == null 강등 분기는 현재 도달 불가지만 가드로 필수.
    final entry = activityForRoute(destination?.route);
    // 3중 반복("Heutige Mission starten" ×2 + brand eyebrow) 해체 —
    // 제목은 오늘 활동의 로컬라이즈드 타이틀이 말한다.
    final String title = destination == null
        ? t.soriStageTodayEmpty
        : (entry == null
              ? t.soriStageMissionAction
              : localCopy(context, entry.title));
    return Container(
      // §P3-1: padding 0 — 상단 21:9 일러스트가 카드 모서리까지 간다.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SoriActivityColors.hanokStage,
        borderRadius: BorderRadius.circular(SoriRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry != null && destination != null)
            // errorBuilder 는 2차 가드일 뿐: AspectRatio 는 자식이 아니라
            // 제약으로 크기가 잡히므로 errorBuilder 만으론 빈 다크 밴드가
            // 남는다. 1차 강등은 위 entry null 게이트다.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SoriRadius.xl),
              ),
              child: AspectRatio(
                aspectRatio: 21 / 9,
                child: Image.asset(
                  activityIllustrationAsset(entry.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.soriStageTodayMissionEyebrow,
                  // eyebrow 토큰 — 짙은 한옥 스테이지 위라 석간주 대신 골드.
                  style: tt.eyebrow.copyWith(color: SoriColors.gold),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  title,
                  // §D: 카드 내부 헤드라인은 h1 상한 — hero(38)는 페이지
                  // 헤더 전용.
                  style: tt.h1.copyWith(color: Colors.white),
                ),
                if (contract != null && contract.items.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  // §P3-1: ' · ' 조인 문자열 대신 아이템별 칩 — items 는
                  // kind 가 아이템마다 다르다 (단일 roofing 아이콘 금지).
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: Spacing.md,
                      runSpacing: Spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${t.soriStagePossibleReward}:',
                          style: tt.label.copyWith(
                            color: SoriActivityColors.onHanokStage,
                          ),
                        ),
                        for (final item in contract.items)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  soriRewardIcon(item.kind),
                                  size: 16,
                                  color: SoriColors.gold,
                                ),
                                const SizedBox(width: Spacing.xs),
                                Flexible(
                                  child: Text(
                                    localCopy(context, item.label),
                                    softWrap: true,
                                    style: tt.label.copyWith(
                                      color: SoriActivityColors.onHanokStage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                SoriButton(
                  // 제목이 이미 무엇인지 말한다 — CTA 는 "Starten" 한 단어.
                  // 미션이 없을 때는 기존 안내형 라벨 유지.
                  label: destination == null || entry == null
                      ? t.soriStageMissionAction
                      : t.soriStageMissionStart,
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
          ),
        ],
      ),
    );
  }
}

/// Conservative presentation for a partial Today snapshot.
///
/// This preserves the shared loader's availability contract: users may retry
/// or open an already-saved review, but no stale recommendation is presented
/// as today's fresh mission and no Stage reward receipt is captured.
class _TodayUnavailableMissionStage extends StatelessWidget {
  const _TodayUnavailableMissionStage({
    super.key,
    required this.today,
    required this.onRetry,
  });

  final TodayLearningSnapshot today;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final hasSavedReview = today.dueCount > 0;
    final copy = _TodayUnavailableCopy.from(
      t,
      today.unavailableReason,
      hasSavedReview: hasSavedReview,
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: SoriActivityColors.hanokStage,
        borderRadius: BorderRadius.circular(SoriRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(copy.icon, color: SoriColors.gold),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  copy.eyebrow,
                  style: tt.eyebrow.copyWith(color: SoriColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(copy.title, style: tt.h1.copyWith(color: Colors.white)),
          const SizedBox(height: Spacing.sm),
          Text(
            copy.body,
            style: tt.body.copyWith(color: SoriActivityColors.onHanokStage),
          ),
          if (hasSavedReview) ...[
            const SizedBox(height: Spacing.xl),
            Text(
              t.homeUnavailableSafeTitle,
              style: tt.label.copyWith(color: SoriColors.gold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              t.homeUnavailableSafeBody,
              style: tt.bodySmall.copyWith(
                color: SoriActivityColors.onHanokStage,
              ),
            ),
          ],
          const SizedBox(height: Spacing.xl),
          if (hasSavedReview) ...[
            SoriButton(
              key: const ValueKey('sori-today-saved-review'),
              label: t.homeUnavailableCta,
              onTap: () => Navigator.of(context).pushNamed('/review'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              key: const ValueKey('sori-today-unavailable-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: SoriActivityColors.onHanokStage,
              ),
              child: Text(copy.retryLabel),
            ),
          ] else
            SoriButton(
              key: const ValueKey('sori-today-unavailable-retry'),
              label: copy.retryLabel,
              onTap: onRetry,
            ),
        ],
      ),
    );
  }
}

class _TodayUnavailableCopy {
  const _TodayUnavailableCopy({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.retryLabel,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String retryLabel;

  factory _TodayUnavailableCopy.from(
    AppL10n t,
    TodayLearningUnavailableReason? reason, {
    required bool hasSavedReview,
  }) {
    return switch (reason ?? TodayLearningUnavailableReason.localData) {
      TodayLearningUnavailableReason.offline => _TodayUnavailableCopy(
        icon: Icons.cloud_off_outlined,
        eyebrow: t.homeUnavailableEyebrow,
        title: t.homeUnavailableTitle,
        body: hasSavedReview
            ? t.homeUnavailableDescription
            : t.homeUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetry,
      ),
      TodayLearningUnavailableReason.remoteService => _TodayUnavailableCopy(
        icon: Icons.cloud_sync_outlined,
        eyebrow: t.homeRemoteUnavailableEyebrow,
        title: t.homeRemoteUnavailableTitle,
        body: hasSavedReview
            ? t.homeRemoteUnavailableDescription
            : t.homeRemoteUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetryGeneric,
      ),
      TodayLearningUnavailableReason.localData => _TodayUnavailableCopy(
        icon: Icons.refresh_rounded,
        eyebrow: t.homeLocalUnavailableEyebrow,
        title: t.homeLocalUnavailableTitle,
        body: hasSavedReview
            ? t.homeLocalUnavailableDescription
            : t.homeLocalUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetryGeneric,
      ),
    };
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
    final stage = snapshot.hanok.structureStage;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/hanok'),
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SoriColors.primarySoft,
          borderRadius: BorderRadius.circular(SoriRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // §P3-3a: 아이콘 텍스트 → 한옥 스테이지 배너 (기존 12장 리졸버
            // 규약 `hanok_stages/stage_{slug}_light.png` 재사용 — 신규 매핑
            // 함수 발명 금지). 미존재 시 기존 아이콘 행으로 강등.
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SoriRadius.lg),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 5,
                    child: Image.asset(
                      'assets/illustrations/hanok_stages/'
                      'stage_${stage.assetSlug}_light.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: SoriColors.primarySoft,
                        child: Center(
                          child: Icon(
                            Icons.home_work_outlined,
                            size: 34,
                            color: SoriColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: Spacing.md,
                  bottom: Spacing.sm,
                  child: Text(
                    '$built / $total',
                    // §D: 진행 수치는 tabular — 조각이 늘어도 자리 흔들림
                    // 없음. 배너 위 가독을 위해 밝은 바탕 필.
                    style: tt.h3.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: SoriColors.primaryDark,
                      backgroundColor: SoriColors.lightSurfaceRaised.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.soriStageHanokNow, style: tt.h3),
                  const SizedBox(height: Spacing.md),
                  LinearProgressIndicator(
                    value: snapshot.hanok.constructionFraction,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(SoriRadius.sm),
                    color: SoriColors.primaryDark,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    // §P3-3a: enum 원문("empty") 노출 수리 — exhaustive
                    // DE/EN 매핑 (hanok_stage_names.dart).
                    '${t.soriStageNextPiece}: '
                    '${hanokStageDisplayName(t, stage)}',
                    style: tt.label,
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
    // §P3-3b: 맨 ListTile → SoriCard(compact) 규율 + 보상 썸네일(퀘스트가
    // 언락하는 마당 장식 — quests 화면과 같은 SoriRewardThumb 공용 위젯).
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: () => Navigator.of(context).pushNamed('/quests'),
        child: Row(
          children: [
            SoriRewardThumb(
              slug: definition.decorationSlug,
              earned: progress.completed,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language == 'de' ? definition.name.de : definition.name.en,
                    style: tt.cardTitle,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(SoriRadius.xs),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            Text(
              '${progress.current} / ${progress.target}',
              style: tt.label.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
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
