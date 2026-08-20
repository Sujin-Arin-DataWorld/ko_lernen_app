import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../motion/transitions.dart';
import '../models/course_practice_context.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/feedback_completion.dart';
import '../models/learner_level.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_checkpoint_questions.dart';
import '../services/curriculum_catalog.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/deck_coach.dart';
import '../services/content_share_service.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/wordbook_add.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
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
  late final QuestAbandonTracker _abandonTracker;

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

  /// 내 단어장에 저장(↑). 문법 카드는 패턴이 표제어이고 뜻풀이가 번역,
  /// 예문은 예문 슬롯으로 들어간다 — 단어 카드와 같은 저장 계약을 쓴다.
  void _saveCurrent() {
    final g = _current;
    if (g == null) return;
    // ignore: discarded_futures
    addToWordbook(
      context,
      korean: g.pattern,
      translationDe: g.explanationDe,
      translationEn: g.explanationEn,
      translationLanguage: Localizations.localeOf(context).languageCode,
      posDe: g.typeDe,
      exampleKorean: g.exampleKorean,
      exampleDe: g.exampleGerman,
    );
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

  void _shareCurrent() {
    final g = _current;
    if (g == null) {
      return;
    }
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final gloss = lang == 'en' ? g.explanationEn : g.explanationDe;
    // ignore: discarded_futures
    ContentShareService.shareStorySlip(
      korean: g.pattern,
      gloss: gloss,
      caption: t.contentShareBody(g.pattern, gloss),
    );
  }

  /// This is intentionally a separate, free-practice route. Course grammar
  /// checkpoints retain their scoped three-choice evidence contract; opening
  /// this four-choice recognition exercise must never unlock a mission.
  void _openChoicePractice() {
    final initialLevel = _level == 'Alle' ? null : _level;
    Navigator.of(context).push(
      SoriTransitions.fadeScale(
        (_) => GrammarChoiceQuizScreen(initialLevel: initialLevel),
      ),
    );
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
    Analytics.lessonCompleted(lessonType: 'grammar');
    _abandonTracker.markCompleted();
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

  List<String> get _types {
    final s = _courseGrammarCandidates.map((g) => g.typeDe).toSet().toList()
      ..sort();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenGrammarTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (!_isCoursePractice)
            IconButton(
              key: const Key('grammar-choice-cta'),
              tooltip: t.grammarChoiceCta,
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: _openChoicePractice,
            ),
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
          // 세션 종료(테스터 피드백 수집)는 하단에서 앱바로 올렸다. 하단은
          // 판정 2버튼만 남기지만, 182장짜리 둘러보기 덱에서는 "마지막 카드"에
          // 도달할 일이 없어 자동 종료만으로는 피드백 경로가 사라진다.
          // 의미 있는 학습(카드를 한 장이라도 본 뒤)에만 켜지는 계약은 그대로다.
          IconButton(
            key: const Key('grammar-finish-session'),
            tooltip: t.testerFeedbackCompleteGrammar,
            icon: const Icon(Icons.task_alt_rounded),
            onPressed: _sessionSeen.isEmpty ? null : _finishSession,
          ),
          const TtsSpeedAction(),
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
                    // 난이도(Leicht/Schwer)는 **필터 시트로 이동**했고, 진행바는
                    // Hören 과 같이 카드 **아래**로 내렸다. 학습 화면의 세로
                    // 공간은 카드가 먼저 가져간다 — C1/C2 처럼 예문이 길어질수록
                    // 고정 크롬이 카드를 눌러 읽기 어려워졌기 때문이다.
                    const SizedBox(height: Spacing.sm),

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
                                  final cardH =
                                      cardConstraints.maxHeight.isFinite
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
                                  // 네 동작이 메뉴로 노출된다 — 스와이프를 쓸 수
                                  // 없는 사용자가 하단 버튼 없이도 판정할 수 있다.
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
                                            CustomSemanticsAction(
                                              label: t.btnSkip,
                                            ): _skipCurrent,
                                        },
                                    child: SoriContentFeed(
                                      judgmentsEnabled: allowJudging && _flipped,
                                      onBlockedJudgment: allowJudging
                                          ? () {}
                                          : null,
                                      onNext: allowJudging
                                          ? () => _judge(understood: true)
                                          : null,
                                      onHard: allowJudging
                                          ? () => _judge(understood: false)
                                          : null,
                                      onSkip: _canNavigateDeck
                                          ? _skipCurrent
                                          : null,
                                      skipEnabled: _canNavigateDeck,
                                      onLike: _likeCurrent,
                                      onBookmark: _saveCurrent,
                                      onShare: _shareCurrent,
                                      onFlip: canRecordCheckpoint
                                          ? () => _showCheckpoint(
                                              g,
                                              assessmentLink!,
                                            )
                                          : _onFlip,
                                      liked: LikedContentService.isLiked(
                                        kind: LikedContentService.grammar,
                                        id: g.pattern,
                                      ),
                                      knowLabel: allowJudging
                                          ? t.grammarEasy
                                          : null,
                                      hardLabel: allowJudging
                                          ? t.grammarHard
                                          : null,
                                      skipLabel: t.btnSkip,
                                      bookmarkLabel: t.deckActionSave,
                                      child: SoriStudyScale(
                                        child: FlipCard(
                                          key: _cardKey,
                                          flipped: _flipped,
                                          onTap: canRecordCheckpoint
                                              ? () => _showCheckpoint(
                                                  g,
                                                  assessmentLink!,
                                                )
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
                    // 것이 없으므로 꺼진다. 두 아이콘 모두 44×44 터치 영역이다.
                    SoriProgressBar(
                      value: _filtered.isEmpty
                          ? 0
                          : (_idx + 1) / _filtered.length,
                      thickness: 6,
                      color: SoriColors.warning,
                      animated: true,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        // 듣기는 카드 안(읽어 주는 문장 옆)으로 옮겼다. 균형을
                        // 위해 실행취소와 같은 폭만 비워 카운터를 가운데 둔다.
                        const SizedBox(width: 44),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_idx + 1} / ${_filtered.length}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: s.textMuted,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
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
                          accent: SoriColors.warning,
                          fullWidth: true,
                          onTap: () => _showCheckpoint(g, assessmentLink!),
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
              const SizedBox(height: Spacing.md),
              _dropdown(t.filterLevel, stagedLevel, _levels, (v) {
                setLocal(() => stagedLevel = v!);
              }),
              const SizedBox(height: Spacing.sm + 2),
              _dropdown(t.filterType, stagedType, _types, (v) {
                setLocal(() => stagedType = v!);
              }),
              const SizedBox(height: Spacing.sm + 2),
              // 난이도는 학습 화면의 가로줄에서 여기로 옮겼다. 카드가 세로
              // 공간을 먼저 갖되, 스와이프로 모은 "Schwierig" 를 다시 모아
              // 볼 수 있어야 판정이 보상으로 돌아온다.
              // TODO(l10n): 'Leicht'/'Schwer' 는 이 화면이 원래 갖고 있던
              // 하드코딩 문자열을 그대로 옮긴 것이다. ARB 로 빼야 한다.
              Wrap(
                spacing: Spacing.xs + 2,
                children: [
                  for (final diff in const ['Alle', 'Leicht', 'Schwer'])
                    SoriChip(
                      label: diff == 'Alle' ? t.filterAll : diff,
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
                  _level = stagedLevel;
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
      accent: SoriColors.warning,
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
                accent: SoriColors.warning,
                variant: SoriChipVariant.filled,
              ),
              const SizedBox(height: Spacing.sm),
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
              Text(
                g.exampleKorean,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.09, 21, 48),
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
    final h = cardHeight;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.warning,
      width: double.infinity,
      // 히어로 학습 카드: spaceEvenly 로 세로를 채운다. 오버플로는 FlipCard 의
      // 스크롤 래퍼가 받아낸다(추가 스크롤뷰 불필요). 논리적으로 붙는 요소는
      // 내부 Column(min) 으로 묶어 spaceEvenly 가 흩뜨리지 않게 한다.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 레벨 칩 + 패턴(헤드라인) + 품사를 한 묶음으로.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriChip(
                label: g.level,
                accent: SoriColors.warning,
                variant: SoriChipVariant.filled,
              ),
              const SizedBox(height: 12),
              // 패턴 — 카드를 채우는 대형 헤드라인. 짧은 토큰이라 한 줄에
              // 맞추는 FittedBox(scaleDown)로 폭을 채운다.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  g.pattern,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.18, 30, 90),
                    fontWeight: FontWeight.w800,
                    color: SoriColors.warning,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                g.typeFor(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.05, 13, 26),
                  color: SoriColors.warning.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // 예문 미리보기 — 빈 카드를 채우고 패턴을 바로 용례로 보여줌.
          if (g.exampleKorean.isNotEmpty)
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
                      fontSize: soriFillSize(h, 0.075, 17, 40),
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
                        fontSize: soriFillSize(h, 0.05, 12.5, 26),
                        color: s.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
            style: TextStyle(
              fontSize: soriFillSize(h, 0.038, 12, 20),
              color: s.textDim,
            ),
          ),
          _ListenButton(korean: g.exampleKorean),
        ],
      ),
    );
  }
}

