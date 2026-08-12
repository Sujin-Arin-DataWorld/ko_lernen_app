import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/course_practice_context.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../models/vocab.dart';
import '../models/vocab_pack.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_mission_navigation.dart';
import '../services/curriculum_catalog.dart';
import '../services/decoration_reward_service.dart';
import '../services/pack_progress_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/flip_card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/feature_coach.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/score_pop.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Vocab Pack Play Screen** — Phase 2 의 3-단계 학습 플로우.
///
/// 단계 진행:
///   1. **learn**   — 일반 단어 flip cards. "Gewusst" → SRS update + 다음.
///   2. **quiz**    — 일반 단어 4지선다 (한국어 → 독일어).
///   3. **boss**    — 보스 단어 4지선다 + TTS 재생 (한국어 발음 듣고 의미).
///
/// 모든 단계 끝나면 결과 화면(`/vocab/result`)으로 push & replace.
///
/// **Args (routes)**: `packId: String` (Navigator.pushNamed argument).
class VocabPackScreen extends StatefulWidget {
  final String packId;
  final CoursePracticeContext? courseContext;
  final Future<VocabPack?> Function(String packId)? packLoader;
  final Future<List<VocabPack>> Function(String level)? siblingPacksLoader;

  const VocabPackScreen({
    super.key,
    required this.packId,
    this.courseContext,
    this.packLoader,
    this.siblingPacksLoader,
  });

  @override
  State<VocabPackScreen> createState() => _VocabPackScreenState();
}

enum _Stage { learn, quiz, boss }

Map<String, dynamic> vocabPackResultArguments({
  required String packId,
  required String packLevel,
  required double bossAccuracy,
  required int bossCorrect,
  required int bossTotal,
  required int quizCorrect,
  required int quizTotal,
  required bool justCleared,
  required String? nextUnlockedPackId,
  required FeedbackCompletion feedbackCompletion,
  CoursePracticeContext? courseContext,
}) => <String, dynamic>{
  'packId': packId,
  'packLevel': packLevel,
  'bossAccuracy': bossAccuracy,
  'bossCorrect': bossCorrect,
  'bossTotal': bossTotal,
  'quizCorrect': quizCorrect,
  'quizTotal': quizTotal,
  'justCleared': justCleared,
  'nextUnlockedPackId': nextUnlockedPackId,
  'completionId': feedbackCompletion.context.completionId,
  'feedbackContext': feedbackCompletion.context,
  'courseContext': courseContext,
};

class _VocabPackScreenState extends State<VocabPackScreen> {
  bool _loading = true;
  String? _error;
  VocabPack? _pack;
  List<VocabPack> _siblingPacks = [];
  CourseMissionStep? _missionStep;
  String? _missionTitle;

  _Stage _stage = _Stage.learn;

  // Stage 1 (learn) state
  int _learnIdx = 0;
  bool _flipped = false;

  // Stage 2 (quiz) + Stage 3 (boss) state
  int _qIdx = 0;
  int _quizCorrect = 0;
  int _bossCorrect = 0;
  int _selectedChoice = -1;
  bool _choiceLocked = false;
  int _combo = 0; // 연속 정답 (도파민 루프)
  List<String>? _choices; // per-question 4-option cache

