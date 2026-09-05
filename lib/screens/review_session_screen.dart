import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

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
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/deck_coach.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../services/liked_content_service.dart';
import '../widgets/app_error.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/scroll_if_needed.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

String? unambiguousReviewLevel(Iterable<String> deckLevels) {
  const supported = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  final levels = deckLevels.map((level) => level.trim().toUpperCase()).toSet();
  if (levels.length != 1 || !supported.contains(levels.single)) return null;
  return levels.single;
}

typedef ReviewableLoader = Future<List<Vocab>> Function();

enum ReviewLoadState { loading, ready, empty, error }

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
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  final _speech = ContentSpeechController();

  bool get _loading => _loadState == ReviewLoadState.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) _speech.subscribe(route);
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
  bool get coachReady => !_loading && _queue?.current != null && !_done;

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
    _load().then((_) {
      if (mounted && _queue?.current != null) {
        _speech.playOnEnter(_card.korean);
      }
    });
    scheduleCoach();
    // K-Culture 노트 로드 후 카드 반영.
    unawaited(_loadCultureNotes());
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
    _speech.dispose();
    _flipHintTrigger.dispose();
    super.dispose();
  }

  void _saveCurrent() {
    if (_loading || _done || _queue?.current == null) {
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
    if (_loading || _done || _queue?.current == null) {
      return;
    }
    await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: _card.korean,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareCurrent() async {
    if (_loading || _done || _queue?.current == null) {
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
    if (_loading || _done || queue == null || !queue.canDefer) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      queue.defer();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _showPrevious() {
    final queue = _queue;
    if (queue == null || !queue.canGoPrevious) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      queue.previous();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _showNextHistory() {
    final queue = _queue;
    if (queue == null || !queue.canGoForward) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      queue.nextHistory();
      _flipped = false;
      _cardRevealed = false;
    });
    _speech.playOnEnter(_card.korean);
  }

  void _toggleFlip() {
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

  void _answer(bool gotIt) {
    final queue = _queue;
    if (queue == null || !queue.canJudgeCurrent) {
      return;
    }
    final card = _card;
    final shouldRecordEvidence = queue.currentNeedsEvidence;

    // 답변 순간 촉각 피드백 — 맞으면 강하게, 틀리면 가볍게.
    gotIt ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    if (shouldRecordEvidence) {
      // ignore: discarded_futures
      Storage.srsReview(card.korean, gotIt: gotIt);
    }
    if (!gotIt) {
      // ignore: discarded_futures
      Storage.incrementWrongCount(card.korean);
    }
    if (shouldRecordEvidence) {
      _reviewed++;
    }
    queue.recordJudgment(correct: gotIt);

    if (queue.isComplete) {
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
      Storage.addXp(_reviewed * 2);
      setState(() => _done = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SoriCelebration.burst(context);
      });
    } else {
      setState(() {
        _flipped = false;
        _cardRevealed = false;
      });
      _speech.playOnEnter(_card.korean);
      final next = queue.peekNext;
      _speech.prefetchNeighbors([if (next != null) next.korean]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return SoriStudyFrame(
      title: widget.title ?? t.reviewTitle,
      homeEscape: SoriHomeEscape(confirmWhen: !_done && _reviewed > 0),
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
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
        ReviewLoadState.error => AppError(
          message: t.loadErrorTryAgain,
          onRetry: _load,
          messageLiveRegion: true,
        ),
        ReviewLoadState.empty => _buildEmpty(t),
        ReviewLoadState.ready => _done ? _buildDone(t, s) : _buildCard(t, s),
      },
    );
  }

  Widget _buildEmpty(AppL10n t) => SoriEmptyState(
    asset: 'assets/illustrations/mascot/magpie_celebrate.png',
    icon: Icons.celebration_rounded,
    title: t.reviewEmptyTitle,
    body: t.reviewEmptyBody,
    ctaLabel: t.btnClose,
    onCta: () => Navigator.of(context).maybePop(),
  );

  Widget _buildDone(AppL10n t, SoriSurfaces s) {
    final tt = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    // 세로 중앙 정렬 — 예전엔 콘텐츠가 상단에 뭉치고 화면 아래 절반이 통째로
    // 비어서, 축하 문구와 Schließen 이 호랑이 바로 밑에 달라붙은 덩어리로
    // 보였다(Jin 2026-08-12 "완성도 떨어져"). 콘텐츠가 화면보다 길어지면
    // SingleChildScrollView 가 그대로 받아 스크롤한다 — 오버플로 계약 유지.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 세션 완료 = 기지개 클립 (배치 계획 §2-11). 폴백은 기존 celebrate.
                CompanionBuilder(
                  builder: (context, kind) => CharacterClipPlayer(
                    asset: CharacterClips.sessionCompleteFor(kind),
                    size: 120,
                    // The screen uses the HanjiTexture base wash behind the clip.
                    blendColor: SoriColors.lightBg,
                    fallbackKind: kind,
                    fallbackEmotion: MascotEmotion.celebrate,
                  ),
                  noneBuilder: (context) => const Icon(
                    Icons.celebration_rounded,
                    size: 104,
                    color: SoriColors.success,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  t.reviewDoneTitle,
                  textAlign: TextAlign.center,
                  style: tt.h1,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.reviewDoneBody,
                  textAlign: TextAlign.center,
                  style: tt.body.copyWith(color: s.textMuted),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  '+${_reviewed * 2} XP',
                  // 황은 XP·스트릭 전용이다. 여기는 실제 XP 라 유지한다 —
                  // 카드 위 장식 금색과는 다른 이야기.
                  style: tt.h2.copyWith(color: SoriColors.gold),
                ),
                // M5: "한마디" — interessen-passender Small-talk-Satz als Bonus.
                if (widget.bonusPhrase != null) ...[
                  const SizedBox(height: Spacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: SoriColors.highlight.withValues(alpha: 0.10),
                      borderRadius: SoriRadius.brMd,
                    ),
                    child: Column(
                      children: [
                        Text(
                          t.reviewBonusLabel,
                          style: tt.label.copyWith(color: SoriColors.highlight),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.bonusPhrase!.ko,
                          textAlign: TextAlign.center,
                          style: tt.h3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bonusPhrase!.translation(
                            Localizations.localeOf(context).languageCode,
                          ),
                          textAlign: TextAlign.center,
                          style: tt.bodySmall.copyWith(color: s.textMuted),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => TtsService.speak(widget.bonusPhrase!.ko),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: SoriColors.highlight,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_feedbackCompletion.current != null &&
                    feedbackScope != null &&
                    feedbackScope.featureGate.isEnabled) ...[
                  const SizedBox(height: Spacing.xl),
                  ContentFeedbackCard(
                    feedbackContext: _feedbackCompletion.current!.context,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                    completedMissionIds: feedbackScope.completedMissionIds,
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                SoriButton.filled(
                  label: t.btnClose,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AppL10n t, SoriSurfaces s) {
    final queue = _queue!;
    final card = _card;
    final total = queue.originalCount;
    final browsingHistory = queue.isBrowsingHistory;
    final tt = SoriTextTheme.of(context);

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
            padding: const EdgeInsets.all(Spacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 카드 크기는 **글자 수와 완전히 무관하게** 기기 화면에만 맞춰
                // 고정한다:
                //  · 높이 = 가용 영역의 82% (짧은 단어여도 쪼그라들지 않음, 남는
                //    상하 여백이 코치마크 말풍선·버튼 공간).
                //  · 너비 = 가용 너비 가득(`width: double.infinity`). ⚠️ 이 너비
                //    고정이 없으면 SoriCard 가 세로 스크롤 자식의 콘텐츠 폭에
                //    맞춰 줄어들어(SingleChildScrollView 는 가로 제약을 그대로
                //    통과시킴) "단어 길이에 따라 카드가 커졌다 작아졌다" 하는
                //    회귀가 재발한다. 절대 지우지 말 것.
                // 가용 폭 자체는 SoriCenterClamp 이 기기별로 최적 클램프하므로
                // 기기 최적화 + 콘텐츠 불변이 동시에 성립한다.
                final h = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 360.0;
                final cardH = h * 0.82;
                final next = queue.peekNext;
                return Semantics(
                  container: true,
                  customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                    if (queue.canGoPrevious)
                      CustomSemanticsAction(label: t.legacyVocabPrevious):
                          _showPrevious,
                    if (queue.canGoForward)
                      CustomSemanticsAction(label: t.btnNext): _showNextHistory,
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
                        : () => _flipHintTrigger.value++,
                    flipHintTrigger: _flipHintTrigger,
                    onNext: browsingHistory
                        ? _showNextHistory
                        : () => _answer(true),
                    // In history mode this remains non-null at the oldest
                    // card. SoriContentFeed otherwise falls a downward fling
                    // through to onNext and moves in the wrong direction.
                    onPrevious: browsingHistory || queue.canGoPrevious
                        ? _showPrevious
                        : null,
                    onHard: browsingHistory ? null : () => _answer(false),
                    onSkip: !browsingHistory && queue.canDefer
                        ? _deferCurrent
                        : null,
                    skipEnabled: !browsingHistory && queue.canDefer,
                    onLike: _likeCurrent,
                    onBookmark: _saveCurrent,
                    bookmarkKey: _card.korean,
                    topAccessory: SoriSpeechIndicator(text: _card.korean),
                    onShare: _shareCurrent,
                    onFlip: _toggleFlip,
                    liked: LikedContentService.isLiked(
                      kind: LikedContentService.vocab,
                      id: card.korean,
                    ),
                    underlay: next == null
                        ? null
                        : SizedBox(
                            width: double.infinity,
                            height: cardH,
                            child: _heroCardBody(
                              next,
                              s,
                              tt,
                              t,
                              showBack: false,
                            ),
                          ),
                    knowLabel: browsingHistory ? null : t.btnGewusst,
                    hardLabel: browsingHistory ? null : t.btnNichtGewusst,
                    skipLabel: browsingHistory ? null : t.btnSkip,
                    bookmarkLabel: t.deckActionSave,
                    child: SoriPressable(
                      key: _cardKey,
                      onTap: _toggleFlip,
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
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }

  /// 히어로 카드 본문 — 본 카드와 덱 스택 underlay(다음 카드 앞면)가 공유.
  /// P1 의 덱 공유 균일 헤드라인 계산을 포함해 **본문 그대로** 추출했다.
  Widget _heroCardBody(
    Vocab card,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t, {
    required bool showBack,
  }) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: !showBack,
      child: LayoutBuilder(
        builder: (context, cc) {
          // 카드 안쪽 높이를 폰트·간격의 기준으로 삼는다 → 텍스트가 카드
          // 크기에 비례해 커지고(기기 무관 균일 충전율) 세로는 spaceEvenly 로
          // 카드를 채운다. 콘텐츠가 카드보다 커지는 드문 경우엔
          // SingleChildScrollView 가 스크롤로 받아낸다(기존 계약 유지).
          final ch = cc.maxHeight.isFinite ? cc.maxHeight : 360.0;
          // P1-2 (2026-08-14, 의도된 시각 변화): 제시어 크기를 per-word
          // FittedBox 단독에서 **덱 공유 균일값**으로 — 단어마다 글자 크기가
          // 튀지 않는다 (custom_pack_play 선례 복제). FittedBox 는 실측
          // 오차용 안전망으로만 남는다.
          final headlineSize = soriUniformFitSize(
            context,
            texts: [for (final v in _deck) v.korean],
            maxWidth: cc.maxWidth,
            cap: _sz(ch, 0.155, 38, 72),
            min: 30,
            fontWeight: FontWeight.w700,
            lineHeight: 1.05,
          );
          return SingleChildScrollView(
            physics: kSoriCardFacePhysics,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cc.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: showBack
                    ? _backList(card, s, tt, t, ch)
                    : _frontList(card, s, tt, t, ch, headlineSize),
              ),
            ),
          );
        },
      ),
    );
  }

  // 카드 안쪽 높이 [h] 에 비례한 폰트/간격 크기 — 짧은 값(lo)과 큰 화면 상한(hi)
  // 사이로 클램프. 카드가 커질수록 텍스트도 커져 충전율이 기기와 무관하게 유지된다.
  static double _sz(double h, double frac, double lo, double hi) =>
      (h * frac).clamp(lo, hi).toDouble();

  List<Widget> _frontList(
    Vocab v,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t,
    double h,
    double headlineSize,
  ) => [
    // 단어 — 카드를 채우는 대형 헤드라인. 크기는 덱 공유값([headlineSize],
    // soriUniformFitSize) 하나 — 단어 길이에 따라 카드마다 요동치지 않는다
    // (P1-2, 2026-08-14). FittedBox 는 실측 오차용 안전망일 뿐 정상 경로에서는
    // 개입하지 않는다.
    //
    // 앞/뒷면 크기비는 **의도적으로 1.3 배 안쪽**으로 묶는다. 예전엔 앞면
    // 0.19(최대 92sp) 대 뒷면 0.11(최대 48sp) = 1.7 배라, 짧은 한국어 단어는
    // 카드를 꽉 채우고 뒤집으면 독일어가 갑자기 작아져 같은 카드로 안 보였다
    // (Jin 2026-08-12 "한국어카드일때 글씨 너무 크고 독일어일때 너무 좀…").
    // 한글은 같은 sp 에서 라틴보다 작게 보이므로 1:1 이 아니라 1.3 배로 둔다.
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        v.korean,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: SoriFonts.sans,
          fontSize: headlineSize,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
    ),
    // 듣기 버튼 + 로마자를 한 묶음으로(발음 정보끼리 붙어 있게).
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpeakButton(
          text: v.korean,
          label: t.ttsListen,
          size: _sz(h, 0.10, 30, 60),
        ),
        if (v.romanization.isNotEmpty) ...[
          SizedBox(height: _sz(h, 0.03, 8, 20)),
          Text(
            v.romanization,
            textAlign: TextAlign.center,
            style: tt.body.copyWith(
              color: s.textMuted,
              fontSize: _sz(h, 0.052, 16, 30),
            ),
          ),
        ],
      ],
    ),
    Text(
      t.hintTapToFlip,
      textAlign: TextAlign.center,
      style: tt.caption.copyWith(
        color: s.textDim,
        fontSize: _sz(h, 0.038, 13, 22),
      ),
    ),
  ];

  List<Widget> _backList(
    Vocab v,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t,
    double h,
  ) {
    final lang = Localizations.localeOf(context).languageCode;
    return [
      // 뜻 (헤드라인) — 긴 독일어(예: "Entschuldigung (formell)")가 큰 폰트로
      // 3줄 폭주하지 않도록 FittedBox 로 한 줄에 맞춰 축소한다.
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          v.translationFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: SoriFonts.sans,
            // 앞면(0.155)의 약 0.8 배 — 위 주석의 1.3 배 계약.
            fontSize: _sz(h, 0.125, 28, 54),
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
      // 예문(한국어 + 듣기 + 번역)을 한 묶음으로 → spaceEvenly 가 흩뜨리지 않는다.
      if (v.exampleKorean.isNotEmpty)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _noIntraWordBreak(v.exampleKorean),
              textAlign: TextAlign.center,
              // 두 줄까지 허용한다. 카드 아래 여백이 넉넉한데 예문만 잘리거나
              // 쪼그라들 이유가 없다(Jin, 2026-08-12).
              maxLines: 2,
              style: TextStyle(
                fontFamily: SoriFonts.sans,
                fontSize: _sz(h, 0.068, 20, 34),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            SizedBox(height: _sz(h, 0.03, 8, 20)),
            _SpeakButton(
              text: v.exampleKorean,
              label: t.ttsListen,
              size: _sz(h, 0.075, 24, 48),
            ),
            if (v.exampleFor(lang).isNotEmpty) ...[
              SizedBox(height: _sz(h, 0.04, 12, 24)),
              Text(
                v.exampleFor(lang),
                textAlign: TextAlign.center,
                style: tt.bodySmall.copyWith(
                  color: s.textMuted,
                  fontSize: _sz(h, 0.055, 16, 30),
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      // K-Culture 노트 — 노트가 있을 때만 슬롯을 만든다. 없는데도 SizedBox.shrink
      // 를 spaceEvenly 슬롯으로 두면 콘텐츠가 위로 쏠리고 아래가 비어 답답해진다.
      if (CultureNotesService.noteFor(v.korean) != null)
        SizedBox(
          width: double.infinity,
          child: CultureNoteCard(korean: v.korean),
        ),
    ];
  }
}

/// 발음 듣기 버튼 — 카드 탭(뒤집기)과 분리되도록 InkWell 이 탭을 소비한다.
/// 앞면(단어)·뒷면(예문) 양쪽에서 재사용.
class _SpeakButton extends StatelessWidget {
  final String text;
  final String label;
  final double size;
  const _SpeakButton({required this.text, required this.label, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: SoriColors.primary.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => TtsService.speak(text),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// 어절 **안에서는** 줄이 바뀌지 않게 낱글자 사이에 U+2060(WORD JOINER)을 넣는다.
///
/// Flutter 는 한국어를 CJK 로 보고 글자 사이 아무 데서나 줄을 바꾼다. 그래서
/// "안녕하세요, 처음 뵙겠습니다." 가 "안녕하세요, 처음 뵙겠습" / "니다." 처럼
/// 어절 한복판에서 끊겼다(Jin, 2026-08-12 Heute wiederholen). 공백으로 나뉜
/// 어절 안쪽만 묶어 주면 줄바꿈은 어절 경계에서만 일어난다.
///
/// U+2060 은 폭이 0이고 글리프가 없어 화면에 영향이 없다. 붙이는 대상은 화면에
/// 그릴 문자열뿐이고, TTS·채점·저장에 쓰는 원본에는 절대 넣지 않는다 — 해시가
/// 달라져 음성 캐시가 통째로 어긋난다.
String _noIntraWordBreak(String text) =>
    text.split(' ').map((word) => word.split('').join('⁠')).join(' ');
