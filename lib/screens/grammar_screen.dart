import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../features/study_library/study_library_models.dart';
import '../motion/transitions.dart';
import '../models/course_practice_context.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/grammar_study_plan.dart';
import '../models/grammar_study_copy.dart';
import '../models/feedback_completion.dart';
import '../models/learner_level.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_checkpoint_questions.dart';
import '../services/curriculum_catalog.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/data_loader.dart';
import '../services/grammar_plan_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../services/custom_pack_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/ko_wrap.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/deck_coach.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/wordbook_add.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../l10n/generated/app_localizations.dart';
import 'grammar_choice_quiz_screen.dart';

/// 문법 학습 본문이 넘치지 않고 들어가는 최소 높이. 이보다 짧은 뷰포트에서는
/// [SoriMinHeightScroll] 이 이 높이의 본문을 스크롤시킨다.
///
/// 근거(360dp 폭, 실측): 고정 크롬이 필터 2줄 72 + 간격 32 + 진행바 24 +
/// 안팎 패딩 16 ≈ 144, 하단 액션 블록 ≈ 150. 카드가 학습용으로 의미를 가지려면
/// 최소 160 은 필요해 합이 ≈ 454 → 여유를 둬 460.
const double _studyBodyMinHeight = 460;

class GrammarCheckpointAttempt {
  const GrammarCheckpointAttempt({
    required this.targetId,
    required this.correct,
    required this.courseContext,
    required this.conceptId,
    required this.errorReason,
  });

  final String targetId;
  final bool correct;
  final CoursePracticeContext? courseContext;
  final String conceptId;
  final MasteryErrorReason? errorReason;
}

typedef GrammarCheckpointRecorder =
    Future<void> Function(GrammarCheckpointAttempt attempt);