/// 카드 안 하단 중앙의 듣기 버튼.
///
/// 읽어 주는 문장 바로 옆에 두는 게 맞다 — 예전에는 카드 밖 액션 바에 있어서
/// 무엇을 읽는지가 위치로 드러나지 않았다. 탭 대상은 48dp 로, 최소 44×44
/// 권고보다 크게 잡았다(카드 전체 탭=뒤집기와 겹치므로 오조작이 비싸다).
class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.korean});

  final String korean;

  @override
  Widget build(BuildContext context) {
    if (korean.isEmpty) return const SizedBox.shrink();
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Semantics(
      button: true,
      label: t.btnHoeren,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => TtsService.speak(korean),
          borderRadius: BorderRadius.circular(SoriRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: SoriColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up, size: 18, color: s.text),
                const SizedBox(width: Spacing.xs + 2),
                Text(
                  t.btnHoeren,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: s.text,
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

class _Back extends StatelessWidget {
  final Grammar g;

  /// 카드가 놓인 바운드 영역의 유한 높이 — [soriFillSize] 기준.
  final double cardHeight;
  const _Back({required this.g, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final h = cardHeight;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.hangul,
      width: double.infinity,
      // 히어로 학습 카드: spaceEvenly 로 세로를 채운다. 오버플로는 FlipCard 의
      // 스크롤 래퍼가 받아낸다. 예문·주석은 각각 Column(min) 으로 묶는다.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 레벨 칩 + 패턴(헤드라인)을 한 묶음으로.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriChip(
                label: g.level,
                accent: SoriColors.hangul,
                variant: SoriChipVariant.filled,
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  g.pattern,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.10, 22, 52),
                    fontWeight: FontWeight.w800,
                    color: SoriColors.hangul,
                  ),
                ),
              ),
            ],
          ),
          // 설명 — 뒷면의 핵심 본문(여러 줄로 줄바꿈).
          Text(
            g.explanationFor(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: soriFillSize(h, 0.045, 13.5, 24),
              color: s.text,
              height: 1.5,
            ),
          ),
          // 예문(한국어 + 번역)을 한 묶음으로.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                g.exampleKorean,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.075, 16, 40),
                  fontWeight: FontWeight.w700,
                  color: SoriColors.hangul.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                g.exampleFor(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.05, 13, 26),
                  color: s.text,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          if (g.note.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: SoriColors.hangul.withValues(alpha: 0.25),
                  height: 1,
                ),
                const SizedBox(height: Spacing.xs + 2),
                Text(
                  g.noteFor(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.038, 11.5, 22),
                    color: s.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          // 뒤집어 설명을 보는 중에도 예문을 다시 들을 수 있어야 한다.
          _ListenButton(korean: g.exampleKorean),
        ],
      ),
    );
  }
}
