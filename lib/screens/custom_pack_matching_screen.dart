import '../data/canonical_companion_art.dart';
import '../services/haptic_service.dart';
import '../widgets/sori/study_evidence_recovery.dart';
import '../widgets/sori/game_result_recovery.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../models/feedback_completion.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/custom_pack_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/route_observer.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/approved_games/approved_game_material.dart';
import '../widgets/sori/approved_games/approved_matching_view.dart';

/// A3 — "짝 맞추기"(Matching). 한국어 ↔ 뜻 카드를 짝짓고 완료한 자리에 남긴다.
/// 가벼운 인출 강화 게임. 한 라운드 최대 6쌍.
class CustomPackMatchingScreen extends StatefulWidget {
  final String packId;
  final List<ExtractedWord>? words;
  const CustomPackMatchingScreen({
    super.key,
    required this.packId,
    this.words,
    this.recordResult,
  });

  /// Injects the existing result write for delayed/failing persistence tests.
  final Future<GameOutcome> Function({required String gameId, required int xp})?
  recordResult;

  @override
  State<CustomPackMatchingScreen> createState() =>
      _CustomPackMatchingScreenState();
}

class _CustomPackMatchingScreenState extends State<CustomPackMatchingScreen>
    with
        WidgetsBindingObserver,
        RouteAware,
        ScreenCoachMixin<CustomPackMatchingScreen>,
        GameResultRecovery<CustomPackMatchingScreen>,
        StudyEvidenceRecovery<CustomPackMatchingScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  int _presentation = 0;
  bool get _acceptsInput => studyEvidenceAcceptsInput && gameResultAcceptsInput;
  void _retireStudy() {
    _stopSpeech();
    retireStudyEvidence();
    retireGameResult();
  }

  List<ExtractedWord> _pool = const [];
  String _languageCode = 'de';
  bool _roundInitialized = false;
  bool _foreground = true;
  bool _routeVisible = true;
  bool _ownsSpeech = false;
  int _speechRequest = 0;

  List<ExtractedWord> _round = const [];
  List<String> _leftKo = const []; // 한국어 열 (셔플)
  List<String> _rightMeanings = const []; // 뜻 열 (셔플)
  int? _selLeft; // 선택된 한국어 index
  final Set<String> _matched = {}; // 맞춘 한국어
  // 이번 라운드에서 한 번이라도 잘못 짝지은 단어. 이후 정답은 게임 보상은
  // 유지하지만 SRS 성공 증거로 올리지 않는다.
  final Set<String> _missedKorean = {};
  String? _wrongRight; // 방금 틀린 뜻 (빨강 플래시)
  String? _statusMessage;
  int _misses = 0; // 라운드 내 오답 탭 수 (XP 보상에 반영)
  GameOutcome? _outcome;

  // ── 코치마크 타겟 ──
  final GlobalKey _boardKey = GlobalKey();
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;

  @override
  String get coachId => 'cpMatching';

  @override
  bool get coachReady => _pool.length >= 2 && _round.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _boardKey,
        title: t.coachCpMatchingTitle,
        body: t.coachCpMatchingBody,
        icon: Icons.grid_view_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Analytics.gameStarted(gameType: 'matching');
    _abandonTracker = QuestAbandonTracker(
      questType: 'matching',
      questId: widget.packId,
      lastStepReached: () => 'matched_${_matched.length}',
    );
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
    if (_roundInitialized) {
      return;
    }
    _roundInitialized = true;
    _startRoundForLocale(Localizations.localeOf(context).languageCode);
  }

  void _startRoundForLocale(String languageCode) {
    _languageCode = languageCode;
    final pack = _pack;
    if (pack == null) {
      return;
    }
    _pool = pack.words
        .where((word) => word.translationFor(languageCode).trim().isNotEmpty)
        .toList();
    if (_pool.length >= 2) {
      _newRound();
    }
  }

  void _newRound() {
    _presentation++;
    final shuffled = [..._pool]..shuffle(_rng);
    // Preserve the existing rule: one tile per distinct meaning. Apply that
    // rule to the locale fixed for this round so the right column is clear.
    final seenMeanings = <String>{};
    final unique = <ExtractedWord>[];
    for (final word in shuffled) {
      final meaning = word.translationFor(_languageCode).trim();
      if (seenMeanings.contains(meaning)) {
        continue;
      }
      seenMeanings.add(meaning);
      unique.add(word);
      if (unique.length >= 6) {
        break;
      }
    }
    _round = unique;
    _leftKo = _round.map((w) => w.korean).toList()..shuffle(_rng);
    _rightMeanings =
        _round.map((word) => word.translationFor(_languageCode).trim()).toList()
          ..shuffle(_rng);
    _matched.clear();
    _missedKorean.clear();
    _selLeft = null;
    _wrongRight = null;
    _statusMessage = null;
    _misses = 0;
    _feedbackCompletion.reset();
    _outcome = null;
    resetGameResult();
  }

  void _tapLeft(int i, int presentation) {
    if (!_foreground ||
        !_routeVisible ||
        !_acceptsInput ||
        presentation != _presentation ||
        _roundDone) {
      return;
    }
    final ko = _leftKo[i];
    if (_matched.contains(ko)) {
      return;
    }
    _presentation++;
    HapticService.selectionClick();
    setState(() {
      _selLeft = i;
      _wrongRight = null;
      _statusMessage = null;
    });
    _ownsSpeech = true;
    final request = ++_speechRequest;
    unawaited(
      TtsService.speak(ko).whenComplete(() {
        if (request == _speechRequest) {
          _ownsSpeech = false;
        }
      }),
    );
  }

  Future<void> _tapRight(String meaning, int presentation) async {
    if (!_foreground ||
        !_routeVisible ||
        !_acceptsInput ||
        presentation != _presentation ||
        _roundDone ||
        _selLeft == null) {
      return;
    }
    final ko = _leftKo[_selLeft!];
    final expected = _round
        .firstWhere((word) => word.korean == ko)
        .translationFor(_languageCode)
        .trim();
    final judgment = ++_presentation;
    final firstJudgment = !_missedKorean.contains(ko);
    if (firstJudgment) {
      final correct = meaning == expected;
      final attempt = SrsReviewAttempt(id: ko, gotIt: meaning == expected);
      final progress = VocabProgressAttempt(
        seenId: ko,
        wrongCountId: correct ? null : ko,
      );
      if (!await saveStudyEvidence(() async {
        if (!await attempt.save()) {
          return false;
        }
        if (!studyEvidenceIsCurrent) {
          return false;
        }
        return progress.save();
      })) {
        return;
      }
    }
    if (!mounted || !_acceptsInput || judgment != _presentation) {
      return;
    }
    if (meaning == expected) {
      if (_foreground && _routeVisible) {
        SoundService.correct();
      }
      // Eine spätere Korrektur darf XP und den Spielfortschritt abschließen,
      // aber keine positive SRS-Evidenz über den vorherigen Fehlversuch legen.
      setState(() {
        _matched.add(ko);
        _selLeft = null;
        _wrongRight = null;
        _statusMessage = AppL10n.of(context).statsCorrect;
      });
      if (_roundDone) {
        _finish();
      }
    } else {
      if (_foreground && _routeVisible) {
        SoundService.wrong();
      }
      _misses++;
      // Pro Wort/Runde genau ein negativer Lernnachweis. Wiederholte Taps auf
      // dieselbe falsche Zuordnung dürfen den Zähler nicht künstlich aufblasen.
      _missedKorean.add(ko);
      setState(() {
        _wrongRight = meaning;
        _statusMessage = AppL10n.of(context).statsWrong;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && _acceptsInput && judgment == _presentation) {
          setState(() => _wrongRight = null);
        }
      });
    }
  }

  void _restart(int presentation) {
    if (!_acceptsInput ||
        presentation != _presentation ||
        !_roundDone ||
        _feedbackCompletion.current == null) {
      return;
    }
    setState(
      () => _startRoundForLocale(Localizations.localeOf(context).languageCode),
    );
  }

  Future<void> _finish() async {
    if (!_acceptsInput) return;
    final presentation = _presentation;
    // Fehlerfreie Runde → voller XP, sonst kleiner Abschlag (Aufwand spiegeln).
    final recorder = widget.recordResult;
    final outcome = await saveGameResult(
      gameId: 'cp_matching',
      xp: _roundXp,
      saveOverride: recorder == null
          ? null
          : () => recorder(gameId: 'cp_matching', xp: _roundXp),
    );
    if (!mounted ||
        !studyEvidenceIsCurrent ||
        presentation != _presentation ||
        outcome == null) {
      return;
    }
    setState(() => _outcome = outcome);
    _feedbackCompletion.complete(
      () => FeedbackCompletion.customPackMatching(
        packId: widget.packId,
        pairs: _matched.length,
        misses: _misses,
      ),
    );
    unawaited(
      Analytics.gameCompleted(
        gameType: 'matching',
        result: 'win',
        score: _round.length,
      ),
    );
    if (!studyEvidenceIsCurrent || presentation != _presentation) return;
    _abandonTracker.markCompleted();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    soriRouteObserver.unsubscribe(this);
    _stopSpeech();
    _abandonTracker.dispose();
    super.dispose();
  }

  void _stopSpeech() {
    if (!_ownsSpeech) {
      return;
    }
    _ownsSpeech = false;
    _speechRequest++;
    unawaited(TtsService.stop());
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _stopSpeech();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
  }

  @override
  void didPop() {
    _routeVisible = false;
    _stopSpeech();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stopSpeech();
    }
  }

  bool get _roundDone => _round.isNotEmpty && _matched.length >= _round.length;

  int get _roundXp => _misses == 0 ? _round.length * 4 : _round.length * 3;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation;
    final recovery =
        studyEvidenceRecoveryFrame(AppL10n.of(context).wbMatching) ??
        gameResultRecoveryFrame(AppL10n.of(context).wbMatching);
    if (recovery != null) {
      return recovery;
    }
    final t = AppL10n.of(context);
    final pack = _pack;

    if (pack == null) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.wbMatching,
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
    if (_pool.length < 2 || _round.length < 2) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.wbMatching,
        child: Center(
          child: SoriEmptyState(
            asset: CanonicalCompanionArt.magpieGuide,
            icon: Icons.grid_view_rounded,
            title: t.wbMatching,
            body: t.wbMatchingNeedMore,
          ),
        ),
      );
    }

    if (_roundDone) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.wbMatching,
        child: _buildDone(t),
      );
    }

    final matchedMeanings = {
      for (final word in _round)
        if (_matched.contains(word.korean))
          word.translationFor(_languageCode).trim(),
    };
    return ApprovedGameFrame(
      navigationArt: 'jade_geometric_legacy',
      title: t.wbMatching,
      onLeave: _retireStudy,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_roundDone && (_matched.isNotEmpty || _misses > 0),
      ),
      contentBuilder: (context, close) => ApprovedMatchingView(
        title: t.wbMatching,
        topic: pack.name,
        counter: t.approvedMatchingCounter(_matched.length, _round.length),
        koreanLabel: t.wbFieldKorean,
        meaningLabel: t.wbFieldMeaning,
        instruction: _selLeft == null
            ? t.approvedMatchingPickKorean
            : t.approvedMatchingPickMeaning,
        footer: _statusMessage == t.statsWrong
            ? t.statsWrong
            : _selLeft != null
            ? t.approvedMatchingRetry
            : _matched.isNotEmpty
            ? t.approvedMatchingFound
            : t.approvedMatchingInstruction,
        statusMessage: _statusMessage,
        leading: close,
        boardKey: _boardKey,
        leftTiles: [
          for (var i = 0; i < _leftKo.length; i++)
            ApprovedMatchingTile(
              label: _leftKo[i],
              matched: _matched.contains(_leftKo[i]),
              selected: _selLeft == i,
              onTap: _acceptsInput && !_matched.contains(_leftKo[i])
                  ? () => _tapLeft(i, presentation)
                  : null,
            ),
        ],
        rightTiles: [
          for (final meaning in _rightMeanings)
            ApprovedMatchingTile(
              label: meaning,
              matched: matchedMeanings.contains(meaning),
              wrong: _wrongRight == meaning,
              onTap:
                  _acceptsInput &&
                      _selLeft != null &&
                      !matchedMeanings.contains(meaning)
                  ? () => _tapRight(meaning, presentation)
                  : null,
            ),
        ],
      ),
    );
  }

  void _closeResult(int presentation) {
    if (!_acceptsInput ||
        presentation != _presentation ||
        !(_roundDone && _feedbackCompletion.current != null)) {
      return;
    }
    _retireStudy();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/my_words', (route) => route.isFirst);
  }

  Widget _buildDone(AppL10n t) {
    final presentation = _presentation;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${t.wbMatchingDone}. ${t.wbMatchingDoneBody}',
      child: GameOverCard(
        outcome: _outcome,
        rewardReady: _outcome != null,
        headline: t.wbMatchingDone,
        scoreLabel: t.wbMatchingDoneBody,
        feedbackContext: _feedbackCompletion.current?.context,
        xpGained: _outcome?.xpGained ?? 0,
        mascotKind: MascotKind.magpie,
        mascotEmotion: MascotEmotion.celebrate,
        actions: [
          SoriButton(
            label: t.quizAgain,
            icon: Icons.refresh_rounded,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: () => _restart(presentation),
          ),
          SoriButton(
            label: t.btnClose,
            variant: SoriButtonVariant.ghost,
            fullWidth: true,
            onTap: () => _closeResult(presentation),
          ),
        ],
      ),
    );
  }
}
