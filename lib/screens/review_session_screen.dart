import '../data/canonical_companion_art.dart';
import '../services/haptic_service.dart';
import '../widgets/sori/game_reward.dart';
import '../services/learning_journey.dart';
import '../models/sori_stage_progression.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/review_session_queue.dart';
import '../services/tts_service.dart';
import '../services/culture_notes_service.dart';
import '../widgets/sori/culture_note_card.dart';
import '../widgets/sori/mascot_preference.dart';
import '../services/storage_service.dart';
import '../services/local_data_lifetime.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/confirmed_choice_action.dart';
import '../widgets/sori/deck_action_bar.dart';
import '../widgets/sori/deck_coach.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/viewport_pages.dart';
import '../widgets/sori/wordbook_add.dart';

String? unambiguousReviewLevel(Iterable<String> deckLevels) {
  const supported = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  final levels = deckLevels.map((level) => level.trim().toUpperCase()).toSet();
  if (levels.length != 1 || !supported.contains(levels.single)) return null;
  return levels.single;
}

typedef ReviewableLoader = Future<List<Vocab>> Function();

enum ReviewLoadState { loading, ready, empty, error }

/// Retains the learner's answer while its durable evidence is retried.
class _ReviewJudgment {
  _ReviewJudgment({
    required this.id,
    required this.gotIt,
    required this.needsEvidence,
  }) : srs = needsEvidence ? SrsReviewAttempt(id: id, gotIt: gotIt) : null,
       progress = gotIt ? null : VocabProgressAttempt(wrongCountId: id);

  final String id;
  final bool gotIt;
  final bool needsEvidence;
  final SrsReviewAttempt? srs;
  final VocabProgressAttempt? progress;
  bool appliedToQueue = false;
}

/// **Review Session (M2)** — "Heute lernen / 오늘의 학습".
///
/// Zieht die heute fälligen + neuen SRS-Karten (`Storage.todayGoalIds`) und
/// lässt sie als Flip-Karten wiederholen. Jede Antwort speist das SRS
/// (`Storage.srsReview`). So schließt sich der Lern-Loop: Spiele & Packs füllen
/// das SRS, hier wird es abgearbeitet.
class ReviewSessionScreen extends StatefulWidget {
  /// Optionaler vorgegebener Deck (M5: personalisierter Tageskurs). Null →
  /// lädt selbst die heute fälligen SRS-Karten (Standard "Heute lernen").
  final List<Vocab>? deck;
  final String? title;
  final String feedbackContentId;
  final String? feedbackContentLabel;
  final ReviewableLoader? reviewableLoader;
  final CultureNotesLoader? cultureNotesLoader;

