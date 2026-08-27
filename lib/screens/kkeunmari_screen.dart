import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../models/feedback_completion.dart';
import '../models/scenario.dart';
import '../services/data_loader.dart';
import '../services/kkeunmari_dictionary_service.dart';
import '../services/kkeunmari_engine.dart';
import '../services/learner_level_selection.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/home_action.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/sori_icon.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/text_field.dart';
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
  const KkeunmariScreen({super.key, this.poolLoader});

  /// Optional deterministic seam. Production keeps [KkeunmariEngine.load].
  final Future<List<KkeunmariWord>> Function()? poolLoader;

  @override
  State<KkeunmariScreen> createState() => _KkeunmariScreenState();
}

class _KkeunmariScreenState extends State<KkeunmariScreen>
    with ScreenCoachMixin<KkeunmariScreen>, WidgetsBindingObserver {
  static const _turnSeconds = 30;

  bool _loading = true;
  bool _loadFailed = false;
  List<KkeunmariWord> _chain = [];
  final Set<String> _used = {};
  Set<String> _vocabKeys = {}; // M1: nur diese Wörter speisen das SRS
  _Turn _turn = _Turn.user;
  _End _end = _End.none;
  bool _newBest = false; // diese Runde = längste Kette aller Zeiten?
  bool _dictionaryChecking = false;
  int _roundGeneration = 0;
  String _errorMsg = '';
  LearnerLevel _maxLevel = LearnerLevel.a1;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;
  KkeunmariWord? _last; // 마지막으로 낸 단어 (chain 마지막)

  Timer? _timer;
  int _remaining = _turnSeconds;
  bool _lifecyclePaused = false;
  bool _resumeCountdownAfterLifecycle = false;
  Timer? _turnDelayTimer;
  _PendingTurnAction _pendingTurnAction = _PendingTurnAction.none;
  Duration _pendingTurnDelay = Duration.zero;
  DateTime? _pendingTurnStartedAt;

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

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
    _start();
    scheduleCoach();
    Analytics.gameStarted(gameType: 'kkeunmari');
    _abandonTracker = QuestAbandonTracker(
      questType: 'kkeunmari',
      lastStepReached: () => 'chain_${_chain.length}',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecyclePaused = false;
        if (_resumeCountdownAfterLifecycle &&
            _end == _End.none &&
            _turn == _Turn.user &&
            _remaining > 0) {
          _runTimer();
        }
        _resumeCountdownAfterLifecycle = false;
        _resumePendingTurnAction();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _lifecyclePaused = true;
        if (_timer != null) {
          _resumeCountdownAfterLifecycle = true;
          _timer?.cancel();
          _timer = null;
        }
        _pausePendingTurnAction();
    }
  }

  Future<void> _start() async {
    if (!_loading || _loadFailed) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    _roundGeneration++;
    _feedbackCompletion.reset();
    _cancelPendingTurnAction();
    _maxLevel = learnerLevelForStoredCode(Storage.userLevelCode);
    try {
      final poolLoader = widget.poolLoader;
      if (poolLoader == null) {
        await KkeunmariEngine.load();
      } else {
        KkeunmariEngine.setPoolForTesting(await poolLoader());
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    if (!mounted) {
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
    // M1: Vokabel-Keys laden → nur Kkeunmari-Wörter, die echte Vokabeln sind,
    // speisen das SRS (best-effort; Spiel läuft auch ohne).
    if (widget.poolLoader == null && _vocabKeys.isEmpty) {
      try {
        final vocab = await DataLoader.loadVocab();
        if (!mounted) return;
        _vocabKeys = vocab.map((v) => v.korean).toSet();
      } catch (_) {
        /* SRS-Einspeisung optional */
      }
    }
    if (!mounted) return;
    if (KkeunmariEngine.pool.isEmpty) {
      // Pool leer (Asset fehlt/defekt) → Leer-Zustand zeigen statt pickStart-Crash.
      setState(() => _loading = false);
      return;
    }
    final start = KkeunmariEngine.pickStart(maxLevel: _maxLevel);
    setState(() {
      _chain = [start];
      _used
        ..clear()
        ..add(start.word);
      _last = start;
      _turn = _Turn.user;
      _end = _End.none;
      _newBest = false;
      _dictionaryChecking = false;
      _errorMsg = '';
      _remaining = _turnSeconds;
      _loading = false;
    });
    _ctrl.clear();
    _startTimer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) TtsService.speak(start.word);
    });
  }

  Future<void> _retryLoad() async {
    if (widget.poolLoader == null) {
      KkeunmariEngine.reset();
    }
    await _start();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _turnSeconds;
    if (_lifecyclePaused) {
      _timer = null;
      _resumeCountdownAfterLifecycle = true;
      return;
    }
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
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
    if (!_lifecyclePaused) {
      _armPendingTurnAction();
    }
  }

  void _armPendingTurnAction() {
    if (_pendingTurnAction == _PendingTurnAction.none) return;
    _pendingTurnStartedAt = DateTime.now();
    _turnDelayTimer = Timer(_pendingTurnDelay, () {
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
    if (_pendingTurnAction != _PendingTurnAction.none &&
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

  Future<void> _submit() async {
    if (_dictionaryChecking || _end != _End.none || _turn != _Turn.user) {
      return;
    }
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;
    final (valid, reason, word) = KkeunmariEngine.validateUserWord(
      input,
      _required,
      _used,
    );
    if (!valid) {
      if (reason != 'not_in_pool') {
        _showValidationError(reason);
        return;
      }
      await _checkDictionaryWord(input);
      return;
    }
    _acceptUserWord(word!);
  }

  Future<void> _checkDictionaryWord(String input) async {
    final t = AppL10n.of(context);
    final generation = _roundGeneration;
    setState(() {
      _dictionaryChecking = true;
      _errorMsg = t.kkeunmariDictionaryChecking;
    });
    try {
      final result = await KkeunmariDictionaryService.validate(word: input);
      if (!mounted ||
          generation != _roundGeneration ||
          _end != _End.none ||
          _turn != _Turn.user) {
        return;
      }
      if (result.isValid) {
        _acceptUserWord(KkeunmariWord.dictionary(input));
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() {
        _errorMsg = switch (result.status) {
          KkeunmariDictionaryStatus.invalid => t.kkeunmariNotDictionaryWord,
          KkeunmariDictionaryStatus.unavailable =>
            t.kkeunmariDictionaryUnavailable,
          KkeunmariDictionaryStatus.valid => '',
        };
      });
    } finally {
      if (mounted) {
        setState(() => _dictionaryChecking = false);
      }
    }
  }

  void _showValidationError(String reason) {
    final t = AppL10n.of(context);
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMsg = switch (reason) {
        'not_korean' => t.kkeunmariNotKorean,
        'wrong_start' => t.kkeunmariWrongStart(_required),
        'already_used' => t.kkeunmariAlreadyUsed,
        _ => t.kkeunmariNotInPool,
      };
    });
  }

  void _acceptUserWord(KkeunmariWord w) {
    HapticFeedback.lightImpact();
    // 정답을 또렷한 긍정 신호로 알린다 — 예전엔 햅틱만 있어 곧바로 뜨는
    // 호랑이 '생각 중' 클립이 오답 플래시처럼 읽혔다 (Jin 2026-08-11 실기기).
    SoundService.correct();
    setState(() {
      _chain.add(w);
      _used.add(w.word);
      _last = w;
      _errorMsg = '';
      _ctrl.clear();
    });
    TtsService.speak(w.word);

    // M1: nur echte Vokabeln ins SRS (Kkeunmari-Pool ≠ Vokabel-CSV → sonst
    // Geisterkarten, die in der Wiederholung nie auftauchen).
    if (_vocabKeys.contains(w.word)) {
      Storage.srsReview(w.word, gotIt: true);
    }

    // The bundle-level `is_dead_end` is only a full-pool snapshot. A real
    // turn must use the learner-level subset and already-used words, otherwise
    // a stale next_count can end a valid chain (or delay an impossible one).
    if (KkeunmariEngine.nextCountFor(w.last, _used, maxLevel: _maxLevel) == 0) {
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
    if (!mounted || _end != _End.none) return;
    final next = KkeunmariEngine.pickTigerNext(
      _required,
      _used,
      maxLevel: _maxLevel,
    );
    if (next == null) {
      _endGame(_End.tigerStuck);
      return;
    }
    setState(() {
      _chain.add(next);
      _used.add(next.word);
      _last = next;
      _turn = _Turn.user;
    });
    TtsService.speak(next.word);
    _startTimer();
    _focusNode.requestFocus();
  }

  void _endGame(_End reason) {
    if (_end != _End.none) return;
    _stopTimer();
    _cancelPendingTurnAction();
    HapticFeedback.heavyImpact();
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
    // 사용자 승 (tigerStuck, deadEnd) → 셀러브레이션 + Phase 4 Quest-Tracking.
    final didWin = reason == _End.tigerStuck || reason == _End.deadEnd;
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
        if (mounted) SoriCelebration.burst(context);
      });
      // ignore: discarded_futures
      Storage.incKkeunmariWins();
    }
    // XP 보상 — chain length × 10. 최소 20.
    final earned = (_chain.length * 10).clamp(20, 500);
    // ignore: discarded_futures
    Storage.addXp(earned);
    // Persönliche Bestleistung = längste Kette (Selbst-Wettbewerb, keine Rangliste).
    // ignore: discarded_futures
    Storage.recordGameBest('kkeunmari', _chain.length).then((b) {
      if (mounted && b) setState(() => _newBest = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _abandonTracker.dispose();
    _timer?.cancel();
    _turnDelayTimer?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    if (_loading) {
      return SoriStudyFrame(
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
        title: t.kkeunmariTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: t.loadErrorTryAgain,
          onRetry: _retryLoad,
          messageLiveRegion: true,
        ),
      );
    }

    if (KkeunmariEngine.pool.isEmpty) {
      return SoriStudyFrame(
        title: t.kkeunmariTitle,
        child: SoriEmptyState(
          asset: 'assets/illustrations/mascot/magpie_encourage.png',
          icon: Icons.link_off_rounded,
          title: t.kkeunmariTitle,
          body: t.kkeunmariEmptyBody,
        ),
      );
    }

    return SoriStudyFrame(
      title: t.kkeunmariTitle,
      leading: SoriHomeAction(
        // `_remaining` resets to `_turnSeconds` both at a brand-new round
        // (`_start`, :240) and at the start of every later user turn
        // (`_tigerMove` → `_startTimer`, :478) — not only once. Gating on
        // that alone would also flag `_end` (dead_end/tiger_stuck already
        // resolved, timer just left mid-value) as "round active" and pop an
        // unneeded leave-confirmation over an already-shown result card.
        // `_end == _End.none` is the existing round-lifecycle boolean that
        // closes that gap.
        isRoundActive: () =>
            _end == _End.none && _remaining > 0 && _remaining < _turnSeconds,
      ),
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: soriClampPadding(
            constraints.maxWidth,
            base: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── hero ──
              // ⚠️ aspectRatio 는 **에셋 실제 비율**이어야 한다.
              // kkeunmari_hero.png 는 1254×700(≈1.79)인데 10/3(≈3.33)
              // 프레임에 `BoxFit.cover` 로 넣고 있어 세로의 **46%** 가
              // 잘려 나갔다 — 호랑이와 까치가 위아래로 잘려 보이던 원인
              // (Jin 2026-08-07 실기기: "Wortkette에서 동영상이 잘려").
              // 에셋을 다시 만들 필요 없이 프레임만 맞추면 된다.
              HanokHeader(
                asset: 'assets/illustrations/hanok/kkeunmari_hero.png',
                fallbackIcon: Icons.link_rounded,
                fallbackTint: SoriColors.accent,
                aspectRatio: 1254 / 700,
              ),
              const SizedBox(height: Spacing.md),

              // ── chain 시각화 ──
              _ChainStrip(chain: _chain),
              const SizedBox(height: Spacing.md),

              if (_end != _End.none)
                _ResultCard(
                  end: _end,
                  chainLength: _chain.length,
                  xpEarned: (_chain.length * 10).clamp(20, 500),
                  isNewBest: _newBest,
                  feedbackCompletion: _feedbackCompletion.current,
                  onAgain: _start,
                  onHome: () => Navigator.pop(context),
                )
              else ...[
                // ── 현재 차례 + 타이머 ──
                Wrap(
                  key: _timerRowKey,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  children: [
                    _TurnIndicator(turn: _turn, t: t),
                    _Timer(remaining: _remaining, total: _turnSeconds),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // ── 마지막 단어 카드 (last 음절 강조) ──
                KeyedSubtree(
                  key: _lastWordCardKey,
                  child: _LastWordCard(word: _last!),
                ),
                const SizedBox(height: Spacing.md),

                // ── 사용자 차례: 입력 ──
                if (_turn == _Turn.user) ...[
                  Text(
                    t.kkeunmariStartHint(_required),
                    style: TextStyle(
                      color: s.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriTextField(
                    fieldKey: _inputFieldKey,
                    controller: _ctrl,
                    focusNode: _focusNode,
                    autofocus: true,
                    enabled: !_dictionaryChecking,
                    textAlign: TextAlign.center,
                    hintText: t.kkeunmariInputHint,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    onSubmitted: (_) => unawaited(_submit()),
                  ),
                  if (_errorMsg.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SoriColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.md),
                  SoriButton.filled(
                    label: t.kkeunmariSubmit,
                    icon: Icons.send_rounded,
                    accent: SoriColors.accent,
                    fullWidth: true,
                    onTap: _dictionaryChecking
                        ? null
                        : () => unawaited(_submit()),
                  ),
                ] else
                  // 호랑이 차례: 짧은 "생각 중" 카드
                  SoriCard(
                    variant: SoriCardVariant.base,
                    accent: SoriColors.tiger,
                    tinted: true,
                    child: Row(
                      children: [
                        // 생각 중 클립 루프 — 카드 실배경과 **같은 함수**로
                        // blendColor를 맞춰 흰 배경 흡수(수식 복제 금지).
                        CompanionBuilder(
                          builder: (context, kind) => CharacterClipPlayer(
                            asset: CharacterClips.thinkingFor(kind),
                            size: 56,
                            loop: true,
                            blendColor: SoriCard.resolvedBackground(
                              context,
                              accent: SoriColors.tiger,
                              tinted: true,
                            ),
                            fallbackKind: kind,
                            fallbackEmotion: MascotEmotion.thinking,
                          ),
                          noneBuilder: (context) => const SizedBox.square(
                            dimension: 56,
                            child: Icon(
                              Icons.psychology_alt_rounded,
                              color: SoriColors.tiger,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Text(
                            MascotPreference.hasCompanion
                                ? t.kkeunmariTigerTurn
                                : t.companionNeutralThinking,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SoriColors.tiger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: Spacing.lg),

                // ── chain length ──
                Center(
                  child: SoriChip(
                    label: t.kkeunmariChainLength(_chain.length),
                    accent: SoriColors.accent,
                    variant: SoriChipVariant.soft,
                  ),
                ),
              ],
            ],
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
              style: TextStyle(
                color: isLast ? SoriColors.accent : s.text,
                fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Turn Indicator ───────────────────────────────────────────────────────────

class _TurnIndicator extends StatelessWidget {
  final _Turn turn;
  final AppL10n t;
  const _TurnIndicator({required this.turn, required this.t});

  @override
  Widget build(BuildContext context) {
    final isUser = turn == _Turn.user;
    final color = isUser ? SoriColors.accent : SoriColors.tiger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUser ? Icons.person_rounded : Icons.pets_rounded,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            isUser ? t.kkeunmariYourTurn : t.kkeunmariTigerTurn,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Timer extends StatelessWidget {
  final int remaining;
  final int total;
  const _Timer({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final urgent = remaining <= 10;
    final color = urgent ? SoriColors.danger : SoriColors.info;
    final label = t.kkeunmariTimerSeconds(remaining < 0 ? 0 : remaining);
    return Semantics(
      liveRegion: urgent,
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            child: SoriProgressBar(
              value: (remaining / total).clamp(0.0, 1.0),
              thickness: 6,
              animated: false,
              color: color,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              // 카운트다운 자릿수 폭 고정(흔들림 방지).
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Last Word Card ───────────────────────────────────────────────────────────

class _LastWordCard extends StatelessWidget {
  final KkeunmariWord word;
  const _LastWordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final chars = word.word.split('');
    void onListen() => unawaited(TtsService.speak(word.word));
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.accent,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final n = chars.length;
              final fittedBox = ((c.maxWidth - (n - 1) * 4) / n).clamp(
                36.0,
                56.0,
              );
              final scaledGlyph = MediaQuery.textScalerOf(context).scale(20);
              final accessibleBox = (scaledGlyph + Spacing.md).clamp(
                36.0,
                72.0,
              );
              final box = fittedBox < accessibleBox ? accessibleBox : fittedBox;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: List.generate(n, (i) {
                  final isLast = i == n - 1;
                  return Container(
                    width: box,
                    height: box,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLast
                          ? SoriColors.accent
                          : SoriColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(SoriRadius.sm),
                      border: Border.all(
                        color: SoriColors.accent.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      chars[i],
                      style: TextStyle(
                        color: isLast ? Colors.white : SoriColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: Spacing.sm),
          // Nur echte Übersetzungen zeigen — "TODO"/leer wird ausgeblendet
          // (der Pool ist fragment-lastig; siehe tools/content_factory/README).
          if (word.german.isNotEmpty && word.german != 'TODO')
            Text(
              word.german,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          Semantics(
            button: true,
            label: t.ttsListenTarget(word.word),
            onTap: onListen,
            excludeSemantics: true,
            child: SoriPressable(
              onTap: onListen,
              haptic: SoriHaptic.selection,
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: SoriColors.accent.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _End end;
  final int chainLength;
  final int xpEarned;
  final bool isNewBest;
  final FeedbackCompletion? feedbackCompletion;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _ResultCard({
    required this.end,
    required this.chainLength,
    required this.xpEarned,
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
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              reasonLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SoriChip(
                  label: t.kkeunmariChainLength(chainLength),
                  accent: SoriColors.accent,
                ),
                const SizedBox(width: Spacing.sm),
                SoriBadge.xp(xpEarned, size: 24),
              ],
            ),
            if (isNewBest) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    SoriGlyph.record,
                    size: 15,
                    color: SoriColors.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t.gameNewBest,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SoriColors.gold,
                    ),
                  ),
                ],
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
