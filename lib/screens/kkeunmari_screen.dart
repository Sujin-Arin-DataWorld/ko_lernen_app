import '../data/canonical_companion_art.dart';
import '../services/haptic_service.dart';
import '../widgets/sori/game_reward.dart';
import '../services/learning_journey.dart';
import '../models/sori_stage_progression.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../models/feedback_completion.dart';
import '../services/data_loader.dart';
import '../services/kkeunmari_dictionary_service.dart';
import '../services/kkeunmari_engine.dart';
import '../services/vocab_deck_source.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/approved_games/approved_game_material.dart';
import '../widgets/sori/approved_games/approved_word_chain_view.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_result_recovery.dart';
import '../widgets/sori/study_evidence_recovery.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sori_icon.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/route_observer.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

enum _Turn { user, tiger }

enum _End { none, tigerStuck, userStuck, deadEnd, timeUp }

enum _PendingTurnAction { none, deadEnd, tigerMove }

/// 끝말잇기 화면 — 호랑이 ↔ 사용자 턴제 게임.
///
/// 시작: 호랑이가 안전한 단어 1개 제시.
/// 사용자 차례: 호랑이 단어의 last 음절로 시작하는 단어 입력 → 30s 카운트.
/// 호랑이 차례: 자동으로 다음 단어 선택 → 호랑이가 단어 없으면 사용자 승.
/// dead_end 단어가 나오면 그 차례 종료 (다음 차례 응답 못 함).
class KkeunmariScreen extends StatefulWidget {
  const KkeunmariScreen({
    super.key,
    this.poolLoader,
    this.dictionaryValidator,
    this.source,
  });

  final VocabDeckSource? source;

  /// Optional deterministic seam. Production keeps [KkeunmariEngine.load].
  final Future<List<KkeunmariWord>> Function()? poolLoader;

  /// Optional deterministic seam. Production keeps the trusted validator.
  final Future<KkeunmariDictionaryResult> Function(String word)?
  dictionaryValidator;

  @override
  State<KkeunmariScreen> createState() => _KkeunmariScreenState();
}

