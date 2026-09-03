import 'dart:async';
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
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_mission_navigation.dart';
import '../services/curriculum_catalog.dart';
import '../services/learn_session_queue.dart';
import '../services/korean_romanization.dart';
import '../services/pack_progress_service.dart';
import '../services/pack_session_srs_ledger.dart';
import '../services/quiz_distractor_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_finish_coordinator.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/flip_card.dart';
import '../widgets/flashcard_romanization_action.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/feature_coach.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../widgets/sori/toast.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/score_pop.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Vocab Pack Play Screen** — Phase 2 의 3-단계 학습 플로우.
///
/// 단계 진행:
///   1. **learn**   — 현재 팩의 모든 단어 flip cards (Boss 단어 포함).
///   2. **quiz**    — 일반 단어 4지선다 (한국어 → 독일어).
///   3. **boss**    — 현재 팩 Boss 단어 4지선다 + TTS 재생 (인식 평가).
///
/// 모든 단계 끝나면 결과 화면(`/vocab/result`)으로 push & replace.
///
/// **Args (routes)**: `packId: String` (Navigator.pushNamed argument).
typedef VocabPackAdvanceTimerFactory =
    Timer Function(Duration duration, void Function() callback);

class VocabPackScreen extends StatefulWidget {
  final String packId;
  final CoursePracticeContext? courseContext;
  final Future<VocabPack?> Function(String packId)? packLoader;
  final Future<List<VocabPack>> Function(String level)? siblingPacksLoader;
  final VocabPackFinishOperations? finishOperations;
  final VocabPackAdvanceTimerFactory? advanceTimerFactory;

