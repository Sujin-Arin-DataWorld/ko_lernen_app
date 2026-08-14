import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/personal_hanok.dart';
import '../models/hanok_build_narrative.dart';
import '../models/feedback_completion.dart';
import '../models/gye.dart';
import '../models/hanok_stage.dart';
import '../services/decoration_reward_service.dart';
import '../services/mission_recommender.dart';
import '../services/pack_access.dart';
import '../services/gye_service.dart';
import '../services/quest_tracker.dart';
import '../services/hanok_stage_service.dart';
import '../services/hanok_build_narrative_service.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../services/today_learning_snapshot.dart';
import '../services/today_learning_navigation.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/hanok_cinematic.dart';
import '../widgets/sori/home_hero.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_hero_card.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/stats_top_bar.dart';
import '../widgets/sori/week_sheet.dart';
import '../widgets/sori/motivation_sheet.dart';
import '../widgets/sori/milestone_celebration.dart';
import '../data/learner_motivation.dart';
import '../data/milestone.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **Home — v4 (2026-05-29 완전 재구성)**
///
/// 이전 (v3)의 문제:
///   - `madang(light/dark).png` 배경에 호랑이/하녹이 baked-in 되어 BoxFit.cover 시
///     랜덤한 위치에서 잘림 (bug)
///   - Stats peek + Daily char + Hero + Modules grid → 정보 폭격, 페르소나 약함
///   - 호랑이가 hero card 한 칸에만 등장 → 안내자 페르소나 0
///
/// v4 컨셉: **"한옥 마당에 호랑이가 사용자에게 말 거는 한 장면"**
///   1. 추상 gradient + ambient 입자 + flying magpie (baked-in mascot 0)
///   2. 시간대별 인사 + 큰 호랑이 + 말풍선 (Duo의 캐릭터 페르소나를 한국식으로)
///   3. Inline stat chip row (streak · XP · shield) — 큰 카드 X
///   4. 오늘의 글자 compact
///   5. "다음 한 발" hero CTA (1개 시나리오 추천)
///   6. Modules + Games → horizontal scroll secondary
class HomePreviewFixture {
  const HomePreviewFixture({
    required this.today,
    required this.hanok,
    required this.narrative,
    this.onOpenToday,
    this.onOpenHanok,
  });

  final TodayLearningSnapshot today;
  final PersonalHanokProjection hanok;
  final HanokBuildNarrative narrative;
  final FutureOr<void> Function(TodayLearningDestination? destination)?
  onOpenToday;
  final FutureOr<void> Function()? onOpenHanok;
}

class HomeScreen extends StatefulWidget {
  /// 첫 실행 코치마크가 가리키는 **오늘의 미션 카드** 키.
  /// 신규 사용자가 배워야 할 단 하나 — "여기서 첫 미션이 시작된다".
  final GlobalKey? missionTourKey;
  final String? dailyCharacter;
  final Future<TodayLearningSnapshot> Function()? loadTodaySnapshot;
  final Future<LevelRatios> Function()? loadHanokRatios;
  final Future<PersonalHanokProjection> Function(LevelRatios ratios)?
  loadHanokProjection;
  final Future<HanokBuildNarrative> Function(
    PersonalHanokProjection projection,
  )?
  loadHanokNarrative;
  final DateTime Function()? now;
  final HomePreviewFixture? previewFixture;

  /// Uses injected fixture state without starting production refresh, reward,
  /// reminder, intro, or Hanok flows. Intended for tests and the UX gallery.
  final bool previewMode;
  final Future<void> Function()? onOpenSavedReview;
  final TodayLearningPackAccessGate? ensureTodayPackAccess;
  final TodayLearningRouteOpener? openTodayRoute;
  final Stream<TodayNetworkStatus>? connectivityUpdates;

  // Stage B 예약: final GlobalKey? bookTourKey;

  const HomeScreen({
    super.key,
    this.missionTourKey,
    this.dailyCharacter,
    this.loadTodaySnapshot,
    this.loadHanokRatios,
    this.loadHanokProjection,
    this.loadHanokNarrative,
    this.now,
    this.previewMode = false,
    this.onOpenSavedReview,
    this.ensureTodayPackAccess,
    this.openTodayRoute,
    this.connectivityUpdates,
  }) : previewFixture = null;

  /// The real Home surface with deterministic read-only state. It skips path,
  /// notification, reward, cinematic, and onboarding flows entirely.
  const HomeScreen.preview({
    super.key,
    required this.previewFixture,
    this.dailyCharacter,
    this.now,
  }) : missionTourKey = null,
       loadTodaySnapshot = null,
       loadHanokRatios = null,
       loadHanokProjection = null,
       loadHanokNarrative = null,
       previewMode = true,
       onOpenSavedReview = null,
       ensureTodayPackAccess = null,
       openTodayRoute = null,
       connectivityUpdates = null;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TodayLearningSnapshot? _todaySnapshot;
  HanokBuildNarrative? _hanokNarrative;
  bool _loadingTodaySnapshot = true;
  TodayLearningUnavailableReason? _todayUnavailableReason;
  StreamSubscription<TodayNetworkStatus>? _connectivitySubscription;
  int _todayLoadGeneration = 0;
  int _dueCount = 0; // M2: heute fällige + neue SRS-Karten ("Heute lernen")