  // 동일 pack 내에서 distractor 풀로 사용. pack이 너무 작으면 sibling pack 단어로 채움.
  List<Vocab> _distractorPool = [];

  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _load();
    // 첫 진입 시 3단계 코치마크 1회 표시.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (!Storage.tutVocabPackSeen) {
        await showFeatureCoachSheet(context, FeatureCoach.vocabPack);
        await Storage.setTutVocabPackSeen();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final providedPackLoader = widget.packLoader;
      final pack = providedPackLoader != null
          ? await providedPackLoader(widget.packId)
          : await VocabPackService.findById(widget.packId);
      if (!mounted) return;
      if (pack == null) {
        setState(() {
          _loading = false;
          _error = AppL10n.of(context).loadErrorTryAgain;
        });
        return;
      }
      // Sibling packs — Distractor 풀 보강용 (같은 level).
      final providedSiblingLoader = widget.siblingPacksLoader;
      final siblings = providedSiblingLoader != null
          ? await providedSiblingLoader(pack.level)
          : await VocabPackService.packsForLevel(pack.level);
      final courseContext = widget.courseContext;
      final catalog = courseContext?.isFor(CurriculumContentKind.vocab) == true
          ? await CurriculumCatalog.load()
          : null;
      if (!mounted) return;
      final languageCode = Localizations.localeOf(context).languageCode;
      final pool = <Vocab>[
        ...pack.words,
        for (final p in siblings)
          if (p.id != pack.id) ...p.words,
      ];
      final packCourseContext = vocabCourseContextForPack(
        courseContext: courseContext,
        contentIds: pack.words.map((word) => word.id),
      );
      final candidateMissionStep = catalog == null || packCourseContext == null
          ? null
          : CourseMissionStepPlan.fromLinks(
              catalog.linksForCourseUnit(packCourseContext.courseUnitId),
            ).stepForContentLinkId(packCourseContext.contentLinkId);
      final missionStep =
          candidateMissionStep == null ||
              packCourseContext == null ||
              candidateMissionStep.link.contentKind !=
                  CurriculumContentKind.vocab ||
              candidateMissionStep.link.contentId !=
                  packCourseContext.initialContentId ||
              candidateMissionStep.link.courseUnitId !=
                  packCourseContext.courseUnitId
          ? null
          : candidateMissionStep;
      final missionTitle =
          catalog == null || packCourseContext == null || missionStep == null
          ? null
          : catalog
                .courseUnitFor(packCourseContext.courseUnitId)
                ?.title
                .pick(languageCode);
      setState(() {
        _pack = pack;
        _siblingPacks = siblings;
        _distractorPool = pool;
        _missionStep = missionStep;
        _missionTitle = missionTitle;
        _loading = false;
      });
      _prepareNextQuestion(); // pre-warm choice cache for stage 1 → 2 transition
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  List<Vocab> get _normalWords => _pack?.normalWords.toList() ?? const [];

  List<Vocab> get _bossWords => _pack?.bossWords.toList() ?? const [];

  Vocab? get _currentLearn =>
      _learnIdx < _normalWords.length ? _normalWords[_learnIdx] : null;

  Vocab? get _currentQuiz {
    switch (_stage) {
      case _Stage.learn:
        return null;
      case _Stage.quiz:
        return _qIdx < _normalWords.length ? _normalWords[_qIdx] : null;
      case _Stage.boss:
        return _qIdx < _bossWords.length ? _bossWords[_qIdx] : null;
    }
  }

  // ── Stage 1 (Learn) ────────────────────────────────────────────────

  void _learnGotIt() {
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.lightImpact();
    Storage.addVokSeen(cur.korean);
    // ignore: discarded_futures
    Storage.srsReview(cur.korean, gotIt: true);
    _advanceLearn();
  }

  void _learnDontKnow() {
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.mediumImpact();
    Storage.addVokSeen(cur.korean);
    // ignore: discarded_futures
    Storage.srsReview(cur.korean, gotIt: false);
    _advanceLearn();
  }