  /// M5: optionaler Small-talk-Satz, der am Kursende als "한마디" gezeigt wird.
  final SmalltalkPhrase? bonusPhrase;
  const ReviewSessionScreen({
    super.key,
    this.deck,
    this.title,
    this.bonusPhrase,
    this.feedbackContentId = 'today_review',
    this.feedbackContentLabel,
    this.reviewableLoader,
    this.cultureNotesLoader,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen>
    with ScreenCoachMixin<ReviewSessionScreen> {
  ReviewLoadState _loadState = ReviewLoadState.loading;
  List<Vocab> _deck = [];
  ReviewSessionQueue<Vocab>? _queue;
  bool _flipped = false;
  // 이 카드에서 답을 한 번이라도 본 뒤에는 앞면으로 다시 돌아와도 좌/우
  // 판정을 유지한다. 새 카드가 서빙될 때만 false로 초기화한다.
  bool _cardRevealed = false;
  int _reviewed = 0;
  bool _done = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _sessionExpired = false;
  bool _leaving = false;
  ModalRoute<dynamic>? _route;
  final _sessionLifetime = LocalDataLifetime.capture();
  _ReviewJudgment? _pendingJudgment;
  XpAwardAttempt? _completionXp;
  int _presentation = 0;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  final _speech = ContentSpeechController();
  late final ConfirmedChoiceActionOwner _choiceOwner;

  bool get _loading => _loadState == ReviewLoadState.loading;
  bool get _routeIsActive => _route?.isActive ?? true;
  bool get _routeCanUpdate => mounted && !_leaving && _routeIsActive;
  bool get _sessionIsCurrent => _routeCanUpdate && _sessionLifetime.isCurrent;
  bool get _acceptsInput =>
      _sessionIsCurrent && !_saving && _pendingJudgment == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _route = route;
      _speech.subscribe(route);
    }
  }

  @override
  void deactivate() {
    // 프레임 지연은 ContentSpeechController.deactivate() 안으로 옮겼다
    // (검수#13 보강 fix 2) — 이 화면은 그냥 부르기만 하면 된다.
    _speech.deactivate();
    super.deactivate();
  }

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _answerRowKey = GlobalKey();

  @override
  String get coachId => 'review';

  @override
  bool get coachReady =>
      _acceptsInput && !_loading && _queue?.current != null && !_done;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachReviewStep1Title,
        body: t.coachReviewStep1Body,
        icon: Icons.flip_rounded,
      ),
      SpotlightStep(
        targetKey: _answerRowKey,
        title: t.coachReviewStep2Title,
        body: t.coachReviewStep2Body,
        icon: Icons.thumbs_up_down_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _choiceOwner = ConfirmedChoiceActionOwner(
      isCurrentSource: () => _sessionIsCurrent,
      onConfirmed: () {
        if (_sessionIsCurrent) {
          setState(() {});
        }
      },
    );
    _load().then((_) {
      if (mounted && _queue?.current != null) {
        _speech.playOnEnter(_card.korean);
      }
    });
    scheduleCoach();
    // K-Culture 노트 로드 후 카드 반영.
    unawaited(_loadCultureNotes());
  }