  // Phase 3 (stately-rising-jongga) — Hanok-Cinematic gating.
  HanokStage? _pendingCinematicStage;
  bool _cinematicShown = false;

  @override
  void initState() {
    super.initState();
    final preview = widget.previewFixture;
    if (preview != null) {
      _todaySnapshot = preview.today;
      _hanokNarrative = preview.narrative;
      _loadingTodaySnapshot = false;
      _dueCount = preview.today.dueCount;
      return;
    }
    _loadToday();
    final connectivityUpdates =
        widget.connectivityUpdates ??
        (widget.previewMode ? null : TodayLearningConnectivity.statusChanges);
    _connectivitySubscription = connectivityUpdates?.listen(
      _handleConnectivityChange,
    );
    if (!widget.previewMode) {
      WidgetsBinding.instance.addObserver(this);
      _loadHanokPreview();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        if (await Storage.markDailyGoalMetIfReached()) {
          Analytics.dailyGoalMet(
            goalType: 'xp',
            goalValue: Storage.dailyGoalXp,
          );
        }
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeShowIntroFlows(),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    if (!widget.previewMode && widget.previewFixture == null) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 공부→백그라운드→재개 시 그새 생산된 보자기·성장을 끌어온다. _refreshHome
    // 이 syncEarnedRewards 를 돌리고 openableBoxCount 를 재독해 배너에 반영한다.
    if (!widget.previewMode &&
        widget.previewFixture == null &&
        state == AppLifecycleState.resumed &&
        mounted) {
      _refreshHome();
    }
  }

  /// 첫 프레임 뒤 순차: 동기 시트(1회) → 없으면 마일스톤 축하(있으면). 겹침 방지.
  Future<void> _maybeShowIntroFlows() async {
    final shownMotivation = await _maybeAskMotivation();
    if (shownMotivation || !mounted) {
      return;
    }
    await _maybeCelebrateMilestone();
  }

  /// 첫 진입 시 1회 — "왜 한국어를 배우나" 캡처(홈 투어 뒤에). 시트 띄웠으면 true.
  Future<bool> _maybeAskMotivation() async {
    if (!mounted) {
      return false;
    }
    // 온보딩 홈 투어를 먼저 보이고, 그 뒤에 동기 시트(겹침 방지).
    if (Storage.motivationAsked || !Storage.tutHomeTourSeen) {
      return false;
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return false;
    }
    await showMotivationSheet(context);
    if (mounted) {
      setState(() {}); // tiger bubble 개인화 반영
    }
    return true;
  }

  bool _celebrating = false;

  /// 새로 달성한 마일스톤 중 실제로 표시할 우선순위 1개만 축하·마킹한다.
  /// 홈 투어(오리엔테이션) 완료 후 + 재진입 가드(시트 중복 방지).
  Future<void> _maybeCelebrateMilestone() async {
    if (!mounted || _celebrating || !Storage.tutHomeTourSeen) {
      return;
    }
    final newly = newlyReachedMilestones(
      streak: Storage.streakDays,
      level: Storage.xpLevel,
      // 고유 단어 수(누적 정답 시도가 아님 — "N개 단어" 카피와 정합).
      vocab: Storage.vokSeenIds.length,
      celebrated: Storage.celebratedMilestones.toSet(),
    );
    if (newly.isEmpty) {
      return;
    }
    // 타입 우선순위(스트릭>레벨>단어) 후 값 최대 1개만 축하.
    const priority = {
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
    if (!mounted) {
      return;
    }
    _celebrating = true;
    try {
      // P2-c: 마일스톤 축하와 함께 보자기 한 개를 떨군다. 출처는 마일스톤 id
      // (`milestone:level_5` 등). ensurePendingBox 는 출처별 멱등이라 마킹 전에
      // 떨어뜨려도(또는 재축하 시) 중복 생산되지 않는다. 크래시 안전을 위해
      // 마킹보다 먼저 생산한다 — 마킹만 되고 보자기를 잃는 창을 없앤다.
      await DecorationRewardService.ensurePendingBox(
        '${DecorationRewardService.kMilestoneSourcePrefix}${top.id}',
      );
      await Storage.markMilestonesCelebrated([top.id]);
      if (!mounted) return;
      final feedbackContext = FeedbackCompletion.milestone(
        milestoneId: top.id,
        milestoneType: top.type.name,
        value: top.value,
      ).context;
      await showMilestoneCelebration(
        context,
        top,
        feedbackContext: feedbackContext,
      );
    } finally {
      _celebrating = false;
    }
  }

  Future<void> _checkHanokCinematic(HanokStage stage) async {
    if (!mounted) return;
    final shouldShow = await HanokCinematic.shouldShow(stage);
    if (!shouldShow || !mounted) return;
    setState(() => _pendingCinematicStage = stage);
  }

  /// Reads the same deterministic construction projection shown by the map.
  ///
  /// This preview is deliberately read-only: it never awards, unlocks, or
  /// mutates the learner's rooms, decor, or course evidence.
  Future<void> _loadHanokPreview() async {
    final loadRatios = widget.loadHanokRatios ?? HanokStageService.levelRatios;
    PersonalHanokProjection projection;
    try {
      final ratios = await loadRatios();
      final loadProjection =
          widget.loadHanokProjection ??
          HanokStructureProjectionService.loadForRatios;
      projection = await loadProjection(ratios);
    } catch (_) {
      projection = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      );
    }
    unawaited(_checkHanokCinematic(projection.structureStage));

    HanokBuildNarrative narrative;
    try {
      final loadNarrative =
          widget.loadHanokNarrative ??
          HanokBuildNarrativeService.loadForProjection;
      narrative = await loadNarrative(projection);
    } catch (_) {
      narrative = HanokBuildNarrative.empty(projection);
    }
    if (mounted) {
      setState(() => _hanokNarrative = narrative);
    }
  }

  /// Loads the same read-only recommendation snapshot as the Sarangbang.
  ///
  /// Home only previews the selected mission. Its CTA executes the snapshot's
  /// existing destination through the shared access-gated navigator rather
  /// than adding a second decision in the Sarangbang.
  Future<void> _loadToday() async {
    final generation = ++_todayLoadGeneration;
    if (mounted) {
      setState(() {
        _loadingTodaySnapshot = true;
        _todayUnavailableReason = null;
      });
    }
    try {
      final load = widget.loadTodaySnapshot ?? TodayLearningSnapshotLoader.load;
      final snapshot = await load();
      if (!mounted || generation != _todayLoadGeneration) {
        return;
      }

      setState(() {
        _todaySnapshot = snapshot;
        _dueCount = snapshot.dueCount;
        _loadingTodaySnapshot = false;
        _todayUnavailableReason = snapshot.unavailableReason;
      });
      // 푸시 리텐션: 데일리 리마인더 body를 최신 스트릭으로 갱신해 재예약.
      if (!widget.previewMode && !snapshot.isUnavailable) {
        _refreshDailyReminder();
      }
    } catch (error) {
      if (!mounted || generation != _todayLoadGeneration) {
        return;
      }
      setState(() {
        _loadingTodaySnapshot = false;
        _dueCount = 0;
        _todayUnavailableReason = error is TodayLearningSourceFailure
            ? error.reason
            : TodayLearningUnavailableReason.localData;
      });
    }
  }

  void _handleConnectivityChange(TodayNetworkStatus status) {
    if (!mounted || status == TodayNetworkStatus.unknown) return;
    if (status == TodayNetworkStatus.offline) {
      _todayLoadGeneration++;
      setState(() {
        _loadingTodaySnapshot = false;
        _todayUnavailableReason = TodayLearningUnavailableReason.offline;
      });
      return;
    }
    if (_todayUnavailableReason == TodayLearningUnavailableReason.offline) {
      unawaited(_loadToday());
    }
  }

  String _todayUnavailableEyebrow(AppL10n t) =>
      switch (_todayUnavailableReason!) {
        TodayLearningUnavailableReason.offline => t.homeUnavailableEyebrow,
        TodayLearningUnavailableReason.remoteService =>
          t.homeRemoteUnavailableEyebrow,
        TodayLearningUnavailableReason.localData =>
          t.homeLocalUnavailableEyebrow,
      };

  String _todayUnavailableTitle(AppL10n t) =>
      switch (_todayUnavailableReason!) {
        TodayLearningUnavailableReason.offline => t.homeUnavailableTitle,
        TodayLearningUnavailableReason.remoteService =>
          t.homeRemoteUnavailableTitle,
        TodayLearningUnavailableReason.localData => t.homeLocalUnavailableTitle,
      };

  String _todayUnavailableBody(AppL10n t) {
    final hasSavedReview = _dueCount > 0;
    return switch (_todayUnavailableReason!) {
      TodayLearningUnavailableReason.offline =>
        hasSavedReview
            ? t.homeUnavailableDescription
            : t.homeUnavailableDescriptionNoReview,
      TodayLearningUnavailableReason.remoteService =>
        hasSavedReview
            ? t.homeRemoteUnavailableDescription
            : t.homeRemoteUnavailableDescriptionNoReview,
      TodayLearningUnavailableReason.localData =>
        hasSavedReview
            ? t.homeLocalUnavailableDescription
            : t.homeLocalUnavailableDescriptionNoReview,
    };
  }

  String _todayUnavailableRetryLabel(AppL10n t) =>
      _todayUnavailableReason == TodayLearningUnavailableReason.offline
      ? t.homeUnavailableRetry
      : t.homeUnavailableRetryGeneric;

  IconData get _todayUnavailableIcon => switch (_todayUnavailableReason!) {
    TodayLearningUnavailableReason.offline => Icons.cloud_off_outlined,
    TodayLearningUnavailableReason.remoteService => Icons.cloud_sync_outlined,
    TodayLearningUnavailableReason.localData => Icons.refresh_rounded,
  };

  Future<void> _refreshHome() async {
    if (widget.previewFixture != null) {
      return;
    }
    if (widget.previewMode) {
      await _loadToday();
      return;
    }
    // 공부하고 돌아오면 그새 target 도달한 퀘스트의 보자기를 생산한다(퀘스트
    // 화면을 안 열어도 — 실제 근본 수리). 이후 _loadToday 가 openableBoxCount 를
    // 다시 읽어 보자기 배너에 반영한다.
    await QuestTracker.syncEarnedRewards();
    await Future.wait<void>([_loadToday(), _loadHanokPreview()]);
  }

  /// 알림이 켜져 있으면 데일리 리마인더를 최신 스트릭 문구로 재예약한다
  /// (홈 진입마다). 스트릭이 있으면 "🔥 N일 연속" 넛지로 강화.
  void _refreshDailyReminder() {
    if (!mounted || !Storage.notificationsEnabled) {
      return;
    }
    final t = AppL10n.of(context);
    final streak = Storage.streakDays;
    final body = streak > 0
        ? t.notifDailyStreakBody(streak)
        : t.notificationBody;
    // ignore: discarded_futures
    NotificationService.scheduleDaily(
      hour: Storage.notificationHour,
      minute: 0,
      title: t.notificationTitle,
      body: body,
    );
  }

  /// 스트릭 칩 탭 — 주간 시트(공용 [showSoriWeekSheet]) 후 최신 값 반영.
  Future<void> _showWeekSheet() async {
    await showSoriWeekSheet(context);
    if (mounted) {
      setState(() {}); // 시트에서 돌아온 뒤 최신 값 반영.
    }
  }

  /// 시간대 — 인사 + 호랑이 emotion 결정 (공용 [soriDayPhaseFor]).
  SoriDayPhase get _phase =>
      soriDayPhaseFor(widget.now?.call() ?? DateTime.now());

  String _todayHeading(AppL10n t) {
    final date = widget.now?.call() ?? DateTime.now();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return t.homeFocusDate(DateFormat.EEEE(locale).format(date));
  }

  String _greeting(AppL10n t) => soriHeroGreeting(t, _phase);

  /// 말풍선 텍스트 — streak·진척·학습 이유(motivation)에 따라. 순수 함수 위임.
  String _tigerBubble(AppL10n t, MascotKind kind) => homeTigerBubble(
    t,
    streak: Storage.streakDays,
    xp: Storage.xp,
    motivation: learnerMotivationFromId(Storage.motivation),
    kind: kind,
  );

  Future<void> _openTodayDestination({bool celebrateMilestone = false}) async {
    if (!mounted) {
      return;
    }
    final preview = widget.previewFixture;
    if (preview != null) {
      await preview.onOpenToday?.call(_todaySnapshot?.destination);
      return;
    }
    final opened = await TodayLearningNavigation.open(
      _todaySnapshot?.destination,
      ensurePackAccess:
          widget.ensureTodayPackAccess ??
          (level) => ensurePackAccess(context, level: level),
      openRoute:
          widget.openTodayRoute ??
          (route, arguments) async {
            await Navigator.of(context).pushNamed(route, arguments: arguments);
          },
    );
    if (!opened || !mounted) {
      return;
    }
    await _refreshHome();
    if (celebrateMilestone && mounted) {
      await _maybeCelebrateMilestone();
    }
  }

  Future<void> _openSavedReview() async {
    final open = widget.onOpenSavedReview;
    if (open != null) {
      await open();
    } else {
      await Navigator.pushNamed(context, '/review');
    }
    if (mounted && !widget.previewMode) {
      await _loadToday();
    }
  }

  /// §6.1 블록 3 추천 엔진 — "다음 것 1개"의 단일 소스.
  /// 우선순위: ① 현재 코스 미션 > ② 진행 중 팩 > ③ due 복습(≥10) >
  /// ④ 시나리오 추천. null = 오늘 할 것 없음(allDone).
  /// 규칙 R-REC(H-6): 추천 레벨 ≤ 사용자 레벨 — 코스·팩은 순차 구조가
  /// 레벨을 보장하므로 시나리오에만 명시 가드를 둔다.
  MissionHeroContent? _missionHeroContent(AppL10n t, String lang) {
    // The shared snapshot is the only input-assembly owner. Home only turns
    // its already selected pick into presentation copy and opens that exact
    // destination through [TodayLearningNavigation].
    final snapshot = _todaySnapshot;
    final pick = snapshot?.pick;
    switch (pick) {
      case CoursePick c:
        return MissionHeroContent(
          kind: MissionHeroKind.course,
          title: c.unit.title.pick(lang),
          contextLabel: t.homeTodayEyebrow,
          levelCode: c.unit.level.toUpperCase(),
          // The home promise is the learner's real-world outcome. Mission
          // numbering still exists in the course path, but it is not the
          // reason a beginner should choose today's one action.
          meta: c.unit.canDo.pick(lang),
          fraction: c.fraction,
          started: c.started,
          ctaLabel: t.homeTodayCourseAction,
          onStart: () => _openTodayDestination(celebrateMilestone: true),
        );
      case PackPick p:
        final level = p.pack.level.toUpperCase();
        return MissionHeroContent(
          kind: MissionHeroKind.pack,
          title: VocabPackService.displayLabel(p.pack.id, lang: lang),
          contextLabel: t.homeTodayEyebrow,
          levelCode: level,
          meta: t.homeTodayPackDescription,
          fraction: p.fraction,
          started: true,
          ctaLabel: t.homeTodayPackAction,
          onStart: _openTodayDestination,
        );
      case ReviewPick r:
        return MissionHeroContent(
          kind: MissionHeroKind.review,
          title: t.homeTodayReviewDescription,
          contextLabel: t.homeTodayFirst,
          levelCode: null,
          meta: t.homeTodayReviewLead(r.dueCount),
          fraction: 0,
          started: false,
          ctaLabel: t.homeTodayReviewAction,
          actionLabel: t.homeTodayNextAction,
          actionTitle: t.homeTodayReviewMission(r.dueCount),
          actionMeta: t.homeTodayReviewTime,
          supportingTitle: t.homeTodayReviewReasonTitle,
          supportingBody: t.homeTodayReviewReason,
          onStart: _openTodayDestination,
        );
      case ScenarioPick sc:
        final level = sc.level.code.toUpperCase();
        return MissionHeroContent(
          kind: MissionHeroKind.scenario,
          title: snapshot?.scenario?.title.pick(lang) ?? sc.scenarioId,
          contextLabel: t.homeTodayEyebrow,
          levelCode: level,
          meta: t.homeTodayScenarioDescription,
          fraction: 0,
          started: false,
          ctaLabel: t.homeTodayScenarioAction,
          onStart: _openTodayDestination,
        );
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. 배경 ──
          // ⚠️ **라이트 모드는 평면 단색이다. 그라데이션을 되돌리지 말 것.**
          //
          // 홈 히어로는 한지색 매트를 미리 합성한 **불투명 정사각 mp4** 다.
          // 배경이 조금이라도 균일하지 않으면 그 사각형만 주변과 달라 액자처럼
          // 뜬다. Jin 이 2026-08-06 부터 **네 번** 지적한 "호랑이 흰 배경"이다.
          //
          // 2026-08-12 실기기 실측(`adb exec-out screencap`, M2101K6G):
          //   · 영상 사각형 = 본문 세로의 **59.7% ~ 86.3%** 구간
          //   · 옛 평면 구간 = 0 ~ 60%  → **영상이 통째로 그라데이션 위에 있었다**
          //   · 사각형 바깥 `#F2DBBD` ↔ 안쪽 `#FBF5EB` → B 채널 **46** 차이
          //     (직전 세션이 고친 매트 1~2 차이는 전체 오차의 5% 에 불과했다)
          //
          // 비율(`0.60` 같은 상수)로는 절대 못 덮는다 — 밴드의 세로 위치는
          // 미션 카드 높이·글자 배율·기기 높이에 따라 dp 단위로 움직이고,
          // 무엇보다 **스크롤하면 배경(화면 고정)과 밴드(콘텐츠)가 어긋난다.**
          // 그래서 라이트 배경 전체를 매트 색으로 평평하게 둔다.
          // 다크 모드는 히어로가 정지 PNG(투명 배경)라 안전 → 그라데이션 유지.
          Positioned.fill(
            child: isDark
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF14201E),
                          Color(0xFF14201E),
                          Color(0xFF0E1815),
                          Color(0xFF0A1310),
                        ],
                        stops: [0.0, 0.60, 0.8, 1.0],
                      ),
                    ),
                  )
                : const ColoredBox(color: _kHeroMatte),
          ),

          // ── 2. Subtle radial accent — 따뜻한 빛 · **다크 전용** ──
          // 라이트에서 이 glow 는 영상 밴드와 겹쳐 사각형 **바깥만** 주황빛으로
          // 덥히고 안쪽은 그대로 둬서 이음매를 만든다. 선언은 밴드 바닥
          // 상한 500dp 였지만 실측 밴드 바닥은 **678dp** 였다 — 178dp 겹쳤다.
          // 라이트의 따뜻함은 카드·마스코트가 담당한다.
          if (isDark)
            Positioned(
              top: _kHeroBandBottomDp,
              left: -40,
              right: -40,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        SoriColors.tiger.withValues(alpha: 0.15),
                        SoriColors.tiger.withValues(alpha: 0.0),
                      ],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),
            ),

          // ── 3. Content ──
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              color: SoriColors.primary,
              // 바깥 LayoutBuilder 는 clamp **상한**만 정한다(2열이 들어갈
              // 폭에서만 640dp 고정 상한을 푼다). 실제 1열/2열 판정은 clamp
              // padding 이 적용된 **안쪽** LayoutBuilder 가 콘텐츠 폭으로 한다.
              child: LayoutBuilder(
                builder: (context, outer) => SoriContentClamp(
                  maxWidth: _homeContentMaxWidth(outer.maxWidth),
                  base: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.xl,
                  ),
                  builder: (context, padding) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: padding,
                    child: LayoutBuilder(
                      builder: (context, content) {
                        final bool twoColumn =
                            content.maxWidth >= kHomeTwoColumnMinWidth;

                        // 홈은 IndexedStack 안이라 설정에서 캐릭터를 바꿔도
                        // setState 가 안 온다 → notifier 를 직접 구독한다.
                        final Widget heroBand = SoriEntrance(
                          delay: const Duration(milliseconds: 40),
                          child: ValueListenableBuilder<CompanionPreference>(
                            valueListenable: MascotPreference.preference,
                            builder: (context, preference, _) {
                              final kind = MascotPreference.mascotKindFor(
                                preference,
                              );
                              if (kind == null) {
                                return const SizedBox.shrink(
                                  key: ValueKey('home-companion-hidden'),
                                );
                              }
                              return SoriCharacterHero(
                                greeting: _greeting(t),
                                bubble: _tigerBubble(t, kind),
                                phase: _phase,
                                kind: kind,
                              );
                            },
                          ),
                        );
                        // 화면상 맨 위 — 목록 마지막 = 가장 나중에 paint.
                        // (`_TopBar` 는 자체 하단 여백 Spacing.lg 를 갖고 있어
                        //  인사말과의 간격은 그대로 유지된다.)
                        final Widget topBar = SoriStatsTopBar(
                          streak: Storage.streakDays,
                          level: Storage.xpLevel,
                          xp: Storage.xp,
                          onStreakTap: _showWeekSheet,
                          onStatsTap: () =>
                              Navigator.pushNamed(context, '/stats'),
                        );
                        // ── D. 오늘의 미션 히어로 — 단일 CTA (§6.1 블록 3·§10.1).
                        // 구 "Jetzt lernen" 버튼 + Today 시나리오 카드를 흡수한
                        // 추천 엔진: 코스 미션 > 진행 중 팩 > 복습 > 시나리오.
                        final Widget missionCard = SoriEntrance(
                          delay: const Duration(milliseconds: 100),
                          slideY: 14,
                          // 첫 실행 코치마크 타겟은 **바깥에** 덧씌운다 —
                          // `home-primary-today` ValueKey 는 기존 테스트와
                          // 위젯 정체성이 걸려 있어 건드리지 않는다.
                          child: _MaybeKeyed(
                            tourKey: widget.missionTourKey,
                            child: KeyedSubtree(
                              key: const ValueKey('home-primary-today'),
                              child: MissionHeroCard(
                                loading: _loadingTodaySnapshot,
                                content: _loadingTodaySnapshot
                                    ? null
                                    : _missionHeroContent(t, lang),
                                unavailable: _todayUnavailableReason != null
                                    ? MissionHeroUnavailable(
                                        icon: _todayUnavailableIcon,
                                        eyebrow: _todayUnavailableEyebrow(t),
                                        title: _todayUnavailableTitle(t),
                                        body: _todayUnavailableBody(t),
                                        ctaLabel: _dueCount > 0
                                            ? t.homeUnavailableCta
                                            : null,
                                        onStart: _dueCount > 0
                                            ? _openSavedReview
                                            : null,
                                        retryLabel: _todayUnavailableRetryLabel(
                                          t,
                                        ),
                                        onRetry: _loadToday,
                                      )
                                    : null,
                                onAnotherRound: _todayUnavailableReason != null
                                    ? null
                                    : _openSavedReview,
                                allDoneCtaLabel: t.homeEmptyCta,
                              ),
                            ),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── A + B. 헤더(워드마크·스트릭/레벨 칩·설정) + 캐릭터 히어로 ──
                            //
                            // `verticalDirection: up` = **배치는 그대로, paint 순서만 역전**.
                            // children 은 목록 순서대로 그려지지만 배치는 아래→위라서,
                            // 화면에는 여전히 [헤더 → 인사 → 말풍선 → 영상] 으로 보이고
                            // 그리는 순서는 [영상 → 말풍선 → 인사 → 헤더] 가 된다.
                            //
                            // 이유(2026-08-06 Jin 실기기, M2101K6G/Android 12): 히어로에
                            // 영상이 실제로 재생되기 시작하자 **그보다 먼저 그려지는**
                            // 로고·스트릭·레벨 칩·설정 아이콘·인사말이 통째로 사라졌다
                            // (자리는 그대로 비어 있고 미션 카드 등 뒤에 그려지는 것만 정상).
                            // 안드로이드 영상 텍스처 합성 문제라 Dart 쪽에서 고칠 수 있는
                            // 건 **순서뿐** — 헤더/텍스트를 영상보다 나중에 그리게 해서
                            // 구조적으로 차단한다. 시각 결과는 동일하므로 원인이 다르더라도
                            // 부작용이 없다.
                            // 2열: 히어로와 미션을 같은 행에 둔다. `verticalDirection`
                            // 은 **양쪽 분기 모두** 유지해야 한다 — 위 주석의 영상
                            // 텍스처 문제는 열 개수와 무관하고, 행 안의 영상이
                            // `_TopBar` 보다 먼저 그려져야 하는 조건은 그대로다.
                            if (twoColumn)
                              Column(
                                verticalDirection: VerticalDirection.up,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(child: heroBand),
                                      const SizedBox(width: kHomeColumnGap),
                                      Expanded(child: missionCard),
                                    ],
                                  ),
                                  topBar,
                                ],
                              )
                            else ...[
                              Column(
                                verticalDirection: VerticalDirection.up,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                // The outer reversed paint order is a real
                                // Android video-compositor safeguard: the
                                // clip paints before the header and mission.
                                // Visually, however, phone learners still see
                                // Today and its one action before the
                                // decorative character band.
                                children: [
                                  heroBand,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      topBar,
                                      const SizedBox(height: Spacing.sm),
                                      Text(
                                        _todayHeading(t),
                                        key: const ValueKey(
                                          'home-today-heading',
                                        ),
                                        style: SoriTextTheme.of(context).h2,
                                      ),
                                      const SizedBox(height: Spacing.sm),
                                      missionCard,
                                      const SizedBox(height: Spacing.lg),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: Spacing.lg),

                            HomeBuildNote(
                              key: const ValueKey('home-hanok-build-note'),
                              narrative: _hanokNarrative,
                            ),
                            if (_dueCount > 0 &&
                                _todaySnapshot?.pick is! ReviewPick) ...[
                              const SizedBox(height: Spacing.md),
                              _HomeLaterTodayNote(dueCount: _dueCount),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. 매화 입자 — **콘텐츠 위**에 그린다.
          // 캐릭터 mp4 는 한지색 매트를 미리 합성한 **불투명 사각형**이라,
          // 입자를 아래 깔면 꽃잎이 히어로 영상 경계에서 사라졌다 반대편에서
          // 다시 나타난다(2026-08-06). 위로 올리면 캐릭터 앞을 스치듯 지나가
          // 의도한 앰비언트가 되고, IgnorePointer 라 탭도 안 가로챈다.
          // 시네마틱(아래 6번)보다는 **먼저** 그려야 토스트가 위에 남는다.
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 14)),
          ),

          // ── 5. (Flying-Magpie-Overlay entfernt — Jin 2026-08-06:
          //        nicht-Video-Elster raus, Charakter nur als Video-Hero) ──

          // ── 6. Hanok-Cinematic — Phase 3 stage transition ──
          // Wird einmalig pro neuem Stage gezeigt (Storage gating).
          if (_pendingCinematicStage != null && !_cinematicShown)
            Positioned.fill(
              child: HanokCinematic(
                current: _pendingCinematicStage!,
                onDone: () {
                  if (!mounted) return;
                  setState(() {
                    _cinematicShown = true;
                    _pendingCinematicStage = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// [tourKey] 가 있을 때만 [KeyedSubtree] 로 한 겹 감싼다.
///
/// 코치마크는 타겟을 측정할 GlobalKey 가 필요한데, 그 키를 기존 위젯에
/// 직접 붙이면 위젯 정체성이 바뀌어 상태가 날아간다. 밖에 한 겹 씌우면
/// 측정 위치는 같고 안쪽 트리는 그대로다.
class _MaybeKeyed extends StatelessWidget {
  final GlobalKey? tourKey;
  final Widget child;

  const _MaybeKeyed({required this.tourKey, required this.child});

  @override
  Widget build(BuildContext context) {
    if (tourKey == null) {
      return child;
    }
    return KeyedSubtree(key: tourKey, child: child);
  }
}

/// 홈 한옥 미리보기 지도의 **폭 상한**(dp).
///
/// 폰의 480dp 컬럼에서 카드 안쪽 폭은 480 − 좌우 여백(Spacing.lg×2 = 32)
/// − 카드 패딩(Spacing.lg×2 = 32) ≈ 416dp 라 이 상한에 걸리지 않는다
/// (= 폰 시각 변화 0). 640dp 태블릿 컬럼에서만 걸려 4:3 높이가 약 1/4 줄어든다.
const double kHanokPreviewMaxWidth = 440;

// ── 홈 2열(expanded) 레이아웃 ─────────────────────────────────────────────
//
// 기준은 **화면 폭이 아니라 실제 콘텐츠 영역 폭**이다. 홈은 `AppShell` 안에서
// NavigationRail(96dp) 오른쪽에 놓이고 좌우 clamp padding 도 먹으므로, 화면
// 폭으로 분기하면 실제로 쓸 수 있는 폭과 어긋난다(1280dp 화면의 홈 콘텐츠는
// 1184dp 가 아니라 clamp 후의 값). 그래서 `LayoutBuilder` 가 돌려주는
// `constraints.maxWidth` 로만 판정한다.

/// 두 열 사이 간격.
const double kHomeColumnGap = Spacing.xl;

/// 2열에서 오른쪽(보조) 열이 가져야 할 최소 폭.
///
/// 한옥 행의 진행률 열이 `"Dein Hanok ist zu 100 % gebaut"` 한 줄과 CTA 버튼을
/// 담아야 해서, 이보다 좁아지면 독일어가 3줄로 접힌다.
const double kHomeSideColumnMinWidth = 280;

/// 2열로 전환할 **콘텐츠 영역** 최소 폭.
///
/// 가장 넓은 요구를 갖는 행이 한옥이다 — 지도 상한([kHanokPreviewMaxWidth])
/// + 간격 + 보조 열 최소폭. 히어로+미션 행은 이 폭이면 각 열 360dp 로
/// 폰 컬럼(328dp)보다 넓으므로 자동으로 충족된다.
const double kHomeTwoColumnMinWidth =
    kHanokPreviewMaxWidth + kHomeColumnGap + kHomeSideColumnMinWidth;

/// 2열일 때 콘텐츠 컬럼 상한.
///
/// 공용 [soriAdaptiveContentMaxWidth] 는 720dp 이상에서 640dp 로 **고정**이라
/// 1280dp 태블릿에서 화면의 52.5% 가 빈 여백이 됐다(2026-08-07 실측). 2열
/// 경로에서만 이 상한을 올린다 — 열 하나가 480dp(= [SoriBreakpoints.content],
/// 폰 컬럼 상한)를 넘지 않는 선이 기준이다: 480×2 + 간격 24 = 984.
const double kHomeTwoColumnContentMaxWidth = 984;

/// 홈 콘텐츠 컬럼 상한. [available] 은 clamp **바깥** 가용 폭.
///
/// 2열이 실제로 들어가지 않는 폭에서는 공용 적응 폭을 그대로 돌려주므로
/// compact/medium 은 **시각 변화 0** 이다.
double _homeContentMaxWidth(double available) {
  const double horizontalPadding = Spacing.lg * 2;
  final bool canTwoColumn =
      available - horizontalPadding >= kHomeTwoColumnMinWidth;
  if (!canTwoColumn) {
    return soriAdaptiveContentMaxWidth(available);
  }
  return kHomeTwoColumnContentMaxWidth;
}

/// Compact, read-only construction note kept on the focused Today surface.
/// The full map stays available in the dedicated Hanok destination.
class HomeBuildNote extends StatelessWidget {
  const HomeBuildNote({super.key, required this.narrative});

  final HanokBuildNarrative? narrative;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final value = narrative;
    final note =
        value?.verifiedUnit?.canDo.pick(languageCode) ??
        value?.nextUnit?.canDo.pick(languageCode) ??
        t.homeHanokPreviewBody;
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.foundation_outlined, color: SoriColors.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.homeFocusBuildTitle, style: text.label),
                const SizedBox(height: Spacing.xs),
                Text(note, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLaterTodayNote extends StatelessWidget {
  const _HomeLaterTodayNote({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.homeFocusLaterTitle, style: text.label),
          const SizedBox(height: Spacing.xs),
          Text(t.homeFocusLaterBody(dueCount), style: text.bodySmall),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// B. Character hero — greeting + 말풍선 + 캐릭터 클립 밴드
// ════════════════════════════════════════════════════════════════════════

/// 라이트 모드 홈 배경색 — **영상의 실측 매트와 같은 값**(반대가 아니다).
///
/// 근거와 계약은 [HomeHeroClips.matte] 주석에 있다. 요약: 홈 히어로는 매트를
/// 미리 합성한 불투명 mp4 이고, Android 가 그걸 `#FBF5EB` 로 렌더한다. 배경이
/// 이 값이 아니거나 균일하지 않으면 영상 사각형이 액자처럼 뜬다.
///
/// ⚠️ `SoriColors.lightBg`(#FAF6EC) 자체를 바꾸지 않는 이유: 그건 앱 전체
///    배경이라 이 1 차이를 모든 화면에 퍼뜨린다. 홈에서만 맞춘다.
///
/// ⚠️ 이 색 위에 **어떤 그라데이션·glow·틴트도 겹치면 안 된다.** 겹치는 순간
///    영상 사각형만 그 효과를 못 받아 경계가 드러난다. 2026-08-12 실측 기준.
const Color _kHeroMatte = HomeHeroClips.matte;

/// 다크 모드 radial glow 의 시작 위치(dp, 화면 최상단 기준).
///
/// **다크 전용이다.** 라이트에서는 glow 자체를 안 그린다 — 실측 밴드 바닥이
/// 678dp 라 이 값(500)으로는 겹침을 못 피했고, 애초에 밴드 위치가 미션 카드
/// 높이·글자 배율·스크롤에 따라 움직여서 어떤 고정 dp 로도 못 피한다.
/// 다크는 히어로가 투명 배경 PNG 라 겹쳐도 이음매가 안 생긴다.
const double _kHeroBandBottomDp = 500;

/// 계(契) 진입 — 내 계 목록 + 만들기/입장 선택 바텀시트. plan §7.3.
Future<void> showGyeChooser(BuildContext context) async {
  // GDPR-K: 16세 미만은 계 진입 차단(생년 미상 시 입력 요청). 서비스도 backstop.
  if (!await ensureGyeAgeAllowed(context)) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final t = AppL10n.of(context);
  showSoriSheet<void>(
    context: context,
    builder: (sheetCtx) => FutureBuilder<List<GyeMeta>>(
      future: GyeService.myGyeMetas(),
      builder: (ctx, snap) {
        final mine = snap.data ?? const <GyeMeta>[];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.md),
            Text(t.gyeChooserTitle, style: SoriTextTheme.of(context).h3),
            const SizedBox(height: Spacing.sm),
            for (final g in mine)
              ListTile(
                leading: const Icon(
                  Icons.groups_2_outlined,
                  color: SoriColors.primary,
                ),
                title: Text(g.name),
                subtitle: Text(g.code),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(context).pushNamed('/gye', arguments: g.id);
                },
              ),
            if (mine.isNotEmpty) const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.add_home_outlined,
                color: SoriColors.primary,
              ),
              title: Text(t.gyeChooserCreate),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                Navigator.of(context).pushNamed('/gye/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login_rounded, color: SoriColors.info),
              title: Text(t.gyeChooserJoin),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                Navigator.of(context).pushNamed('/gye/join');
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
        );
      },
    ),
  );
}
