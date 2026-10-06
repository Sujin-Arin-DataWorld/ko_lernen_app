import '../../widgets/sori/yeopjeon_wallet_card.dart';
import '../../features/dancheong/dancheong_connections.dart';
import '../../features/dancheong/dancheong_store.dart';
import '../../features/content_learning/content_learning_widgets.dart';
import '../../widgets/sori/learning_focus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/milestone.dart';
import '../../data/quest_catalog.dart';
import '../../data/sori_activity_catalog.dart';
import '../../features/guide/today_guide_section.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/feedback_completion.dart';
import '../../models/home_navigation_art.dart';
import '../../models/companion_art.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/quest.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/decoration_reward_service.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../services/today_learning_navigation.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/catalog_card.dart';
import '../../widgets/sori/character_clip.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/home_hero.dart';
import '../../widgets/sori/learning_companion.dart';
import '../../widgets/sori/mascot_preference.dart';
import '../../widgets/sori/milestone_celebration.dart';
import '../../widgets/sori/motion.dart';
import '../../widgets/sori/placed_decoration.dart'
    show decorName, decorTerm, kAvailableDecorations;
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/sori_term.dart';
import '../../widgets/sori/spotlight_coach.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/week_sheet.dart';
import '../../widgets/sori/window_class.dart';
import 'sori_stage_common.dart';
import 'sori_stage_reward_receipt_sheet.dart';
import 'c_stage_chrome.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';

