import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course_practice_context.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/feedback_completion.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_checkpoint_questions.dart';
import '../services/curriculum_catalog.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/study_action_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_card_face.dart';
import '../l10n/generated/app_localizations.dart';

/// 문법 학습 본문이 넘치지 않고 들어가는 최소 높이. 이보다 짧은 뷰포트에서는
/// [SoriMinHeightScroll] 이 이 높이의 본문을 스크롤시킨다.
///
/// 근거(360dp 폭, 실측): 고정 크롬이 필터 2줄 72 + 간격 32 + 진행바 24 +
/// 안팎 패딩 16 ≈ 144, 하단 액션 블록 ≈ 150. 카드가 학습용으로 의미를 가지려면
/// 최소 160 은 필요해 합이 ≈ 454 → 여유를 둬 460.
const double _studyBodyMinHeight = 460;

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key, this.courseContext});

  final CoursePracticeContext? courseContext;

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

  bool get _isCoursePractice => widget.courseContext != null;

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _filterRowKey = GlobalKey();

  @override
  String get coachId => 'grammar';

  @override
  bool get coachReady => !_loading && _current != null;

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
    if (!_isCoursePractice) {
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
    _load();
    scheduleCoach();
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
      final userLvl = (Storage.userLevelCode ?? '').toUpperCase();
      final available = courseContentIds == null
          ? g
          : g
                .where((item) => courseContentIds.contains(item.id))
                .toList(growable: false);
      final useLevel = _isCoursePractice
          ? 'Alle'
          : (available.any((x) => x.level == userLvl) ? userLvl : 'Alle');
      setState(() {
        _all = g;
        _courseContentIds = courseContentIds;
        _courseAssessmentLinks = courseAssessmentLinks;
        _missionStep = missionStep;
        _missionTitle = missionTitle;
        _level = useLevel;
        _filtered = useLevel == 'Alle'
            ? available
            : available.where((x) => x.level == useLevel).toList();
        _loading = false;
        _loadFailed = g.isEmpty && DataLoader.lastError != null;
        if (_idx >= _filtered.length) _idx = 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _loadError = error.toString();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      final hardPatterns = Storage.grammarHard;
      final scoped = _courseContentIds == null
          ? _all
          : _all
                .where((item) => _courseContentIds!.contains(item.id))
                .toList(growable: false);
      _filtered = scoped.where((g) {
        if (_level != 'Alle' && g.level != _level) return false;
        if (_type != 'Alle' && g.typeDe != _type) return false;
        if (_difficulty == 'Schwer' && !hardPatterns.contains(g.pattern)) {
          return false;
        }
        if (_difficulty == 'Leicht' && hardPatterns.contains(g.pattern)) {
          return false;
        }
        return true;
      }).toList();
      _idx = 0;
      _flipped = false;
      _sessionSeen.clear();
      _feedbackCompletion.reset();
    });
  }

  Grammar? get _current =>
      _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

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

  void _next() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx + 1) % _filtered.length;
    });
    _persistIdx();
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx - 1 + _filtered.length) % _filtered.length;
    });
    _persistIdx();
  }

  void _random() {
    HapticFeedback.lightImpact();
    setState(() {
      _flipped = false;
      _idx = math.Random().nextInt(_filtered.length);
    });
    _persistIdx();
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
              if (isComplete || isSaving) return;
              setLocal(() => isSaving = true);
              final update = await CourseActivityReporter.recordContentAttempt(
                CurriculumContentKind.grammar,
                target.id,
                question.isCorrect(answerId),
                courseContext: widget.courseContext,
                conceptId: assessmentLink.conceptIds.single,
                errorReason: question.isCorrect(answerId)
                    ? null
                    : MasteryErrorReason.unknown,
              );
              if (!mounted) return;
              setLocal(() => isSaving = false);
              if (update != null) {
                setState(() => _submittedAnswers[target.id] = answerId);
                setLocal(() => selectedAnswer = answerId);
              } else {
                _showCheckpointSaveError();
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
                Text(
                  target.exampleKorean,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SoriSurfaces.of(sheetContext).text,
                  ),
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
                    style: TextStyle(
                      color: isCorrect ? SoriColors.success : SoriColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (savedAnswer != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      t.courseCheckpointSaved,
                      style: TextStyle(
                        color: SoriSurfaces.of(sheetContext).textMuted,
                      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppL10n.of(context).courseCheckpointSaveError)),
    );
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

  List<String> get _levels {
    final s = _all.map((g) => g.level).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  List<String> get _types {
    final s = _all.map((g) => g.typeDe).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(body: AppLoading(message: t.loadingGrammar));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenGrammarTitle)),
        body: AppError(
          message: _loadError ?? DataLoader.lastError ?? 'Unbekannter Fehler',
          onRetry: () {
            DataLoader.reset();
            _load();
          },
        ),
      );
    }
    final g = _current;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenGrammarTitle)),
        body: SoriEmptyState(
          asset: 'assets/illustrations/mascot/magpie_wave.png',
          icon: Icons.menu_book_outlined,
          title: t.emptyGrammar,
          ctaLabel: _isCoursePractice ? null : t.filterOpenBtn,
          onCta: _isCoursePractice ? null : _showFilterSheet,
        ),
      );
    }

    final assessmentLink = _assessmentLinkFor(g);
    final canRecordCheckpoint = _canRecordCheckpoint(g);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenGrammarTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
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
                    // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
                    //
                    // 짧은 뷰포트에서 배너가 스스로 접히는 규칙은 HanokHeader 안에
                    // 있다(자기 높이가 화면의 22% 를 넘으면 SizedBox.shrink).
                    // 배너를 쓰는 모든 화면이 같은 규칙을 받는다.
                    const HanokHeader(
                      asset: 'assets/illustrations/hanok/study_scholar.png',
                      fallbackIcon: Icons.auto_stories_outlined,
                    ),
                    if (_missionStep case final step?) ...[
                      const SizedBox(height: Spacing.md),
                      MissionContextBar(
                        missionTitle:
                            _missionTitle ?? t.courseMissionTitleShort,
                        step: step,
                      ),
                    ],
                    const SizedBox(height: Spacing.md),

                    // 레벨 분할 칩 — 80+ 패턴을 레벨별로 쪼개 한 번에 보는 양을 줄임.
                    SizedBox(
                      key: _filterRowKey,
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final lvl in _levels)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SoriChip(
                                label: lvl == 'Alle' ? t.filterAll : lvl,
                                accent: SoriColors.warning,
                                selected: _level == lvl,
                                variant: SoriChipVariant.soft,
                                onTap: _level == lvl
                                    ? null
                                    : () {
                                        setState(() => _level = lvl);
                                        _applyFilters();
                                      },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),

                    // Difficulty Filter
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final diff in ['Alle', 'Leicht', 'Schwer'])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SoriChip(
                                label: diff,
                                accent: SoriColors.info,
                                selected: _difficulty == diff,
                                variant: SoriChipVariant.soft,
                                onTap: _difficulty == diff
                                    ? null
                                    : () {
                                        setState(() => _difficulty = diff);
                                        _applyFilters();
                                      },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),

                    // 진행도 — 슬림 바 + 위치 카운터 (3중 칩 정리, level·typeDe는 카드에 표시).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: SoriProgressBar(
                              value: _filtered.isEmpty
                                  ? 0
                                  : (_idx + 1) / _filtered.length,
                              thickness: 6,
                              color: SoriColors.warning,
                              animated: true,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            '${_idx + 1} / ${_filtered.length}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: s.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card + Difficulty Buttons
                    Expanded(
                      child: SoriEntrance(
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onHorizontalDragEnd: (d) {
                                  if (d.primaryVelocity == null) {
                                    return;
                                  }
                                  if (d.primaryVelocity! < -250) {
                                    _next();
                                  } else if (d.primaryVelocity! > 250) {
                                    _prev();
                                  }
                                },
                                child: SoriStudyScale(
                                  child: FlipCard(
                                    key: _cardKey,
                                    flipped: _flipped,
                                    onTap: canRecordCheckpoint ? null : _onFlip,
                                    front: canRecordCheckpoint
                                        ? _CourseCheckpointFront(g: g)
                                        : _Front(g: g),
                                    back: _Back(g: g),
                                  ),
                                ),
                              ),
                            ),
                            // SRS 마킹 (이 카드 난이도) — 네비게이션과 별개.
                            //
                            // ⚠️ 코스 체크포인트에서는 **숨긴다**. 체크포인트
                            // 앞면([_CourseCheckpointFront])은 채점 전까지
                            // `g.pattern` 을 일부러 가리는데, 아직 보지도 않은
                            // 패턴에 "쉬움/어려움"을 매기면
                            // `Storage.markGrammarEasy/Hard` 가 엉뚱한 SRS
                            // 스케줄을 기록한다 — 레이아웃이 아니라 **데이터
                            // 정합성** 문제라서 짧은 뷰포트와 무관하게 필요하다.
                            //
                            // 레이아웃(고정 높이 Row 가 짧은 화면에서 넘치는 것)은
                            // 이 가드가 아니라 본문의 [SoriMinHeightScroll] 이
                            // 맡는다 — 일반 문법 모드에는 가드가 걸리지 않으므로
                            // 그쪽 오버플로는 스크롤로만 해결된다.
                            if (!canRecordCheckpoint) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SoriButton.outlined(
                                      label: t.grammarEasy,
                                      icon: Icons.thumb_up_alt_outlined,
                                      onTap: () async {
                                        setState(
                                          () => _sessionSeen.add(g.pattern),
                                        );
                                        await Storage.markGrammarEasy(
                                          g.pattern,
                                        );
                                        _next();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SoriButton.outlined(
                                      label: t.grammarHard,
                                      icon: Icons.psychology_outlined,
                                      destructive: true,
                                      onTap: () async {
                                        setState(
                                          () => _sessionSeen.add(g.pattern),
                                        );
                                        await Storage.markGrammarHard(
                                          g.pattern,
                                        );
                                        _next();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 하단 액션 위계: Weiter(primary) > Hören·Zurück(secondary) > Zufällig(tertiary).
                    SoriEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StudyActionBar(
                            accent: SoriColors.warning,
                            secondary: [
                              StudyAction(
                                label: t.btnHoeren,
                                icon: Icons.volume_up,
                                onTap: () => TtsService.speak(g.exampleKorean),
                              ),
                              StudyAction(
                                label: t.btnPrev,
                                icon: Icons.arrow_back,
                                onTap: _prev,
                              ),
                            ],
                            primary: StudyAction(
                              label: canRecordCheckpoint
                                  ? t.courseCheckpointCheck
                                  : t.btnNext,
                              icon: canRecordCheckpoint
                                  ? Icons.fact_check_outlined
                                  : Icons.arrow_forward,
                              onTap: canRecordCheckpoint
                                  ? () => _showCheckpoint(g, assessmentLink!)
                                  : _next,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: SoriButton.ghost(
                                  label: t.btnRandom,
                                  size: SoriButtonSize.sm,
                                  onTap: _random,
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Expanded(
                                child: SoriButton.ghost(
                                  key: const Key('grammar-finish-session'),
                                  label: t.testerFeedbackCompleteGrammar,
                                  size: SoriButtonSize.sm,
                                  onTap: _sessionSeen.isEmpty
                                      ? null
                                      : _finishSession,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final t = AppL10n.of(context);
    var stagedLevel = _level;
    var stagedType = _type;
    showSoriSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.filterTitle, style: SoriTextTheme.of(ctx).h3),
              const SizedBox(height: Spacing.md),
              _dropdown(t.filterLevel, stagedLevel, _levels, (v) {
                setLocal(() => stagedLevel = v!);
              }),
              const SizedBox(height: Spacing.sm + 2),
              _dropdown(t.filterType, stagedType, _types, (v) {
                setLocal(() => stagedType = v!);
              }),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.btnApply,
                fullWidth: true,
                onTap: () {
                  _level = stagedLevel;
                  _type = stagedType;
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
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        border: Border.all(color: s.surfaceAlt),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: s.surface,
        hint: Text(label, style: TextStyle(color: s.textMuted)),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// A scored mission card deliberately withholds the target pattern until the
/// learner has answered. The normal flip card remains available in browse
/// mode and after the attempt, but the evidence-producing choice is not a
/// copy-the-text action.
class _CourseCheckpointFront extends StatelessWidget {
  const _CourseCheckpointFront({required this.g});

  final Grammar g;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return StudyCardFace(
      accent: SoriColors.warning,
      children: [
        SoriChip(
          label: g.level,
          accent: SoriColors.warning,
          variant: SoriChipVariant.filled,
        ),
        const SizedBox(height: Spacing.lg),
        const Icon(
          Icons.fact_check_outlined,
          size: 34,
          color: SoriColors.warning,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          t.courseCheckpointGrammarPrompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: s.text,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          g.exampleKorean,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: SoriColors.warning,
            height: 1.35,
          ),
        ),
        if (g.exampleGerman.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            g.exampleFor(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: s.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _Front extends StatelessWidget {
  final Grammar g;
  const _Front({required this.g});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return StudyCardFace(
      accent: SoriColors.warning,
      children: [
        SoriChip(
          label: g.level,
          accent: SoriColors.warning,
          variant: SoriChipVariant.filled,
        ),
        const SizedBox(height: 14),
        Text(
          g.pattern,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: SoriColors.warning,
            height: 1.15,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          g.typeFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: SoriColors.warning.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
        // 예문 미리보기 — 빈 카드를 채우고 패턴을 바로 용례로 보여줌.
        if (g.exampleKorean.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SoriColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.exampleKorean,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: s.text,
                    height: 1.3,
                  ),
                ),
                if (g.exampleGerman.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    g.exampleFor(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: s.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        // 인라인 아이콘 + 힌트 — Text.rich라 좁은 폭에서 자연스럽게 줄바꿈(오버플로 X).
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.touch_app_outlined,
                  size: 13,
                  color: s.textDim,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(text: t.hintTapForExplanation),
            ],
          ),
          style: TextStyle(fontSize: 11.5, color: s.textDim),
        ),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  final Grammar g;
  const _Back({required this.g});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return StudyCardFace(
      accent: SoriColors.hangul,
      children: [
        SoriChip(
          label: g.level,
          accent: SoriColors.hangul,
          variant: SoriChipVariant.filled,
        ),
        const SizedBox(height: 10),
        Text(
          g.pattern,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: SoriColors.hangul,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          g.explanationFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: s.text, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          g.exampleKorean,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SoriColors.hangul.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          g.exampleFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: s.text,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (g.note.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Divider(color: SoriColors.hangul.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: Spacing.xs + 2),
          Text(
            g.noteFor(lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: s.textMuted, height: 1.4),
          ),
        ],
      ],
    );
  }
}
