import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../data/hangul_strokes.dart';
import '../models/personal_hanok.dart';
import '../models/feedback_completion.dart';
import '../models/gye.dart';
import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import '../services/data_loader.dart';
import '../services/decoration_reward_service.dart';
import '../services/mission_recommender.dart';
import '../services/pack_access.dart';
import '../services/gye_service.dart';
import '../services/daily_char_service.dart';
import '../services/pack_progress_service.dart';
import '../services/personalized_lesson_service.dart';
import '../services/premium_service.dart';
import '../services/quest_tracker.dart';
import '../services/smalltalk_loader.dart';
import '../services/hanok_stage_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/today_learning_snapshot.dart';
import '../services/vocab_pack_service.dart';
import 'daily_char_sheet.dart';
import 'review_session_screen.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/hanok_cinematic.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_hero_card.dart';
import '../widgets/sori/week_progress.dart';
import '../widgets/sori/path_preview_row.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/personal_hanok_map.dart';
import '../widgets/sori/path_trail.dart';
import '../widgets/sori/pending_reward_card.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/sheet.dart';
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
class HomeScreen extends StatefulWidget {
  /// AppShell이 스포트라이트 투어 타겟으로 전달하는 학습경로 섹션 키.
  /// null이면 KeyedSubtree 래핑 없이 그냥 렌더 (독립 실행 등).
  final GlobalKey? pathTourKey;
  final String? dailyCharacter;
  final Future<TodayLearningSnapshot> Function()? loadTodaySnapshot;
  final Future<LevelRatios> Function()? loadHanokRatios;

  // Stage B 예약: final GlobalKey? bookTourKey;

  const HomeScreen({
    super.key,
    this.pathTourKey,
    this.dailyCharacter,
    this.loadTodaySnapshot,
    this.loadHanokRatios,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TodayLearningSnapshot? _todaySnapshot;
  PersonalHanokProjection? _hanokProjection;
  bool _loadingTodaySnapshot = true;
  int _dueCount = 0; // M2: heute fällige + neue SRS-Karten ("Heute lernen")
  int _hardCount = 0; // A2: "어려운 단어"(leech) 개수
  int _openableBoxes = 0; // 열 수 있는 보자기(퀘스트 보상) 개수 — 홈 배너 게이트

  // E1a. Lernpfad 홈 임베드 — 현재 레벨 단어팩 노드 리스트.
  List<({VocabPack pack, PackProgress progress})> _pathNodes = [];
  String? _nowPackId;

  /// Q2: Tageskurs 전용 카드 — 이번 주 첫 홈 세션에만 true(주 1회 노출).
  bool _courseCardThisWeek = false;

  // Phase 3 (stately-rising-jongga) — Hanok-Cinematic gating.
  HanokStage? _pendingCinematicStage;
  bool _cinematicShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToday();
    _loadPath();
    _loadHanokPreview();
    _checkHanokCinematic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntroFlows());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 공부→백그라운드→재개 시 그새 생산된 보자기·성장을 끌어온다. _refreshHome
    // 이 syncEarnedRewards 를 돌리고 openableBoxCount 를 재독해 배너에 반영한다.
    if (state == AppLifecycleState.resumed && mounted) {
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
    if (mounted) {
      // 방금 떨어뜨린 마일스톤 보자기를 배너에 즉시 반영한다.
      setState(
        () => _openableBoxes = DecorationRewardService.openableBoxCount(),
      );
    }
  }

  /// E1a: 현재 레벨의 단어팩 노드 로드.
  /// 첫 미완·잠금해제 팩이 속한 레벨의 view를 홈에 임베드한다.
  /// 다 클리어됐으면 마지막 레벨(B2)의 view를 보여준다.
  Future<void> _loadPath() async {
    try {
      const levels = ['A1', 'A2', 'B1', 'B2'];
      String? nowId;
      List<({VocabPack pack, PackProgress progress})> nodes = [];

      for (final lv in levels) {
        final view = await PackProgressService.loadLevelView(lv);
        for (final e in view) {
          if (nowId == null &&
              e.progress.status != PackStatus.cleared &&
              e.progress.status != PackStatus.locked) {
            nowId = e.pack.id;
            nodes = view;
          }
        }
        if (nowId != null) {
          break;
        }
        // 이 레벨이 다 클리어됐으면 다음 레벨로
        nodes = view; // 계속 갱신 — 다 클리어 시 마지막 레벨로 남음
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _pathNodes = nodes;
        _nowPackId = nowId;
      });
    } catch (_) {
      // best-effort — 로드 실패 시 _pathNodes 빈 상태 유지 → _PathCard fallback
    }
  }