  const VocabPackScreen({
    super.key,
    required this.packId,
    this.courseContext,
    this.packLoader,
    this.siblingPacksLoader,
    this.finishOperations,
    this.advanceTimerFactory,
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
  bool showHardWordsCta = false,
  PackRecallSession? recallSession,
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
  'showHardWordsCta': showHardWordsCta,
  'recallSession': recallSession,
};

/// Returns a one-time assessment order that is shuffled but never leaves a
/// multi-item list in its original order. The caller supplies [rng] so tests
/// can use `Random(seed)` while the app uses an unseeded session RNG.
List<T> shuffledAssessmentOrder<T>(
  Iterable<T> items, {
  required math.Random rng,
}) {
  final original = items.toList(growable: false);
  final shuffled = List<T>.of(original)..shuffle(rng);
  if (shuffled.length > 1 && _sameAssessmentOrder(shuffled, original)) {
    final first = shuffled.removeAt(0);
    shuffled.add(first);
  }
  return shuffled;
}

bool _sameAssessmentOrder<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

/// Only offer the existing Hard Words set when an item missed in this pack
/// session has reached its existing leech or explicit-wrong-count threshold.
bool shouldOfferHardWordPractice(Iterable<String> sessionMissedWordIds) {
  final ids = sessionMissedWordIds.toSet();
  if (ids.isEmpty) {
    return false;
  }
  return Storage.hardIds(ids).isNotEmpty ||
      Storage.frequentlyMissedIds(ids).isNotEmpty;
}

class _VocabPackScreenState extends State<VocabPackScreen> {
  bool _loading = true;
  String? _error;
  VocabPack? _pack;
  bool _learningStartRecorded = false;
  List<VocabPack> _siblingPacks = [];
  CourseMissionStep? _missionStep;
  String? _missionTitle;

  _Stage _stage = _Stage.learn;

  // Stage 1 (learn) state — 재출제 큐 (테스터 피드백 ②: "몰라요"가 세션 내에서
  // 차이를 만들도록). null = 로드 전.
  LearnSessionQueue<Vocab>? _learnQueue;
  // SRS 는 단어당 **최초 답변 1회만** 평가 — 재출제로 같은 단어를 여러 번
  // 틀려도 ease 가 세션 안에서 연타로 깎이지 않게. (오답 카운터는 매번 셈.)
  final Set<String> _learnSrsRated = {};
  bool _flipped = false;
  bool _romanizationOnFront = Storage.flashcardRomanizationOnFront;
  // 앞면을 보는 것만으로는 단어 뜻을 가르쳤다고 볼 수 없다. 카드 뒷면을 한 번
  // 연 뒤에만 판정/스와이프를 허용해, Boss 단어를 포함한 모든 Learn 단어가
  // 평가 전 의도적으로 노출되도록 한다.
  bool _learnCardRevealed = false;
  // 카드 서빙마다 증가 — FlipCard re-key용. 같은 setState에서 _flipped=false와
  // 인덱스가 함께 바뀌면 FlipCard가 다음 카드 내용 위로 reverse 애니메이션을
  // 돌려 뒷면(뜻)이 먼저 보인다. 새 key로 State를 새로 만들면 항상 앞면 시작.
  int _learnServe = 0;
  // 이 세션에서 재출제로 다시 나온 카드 수 — "3/9 · +2 Wdh." 표시용
  // (지시서 검수#21: 별도 칩이 아니라 숫자에 병기).
  int _learnRepeatCount = 0;

  // Stage 2 (quiz) + Stage 3 (boss) state
  int _qIdx = 0;
  int _quizCorrect = 0;
  int _bossCorrect = 0;
  int _selectedChoice = -1;
  bool _choiceLocked = false;
  bool _hasSubmittedAssessment = false;
  int _combo = 0; // 연속 정답 (도파민 루프)
  List<String>? _choices; // per-question 4-option cache

  // 동일 pack 내에서 distractor 풀로 사용. pack이 너무 작으면 sibling pack 단어로 채움.
  List<Vocab> _distractorPool = [];

  // Learn 단계가 끝난 뒤 한 번만 만드는 평가 순서. 일반 Quiz와 Boss의
  // current-pack 멤버십은 그대로 두되, Learn 순서가 힌트가 되지 않게 한다.
  List<Vocab> _quizQuestions = const [];
  List<Vocab> _bossQuestions = const [];
  bool _assessmentOrdersPrepared = false;
  final _assessmentOrderRng = math.Random();

  // 이 세션에서 틀린 단어만 결과의 Hard Words CTA 후보가 된다. 기존
  // hard/leech 기준을 넘은 경우에만 CTA를 노출해 단발 오답을 과잉 분기하지 않는다.
  final Set<String> _sessionMissedWordIds = {};
  // One ephemeral ledger follows this pack through its optional result/typed
  // recall route. It coalesces each word's SRS evidence without adding a
  // persisted LearningAttempt model or migration.
  PackRecallSession? _recallSession;

  final _rng = math.Random();

  // §P2-5 플립 게이트 힌트 칩 트리거 — 저항 드래그/판정 버튼 탭당 1펄스.
  final ValueNotifier<int> _flipHintTrigger = ValueNotifier<int>(0);
  // AppBar 단어장 버튼(quiz/boss)의 스포트라이트 코치 게이팅용 — 팩 진입
  // 3단계 모달 코치가 먼저 끝나야 전역 단어장 코치가 뒤이어 뜬다.
  late bool _featureCoachComplete;
  late final QuestAbandonTracker _abandonTracker;
  late final VocabPackFinishCoordinator _finishCoordinator;
  VocabPackFinishRequest? _finishRequest;
  bool _finishing = false;
  String? _finishError;
  Timer? _advanceTimer;

  @override
  void dispose() {
    _cancelAdvanceTimer();
    _persistLearnProgress();
    _abandonTracker.dispose();
    _flipHintTrigger.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _featureCoachComplete = Storage.tutVocabPackSeen;
    _abandonTracker = QuestAbandonTracker(
      questType: 'vocab_pack',
      questId: widget.packId,
      lastStepReached: () => '${_stage.name}_$_qIdx',
    );
    _finishCoordinator = VocabPackFinishCoordinator(
      widget.finishOperations ?? const DefaultVocabPackFinishOperations(),
    );
    _load();
    // 첫 진입 시 3단계 코치마크 1회 표시.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (!Storage.tutVocabPackSeen) {
        await showFeatureCoachSheet(context, FeatureCoach.vocabPack);
        await Storage.setTutVocabPackSeen();
        if (mounted) {
          setState(() => _featureCoachComplete = true);
        }
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
      if (!_learningStartRecorded) {
        _learningStartRecorded = true;
        Analytics.lessonStarted(
          lessonType: 'vocab',
          lessonId: pack.id,
          level: pack.level.toUpperCase(),
        );
      }
      setState(() {
        _pack = pack;
        _siblingPacks = siblings;
        _distractorPool = pool;
        _missionStep = missionStep;
        _missionTitle = missionTitle;
        _learnQueue = LearnSessionQueue<Vocab>(
          pack.learnWords.toList(),
          idOf: (v) => v.korean,
        );
        _learnSrsRated.clear();
        _flipped = false;
        _learnCardRevealed = false;
        _sessionMissedWordIds.clear();
        _recallSession = PackRecallSession.forPack(packId: pack.id);
        _quizQuestions = const [];
        _bossQuestions = const [];
        _assessmentOrdersPrepared = false;
        _hasSubmittedAssessment = false;
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

  List<Vocab> get _learnWords => _pack?.learnWords.toList() ?? const [];

  Vocab? get _currentLearn => _learnQueue?.current;

  Vocab? get _currentQuiz {
    switch (_stage) {
      case _Stage.learn:
        return null;
      case _Stage.quiz:
        return _qIdx < _quizQuestions.length ? _quizQuestions[_qIdx] : null;
      case _Stage.boss:
        return _qIdx < _bossQuestions.length ? _bossQuestions[_qIdx] : null;
    }
  }

  // ── Stage 1 (Learn) ────────────────────────────────────────────────

  void _learnGotIt() {
    if (!_learnCardRevealed) {
      return;
    }
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.lightImpact();
    Storage.addVokSeen(cur.korean);
    if (_learnSrsRated.add(cur.korean)) {
      // 처음 몰랐다가 재출제에서 맞힌 단어는 이 분기에 안 들어온다 —
      // 최초의 정직한 "몰랐다" 평가가 유지된다.
      _recordSessionSrs(cur.korean, gotIt: true);
    }
    _learnQueue?.markKnown();
    _advanceLearn();
  }

  void _learnDontKnow() {
    if (!_learnCardRevealed) {
      return;
    }
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.mediumImpact();
    Storage.addVokSeen(cur.korean);
    if (_learnSrsRated.add(cur.korean)) {
      _recordSessionSrs(cur.korean, gotIt: false);
    }
    // 오답 카운터는 SRS 와 달리 **모든** 인출 실패를 센다 — 한 세션에서
    // 3번 틀리면 그 자리에서 Extra-Lernset 임계치(3)에 도달한다.
    _sessionMissedWordIds.add(cur.korean);
    // ignore: discarded_futures
    Storage.incrementWrongCount(cur.korean);
    _learnQueue?.markUnknown();
    _advanceLearn();
  }

  void _advanceLearn() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _learnCardRevealed = false;
      _learnServe++;
      if (_learnQueue?.currentIsRepeat ?? false) {
        _learnRepeatCount++;
      }
    });
    if (_learnQueue?.isDone ?? true) {
      // Stage 1 끝 — 모든 current-pack 단어를 Learn에서 의도적으로 노출한 뒤
      // wordsLearned 기록 및 평가 단계로 진입.
      // ignore: discarded_futures
      PackProgressService.recordWordLearned(pack);
      _enterQuiz();
    }
  }

  /// Learn 단계를 완주하지 않고 이탈해도 그때까지 본 단어 수를 영속화한다
  /// (지시서 1.1 "3/9 멈춤" — 완주해야만 recordWordLearned 가 불렸던 것을
  /// 이탈 시에도 flush). wordsLearnedIn 은 vokSeenIds 교집합으로 유도하므로
  /// 여러 번 불러도 멱등 — 세션당 완주 시 1회(_advanceLearn) + 이탈 시 1회
  /// (dispose) = 최대 2회.
  void _persistLearnProgress() {
    final pack = _pack;
    if (pack == null) return;
    // ignore: discarded_futures
    PackProgressService.recordWordLearned(pack);
  }

  void _toggleLearnFlip() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_flipped) {
        _learnCardRevealed = true;
      }
      _flipped = !_flipped;
    });
  }

  /// ↑ 저장 (§P2-2) — SRS·오답·ledger 를 절대 건드리지 않는다. 전진 없음.
  /// 중복 저장은 quickAdd 의 `alreadyExists` 스낵바로 해소.
  void _saveCurrent() {
    final cur = _currentLearn;
    if (cur == null) {
      return;
    }
    // ignore: discarded_futures
    addToWordbook(
      context,
      korean: cur.korean,
      translationDe: cur.german,
      translationEn: cur.english,
      romanization: cur.romanization,
      posDe: cur.posDe,
      exampleKorean: cur.exampleKorean,
      exampleDe: cur.exampleGerman,
      exampleEn: cur.exampleEnglish,
      source: 'content_bookmark',
    );
  }

  Future<void> _likeCurrent() async {
    final cur = _currentLearn;
    if (cur == null) {
      return;
    }
    await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: cur.korean,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareCurrent() async {
    final cur = _currentLearn;
    if (cur == null) {
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    await shareContentStoryWithRecovery(
      context: context,
      korean: cur.korean,
      gloss: cur.translationFor(lang),
    );
  }

  /// ↓ 스킵 (§P2-2) — **기록 없는 미루기**. SRS/오답/ledger 금지 대상이 아닌
  /// 건 재서빙 리셋뿐이다: defer 는 큐를 비우지 않으므로 `_advanceLearn` 의
  /// `isDone→_enterQuiz` 분기는 발동 불가.
  void _learnDefer() {
    final queue = _learnQueue;
    if (queue == null || queue.isDone) {
      return;
    }
    HapticFeedback.selectionClick();
    queue.defer();
    _advanceLearn();
  }

  void _recordSessionSrs(String korean, {required bool gotIt}) {
    final session = _recallSession;
    if (session == null) {
      return;
    }
    final action = gotIt
        ? session.recordPositiveFor(
            expectedPackId: session.packId,
            wordId: korean,
          )
        : session.recordNegativeFor(
            expectedPackId: session.packId,
            wordId: korean,
          );
    if (!action.writesSrs) {
      return;
    }
    // ignore: discarded_futures
    Storage.srsReview(korean, gotIt: action.gotIt!);
  }

  // ── Stage 2 / 3 (Quiz / Boss) ──────────────────────────────────────

  void _prepareAssessmentOrders() {
    if (_assessmentOrdersPrepared) {
      return;
    }
    final pack = _pack;
    if (pack == null) {
      return;
    }
    _quizQuestions = shuffledAssessmentOrder(
      pack.normalWords,
      rng: _assessmentOrderRng,
    );
    _bossQuestions = shuffledAssessmentOrder(
      pack.bossWords,
      rng: _assessmentOrderRng,
    );
    _assessmentOrdersPrepared = true;
  }

  void _enterQuiz() {
    _cancelAdvanceTimer();
    _prepareAssessmentOrders();
    if (_quizQuestions.isEmpty) {
      // 일반 단어 없으면 바로 boss
      unawaited(_enterBoss());
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
        final notice = showSoriToast(
          context,
          AppL10n.of(context).coachPackStageQuiz,
          tone: SoriToastTone.neutral,
          duration: const Duration(seconds: 3),
        );
        if (notice != null) {
          await notice.closed;
        }
        await Storage.setTutPackQuizSeen();
      });
    }
  }

  Future<void> _enterBoss() async {
    _cancelAdvanceTimer();
    _prepareAssessmentOrders();
    if (_bossQuestions.isEmpty) {
      // 보스 없으면 perfect로 간주 (edge case — 작은 팩)
      await _finish(bossAccuracy: 1.0, bossCorrect: 0, bossTotal: 0);
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
        final notice = showSoriToast(
          context,
          AppL10n.of(context).coachPackStageBoss,
          tone: SoriToastTone.neutral,
          duration: const Duration(seconds: 3),
        );
        if (notice != null) {
          await notice.closed;
        }
        await Storage.setTutPackBossSeen();
      });
    }
  }

  /// 4지선다 옵션 생성 — 정답 + 같은 품사·레벨 우선 3 distractor
  /// (계층 폴백은 `quiz_distractor_service.dart`).
  void _prepareNextQuestion() {
    final cur = _currentQuiz;
    if (cur == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final correct = cur.translationFor(lang);
    // pack 을 실어 보내면 ⓪·① 계층이 **이번 장에서 방금 배운 단어들**을
    // 보기로 최우선 선발한다 — "잘 지냈어요?"의 오답이 Tee/Wochenende 처럼
    // 주제부터 다른 단어면 소거법으로 바로 빠진다 (2026-08-14 Jin 제안).
    final distractors = buildTranslationDistractors(
      target: DistractorCandidate(
        id: cur.korean,
        translation: correct,
        pos: cur.posFor(lang),
        level: cur.level,
        pack: cur.packId,
      ),
      pool: [
        for (final v in _distractorPool)
          DistractorCandidate(
            id: v.korean,
            translation: v.translationFor(lang),
            pos: v.posFor(lang),
            level: v.level,
            pack: v.packId,
          ),
      ],
      rng: _rng,
    );
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
    SoriSpeech.speak(cur.korean);
  }

  void _selectChoice(int i) {
    if (_choiceLocked || _finishing) return;
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final isCorrect = choices[i] == cur.translationFor(lang);
    setState(() {
      _selectedChoice = i;
      _choiceLocked = true;
      _hasSubmittedAssessment = true;
    });
    // Only scored recognition-assessment stages become course evidence. The
    // earlier card self-rating stays in SRS only, so a tap cannot unlock a
    // mission. `vocabularyRecall` is a legacy enum name, not a claim that the
    // four-choice Boss is independent recall.
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
          // 콤보는 실제 보상 순간이고 카드가 아니라 떠오르는 팝이라
          // 황을 유지한다 — 카드 위 금색과는 다른 이야기다.
          color: SoriColors.gold,
        );
      }
      if (_stage == _Stage.quiz) {
        _quizCorrect++;
        Storage.addVokSeen(cur.korean);
        _recordSessionSrs(cur.korean, gotIt: true);
      } else {
        _bossCorrect++;
        Storage.addVokSeen(cur.korean);
        _recordSessionSrs(cur.korean, gotIt: true);
      }
    } else {
      // 오답 — 더 강한 햅틱 + 부드러운 효과음, 콤보 리셋.
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _combo = 0;
      _sessionMissedWordIds.add(cur.korean);
      _recordSessionSrs(cur.korean, gotIt: false);
      // ignore: discarded_futures
      Storage.incrementWrongCount(cur.korean);
    }
    // 짧은 피드백 후 다음 질문
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _cancelAdvanceTimer();
    final createTimer = widget.advanceTimerFactory ?? Timer.new;
    _advanceTimer = createTimer(const Duration(milliseconds: 850), () {
      if (!mounted || _finishing) {
        return;
      }
      unawaited(_advanceQuiz());
    });
  }

  void _cancelAdvanceTimer() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  Future<void> _advanceQuiz() async {
    _cancelAdvanceTimer();
    if (!mounted) {
      return;
    }
    final isQuiz = _stage == _Stage.quiz;
    final total = isQuiz ? _quizQuestions.length : _bossQuestions.length;
    if (_qIdx + 1 >= total) {
      if (isQuiz) {
        await _enterBoss();
      } else {
        await _finish(
          bossAccuracy: _bossQuestions.isEmpty
              ? 1.0
              : _bossCorrect / _bossQuestions.length,
          bossCorrect: _bossCorrect,
          bossTotal: _bossQuestions.length,
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
    _cancelAdvanceTimer();
    if (_finishing) {
      return;
    }
    final pack = _pack;
    if (pack == null) {
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    final request = _finishRequest ??= VocabPackFinishRequest(
      pack: pack,
      siblingPacks: List<VocabPack>.unmodifiable(_siblingPacks),
      bossAccuracy: bossAccuracy,
      bossCorrect: bossCorrect,
      bossTotal: bossTotal,
      quizCorrect: _quizCorrect,
      quizTotal: _quizQuestions.length,
      courseContext: _missionStep == null ? null : widget.courseContext,
      completionStampMotif: motifForPackId(pack.id).name,
    );
    final feedbackCompletion = FeedbackCompletion.vocabPack(
      packId: pack.id,
      contentLabel: VocabPackService.displayLabel(pack.id, lang: lang),
      level: pack.level,
      bossCorrect: request.bossCorrect,
      bossTotal: request.bossTotal,
      quizCorrect: request.quizCorrect,
      quizTotal: request.quizTotal,
    );
    setState(() {
      _finishing = true;
      _finishError = null;
    });

    late final VocabPackFinishOutcome outcome;
    try {
      outcome = await _finishCoordinator.finish(request);
    } catch (_) {
      if (mounted) {
        setState(() {
          _finishing = false;
          _finishError = AppL10n.of(context).vocabPackFinishSaveError;
        });
      }
      return;
    }

    _abandonTracker.markCompleted();
    unawaited(_recordFinishAnalytics(request, outcome));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      '/vocab/result',
      arguments: vocabPackResultArguments(
        packId: pack.id,
        packLevel: pack.level,
        bossAccuracy: request.bossAccuracy,
        bossCorrect: request.bossCorrect,
        bossTotal: request.bossTotal,
        quizCorrect: request.quizCorrect,
        quizTotal: request.quizTotal,
        justCleared: outcome.justCleared,
        nextUnlockedPackId: outcome.nextUnlockedPackId,
        feedbackCompletion: feedbackCompletion,
        courseContext: request.courseContext,
        showHardWordsCta: shouldOfferHardWordPractice(_sessionMissedWordIds),
        recallSession: _recallSession,
      ),
    );
  }

  Future<void> _recordFinishAnalytics(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {
    final bossPct = request.bossTotal == 0
        ? 0
        : (request.bossCorrect * 100 / request.bossTotal).round();
    final bossPassed =
        request.bossAccuracy >= PackProgressService.bossClearThreshold;
    await _ignoreAnalyticsFailure(
      () => Analytics.packCompleted(
        packId: request.pack.id,
        accuracyPct: bossPct,
        firstClear: outcome.justCleared,
      ),
    );
    await _ignoreAnalyticsFailure(
      () => Analytics.quizCompleted(
        quizType: 'vocab_boss',
        accuracyPct: bossPct,
        level: request.pack.level,
        pass: bossPassed,
      ),
    );
    if (!bossPassed) {
      await _ignoreAnalyticsFailure(
        () => Analytics.questFailed(
          questType: 'vocab_boss',
          failReason: 'accuracy_below_threshold',
        ),
      );
    }
  }

  Future<void> _ignoreAnalyticsFailure(Future<void> Function() send) async {
    try {
      await send();
    } catch (_) {
      // Analytics is optional and must never downgrade authoritative success.
    }
  }

  void _retryFinish() {
    final request = _finishRequest;
    if (request == null) {
      return;
    }
    unawaited(
      _finish(
        bossAccuracy: request.bossAccuracy,
        bossCorrect: request.bossCorrect,
        bossTotal: request.bossTotal,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return SoriStudyFrame(
        title: t.vocabPackPlayTitle,
        padding: EdgeInsets.zero,
        child: const AppLoading(),
      );
    }
    if (_error != null || _pack == null) {
      return SoriStudyFrame(
        title: t.vocabPackPlayTitle,
        padding: EdgeInsets.zero,
        child: AppError(message: _error ?? 'unknown error', onRetry: _load),
      );
    }

    final pack = _pack!;
    final lang = Localizations.localeOf(context).languageCode;
    final title = VocabPackService.displayLabel(pack.id, lang: lang);
    // 현재 보고 있는 단어를 바로 내 단어장에 담기. Learn 단계는 피드 북마크
    // 스탬프(지시서 1.24)가 이미 커버하므로 여기선 quiz/boss 만 —
    // `_currentQuiz` 는 learn 단계에서 항상 null 이라 자연히 게이팅된다.
    // quiz/boss 는 `SoriContentFeed`(=스탬프)를 쓰지 않아 이 버튼이 그 단계의
    // 유일한 저장 수단이다.
    final Vocab? addable = _currentQuiz;

    return SoriStudyFrame(
      title: title,
      homeEscape: SoriHomeEscape(confirmWhen: _hasSubmittedAssessment),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        if (_stage == _Stage.learn)
          FlashcardRomanizationAction(
            onFront: _romanizationOnFront,
            onChanged: (value) {
              setState(() => _romanizationOnFront = value);
              unawaited(Storage.setFlashcardRomanizationOnFront(value));
            },
          ),
        if (addable != null)
          AddToWordbookButton(
            korean: addable.korean,
            translationDe: addable.german,
            translationEn: addable.english,
            romanization: addable.romanization,
            posDe: addable.posDe,
            exampleKorean: addable.exampleKorean,
            exampleDe: addable.exampleGerman,
            exampleEn: addable.exampleEnglish,
            compact: true,
            // The pack's modal three-step coach owns first admission. Queue
            // the global wordbook spotlight until that sheet has closed.
            coachEnabled: _featureCoachComplete,
          ),
        const TtsSpeedAction(),
      ],
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
    );
  }

  Widget _buildStageBody(AppL10n t) {
    if (_finishing) {
      return const AppLoading();
    }
    if (_finishError != null) {
      return AppError(
        message: _finishError!,
        onRetry: _retryFinish,
        messageLiveRegion: true,
      );
    }
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
      // 빈 팩 edge case → 바로 quiz/boss
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterQuiz());
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            SoriChip(
              // 분모 = 고유 단어 수(고정). 재출제 중에는 분자가 유지된다.
              // +N Wdh. = 이 세션에서 재출제로 다시 나온 카드 수(지시서 검수#21).
              label:
                  '${_learnQueue?.servedPosition ?? 1} / ${_learnQueue?.uniqueTotal ?? _learnWords.length}'
                  '${_learnRepeatCount > 0 ? t.vocabPackLearnRepeatSuffix(_learnRepeatCount) : ''}',
              accent: SoriColors.info,
            ),
            const SizedBox(width: Spacing.sm),
            // 힌트가 먼저 접힌다 — 칩(숫자)이 사용자에게 필요한 정보이고
            // 힌트는 보조 텍스트다. 칩은 폭 제한 없이 항상 온전히 그려지고,
            // 힌트만 Flexible 로 남는 폭에 맞춰 줄바꿈(320-360dp 오버플로 방지 —
            // Task 2 가 라벨을 최대 ~20자로 늘려 표면화됨). ellipsis 는 쓰지
            // 않는다 — 화면 콘텐츠를 말줄임으로 숨기지 않는다는 프로젝트
            // 불변식(typography_guard_test.dart) 위반이라 줄바꿈으로 대신
            // 전체를 보여준다.
            Flexible(
              child: Text(
                t.vocabPackLearnHint,
                style: TextStyle(
                  fontSize: 12,
                  color: SoriSurfaces.of(context).textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final next = _learnQueue?.peekNext;
              return SoriContentFeed(
                judgmentsEnabled: _learnCardRevealed,
                onBlockedJudgment: () => _flipHintTrigger.value++,
                flipHintTrigger: _flipHintTrigger,
                onNext: _learnGotIt,
                onHard: _learnDontKnow,
                onSkip: _learnDefer,
                onLike: _likeCurrent,
                onBookmark: _saveCurrent,
                bookmarkKey: cur.korean,
                onShare: _shareCurrent,
                onFlip: _toggleLearnFlip,
                liked: LikedContentService.isLiked(
                  kind: LikedContentService.vocab,
                  id: cur.korean,
                ),
                underlay: next == null
                    ? null
                    : _learnFaceSlot(next, box.maxHeight),
                knowLabel: t.vocabPackGotIt,
                hardLabel: t.vocabPackDontKnow,
                skipLabel: t.btnSkip,
                bookmarkLabel: t.deckActionSave,
                child: SizedBox(
                  key: const ValueKey('deck-card-slot'),
                  width: double.infinity,
                  height: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final h = soriStudyTypeScaleHeight(context);
                      final headlineSize = soriUniformFitSize(
                        context,
                        texts: [for (final w in _learnWords) w.korean],
                        maxWidth: constraints.maxWidth - Spacing.xl * 2,
                        cap: soriFillSize(h, 0.18, 36, 96),
                        min: 32,
                        letterSpacing: -0.5,
                        lineHeight: 1.05,
                      );
                      return FlipCard(
                        key: ValueKey('learn-$_learnServe'),
                        flipped: _flipped,
                        onTap: _toggleLearnFlip,
                        front: _FlipFront(
                          v: cur,
                          h: h,
                          headlineSize: headlineSize,
                          romanizationOnFront: _romanizationOnFront,
                        ),
                        back: _FlipBack(
                          v: cur,
                          h: h,
                          romanizationOnFront: _romanizationOnFront,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 덱 스택 underlay 용 앞면 슬롯 — 본 카드와 동일한 지오메트리/타이포 경로
  /// (슬롯 핀 + 덱 공유 균일 헤드라인).
  Widget _learnFaceSlot(Vocab v, double slotHeight) {
    return SizedBox(
      width: double.infinity,
      height: slotHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = soriStudyTypeScaleHeight(context);
          final headlineSize = soriUniformFitSize(
            context,
            texts: [for (final w in _learnWords) w.korean],
            maxWidth: constraints.maxWidth - Spacing.xl * 2,
            cap: soriFillSize(h, 0.18, 36, 96),
            min: 32,
            letterSpacing: -0.5,
            lineHeight: 1.05,
          );
          return _FlipFront(
            v: v,
            h: h,
            headlineSize: headlineSize,
            romanizationOnFront: _romanizationOnFront,
          );
        },
      ),
    );
  }

  Widget _buildQuiz(AppL10n t) {
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _stage == _Stage.quiz
        ? _quizQuestions.length
        : _bossQuestions.length;
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Row(
          children: [
            SoriChip(label: '${_qIdx + 1} / $total', accent: SoriColors.info),
            const SizedBox(width: Spacing.sm),
            // Learn 카운터 행과 같은 규칙(task_a40bf2a2 — 선행 결함, 같은 파일·
            // 같은 결함 클래스라 한 태스크로 묶어 처리): 칩은 폭 제한 없이
            // 온전히, 힌트만 Flexible 로 좁은 화면에서 줄바꿈(ellipsis 로
            // 콘텐츠를 숨기지 않는다는 typography_guard_test.dart 불변식 유지).
            Flexible(
              child: Text(
                _stage == _Stage.boss
                    ? t.vocabPackBossHint
                    : t.vocabPackQuizHint,
                style: TextStyle(fontSize: 12, color: s.textMuted),
              ),
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
                // 보스는 "더 깊은 녹청" 으로 어려움을 말한다. 예전 머스터드는
                // Jin 이 "골든색 너무 답답해 보인다" 고 지목한 카드다.
                accent: _stage == _Stage.boss
                    ? SoriColors.primaryDark
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
                        fontWeight: FontWeight.w700,
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
                          ? SoriColors.primaryDark
                          : SoriColors.info,
                      onTap: () {
                        // ignore: discarded_futures
                        SoriSpeech.speak(cur.korean);
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
                        promptCard,
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
                              onSelected: _choiceLocked || _finishing
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
  final bool romanizationOnFront;

  /// 카드가 놓인 세로 영역의 바운드 높이 — 학습 텍스트를 카드에 비례해 키우는
  /// 기준. `_buildLearn` 의 LayoutBuilder 가 넘겨준다.
  final double h;

  /// 덱 전체가 공유하는 제시어 크기 ([soriUniformFitSize]) — 단어 길이에 따라
  /// 카드마다 글씨가 커졌다 작아졌다 하지 않는다.
  final double headlineSize;
  const _FlipFront({
    required this.v,
    required this.h,
    required this.headlineSize,
    required this.romanizationOnFront,
  });

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
      // P1 이중 안전벨트: SoriCard 는 width: null 이면 내재폭 — 슬롯 핀과
      // 별개로 카드 자체도 항상 가용폭을 채운다 (단어 길이별 폭 신축 금지).
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 제시어 — 카드를 채우는 대형 헤드라인. 크기는 덱 공유값
          // ([headlineSize]) 하나로 고정 — FittedBox 는 실측 오차용 안전망일 뿐
          // 정상 경로에서는 절대 개입하지 않는다 (단어 길이별 크기 요동 금지).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              v.korean,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: headlineSize,
                fontWeight: FontWeight.w700,
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
                  SoriSpeech.speak(v.korean);
                },
              ),
              if (romanizationOnFront && v.romanization.isNotEmpty) ...[
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
              fontSize: soriFillSize(h, 0.032, 12.5, 20),
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
  final bool romanizationOnFront;

  /// 카드가 놓인 세로 영역의 바운드 높이 — 학습 텍스트를 카드에 비례해 키우는
  /// 기준. `_buildLearn` 의 LayoutBuilder 가 넘겨준다.
  final double h;
  const _FlipBack({
    required this.v,
    required this.h,
    required this.romanizationOnFront,
  });

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
      // P1 이중 안전벨트 — _FlipFront 와 동일 계약.
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뜻(헤드라인) + 품사 — 의미 묶음. 뜻은 **고정 크기 + 줄바꿈**:
          // FittedBox 로 줄이면 뜻 길이마다 카드 글씨가 요동친다 (2026-08-14
          // Jin — 단어 길이별 크기 변동 금지). 긴 뜻은 같은 크기로 줄만 는다.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                v.translationFor(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.085, 24, 38),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
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
              if (!romanizationOnFront && v.romanization.isNotEmpty) ...[
                SizedBox(height: soriFillSize(h, 0.02, 6, 14)),
                Text(
                  '[${v.romanization}]',
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).bodySmall.copyWith(
                    fontSize: soriFillSize(h, 0.045, 14, 26),
                    color: s.textMuted,
                  ),
                ),
              ],
            ],
          ),
          // 예문(한국어 + 번역)을 한 묶음으로 — 탭하면 예문 발음, 길게 누르면
          // 느리게 (예문 음성은 사전생성 캐시 적중). 인라인 스피커 아이콘이
          // 들을 수 있음을 알린다 (2026-08-14 Jin: 예문 음성 소실 복구).
          if (v.exampleKorean.isNotEmpty)
            SoriPressable(
              haptic: SoriHaptic.light,
              onTap: () {
                // ignore: discarded_futures
                SoriSpeech.speak(v.exampleKorean);
              },
              onLongPress: () {
                // ignore: discarded_futures
                SoriSpeech.speakSlow(v.exampleKorean);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: soriFillSize(h, 0.055, 18, 28),
                            color: SoriColors.primary,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 6)),
                        TextSpan(text: v.exampleKorean),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.072, 18, 38),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: soriFillSize(h, 0.02, 4, 16)),
                  Text(
                    romanizeKorean(v.exampleKorean),
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).bodySmall.copyWith(
                      fontSize: soriFillSize(h, 0.042, 13, 24),
                      color: s.textMuted,
                      height: 1.3,
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
            ),
        ],
      ),
    );
  }
}