/// Today: compact greeting and companion grounded to the shared learning goal.
/// [SoriStatsTopBar] keeps profile and statistics access above that next step.
///
/// ⚠️ **배경 계약 (홈과 동일)**: 라이트 = [HomeHeroClips.matte] 평면 단색.
/// 히어로 클립이 한지색 매트를 미리 합성한 불투명 mp4 라, 배경이 이 값이
/// 아니거나 균일하지 않으면 영상 사각형이 액자처럼 뜬다 (2026-08-12 실측,
/// 상세는 home_hero.dart 와 홈 build 주석). 그라데이션·한지 그레인 금지.
class SoriStageTodayScreen extends StatefulWidget {
  const SoriStageTodayScreen({
    super.key,
    this.loadSnapshot,
    this.refreshGeneration = 0,
    this.replayHomeTour,
    this.now,
    this.onHomeTourStarted,
    this.enableMilestoneCelebrations,
    this.active = true,
    this.forceStaticHero = false,
  });

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final int refreshGeneration;
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
    final loaderChanged =
        oldWidget.loadSnapshot != widget.loadSnapshot ||
        oldWidget.refreshGeneration != widget.refreshGeneration;
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
          cutoutPadding: const EdgeInsets.all(6),
          cutoutRadius: SoriRadius.xl,
        ),
      ],
      onComplete: () => Storage.setTutHomeTourSeen(),
    );
  }

  void _reload({bool checkMilestones = true}) {
    // Manual refresh uses the same shell-owned recommendation as Lernen.
    // ignore: discarded_futures
    LearningFocusScope.maybeOf(context)?.notifier?.refresh(force: true);
    setState(() {
      _todayUnavailable = null;
      _future = _loadSnapshot(checkMilestones: checkMilestones);
    });
  }

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

  /// The greeting belongs to the learning card; this is only the app toolbar.
  Widget _header(BuildContext context, AppL10n t) {
    return CPaperPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          CImageTap(
            label: '${Storage.streakDays} ${t.statsDays}',
            onTap: _showWeekSheet,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    HomeNavigationArt.today,
                    width: 32,
                    height: 32,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${Storage.streakDays} ${t.statsDays}',
                    style: cStageBody,
                  ),
                ],
              ),
            ),
          ),
          CImageTap(
            label: '${t.navStats}. Lv ${Storage.xpLevel} · ${Storage.xp} XP',
            onTap: () => Navigator.pushNamed(context, '/stats'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CWaxSeal(size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'Lv ${Storage.xpLevel} · ${Storage.xp} XP',
                    style: cStageBody,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companion(BuildContext context, AppL10n t) {
    return ValueListenableBuilder<CompanionPreference>(
      valueListenable: MascotPreference.preference,
      builder: (context, preference, _) {
        final kind = MascotPreference.mascotKindFor(preference);
        return SoriLearningCompanion(
          greeting: soriHeroGreeting(t, _phase),
          title: t.soriStageNavToday,
          kind: kind,
          // teal kill-switch: 흰 배경 위 한지 매트 클립은 액자가 된다 →
          // 다크와 같은 정적 마스코트 경로로.
          // The approved tactile portrait replaces the old raster video
          // appearance. Dignity is preserved through one restrained entrance.
          forceStatic: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: CStageBackground(
        child: Stack(
          children: [
            SafeArea(
              child: FutureBuilder<SoriStageProgressionSnapshot>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      !snapshot.hasError) {
                    return _TodayContent(
                      snapshot: snapshot.requireData,
                      onRefresh: _reload,
                      missionTourKey: _missionTourKey,
                      header: _header(context, t),
                      companion: _companion(context, t),
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
                    maxWidth: SoriMaxWidth.hub,
                    base: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    builder: (context, padding) => ListView(
                      padding: padding,
                      children: [
                        CStageHeader(title: t.soriStageNavToday),
                        if (LearningFocusScope.maybeOf(context) != null)
                          const CPaperPanel(
                            child: SoriLearningFocus(conceptC: true),
                          ),
                        const SizedBox(height: 12),
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
    required this.companion,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onRefresh;
  final GlobalKey missionTourKey;
  final Widget header;
  final Widget companion;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final todayUnavailable = snapshot.today.isUnavailable;
    // §W-D D6: 미션·보자기·한옥·섹션 2개 — 실제로 그려지는 블록 순서대로
    // 40ms 씩 늘려 stagger 한다(최대 6블록, 이 화면은 그 안에 든다).
    // reduce-motion 은 SoriEntrance 자체가 처리한다(§ 재확인 필요 없음).
    var entranceIndex = 0;
    Widget stagger(Widget child) {
      final delay = Duration(milliseconds: 40 * entranceIndex.clamp(0, 5));
      entranceIndex++;
      return SoriEntrance(delay: delay, child: child);
    }

    // §W-D D3: "Fast geschafft"(≥60%)·"Als Nächstes"(<60%) — 둘 다 이미
    // closestQuests 가 상위 3개로 자른 같은 리스트를 fraction 으로 나눌 뿐,
    // 모델에 새 조회를 추가하지 않는다.
    final closestQuests = snapshot.closestQuests;
    final nearlyComplete = closestQuests
        .where((quest) => quest.fraction >= 0.6)
        .take(3)
        .toList(growable: false);
    final upNext = closestQuests
        .where((quest) => quest.fraction < 0.6)
        .take(3)
        .toList(growable: false);

    return SoriContentClamp(
      maxWidth: SoriMaxWidth.hub,
      base: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      builder: (context, padding) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            ValueListenableBuilder<CompanionPreference>(
              valueListenable: MascotPreference.preference,
              builder: (_, preference, _) {
                final kind = MascotPreference.mascotKindFor(preference);
                return CStageHeader(
                  title: t.soriStageNavToday,
                  balance: !todayUnavailable && !snapshot.walletUnavailable
                      ? snapshot.wallet?.balance
                      : null,
                  onWalletReturned: onRefresh,
                  artwork: kind == null
                      ? null
                      : Image.asset(
                          CompanionArt.portrait(kind.name),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                );
              },
            ),
            CPaperPanel(
              key: const ValueKey('c-today-board'),
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stagger(
                    LearningFocusScope.maybeOf(context) != null
                        ? SoriLearningFocus(key: missionTourKey, conceptC: true)
                        : Column(
                            children: [
                              _TodayMissionStage(
                                key: missionTourKey,
                                snapshot: snapshot,
                                onActivityReturned: onRefresh,
                              ),
                            ],
                          ),
                  ),
                  // A partial Today snapshot must not look like a complete daily
                  // dashboard. In particular, neither reward collection nor
                  // unrelated activity CTAs may accompany its safe retry path.
                  if (!todayUnavailable) ...[
                    if (snapshot.pendingBojagiCount > 0 ||
                        snapshot.hasPendingDecorationReceipt) ...[
                      const SizedBox(height: Spacing.lg),
                      stagger(
                        _PendingBojagi(
                          count: snapshot.pendingBojagiCount,
                          resuming: snapshot.hasPendingDecorationReceipt,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    stagger(_HanokProgress(snapshot: snapshot)),
                    const SizedBox(height: 12),
                    const TodayGuideChecklistSection(conceptC: true),
                    const ContentDailyGoals(conceptC: true),
                    DancheongDraftResume(
                      conceptC: true,
                      store: DancheongStore(),
                      onOpen: (arguments) => Navigator.of(context).pushNamed(
                        '/dancheong-studio/edit',
                        arguments: arguments,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    YeopjeonWalletCard(
                      key: ObjectKey(snapshot),
                      compact: true,
                      conceptC: true,
                    ),
                    if (nearlyComplete.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      stagger(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Extra learning stays on the same C paper board.
                            Text(
                              t.soriStageClosestQuests,
                              style: cStageCardTitle,
                            ),
                            const SizedBox(height: 8),
                            for (final quest in nearlyComplete)
                              _QuestProgressRow(progress: quest),
                          ],
                        ),
                      ),
                    ],
                    if (upNext.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      stagger(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.soriStageNextQuests, style: cStageCardTitle),
                            const SizedBox(height: 8),
                            for (final quest in upNext)
                              _QuestProgressRow(progress: quest),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  header,
                ],
              ),
            ),
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
    return CPaperPanel(
      padding: EdgeInsets.zero,
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
                child: cCatalogArt(entry),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.soriStageTodayMissionEyebrow,
                  // eyebrow 토큰 — 짙은 한옥 스테이지 위라 석간주 대신 골드.
                  style: cStageBody.copyWith(fontSize: 13),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  title,
                  // §D: 카드 내부 헤드라인은 h1 상한 — hero(38)는 페이지
                  // 헤더 전용.
                  style: cStageCardTitle.copyWith(fontSize: 25),
                ),
                if (contract != null && contract.items.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  // §W-D D5.2: "Mögliche Belohnung:" 은 골드 라벨보다
                  // 낮은 위계 — meta(13.5) + white@0.8.
                  Text(
                    '${t.soriStagePossibleReward}:',
                    style: cStageBody.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: Spacing.sm),
                  // §W-D D5.1: 세로 3열(아이콘 위·라벨 아래) — items 는 kind 가
                  // 아이템마다 다르다(단일 roofing 아이콘 금지 원칙 유지).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in contract.items)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_possibleRewardArtwork(item.kind)
                                  case final asset?) ...[
                                Image.asset(
                                  asset,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                  cacheWidth:
                                      (36 *
                                              MediaQuery.devicePixelRatioOf(
                                                context,
                                              ))
                                          .ceil(),
                                ),
                                const SizedBox(height: Spacing.xs),
                              ],
                              Text(
                                localCopy(context, item.label),
                                textAlign: TextAlign.center,
                                style: cStageBody.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                CMaterialAction(
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
    final hasSavedReview = today.dueCount > 0;
    final copy = _TodayUnavailableCopy.from(
      t,
      today.unavailableReason,
      hasSavedReview: hasSavedReview,
    );

    return CPaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.eyebrow, style: cStageBody.copyWith(fontSize: 13)),
          const SizedBox(height: Spacing.md),
          Text(copy.title, style: cStageCardTitle),
          const SizedBox(height: Spacing.sm),
          Text(copy.body, style: cStageBody),
          if (hasSavedReview) ...[
            const SizedBox(height: Spacing.xl),
            Text(
              t.homeUnavailableSafeTitle,
              style: cStageBody.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Spacing.xs),
            Text(t.homeUnavailableSafeBody, style: cStageBody),
          ],
          const SizedBox(height: Spacing.xl),
          if (hasSavedReview) ...[
            CMaterialAction(
              key: const ValueKey('sori-today-saved-review'),
              label: t.homeUnavailableCta,
              onTap: () => Navigator.of(context).pushNamed('/review'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              key: const ValueKey('sori-today-unavailable-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: CPalette.ink),
              child: Text(copy.retryLabel),
            ),
          ] else
            CMaterialAction(
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
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.retryLabel,
  });

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
        eyebrow: t.homeUnavailableEyebrow,
        title: t.homeUnavailableTitle,
        body: hasSavedReview
            ? t.homeUnavailableDescription
            : t.homeUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetry,
      ),
      TodayLearningUnavailableReason.remoteService => _TodayUnavailableCopy(
        eyebrow: t.homeRemoteUnavailableEyebrow,
        title: t.homeRemoteUnavailableTitle,
        body: hasSavedReview
            ? t.homeRemoteUnavailableDescription
            : t.homeRemoteUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetryGeneric,
      ),
      TodayLearningUnavailableReason.localData => _TodayUnavailableCopy(
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

String? _possibleRewardArtwork(SoriRewardKind kind) => switch (kind) {
  SoriRewardKind.yeopjeon => SoriArtwork.yeopjeon,
  SoriRewardKind.xp => HomeNavigationArt.learn,
  SoriRewardKind.questProgress => HomeNavigationArt.today,
  SoriRewardKind.hanokProgress => HomeNavigationArt.hanok,
  SoriRewardKind.bojagi => HomeNavigationArt.treasureChest,
  _ => null,
};

class _PendingBojagi extends StatelessWidget {
  const _PendingBojagi({required this.count, this.resuming = false});
  final int count;
  final bool resuming;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    void open() => Navigator.of(context).pushNamed('/bojagi');
    return CPaperPanel(
      radius: 12,
      child: Row(
        children: [
          Image.asset(
            HomeNavigationArt.treasureChest,
            key: const ValueKey('pending-treasure-chest-art'),
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  resuming
                      ? t.rewardChestTitle
                      : '${t.soriStageBojagiTitle} · $count',
                  key: const ValueKey('pending-bojagi-title'),
                  style: cStageCardTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  resuming ? t.rewardChestNewDecoration : t.soriStageBojagiBody,
                  key: const ValueKey('pending-bojagi-body'),
                  style: cStageBody.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                CMaterialAction(
                  key: const ValueKey('pending-bojagi-action'),
                  label: resuming ? t.rewardChestReplay : t.soriStageOpenBojagi,
                  compact: true,
                  gold: false,
                  onTap: open,
                ),
              ],
            ),
          ),
        ],
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
    final progress = snapshot.walletUnavailable
        ? t.soriStageHanokProgressUnavailable
        : t.sarangchaeConstructionProgress(
            snapshot.ownedSarangchaeStage,
            SarangchaeConstruction.stageCount,
          );
    final titleStyle = cStageCardTitle.copyWith(fontSize: 20);
    final progressStyle = cStageBody.copyWith(fontSize: 14);
    final actionStyle = cStageBody.copyWith(fontWeight: FontWeight.w600);
    return CImageTap(
      key: const ValueKey('today-hanok-summary'),
      label: '${t.soriStageOpenHanok}. $progress',
      onTap: () => Navigator.of(context).pushNamed('/hanok'),
      child: CPaperPanel(
        radius: 12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const thumbnailWidth = 128.0;
            const gap = 10.0;
            const arrowSize = 18.0;
            final labelWidth =
                constraints.maxWidth - thumbnailWidth - gap - arrowSize;
            // Keep complete localized words when enlarged type no longer fits
            // beside the picture. The image, copy and route stay unchanged.
            final labelsFit =
                [
                  (t.soriStageNavHanok, titleStyle),
                  (progress, progressStyle),
                  (t.soriStageOpenHanok, actionStyle),
                ].every((label) {
                  for (final word in label.$1.split(RegExp(r'\s+'))) {
                    final measure = TextPainter(
                      text: TextSpan(text: word, style: label.$2),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      locale: Localizations.localeOf(context),
                    )..layout();
                    final fits = measure.width <= labelWidth;
                    measure.dispose();
                    if (!fits) return false;
                  }
                  return true;
                });
            final labels = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.soriStageNavHanok, style: titleStyle),
                const SizedBox(height: 6),
                Text(
                  progress,
                  key: const ValueKey('today-hanok-progress-text'),
                  style: progressStyle,
                ),
                const SizedBox(height: 8),
                Text(t.soriStageOpenHanok, style: actionStyle),
              ],
            );
            const thumbnail = SizedBox(
              width: thumbnailWidth,
              child: CHanokScene(),
            );
            if (!labelsFit) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: thumbnail,
                  ),
                  const SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(child: labels),
                      const CArrow(dark: true, size: arrowSize),
                    ],
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                thumbnail,
                const SizedBox(width: gap),
                Expanded(child: labels),
                const CArrow(dark: true, size: arrowSize),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Secondary "Romanization · Hangul" line under a quest reward's name —
/// only when the glossary actually links [decorationSlug] to a term (most
/// slugs do not) and the term adds something [decorName] does not already
/// say (§W-C C3).
Widget _questCulturalTerm(BuildContext context, String decorationSlug) {
  return CulturalGlossaryBuilder(
    builder: (context, glossary) {
      final termId = glossary?.termIdForDecoration(decorationSlug);
      if (termId == null) {
        return const SizedBox.shrink();
      }
      final t = AppL10n.of(context);
      final term = decorTerm(t, decorationSlug);
      if (term == decorName(t, decorationSlug)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SoriTerm(
          conceptC: true,
          termId: termId,
          text: term,
          style: cStageBody.copyWith(fontSize: 13),
          surface: 'today_quest_row',
        ),
      );
    },
  );
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({required this.progress});
  final QuestProgress progress;

  Widget _thumbMat(String slug, bool earned) {
    const size = 56.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CPalette.paper,
        shape: BoxShape.circle,
      ),
      child: kAvailableDecorations.contains(slug)
          ? SoriRewardThumb(
              slug: slug,
              earned: earned,
              size: size,
              semantic: '',
            )
          : Image.asset(
              HomeNavigationArt.treasureChest,
              width: size,
              height: size,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final definition = kQuestCatalog.firstWhere(
      (quest) => quest.id == progress.questId,
    );
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: CImageTap(
        label:
            '${language == 'de' ? definition.name.de : definition.name.en}. ${progress.current} / ${progress.target}',
        onTap: () => Navigator.of(context).pushNamed('/quests'),
        child: CPaperPanel(
          child: Row(
            children: [
              _thumbMat(definition.decorationSlug, progress.completed),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == 'de'
                          ? definition.name.de
                          : definition.name.en,
                      style: cStageBody.copyWith(fontWeight: FontWeight.w600),
                    ),
                    _questCulturalTerm(context, definition.decorationSlug),
                    const SizedBox(height: Spacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        color: CPalette.jade,
                        backgroundColor: CPalette.fineEdge,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.current} / ${progress.target}',
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
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              HomeNavigationArt.learn,
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              t.homeLocalUnavailableTitle,
              style: cStageCardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.homeLocalUnavailableDescriptionNoReview,
              style: cStageBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            CMaterialAction(
              label: t.homeUnavailableRetryGeneric,
              gold: false,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