  Future<void> _checkHanokCinematic() async {
    final stage = await HanokStageService.currentStage();
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
      projection = PersonalHanokProjection.from(await loadRatios());
    } catch (_) {
      projection = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      );
    }
    if (mounted) {
      setState(() => _hanokProjection = projection);
    }
  }

  /// Loads the same read-only recommendation snapshot as the Sarangbang.
  ///
  /// Home only previews the selected mission and keeps its CTA pointed at the
  /// Sarangbang; the snapshot does not turn Home into a second route chooser.
  Future<void> _loadToday() async {
    if (mounted) {
      setState(() => _loadingTodaySnapshot = true);
    }
    try {
      final load = widget.loadTodaySnapshot ?? TodayLearningSnapshotLoader.load;
      final snapshot = await load();
      if (!mounted) {
        return;
      }

      // Q2: Tageskurs 전용 카드 — 이번 주 첫 홈 세션에만 노출(이후 배지만).
      final week = _isoWeek(DateTime.now());
      final showCourseCard =
          _courseCardThisWeek || Storage.courseCardWeekShown != week;
      if (!_courseCardThisWeek && showCourseCard) {
        // ignore: discarded_futures
        Storage.setCourseCardWeekShown(week);
      }

      setState(() {
        _todaySnapshot = snapshot;
        _dueCount = snapshot.dueCount;
        _hardCount = snapshot.hardCount;
        _openableBoxes = DecorationRewardService.openableBoxCount();
        _courseCardThisWeek = showCourseCard;
        _loadingTodaySnapshot = false;
      });
      // 푸시 리텐션: 데일리 리마인더 body를 최신 스트릭으로 갱신해 재예약.
      _refreshDailyReminder();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingTodaySnapshot = false);
    }
  }

  Future<void> _refreshHome() async {
    // 공부하고 돌아오면 그새 target 도달한 퀘스트의 보자기를 생산한다(퀘스트
    // 화면을 안 열어도 — 실제 근본 수리). 이후 _loadToday 가 openableBoxCount 를
    // 다시 읽어 보자기 배너에 반영한다.
    await QuestTracker.syncEarnedRewards();
    await Future.wait<void>([_loadToday(), _loadPath(), _loadHanokPreview()]);
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

  /// 스트릭 칩 탭 — 주간 디딤돌 + 오늘 목표 시트 (§6.1: 구 _StatChipRow·
  /// _DailyGoalCard 블록의 자리. 수치 전체 상세는 /stats).
  Future<void> _showWeekSheet() async {
    await showSoriSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DailyGoalCard(xpToday: Storage.xpToday, goal: Storage.dailyGoalXp),
            const SizedBox(height: Spacing.md),
            WeekSteppingStonesRow(
              streak: Storage.streakDays,
              xpToday: Storage.xpToday,
              goal: Storage.dailyGoalXp,
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() {}); // 시트에서 돌아온 뒤 최신 값 반영.
    }
  }

  // M5: personalisierter Tageskurs (Premium-gated, Laufzeit-Kosten 0 —
  // rein lokale Auswahl aus vorhandenem Content nach Schwäche + Interesse).
  Future<void> _openCourse() async {
    if (!await PremiumService.gate(context)) return;
    if (!mounted) return;
    final t = AppL10n.of(context);
    final vocab = await DataLoader.loadVocab();
    if (!mounted) return;
    final deck = PersonalizedLessonService.buildFromStorage(vocab);
    if (deck.isEmpty) return;
    // M5: interessen-passenden Small-talk-Satz als Kurs-Bonus ("한마디").
    await SmalltalkLoader.load();
    final bonus = PersonalizedLessonService.pickSmalltalk(
      SmalltalkLoader.phrases,
      levelCode: Storage.userLevelCode ?? 'A1',
      interests: Storage.interests.toSet(),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(
          deck: deck,
          title: t.homeCourseTitle,
          bonusPhrase: bonus.isNotEmpty ? bonus.first : null,
          feedbackContentId: 'personalized_course',
          feedbackContentLabel: t.homeCourseTitle,
        ),
      ),
    );
    if (mounted) _loadToday();
  }

  /// ISO 8601 주차 문자열('2026-W32') — Tageskurs 전용 카드 주 1회 가드(Q2).
  String _isoWeek(DateTime d) {
    final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
    final firstDay = DateTime(thursday.year, 1, 1);
    final week = 1 + thursday.difference(firstDay).inDays ~/ 7;
    return '${thursday.year}-W$week';
  }

  /// 시간대 — 인사 + 호랑이 emotion 결정.
  _DayPhase get _phase {
    final h = DateTime.now().hour;
    if (h < 11) return _DayPhase.morning;
    if (h < 18) return _DayPhase.afternoon;
    return _DayPhase.evening;
  }

  String _greeting(AppL10n t) {
    switch (_phase) {
      case _DayPhase.morning:
        return t.homeHeroGreetingMorning;
      case _DayPhase.afternoon:
        return t.homeHeroGreetingAfternoon;
      case _DayPhase.evening:
        return t.homeHeroGreetingEvening;
    }
  }

  /// 말풍선 텍스트 — streak·진척·학습 이유(motivation)에 따라. 순수 함수 위임.
  String _tigerBubble(AppL10n t, MascotKind kind) => homeTigerBubble(
    t,
    streak: Storage.streakDays,
    xp: Storage.xp,
    motivation: learnerMotivationFromId(Storage.motivation),
    kind: kind,
  );

  /// §6.1 블록 3 추천 엔진 — "다음 것 1개"의 단일 소스.
  /// 우선순위: ① 현재 코스 미션 > ② 진행 중 팩 > ③ due 복습(≥10) >
  /// ④ 시나리오 추천. null = 오늘 할 것 없음(allDone).
  /// 규칙 R-REC(H-6): 추천 레벨 ≤ 사용자 레벨 — 코스·팩은 순차 구조가
  /// 레벨을 보장하므로 시나리오에만 명시 가드를 둔다.
  MissionHeroContent? _missionHeroContent(AppL10n t, String lang) {
    // The shared snapshot is the only input-assembly owner. Home only turns
    // its already selected pick into presentation copy and opens Sarangbang.
    final snapshot = _todaySnapshot;
    final pick = snapshot?.pick;
    switch (pick) {
      case CoursePick c:
        return MissionHeroContent(
          kind: MissionHeroKind.course,
          title: c.unit.title.pick(lang),
          contextLabel: t.homeMadangEyebrow,
          levelCode: c.unit.level.toUpperCase(),
          meta: t.missionHeroCourseMeta(c.missionNumber, c.totalMissions),
          fraction: c.fraction,
          started: c.started,
          ctaLabel: t.homeSarangbangCta,
          onStart: () async {
            await Navigator.pushNamed(context, '/sarangbang');
            if (mounted) {
              await _refreshHome();
            }
            // 레슨 직후 달성한 마일스톤 즉시 축하 (구 주 CTA 동작 승계).
            if (mounted) {
              await _maybeCelebrateMilestone();
            }
          },
        );
      case PackPick p:
        final level = p.pack.level.toUpperCase();
        return MissionHeroContent(
          kind: MissionHeroKind.pack,
          title: VocabPackService.displayLabel(p.pack.id, lang: lang),
          contextLabel: t.homeMadangEyebrow,
          levelCode: level,
          meta: t.missionHeroPackMeta(level),
          fraction: p.fraction,
          started: true,
          ctaLabel: t.homeSarangbangCta,
          onStart: () async {
            await Navigator.pushNamed(context, '/sarangbang');
            if (mounted) {
              await _refreshHome();
            }
          },
        );
      case ReviewPick r:
        return MissionHeroContent(
          kind: MissionHeroKind.review,
          title: t.missionHeroReviewTitle(r.dueCount),
          contextLabel: t.homeMadangEyebrow,
          levelCode: null,
          meta: t.missionHeroReviewMeta,
          fraction: 0,
          started: false,
          ctaLabel: t.homeSarangbangCta,
          onStart: () async {
            await Navigator.pushNamed(context, '/sarangbang');
            if (mounted) {
              await _refreshHome();
            }
          },
        );
      case ScenarioPick sc:
        final level = sc.level.code.toUpperCase();
        return MissionHeroContent(
          kind: MissionHeroKind.scenario,
          title: snapshot?.scenario?.title.pick(lang) ?? sc.scenarioId,
          contextLabel: t.homeMadangEyebrow,
          levelCode: level,
          meta: t.missionHeroScenarioMeta(level),
          fraction: 0,
          started: false,
          ctaLabel: t.homeSarangbangCta,
          onStart: () async {
            await Navigator.pushNamed(context, '/sarangbang');
            if (mounted) {
              await _refreshHome();
            }
          },
        );
      case null:
        return null;
    }
  }

  /// §10.2 블록 4 — 현재 노드 ±1 = 3노드 슬라이스.
  /// 탭 규칙: 현재 노드 = 팩 진입(프리미엄 게이트 승계), 그 외 = `/path`
  /// (해당 노드 id를 스크롤 파라미터로 — R3에서 소비).
  List<SoriPathStop> _previewStops(String lang) {
    final i = _nowPackId == null
        ? -1
        : _pathNodes.indexWhere((e) => e.pack.id == _nowPackId);
    // 슬라이스 규칙은 순수 previewWindow(§10.2)가 담당 — 단위 테스트 고정.
    final slice = previewWindow(_pathNodes, i);
    return [
      for (final e in slice)
        SoriPathStop(
          id: e.pack.id,
          label: VocabPackService.displayLabel(e.pack.id, lang: lang),
          status: e.progress.status,
          fraction: e.progress.progressFraction,
          isNow: e.pack.id == _nowPackId,
          onTap: () async {
            if (e.pack.id != _nowPackId) {
              await Navigator.pushNamed(context, '/path', arguments: e.pack.id);
              if (mounted) {
                await _loadPath();
              }
              return;
            }
            if (!await ensurePackAccess(context, level: e.pack.level)) {
              return;
            }
            if (!mounted) {
              return;
            }
            await Navigator.pushNamed(
              context,
              '/vocab/pack',
              arguments: e.pack.id,
            );
            if (mounted) {
              await _refreshHome();
            }
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. 추상 gradient base — baked-in mascot 없음 ──
          // ⚠️ 상단 [_kHeroFlatBackdropFraction] 구간은 **평면 단색**이어야 한다.
          // 캐릭터 mp4 는 순백(#FFFFFF) 매트를 `blendColor` multiply 로 흡수하는데
          // (`CharacterClipPlayer`), multiply(흰색, C) 의 결과는 **언제나 정확히 C**
          // 단색이다. 뒤 배경이 그라데이션이면 영상 사각형만 주변보다 밝게 떠서
          // 액자처럼 보인다(2026-08-06 Jin 실기기: "영상 배경색"). 그래서 히어로가
          // 놓이는 상단은 `SoriColors.lightBg` 로 평평하게 깔고 그라데이션은 아래부터.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF14201E),
                          Color(0xFF14201E),
                          Color(0xFF0E1815),
                          Color(0xFF0A1310),
                        ]
                      : const [
                          SoriColors.lightBg,
                          SoriColors.lightBg,
                          Color(0xFFF4ECDA),
                          Color(0xFFEEDFC2),
                        ],
                  stops: const [0.0, _kHeroFlatBackdropFraction, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. Subtle radial accent — 따뜻한 빛 ──
          // 히어로 영상 밴드와 **겹치면 안 된다**(위 1번의 매트 이유와 동일:
          // 영상 사각형 안에는 이 glow 가 안 들어가고 주변에만 들어가 이음매가 생김).
          // 캐릭터 뒤가 아니라 그 아래 미션 카드 뒤를 덥힌다.
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
                      SoriColors.tiger.withValues(alpha: isDark ? 0.15 : 0.10),
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
              child: SoriContentClamp(
                base: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.xl,
                ),
                builder: (context, padding) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: padding,
                  child: Column(
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
                      Column(
                        verticalDirection: VerticalDirection.up,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 홈은 IndexedStack 안이라 설정에서 캐릭터를 바꿔도
                          // setState 가 안 온다 → notifier 를 직접 구독한다.
                          SoriEntrance(
                            delay: const Duration(milliseconds: 40),
                            child: ValueListenableBuilder<MascotKind>(
                              valueListenable: MascotPreference.kind,
                              builder: (context, kind, _) => _TigerHero(
                                greeting: _greeting(t),
                                bubble: _tigerBubble(t, kind),
                                phase: _phase,
                                kind: kind,
                              ),
                            ),
                          ),
                          // 화면상 맨 위 — 목록 마지막 = 가장 나중에 paint.
                          // (`_TopBar` 는 자체 하단 여백 Spacing.lg 를 갖고 있어
                          //  인사말과의 간격은 그대로 유지된다.)
                          _TopBar(
                            streak: Storage.streakDays,
                            level: Storage.xpLevel,
                            xp: Storage.xp,
                            onStreakTap: _showWeekSheet,
                            onStatsTap: () =>
                                Navigator.pushNamed(context, '/stats'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── C. 스탯 5종은 헤더 칩 1줄로 압축(§6.1 블록 1) —
                      // 주간 디딤돌·오늘 목표는 스트릭 칩 시트, 상세는 /stats.

                      // ── D. 오늘의 미션 히어로 — 단일 CTA (§6.1 블록 3·§10.1).
                      // 구 "Jetzt lernen" 버튼 + Today 시나리오 카드를 흡수한
                      // 추천 엔진: 코스 미션 > 진행 중 팩 > 복습 > 시나리오.
                      SoriEntrance(
                        delay: const Duration(milliseconds: 100),
                        slideY: 14,
                        child: KeyedSubtree(
                          key: const ValueKey('home-primary-sarangbang'),
                          child: MissionHeroCard(
                            loading: _loadingTodaySnapshot,
                            content: _loadingTodaySnapshot
                                ? null
                                : _missionHeroContent(t, lang),
                            allDoneCtaLabel: t.homeSarangbangCta,
                            onAnotherRound: () async {
                              await Navigator.pushNamed(context, '/sarangbang');
                              if (mounted) {
                                await _refreshHome();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── 보상 안내 — 열 수 있는 보자기가 있으면 발견 배너 ──
                      // 이게 없으면 퀘스트로 상자가 생겨도 사용자가 알 길이 없다.
                      if (_openableBoxes > 0) ...[
                        SoriEntrance(
                          delay: const Duration(milliseconds: 110),
                          slideY: 14,
                          child: PendingRewardCard(
                            count: _openableBoxes,
                            onOpen: () async {
                              await Navigator.pushNamed(context, '/bojagi');
                              if (mounted) {
                                await _refreshHome();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                      ],

                      // ── E1a. 이어지는 길 — 현재 ±1 미리보기 (§6.1 블록 4·§10.2) ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 120),
                        slideY: 14,
                        child: _HomeHanokPreview(
                          key: const ValueKey('home-hanok-preview'),
                          projection: _hanokProjection,
                          onOpen: () async {
                            await Navigator.pushNamed(context, '/hanok');
                            if (mounted) {
                              await _refreshHome();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      widget.pathTourKey != null
                          ? KeyedSubtree(
                              key: widget.pathTourKey!,
                              child: _SectionLabel(label: t.pathTitle),
                            )
                          : _SectionLabel(label: t.pathTitle),
                      const SizedBox(height: Spacing.sm),
                      if (_pathNodes.isEmpty)
                        SoriEntrance(
                          delay: const Duration(milliseconds: 120),
                          slideY: 14,
                          child: _PathCard(
                            onTap: () async {
                              await Navigator.pushNamed(context, '/path');
                              if (mounted) {
                                await _refreshHome();
                              }
                            },
                          ),
                        )
                      else
                        SoriEntrance(
                          delay: const Duration(milliseconds: 120),
                          slideY: 14,
                          // §10.2: 현재 ±1 = 3노드 미리보기. 전량 경로와
                          // 100% 트리거는 /path 전용 화면이 유지(§6.2).
                          // 히어로(블록 2)가 클립이라 미리보기는 정적 —
                          // 동시 디코더 ≤1 계약.
                          child: PathPreviewRow(
                            stops: _previewStops(lang),
                            onSeeAll: () async {
                              await Navigator.pushNamed(context, '/path');
                              if (mounted) {
                                await _loadPath();
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: Spacing.xl),

                      // ── P0-G7. Streak 0 회복 메시지 ──
                      // ⚠️ 이 카드는 "스트릭이 **끊긴**" 사용자를 되돌리는 복구
                      // 카드다("Willkommen zurück!"). 스트릭 0 조건만 보면
                      // 방금 온보딩을 끝낸 신규 사용자에게도 떠서, 첫 화면이
                      // "다시 오신 걸 환영합니다"로 시작한다(2026-07-31 발견).
                      // XP 가 쌓인 적이 있어야 "돌아온 것" — 그때만 보여준다.
                      // (1일차 인사 자체는 learner_motivation.dart:83 이 이미 분기한다.)
                      if (Storage.streakDays == 0 && Storage.xp > 0) ...[
                        SoriEntrance(
                          delay: const Duration(milliseconds: 200),
                          slideY: 14,
                          child: SoriCard(
                            variant: SoriCardVariant.hero,
                            accent: SoriColors.primary,
                            tinted: true,
                            child: Row(
                              children: [
                                ValueListenableBuilder<MascotKind>(
                                  valueListenable: MascotPreference.kind,
                                  builder: (context, kind, _) => Mascot(
                                    kind: kind,
                                    emotion: MascotEmotion.smile,
                                    size: 60,
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.homeTigerBubbleResume,
                                        style: SoriTextTheme.of(
                                          context,
                                        ).cardTitle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t.homeTigerBubbleResumeSub,
                                        style: SoriTextTheme.of(
                                          context,
                                        ).caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                      ],
                      // ── E1b. Heute lernen — due 0건이면 블록 숨김(§6.1 블록 5) ──
                      if (_dueCount > 0)
                        SoriEntrance(
                          delay: const Duration(milliseconds: 220),
                          slideY: 14,
                          child: _ReviewCard(
                            dueCount: _dueCount,
                            onTap: () async {
                              await Navigator.pushNamed(context, '/review');
                              if (mounted) await _loadToday();
                            },
                          ),
                        ),
                      // ── A2. "어려운 단어"(leech) — 있을 때만 노출 ──
                      if (_hardCount > 0) ...[
                        const SizedBox(height: Spacing.sm),
                        SoriEntrance(
                          delay: const Duration(milliseconds: 240),
                          slideY: 14,
                          child: _HardWordsCard(
                            count: _hardCount,
                            onTap: () async {
                              await Navigator.pushNamed(context, '/hard_words');
                              if (mounted) await _loadToday();
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: Spacing.md),

                      // ── E1c. Dein Tageskurs — Q2: 전용 카드는 주 1회,
                      // 상시 진입점은 미션 히어로 배지 ──
                      if (_courseCardThisWeek) ...[
                        SoriEntrance(
                          delay: const Duration(milliseconds: 260),
                          slideY: 14,
                          child: _CourseCard(onTap: _openCourse),
                        ),
                        const SizedBox(height: Spacing.md),
                      ],

                      // ── D2. 오늘의 글자 — 완료(0건)면 블록 숨김(§6.1 블록 5) ──
                      if (!Storage.calligraphyDoneToday) ...[
                        SoriEntrance(
                          delay: const Duration(milliseconds: 300),
                          slideY: 12,
                          child: _DailyCharCard(
                            char:
                                widget.dailyCharacter ??
                                DailyCharService.today(),
                            doneToday: Storage.calligraphyDoneToday,
                            onTap: () => showDailyCharSheet(context).then((_) {
                              if (mounted) setState(() {});
                            }),
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),
                      ],

                      const SizedBox(height: Spacing.xxxl),
                      Center(
                        child: Text(
                          t.footerCheer,
                          style: SoriTextTheme.of(
                            context,
                          ).caption.copyWith(color: s.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. 매화 입자 — **콘텐츠 위**에 그린다.
          // 캐릭터 mp4 는 흰 매트를 multiply 로 흡수한 **불투명 사각형**이라,
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

enum _DayPhase { morning, afternoon, evening }

/// A read-only glimpse of the learner's estate. The main Hanok screen owns
/// place selection and navigation; Home only provides one deliberate doorway.
class _HomeHanokPreview extends StatelessWidget {
  final PersonalHanokProjection? projection;
  final VoidCallback onOpen;

  const _HomeHanokPreview({
    super.key,
    required this.projection,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    // 연속(fractional) 학습 진행 — 한 팩만 클리어해도 즉시 올라가 홈에서
    // 한옥 성장이 매끄럽게 보인다(마일스톤 단위 계단식 constructionFraction 대신).
    final progress = projection?.studyFraction ?? 0;

    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.homeHanokPreviewTitle, style: text.h3),
          const SizedBox(height: 4),
          Text(t.homeHanokPreviewBody, style: text.bodySmall),
          const SizedBox(height: Spacing.md),
          if (projection == null)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaces.surfaceAlt,
                  borderRadius: SoriRadius.brLg,
                ),
              ),
            )
          else
            Semantics(
              image: true,
              label: t.homeHanokPreviewTitle,
              child: ExcludeSemantics(
                child: PersonalHanokMap(
                  projection: projection!,
                  zoneLabel: (_) => '',
                  showTargets: false,
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          SoriProgressBar(
            value: progress,
            thickness: 10,
            color: SoriColors.primary,
            animated: true,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            t.homeHanokPreviewProgress((progress * 100).round()),
            style: text.caption.copyWith(color: SoriColors.primary),
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.outlined(
            label: t.homeHanokPreviewCta,
            fullWidth: true,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// A. Top bar — compact, no big stats
// ════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final int streak;
  final int level;
  final int xp;
  final VoidCallback onStreakTap;
  final VoidCallback onStatsTap;

  const _TopBar({
    required this.streak,
    required this.level,
    required this.xp,
    required this.onStreakTap,
    required this.onStatsTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);

    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/icon-192.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Hangul Sori',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: s.text,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            // §6.1 블록 1: 스탯을 헤더 칩 1줄로 — 🔥는 아이콘으로만(이모지
            // 글리프 금지). 스트릭 칩 탭 = 주간 시트, 레벨 칩 탭 = /stats.
            _HeaderChip(
              icon: Icons.local_fire_department_rounded,
              color: SoriColors.warning,
              label: '$streak',
              semanticLabel: '$streak ${t.statsDays}',
              onTap: onStreakTap,
            ),
            const SizedBox(width: Spacing.sm),
            _HeaderChip(
              icon: Icons.stars_rounded,
              color: SoriColors.primary,
              label: 'Lv $level',
              semanticLabel: 'Lv $level · $xp XP',
              onTap: onStatsTap,
            ),
            const SizedBox(width: Spacing.sm),
            // 2026-07-31: 아이콘 4개 → 1개.
            // 학습그룹·프로필은 하단 탭(#2·#3)에 이미 있어 중복 진입점이었고
            // (SC 3.2.3), 통계는 프로필 안에서 갈 수 있다. 설정만 남긴다 —
            // 하단 탭에 없는 유일한 목적지.
            _RoundIconButton(
              icon: Icons.settings_outlined,
              semanticLabel: t.settingsTitle,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }
}

/// 헤더 스탯 칩 — 표면 v2(라이트 무테두리 + low 그림자 / 다크 테두리),
/// 시각 32dp + 상하 패딩으로 48dp 터치 타깃 확보.
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _HeaderChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SoriPressable(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isLight ? SoriColors.lightSurfaceRaised : s.surface,
              borderRadius: SoriRadius.brPill,
              boxShadow: isLight ? SoriElevation.low : null,
              border: isLight
                  ? null
                  : Border.all(color: SoriColors.darkBorderStrong, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: SoriTextTheme.of(context).label.copyWith(
                    fontSize: 12.5,
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    // 눌리는 영역은 48dp(Material 최소 권고), 보이는 원판은 40dp.
    // 이전엔 36dp 원판이 곧 터치 타깃이라 손가락으로 놓치기 쉬웠다.
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SoriPressable(
        onTap: onTap,
        haptic: SoriHaptic.selection,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: s.surface.withValues(alpha: 0.62),
                shape: BoxShape.circle,
                border: Border.all(color: SoriColors.lightBorderStrong),
              ),
              child: Icon(icon, size: 20, color: s.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// B. Character hero — greeting + 말풍선 + 캐릭터 클립 밴드
// ════════════════════════════════════════════════════════════════════════

/// 홈 배경 gradient 중 **평면 단색**으로 유지할 상단 비율.
///
/// 캐릭터 mp4 의 순백 매트는 `multiply(흰색, blendColor) = blendColor` 라
/// 언제나 정확한 단색 사각형이 된다. 그 사각형이 놓이는 구간의 배경이
/// 그라데이션이면 영상만 밝게 떠 액자처럼 보인다 → 히어로가 차지하는 상단은
/// `SoriColors.lightBg` 로 평평하게 둔다. 짧은 화면(≈640dp)에서도 밴드 하단이
/// 이 비율 안에 들어오도록 잡은 값.
const double _kHeroFlatBackdropFraction = 0.60;

/// 히어로 밴드가 끝날 수 있는 **최대** 위치(dp, 화면 최상단 기준).
///
/// 따뜻한 radial glow 를 이 아래에만 깔아 영상 사각형 주변에 색차가 안 생기게
/// 한다. glow 는 바깥 Stack 의 **화면 고정 좌표**인데 밴드 바닥은 동적이므로
/// (SafeArea + Spacing.md + TopBar 64 + 인사말 + 8 + 말풍선 + [bandHeight])
/// **상한**을 잡아야 안전하다. 최악 조합 = 상태바 ~28 + 12 + 64 + 2줄 독일어
/// 인사말 ~52 + 8 + 2줄 말풍선 ~70 + 밴드 상한 216 ≈ 450, 여기에 시스템 글자
/// 1.3배 여유를 더해 500. 값이 크면 glow 가 더 아래에서 시작할 뿐 무해하지만,
/// 작으면 밴드와 겹쳐 영상 사각형만 glow 를 못 받아 이음매가 생긴다.
const double _kHeroBandBottomDp = 500;

class _TigerHero extends StatelessWidget {
  final String greeting;
  final String bubble;
  final _DayPhase phase;

  /// 표시 캐릭터 — 말풍선 액센트·밴드·폴백이 전부 이걸 따른다.
  final MascotKind kind;

  /// Phase E — hero 탭 시 추천 팩으로 직행(있으면). null = 비탭.

  const _TigerHero({
    required this.greeting,
    required this.bubble,
    required this.phase,
    required this.kind,
  });

  MascotEmotion get _emotion {
    switch (phase) {
      case _DayPhase.morning:
        return MascotEmotion.smile;
      case _DayPhase.afternoon:
        return MascotEmotion.smile;
      case _DayPhase.evening:
        return MascotEmotion.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final media = MediaQuery.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // v6 (2026-06-03): 정적 아바타 → 살아있는 캐릭터 "마당 밴드".
    // greeting 텍스트 위 + 말풍선 + 캐릭터 클립 밴드.
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final bool veryNarrow = w < 330;
        final double greetingSize = veryNarrow ? 21.0 : 24.0;

        // Jin 2026-08-06: "크기 때문인지 위가 다 잘린다" → 밴드를 **화면 높이·폭·
        // 글자배율에 비례**하게. 고정 244dp 는 짧은 화면이나 시스템 글자 확대에서
        // 헤더·인사말을 첫 화면 밖으로 밀어냈다. 상한도 244 → 216 으로 낮춘다.
        final double textScale = media.textScaler.scale(16) / 16;
        final double byHeight = media.size.height * 0.24;
        final double byWidth = w * 0.60;
        final double bandHeight = (byHeight < byWidth ? byHeight : byWidth)
            .clamp(
              veryNarrow ? 148.0 : 164.0,
              textScale > 1.15 ? 188.0 : 216.0,
            );

        // 짧은 대사(예: "Jedes Wort…")는 한 줄에 들어가게 말풍선 폭을 넓힌다.
        final double bubbleMax = (w * 0.92).clamp(240.0, 360.0);

        final greetingText = Text(
          greeting,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: greetingSize,
            fontWeight: FontWeight.w900,
            color: s.text,
            letterSpacing: -0.7,
            height: 1.05,
          ),
          // §4.3: 독일어 복합어 말줄임 방지 — 2줄 허용.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

        // §6.1 블록 2 발화 단일화(H-4): 서브카피 폐지 — 발화는 말풍선 1개만.
        // 말풍선을 캐릭터 *위*에 두고 아래로 꼬리를 내려 지시한다(얼굴 안 가림).
        final speechBubble = Center(
          child: _SpeechBubble(
            text: bubble,
            maxWidth: bubbleMax,
            accent: kind == MascotKind.magpie
                ? SoriColors.highlight
                : SoriColors.tigerOnLight,
          ),
        );

        // 캐릭터 밴드 — Jin 2026-08-06: 홈 히어로 = 캐릭터별 **단일 클립 루프**.
        // 까치=magpie_walking_front, 호랑이(태고)=tiger_rise. bob2↔bob3 교대는 클립 사이
        // 디코더 핸드오프마다 정적 폴백이 번쩍여 폐지 → 루프는 핸드오프가 없다.
        // staticFallback:false → 로드 전/실패에도 흰 박스 대신 투명(배경 그대로).
        // ⚠️ 단 reduce-motion 에서는 켠다. 영상 lease 가 `!reduceMotion` 을 요구해
        // (video_lease.dart) 접근성 설정 사용자는 영상을 아예 못 받는데, 폴백까지
        // 꺼 두면 히어로 밴드가 통째로 빈칸이 된다.
        final band = SizedBox(
          height: bandHeight,
          width: double.infinity,
          child: Center(
            child: isDark
                // multiply 블렌드는 **밝은 배경 전용**(AGENTS·tiger_video.dart).
                // 다크에서 흰 매트를 크림으로 곱하면 어두운 배경 위에 밝은 사각형이
                // 그대로 뜬다 → 다크는 정적 마스코트로 간다.
                ? Mascot(
                    kind: kind,
                    emotion: _emotion,
                    size: bandHeight * 0.92,
                    animate: true,
                  )
                : CharacterClipPlayer(
                    key: ValueKey('home_hero_${kind.name}'),
                    asset: kind == MascotKind.magpie
                        ? CharacterClips.magpieWalkingFront
                        : CharacterClips.tigerRise,
                    size: bandHeight,
                    loop: true,
                    staticFallback: CharacterClipPlayer.videoUnavailable(
                      context,
                    ),
                    // 흰 매트 multiply 결과 = 정확히 이 색. 홈 배경 상단의
                    // **평면 구간과 같은 상수**여야 이음매가 사라진다
                    // (`build` 의 gradient 주석 참고). `s.bg` 가 아니라 상수인
                    // 이유: 배경 gradient 도 팔레트 무관 상수이기 때문.
                    blendColor: SoriColors.lightBg,
                    fallbackKind: kind,
                    fallbackEmotion: _emotion,
                  ),
          ),
        );

        // `verticalDirection: up` — 배치는 [인사 → 말풍선 → 밴드] 그대로,
        // paint 순서만 [밴드 → 말풍선 → 인사] 로 역전. 이유는 홈 `build` 의
        // 헤더+히어로 블록 주석 참고(영상 텍스처가 먼저 그린 형제를 가리는 건).
        return Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            band,
            speechBubble,
            SizedBox(height: veryNarrow ? 6 : 8),
            greetingText,
          ],
        );
      },
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final double maxWidth;

  /// 캐릭터 액센트 — 테두리·꼬리에 쓴다. 호랑이/까치가 눈에 띄게 갈리는 지점.
  final Color accent;
  const _SpeechBubble({
    required this.text,
    this.maxWidth = 220,
    this.accent = SoriColors.tigerOnLight,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white.withValues(alpha: 0.94) : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.42),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF1F1A14) : s.text,
              height: 1.35,
              letterSpacing: -0.1,
            ),
          ),
        ),
        // 아래로 향하는 작은 꼬리 → 호랑이를 가리킴.
        CustomPaint(size: const Size(16, 7), painter: _BubbleTailPainter(bg)),
      ],
    );
  }
}

/// 말풍선 아래 꼬리(중앙, 아래 방향).
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}

// ════════════════════════════════════════════════════════════════════════
// D. Daily char (compact)
// ════════════════════════════════════════════════════════════════════════
class _DailyCharCard extends StatelessWidget {
  final String char;
  final bool doneToday;
  final VoidCallback onTap;

  const _DailyCharCard({
    required this.char,
    required this.doneToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.hangul,
      tinted: !doneToday,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.hangul.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              char,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: SoriColors.hangul,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dailyCharTitle,
                  style: SoriTextTheme.of(context).cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  doneToday
                      ? t.dailyCharDoneToday
                      : hangulStrokes[char]?.isNotEmpty == true
                      ? t.dailyCharSubtitle
                      : t.dailyCharFallbackSubtitle,
                  style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                    color: doneToday ? SoriColors.success : null,
                    fontWeight: doneToday ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          if (doneToday)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: SoriColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: SoriColors.hangul.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// E1b. "Heute lernen" review card (M2) — fällige SRS-Karten → /review
// ════════════════════════════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback onTap;
  const _ReviewCard({required this.dueCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final has = dueCount > 0;
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.gold,
      tinted: has,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.refresh_rounded,
              color: SoriColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.homeReviewTitle,
                  style: SoriTextTheme.of(context).cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  has ? t.homeReviewDue(dueCount) : t.homeReviewDone,
                  style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                    color: has ? SoriColors.gold : SoriColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            has ? Icons.chevron_right_rounded : Icons.check_circle_rounded,
            color: has
                ? SoriColors.gold.withValues(alpha: 0.8)
                : SoriColors.success,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// E1a. Lernpfad(학습 경로) 진입 카드 — 진척 시각화 화면(/path)으로
// ════════════════════════════════════════════════════════════════════════
class _PathCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PathCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      tinted: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.route_rounded,
              color: SoriColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.homePathCardTitle,
                  style: SoriTextTheme.of(context).cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  t.homePathCardSub,
                  style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                    color: SoriColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: SoriColors.primary.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════
// A2. "어려운 단어"(leech) 카드 — 반복해도 안 외워지는 단어 집중 복습
// ════════════════════════════════════════════════════════════════════════
class _HardWordsCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _HardWordsCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.danger,
      tinted: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.danger.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bolt_rounded,
              color: SoriColors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.hardWordsTitle,
                  style: SoriTextTheme.of(context).cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  t.hardWordsSubtitle(count),
                  style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                    color: SoriColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: SoriColors.danger.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// E1c. "Dein Tageskurs" (M5) — personalisierter Kurs, Premium-gated
// ════════════════════════════════════════════════════════════════════════
class _CourseCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CourseCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final isPro = PremiumService.isPremium;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.tiger,
      tinted: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SoriColors.tiger.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(SoriRadius.md),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: SoriColors.tiger,
                size: 26,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.homeCourseTitle,
                          style: SoriTextTheme.of(
                            context,
                          ).h3.copyWith(fontWeight: FontWeight.w900),
                          // §4.3: 2줄 허용.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isPro) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SoriColors.gold,
                            borderRadius: BorderRadius.circular(
                              SoriRadius.pill,
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.homeCourseDesc,
                    style: SoriTextTheme.of(
                      context,
                    ).cardSubtitle.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isPro ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
              color: SoriColors.tiger.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ════════════════════════════════════════════════════════════════════════
// Section label
// ════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: SoriTextTheme.of(context).label.copyWith(
          color: s.textMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