class _KkeunmariScreenState extends State<KkeunmariScreen>
    with
        ScreenCoachMixin<KkeunmariScreen>,
        WidgetsBindingObserver,
        RouteAware,
        GameResultRecovery<KkeunmariScreen>,
        StudyEvidenceRecovery<KkeunmariScreen> {
  static const _turnSeconds = 30;

  bool _loading = true;
  bool _loadFailed = false;
  List<KkeunmariWord> _chain = [];
  List<KkeunmariWord> _pool = const [];
  bool get _hasPlayablePool =>
      _pool.isNotEmpty && KkeunmariEngine.hasChain(_pool);
  final Set<String> _used = {};
  Set<String> _vocabKeys = {}; // M1: nur diese Wörter speisen das SRS
  _Turn _turn = _Turn.user;
  _End _end = _End.none;
  bool _finishing = false;
  bool _newBest = false; // diese Runde = längste Kette aller Zeiten?
  LearningAttempt? _learningAttempt;
  int? _persistedXp;
  bool _dictionaryChecking = false;
  bool _dictionaryUnavailable = false;
  int _roundGeneration = 0;
  int _turnGeneration = 0;
  int _dictionaryGeneration = 0;
  String _errorMsg = '';
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;
  KkeunmariWord? _last; // 마지막으로 낸 단어 (chain 마지막)

  Timer? _timer;
  int _remaining = _turnSeconds;
  bool _lifecyclePaused = false;
  bool _resumeCountdownAfterLifecycle = false;
  ModalRoute<dynamic>? _route;
  bool _routeVisible = true;
  Timer? _openingSpeech;
  String? _queuedSpeech;
  bool _ownsSpeech = false;
  int _speechRequest = 0;
  Timer? _turnDelayTimer;
  _PendingTurnAction _pendingTurnAction = _PendingTurnAction.none;
  Duration _pendingTurnDelay = Duration.zero;
  DateTime? _pendingTurnStartedAt;

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  bool get _acceptsInput => studyEvidenceAcceptsInput && gameResultAcceptsInput;
  bool get _isVisible => !_lifecyclePaused && _routeVisible;
  // A covered route may finish an already accepted write, but cannot accept
  // another input or run the next timed turn underneath its destination.
  bool get _canInteract => _acceptsInput && _isVisible;

  void _retireStudy() {
    retireStudyEvidence();
    retireGameResult();
  }

  // ── 코치마크 타겟 ──
  final GlobalKey _lastWordCardKey = GlobalKey();
  final GlobalKey _timerRowKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();

  @override
  String get coachId => 'kkeunmari';

  @override
  bool get coachReady => !_loading && _last != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _lastWordCardKey,
        title: t.coachKkeunmariStep1Title,
        body: t.coachKkeunmariStep1Body,
        icon: Icons.link_rounded,
      ),
      SpotlightStep(
        targetKey: _timerRowKey,
        title: t.coachKkeunmariStep2Title,
        body: t.coachKkeunmariStep2Body,
        icon: Icons.timer_outlined,
      ),
      SpotlightStep(
        targetKey: _inputFieldKey,
        title: t.coachKkeunmariStep3Title,
        body: t.coachKkeunmariStep3Body,
        icon: Icons.keyboard_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecyclePaused =
        WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
    _start();
    scheduleCoach();
    Analytics.gameStarted(gameType: 'kkeunmari');
    _abandonTracker = QuestAbandonTracker(
      questType: 'kkeunmari',
      lastStepReached: () => 'chain_${_chain.length}',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      soriRouteObserver.unsubscribe(this);
      _route = route;
      _routeVisible = route?.isCurrent ?? true;
      if (route != null) {
        soriRouteObserver.subscribe(this, route);
      }
    }
  }

  void _suspendRound() {
    if (_timer != null) {
      _resumeCountdownAfterLifecycle = true;
      _timer?.cancel();
      _timer = null;
    }
    _pausePendingTurnAction();
    _openingSpeech?.cancel();
    _openingSpeech = null;
    _stopSpeech();
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _resumeRound() {
    if (!_canInteract) {
      return;
    }
    if (_resumeCountdownAfterLifecycle &&
        _end == _End.none &&
        _turn == _Turn.user &&
        _remaining > 0) {
      _runTimer();
    }
    _resumePendingTurnAction();
    final speech = _queuedSpeech;
    if (speech != null) {
      _speakWord(speech);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canInteract &&
          !_loading &&
          !_dictionaryChecking &&
          _end == _End.none &&
          _turn == _Turn.user &&
          _pendingTurnAction == _PendingTurnAction.none) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _suspendRound();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _resumeRound();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _suspendRound();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecyclePaused = state != AppLifecycleState.resumed;
    if (_isVisible) {
      _resumeRound();
    } else {
      _suspendRound();
    }
  }

  void _speakWord(String word) {
    if (!_acceptsInput || _finishing || _end != _End.none) {
      return;
    }
    if (!_isVisible) {
      _queuedSpeech = word;
      return;
    }
    _queuedSpeech = null;
    _openingSpeech?.cancel();
    _openingSpeech = null;
    _ownsSpeech = true;
    final request = ++_speechRequest;
    unawaited(
      SoriSpeech.speak(word).whenComplete(() {
        if (request == _speechRequest) {
          _ownsSpeech = false;
        }
      }),
    );
  }

  void _stopSpeech() {
    if (!_ownsSpeech) {
      return;
    }
    _ownsSpeech = false;
    _speechRequest++;
    unawaited(SoriSpeech.stop());
  }

  Future<void> _start() async {
    if (!_acceptsInput || (_loading && _roundGeneration > 0)) {
      return;
    }
    if (!_loading || _loadFailed) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    resetGameResult();
    final generation = ++_roundGeneration;
    _dictionaryGeneration++;
    _finishing = false;
    _feedbackCompletion.reset();
    _cancelPendingTurnAction();
    try {
      final poolLoader = widget.poolLoader;
      if (poolLoader == null) {
        _pool = await KkeunmariEngine.load();
      } else {
        final pool = await poolLoader();
        if (!_acceptsInput || generation != _roundGeneration) {
          return;
        }
        _pool = List<KkeunmariWord>.unmodifiable(pool);
      }
    } catch (_) {
      if (!_acceptsInput || generation != _roundGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    if (!_acceptsInput || generation != _roundGeneration) {
      return;
    }
    final defaultLoadFailed =
        widget.poolLoader == null && KkeunmariEngine.lastError != null;
    if (defaultLoadFailed) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    if (widget.source != null) {
      _pool = widget.source!.wordChainPool(_pool);
    }
    // M1: Vokabel-Keys laden → nur Kkeunmari-Wörter, die echte Vokabeln sind,
    // speisen das SRS (best-effort; Spiel läuft auch ohne).
    if (widget.source == null &&
        widget.poolLoader == null &&
        _vocabKeys.isEmpty) {
      try {
        final vocab = await DataLoader.loadVocab();
        if (!_acceptsInput || generation != _roundGeneration) {
          return;
        }
        _vocabKeys = vocab.map((v) => v.korean).toSet();
      } catch (_) {
        /* SRS-Einspeisung optional */
      }
    }
    if (!_acceptsInput || generation != _roundGeneration) {
      return;
    }
    if (!_hasPlayablePool) {
      // Pool leer (Asset fehlt/defekt) → Leer-Zustand zeigen statt pickStart-Crash.
      setState(() => _loading = false);
      return;
    }
    final start = KkeunmariEngine.pickStart(source: _pool);
    setState(() {
      _chain = [start];
      _used
        ..clear()
        ..add(start.word);
      _last = start;
      _turn = _Turn.user;
      _turnGeneration++;
      _end = _End.none;
      _newBest = false;
      _learningAttempt = null;
      _persistedXp = null;
      _dictionaryChecking = false;
      _dictionaryUnavailable = false;
      _errorMsg = '';
      _remaining = _turnSeconds;
      _loading = false;
    });
    _ctrl.clear();
    _startTimer();
    _queuedSpeech = start.word;
    _openingSpeech = Timer(const Duration(milliseconds: 200), () {
      _openingSpeech = null;
      if (_acceptsInput && generation == _roundGeneration) {
        _speakWord(start.word);
      }
    });
  }

  Future<void> _retryLoad(int generation) async {
    if (!_canInteract ||
        generation != _roundGeneration ||
        _loading ||
        !_loadFailed) {
      return;
    }
    if (widget.poolLoader == null) {
      KkeunmariEngine.reset();
    }
    await _start();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _turnSeconds;
    if (!_isVisible) {
      _timer = null;
      _resumeCountdownAfterLifecycle = true;
      return;
    }
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _resumeCountdownAfterLifecycle = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!identical(t, _timer)) {
        t.cancel();
        return;
      }
      if (!_canInteract ||
          _dictionaryChecking ||
          _dictionaryUnavailable ||
          _finishing ||
          _end != _End.none ||
          _turn != _Turn.user) {
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _endGame(_End.timeUp);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _resumeCountdownAfterLifecycle = false;
  }

  void _schedulePendingTurnAction(_PendingTurnAction action, Duration delay) {
    _turnDelayTimer?.cancel();
    _pendingTurnAction = action;
    _pendingTurnDelay = delay;
    _pendingTurnStartedAt = null;
    if (_isVisible) {
      _armPendingTurnAction();
    }
  }

  void _armPendingTurnAction() {
    if (_pendingTurnAction == _PendingTurnAction.none) {
      return;
    }
    final generation = _roundGeneration;
    _pendingTurnStartedAt = DateTime.now();
    _turnDelayTimer = Timer(_pendingTurnDelay, () {
      if (!_canInteract ||
          generation != _roundGeneration ||
          _finishing ||
          _end != _End.none) {
        return;
      }
      final action = _pendingTurnAction;
      _turnDelayTimer = null;
      _pendingTurnAction = _PendingTurnAction.none;
      _pendingTurnDelay = Duration.zero;
      _pendingTurnStartedAt = null;
      switch (action) {
        case _PendingTurnAction.none:
          break;
        case _PendingTurnAction.deadEnd:
          _endGame(_End.deadEnd);
        case _PendingTurnAction.tigerMove:
          _tigerMove();
      }
    });
  }

  void _pausePendingTurnAction() {
    final startedAt = _pendingTurnStartedAt;
    if (_turnDelayTimer == null || startedAt == null) return;
    final elapsed = DateTime.now().difference(startedAt);
    _pendingTurnDelay = elapsed >= _pendingTurnDelay
        ? Duration.zero
        : _pendingTurnDelay - elapsed;
    _turnDelayTimer?.cancel();
    _turnDelayTimer = null;
    _pendingTurnStartedAt = null;
  }

  void _resumePendingTurnAction() {
    if (_canInteract &&
        _pendingTurnAction != _PendingTurnAction.none &&
        _turnDelayTimer == null) {
      _armPendingTurnAction();
    }
  }

  void _cancelPendingTurnAction() {
    _turnDelayTimer?.cancel();
    _turnDelayTimer = null;
    _pendingTurnAction = _PendingTurnAction.none;
    _pendingTurnDelay = Duration.zero;
    _pendingTurnStartedAt = null;
  }

  String get _required => _last?.last ?? '';

  Future<void> _submit(int generation, int turnGeneration) async {
    if (!_canInteract ||
        _finishing ||
        generation != _roundGeneration ||
        turnGeneration != _turnGeneration ||
        _dictionaryChecking ||
        _end != _End.none ||
        _turn != _Turn.user) {
      return;
    }
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;
    final (valid, reason, word) = KkeunmariEngine.validateUserWord(
      input,
      _required,
      _used,
      source: _pool,
    );
    if (!valid) {
      if (reason != 'not_in_pool' || widget.source != null) {
        _showValidationError(reason);
        return;
      }
      await _checkDictionaryWord(input, generation, turnGeneration);
      return;
    }
    await _acceptUserWord(word!, generation, turnGeneration);
  }

  Future<void> _checkDictionaryWord(
    String input,
    int generation,
    int turnGeneration,
  ) async {
    final t = AppL10n.of(context);
    final dictionaryGeneration = ++_dictionaryGeneration;
    setState(() {
      _dictionaryChecking = true;
      _errorMsg = t.kkeunmariDictionaryChecking;
    });
    try {
      final validator =
          widget.dictionaryValidator ??
          (word) => KkeunmariDictionaryService.validate(word: word);
      late final KkeunmariDictionaryResult result;
      try {
        result = await validator(input).timeout(const Duration(seconds: 8));
      } catch (_) {
        result = const KkeunmariDictionaryResult(
          KkeunmariDictionaryStatus.unavailable,
        );
      }
      if (!_acceptsInput ||
          _finishing ||
          generation != _roundGeneration ||
          turnGeneration != _turnGeneration ||
          dictionaryGeneration != _dictionaryGeneration ||
          _end != _End.none ||
          _turn != _Turn.user) {
        return;
      }
      if (result.isValid) {
        await _acceptUserWord(
          KkeunmariWord.dictionary(input),
          generation,
          turnGeneration,
        );
        return;
      }
      if (_isVisible) {
        HapticService.mediumImpact();
      }
      setState(() {
        // Do not make learners lose a turn because our dictionary is down.
        // Keep this turn paused until a valid answer advances the game.
        if (result.status == KkeunmariDictionaryStatus.unavailable) {
          _dictionaryUnavailable = true;
        }
        _errorMsg = switch (result.status) {
          KkeunmariDictionaryStatus.invalid => t.kkeunmariNotDictionaryWord,
          KkeunmariDictionaryStatus.unavailable =>
            t.kkeunmariDictionaryUnavailable,
          KkeunmariDictionaryStatus.valid => '',
        };
      });
    } finally {
      if (_acceptsInput &&
          generation == _roundGeneration &&
          dictionaryGeneration == _dictionaryGeneration) {
        setState(() => _dictionaryChecking = false);
      }
    }
  }

  void _showValidationError(String reason) {
    final t = AppL10n.of(context);
    HapticService.mediumImpact();
    setState(() {
      _errorMsg = switch (reason) {
        'not_korean' => t.kkeunmariNotKorean,
        'wrong_start' => t.kkeunmariWrongStart(_required),
        'already_used' => t.kkeunmariAlreadyUsed,
        _ =>
          widget.source == null
              ? t.kkeunmariNotInPool
              : t.kkeunmariNotInSelection,
      };
    });
  }

  Future<void> _acceptUserWord(
    KkeunmariWord w,
    int generation,
    int turnGeneration,
  ) async {
    if (!_acceptsInput ||
        generation != _roundGeneration ||
        turnGeneration != _turnGeneration ||
        _finishing ||
        _end != _End.none ||
        _turn != _Turn.user) {
      return;
    }
    // A validated answer owns the current turn. Stop its clock before any
    // persistence I/O, retaining the exact displayed remainder across retry.
    _stopTimer();
    if (_vocabKeys.contains(w.word)) {
      final attempt = SrsReviewAttempt(id: w.word, gotIt: true);
      if (!await saveStudyEvidence(attempt.save)) {
        return;
      }
      if (!mounted ||
          !_acceptsInput ||
          generation != _roundGeneration ||
          turnGeneration != _turnGeneration ||
          _finishing ||
          _end != _End.none ||
          _turn != _Turn.user) {
        return;
      }
    }
    if (_isVisible) {
      HapticService.lightImpact();
      // Accepted writes still finish under cover, but transient feedback belongs
      // only to the currently visible round.
      SoundService.correct();
    }
    setState(() {
      _turnGeneration++;
      _dictionaryUnavailable = false;
      _chain.add(w);
      _used.add(w.word);
      _last = w;
      _errorMsg = '';
      _ctrl.clear();
    });
    _speakWord(w.word);

    // The bundle-level `is_dead_end` is only an unused-pool snapshot. A real
    // turn must account for already-used words, otherwise a stale next_count
    // can end a valid chain (or delay an impossible one).
    if (KkeunmariEngine.nextCountFor(w.last, _used, source: _pool) == 0) {
      _stopTimer();
      _schedulePendingTurnAction(
        _PendingTurnAction.deadEnd,
        const Duration(milliseconds: 1000),
      );
      return;
    }

    // 호랑이 차례. 생각 비트를 넉넉히(1800ms) 둬서 전환이 번쩍 지나가
    // 오류처럼 보이지 않게 한다 — 상대가 '생각하는' 순간으로 또렷이 읽히도록.
    _stopTimer();
    setState(() => _turn = _Turn.tiger);
    _schedulePendingTurnAction(
      _PendingTurnAction.tigerMove,
      const Duration(milliseconds: 1800),
    );
  }

  void _tigerMove() {
    if (!_canInteract || _finishing || _end != _End.none) {
      return;
    }
    final next = KkeunmariEngine.pickTigerNext(_required, _used, source: _pool);
    if (next == null) {
      _endGame(_End.tigerStuck);
      return;
    }
    setState(() {
      _chain.add(next);
      _used.add(next.word);
      _last = next;
      _turn = _Turn.user;
      _turnGeneration++;
    });
    _speakWord(next.word);
    _startTimer();
    _focusNode.requestFocus();
  }

  Future<void> _endGame(_End reason) async {
    if (!_acceptsInput || _finishing || _end != _End.none) {
      return;
    }
    final generation = _roundGeneration;
    _finishing = true;
    _stopTimer();
    _cancelPendingTurnAction();
    final didWin = reason == _End.tigerStuck || reason == _End.deadEnd;
    final outcome = await saveGameResult(
      gameId: 'kkeunmari',
      xp: (_chain.length * 10).clamp(20, 500),
      score: _chain.length,
      kkeunmariWin: didWin,
    );
    if (!mounted ||
        !studyEvidenceIsCurrent ||
        generation != _roundGeneration ||
        outcome == null) {
      return;
    }
    _newBest = outcome.isNewBest;
    _learningAttempt = outcome.attempt;
    _persistedXp = outcome.xpGained;
    if (_isVisible) {
      HapticService.heavyImpact();
    }
    _feedbackCompletion.complete(
      () => FeedbackCompletion.kkeunmari(
        contentLabel: AppL10n.of(context).kkeunmariTitle,
        chainLength: _chain.length,
        endReason: switch (reason) {
          _End.tigerStuck => 'tiger_stuck',
          _End.userStuck => 'user_stuck',
          _End.deadEnd => 'dead_end',
          _End.timeUp => 'time_up',
          _End.none => 'none',
        },
      ),
    );
    setState(() => _end = reason);
    // Publish feedback and quest completion only after the saved result.
    Analytics.gameCompleted(
      gameType: 'kkeunmari',
      result: didWin ? 'win' : 'lose',
      score: _chain.length,
    );
    _abandonTracker.markCompleted();
    if (reason == _End.timeUp) {
      Analytics.questFailed(questType: 'kkeunmari', failReason: 'timeout');
    }
    if (didWin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_canInteract && generation == _roundGeneration && _end == reason) {
          SoriCelebration.burst(context);
        }
      });
    }
  }

  @override
  void retireGameResult() {
    _roundGeneration++;
    _turnGeneration++;
    _dictionaryGeneration++;
    _stopTimer();
    _cancelPendingTurnAction();
    _openingSpeech?.cancel();
    _openingSpeech = null;
    _queuedSpeech = null;
    _stopSpeech();
    super.retireGameResult();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    soriRouteObserver.unsubscribe(this);
    _abandonTracker.dispose();
    _timer?.cancel();
    _turnDelayTimer?.cancel();
    _openingSpeech?.cancel();
    _stopSpeech();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final recovery =
        studyEvidenceRecoveryFrame(t.kkeunmariTitle) ??
        gameResultRecoveryFrame(t.kkeunmariTitle);
    if (recovery != null) return recovery;
    final generation = _roundGeneration;
    final turnGeneration = _turnGeneration;
    if (_loading) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.kkeunmariTitle,
        padding: EdgeInsets.zero,
        child: Semantics(
          liveRegion: true,
          label: t.gameLoading,
          excludeSemantics: true,
          child: AppLoading(message: t.gameLoading),
        ),
      );
    }
    if (_loadFailed) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.kkeunmariTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: t.loadErrorTryAgain,
          onRetry: () => _retryLoad(generation),
          messageLiveRegion: true,
        ),
      );
    }
    if (!_hasPlayablePool) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.kkeunmariTitle,
        child: SoriEmptyState(
          asset: CanonicalCompanionArt.magpieGuide,
          icon: Icons.link_off_rounded,
          title: t.kkeunmariTitle,
          body: widget.source == null
              ? t.kkeunmariEmptyBody
              : t.kkeunmariSelectionEmpty,
        ),
      );
    }
    if (_end == _End.none) {
      final word = _last!;
      final gloss =
          widget.source?.meaningFor(
            word.word,
            Localizations.localeOf(context).languageCode,
          ) ??
          word.meaning(Localizations.localeOf(context).languageCode);
      return ApprovedWordChainFrame(
        title: t.kkeunmariTitle,
        onLeave: _retireStudy,
        homeEscape: SoriHomeEscape(
          confirmWhen: _end == _End.none && _remaining > 0,
        ),
        contentBuilder: (context, close) => ValueListenableBuilder<double>(
          valueListenable: SoriSpeech.speed,
          builder: (context, speed, _) =>
              ValueListenableBuilder<CompanionPreference>(
                valueListenable: MascotPreference.preference,
                builder: (context, preference, _) {
                  final kind = MascotPreference.mascotKindFor(preference);
                  final userTurn = _turn == _Turn.user;
                  final speedText = speed
                      .toStringAsFixed(2)
                      .replaceFirst(RegExp(r'0+$'), '')
                      .replaceFirst(RegExp(r'\.$'), '');
                  return ApprovedWordChainView(
                    key: const ValueKey('kkeunmari-gameplay'),
                    title: t.kkeunmariTitle,
                    instruction: t.kkeunmariSubtitle,
                    turnLabel: userTurn
                        ? t.kkeunmariYourTurn
                        : kind == null
                        ? t.companionNeutralThinking
                        : t.kkeunmariTigerTurn,
                    timerLabel: t.kkeunmariTimerSeconds(_remaining),
                    chainLabel: t.kkeunmariChainLength(_chain.length),
                    chain: [for (final item in _chain) item.word],
                    word: word.word,
                    meaning: gloss == 'TODO' ? '' : gloss,
                    requiredSyllable: _required,
                    requiredHint: t.kkeunmariStartHint(_required),
                    inputHint: t.kkeunmariInputHint,
                    listenLabel: t.approvedGameListen,
                    listenSemantics: t.ttsListenTarget(word.word),
                    submitLabel: t.kkeunmariSubmit,
                    controller: _ctrl,
                    focusNode: _focusNode,
                    close: close,
                    onSubmit: () =>
                        unawaited(_submit(generation, turnGeneration)),
                    onListen: () {
                      if (_canInteract &&
                          generation == _roundGeneration &&
                          turnGeneration == _turnGeneration) {
                        _speakWord(word.word);
                      }
                    },
                    speedLabel: '$speedText×',
                    onSpeed: () {
                      if (_canInteract && generation == _roundGeneration) {
                        showWordChainSpeedSheet(context);
                      }
                    },
                    userTurn: userTurn,
                    checkingDictionary: _dictionaryChecking,
                    urgent: _remaining <= 10,
                    statusMessage: _errorMsg,
                    selectionHint: widget.source == null
                        ? null
                        : t.kkeunmariSelectionHint,
                    lastWordKey: _lastWordCardKey,
                    timerKey: _timerRowKey,
                    inputKey: _inputFieldKey,
                    companion: userTurn || kind == null
                        ? null
                        : CharacterClipPlayer(
                            asset: CharacterClips.thinkingFor(kind),
                            size: 56,
                            loop: true,
                            blendColor: gameCream,
                            fallbackKind: kind,
                            fallbackEmotion: MascotEmotion.thinking,
                          ),
                  );
                },
              ),
        ),
      );
    }
    // Results retain their existing save/recovery, reward, replay and home contracts.
    return SoriStudyFrame(
      onLeave: _retireStudy,
      title: t.kkeunmariTitle,
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SoriMinHeightScroll(
          minHeight: 0,
          fillViewport: true,
          intrinsic: false,
          child: Padding(
            padding: soriClampPadding(
              constraints.maxWidth,
              base: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.source != null) ...[
                  Text(t.kkeunmariSelectionHint),
                  const SizedBox(height: Spacing.md),
                ],
                _ChainStrip(chain: _chain),
                const SizedBox(height: Spacing.md),
                _ResultCard(
                  learningAttempt: _learningAttempt,
                  end: _end,
                  chainLength: _chain.length,
                  xpEarned: _persistedXp ?? 0,
                  rewardReady: _persistedXp != null,
                  isNewBest: _newBest,
                  feedbackCompletion: _feedbackCompletion.current,
                  onAgain: () {
                    if (_canInteract &&
                        generation == _roundGeneration &&
                        _end != _End.none) {
                      _start();
                    }
                  },
                  onHome: () {
                    if (_canInteract &&
                        generation == _roundGeneration &&
                        _end != _End.none) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chain Strip ──────────────────────────────────────────────────────────────

class _ChainStrip extends StatelessWidget {
  final List<KkeunmariWord> chain;
  const _ChainStrip({required this.chain});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: chain.length,
        separatorBuilder: (_, __) => Center(
          child: Container(
            width: 10,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: SoriColors.accent.withValues(alpha: 0.35),
          ),
        ),
        itemBuilder: (_, i) {
          final w = chain[chain.length - 1 - i];
          final isLast = i == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLast
                  ? SoriColors.accent.withValues(alpha: 0.18)
                  : s.surfaceAlt,
              borderRadius: SoriRadius.brPill,
              border: Border.all(
                color: isLast ? SoriColors.accent : s.border,
                width: isLast ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              w.word,
              style: SoriTextTheme.of(context).caption.copyWith(
                color: isLast ? SoriColors.accent : s.text,
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final LearningAttempt? learningAttempt;
  final _End end;
  final int chainLength;
  final int xpEarned;
  final bool rewardReady;
  final bool isNewBest;
  final FeedbackCompletion? feedbackCompletion;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _ResultCard({
    this.learningAttempt,
    required this.end,
    required this.chainLength,
    required this.xpEarned,
    required this.rewardReady,
    required this.isNewBest,
    required this.feedbackCompletion,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final won = end == _End.tigerStuck || end == _End.deadEnd;
    final color = won ? SoriColors.success : SoriColors.warning;
    final reasonLabel = switch (end) {
      _End.tigerStuck => t.kkeunmariResultBody(chainLength),
      _End.deadEnd => t.kkeunmariDeadEnd,
      _End.timeUp => t.kkeunmariTimeUp,
      _End.userStuck => t.kkeunmariResultBody(chainLength),
      _End.none => '',
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${t.kkeunmariResultTitle}. $reasonLabel',
      child: SoriCard(
        variant: SoriCardVariant.hero,
        accent: color,
        tinted: true,
        width: double.infinity,
        child: Column(
          children: [
            Mascot(
              kind: won ? MascotKind.magpie : MascotKind.tiger,
              emotion: won ? MascotEmotion.celebrate : MascotEmotion.worry,
              size: 88,
              animate: true,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              t.kkeunmariResultTitle,
              style: SoriTextTheme.of(context).caption.copyWith(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              reasonLabel,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).caption.copyWith(
                color: s.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                SoriChip(
                  label: t.kkeunmariChainLength(chainLength),
                  accent: SoriColors.accent,
                ),
                if (rewardReady)
                  LearningRewardPresentation(
                    attempt: learningAttempt,
                    kind: SoriRewardKind.xp,
                    amount: xpEarned,
                    child: SoriBadge.xp(xpEarned, size: 24),
                  ),
              ],
            ),
            if (rewardReady && isNewBest) ...[
              const SizedBox(height: Spacing.sm),
              LearningRewardPresentation(
                attempt: learningAttempt,
                kind: SoriRewardKind.personalBest,
                amount: 1,
                identity: 'kkeunmari',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      SoriGlyph.record,
                      size: 15,
                      color: SoriColors.gold,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        t.gameNewBest,
                        style: SoriTextTheme.of(context).caption.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SoriColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (feedbackCompletion != null &&
                feedbackScope != null &&
                feedbackScope.featureGate.isEnabled) ...[
              const SizedBox(height: Spacing.lg),
              ContentFeedbackCard(
                feedbackContext: feedbackCompletion!.context,
                featureGate: feedbackScope.featureGate,
                submitFeedback: feedbackScope.submitFeedback,
                completedMissionIds: feedbackScope.completedMissionIds,
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: SoriButton.outlined(
                    label: t.kkeunmariBackHome,
                    fullWidth: true,
                    onTap: onHome,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: SoriButton.filled(
                    label: t.kkeunmariPlayAgain,
                    icon: Icons.refresh_rounded,
                    accent: color,
                    fullWidth: true,
                    onTap: onAgain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