  @override
  void didUpdateWidget(covariant ReviewSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.deck, widget.deck) ||
        !identical(oldWidget.reviewableLoader, widget.reviewableLoader)) {
      _presentation++;
      _choiceOwner.replaceSource();
    }
  }

  Future<void> _loadCultureNotes() async {
    try {
      await (widget.cultureNotesLoader ?? CultureNotesService.load)();
    } catch (_) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loadState = ReviewLoadState.loading;
        _learningAttempt = null;
        _rewardPersisted = false;
        _completionXp = null;
      });
    }
    // M5: vorgegebener personalisierter Deck hat Vorrang.
    if (widget.deck != null) {
      final deck = List<Vocab>.of(widget.deck!);
      final queue = _reviewQueue(deck);
      setState(() {
        _deck = deck;
        _queue = queue;
        _reviewed = 0;
        _done = false;
        _flipped = false;
        _cardRevealed = false;
        _loadState = queue.isComplete
            ? ReviewLoadState.empty
            : ReviewLoadState.ready;
      });
      return;
    }
    late final List<Vocab> deck;
    try {
      final providedLoader = widget.reviewableLoader;
      if (providedLoader != null) {
        deck = await providedLoader();
      } else {
        // A1: CSV + 나만의 단어장 + 책 한 컷 단어를 모두 포함 (한국어 기준 dedup).
        final vocab = await ReviewDeckService.allReviewable();
        deck = ReviewDeckService.todaySelectionForLevel(
          vocab,
          levelCode: Storage.userLevelCode,
        ).words;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deck = <Vocab>[];
          _queue = null;
          _loadState = ReviewLoadState.error;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final queue = _reviewQueue(deck);
    setState(() {
      _deck = List<Vocab>.of(deck);
      _queue = queue;
      _reviewed = 0;
      _done = false;
      _flipped = false;
      _cardRevealed = false;
      _loadState = queue.isComplete
          ? ReviewLoadState.empty
          : ReviewLoadState.ready;
    });
  }

  ReviewSessionQueue<Vocab> _reviewQueue(List<Vocab> deck) {
    return ReviewSessionQueue<Vocab>(
      deck,
      idOf: (word) => word.id.trim().isEmpty ? word.korean : word.id,
    );
  }

  Vocab get _card => _queue!.current!;

  // §P2-5 플립 게이트 힌트 칩 트리거.
  final ValueNotifier<int> _flipHintTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _choiceOwner.dispose();
    _speech.dispose();
    _flipHintTrigger.dispose();
    super.dispose();
  }

  void _saveCurrent() {
    if (!_acceptsInput || _loading || _done || _queue?.current == null) {
      return;
    }
    final card = _card;
    // ignore: discarded_futures
    addToWordbook(
      context,
      korean: card.korean,
      translationDe: card.german,
      translationEn: card.english,
      romanization: card.romanization,
      posDe: card.posDe,
      exampleKorean: card.exampleKorean,
      exampleDe: card.exampleGerman,
      source: 'content_bookmark',
    );
  }

  Future<void> _likeCurrent() async {
    if (!_acceptsInput || _loading || _done || _queue?.current == null) {
      return;
    }
    final card = _card;
    await _choiceOwner.toggle(
      context,
      ConfirmedChoiceTarget.liked(
        label: card.korean,
        kind: LikedContentService.vocab,
        id: card.korean,
      ),
    );
  }

  Future<void> _shareCurrent() async {
    if (!_acceptsInput || _loading || _done || _queue?.current == null) {
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    await shareContentStoryWithRecovery(
      context: context,
      korean: _card.korean,
      gloss: _card.translationFor(lang),
    );
  }

  /// ↓ 스킵 (§P2-2) — 현재 카드를 미판정 큐 맨 뒤로 보낸다. SRS 기록 없음.
  void _deferCurrent() {
    final queue = _queue;
    if (!_acceptsInput ||
        _loading ||
        _done ||
        queue == null ||
        !queue.canDefer) {
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _presentation++;
      queue.defer();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _showPrevious() {
    final queue = _queue;
    if (!_acceptsInput || queue == null || !queue.canGoPrevious) {
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _presentation++;
      queue.previous();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _showNextHistory() {
    final queue = _queue;
    if (!_acceptsInput || queue == null || !queue.canGoForward) {
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _presentation++;
      queue.nextHistory();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _toggleFlip() {
    if (!_acceptsInput) {
      return;
    }
    setState(() {
      if (!_flipped) {
        _cardRevealed = true;
      }
      _flipped = !_flipped;
    });
  }

  String? get _unambiguousDeckLevel {
    return unambiguousReviewLevel(_deck.map((word) => word.level));
  }

  LearningAttempt? _learningAttempt;
  bool _rewardPersisted = false;

  void _answer(bool gotIt) {
    final queue = _queue;
    if (!_acceptsInput ||
        !_cardRevealed ||
        queue == null ||
        !queue.canJudgeCurrent) {
      return;
    }
    _presentation++;
    gotIt ? HapticService.mediumImpact() : HapticService.lightImpact();
    _pendingJudgment = _ReviewJudgment(
      id: _card.korean,
      gotIt: gotIt,
      needsEvidence: queue.currentNeedsEvidence,
    );
    unawaited(_savePendingJudgment());
  }

  Future<void> _savePendingJudgment() async {
    final judgment = _pendingJudgment;
    final queue = _queue;
    if (_saving || !_sessionIsCurrent || judgment == null || queue == null) {
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      _sessionLifetime.assertCurrent();
      if (!judgment.appliedToQueue) {
        final srs = judgment.srs;
        if (srs != null && !await srs.save()) {
          if (!srs.isCurrent) {
            throw const StaleLocalDataLifetimeException();
          }
          _sessionLifetime.assertCurrent();
          throw StateError('Review evidence has not been confirmed.');
        }
        if (!_routeCanUpdate) {
          return;
        }
        _sessionLifetime.assertCurrent();
        final progress = judgment.progress;
        if (progress != null && !await progress.save()) {
          _sessionLifetime.assertCurrent();
          throw StateError('Vocabulary progress has not been confirmed.');
        }
        if (!_routeCanUpdate) {
          return;
        }
        _sessionLifetime.assertCurrent();
        if (judgment.needsEvidence) {
          _reviewed++;
        }
        queue.recordJudgment(correct: judgment.gotIt);
        judgment.appliedToQueue = true;
      }
      if (!queue.isComplete) {
        setState(() {
          _pendingJudgment = null;
          _flipped = false;
          _cardRevealed = false;
        });
        _speech.playOnEnter(_card.korean);
        final next = queue.peekNext;
        _speech.prefetchNeighbors([if (next != null) next.korean]);
        return;
      }
      final attempt = _learningAttempt ??=
          LearningJourneyObserver.beginAttempt();
      await trackLearningPersistence(
        attempt,
        (_completionXp ??= XpAwardAttempt(_reviewed * 2)).save(),
      );
      if (!_routeCanUpdate) {
        return;
      }
      _sessionLifetime.assertCurrent();
      _feedbackCompletion.complete(
        () => FeedbackCompletion.review(
          contentId: widget.feedbackContentId,
          contentLabel:
              widget.feedbackContentLabel ??
              widget.title ??
              AppL10n.of(context).reviewTitle,
          level: _unambiguousDeckLevel,
          reviewed: _reviewed,
          total: queue.originalCount,
        ),
      );
      setState(() {
        _done = true;
        _pendingJudgment = null;
        _rewardPersisted = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sessionIsCurrent) {
          SoriCelebration.burst(context);
        }
      });
    } catch (error) {
      if (_routeCanUpdate) {
        setState(() {
          _saveFailed = true;
          _sessionExpired = error is StaleLocalDataLifetimeException;
        });
      }
    } finally {
      if (_routeCanUpdate) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return SoriStudyFrame(
      title: widget.title ?? t.reviewTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_done && (_reviewed > 0 || _pendingJudgment != null),
      ),
      onLeave: () => _leaving = true,
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      bottomNavigationBar: _resultAction(t),
      // ⚠️ 완료 화면에서는 한지 결을 끈다. `_HanjiPainter` 는 반지름 48~163px
      // 짜리 따뜻한 구름 얼룩(#D4C496 @0.075)을 최대 40개 뿌려 배경을
      // 얼룩덜룩하게 만든다 — 실측 #FAF6EC → #F7F2E6. 그런데 캐릭터 mp4 는
      // 흰 매트를 multiply 로 지운 **완전 평면 #FAF6EC** 사각형이라, 색이
      // 맞아도 "매끈한 밝은 사각형"으로 읽힌다. Jin 이 여러 화면에서 반복
      // 지적한 "호랑이 흰 배경"의 실제 정체가 이 평면 대 얼룩 대비다.
      // 배경을 평면으로 두면 사각형이 배경과 **완전히 같은 값**이 된다.
      noiseAlpha: _done ? 0 : 0.11,
      child: switch (_loadState) {
        ReviewLoadState.loading => const AppLoading(),
        ReviewLoadState.error => _statusMessage(t.loadErrorTryAgain),
        ReviewLoadState.empty => _buildEmpty(t),
        ReviewLoadState.ready =>
          _saving
              ? const AppLoading()
              : _saveFailed
              ? _statusMessage(t.courseCheckpointSaveError)
              : _done
              ? _buildDone(t, s)
              : _buildCard(t, s),
      },
    );
  }

  Widget? _resultAction(AppL10n t) {
    if (_saving) return null;
    final close =
        _done || _loadState == ReviewLoadState.empty || _sessionExpired;
    final retryLoad = _loadState == ReviewLoadState.error;
    if (!close && !retryLoad && !_saveFailed) return null;
    return SoriBottomActionArea(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoriButton.filled(
            key: const ValueKey('review-session-result-action'),
            label: close ? t.btnClose : t.btnRetry,
            fullWidth: true,
            onTap: close
                ? () => Navigator.of(context).maybePop()
                : retryLoad
                ? _load
                : () => unawaited(_savePendingJudgment()),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage(String message) => Padding(
    key: const ValueKey('review-session-status'),
    padding: const EdgeInsets.all(Spacing.lg),
    child: LayoutBuilder(
      builder: (context, box) => SoriViewportPages(
        centerContent: true,
        sections: [
          for (final text in _textSections(
            context,
            box,
            message,
            _instructionStyle(context),
          ))
            Semantics(liveRegion: true, child: text),
        ],
      ),
    ),
  );

  Widget _buildEmpty(AppL10n t) {
    final tt = SoriTextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: LayoutBuilder(
        builder: (context, box) => SoriViewportPages(
          centerContent: true,
          sections: [
            Image.asset(
              CanonicalCompanionArt.magpieCelebrate,
              height: _artHeight(box),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            ..._textSections(context, box, t.reviewEmptyTitle, tt.h1),
            ..._textSections(
              context,
              box,
              t.reviewEmptyBody,
              _instructionStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t, SoriSurfaces s) {
    final tt = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final bonus = widget.bonusPhrase;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, box) {
          final artHeight = _artHeight(box);
          return SoriViewportPages(
            centerContent: true,
            sections: [
              Align(
                alignment: Alignment.center,
                child: CompanionBuilder(
                  builder: (context, kind) => CharacterClipPlayer(
                    asset: CharacterClips.sessionCompleteFor(kind),
                    size: artHeight,
                    blendColor: SoriColors.lightBg,
                    fallbackKind: kind,
                    fallbackEmotion: MascotEmotion.celebrate,
                  ),
                  noneBuilder: (context) => Icon(
                    Icons.celebration_rounded,
                    size: artHeight,
                    color: SoriColors.success,
                  ),
                ),
              ),
              ..._textSections(context, box, t.reviewDoneTitle, tt.h1),
              ..._textSections(
                context,
                box,
                t.reviewDoneBody,
                _instructionStyle(context).copyWith(color: s.textMuted),
              ),
              if (_rewardPersisted)
                LearningRewardPresentation(
                  attempt: _learningAttempt,
                  kind: SoriRewardKind.xp,
                  amount: _reviewed * 2,
                  presentationComplete: _rewardPersisted,
                  child: Text(
                    '+${_reviewed * 2} XP',
                    textAlign: TextAlign.center,
                    style: tt.h2.copyWith(color: SoriColors.gold),
                  ),
                ),
              if (bonus != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.reviewBonusLabel,
                        style: tt.label.copyWith(color: SoriColors.highlight),
                      ),
                    ),
                    Tooltip(
                      message: t.ttsListenTarget(bonus.ko),
                      excludeFromSemantics: true,
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => TtsService.speak(bonus.ko),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          semanticLabel: t.ttsListenTarget(bonus.ko),
                          color: SoriColors.highlight,
                        ),
                      ),
                    ),
                  ],
                ),
                ..._textSections(context, box, bonus.ko, tt.h3),
                ..._textSections(
                  context,
                  box,
                  bonus.translation(
                    Localizations.localeOf(context).languageCode,
                  ),
                  _instructionStyle(context).copyWith(color: s.textMuted),
                ),
              ],
              if (_feedbackCompletion.current != null &&
                  feedbackScope != null &&
                  feedbackScope.featureGate.isEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.md),
                  child: ContentFeedbackCard(
                    feedbackContext: _feedbackCompletion.current!.context,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                    completedMissionIds: feedbackScope.completedMissionIds,
                    mascotKind: box.maxHeight >= 380 && box.maxWidth >= SoriBreakpoints.feedbackCompanion
                        ? MascotPreference.selectedKind
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _artHeight(BoxConstraints box) => (box.maxHeight * .23).clamp(44, 120);

  TextStyle _instructionStyle(BuildContext context) {
    final body = SoriTextTheme.of(context).body;
    return Theme.of(context).platform == TargetPlatform.iOS
        ? body.copyWith(fontSize: 17)
        : body;
  }

  Iterable<Widget> _textSections(
    BuildContext context,
    BoxConstraints box,
    String text,
    TextStyle style,
  ) sync* {
    if (text.isEmpty) return;
    final pages = soriViewportTextPages(
      context,
      text,
      style: style,
      width: box.maxWidth,
      height: box.maxHeight - SoriViewportPages.controlsHeight - Spacing.sm,
    );
    for (final page in pages) {
      yield Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(page, textAlign: TextAlign.center, style: style),
      );
    }
  }

  Widget _buildCard(AppL10n t, SoriSurfaces s) {
    final queue = _queue!;
    final card = _card;
    final total = queue.originalCount;
    final browsingHistory = queue.isBrowsingHistory;
    final tt = SoriTextTheme.of(context);
    final presentation = _presentation;
    VoidCallback forThisCard(VoidCallback action) => () {
      if (mounted && _acceptsInput && presentation == _presentation) {
        action();
      }
    };

    // §P2-5: 4방향 덱 코치 — 기존 review 코치가 이미 표시된 뒤에만.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowSoriDeckCoach(
          context,
          targetKey: _cardKey,
          afterCoachIds: const ['review'],
        );
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            0,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${queue.servedPosition} / $total',
                    style: tt.label.copyWith(color: s.textMuted),
                  ),
                  Text(
                    card.level,
                    style: tt.label.copyWith(color: SoriColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : queue.servedPosition / total,
                  minHeight: 6,
                  backgroundColor: s.text.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(SoriColors.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) >= 1.6;
                final compact = constraints.maxHeight < (largeText ? 500 : 340);
                final next = queue.peekNext;
                return Semantics(
                  container: true,
                  customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                    if (queue.canGoPrevious)
                      CustomSemanticsAction(label: t.legacyVocabPrevious):
                          forThisCard(_showPrevious),
                    if (queue.canGoForward)
                      CustomSemanticsAction(label: t.btnNext): forThisCard(
                        _showNextHistory,
                      ),
                  },
                  child: SoriContentFeed(
                    key: _answerRowKey,
                    // 1.7 잔여 — 복습 피드만 snap 물리로 옵트인한다. 전역
                    // 기본값(legacy)은 다른 화면에 그대로 남는다
                    // (feed_physics_candidates_test.dart 의 legacy 기본
                    // 단언 참고).
                    physics: FeedPhysics.snap,
                    judgmentsEnabled: browsingHistory || _cardRevealed,
                    onBlockedJudgment: browsingHistory
                        ? null
                        : forThisCard(() => _flipHintTrigger.value++),
                    flipHintTrigger: _flipHintTrigger,
                    onNext: browsingHistory
                        ? forThisCard(_showNextHistory)
                        : forThisCard(() => _answer(true)),
                    // In history mode this remains non-null at the oldest
                    // card. SoriContentFeed otherwise falls a downward fling
                    // through to onNext and moves in the wrong direction.
                    onPrevious: browsingHistory || queue.canGoPrevious
                        ? forThisCard(_showPrevious)
                        : null,
                    onHard: browsingHistory
                        ? null
                        : forThisCard(() => _answer(false)),
                    onSkip: !browsingHistory && queue.canDefer
                        ? forThisCard(_deferCurrent)
                        : null,
                    skipEnabled: !browsingHistory && queue.canDefer,
                    onLike: forThisCard(_likeCurrent),
                    onBookmark: forThisCard(_saveCurrent),
                    bookmarkKey: _card.korean,
                    topAccessory: compact
                        ? null
                        : SoriSpeechIndicator(text: card.korean),
                    onShare: forThisCard(_shareCurrent),
                    onFlip: forThisCard(_toggleFlip),
                    liked: LikedContentService.isLiked(
                      kind: LikedContentService.vocab,
                      id: card.korean,
                    ),
                    underlay: next == null
                        ? null
                        : SizedBox.expand(
                            child: _heroCardBody(
                              next,
                              s,
                              tt,
                              t,
                              showBack: false,
                              compact: compact,
                            ),
                          ),
                    actionBuilder: (context) => _cardActions(
                      t,
                      card,
                      browsingHistory: browsingHistory,
                      canDefer: queue.canDefer,
                      hasMultipleCards: total > 1,
                      compact: compact,
                      forThisCard: forThisCard,
                    ),
                    knowLabel: browsingHistory ? null : t.btnGewusst,
                    hardLabel: browsingHistory ? null : t.btnNichtGewusst,
                    skipLabel: browsingHistory ? null : t.btnSkip,
                    bookmarkLabel: t.deckActionSave,
                    child: SoriPressable(
                      key: _cardKey,
                      onTap: forThisCard(_toggleFlip),
                      haptic: SoriHaptic.selection,
                      child: SizedBox(
                        key: const ValueKey('deck-card-slot'),
                        width: double.infinity,
                        height: double.infinity,
                        child: _heroCardBody(
                          card,
                          s,
                          tt,
                          t,
                          showBack: _flipped,
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
      ],
    );
  }

  Widget _cardActions(
    AppL10n t,
    Vocab card, {
    required bool browsingHistory,
    required bool canDefer,
    required bool hasMultipleCards,
    required bool compact,
    required VoidCallback Function(VoidCallback) forThisCard,
  }) {
    final canJudge = _cardRevealed;
    final s = SoriSurfaces.of(context);
    final labelStyle = SoriTextTheme.of(context).label;
    final reserveSkipLabel =
        hasMultipleCards &&
        !compact &&
        MediaQuery.sizeOf(context).width >= SoriBreakpoints.reviewSkipLabel &&
        MediaQuery.textScalerOf(context).scale(1) < 1.4;
    final showSkip = !browsingHistory && canDefer;
    VoidCallback action(bool gotIt) => forThisCard(
      canJudge ? () => _answer(gotIt) : () => _flipHintTrigger.value++,
    );
    final opacity = canJudge ? 1.0 : 0.56;
    return Column(
      key: const ValueKey('review-session-card-actions'),
      children: [
        Row(
          children: [
            if (compact)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: SoriSpeechIndicator(text: card.korean),
              ),
            Expanded(
              child: SoriContentActions(
                onFlip: forThisCard(_toggleFlip),
                onShare: forThisCard(_shareCurrent),
                onBookmark: forThisCard(_saveCurrent),
                bookmarkKey: card.korean,
                flipLabel: t.contentActionFlip,
                shareLabel: t.contentActionShare,
                likeLabel: t.contentActionLike,
                bookmarkLabel: t.deckActionSave,
              ),
            ),
            if (showSkip && !reserveSkipLabel)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: IconButton(
                  key: deckActionKey('skip'),
                  tooltip: t.btnSkip,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: forThisCard(_deferCurrent),
                ),
              ),
          ],
        ),
        // Card geometry must not move when the last card loses Skip or
        // history hides ratings. Keep the same label constraints as the deck.
        Visibility(
          visible: !browsingHistory,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: SoriButton.ghost(
                      key: deckActionKey('dontknow'),
                      label: t.btnNichtGewusst,
                      size: SoriButtonSize.sm,
                      accent: canJudge ? SoriColors.accent : s.textDim,
                      textStyle: labelStyle,
                      onTap: browsingHistory ? null : action(false),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                if (reserveSkipLabel) ...[
                  Expanded(
                    child: Visibility(
                      visible: showSkip,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: SoriButton.ghost(
                        key: deckActionKey('skip'),
                        label: t.btnSkip,
                        size: SoriButtonSize.sm,
                        accent: s.textMuted,
                        textStyle: labelStyle,
                        onTap: showSkip ? forThisCard(_deferCurrent) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: SoriButton.ghost(
                      key: deckActionKey('know'),
                      label: t.btnGewusst,
                      size: SoriButtonSize.sm,
                      accent: canJudge ? SoriColors.contentCta : s.textDim,
                      textStyle: labelStyle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      onTap: browsingHistory ? null : action(true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroCardBody(
    Vocab card,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t, {
    required bool showBack,
    required bool compact,
  }) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: !showBack,
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 52, 12, 8),
      child: LayoutBuilder(
        builder: (context, box) {
          final lang = Localizations.localeOf(context).languageCode;
          final headlineSize = soriUniformFitSize(
            context,
            texts: [for (final v in _deck) v.korean],
            maxWidth: box.maxWidth,
            cap: _sz(box.maxHeight, .155, compact ? 28 : 38, 72),
            min: compact ? 20 : 30,
            fontWeight: FontWeight.w700,
            lineHeight: 1.05,
          );
          final headline = TextStyle(
            fontFamily: SoriFonts.sans,
            fontSize: showBack
                ? _sz(box.maxHeight, .125, 28, 54)
                : headlineSize,
            fontWeight: FontWeight.w700,
            height: 1.1,
          );
          final body = _instructionStyle(context).copyWith(color: s.textMuted);
          final example = tt.h3.copyWith(fontFamily: SoriFonts.sans);
          final note = showBack
              ? CultureNotesService.noteFor(card.korean)
              : null;
          return SoriViewportPages(
            key: ValueKey((card.korean, showBack, _presentation)),
            centerContent: true,
            sections: [
              ..._textSections(
                context,
                box,
                showBack ? card.translationFor(lang) : card.korean,
                headline,
              ),
              if (showBack) ...[
                ..._textSections(context, box, card.exampleKorean, example),
                if (card.exampleKorean.isNotEmpty)
                  Center(
                    child: _SpeakButton(
                      text: card.exampleKorean,
                      label: t.ttsListen,
                    ),
                  ),
                ..._textSections(context, box, card.exampleFor(lang), body),
                if (note != null)
                  if (MediaQuery.textScalerOf(context).scale(1) <= 1.25 &&
                      box.maxHeight >= 360)
                    SizedBox(
                      width: double.infinity,
                      child: CultureNoteCard(korean: card.korean),
                    )
                  else ...[
                    ..._textSections(
                      context,
                      box,
                      t.cultureNoteTitle,
                      tt.label,
                    ),
                    ..._textSections(context, box, note.ko, tt.cultureTitle),
                    ..._textSections(context, box, note.text(lang), body),
                  ],
              ] else ...[
                ..._textSections(context, box, card.romanization, body),
                ..._textSections(
                  context,
                  box,
                  t.hintTapToFlip,
                  tt.caption.copyWith(color: s.textDim),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static double _sz(double h, double frac, double lo, double hi) =>
      (h * frac).clamp(lo, hi).toDouble();
}

/// 발음 듣기 버튼 — 카드 탭(뒤집기)과 분리되도록 InkWell 이 탭을 소비한다.
/// 뒷면 예문은 카드 상단의 단어 재생과 별도로 들을 수 있다.
class _SpeakButton extends StatelessWidget {
  final String text;
  final String label;
  const _SpeakButton({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: SoriColors.primary.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => TtsService.speak(text),
            child: const SizedBox.square(
              dimension: 48,
              child: Icon(
                Icons.volume_up_rounded,
                color: SoriColors.primary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
