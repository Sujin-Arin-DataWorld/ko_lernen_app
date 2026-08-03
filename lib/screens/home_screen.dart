import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../data/hangul_strokes.dart';
import '../models/feedback_completion.dart';
import '../models/gye.dart';
import '../models/hanok_stage.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/pack_progress.dart';
import '../models/scenario.dart';
import '../models/vocab_pack.dart';
import '../services/data_loader.dart';
import '../services/course_progress_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/gye_service.dart';
import '../services/daily_char_service.dart';
import '../services/pack_progress_service.dart';
import '../services/personalized_lesson_service.dart';
import '../services/premium_service.dart';
import '../services/smalltalk_loader.dart';
import '../services/hanok_stage_service.dart';
import '../services/review_deck_service.dart';
import '../services/scenario_loader.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import 'daily_char_sheet.dart';
import 'review_session_screen.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/flying_magpie.dart';
import '../widgets/sori/hanok_cinematic.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_hero_card.dart';
import '../widgets/sori/path_preview_row.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/path_trail.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/motivation_sheet.dart';
import '../widgets/sori/milestone_celebration.dart';
import '../data/learner_motivation.dart';
import '../data/milestone.dart';
import '../widgets/sori/tiger_video.dart';
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

  // Stage B 예약: final GlobalKey? bookTourKey;

  const HomeScreen({super.key, this.pathTourKey, this.dailyCharacter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Scenario? _today;
  bool _loadingScenario = true;
  int _dueCount = 0; // M2: heute fällige + neue SRS-Karten ("Heute lernen")
  int _hardCount = 0; // A2: "어려운 단어"(leech) 개수

  // 시나리오 추천(소스 ④) 가드용 — 완료 시나리오 집합.
  Set<String> _completed = const {};

  // E1a. Lernpfad 홈 임베드 — 현재 레벨 단어팩 노드 리스트.
  List<({VocabPack pack, PackProgress progress})> _pathNodes = [];
  String? _nowPackId;

  // 블록 3(§6.1) 추천 엔진 소스 ① — 코스 커리큘럼 카탈로그·진행 스냅샷.
  CurriculumCatalog? _courseCatalog;
  CourseMasterySnapshot? _courseSnapshot;
  bool _loadingCourse = true;

  /// Q2: Tageskurs 전용 카드 — 이번 주 첫 홈 세션에만 true(주 1회 노출).
  bool _courseCardThisWeek = false;

  // Phase 3 (stately-rising-jongga) — Hanok-Cinematic gating.
  HanokStage? _pendingCinematicStage;
  bool _cinematicShown = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadPath();
    _loadCourse();
    _checkHanokCinematic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntroFlows());
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
      setState(() {});
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

  /// 블록 3 소스 ① — 코스 카탈로그·진행 스냅샷 로드.
  /// 실패 시 오류 카드를 띄우지 않고 조용히 다음 소스로 폴백한다(§10.1).
  Future<void> _loadCourse() async {
    try {
      final catalog = await CurriculumCatalog.load();
      final snap = await CourseProgressService.shared.refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _courseCatalog = catalog;
        _courseSnapshot = snap;
        _loadingCourse = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingCourse = false);
    }
  }

  Future<void> _checkHanokCinematic() async {
    final stage = await HanokStageService.currentStage();
    if (!mounted) return;
    final shouldShow = await HanokCinematic.shouldShow(stage);
    if (!shouldShow || !mounted) return;
    setState(() => _pendingCinematicStage = stage);
  }

  Future<void> _loadToday() async {
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completed = Storage.completedScenarios.toSet();

    Scenario? pick;
    for (final s in list.where((s) => s.level == userLevel)) {
      if (!completed.contains(s.id)) {
        pick = s;
        break;
      }
    }
    if (pick == null) {
      for (final s in list) {
        if (!completed.contains(s.id)) {
          pick = s;
          break;
        }
      }
    }
    pick ??= list.isEmpty ? null : list.first;

    // M2/A1: "Heute lernen" — fällige + neue SRS-Karten. A1: CSV + 나만의 단어장
    // + 책 한 컷 단어 모두 포함. A2: "어려운 단어"(leech) 개수도 함께 계산.
    int dueCount = 0;
    int hardCount = 0;
    try {
      final all = await ReviewDeckService.allReviewable();
      if (!mounted) return;
      final koreans = all.map((v) => v.korean);
      dueCount = Storage.todayGoalIds(koreans).length;
      hardCount = Storage.hardIds(koreans).length;
    } catch (_) {
      /* best-effort; ohne Vokabeln einfach 0 */
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
      _today = pick;
      _completed = completed;
      _dueCount = dueCount;
      _hardCount = hardCount;
      _courseCardThisWeek = showCourseCard;
      _loadingScenario = false;
    });

    // 푸시 리텐션: 데일리 리마인더 body를 최신 스트릭으로 갱신해 재예약.
    _refreshDailyReminder();
    // 팩 진행도 새로고침 (RefreshIndicator → pull-to-refresh 시 동기화).
    // ignore: discarded_futures
    _loadPath();
    // 코스 스냅샷 새로고침 (미션 히어로 소스 ①).
    // ignore: discarded_futures
    _loadCourse();
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
            _DailyGoalCard(
              xpToday: Storage.xpToday,
              goal: Storage.dailyGoalXp,
            ),
            const SizedBox(height: Spacing.md),
            _SteppingStonesRow(
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

  /// Hero tap opens the course-first mission rather than a free library pack.
  Future<void> _onHeroTap() async {
    await Navigator.pushNamed(context, '/course/mission');
    if (mounted) {
      await _loadToday();
      await _loadPath();
    }
  }

  /// §6.1 블록 3 추천 엔진 — "다음 것 1개"의 단일 소스.
  /// 우선순위: ① 현재 코스 미션 > ② 진행 중 팩 > ③ due 복습(≥10) >
  /// ④ 시나리오 추천. null = 오늘 할 것 없음(allDone).
  /// 규칙 R-REC(H-6): 추천 레벨 ≤ 사용자 레벨 — 코스·팩은 순차 구조가
  /// 레벨을 보장하므로 시나리오에만 명시 가드를 둔다.
  MissionHeroContent? _missionHeroContent(AppL10n t, String lang) {
    // ① 현재 코스 미션 — 구 주 CTA가 가던 /course/mission 커리큘럼.
    final catalog = _courseCatalog;
    final snap = _courseSnapshot;
    if (catalog != null && snap != null && catalog.courseUnits.isNotEmpty) {
      final total = catalog.courseUnits.length;
      final completed = snap.completedUnitIds.toSet();
      CourseUnit? unit = snap.currentCourseUnitId == null
          ? null
          : catalog.courseUnitFor(snap.currentCourseUnitId!);
      if (unit == null && completed.length < total) {
        // 진단 전(스냅샷 비어 있음) — order 순 첫 미완 미션.
        final remaining =
            catalog.courseUnits
                .where((u) => !completed.contains(u.id))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        if (remaining.isNotEmpty) {
          unit = remaining.first;
        }
      }
      if (unit != null) {
        // clamp()는 num을 돌려줘 int 파라미터와 안 맞는다 — 순수 int 연산.
        final n = completed.length + 1 > total ? total : completed.length + 1;
        return MissionHeroContent(
          kind: MissionHeroKind.course,
          title: unit.title.pick(lang),
          levelCode: unit.level.toUpperCase(),
          meta: t.missionHeroCourseMeta(n, total),
          fraction: completed.length / total,
          started: completed.isNotEmpty,
          onStart: () async {
            await Navigator.pushNamed(context, '/course/mission');
            if (mounted) {
              await _loadToday();
              await _loadPath();
            }
            // 레슨 직후 달성한 마일스톤 즉시 축하 (구 주 CTA 동작 승계).
            if (mounted) {
              await _maybeCelebrateMilestone();
            }
          },
        );
      }
    }
    // ② 진행 중 팩 — 시작했고 아직 안 끝난 현재 노드.
    final nowId = _nowPackId;
    if (nowId != null) {
      for (final e in _pathNodes) {
        if (e.pack.id != nowId) {
          continue;
        }
        if (e.progress.progressFraction > 0 &&
            e.progress.status != PackStatus.cleared) {
          final level = e.pack.level.toUpperCase();
          return MissionHeroContent(
            kind: MissionHeroKind.pack,
            title: VocabPackService.displayLabel(e.pack.id, lang: lang),
            levelCode: level,
            meta: t.missionHeroPackMeta(level),
            fraction: e.progress.progressFraction,
            started: true,
            onStart: () async {
              if (level != 'A1' && !PremiumService.isPremium) {
                final ok = await PremiumService.gate(context);
                if (!ok) {
                  return;
                }
              }
              if (!mounted) {
                return;
              }
              await Navigator.pushNamed(
                context,
                '/vocab/pack',
                arguments: nowId,
              );
              if (mounted) {
                await _loadToday();
                await _loadPath();
              }
            },
          );
        }
        break;
      }
    }
    // ③ 오늘 복습 — due 카드가 10개 이상일 때만 미션으로 승격.
    if (_dueCount >= 10) {
      return MissionHeroContent(
        kind: MissionHeroKind.review,
        title: t.missionHeroReviewTitle(_dueCount),
        levelCode: null,
        meta: t.missionHeroReviewMeta,
        fraction: 0,
        started: false,
        onStart: () async {
          await Navigator.pushNamed(context, '/review');
          if (mounted) {
            await _loadToday();
          }
        },
      );
    }
    // ④ 시나리오 추천 — R-REC: 레벨 초과 추천 금지(H-6).
    final today = _today;
    if (today != null && !_completed.contains(today.id)) {
      final userLevel =
          LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
      if (today.level.index <= userLevel.index) {
        final level = today.level.code.toUpperCase();
        return MissionHeroContent(
          kind: MissionHeroKind.scenario,
          title: today.title.pick(lang),
          levelCode: level,
          meta: t.missionHeroScenarioMeta(level),
          fraction: 0,
          started: false,
          onStart: () async {
            await Navigator.pushNamed(
              context,
              '/scenario',
              arguments: today.id,
            );
            if (mounted) {
              await _loadToday();
            }
          },
        );
      }
    }
    return null;
  }

  /// §10.2 블록 4 — 현재 노드 ±1 = 3노드 슬라이스.
  /// 탭 규칙: 현재 노드 = 팩 진입(프리미엄 게이트 승계), 그 외 = `/path`
  /// (해당 노드 id를 스크롤 파라미터로 — R3에서 소비).
  List<SoriPathStop> _previewStops(String lang) {
    if (_pathNodes.isEmpty) {
      return const [];
    }
    var i = _nowPackId == null
        ? _pathNodes.length - 1
        : _pathNodes.indexWhere((e) => e.pack.id == _nowPackId);
    if (i < 0) {
      i = _pathNodes.length - 1;
    }
    var start = i - 1 < 0 ? 0 : i - 1;
    var end = start + 3;
    if (end > _pathNodes.length) {
      end = _pathNodes.length;
      start = end - 3 < 0 ? 0 : end - 3;
    }
    final slice = _pathNodes.sublist(start, end);
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
            if (e.pack.level.toUpperCase() != 'A1' &&
                !PremiumService.isPremium) {
              final ok = await PremiumService.gate(context);
              if (!ok) {
                return;
              }
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
              await _loadToday();
              await _loadPath();
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF14201E),
                          Color(0xFF0E1815),
                          Color(0xFF0A1310),
                        ]
                      : const [
                          Color(0xFFFAF6EC),
                          Color(0xFFF4ECDA),
                          Color(0xFFEEDFC2),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. Subtle radial accent — 호랑이 뒤 따뜻한 빛 ──
          Positioned(
            top: 60,
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

          // ── 3. Ambient particles ──
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 14)),
          ),

          // ── 4. Content ──
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadToday,
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
                      // ── A. 헤더 — 워드마크 + 스트릭·레벨 칩 + 설정(§6.1 블록 1) ──
                      _TopBar(
                        streak: Storage.streakDays,
                        level: Storage.xpLevel,
                        xp: Storage.xp,
                        onStreakTap: _showWeekSheet,
                        onStatsTap: () =>
                            Navigator.pushNamed(context, '/stats'),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── B. 캐릭터 히어로 — 인사 + 말풍선 + 큰 캐릭터 ──
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
                            onTap: _onHeroTap,
                            kind: kind,
                          ),
                        ),
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
                        child: MissionHeroCard(
                          loading: _loadingScenario || _loadingCourse,
                          content: (_loadingScenario || _loadingCourse)
                              ? null
                              : _missionHeroContent(t, lang),
                          onPremiumCourse: _openCourse,
                          onAnotherRound: () async {
                            await Navigator.pushNamed(context, '/path');
                            if (mounted) {
                              await _loadToday();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── E1a. 이어지는 길 — 현재 ±1 미리보기 (§6.1 블록 4·§10.2) ──
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
                                await _loadToday();
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

          // ── 5. Flying magpie overlay ──
          const Positioned.fill(child: IgnorePointer(child: FlyingMagpie())),

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
                  : Border.all(
                      color: SoriColors.darkBorderStrong,
                      width: 1.5,
                    ),
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
// B. Tiger hero — greeting + 큰 호랑이 + 말풍선
// ════════════════════════════════════════════════════════════════════════
class _TigerHero extends StatelessWidget {
  final String greeting;
  final String bubble;
  final _DayPhase phase;

  /// 표시 캐릭터 — 말풍선 액센트·밴드·폴백이 전부 이걸 따른다.
  final MascotKind kind;

  /// Phase E — hero 탭 시 추천 팩으로 직행(있으면). null = 비탭.
  final VoidCallback? onTap;

  const _TigerHero({
    required this.greeting,
    required this.bubble,
    required this.phase,
    required this.kind,
    this.onTap,
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
    // v6 (2026-06-03): 정적 아바타 → 살아있는 호랑이 "마당 밴드".
    // greeting 텍스트 위 + TigerStage 밴드(진입 인사→idle→좌우 pacing) +
    // 말풍선. 밴드는 콘텐츠 폭 전체를 차지(걷는 가로 공간 확보).
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final bool veryNarrow = w < 330;
        final double greetingSize = veryNarrow ? 21.0 : 24.0;
        // §6.1 블록 2: 클립 밴드 높이 축소 ~160dp.
        final double bandHeight = veryNarrow ? 144.0 : 160.0;
        final double bubbleMax = (w * 0.62).clamp(140.0, 260.0);

        final hero = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
            ),
            // §6.1 블록 2 발화 단일화(H-4): 서브카피 폐지 — 발화는
            // 말풍선 1개만. CTA 문구는 블록 3 미션 히어로가 담당한다.
            SizedBox(height: veryNarrow ? 6 : 8),
            // 말풍선을 호랑이 *위*에 두고 아래로 꼬리를 내려 지시 — 얼굴을 덮지
            // 않으면서 "호랑이가 말하는" 느낌 유지(기존 오버레이는 얼굴을 가림).
            Center(
              child: _SpeechBubble(
                text: bubble,
                maxWidth: bubbleMax,
                accent: kind == MascotKind.magpie
                    ? SoriColors.highlight
                    : SoriColors.tigerOnLight,
              ),
            ),
            // 살아있는 호랑이 밴드
            SizedBox(
              height: bandHeight,
              width: double.infinity,
              child: TigerStageVideo(
                height: bandHeight,
                fallbackEmotion: _emotion,
                kind: kind,
              ),
            ),
          ],
        );

        if (onTap == null) {
          return hero;
        }
        // hero 전체를 추천 팩으로 가는 탭 타깃으로(Duo식 "큰 캐릭터 + 한 행동").
        return Semantics(
          button: true,
          label: bubble,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: hero,
          ),
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
              fontSize: 12.5,
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
// C. Inline stat chip row — streak · XP · shield
// ════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════
// C2. Daily goal progress — 오늘 XP / 목표 (모멘텀·리텐션)
// ════════════════════════════════════════════════════════════════════════
/// **디딤돌** — 첫 주(또는 스트릭이 끊긴 뒤)의 진행 표시.
///
/// 0%짜리 진행바 두 개로 첫 화면을 시작하지 않기 위한 대체물.
/// 이번 주 7칸 중 오늘 칸을 밝히고, 스트릭에 해당하는 지난 칸을 채운다.
/// 주 시작(월/일)과 요일 약칭은 [MaterialLocalizations] 를 따라 로케일별로
/// 자동 정렬된다 — 독일어는 월요일 시작, 영어는 일요일 시작.
class _SteppingStonesRow extends StatelessWidget {
  final int streak;
  final int xpToday;
  final int goal;
  const _SteppingStonesRow({
    required this.streak,
    required this.xpToday,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final ml = MaterialLocalizations.of(context);
    final now = DateTime.now();
    // 이번 주 첫 날 (로케일의 주 시작 요일 기준).
    final firstDayIdx = ml.firstDayOfWeekIndex; // 0 = 일요일
    final todayIdx = now.weekday % 7; // DateTime: 월=1..일=7 → 일=0
    final offset = (todayIdx - firstDayIdx + 7) % 7;
    final locale = Localizations.localeOf(context).toString();
    // §7.1: 요일 디딤돌은 2글자 축약(Mo Di Mi …) — narrow 1글자는 월/수(M/M)·
    // 토/일(S/S)이 구분 불가. 스크린리더 라벨은 전체 요일명(EEEE).
    DateTime dayOf(int slot) => now.add(Duration(days: slot - offset));
    String short2(int slot) {
      final abbr = DateFormat.E(locale).format(dayOf(slot)).replaceAll('.', '');
      return abbr.length <= 2 ? abbr : abbr.substring(0, 2);
    }

    return SoriCard(
      variant: SoriCardVariant.compact,
      semanticLabel: t.homeFirstWeekTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.homeFirstWeekTitle,
            style: SoriTextTheme.of(context).cardTitle,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _Stone(
                    label: short2(i),
                    fullDayName: DateFormat.EEEE(locale).format(dayOf(i)),
                    isToday: i == offset,
                    // 오늘 이전 칸 중 스트릭 안에 드는 날은 채운다.
                    isDone: i < offset && (offset - i) <= streak,
                  ),
                ),
            ],
          ),
          if (goal > 0) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '$xpToday / $goal XP',
              style: SoriTextTheme.of(context).caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  final String label;

  /// 스크린리더용 전체 요일명 (§7.1 — 시각 라벨은 2글자 축약).
  final String fullDayName;
  final bool isToday;
  final bool isDone;
  const _Stone({
    required this.label,
    required this.fullDayName,
    required this.isToday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final Color fill;
    final Color border;
    final Color fg;
    if (isToday) {
      fill = SoriColors.gold.withValues(alpha: 0.18);
      border = SoriColors.goldOnLight;
      fg = SoriColors.goldOnLight;
    } else if (isDone) {
      fill = SoriColors.primarySoft;
      border = SoriColors.primary;
      fg = SoriColors.primaryOnLight;
    } else {
      fill = Colors.transparent;
      border = SoriColors.lightBorderStrong;
      fg = s.textMuted;
    }
    final stone = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(SoriRadius.xs),
              border: Border.all(color: border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDone
                  ? Icons.check_rounded
                  : (isToday ? Icons.circle : Icons.remove),
              size: isToday ? 9 : 13,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isToday ? SoriColors.goldOnLight : s.textMuted,
            ),
          ),
        ],
      ),
    );
    // §7.1: 시각은 2글자, 스크린리더는 전체 요일명.
    return Semantics(
      label: fullDayName,
      excludeSemantics: true,
      child: stone,
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final int xpToday;
  final int goal;
  const _DailyGoalCard({required this.xpToday, required this.goal});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final today = xpToday;
    final done = goal > 0 && today >= goal;
    final ratio = goal > 0 ? (today / goal).clamp(0.0, 1.0) : 0.0;
    final accent = done ? SoriColors.success : SoriColors.tiger;
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.flag_outlined,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done ? t.homeDailyGoalDone : t.homeDailyGoalLabel,
                  // §4.3: 2줄 허용.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$today/$goal XP',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: s.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SoriProgressBar(value: ratio, color: accent),
        ],
      ),
    );
  }
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
