import 'dart:async';

import '../data/canonical_companion_art.dart';
import '../widgets/sori/study_evidence_recovery.dart';
import '../widgets/sori/game_result_recovery.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../models/feedback_completion.dart';
import '../services/custom_pack_service.dart';
import '../services/quiz_distractor_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/managed_media_image.dart';
import '../widgets/sori/approved_games/approved_game_material.dart';
import '../widgets/sori/approved_games/approved_quiz_view.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/route_observer.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// "나만의 단어장" 객관식 퀴즈 — 한국어를 보고 뜻 4지선다 (Quizlet/클래스카드 식).
///
/// 활성 언어 뜻이 있는 단어만 출제. 최소 4개 필요.
class CustomPackQuizScreen extends StatefulWidget {
  final String packId;
  final List<ExtractedWord>? words;
  const CustomPackQuizScreen({super.key, required this.packId, this.words});

  @override
  State<CustomPackQuizScreen> createState() => _CustomPackQuizScreenState();
}

class _CustomPackQuizScreenState extends State<CustomPackQuizScreen>
    with
        WidgetsBindingObserver,
        RouteAware,
        ScreenCoachMixin<CustomPackQuizScreen>,
        GameResultRecovery<CustomPackQuizScreen>,
        StudyEvidenceRecovery<CustomPackQuizScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  int _presentation = 0;
  bool get _acceptsInput => studyEvidenceAcceptsInput && gameResultAcceptsInput;
  void _retireStudy() {
    _autoAdvance?.cancel();
    _remainingAdvance = null;
    _stopSpeech();
    retireStudyEvidence();
    retireGameResult();
  }

  List<ExtractedWord> _pool = const [];
  List<int> _order = const [];
  int _qIdx = 0;
  int _score = 0;
  List<String> _options = const [];
  String? _picked; // 선택한 답 (null = 미선택)
  GameOutcome? _outcome;
  String _languageCode = 'de';
  bool _roundInitialized = false;
  Timer? _autoAdvance;
  Duration? _remainingAdvance;
  DateTime? _advanceDeadline;
  bool _foreground = true;
  bool _routeVisible = true;
  bool _ownsSpeech = false;
  int _speechRequest = 0;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  // ── 코치마크 타겟 ──
  final GlobalKey _optionsKey = GlobalKey();

  @override
  String get coachId => 'cpQuiz';

  @override
  bool get coachReady => _pool.length >= 4;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _optionsKey,
        title: t.coachCpQuizTitle,
        body: t.coachCpQuizBody,
        icon: Icons.quiz_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final loaded = CustomPackService.getById(widget.packId);
    final pack = loaded == null || widget.words == null
        ? loaded
        : loaded.copyWith(words: widget.words);
    _pack = pack;
    scheduleCoach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      soriRouteObserver.subscribe(this, route);
    }
    if (SoriMotion.reduceMotion(context)) {
      _autoAdvance?.cancel();
      _remainingAdvance = null;
    }
    if (_roundInitialized) {
      return;
    }
    _roundInitialized = true;
    _startRoundForLocale(Localizations.localeOf(context).languageCode);
  }

  void _pauseAdvance() {
    if (_autoAdvance?.isActive ?? false) {
      final left = _advanceDeadline!.difference(DateTime.now());
      _remainingAdvance = left.isNegative ? Duration.zero : left;
    }
    _autoAdvance?.cancel();
    _stopSpeech();
  }

  void _stopSpeech() {
    if (!_ownsSpeech) {
      return;
    }
    _ownsSpeech = false;
    _speechRequest++;
    unawaited(TtsService.stop());
  }

  void _resumeAdvance() {
    final remaining = _remainingAdvance;
    if (!mounted ||
        !_foreground ||
        !_routeVisible ||
        remaining == null ||
        !_acceptsInput ||
        _picked == null ||
        SoriMotion.reduceMotion(context)) {
      return;
    }
    final presentation = _presentation;
    _autoAdvance?.cancel();
    _advanceDeadline = DateTime.now().add(remaining);
    _autoAdvance = Timer(remaining, () {
      _remainingAdvance = null;
      if (mounted && _foreground && _routeVisible) {
        _advance(presentation);
      }
    });
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _pauseAdvance();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _resumeAdvance();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _pauseAdvance();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _resumeAdvance();
    } else {
      _pauseAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    soriRouteObserver.unsubscribe(this);
    _stopSpeech();
    super.dispose();
  }

  void _startRoundForLocale(String languageCode) {
    _autoAdvance?.cancel();
    _remainingAdvance = null;
    _presentation++;
    _languageCode = languageCode;
    final pack = _pack;
    if (pack == null) {
      return;
    }
    _pool = pack.words
        .where((word) => word.translationFor(languageCode).trim().isNotEmpty)
        .toList();
    _order = List<int>.generate(_pool.length, (index) => index)..shuffle(_rng);
    _qIdx = 0;
    _score = 0;
    _outcome = null;
    _feedbackCompletion.reset();
    resetGameResult();
    if (_pool.length >= 4) {
      _buildOptions();
    }
  }

  void _buildOptions() {
    _presentation++;
    final word = _pool[_order[_qIdx]];
    final correct = word.translationFor(_languageCode).trim();
    // 같은 품사 오답 우선 (커스텀 단어는 레벨이 없어 품사 계층만 작동;
    // 폴백은 quiz_distractor_service.dart).
    final distractors = buildTranslationDistractors(
      target: DistractorCandidate(
        id: word.korean,
        translation: correct,
        pos: word.posDe,
      ),
      pool: [
        for (final w in _pool)
          DistractorCandidate(
            id: w.korean,
            translation: w.translationFor(_languageCode),
            pos: w.posDe,
          ),
      ],
      rng: _rng,
    );
    final opts = <String>[correct, ...distractors];
    opts.shuffle(_rng);
    _options = opts;
    _picked = null;
  }

  Future<void> _pick(String option, int presentation) async {
    if (!_foreground ||
        !_routeVisible ||
        !_acceptsInput ||
        presentation != _presentation ||
        _qIdx >= _order.length ||
        _picked != null) {
      return;
    }
    final word = _pool[_order[_qIdx]];
    final correct = word.translationFor(_languageCode).trim();
    final isRight = option == correct;
    final attempt = SrsReviewAttempt(id: word.korean, gotIt: isRight);
    final progress = VocabProgressAttempt(
      seenId: word.korean,
      wrongCountId: isRight ? null : word.korean,
    );
    if (!await saveStudyEvidence(() async {
          if (!await attempt.save()) {
            return false;
          }
          if (!studyEvidenceIsCurrent) {
            return false;
          }
          return progress.save();
        }) ||
        !mounted ||
        !_acceptsInput ||
        presentation != _presentation) {
      return;
    }
    setState(() => _picked = option);
    if (isRight) {
      _score++;
      if (_foreground && _routeVisible) {
        SoundService.correct();
      }
    } else if (_foreground && _routeVisible) {
      SoundService.wrong();
    }
    if (SoriMotion.reduceMotion(context)) {
      return;
    }
    _remainingAdvance = const Duration(milliseconds: 900);
    _resumeAdvance();
  }

  void _advance(int presentation) {
    if (!_foreground ||
        !_routeVisible ||
        !_acceptsInput ||
        presentation != _presentation ||
        _picked == null ||
        _qIdx >= _order.length) {
      return;
    }
    _autoAdvance?.cancel();
    _remainingAdvance = null;
    _stopSpeech();
    _presentation++;
    setState(() {
      _qIdx++;
      if (_qIdx < _order.length) {
        _buildOptions();
      }
    });
    if (_qIdx >= _order.length) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (!_acceptsInput) return;
    final presentation = _presentation;
    final pct = ((_score / _order.length) * 100).round();
    final outcome = await saveGameResult(
      gameId: 'cp_quiz',
      xp: _score * 4,
      score: pct,
    );
    if (!mounted ||
        !studyEvidenceIsCurrent ||
        presentation != _presentation ||
        outcome == null) {
      return;
    }
    _feedbackCompletion.complete(
      () => FeedbackCompletion.customPackQuiz(
        packId: widget.packId,
        correct: _score,
        total: _order.length,
      ),
    );
    if (mounted) {
      setState(() => _outcome = outcome);
    }
  }

  void _restart(int presentation) {
    if (!_acceptsInput || presentation != _presentation || _outcome == null) {
      return;
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _startRoundForLocale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation;
    final recovery =
        studyEvidenceRecoveryFrame(AppL10n.of(context).wbQuiz) ??
        gameResultRecoveryFrame(AppL10n.of(context).wbQuiz);
    if (recovery != null) {
      return recovery;
    }
    final t = AppL10n.of(context);

    if (_pack == null) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.wbQuiz,
        child: Center(
          child: SoriEmptyState(
            asset: CanonicalCompanionArt.baekhoSeated,
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }

    if (_pool.length < 4) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.wbQuiz,
        child: Center(
          child: SoriEmptyState(
            asset: CanonicalCompanionArt.magpieGuide,
            icon: Icons.quiz_outlined,
            title: t.wbQuiz,
            body: t.quizNeedMore,
          ),
        ),
      );
    }

    if (_qIdx >= _order.length) {
      return _buildDone(t);
    }

    final reduceMotion = SoriMotion.reduceMotion(context);
    final word = _pool[_order[_qIdx]];
    final correct = word.translationFor(_languageCode).trim();

    return ApprovedGameFrame(
      title: t.approvedQuizTitle,
      onLeave: _retireStudy,
      confirmWhen: _qIdx > 0 || _picked != null,
      contentBuilder: (context, close) => ApprovedQuizView(
        title: t.approvedQuizTitle,
        topic: _pack!.displayName(),
        scoreLabel: t.approvedQuizCorrect(_score),
        progressLabel: t.scenarioQuestProgress(_qIdx + 1, _order.length),
        question: t.quizQuestion,
        instruction: t.approvedQuizChooseMeaning,
        korean: word.korean,
        options: _options,
        correctOption: correct,
        picked: _picked,
        listenLabel: t.approvedGameListen,
        correctFeedback: t.statsCorrect,
        wrongFeedback: t.statsWrong,
        nextLabel: t.btnNext,
        leading: close,
        optionsKey: _optionsKey,
        onOption: (option) => _pick(option, presentation),
        onListen: () {
          if (_foreground &&
              _routeVisible &&
              _acceptsInput &&
              presentation == _presentation) {
            _ownsSpeech = true;
            final request = ++_speechRequest;
            unawaited(
              TtsService.speak(word.korean).whenComplete(() {
                if (request == _speechRequest) {
                  _ownsSpeech = false;
                }
              }),
            );
          }
        },
        onNext: _picked != null && reduceMotion
            ? () => _advance(presentation)
            : null,
        wordImage: word.imagePath.isEmpty
            ? null
            : ManagedMediaImage(
                reference: word.imagePath,
                width: 220,
                height: 110,
                borderRadius: BorderRadius.circular(SoriRadius.md),
              ),
      ),
    );
  }

  void _closeResult(int presentation) {
    if (!_acceptsInput ||
        presentation != _presentation ||
        !(_outcome != null)) {
      return;
    }
    _retireStudy();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/my_words', (route) => route.isFirst);
  }

  Widget _buildDone(AppL10n t) {
    final presentation = _presentation;
    final pct = ((_score / _order.length) * 100).round();
    return SoriStudyFrame(
      onLeave: _retireStudy,
      title: t.quizResultTitle,
      automaticallyImplyLeading: false,
      padding: EdgeInsets.zero,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: '${t.quizResultTitle}. ${t.quizScore(_score, _order.length)}',
        child: GameOverCard(
          outcome: _outcome,
          rewardReady: _outcome != null,
          headline: t.quizResultTitle,
          scoreLabel: t.quizScore(_score, _order.length),
          feedbackContext: _feedbackCompletion.current?.context,
          xpGained: _outcome?.xpGained ?? 0,
          isNewBest: _outcome?.isNewBest ?? false,
          newBestLabel: t.gameNewBest,
          bestLabel: t.gameBestAccuracy(Storage.gameBest('cp_quiz')),
          mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
          mascotEmotion: pct >= 50
              ? MascotEmotion.celebrate
              : MascotEmotion.worry,
          celebrate: pct >= 50,
          actions: [
            SoriButton(
              label: t.quizAgain,
              icon: Icons.refresh_rounded,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.accent,
              fullWidth: true,
              onTap: () => _restart(presentation),
            ),
            SoriButton(
              label: t.customPackResultBack,
              icon: Icons.menu_book_outlined,
              variant: SoriButtonVariant.outlined,
              fullWidth: true,
              onTap: () => _closeResult(presentation),
            ),
          ],
        ),
      ),
    );
  }
}