Future<void> _recordGrammarCheckpoint(GrammarCheckpointAttempt attempt) async {
  final update = await CourseActivityReporter.recordContentAttempt(
    CurriculumContentKind.grammar,
    attempt.targetId,
    attempt.correct,
    courseContext: attempt.courseContext,
    conceptId: attempt.conceptId,
    errorReason: attempt.errorReason,
  );
  if (update == null) {
    throw StateError('Grammar checkpoint was not persisted.');
  }
}

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key, this.courseContext, this.checkpointRecorder});

  final CoursePracticeContext? courseContext;
  final GrammarCheckpointRecorder? checkpointRecorder;

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen>
    with ScreenCoachMixin<GrammarScreen> {
  List<Grammar> _all = [];
  List<Grammar> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  String _level = 'Alle';
  String _type = 'Alle';
  String _difficulty = 'Alle'; // Alle / Leicht / Schwer
  bool _loading = true;
  bool _loadFailed = false;
  String? _loadError;
  Set<String>? _courseContentIds;
  Map<String, ContentLink> _courseAssessmentLinks =
      const <String, ContentLink>{};
  CourseMissionStep? _missionStep;
  String? _missionTitle;
  final Map<String, String> _submittedAnswers = <String, String>{};
  final Set<String> _sessionSeen = <String>{};
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;
  Map<String, GrammarStudyPlan> _plans = const <String, GrammarStudyPlan>{};
  bool _legacyBrowseForVisit = false;
  bool _planOnboardingInFlight = false;
  bool _planCompletionInFlight = false;
  bool _planCompletionShown = false;
  bool _planDayCompletedForVisit = false;

  /// 지시서 1.11 — 온보딩 시트에서 고른 플랜 레벨. `Storage.grammarPlanLevel`
  /// 로 영속되어(Fable R1) 화면을 나갔다 다시 들어와도 그대로 이어진다. null이면
  /// [_userLevelForPlan](전역 사용자 레벨)을 그대로 따른다(아직 한 번도 고른
  /// 적이 없는 경우). `Storage.userLevelCode` 자체는 건드리지 않는다.
  String? _planLevel;

  bool get _isCoursePractice => widget.courseContext != null;

  String get _userLevelForPlan =>
      LearnerLevel.fromCode(Storage.userLevelCode)?.code ?? 'a1';

  GrammarStudyPlan? get _activePlan =>
      _isCoursePractice ? null : _plans[_planLevel ?? _userLevelForPlan];

  List<Grammar> _curatedRowsForPlan(GrammarStudyPlan plan) =>
      GrammarPlanService.curatedRowsForLevel(_all, plan.level);

  bool get _planFinished {
    final plan = _activePlan;
    if (plan == null) return false;
    return GrammarPlanService.todaysSlice(
      curatedRows: _curatedRowsForPlan(plan),
      plan: plan,
    ).isEmpty;
  }

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _filterRowKey = GlobalKey();

  @override
  String get coachId => 'grammar';

  @override
  bool get coachReady =>
      !_loading && _current != null && !_planOnboardingInFlight;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    final steps = <SpotlightStep>[
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachGrammarStep1Title,
        body: t.coachGrammarStep1Body,
        icon: Icons.flip_rounded,
      ),
    ];
    if (!_isCoursePractice && _activePlan == null) {
      steps.add(
        SpotlightStep(
          targetKey: _filterRowKey,
          title: t.coachGrammarStep2Title,
          body: t.coachGrammarStep2Body,
          icon: Icons.tune_rounded,
        ),
      );
    }
    return steps;
  }

  @override
  void initState() {
    super.initState();
    _idx = Storage.grammarLastIdx;
    _planLevel = Storage.grammarPlanLevel;
    _load();
    scheduleCoach();
    Analytics.lessonStarted(lessonType: 'grammar');
    _abandonTracker = QuestAbandonTracker(
      questType: 'grammar',
      lastStepReached: () => 'card_$_idx',
    );
  }

  @override
  void dispose() {
    _abandonTracker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadError = null;
    });
    try {
      final g = await DataLoader.loadGrammar();
      final catalog = _isCoursePractice ? await CurriculumCatalog.load() : null;
      if (!mounted) return;
      final languageCode = Localizations.localeOf(context).languageCode;
      final courseContentIds = catalog == null
          ? null
          : courseContentIdsForContext(
              catalog: catalog,
              courseContext: widget.courseContext,
              kind: CurriculumContentKind.grammar,
            );
      final courseAssessmentLinks = catalog == null
          ? const <String, ContentLink>{}
          : courseAssessmentLinksForContext(
              catalog: catalog,
              courseContext: widget.courseContext,
              kind: CurriculumContentKind.grammar,
            );
      final courseContext = widget.courseContext;
      final missionStep = catalog == null || courseContext == null
          ? null
          : CourseMissionStepPlan.fromLinks(
              catalog.linksForCourseUnit(courseContext.courseUnitId),
            ).stepForContentLinkId(courseContext.contentLinkId);
      final missionTitle = catalog == null || courseContext == null
          ? null
          : catalog
                .courseUnitFor(courseContext.courseUnitId)
                ?.title
                .pick(languageCode);
      // 80+ 패턴을 한 번에 보여주지 않도록, 첫 진입 시 사용자 레벨로 스코프.
      // (CSV 레벨 표기와 일치할 때만 — 아니면 'Alle' 유지, 안전.)
      final userLvl = LearnerLevel.fromCode(Storage.userLevelCode)?.display;
      final available = courseContentIds == null
          ? g
          : g
                .where((item) => courseContentIds.contains(item.id))
                .toList(growable: false);
      final useLevel = _isCoursePractice
          ? 'Alle'
          : (userLvl != null && available.any((x) => x.level == userLvl)
                ? userLvl
                : 'Alle');
      final plans = GrammarPlanService.decodePlans(Storage.grammarPlanRawJson);
      final activePlan = _isCoursePractice
          ? null
          : plans[_planLevel ?? _userLevelForPlan];
      final planCompletedToday =
          activePlan?.servedIdsByDate.containsKey(Storage.todayIso()) ?? false;
      final initialSlice = activePlan == null || planCompletedToday
          ? const <Grammar>[]
          : GrammarPlanService.todaysSlice(
              curatedRows: GrammarPlanService.curatedRowsForLevel(
                g,
                activePlan.level,
              ),
              plan: activePlan,
            );
      setState(() {
        _all = g;
        _plans = plans;
        _planDayCompletedForVisit = planCompletedToday;
        _courseContentIds = courseContentIds;
        _courseAssessmentLinks = courseAssessmentLinks;
        _missionStep = missionStep;
        _missionTitle = missionTitle;
        _level = useLevel;
        _filtered = activePlan == null
            ? (useLevel == 'Alle'
                  ? available
                  : available.where((x) => x.level == useLevel).toList())
            : initialSlice;
        _loading = false;
        _loadFailed = g.isEmpty && DataLoader.lastError != null;
        if (_idx >= _filtered.length) _idx = 0;
      });
      if (!mounted || _isCoursePractice || activePlan != null) return;
      unawaited(_showPlanOnboardingSheet(allowLegacyBrowseOnDismissal: true));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _loadError = error.toString();
      });
    }
  }

  bool get _hasActiveFilter =>
      _level != 'Alle' || _type != 'Alle' || _difficulty != 'Alle';

  bool _typeMatches(Grammar grammar, String type, String lang) {
    if (type == 'Alle') {
      return true;
    }
    return grammar.typeFor(lang) == type ||
        grammar.typeDe == type ||
        grammar.typeEn == type;
  }

  List<Grammar> _computeFiltered({
    required String level,
    required String type,
    required String difficulty,
  }) {
    final lang = Localizations.localeOf(context).languageCode;
    final hardPatterns = Storage.grammarHard;
    final scoped = _courseContentIds == null
        ? _all
        : _all
              .where((item) => _courseContentIds!.contains(item.id))
              .toList(growable: false);
    return scoped.where((g) {
      if (level != 'Alle' && g.level != level) {
        return false;
      }
      if (!_typeMatches(g, type, lang)) {
        return false;
      }
      if (difficulty == 'Schwer' && !hardPatterns.contains(g.pattern)) {
        return false;
      }
      if (difficulty == 'Leicht' && hardPatterns.contains(g.pattern)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _applyFilters() {
    final currentId = _filtered.isEmpty || _idx >= _filtered.length
        ? null
        : _filtered[_idx].id;
    setState(() {
      // 레벨을 바꾸면 그 레벨에 없는 유형이 남아 있을 수 있다. 남겨 두면
      // 결과가 0 장이 되고 드롭다운 value 도 항목 밖이라 터진다.
      if (!_types.contains(_type)) {
        _type = 'Alle';
      }
      _filtered = _computeFiltered(
        level: _level,
        type: _type,
        difficulty: _difficulty,
      );
      // 검수#17: 필터를 바꿔도 지금 보던 카드가 새 목록에 남아 있으면 그
      // 자리를 지킨다. 예전엔 무조건 0으로 되돌려 "필터를 바꿨더니 임의의
      // 카드로 튄다"는 체감을 낳았다 — 새 목록에 없을 때만(레벨을 바꿔
      // 그 카드가 진짜 사라진 경우) 0으로 되돌린다.
      final keepIdx = currentId == null
          ? -1
          : _filtered.indexWhere((g) => g.id == currentId);
      _idx = keepIdx >= 0 ? keepIdx : 0;
      _flipped = false;
      _sessionSeen.clear();
      _feedbackCompletion.reset();
    });
  }

  void _clearFilters() {
    _level = 'Alle';
    _type = 'Alle';
    _difficulty = 'Alle';
    _applyFilters();
  }

  Grammar? get _current => _planDayCompletedForVisit || _filtered.isEmpty
      ? null
      : _filtered[_idx % _filtered.length];

  List<Grammar> get _courseGrammarCandidates => _courseContentIds == null
      ? _all
      : _all
            .where((grammar) => _courseContentIds!.contains(grammar.id))
            .toList(growable: false);

  GrammarCheckpointQuestion _checkpointQuestionFor(Grammar grammar) =>
      GrammarCheckpointQuestion.forGrammar(
        target: grammar,
        candidates: _courseGrammarCandidates,
      );

  bool _hasSavedCheckpoint(Grammar grammar) =>
      _submittedAnswers.containsKey(grammar.id);

  ContentLink? _assessmentLinkFor(Grammar grammar) =>
      _courseAssessmentLinks[grammar.id];

  bool _canRecordCheckpoint(Grammar grammar) {
    if (!_isCoursePractice || _hasSavedCheckpoint(grammar)) return false;
    return _assessmentLinkFor(grammar) != null &&
        _checkpointQuestionFor(grammar).canRecordEvidence;
  }

  void _persistIdx() => Storage.setGrammarLastIdx(_idx);

  /// 한 장짜리 덱에는 이동할 곳이 없다.
  ///
  /// 이동은 전부 `% _filtered.length` 로 감싸여 있어서 길이가 1이면 언제나
  /// 같은 인덱스가 나온다 — Weiter·Zurück·Zufällig 가 눌리는 것처럼 보이면서
  /// 아무 일도 하지 않았고, Verstanden/Schwierig 도 마지막에 [_next] 를 불러
  /// 같은 증상을 냈다. 드문 상태가 아니다: `grammar.csv` 의 레벨+유형 조합
  /// 181개 중 **180개가 카드 한 장**이라 유형 필터를 고르면 거의 항상 이렇게
  /// 되고, 문법 카드를 하나만 연결한 코스 단원 6개도 같은 덱이 된다.
  bool get _canNavigateDeck => _filtered.length > 1;

  void _next() {
    if (!_canNavigateDeck) return;
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx + 1) % _filtered.length;
    });
    _persistIdx();
  }

  void _prev() {
    if (!_canNavigateDeck) return;
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx - 1 + _filtered.length) % _filtered.length;
    });
    _persistIdx();
  }

  /// `onPrevious`(아래 플링, 검수#17 배선)와 그 접근성 대체수단(WCAG
  /// 2.5.1 커스텀 시맨틱 액션)이 공유하는 몸통 — 제스처와 대체수단이 정확히
  /// 같은 게이트·동작을 내야 한다. `_prev()`와 달리 감싸지 않는다(끝에서
  /// 처음으로 안 돌아간다) — 두 호출부 모두 `_idx > 0` 일 때만 이 메서드를
  /// 넘긴다.
  void _goToPreviousCard() {
    setState(() {
      _idx--;
      _flipped = false;
    });
  }

  /// 판정 = SRS 마킹 **+ 전진**. 단어장·복습 덱(`SoriSwipeCard`)과 같은 계약이라
  /// 스와이프와 하단 버튼이 정확히 같은 일을 한다 — 제스처를 모르거나 정밀
  /// 터치가 필요한 사용자를 위해 버튼이 제스처의 완전한 대체 수단이어야 한다.
  Future<void> _judge({required bool understood}) async {
    final g = _current;
    if (g == null) return;
    setState(() => _sessionSeen.add(g.pattern));
    if (understood) {
      await Storage.markGrammarEasy(g.pattern);
    } else {
      await Storage.markGrammarHard(g.pattern);
      // 어렵다고 표시한 패턴은 자동으로 단어장에 넣는다(Jin 확정). 판정이
      // 곧 "나중에 다시 볼 목록"이 되므로, 어렵다는 신호가 저장까지 가야
      // 사용자가 한 번 더 손대지 않는다.
      _saveCurrent();
    }
    if (!mounted) return;
    // 마지막 카드의 판정은 곧 세션 종료다 — Hören 이 마지막 스텝에서 완료로
    // 넘어가는 것과 같은 흐름이라 별도 "Grammatikübung abschließen" 버튼이
    // 필요 없다. 한 장짜리 덱도 이 경로로 정상 종료된다.
    if (_idx >= _filtered.length - 1) {
      if (_activePlan != null) {
        await _completePlanDayIfNeeded();
        return;
      }
      await _finishSession();
      return;
    }
    _next();
  }

  /// 평가 없이 넘기기(↓). 판정이 아니므로 플립 게이트와 무관하다.
  void _skipCurrent() {
    if (!_canNavigateDeck) return;
    _next();
  }

  /// 내 저장에 담기(↑). Study Library에는 문법 타입을 보존하고, 기존 게임
  /// 연결을 위해서만 같은 내용을 빠른저장 팩에 호환 미러로 남긴다.
  void _saveCurrent() {
    final g = _current;
    if (g == null) return;
    unawaited(_saveGrammar(g));
  }

  Future<void> _saveGrammar(Grammar grammar) async {
    await addTypedBookmarkWithWordbookMirror(
      context,
      itemType: StudyLibraryItemType.grammar,
      itemId: grammar.pattern,
      korean: grammar.pattern,
      translationDe: grammar.explanationDe,
      translationEn: grammar.explanationEn,
      translationLanguage: Localizations.localeOf(context).languageCode,
      posDe: grammar.typeDe,
      exampleKorean: grammar.exampleKorean,
      exampleDe: grammar.exampleGerman,
      exampleEn: grammar.exampleEn,
      sourceUnitId: grammar.id,
      source: 'grammar',
    );
    if (mounted) setState(() {});
  }

  Future<void> _likeCurrent() async {
    final g = _current;
    if (g == null) {
      return;
    }
    await LikedContentService.toggle(
      kind: LikedContentService.grammar,
      id: g.pattern,
    );
    if (mounted) {
      setState(() {});
    }
  }

  /// This is intentionally a separate, free-practice route. Course grammar
  /// checkpoints retain their scoped three-choice evidence contract; opening
  /// this four-choice recognition exercise must never unlock a mission.
  void _openChoicePractice() {
    final initialLevel = _level == 'Alle' ? null : _level;
    Navigator.of(context).push(
      SoriTransitions.page(
        (_) => GrammarChoiceQuizScreen(initialLevel: initialLevel),
      ),
    );
  }

  Future<void> _openLevelChrome() async {
    if (_isCoursePractice || _legacyBrowseForVisit) {
      _showFilterSheet();
      return;
    }
    if (_activePlan == null) {
      await _showPlanOnboardingSheet(allowLegacyBrowseOnDismissal: true);
    }
  }

  Future<void> _showPlanOnboardingSheet({
    bool allowLegacyBrowseOnDismissal = false,
  }) async {
    if (!mounted || _planOnboardingInFlight) return;
    _planOnboardingInFlight = true;
    var started = false;
    try {
      final t = AppL10n.of(context);
      var planLevel = _planLevel ?? _userLevelForPlan;
      var itemsPerDay =
          _plans[planLevel]?.itemsPerDay ?? GrammarPlanService.defaultItemsPerDay;
      var isStarting = false;
      await showSoriSheet<void>(
        context: context,
        builder: (sheetContext) => KeyedSubtree(
          key: const Key('grammar-plan-onboarding-sheet'),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.grammarPlanLevelLabel,
                    style: SoriTextTheme.of(sheetContext).label,
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriLevelFilterBar(
                    key: const Key('grammar-plan-level-bar'),
                    selected: planLevel,
                    onChanged: (level) {
                      if (isStarting || level == null || level == planLevel) {
                        return;
                      }
                      setSheetState(() {
                        planLevel = level;
                        itemsPerDay = _plans[level]?.itemsPerDay ?? itemsPerDay;
                      });
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    t.grammarPlanOnboardingTitle,
                    style: SoriTextTheme.of(sheetContext).h3,
                  ),
                  const SizedBox(height: Spacing.md),
                  SizedBox(
                    height: SoriLayout.chromeRowTouchHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final n
                              in GrammarPlanService.itemsPerDayOptions) ...[
                            if (n !=
                                GrammarPlanService.itemsPerDayOptions.first)
                              const SizedBox(width: Spacing.sm),
                            SoriChip(
                              key: Key('grammar-plan-items-$n'),
                              label: t.grammarPlanItemsPerDayOption(n),
                              accent: SoriColors.info,
                              selected: itemsPerDay == n,
                              variant: SoriChipVariant.soft,
                              minInteractiveHeight:
                                  SoriLayout.chromeRowTouchHeight,
                              onTap: isStarting
                                  ? null
                                  : () {
                                      if (itemsPerDay == n) {
                                        return;
                                      }
                                      setSheetState(() => itemsPerDay = n);
                                    },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  SoriButton.filled(
                    label: t.grammarPlanStartCta,
                    fullWidth: true,
                    onTap: isStarting
                        ? null
                        : () async {
                            setSheetState(() => isStarting = true);
                            final chosenLevel = planLevel;
                            final next = Map<String, GrammarStudyPlan>.of(
                              _plans,
                            );
                            final existing = next[chosenLevel];
                            final existingFinished =
                                existing != null &&
                                GrammarPlanService.todaysSlice(
                                  curatedRows:
                                      GrammarPlanService.curatedRowsForLevel(
                                        _all,
                                        chosenLevel,
                                      ),
                                  plan: existing,
                                ).isEmpty;
                            // 이미 있는(끝나지 않은) 플랜을 고르면 진행을
                            // 이어간다 — 리셋은 새 레벨이거나 그 레벨을 이미
                            // 다 끝냈을 때만(지시서 1.11).
                            final plan = existing == null || existingFinished
                                ? GrammarStudyPlan(
                                    level: chosenLevel,
                                    itemsPerDay: itemsPerDay,
                                    servedIdsByDate: const {},
                                  )
                                : existing.copyWith(itemsPerDay: itemsPerDay);
                            next[chosenLevel] = plan;
                            try {
                              await Storage.setGrammarPlanRawJson(
                                GrammarPlanService.encodePlans(next),
                              );
                              await Storage.setGrammarPlanLevel(chosenLevel);
                            } catch (_) {
                              if (mounted && sheetContext.mounted) {
                                setSheetState(() => isStarting = false);
                              }
                              return;
                            }
                            if (!mounted || !sheetContext.mounted) return;
                            started = true;
                            setState(() {
                              _plans = next;
                              _planLevel = chosenLevel;
                              _applyPlanSlice(plan);
                            });
                            Navigator.of(sheetContext).pop();
                          },
                  ),
                ],
              );
            },
          ),
        ),
      );
      if (mounted && allowLegacyBrowseOnDismissal && !started) {
        setState(() => _legacyBrowseForVisit = true);
      }
    } finally {
      _planOnboardingInFlight = false;
    }
  }

  void _applyPlanSlice(GrammarStudyPlan plan) {
    _filtered = GrammarPlanService.todaysSlice(
      curatedRows: _curatedRowsForPlan(plan),
      plan: plan,
    );
    _idx = 0;
    _flipped = false;
    _sessionSeen.clear();
    _feedbackCompletion.reset();
    _planCompletionShown = false;
    _planDayCompletedForVisit = false;
  }

  Future<void> _showCheckpoint(
    Grammar target,
    ContentLink assessmentLink,
  ) async {
    final question = _checkpointQuestionFor(target);
    if (!question.canRecordEvidence || assessmentLink.conceptIds.length != 1) {
      return;
    }
    final grammarById = {for (final grammar in _all) grammar.id: grammar};
    final savedAnswer = _submittedAnswers[target.id];
    final t = AppL10n.of(context);

    await showSoriSheet<void>(
      context: context,
      builder: (sheetContext) {
        String? selectedAnswer = savedAnswer;
        var isSaving = false;

        return StatefulBuilder(
          builder: (sheetContext, setLocal) {
            final isComplete = selectedAnswer != null;
            final isCorrect = isComplete && question.isCorrect(selectedAnswer!);

            Future<void> submit(String answerId) async {
              if (isComplete || isSaving || !sheetContext.mounted) {
                return;
              }
              setLocal(() => isSaving = true);
              final correct = question.isCorrect(answerId);
              final attempt = GrammarCheckpointAttempt(
                targetId: target.id,
                correct: correct,
                courseContext: widget.courseContext,
                conceptId: assessmentLink.conceptIds.single,
                errorReason: correct ? null : MasteryErrorReason.unknown,
              );
              try {
                await (widget.checkpointRecorder ?? _recordGrammarCheckpoint)(
                  attempt,
                );
              } catch (_) {
                if (sheetContext.mounted) {
                  setLocal(() => isSaving = false);
                }
                if (mounted) {
                  _showCheckpointSaveError();
                }
                return;
              }
              if (mounted) {
                setState(() => _submittedAnswers[target.id] = answerId);
              }
              if (sheetContext.mounted) {
                setLocal(() {
                  isSaving = false;
                  selectedAnswer = answerId;
                });
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.courseCheckpointGrammarPrompt,
                  style: SoriTextTheme.of(sheetContext).h3,
                ),
                const SizedBox(height: Spacing.sm),
                SoriPhraseWrap(
                  target.exampleKorean,
                  style: SoriTextTheme.of(
                    sheetContext,
                  ).h3.copyWith(height: 1.45),
                ),
                const SizedBox(height: Spacing.lg),
                for (final optionId in question.optionIds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: SoriButton.outlined(
                      label: grammarById[optionId]?.pattern ?? optionId,
                      fullWidth: true,
                      accent: isComplete && optionId == target.id
                          ? SoriColors.success
                          : null,
                      destructive:
                          isComplete &&
                          !isCorrect &&
                          optionId == selectedAnswer,
                      onTap: isComplete || isSaving
                          ? null
                          : () => submit(optionId),
                    ),
                  ),
                if (isComplete) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    isCorrect
                        ? t.courseCheckpointCorrect
                        : t.courseCheckpointIncorrect,
                    style: SoriTextTheme.of(sheetContext).label.copyWith(
                      color: isCorrect ? SoriColors.success : SoriColors.danger,
                    ),
                  ),
                  if (savedAnswer != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      t.courseCheckpointSaved,
                      style: SoriTextTheme.of(sheetContext).caption,
                    ),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _showCheckpointSaveError() {
    soriToast(context, AppL10n.of(context).courseCheckpointSaveError);
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    final revealsAnswer = !_flipped;
    setState(() {
      _flipped = !_flipped;
      if (revealsAnswer && _current != null) {
        _sessionSeen.add(_current!.pattern);
      }
    });
    if (_flipped && _current != null) Storage.addGrammarSeen(_current!.pattern);
  }

  Future<void> _finishSession() async {
    if (_sessionSeen.isEmpty) return;
    _recordSessionCompleted();
    final t = AppL10n.of(context);
    final completion = _feedbackCompletion.complete(
      () => FeedbackCompletion.grammarSession(
        contentLabel: t.screenGrammarTitle,
        level: _level,
        type: _type,
        difficulty: _difficulty,
        seenCount: _sessionSeen.length,
      ),
    );

    await showSoriSheet<void>(
      context: context,
      builder: (sheetContext) {
        final feedbackScope = ContentFeedbackControllerScope.maybeOf(
          sheetContext,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.testerFeedbackCompleteGrammar,
              style: SoriTextTheme.of(sheetContext).h2,
              textAlign: TextAlign.center,
            ),
            if (feedbackScope != null &&
                feedbackScope.featureGate.isEnabled) ...[
              const SizedBox(height: Spacing.lg),
              ContentFeedbackCard(
                feedbackContext: completion.context,
                featureGate: feedbackScope.featureGate,
                submitFeedback: feedbackScope.submitFeedback,
                completedMissionIds: feedbackScope.completedMissionIds,
              ),
            ],
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              label: t.btnClose,
              fullWidth: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _sessionSeen.clear();
      _feedbackCompletion.reset();
    });
  }

  void _recordSessionCompleted() {
    Analytics.lessonCompleted(lessonType: 'grammar');
    _abandonTracker.markCompleted();
  }

  Future<void> _completePlanDayIfNeeded() async {
    if (_planCompletionInFlight || _planCompletionShown) return;
    final plan = _activePlan;
    if (plan == null || _filtered.isEmpty) return;
    final today = Storage.todayIso();
    if (plan.servedIdsByDate.containsKey(today)) {
      _planCompletionShown = true;
      return;
    }
    _planCompletionInFlight = true;
    try {
      final servedIds = _filtered
          .map((grammar) => grammar.id)
          .toList(growable: false);
      final updated = GrammarPlanService.recordServedDay(
        plan,
        dateIso: today,
        servedIds: servedIds,
      );
      final next = Map<String, GrammarStudyPlan>.of(_plans)
        ..[plan.level] = updated;
      await Storage.setGrammarPlanRawJson(GrammarPlanService.encodePlans(next));
      if (!mounted) return;
      _planCompletionShown = true;
      _recordSessionCompleted();
      setState(() {
        _plans = next;
        _planDayCompletedForVisit = true;
      });
      final t = AppL10n.of(context);
      await showSoriSheet<void>(
        context: context,
        builder: (sheetContext) => KeyedSubtree(
          key: const Key('grammar-plan-completion-sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.grammarPlanCompletionTitle,
                style: SoriTextTheme.of(sheetContext).h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.grammarPlanCompletionBody,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(sheetContext).body,
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.grammarPlanCompletionCta,
                fullWidth: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(
                    '/grammar_choice_quiz',
                    arguments: <String, dynamic>{
                      'level': plan.level,
                      'allowedTargetIds': servedIds.toSet(),
                      'planDayLabel': t.grammarPlanDayHeader(
                        plan.completedDays + 1,
                        GrammarPlanService.totalDays(
                          _curatedRowsForPlan(plan),
                          plan.itemsPerDay,
                        ),
                      ),
                    },
                  );
                },
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.grammarPlanCompletionSkip,
                fullWidth: true,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _sessionSeen.clear();
        _feedbackCompletion.reset();
      });
    } finally {
      _planCompletionInFlight = false;
    }
  }

  // 칩 목록은 **_applyFilters 가 실제로 훑는 집합**에서 뽑는다.
  //
  // 예전엔 _all(전체 문법)에서 뽑았는데, 코스 연습 모드에서 _applyFilters 는
  // _courseContentIds 로 좁힌 scoped 에만 필터를 건다(194-198행). 그래서 코스
  // 범위에 한 건도 없는 레벨·유형 칩이 그대로 노출됐고, 누르면 결과가 0이
  // 되면서 시트가 닫히고 빈 화면만 남았다("필터걸면 없다고 하고 뒤로 튕겨" —
  // Jin, 2026-08-12 실기기. 그 '튕김'은 필터 시트가 닫히는 동작이다).
  //
  // 고를 수 없는 선택지를 아예 안 보여주는 게 근본 해법이다 — 빈 결과를 예쁘게
  // 안내하는 것보다 낫다.
  List<String> get _levels {
    final s = _courseGrammarCandidates.map((g) => g.level).toSet().toList()
      ..sort();
    return ['Alle', ...s];
  }

  /// 이 레벨에 실제로 있는 패턴 수 ('Alle' = 전체). 칩에 붙여 보여준다 —
  /// 레벨을 눌러 보기 전에 A1 37 · C2 17 처럼 분포가 드러나야 한다
  /// (2026-08-19 Jin: "레벨별로 몇 개인지 배치가 안 보인다").
  int _levelCount(String level) => level == 'Alle'
      ? _courseGrammarCandidates.length
      : _courseGrammarCandidates.where((g) => g.level == level).length;

  /// Typ 후보 — **현재 레벨 스코프에서 2개 이상인 유형만** 내놓는다.
  ///
  /// `grammar.csv` 의 `type_de` 는 214 행에 고유값 213 개다(212 개가 1 행짜리).
  /// 사실상 기본키라, 유형을 하나 고르면 덱이 카드 1 장으로 줄고
  /// [_canNavigateDeck](길이>1)이 false 가 되어 뭘 눌러도 같은 카드만 나왔다
  /// ("뭘 눌러도 이것만 나온다니까?" — Jin, 2026-08-19. 유형 이름 6 개가
  /// 'Frage' 를 포함해 증상이 그 문구로 보였다).
  ///
  /// 고를 수 있는 게 'Alle' 뿐이면 [_showFilterSheet] 가 드롭다운 자체를
  /// 감춘다 — 죽은 컨트롤을 살아 있는 척 보여주지 않는다.
  List<String> get _types => _typesForLevel(_level);

  List<String> _typesForLevel(String level) {
    final lang = Localizations.localeOf(context).languageCode;
    final counts = <String, int>{};
    for (final grammar in _courseGrammarCandidates) {
      if (level != 'Alle' && grammar.level != level) {
        continue;
      }
      final type = grammar.typeFor(lang);
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final usable =
        counts.entries
            .where((entry) => entry.value >= 2)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    return ['Alle', ...usable];
  }

  Future<void> _showLevelFilter(AppL10n t) async {
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level,
      levels: _levels,
      allLabel: t.filterAll,
      countFor: _levelCount,
    );
    if (!mounted || next == null) return;
    _level = next;
    if (!_typesForLevel(next).contains(_type)) {
      _type = 'Alle';
    }
    _applyFilters();
  }

  Widget _legacyFilterChrome(AppL10n t) {
    return SoriChromeRow(
      key: const Key('grammar-filter-row'),
      onFilterTap: () => _showLevelFilter(t),
      filterSemanticLabel: t.filterLevel,
      meta: Text(
        '${_level == 'Alle' ? t.filterAll : _level} · ${_levelCount(_level)}',
        style: SoriTextTheme.of(context).meta,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.filter_list_rounded),
        tooltip: t.filterTitle,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: _showFilterSheet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return SoriStudyFrame(
        title: t.screenGrammarTitle,
        padding: EdgeInsets.zero,
        child: AppLoading(message: t.loadingGrammar),
      );
    }
    if (_loadFailed) {
      return SoriStudyFrame(
        title: t.screenGrammarTitle,
        child: AppError(
          message: _loadError ?? DataLoader.lastError ?? t.errorUnknown,
          onRetry: () {
            DataLoader.reset();
            _load();
          },
        ),
      );
    }
    final g = _current;
    if (g == null) {
      if (_planDayCompletedForVisit && _activePlan != null && !_planFinished) {
        return SoriStudyFrame(
          title: t.screenGrammarTitle,
          actions: const [TtsSpeedAction()],
          child: KeyedSubtree(
            key: const Key('grammar-plan-day-complete'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.grammarPlanCompletionTitle,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).h3,
                ),
              ],
            ),
          ),
        );
      }
      if (_planFinished) {
        return SoriStudyFrame(
          title: t.screenGrammarTitle,
          actions: const [TtsSpeedAction()],
          child: KeyedSubtree(
            key: const Key('grammar-plan-finished'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.grammarPlanFinishedTitle,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).h3,
                ),
                const SizedBox(height: Spacing.lg),
                SoriButton.outlined(
                  label: t.grammarPlanFinishedRestartCta,
                  onTap: _showPlanOnboardingSheet,
                ),
              ],
            ),
          ),
        );
      }
      return PopScope(
        canPop: !_hasActiveFilter,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _hasActiveFilter) {
            _clearFilters();
          }
        },
        child: SoriStudyFrame(
          title: t.screenGrammarTitle,
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_wave.png',
            icon: Icons.menu_book_outlined,
            title: t.emptyGrammar,
            ctaLabel: _isCoursePractice ? null : t.filterOpenBtn,
            onCta: _isCoursePractice ? null : _openLevelChrome,
          ),
        ),
      );
    }

    final assessmentLink = _assessmentLinkFor(g);
    final canRecordCheckpoint = _canRecordCheckpoint(g);
    // 덱이 한 장이면 Weiter 는 갈 곳이 없다([_canNavigateDeck]). 둘러보기에서는
    // 이 화면의 빈 상태와 같은 규칙으로 필터를 여는 CTA 를 대신 내주고, 코스
    // 연습에서는 빈 상태와 마찬가지로 필터 CTA 를 주지 않으므로 비활성으로
    // 남긴다 — 죽은 버튼을 살아 있는 척 보여주지 않는 게 요점이다.
    // 체크포인트 카드는 채점 전까지 패턴을 가리므로 SRS 판정을 허용하지 않는다
    // (못 본 패턴에 쉬움/어려움을 매기면 스케줄이 망가진다). 그 외에는 앞면이
    // 패턴을 그대로 보여주므로 일반 덱과 같은 판정 계약을 쓴다.
    final allowJudging = !canRecordCheckpoint;
    // 4방향 덱 코치 — 화면 코치('grammar')가 끝난 뒤에만 뜨고,
    // `Storage.tutSeen('soriDeck')` 로 사용자당 1회다. 단어장·복습·커스텀팩이
    // 쓰는 것과 같은 공용 헬퍼라 네 방향의 의미가 앱 전체에서 한 번만 학습된다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowSoriDeckCoach(
          context,
          targetKey: _cardKey,
          afterCoachIds: const ['grammar'],
        );
      }
    });
    final s = SoriSurfaces.of(context);
    return SoriStudyFrame(
      title: t.screenGrammarTitle,
      actions: [
        if (_isCoursePractice)
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: t.filterTitle,
            onPressed: _showFilterSheet,
          ),
        const TtsSpeedAction(),
      ],
      padding: EdgeInsets.zero,
      // 짧은 뷰포트에서 넘치는 대신 스크롤한다. 이 화면은 헤더·필터 2줄·
      // 진행바가 고정 높이라, 세로가 짧아지면 가운데 `Expanded` 가 0이 돼도
      // 카드 아래 난이도 버튼이 그대로 넘쳤다(360×400 에서 25px).
      // 460 이상에서는 지금까지와 같은 flex 레이아웃이라 시각 변화 0.
      child: SoriMinHeightScroll(
        minHeight: _studyBodyMinHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              if (_missionStep case final step?) ...[
                MissionContextBar(
                  missionTitle: _missionTitle ?? t.courseMissionTitleShort,
                  step: step,
                ),
                const SizedBox(height: Spacing.sm),
              ],

              if (_activePlan case final plan?) ...[
                KeyedSubtree(
                  key: const Key('grammar-plan-day-header'),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.grammarPlanDayHeader(
                              plan.completedDays + 1,
                              GrammarPlanService.totalDays(
                                _curatedRowsForPlan(plan),
                                plan.itemsPerDay,
                              ),
                            ),
                            style: SoriTextTheme.of(context).label,
                          ),
                          const SizedBox(width: Spacing.xs),
                          // 지시서 1.11 — 플랜이 이미 도는 중에도 레벨/페이스를
                          // 다시 고를 수 있는 유일한 진입점(그 외엔 '플랜
                          // 완료' 또는 '레벨 필터가 아직 없음'일 때만 시트가
                          // 열린다).
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              key: const Key('grammar-plan-edit-button'),
                              iconSize: 20,
                              icon: const Icon(Icons.tune_rounded),
                              tooltip: t.grammarPlanEditTooltip,
                              onPressed: _showPlanOnboardingSheet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        children: [
                          for (var i = 0; i < plan.completedDays; i++)
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: SoriColors.success,
                            ),
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: SoriColors.info,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
              ] else if (!_isCoursePractice) ...[
                KeyedSubtree(
                  key: _filterRowKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _legacyFilterChrome(t),
                      const SizedBox(height: Spacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SoriButton.filled(
                          key: const Key('grammar-choice-cta'),
                          label: t.grammarChoiceCta,
                          size: SoriButtonSize.sm,
                          accent: SoriColors.primary,
                          onTap: _openChoicePractice,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
              ],

              // Card + Difficulty Buttons
              Expanded(
                child: SoriEntrance(
                  child: Column(
                    children: [
                      Expanded(
                        // 카드가 놓이는 바운드 영역의 유한 높이를 여기서
                        // 읽어(플립카드 내부 스크롤 래퍼 아래로 내려가면
                        // maxHeight 가 무한이 된다) 앞/뒷면 학습 텍스트를
                        // 카드 높이에 비례해 키운다 — review_session 히어로
                        // 카드와 같은 충전 규칙(soriFillSize).
                        child: LayoutBuilder(
                          builder: (context, cardConstraints) {
                            final cardH = cardConstraints.maxHeight.isFinite
                                ? cardConstraints.maxHeight
                                : 360.0;
                            // Sori Deck 2.0 — 단어장·복습 덱과 같은 4방향
                            // 제스처. 좌=Schwierig · 우=Verstanden ·
                            // 아래=평가 없이 넘기기. 위(저장)는 문법
                            // 패턴이 단어장 저장 대상이 아니라 끈다.
                            //
                            // `enabled` 는 **좌/우 판정 허용** 계약이다:
                            // 뒤집어 뜻을 보기 전에는 판정할 수 없다
                            // (안 그러면 못 본 패턴에 SRS 가 기록된다).
                            // 코스 체크포인트 카드는 앞면이 패턴을
                            // 가리므로 판정 자체를 막는다.
                            // 제스처 대체 수단(WCAG 2.2 §2.5.1). 화면에는
                            // 아무것도 그리지 않지만 TalkBack/VoiceOver 에는
                            // 다섯 동작(이해함/어려움/저장/건너뛰기/이전
                            // 카드)이 메뉴로 노출된다 — 스와이프를 쓸 수
                            // 없는 사용자가 하단 버튼 없이도 판정·이동할 수
                            // 있다. onPrevious 는 처음엔 이 목록에서
                            // 빠졌었다 — 아래 플링만 대체수단이 없는 채로
                            // 남았던 것을 접근성 후속수정으로 마저 채운다.
                            return Semantics(
                              container: true,
                              customSemanticsActions:
                                  <CustomSemanticsAction, VoidCallback>{
                                    if (allowJudging)
                                      CustomSemanticsAction(
                                        label: t.grammarEasy,
                                      ): () =>
                                          _judge(understood: true),
                                    if (allowJudging)
                                      CustomSemanticsAction(
                                        label: t.grammarHard,
                                      ): () =>
                                          _judge(understood: false),
                                    CustomSemanticsAction(
                                      label: t.deckActionSave,
                                    ): _saveCurrent,
                                    if (_canNavigateDeck)
                                      CustomSemanticsAction(label: t.btnSkip):
                                          _skipCurrent,
                                    if (_idx > 0)
                                      CustomSemanticsAction(
                                        label: t.grammarPreviousCard,
                                      ): _goToPreviousCard,
                                  },
                              child: SoriContentFeed(
                                judgmentsEnabled: allowJudging && _flipped,
                                onBlockedJudgment: allowJudging ? () {} : null,
                                onNext: allowJudging
                                    ? () => _judge(understood: true)
                                    : null,
                                onPrevious: _idx > 0 ? _goToPreviousCard : null,
                                onHard: allowJudging
                                    ? () => _judge(understood: false)
                                    : null,
                                onSkip: _canNavigateDeck ? _skipCurrent : null,
                                skipEnabled: _canNavigateDeck,
                                onLike: _likeCurrent,
                                onBookmark: _saveCurrent,
                                showShare: false,
                                onFlip: canRecordCheckpoint
                                    ? () => _showCheckpoint(g, assessmentLink!)
                                    : _onFlip,
                                liked: LikedContentService.isLiked(
                                  kind: LikedContentService.grammar,
                                  id: g.pattern,
                                ),
                                bookmarked: CustomPackService.containsKorean(
                                  g.pattern,
                                ),
                                bookmarkLabel: t.deckActionSave,
                                // §A3 지시서 2.9: 듣기 아이콘은 카드박스
                                // 상단 왼쪽 구석 — 카드 하단 중앙의 자체
                                // 원형 _ListenButton 을 걷어내고
                                // SoriContentFeed 의 topAccessory 슬롯을
                                // 쓴다(review_session_screen.dart:672 와
                                // 같은 패턴). 체크포인트 카드는 원래도
                                // 듣기 버튼이 없었다(canRecordCheckpoint).
                                topAccessory: canRecordCheckpoint
                                    ? null
                                    : () {
                                        final speakKorean =
                                            GrammarStudyCopy.fromGrammar(
                                              g,
                                              Localizations.localeOf(
                                                context,
                                              ).languageCode,
                                            ).speakKorean;
                                        return speakKorean.isEmpty
                                            ? null
                                            : SoriSpeechIndicator(
                                                text: speakKorean,
                                              );
                                      }(),
                                child: FlipCard(
                                  key: _cardKey,
                                  flipped: _flipped,
                                  onTap: canRecordCheckpoint
                                      ? () =>
                                            _showCheckpoint(g, assessmentLink!)
                                      : _onFlip,
                                  front: canRecordCheckpoint
                                      ? _CourseCheckpointFront(
                                          g: g,
                                          cardHeight: cardH,
                                        )
                                      : _Front(g: g, cardHeight: cardH),
                                  back: _Back(g: g, cardHeight: cardH),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // SRS 판정(Verstanden/Schwierig)은 하단 주버튼 2개와
                      // 4방향 스와이프로 옮겼다 — 카드 바로 아래의 고정
                      // 높이 Row 가 C1/C2 처럼 예문이 길어질 때 카드를
                      // 눌러 읽기를 방해했다. 체크포인트 카드에서 판정을
                      // 막는 계약은 `allowJudging` 이 그대로 이어받는다.
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // 진행바 → [듣기] 위치 [되돌리기]. Hören 과 같은 배치다.
              // Zurück 은 전진 흐름을 막지 않도록 작은 실행취소 아이콘
              // 하나로 줄였고(Tinder 의 Rewind 위계), 첫 카드에서는 되돌릴
              // 것이 없으므로 꺼진다. 두 아이콘 모두 48×48 터치 영역이다.
              SoriProgressBar(
                value: _filtered.isEmpty ? 0 : (_idx + 1) / _filtered.length,
                thickness: 6,
                color: SoriColors.primary,
                animated: true,
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                children: [
                  // 듣기는 카드 안(읽어 주는 문장 옆)으로 옮겼다. 균형을
                  // 위해 실행취소와 같은 폭만 비워 카운터를 가운데 둔다.
                  const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_idx + 1} / ${_filtered.length}',
                        style: SoriTextTheme.of(
                          context,
                        ).meta.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('grammar-undo'),
                      tooltip: t.btnPrev,
                      icon: const Icon(Icons.undo_rounded),
                      iconSize: 20,
                      color: s.textMuted,
                      onPressed: _idx > 0 ? _prev : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // 판정은 **스와이프 전용**이다(Jin 확정) — 하단 CTA 를 없애
              // 카드가 세로를 더 갖는다. 제스처를 못 쓰는 사용자를 위한
              // 대체 수단은 시각적 버튼이 아니라 카드의 Semantics 액션이
              // 맡는다(WCAG 2.2 §2.5.1 — 대체 수단은 필요하지만 그게
              // 화면을 차지하는 버튼이어야 할 필요는 없다).
              //
              // 코스 체크포인트만 CTA 를 유지한다 — "카드 전체 탭과 하단
              // CTA 가 같은 채점 시트를 연다" 는 기존 계약이 있다.
              if (canRecordCheckpoint)
                SoriEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: SoriButton.filled(
                    // 장식 아이콘 없이 라벨만 — 타이포 래칫의
                    // "라벨 CTA 에 장식 아이콘 금지" 규칙을 따른다.
                    label: t.courseCheckpointCheck,
                    accent: SoriColors.contentCta,
                    fullWidth: true,
                    onTap: () => _showCheckpoint(g, assessmentLink!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final t = AppL10n.of(context);
    var stagedType = _type;
    var stagedDifficulty = _difficulty;
    showSoriSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.filterTitle, style: SoriTextTheme.of(ctx).h3),
              // 고를 수 있는 유형이 'Alle' 뿐이면 감춘다 (죽은 컨트롤 금지).
              if (_typesForLevel(_level).length > 1) ...[
                const SizedBox(height: Spacing.md),
                _dropdown(
                  ctx,
                  t.filterType,
                  stagedType,
                  _typesForLevel(_level),
                  (v) {
                    setLocal(() => stagedType = v!);
                  },
                ),
              ],
              const SizedBox(height: Spacing.md),
              // 난이도는 학습 화면의 가로줄에서 여기로 옮겼다. 카드가 세로
              // 공간을 먼저 갖되, 스와이프로 모은 "Schwierig" 를 다시 모아
              // 볼 수 있어야 판정이 보상으로 돌아온다.
              Text(t.filterDifficulty, style: SoriTextTheme.of(ctx).label),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.xs + 2,
                children: [
                  for (final diff in const ['Alle', 'Leicht', 'Schwer'])
                    SoriChip(
                      label: switch (diff) {
                        'Leicht' => t.grammarEasy,
                        'Schwer' => t.grammarHard,
                        _ => t.filterAll,
                      },
                      accent: SoriColors.info,
                      selected: stagedDifficulty == diff,
                      variant: SoriChipVariant.soft,
                      onTap: stagedDifficulty == diff
                          ? null
                          : () => setLocal(() => stagedDifficulty = diff),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.btnApply,
                fullWidth: true,
                onTap: () {
                  final next = _computeFiltered(
                    level: _level,
                    type: stagedType,
                    difficulty: stagedDifficulty,
                  );
                  if (next.isEmpty) {
                    showSoriToast(
                      ctx,
                      t.emptyGrammar,
                      duration: const Duration(milliseconds: 500),
                    );
                    return;
                  }
                  _type = stagedType;
                  _difficulty = stagedDifficulty;
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SoriTextTheme.of(context).label,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// A scored mission card deliberately withholds the target pattern until the
/// learner has answered. The normal flip card remains available in browse
/// mode and after the attempt, but the evidence-producing choice is not a
/// copy-the-text action.
class _CourseCheckpointFront extends StatelessWidget {
  const _CourseCheckpointFront({required this.g, required this.cardHeight});

  final Grammar g;

  /// 카드가 놓인 바운드 영역의 유한 높이 — 학습 텍스트를 카드 높이에 비례해
  /// 키우는 [soriFillSize] 기준. review_session 히어로 카드와 같은 규칙.
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final h = cardHeight;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      width: double.infinity,
      // 히어로 학습 카드: 내용을 spaceEvenly 로 세로로 꽉 채운다. 오버플로는
      // FlipCard 의 스크롤 래퍼가 받아낸다(추가 스크롤뷰 불필요).
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 정체(레벨 칩·아이콘·프롬프트)를 한 묶음으로.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriChip(
                label: g.level,
                accent: SoriColors.primary,
                variant: SoriChipVariant.filled,
              ),
              const SizedBox(height: Spacing.sm),
              const Icon(
                Icons.fact_check_outlined,
                size: 34,
                color: SoriColors.primary,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.courseCheckpointGrammarPrompt,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).caption.copyWith(
                  fontSize: soriFillSize(h, 0.045, 16, 26),
                  fontWeight: FontWeight.w700,
                  color: s.text,
                ),
              ),
            ],
          ),
          // 문제 문장(한국어 + 번역)을 한 묶음으로 — 이 카드의 핵심 학습 요소.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriPhraseWrap(
                g.exampleKorean,
                style: SoriTextTheme.of(context).caption.copyWith(
                  fontSize: soriFillSize(h, 0.09, 21, 48),
                  fontWeight: FontWeight.w700,
                  color: SoriColors.primary,
                  height: 1.35,
                ),
              ),
              if (g.exampleGerman.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  g.exampleFor(lang),
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).caption.copyWith(
                    fontSize: soriFillSize(h, 0.05, 13, 26),
                    color: s.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Front extends StatelessWidget {
  final Grammar g;

  /// 카드가 놓인 바운드 영역의 유한 높이 — [soriFillSize] 기준.
  final double cardHeight;
  const _Front({required this.g, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final copy = GrammarStudyCopy.fromGrammar(g, lang);
    final h = cardHeight;
    final preview = copy.examples.isEmpty ? null : copy.examples.first;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoriChip(
                  label: g.level,
                  accent: SoriColors.info,
                  variant: SoriChipVariant.filled,
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    g.pattern,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      fontSize: soriFillSize(h, 0.16, 28, 72),
                      fontWeight: FontWeight.w700,
                      color: SoriColors.primary,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                SoriPhraseWrap(
                  copy.title.isEmpty ? g.typeFor(lang) : copy.title,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).caption.copyWith(
                    fontSize: soriFillSize(h, 0.048, 14, 22),
                    color: s.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
            if (preview != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SoriColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoriPhraseWrap(
                      preview.korean,
                      style: SoriTextTheme.of(context).caption.copyWith(
                        fontSize: soriFillSize(h, 0.07, 17, 32),
                        fontWeight: FontWeight.w700,
                        color: s.text,
                        height: 1.35,
                      ),
                    ),
                    if (preview.gloss.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SoriPhraseWrap(
                        preview.gloss,
                        style: SoriTextTheme.of(context).caption.copyWith(
                          fontSize: soriFillSize(h, 0.045, 13, 20),
                          color: s.textMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Text(
              t.hintTapForExplanation,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).caption.copyWith(
                fontSize: soriFillSize(h, 0.038, 12.5, 18),
                color: s.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final Grammar g;

  /// 카드가 놓인 바운드 영역의 유한 높이 — [soriFillSize] 기준.
  final double cardHeight;
  const _Back({required this.g, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final copy = GrammarStudyCopy.fromGrammar(g, lang);
    final h = cardHeight;
    final pairCount = copy.rules.length > copy.examples.length
        ? copy.rules.length
        : copy.examples.length;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoriChip(
                  label: g.level,
                  accent: SoriColors.info,
                  variant: SoriChipVariant.filled,
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    g.pattern,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      fontSize: soriFillSize(h, 0.09, 20, 40),
                      fontWeight: FontWeight.w700,
                      color: SoriColors.primary,
                    ),
                  ),
                ),
                if (copy.title.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  SoriPhraseWrap(
                    copy.title,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      fontSize: soriFillSize(h, 0.042, 14, 20),
                      fontWeight: FontWeight.w600,
                      color: s.text,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
            for (var i = 0; i < pairCount; i++)
              _RuleExampleRow(
                rule: i < copy.rules.length ? copy.rules[i] : '',
                example: i < copy.examples.length ? copy.examples[i] : null,
                cardHeight: h,
              ),
            if (copy.note.isNotEmpty)
              SoriPhraseWrap(
                copy.note,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).caption.copyWith(
                  fontSize: soriFillSize(h, 0.038, 12.5, 18),
                  color: s.textMuted,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleExampleRow extends StatelessWidget {
  const _RuleExampleRow({
    required this.rule,
    required this.example,
    required this.cardHeight,
  });

  final String rule;
  final GrammarStudyExample? example;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final h = cardHeight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rule.isNotEmpty)
          SoriPhraseWrap(
            rule,
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).caption.copyWith(
              fontSize: soriFillSize(h, 0.042, 14, 20),
              fontWeight: FontWeight.w700,
              color: SoriColors.primary,
              height: 1.35,
            ),
          ),
        if (example != null) ...[
          const SizedBox(height: 4),
          SoriPhraseWrap(
            example!.korean,
            style: SoriTextTheme.of(context).caption.copyWith(
              fontSize: soriFillSize(h, 0.055, 16, 24),
              fontWeight: FontWeight.w700,
              color: s.text,
              height: 1.35,
            ),
          ),
          if (example!.gloss.isNotEmpty) ...[
            const SizedBox(height: 2),
            SoriPhraseWrap(
              example!.gloss,
              style: SoriTextTheme.of(context).caption.copyWith(
                fontSize: soriFillSize(h, 0.04, 13, 18),
                color: s.textMuted,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