  void _advanceLearn() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _learnIdx++;
    });
    if (_learnIdx >= _normalWords.length) {
      // Stage 1 끝 — wordsLearned 기록 후 stage 2 진입
      // ignore: discarded_futures
      PackProgressService.recordWordLearned(pack);
      _enterQuiz();
    }
  }

  // ── Stage 2 / 3 (Quiz / Boss) ──────────────────────────────────────

  void _enterQuiz() {
    if (_normalWords.isEmpty) {
      // 일반 단어 없으면 바로 boss
      _enterBoss();
      return;
    }
    setState(() {
      _stage = _Stage.quiz;
      _qIdx = 0;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    // 퀴즈도 "듣고 고르기"로 통일 — 첫 단어 자동 발음 재생.
    _speakCurrent();
    // 스테이지 전환 인라인 배너 — 최초 1회만 (모달보다 학습 흐름 덜 끊음).
    if (!Storage.tutPackQuizSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).coachPackStageQuiz),
                duration: const Duration(seconds: 3),
              ),
            )
            .closed;
        await Storage.setTutPackQuizSeen();
      });
    }
  }

  void _enterBoss() {
    if (_bossWords.isEmpty) {
      // 보스 없으면 perfect로 간주 (edge case — 작은 팩)
      _finish(bossAccuracy: 1.0, bossCorrect: 0, bossTotal: 0);
      return;
    }
    setState(() {
      _stage = _Stage.boss;
      _qIdx = 0;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    // Boss 첫 단어 자동 발음 재생.
    _speakCurrent();
    // 스테이지 전환 인라인 배너 — 최초 1회만.
    if (!Storage.tutPackBossSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).coachPackStageBoss),
                duration: const Duration(seconds: 3),
              ),
            )
            .closed;
        await Storage.setTutPackBossSeen();
      });
    }
  }

  /// 4지선다 옵션 생성 — 정답 + 같은 level pool 에서 3 distractor.
  void _prepareNextQuestion() {
    final cur = _currentQuiz;
    if (cur == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final correct = cur.translationFor(lang);
    final pool = _distractorPool
        .where(
          (v) => v.korean != cur.korean && v.translationFor(lang) != correct,
        )
        .map((v) => v.translationFor(lang))
        .toSet()
        .toList();
    pool.shuffle(_rng);
    final distractors = pool.take(3).toList();
    final all = <String>[correct, ...distractors];
    all.shuffle(_rng);
    setState(() {
      _choices = all;
      _selectedChoice = -1;
      _choiceLocked = false;
    });
  }

  /// 현재 문제(퀴즈/보스)의 한국어를 자동 발음 재생.
  ///
  /// 퀴즈·보스는 둘 다 "큰 한국어 단어를 보고 뜻 고르기" — 예전엔 노란 보스만
  /// 소리가 나고 파란 퀴즈는 무음이라 "듣고 고르기"가 뒤섞여 보였다. 두 단계를
  /// 모두 자동 재생으로 통일한다.
  void _speakCurrent() {
    final cur = _currentQuiz;
    if (cur == null) {
      return;
    }
    // ignore: discarded_futures
    TtsService.speak(cur.korean);
  }

  void _selectChoice(int i) {
    if (_choiceLocked) return;
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final isCorrect = choices[i] == cur.translationFor(lang);
    setState(() {
      _selectedChoice = i;
      _choiceLocked = true;
    });
    // Only scored recall stages become course evidence. The earlier card
    // self-rating stays in SRS only, so a tap cannot unlock a mission.
    // ignore: discarded_futures
    CourseActivityReporter.recordContentAttempt(
      CurriculumContentKind.vocab,
      cur.id,
      isCorrect,
      errorReason: isCorrect ? null : MasteryErrorReason.vocabularyRecall,
    );
    if (isCorrect) {
      // 정답 순간 보상 — 햅틱 + 효과음 + 색종이 burst + 콤보.
      HapticFeedback.lightImpact();
      SoundService.correct();
      SoriCelebration.burst(context);
      _combo++;
      if (_combo >= 3) {
        SoundService.combo();
        ScorePop.show(
          context,
          AppL10n.of(context).comboPop(_combo),
          color: SoriColors.tiger,
        );
      }
      if (_stage == _Stage.quiz) {
        _quizCorrect++;
        Storage.addVokSeen(cur.korean);
        // ignore: discarded_futures
        Storage.srsReview(cur.korean, gotIt: true);
      } else {
        _bossCorrect++;
        Storage.addVokSeen(cur.korean);
        // ignore: discarded_futures
        Storage.srsReview(cur.korean, gotIt: true);
      }
    } else {
      // 오답 — 더 강한 햅틱 + 부드러운 효과음, 콤보 리셋.
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _combo = 0;
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: false);
    }
    // 짧은 피드백 후 다음 질문
    Future.delayed(const Duration(milliseconds: 850), _advanceQuiz);
  }

  void _advanceQuiz() {
    if (!mounted) return;
    final isQuiz = _stage == _Stage.quiz;
    final total = isQuiz ? _normalWords.length : _bossWords.length;
    if (_qIdx + 1 >= total) {
      if (isQuiz) {
        _enterBoss();
      } else {
        _finish(
          bossAccuracy: _bossWords.isEmpty
              ? 1.0
              : _bossCorrect / _bossWords.length,
          bossCorrect: _bossCorrect,
          bossTotal: _bossWords.length,
        );
      }
      return;
    }
    setState(() {
      _qIdx++;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    // 퀴즈·보스 모두 다음 단어 자동 발음(듣고 고르기 통일).
    _speakCurrent();
  }

  // ── Finish ─────────────────────────────────────────────────────────

  Future<void> _finish({
    required double bossAccuracy,
    required int bossCorrect,
    required int bossTotal,
  }) async {
    final pack = _pack;
    if (pack == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final feedbackCompletion = FeedbackCompletion.vocabPack(
      packId: pack.id,
      contentLabel: VocabPackService.displayLabel(pack.id, lang: lang),
      level: pack.level,
      bossCorrect: bossCorrect,
      bossTotal: bossTotal,
      quizCorrect: _quizCorrect,
      quizTotal: _normalWords.length,
    );
    // SiblingPacks 같은 level (이미 _siblingPacks). 정렬된 pack list.
    final result = await PackProgressService.recordBossAttempt(
      pack,
      _siblingPacks,
      bossAccuracy: bossAccuracy,
    );
    final missionContext = _missionStep == null ? null : widget.courseContext;
    if (missionContext != null) {
      final totalAnswers = _normalWords.length + bossTotal;
      final correctAnswers = _quizCorrect + bossCorrect;
      final courseScore = totalAnswers == 0
          ? 0.0
          : correctAnswers / totalAnswers;
      await CourseActivityReporter.recordContentAttempt(
        CurriculumContentKind.vocab,
        missionContext.initialContentId,
        courseScore >= .70,
        courseContext: missionContext,
        errorReason: courseScore >= .70
            ? null
            : MasteryErrorReason.vocabularyRecall,
        score: courseScore,
      );
    }
    // XP 보상 (Plan §4.4) — wordsTotal*5 + bossCorrect*10
    await Storage.addXp(pack.total * 5 + bossCorrect * 10);
    // 도장 획득 — 첫 클리어 시 토픽군 motif 도장을 도장첩에 추가.
    if (result.justCleared) {
      await Storage.addEarnedStamp(motifForPackId(pack.id).name);
      // 첫 클리어 = 보자기 하나. 팩 출처(`pack:<id>`)로 큐에 넣으면 홈·사랑방
      // 발견 배너가 바로 집어 든다(퀘스트 화면 불필요). justCleared + 큐 dedup
      // 으로 팩당 정확히 1개.
      await DecorationRewardService.ensurePendingBox(
        '${DecorationRewardService.kPackSourcePrefix}${pack.id}',
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/vocab/result',
      arguments: vocabPackResultArguments(
        packId: pack.id,
        packLevel: pack.level,
        bossAccuracy: bossAccuracy,
        bossCorrect: bossCorrect,
        bossTotal: bossTotal,
        quizCorrect: _quizCorrect,
        quizTotal: _normalWords.length,
        justCleared: result.justCleared,
        nextUnlockedPackId: result.nextUnlocked?.id,
        feedbackCompletion: feedbackCompletion,
        courseContext: _missionStep == null ? null : widget.courseContext,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabPackPlayTitle)),
        body: const AppLoading(),
      );
    }
    if (_error != null || _pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabPackPlayTitle)),
        body: AppError(message: _error ?? 'unknown error', onRetry: _load),
      );
    }

    final pack = _pack!;
    final title = VocabPackService.displayLabel(pack.id);
    // 현재 보고 있는 단어(학습/퀴즈/보스)를 바로 내 단어장에 담기.
    final Vocab? addable = _stage == _Stage.learn
        ? _currentLearn
        : _currentQuiz;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (addable != null)
            AddToWordbookButton(
              korean: addable.korean,
              translationDe: addable.german,
              romanization: addable.romanization,
              posDe: addable.posDe,
              exampleKorean: addable.exampleKorean,
              exampleDe: addable.exampleGerman,
              compact: true,
            ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  if (_missionStep case final step?) ...[
                    MissionContextBar(
                      missionTitle: _missionTitle ?? t.courseMissionTitleShort,
                      step: step,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  _StageBar(stage: _stage),
                  const SizedBox(height: Spacing.md),
                  Expanded(child: _buildStageBody(t)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageBody(AppL10n t) {
    switch (_stage) {
      case _Stage.learn:
        return _buildLearn(t);
      case _Stage.quiz:
      case _Stage.boss:
        return _buildQuiz(t);
    }
  }

  Widget _buildLearn(AppL10n t) {
    final cur = _currentLearn;
    if (cur == null) {
      // 일반 단어 0개인 edge case (보스만 있는 팩) → 바로 quiz/boss
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterQuiz());
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Row(
          children: [
            SoriChip(
              label: '${_learnIdx + 1} / ${_normalWords.length}',
              accent: SoriColors.info,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.vocabPackLearnHint,
              style: TextStyle(
                fontSize: 12,
                color: SoriSurfaces.of(context).textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: SoriStudyScale(
            // 카드가 놓인 세로 영역(Expanded)은 바운드 높이다. 그 높이를 읽어
            // 앞/뒷면 학습 텍스트를 카드 크기에 비례해 키운다 → 기기와 무관하게
            // 균일한 세로 충전율(review_session 히어로 카드와 동일 규칙).
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 타이포 기준은 **뷰포트**에서 뽑는다. 남은 공간을 쓰면 미션
                // 배너 유무만으로 글씨 크기가 달라진다 — (1)에는 배너가 있고
                // (2)에는 없어 같은 카드인데 (2)가 훨씬 컸다(Jin, 2026-08-12).
                final h = soriStudyTypeScaleHeight(context);
                return FlipCard(
                  flipped: _flipped,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _flipped = !_flipped);
                  },
                  front: _FlipFront(v: cur, h: h),
                  back: _FlipBack(v: cur, h: h),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: SoriButton(
                label: t.vocabPackDontKnow,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.danger,
                onTap: _learnDontKnow,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: SoriButton(
                label: t.vocabPackGotIt,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.success,
                onTap: _learnGotIt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuiz(AppL10n t) {
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _stage == _Stage.quiz
        ? _normalWords.length
        : _bossWords.length;
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Row(
          children: [
            SoriChip(label: '${_qIdx + 1} / $total', accent: SoriColors.info),
            const SizedBox(width: Spacing.sm),
            Text(
              _stage == _Stage.boss ? t.vocabPackBossHint : t.vocabPackQuizHint,
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // 단어 카드 + 4지선다를 남는 세로 공간에 **여유롭게 분산**한다.
        // 이전엔 카드 바로 밑에 보기를 붙이고(topCenter) 하단이 텅 비었음
        // (Jin 실기기 반복 지적). cloze/데일리챌린지의 검증된 패턴 재사용 —
        // spaceEvenly 로 화면을 채우되, 큰 글자에선 스크롤로 안전.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 프롬프트 히어로 카드의 학습 텍스트(제시어·로마자) 크기.
              // 학습 단계와 같은 기준(뷰포트)을 써야 단계를 오갈 때 글씨가
              // 튀지 않는다 — 남은 공간을 쓰면 화면에 얹힌 요소에 따라 달라진다.
              final h = soriStudyTypeScaleHeight(context);
              final promptCard = SoriCard(
                variant: SoriCardVariant.hero,
                accent: _stage == _Stage.boss
                    ? SoriColors.warning
                    : SoriColors.info,
                tinted: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cur.korean,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: soriFillSize(h, 0.08, 36, 72),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '[${cur.romanization}]',
                      style: TextStyle(
                        fontSize: soriFillSize(h, 0.03, 14, 24),
                        color: s.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    // "Erneut anhören" — 퀴즈·보스 둘 다 노출(둘 다 자동 재생 통일).
                    const SizedBox(height: Spacing.md),
                    SoriButton(
                      label: t.vocabPackBossReplayAudio,
                      icon: Icons.volume_up_rounded,
                      variant: SoriButtonVariant.outlined,
                      accent: _stage == _Stage.boss
                          ? SoriColors.warning
                          : SoriColors.info,
                      onTap: () {
                        // ignore: discarded_futures
                        TtsService.speak(cur.korean);
                      },
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SoriStudyScale(child: promptCard),
                        for (var i = 0; i < choices.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.xs,
                            ),
                            child: QuizChoice(
                              text: choices[i],
                              isCorrect: choices[i] == cur.translationFor(lang),
                              isSelected: i == _selectedChoice,
                              revealed: _choiceLocked,
                              // 넉넉한 화면을 채우도록 보기 박스를 더 크게.
                              minHeight: 60,
                              onSelected: _choiceLocked
                                  ? null
                                  : () => _selectChoice(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StageBar extends StatelessWidget {
  final _Stage stage;
  const _StageBar({required this.stage});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final stages = [
      ('learn', t.vocabPackStageLearn, _Stage.learn),
      ('quiz', t.vocabPackStageQuiz, _Stage.quiz),
      ('boss', t.vocabPackStageBoss, _Stage.boss),
    ];
    return Row(
      children: stages.map((triple) {
        final active = triple.$3 == stage;
        final done = stage.index > triple.$3.index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: done
                    ? SoriColors.success
                    : (active
                          ? SoriColors.info
                          : SoriColors.info.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FlipFront extends StatelessWidget {
  final Vocab v;

  /// 카드가 놓인 세로 영역의 바운드 높이 — 학습 텍스트를 카드에 비례해 키우는
  /// 기준. `_buildLearn` 의 LayoutBuilder 가 넘겨준다.
  final double h;
  const _FlipFront({required this.v, required this.h});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    // 카드 안쪽 높이(h)에 비례한 히어로 타이포. spaceEvenly 로 세로를 채우되
    // 발음 정보(듣기 버튼 + 로마자)는 한 묶음으로 두어 흩어지지 않게 한다.
    // FlipCard._fitFace 가 이미 SingleChildScrollView + minHeight 로 감싸므로
    // 넘칠 땐 스크롤로 안전(별도 스크롤 래핑 불필요).
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      tinted: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 제시어 — 카드를 채우는 대형 헤드라인. 긴 단어는 scaleDown 으로 한 줄에.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              v.korean,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: soriFillSize(h, 0.18, 36, 96),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
          ),
          // 듣기 버튼 + 로마자를 한 묶음으로(발음 정보끼리 붙어 있게).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.volume_up_rounded,
                  size: soriFillSize(h, 0.085, 28, 52),
                ),
                onPressed: () {
                  // ignore: discarded_futures
                  TtsService.speak(v.korean);
                },
              ),
              SizedBox(height: soriFillSize(h, 0.02, 6, 16)),
              Text(
                '[${v.romanization}]',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.048, 16, 28),
                  color: s.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          // 인라인 아이콘 + 힌트 — Text.rich라 좁은 폭에서 자연스럽게 줄바꿈.
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: s.textDim,
                  ),
                ),
                const WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: AppL10n.of(context).vocabPackTapToFlip),
              ],
            ),
            style: TextStyle(
              fontSize: soriFillSize(h, 0.032, 12, 20),
              color: s.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipBack extends StatelessWidget {
  final Vocab v;

  /// 카드가 놓인 세로 영역의 바운드 높이 — 학습 텍스트를 카드에 비례해 키우는
  /// 기준. `_buildLearn` 의 LayoutBuilder 가 넘겨준다.
  final double h;
  const _FlipBack({required this.v, required this.h});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    // 뜻·품사는 한 묶음(의미), 예문 요소는 또 한 묶음으로 두어 spaceEvenly 가
    // 흩뜨리지 않게 한다. 카드 안쪽 높이(h)에 비례해 텍스트가 카드를 채운다.
    // 넘칠 땐 FlipCard._fitFace 의 SingleChildScrollView 가 스크롤로 받아낸다.
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뜻(헤드라인) + 품사 — 의미 묶음. 뜻은 줄바꿈 허용(FittedBox 미사용).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  v.translationFor(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.11, 28, 48),
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: soriFillSize(h, 0.02, 6, 14)),
              Text(
                v.posFor(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.045, 14, 26),
                  color: s.textMuted,
                ),
              ),
            ],
          ),
          // 예문(한국어 + 번역)을 한 묶음으로.
          if (v.exampleKorean.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.exampleKorean,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.072, 18, 38),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: soriFillSize(h, 0.02, 4, 16)),
                Text(
                  v.exampleFor(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.048, 14, 28),
                    color: s.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
