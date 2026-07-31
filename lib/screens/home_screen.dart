import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import '../models/scenario.dart';
import '../models/vocab_pack.dart';
import '../services/data_loader.dart';
import '../services/gye_service.dart';
import '../services/daily_char_service.dart';
import '../services/pack_progress_service.dart';
import '../services/personalized_lesson_service.dart';
import '../services/premium_service.dart';
import '../services/smalltalk_loader.dart';
import '../services/hanok_stage_service.dart';
import '../services/lesson_recommender_service.dart';
import '../services/review_deck_service.dart';
import '../services/scenario_loader.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_loading.dart';
import 'daily_char_sheet.dart';
import 'review_session_screen.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/flying_magpie.dart';
import '../widgets/sori/hanok_cinematic.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/path_node.dart';
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

  // Stage B 예약: final GlobalKey? bookTourKey;

  const HomeScreen({super.key, this.pathTourKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Scenario? _today;
  bool _loadingScenario = true;
  int _dueCount = 0; // M2: heute fällige + neue SRS-Karten ("Heute lernen")
  int _hardCount = 0; // A2: "어려운 단어"(leech) 개수

  // E2. Skill-path — 사용자 레벨 시나리오 진행 레일.
  List<Scenario> _levelPath = const [];
  Set<String> _completed = const {};

  // E1a. Lernpfad 홈 임베드 — 현재 레벨 단어팩 노드 리스트.
  List<({VocabPack pack, PackProgress progress})> _pathNodes = [];
  String? _nowPackId;

  // Phase E — 호랑이 hero의 "다음 한 가지" 추천(경로 now 노드와 동일 팩).
  LessonPath? _recommendation;

  // Phase 3 (stately-rising-jongga) — Hanok-Cinematic gating.
  HanokStage? _pendingCinematicStage;
  bool _cinematicShown = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadPath();
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

  /// 새로 달성한 마일스톤이 있으면 우선순위 1개 축하(나머지도 마킹 — 스팸 방지).
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
    await Storage.markMilestonesCelebrated(newly.map((m) => m.id).toList());
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
      await showMilestoneCelebration(context, top);
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

      // Phase E — hero CTA용 추천(경로 now 노드와 동일 알고리즘).
      final rec = await LessonRecommenderService.getNextLesson();

      if (!mounted) {
        return;
      }
      setState(() {
        _pathNodes = nodes;
        _nowPackId = nowId;
        _recommendation = rec;
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

    final levelPath = list
        .where((s) => s.level == userLevel)
        .toList(growable: false);

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

    setState(() {
      _today = pick;
      _levelPath = levelPath;
      _completed = completed;
      _dueCount = dueCount;
      _hardCount = hardCount;
      _loadingScenario = false;
    });

    // 푸시 리텐션: 데일리 리마인더 body를 최신 스트릭으로 갱신해 재예약.
    _refreshDailyReminder();
    // 팩 진행도 새로고침 (RefreshIndicator → pull-to-refresh 시 동기화).
    // ignore: discarded_futures
    _loadPath();
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
        ),
      ),
    );
    if (mounted) _loadToday();
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
  String _tigerBubble(AppL10n t) => homeTigerBubble(
    t,
    streak: Storage.streakDays,
    xp: Storage.xp,
    motivation: learnerMotivationFromId(Storage.motivation),
  );

  /// Phase E — hero subline. 추천이 있으면 "▶ {행동} · {팩 이름}",
  /// 없으면(전부 클리어/로드 전) 기본 학습 카피.
  String _heroSubline(AppL10n t, String lang) {
    final rec = _recommendation;
    if (rec == null) {
      return t.homeGreetingLearn;
    }
    final action = rec.kind == LessonKind.continueLearning
        ? t.homeHeroActionContinue
        : t.homeHeroActionStart;
    final label = VocabPackService.displayLabel(rec.packId, lang: lang);
    return '▶ $action · $label';
  }

  /// Phase E — hero 탭. 추천 팩으로 직행(없으면 단어팩 그리드).
  Future<void> _onHeroTap() async {
    final rec = _recommendation;
    if (rec != null) {
      await Navigator.pushNamed(context, '/vocab/pack', arguments: rec.packId);
    } else {
      await Navigator.pushNamed(context, '/vocab');
    }
    if (mounted) {
      await _loadToday();
      await _loadPath();
    }
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
                      // ── A. Compact top bar (logo + actions) ──
                      _TopBar(),
                      const SizedBox(height: Spacing.lg),

                      // ── B. Tiger hero — 시간대별 인사 + 말풍선 + 큰 호랑이 ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 40),
                        child: _TigerHero(
                          greeting: _greeting(t),
                          bubble: _tigerBubble(t),
                          subline: _heroSubline(t, lang),
                          phase: _phase,
                          onTap: _onHeroTap,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── C. Inline stat chip row ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 140),
                        slideY: 14,
                        child: _StatChipRow(
                          streak: Storage.streakDays,
                          xp: Storage.xp,
                          level: Storage.xpLevel,
                          xpToNext: Storage.xpToNext,
                          shields: Storage.streakFreezes,
                          shieldLabel: t.homeShieldLabel,
                          daysLabel: t.statsDays,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),

                      // ── C2. 일일 목표 진행 (모멘텀 — 리텐션) ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 120),
                        slideY: 14,
                        // ⚠️ const 로 두면 안 된다 — const 위젯은 부모 리빌드
                        // 시 동일 canonical 인스턴스라 Flutter 가 rebuild 를
                        // 건너뛴다. 그러면 팩 클리어로 XP 를 얻어도 Tagesziel
                        // 카드가 첫 값(0)에 고정된다. xpToday/goal 을 인자로
                        // 넘겨(부모 build 에서 fresh 읽기) 매번 갱신되게 한다.
                        child: _DailyGoalCard(
                          xpToday: Storage.xpToday,
                          goal: Storage.dailyGoalXp,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),

                      // ── D. 주 CTA — 듀오링고식 단일 행동: "열면 바로 뭘 할지"
                      //    현재 진행 팩으로 직행 (없으면 학습 경로로) ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 100),
                        slideY: 14,
                        child: SoriButton.filled(
                          label: t.homeLearnNowCta,
                          icon: Icons.bolt_rounded,
                          accent: SoriColors.tiger,
                          fullWidth: true,
                          onTap: () async {
                            if (_nowPackId != null) {
                              await Navigator.pushNamed(
                                context,
                                '/vocab/pack',
                                arguments: _nowPackId,
                              );
                            } else {
                              await Navigator.pushNamed(context, '/path');
                            }
                            if (mounted) {
                              await _loadToday();
                              await _loadPath();
                            }
                            // 레슨 직후 달성한 마일스톤 즉시 축하.
                            if (mounted) {
                              await _maybeCelebrateMilestone();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── E1a. Lernpfad — 학습 경로(홈 중심·F1, Today 위로 승격) ──
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final e in _pathNodes)
                                PathNode(
                                  label: VocabPackService.displayLabel(
                                    e.pack.id,
                                    lang: lang,
                                  ),
                                  status: e.progress.status,
                                  fraction: e.progress.progressFraction,
                                  isNow: e.pack.id == _nowPackId,
                                  onTap: () async {
                                    if (e.progress.status ==
                                        PackStatus.locked) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(t.pathLockedHint),
                                        ),
                                      );
                                      return;
                                    }
                                    if (e.pack.level.toUpperCase() != 'A1' &&
                                        !PremiumService.isPremium) {
                                      final ok = await PremiumService.gate(
                                        context,
                                      );
                                      if (!ok) return;
                                    }
                                    if (!context.mounted) return;
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
                              const SizedBox(height: Spacing.xs),
                              TextButton(
                                onPressed: () async {
                                  await Navigator.pushNamed(context, '/path');
                                  if (mounted) {
                                    await _loadPath();
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: SoriColors.primary,
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.pathSeeAll,
                                      style: SoriTextTheme.of(context).label
                                          .copyWith(color: SoriColors.primary),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: Spacing.xl),

                      // ── E. Today CTA — 오늘의 단일 행동(경로 아래) ──
                      _SectionLabel(label: t.homeTodaySection),
                      const SizedBox(height: Spacing.sm),
                      SoriEntrance(
                        delay: const Duration(milliseconds: 150),
                        child: _TodayScenarioCard(
                          scenario: _today,
                          loading: _loadingScenario,
                          lang: lang,
                          onTap: _today == null
                              ? null
                              : () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/scenario',
                                    arguments: _today!.id,
                                  );
                                  if (mounted) await _loadToday();
                                },
                        ),
                      ),
                      const SizedBox(height: Spacing.md),

                      // ── E2. Skill path — 진행 레일(홈 중심 메타포로 승격) ──
                      if (_levelPath.isNotEmpty) ...[
                        _SectionLabel(label: t.scenariosPathTitle),
                        const SizedBox(height: Spacing.sm),
                        SoriEntrance(
                          delay: const Duration(milliseconds: 180),
                          slideY: 14,
                          child: _SkillPathRail(
                            scenarios: _levelPath,
                            completed: _completed,
                            currentId: _today?.id,
                            lang: lang,
                            onTapScenario: (id) async {
                              await Navigator.pushNamed(
                                context,
                                '/scenario',
                                arguments: id,
                              );
                              if (mounted) await _loadToday();
                            },
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),
                      ],

                      // ── P0-G7. Streak 0 회복 메시지 ──
                      if (Storage.streakDays == 0) ...[
                        SoriEntrance(
                          delay: const Duration(milliseconds: 200),
                          slideY: 14,
                          child: SoriCard(
                            variant: SoriCardVariant.hero,
                            accent: SoriColors.primary,
                            tinted: true,
                            child: Row(
                              children: [
                                const Mascot(
                                  kind: MascotKind.tiger,
                                  emotion: MascotEmotion.smile,
                                  size: 60,
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
                      // ── E1b. Heute lernen (M2) — fällige SRS-Karten ──
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

                      // ── E1c. Dein Tageskurs (M5) — personalisiert · Premium ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 260),
                        slideY: 14,
                        child: _CourseCard(onTap: _openCourse),
                      ),
                      const SizedBox(height: Spacing.md),

                      // ── D. Daily char (compact, 부차 요소로 강등) ──
                      SoriEntrance(
                        delay: const Duration(milliseconds: 300),
                        slideY: 12,
                        child: _DailyCharCard(
                          char: DailyCharService.today(),
                          doneToday: Storage.calligraphyDoneToday,
                          onTap: () => showDailyCharSheet(context).then((_) {
                            if (mounted) setState(() {});
                          }),
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),

                      const SizedBox(height: Spacing.xxxl),
                      Center(
                        child: Text(
                          t.footerCheer,
                          style: SoriTextTheme.of(
                            context,
                          ).caption.copyWith(color: s.textDim),
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
  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);

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
            _RoundIconButton(
              icon: Icons.groups_2_outlined,
              onTap: () => showGyeChooser(context),
            ),
            const SizedBox(width: Spacing.xs),
            _RoundIconButton(
              icon: Icons.person_outline_rounded,
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            const SizedBox(width: Spacing.xs),
            _RoundIconButton(
              icon: Icons.bar_chart_rounded,
              onTap: () => Navigator.pushNamed(context, '/stats'),
            ),
            const SizedBox(width: Spacing.xs),
            _RoundIconButton(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: s.surface.withValues(alpha: 0.62),
          shape: BoxShape.circle,
          border: Border.all(color: s.border),
        ),
        child: Icon(icon, size: 18, color: s.textMuted),
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
  final String subline;
  final _DayPhase phase;

  /// Phase E — hero 탭 시 추천 팩으로 직행(있으면). null = 비탭.
  final VoidCallback? onTap;

  const _TigerHero({
    required this.greeting,
    required this.bubble,
    required this.subline,
    required this.phase,
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
    // greeting/subline 텍스트 위 + TigerStage 밴드(진입 인사→idle→좌우 pacing) +
    // 말풍선 오버레이. 밴드는 콘텐츠 폭 전체를 차지(걷는 가로 공간 확보).
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final bool veryNarrow = w < 330;
        final double greetingSize = veryNarrow ? 21.0 : 24.0;
        final double bandHeight = veryNarrow ? 150.0 : 168.0;
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 추천이 있으면(onTap != null) subline 을 primary CTA 로 강조.
            Text(
              subline,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: onTap != null ? 13 : 12,
                color: onTap != null ? SoriColors.primary : s.textMuted,
                height: 1.4,
                fontWeight: onTap != null ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: onTap != null ? -0.2 : 0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: veryNarrow ? 6 : 8),
            // 말풍선을 호랑이 *위*에 두고 아래로 꼬리를 내려 지시 — 얼굴을 덮지
            // 않으면서 "호랑이가 말하는" 느낌 유지(기존 오버레이는 얼굴을 가림).
            Center(
              child: _SpeechBubble(text: bubble, maxWidth: bubbleMax),
            ),
            // 살아있는 호랑이 밴드
            SizedBox(
              height: bandHeight,
              width: double.infinity,
              child: TigerStageVideo(
                height: bandHeight,
                fallbackEmotion: _emotion,
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
          label: subline,
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
  const _SpeechBubble({required this.text, this.maxWidth = 220});

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
              color: SoriColors.tiger.withValues(alpha: 0.30),
              width: 1,
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
                  maxLines: 1,
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

class _StatChipRow extends StatelessWidget {
  final int streak;
  final int xp;
  final int level;
  final int xpToNext;
  final int shields;
  final String shieldLabel;
  final String daysLabel;

  const _StatChipRow({
    required this.streak,
    required this.xp,
    required this.level,
    required this.xpToNext,
    required this.shields,
    required this.shieldLabel,
    required this.daysLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.compact,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          // 스탯칩은 한눈 요약 — 접근성 큰 글씨에서 3칩이 터지지 않게 1.3배 캡.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              children: [
                _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  color: SoriColors.warning,
                  value: '$streak',
                  label: daysLabel,
                ),
                _Divider(),
                _MiniStat(
                  icon: Icons.stars_rounded,
                  color: SoriColors.primary,
                  value: 'Lv $level',
                  label: '$xp XP',
                ),
                if (shields > 0) ...[
                  _Divider(),
                  _MiniStat(
                    icon: Icons.shield_rounded,
                    color: SoriColors.highlight,
                    value: '$shields',
                    label: shieldLabel,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SoriXpProgress(currentXp: xp, level: level, trailingLabel: null),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: s.border,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
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
                  doneToday ? t.dailyCharDoneToday : t.dailyCharSubtitle,
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
// E. Today scenario hero — primary CTA
// ════════════════════════════════════════════════════════════════════════
class _TodayScenarioCard extends StatelessWidget {
  final Scenario? scenario;
  final bool loading;
  final String lang;
  final VoidCallback? onTap;

  const _TodayScenarioCard({
    required this.scenario,
    required this.loading,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (loading) {
      return SoriCard(
        variant: SoriCardVariant.hero,
        accent: SoriColors.primary,
        tinted: true,
        child: const SizedBox(height: 120, child: AppLoading()),
      );
    }

    if (scenario == null) {
      return SoriCard(
        variant: SoriCardVariant.hero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Center(
            child: Text(
              t.homeNoScenario,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).bodySmall,
            ),
          ),
        ),
      );
    }

    final title = scenario!.title.pick(lang);

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScenarioAvatar(
                emoji: scenario!.emoji,
                sidekick: scenario!.sidekick,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.homeRecommended,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: SoriColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: SoriTextTheme.of(
                        context,
                      ).h3.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: SoriColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(
                              SoriRadius.pill,
                            ),
                          ),
                          child: Text(
                            scenario!.level.display,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              color: SoriColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '5–7 min · +${scenario!.xpReward} XP',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SoriTextTheme.of(context).cardSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: SoriColors.primary,
                  borderRadius: SoriRadius.brPill,
                  boxShadow: [
                    BoxShadow(
                      color: SoriColors.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.scenarioStartBtn,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScenarioAvatar extends StatelessWidget {
  final String emoji;
  final String? sidekick;
  const _ScenarioAvatar({required this.emoji, this.sidekick});

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot.forSpeaker(
      sidekick ?? '',
      size: 60,
      emotion: MascotEmotion.smile,
      animate: true,
    );
    if (mascot != null) {
      return SizedBox(width: 60, height: 60, child: mascot);
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
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
                          maxLines: 1,
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
// E2. Skill-path rail — 레벨 시나리오 진행 (완료 ● / 현재 ◉ / 예정 ○)
// ════════════════════════════════════════════════════════════════════════
class _SkillPathRail extends StatelessWidget {
  final List<Scenario> scenarios;
  final Set<String> completed;
  final String? currentId;
  final String lang;
  final void Function(String id) onTapScenario;

  const _SkillPathRail({
    required this.scenarios,
    required this.completed,
    required this.currentId,
    required this.lang,
    required this.onTapScenario,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final doneCount = scenarios.where((sc) => completed.contains(sc.id)).length;

    return SoriCard(
      variant: SoriCardVariant.compact,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.scenariosPathProgress(doneCount, scenarios.length),
            style: SoriTextTheme.of(context).label.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: scenarios.length,
              itemBuilder: (context, i) {
                final sc = scenarios[i];
                return _PathNode(
                  index: i,
                  total: scenarios.length,
                  label: sc.title.pick(lang),
                  done: completed.contains(sc.id),
                  current: sc.id == currentId,
                  onTap: () => onTapScenario(sc.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final int index;
  final int total;
  final String label;
  final bool done;
  final bool current;
  final VoidCallback onTap;
  const _PathNode({
    required this.index,
    required this.total,
    required this.label,
    required this.done,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final Color ring = done
        ? SoriColors.primary
        : current
        ? SoriColors.tiger
        : s.border;
    final Color fill = done
        ? SoriColors.primary
        : current
        ? SoriColors.tiger.withValues(alpha: 0.18)
        : s.surface;

    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: index == 0
                      ? const SizedBox.shrink()
                      : _Connector(active: done || current),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: current ? SoriColors.tiger : s.textMuted,
                          ),
                        ),
                ),
                Expanded(
                  child: index == total - 1
                      ? const SizedBox.shrink()
                      : _Connector(active: done),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                  color: current ? s.text : s.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool active;
  const _Connector({required this.active});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: active ? SoriColors.primary.withValues(alpha: 0.5) : s.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
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
