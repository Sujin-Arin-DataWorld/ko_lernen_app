import '../services/haptic_service.dart';
import '../services/learning_journey.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../models/feedback_completion.dart';
import '../models/guide_contract.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/confirmed_choice_action.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/stroke_matcher.dart';
import '../widgets/flip_card.dart';
import '../widgets/trace_canvas.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/tts_recorded_jamo.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/c_gallery/c_atelier_materials.dart';
import '../widgets/sori/c_gallery/c_calligraphy_canvas.dart';
import '../widgets/sori/c_gallery/c_calligraphy_ink.dart';
import '../services/hangul_util.dart';
import '../services/tts_service.dart';
import '../services/local_data_lifetime.dart';
import '../services/account/cloud_write_session.dart';
import 'settings_screen.dart' show SettingsInitialFocus;

part 'hangul_atelier.dart';

class HangulScreen extends StatefulWidget {
  const HangulScreen({
    super.key,
    this.initialTarget = HangulTarget.overview,
    this.cardsRandom,
    this.speechPlayer,
    this.textPrefetcher,
  });
  final HangulTarget initialTarget;
  final math.Random? cardsRandom;
  final Future<bool> Function(String text)? speechPlayer;

  /// 음성 미리받기 주입구(테스트용). 미지정이면 [SoriSpeech.prefetch].
  final Future<void> Function(String text)? textPrefetcher;

  @override
  State<HangulScreen> createState() => _HangulScreenState();
}

class _HangulScreenState extends State<HangulScreen>
    with
        SingleTickerProviderStateMixin,
        ScreenCoachMixin<HangulScreen>,
        WidgetsBindingObserver {
  late final TabController _tabs;
  int _tabIndex = 0;
  bool _foreground = true, _settingsOpen = false, _retired = false;
  bool get _enabled => _foreground && !_settingsOpen && !_retired;
  var _writingKey = GlobalKey<_WriteTabState>();
  int _accountEpoch = cloudWriteSessionController.identityEpoch;
  void _accountChanged() {
    final current = cloudWriteSessionController.identityEpoch;
    if (_accountEpoch == current) {
      return;
    }
    _accountEpoch = current;
    _retireLocalSession();
  }

  void _retireLocalSession() {
    _pause();
    if (mounted) {
      setState(() => _retired = true);
    }
  }

  void _pause() {
    _writingKey.currentState?._pause();
    unawaited(SoriSpeech.stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pause();
    }
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  Future<void> _openSettings({bool voice = false}) async {
    if (_settingsOpen) {
      return;
    }
    _pause();
    setState(() => _settingsOpen = true);
    try {
      await Navigator.of(context).pushNamed(
        '/settings',
        arguments: voice ? SettingsInitialFocus.voiceSpeed : null,
      );
    } finally {
      if (mounted) {
        setState(() => _settingsOpen = false);
        if (_retired) {
          setState(() {
            _writingKey = GlobalKey<_WriteTabState>();
            _cardsKey = GlobalKey<_CardsTabState>();
            _retired = false;
          });
        }
        _writingKey.currentState?._refreshPreferences();
      }
    }
  }

  final FeedbackCompletionSlot _cardsCompletion = FeedbackCompletionSlot();
  final FeedbackCompletionSlot _writingCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;

  // ── 코치마크 타겟 ──
  final GlobalKey _tabBarKey = GlobalKey();
  var _cardsKey = GlobalKey<_CardsTabState>();

  @override
  String get coachId => 'hangul';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _tabBarKey,
        title: t.coachHangulTitle,
        body: t.coachHangulBody,
        icon: Icons.tab_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalDataLifetime.changes.addListener(_retireLocalSession);
    cloudWriteSessionController.changes.addListener(_accountChanged);
    _tabIndex = widget.initialTarget.index;
    _tabs = TabController(length: 3, initialIndex: _tabIndex, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index != _tabIndex) {
        _pause();
        setState(() => _tabIndex = _tabs.index);
      }
    });
    scheduleCoach();
    Analytics.lessonStarted(lessonType: 'hangul');
    _abandonTracker = QuestAbandonTracker(
      questType: 'hangul',
      lastStepReached: () => switch (_tabIndex) {
        0 => 'overview',
        1 => 'cards',
        2 => 'write',
        _ => 'unknown',
      },
    );
    _warmJamoAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalDataLifetime.changes.removeListener(_retireLocalSession);
    cloudWriteSessionController.changes.removeListener(_accountChanged);
    _pause();
    _abandonTracker.dispose();
    _tabs.dispose();
    super.dispose();
  }

  /// 프리페치는 **어떤 경우에도 화면을 깨뜨리지 않는다**.
  ///
  /// 구현이 삼키는 것과 별개로 호출 지점에서도 막는다 — 주입된 구현이
  /// 던지면 `unawaited` 된 Future 가 미처리 예외로 새어나온다.
  Future<void> _prefetch(String text) async {
    try {
      await (widget.textPrefetcher?.call(text) ?? SoriSpeech.prefetch(text));
    } catch (_) {
      // 못 받아도 누르면 평소 경로로 재생된다.
    }
  }

  /// 화면에 들어온 순간 낱자 34개 음성을 미리 받아둔다.
  ///
  /// 2026-08-17 테스터(Amor): "카드 음성이 너무 늦게 나온다." 첫 재생은
  /// Storage 다운로드를 기다린 뒤에야 소리가 났다. 고정된 34개짜리 작은
  /// 집합이라 미리 받아두면 이후 탭은 전부 로컬 디스크에서 즉시 난다.
  /// 실패는 무시한다 — 못 받아도 누르면 평소 경로로 재생된다.
  void _warmJamoAudio() {
    final texts = [
      for (final c in [...consonants, ...vowels])
        if (!TtsRecordedJamo.hasLetter(c.letter)) speakableJamo(c.letter),
    ];
    if (widget.textPrefetcher != null) {
      unawaited(Future.wait([for (final t in texts) _prefetch(t)]));
      return;
    }
    unawaited(SoriSpeech.prefetchAll(texts));
  }

  Future<void> _finishCards(int interactionCount) async {
    if (!mounted || !_enabled || interactionCount <= 0) {
      return;
    }
    if (interactionCount > 0) {
      LearningJourneyObserver.beginAttempt()?.complete();
    }
    final t = AppL10n.of(context);
    Analytics.lessonCompleted(lessonType: 'hangul', lessonId: 'cards');
    _abandonTracker.markCompleted();
    final completion = _cardsCompletion.complete(
      () => FeedbackCompletion.hangulCards(
        contentLabel: t.hangulTabCards,
        interactionCount: interactionCount,
      ),
    );
    await _showCompletion(
      completion,
      summary: t.cHangulCardsReceipt(interactionCount),
    );
    _cardsCompletion.reset();
  }

  Future<void> _finishWriting(HangulWritingResult result) async {
    if (!mounted || !_enabled || result.letters <= 0) {
      return;
    }
    if (result.letters > 0) {
      LearningJourneyObserver.beginAttempt()?.complete();
    }
    final t = AppL10n.of(context);
    Analytics.lessonCompleted(lessonType: 'hangul', lessonId: 'writing');
    _abandonTracker.markCompleted();
    final completion = _writingCompletion.complete(
      () => FeedbackCompletion.hangulWriting(
        contentLabel: t.hangulTabWrite,
        letterCount: result.letters,
        strokeCount: result.strokes,
        strict: result.strict,
      ),
    );
    await _showCompletion(
      completion,
      summary: t.cHangulWritingReceipt(
        result.letters,
        result.strokes,
        result.strict ? t.hangulCheckModeExam : t.hangulCheckModePractice,
      ),
      primarySummary: t.cHangulWritingLettersReceipt(result.letters),
      detailSummary: t.cHangulWritingStrokesReceipt(
        result.strokes,
        result.strict ? t.hangulCheckModeExam : t.hangulCheckModePractice,
      ),
      glyphs: result.glyphs,
    );
    _writingCompletion.reset();
  }

  Future<void> _showCompletion(
    FeedbackCompletion completion, {
    required String summary,
    String? primarySummary,
    String? detailSummary,
    List<String> glyphs = const [],
  }) async {
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    _pause();
    await _atelierDialog(context, AppL10n.of(context).cHangulCompleted, (
      sheetContext,
    ) {
      final t = AppL10n.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: const Key('hangul-completion-receipt'),
            label: summary,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Text(
                    primarySummary ?? summary,
                    style: CAtelier.text(context, 23, bold: true),
                    textAlign: TextAlign.center,
                  ),
                  if (detailSummary != null)
                    Text(
                      detailSummary,
                      style: CAtelier.text(context, 14),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          if (glyphs.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final glyph in glyphs.toSet())
                  SizedBox.square(
                    dimension: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CAtelier.art('letter-tile'),
                        Text(
                          glyph,
                          style: CAtelier.text(
                            context,
                            28,
                            korean: true,
                            color: CAtelier.jade,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (feedbackScope != null && feedbackScope.featureGate.isEnabled) ...[
            const SizedBox(height: Spacing.md),
            ContentFeedbackCard(
              feedbackContext: completion.context,
              featureGate: feedbackScope.featureGate,
              submitFeedback: feedbackScope.submitFeedback,
              completedMissionIds: feedbackScope.completedMissionIds,
              mascotKind: null,
            ),
          ],
          const SizedBox(height: Spacing.md),
          CAtelierButton(
            key: const Key('hangul-completion-close'),
            label: t.btnClose,
            face: CAtelierFace.gold,
            onTap: () => Navigator.pop(sheetContext),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.cHangulKeepPractising,
            style: CAtelier.text(context, 14),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  Future<bool> _speakJamo(String letter) {
    final text = speakableJamo(letter);
    return widget.speechPlayer?.call(text) ??
        SoriSpeech.speak(
          text,
          voice: TtsRecordedJamo.hasLetter(letter)
              ? TtsRecordedJamo.voiceTag
              : null,
        );
  }

  Future<bool> _speakSyllable(String syllable) =>
      widget.speechPlayer?.call(syllable) ??
      SoriSpeech.speak(
        syllable,
        voice: TtsRecordedJamo.hasCarrier(syllable)
            ? TtsRecordedJamo.voiceTag
            : null,
      );

  @override
  Widget build(BuildContext context) => _atelierScreen(this, context);
}

class _CardsTab extends StatefulWidget {
  const _CardsTab({
    super.key,
    required this.active,
    required this.onFinish,
    required this.random,
    required this.speak,
    required this.prefetch,
  });
  final bool active;
  final Future<void> Function(int) onFinish;
  final math.Random random;
  final Future<bool> Function(String) speak;
  final Future<void> Function(String) prefetch;
  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _mode = 0; // 0=consonants, 1=vowels, 2=syllables
  int _idx = 0;
  bool _flipped = false;
  int _sessionInteractions = 0;
  final _lifetime = LocalDataLifetime.capture();

  /// 플립 전 판정 시도 → 힌트 칩 펄스 (deck_coach.dart 계약).
  final ValueNotifier<int> _flipHint = ValueNotifier<int>(0);

  /// "다시 볼 글자만" 필터. 좌(모름) 판정이 모은 `Storage.hangulHard` 를
  /// **읽는 유일한 경로**다 — 이게 없으면 좌/우 판정이 write-only 라 아무
  /// 효과가 없다(grammar 의 Schwer 필터와 같은 모양, `grammar_screen.dart:215`).
  bool _hardOnly = false;
  late final ConfirmedChoiceActionOwner _choiceOwner;
  int _likeSourceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _choiceOwner = ConfirmedChoiceActionOwner(
      isCurrentSource: () =>
          mounted &&
          widget.active &&
          (ModalRoute.of(context)?.isCurrent ?? false),
      onConfirmed: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.active) {
        _playCurrentAndPrefetch();
      }
    });
  }

  @override
  void dispose() {
    _choiceOwner.dispose();
    _flipHint.dispose();
    super.dispose();
  }

  /// 지금 카드와 좌우 이웃의 음성을 미리 받아둔다. 스와이프가 빨라질수록
  /// 다음 카드에 도착하는 시점이 앞당겨지므로 이게 더 중요해진다.
  void _prefetchAround() {
    final pool = _pool;
    if (pool.isEmpty) {
      return;
    }
    for (final offset in const [0, 1, -1]) {
      final c = pool[(_idx + offset + pool.length) % pool.length];
      if (!TtsRecordedJamo.hasLetter(c.letter)) {
        unawaited(widget.prefetch(speakableJamo(c.letter)));
      }
      if (c.exampleWord.isNotEmpty) {
        unawaited(widget.prefetch(c.exampleWord));
      }
    }
  }

  List<HangulChar> get _basePool {
    switch (_mode) {
      case 1:
        return vowels;
      case 2:
        return [for (final s in syllables) s.toHangulChar()];
      default:
        return consonants;
    }
  }

  List<HangulChar> get _hardPool {
    final hard = Storage.hangulHard.toSet();
    return _basePool.where((c) => hard.contains(c.letter)).toList();
  }

  List<HangulChar> get _pool {
    final base = _basePool;
    if (!_hardOnly) {
      return base;
    }
    final filtered = _hardPool;
    // 마지막 어려운 글자를 "앎"으로 지우면 덱이 비어 `_pool[_idx % 0]` 이
    // 터진다. 빈 결과는 필터를 없는 셈 치고 전체를 돌려준다 — 다음 build 에서
    // 칩도 자동으로 꺼진 것처럼 보인다.
    return filtered.isEmpty ? base : filtered;
  }

  void _speakCurrent() {
    if (widget.active) {
      unawaited(widget.speak(_pool[_idx % _pool.length].letter));
    }
  }

  /// Publish playback first, then warm the surrounding cards.
  ///
  /// If prefetch wins the in-flight key race, a tap/transition must wait for
  /// that download before it can be promoted to playback. Publishing speech
  /// first gives the visible card priority; its prefetch joins that flight
  /// while the two neighbors continue warming in parallel.
  void _playCurrentAndPrefetch() {
    _speakCurrent();
    _prefetchAround();
  }

  void _toggleHardOnly() {
    HapticService.selectionClick();
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    setState(() {
      _hardOnly = !_hardOnly;
      _idx = 0;
      _flipped = false;
    });
    _playCurrentAndPrefetch();
  }

  /// 우 = 앎. 앱 공용 계약(좌=모름 · 우=앎 · 위=저장 · 아래=넘어가기)의 판정.
  ///
  /// 자모는 어휘가 아니라 **SRS 를 건드리지 않는다** — 문법의 `grammarHard` 와
  /// 같은 SRS 밖 집합(`Storage.hangulHard`)만 쓴다.
  void _known() {
    unawaited(_saveJudgment(true));
  }

  /// 좌 = 모름. 다시 볼 낱자로 표시하고 넘어간다.
  void _dontKnow() {
    unawaited(_saveJudgment(false));
  }

  bool _saving = false;
  Future<void> _saveJudgment(bool known) async {
    if (_saving || !widget.active || !_flipped || _pool.isEmpty) {
      return;
    }
    _saving = true;
    final letter = _pool[_idx % _pool.length].letter;
    final source = _likeSourceGeneration;
    void guard() {
      if (!mounted || !widget.active || source != _likeSourceGeneration) {
        throw const StaleLocalDataLifetimeException();
      }
    }

    try {
      await (known
          ? Storage.markHangulEasy(letter, assertCurrentWrite: guard)
          : Storage.markHangulHard(letter, assertCurrentWrite: guard));
      guard();
      _advance();
    } on StaleLocalDataLifetimeException {
      /* Cancelled source, no new result. */
    } on Object {
      if (mounted) {
        soriToast(context, AppL10n.of(context).atelierSaveFailed);
      }
    } finally {
      _saving = false;
    }
  }

  /// 판정 후 전진 — 햅틱은 커밋 순간 `SoriSwipeCard` 가 방향별로 이미 쳤다.
  void _advance() {
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx + 1) % _pool.length;
    });
    _playCurrentAndPrefetch();
  }

  void _next() {
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    HapticService.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx + 1) % _pool.length;
    });
    _playCurrentAndPrefetch();
  }

  void _prev() {
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    HapticService.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx - 1 + _pool.length) % _pool.length;
    });
    _playCurrentAndPrefetch();
  }

  void _random() {
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    final candidate = widget.random.nextInt(_pool.length);
    if (candidate == _idx) {
      return;
    }
    HapticService.lightImpact();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = candidate;
    });
    _playCurrentAndPrefetch();
  }

  void _onFlip() {
    HapticService.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = !_flipped;
    });
    _speakCurrent();
  }

  Future<void> _likeLetter(
    String letter,
    int sourceGeneration, {
    bool addOnly = false,
  }) async {
    if (sourceGeneration != _likeSourceGeneration ||
        _pool[_idx % _pool.length].letter != letter) {
      return;
    }
    final target = ConfirmedChoiceTarget.liked(
      label: letter,
      kind: LikedContentService.hangul,
      id: letter,
    );
    if (addOnly) {
      await _choiceOwner.set(context, target, true);
    } else {
      await _choiceOwner.toggle(context, target);
    }
  }

  Future<void> _shareCurrent() async {
    final c = _pool[_idx % _pool.length];
    await shareContentStoryWithRecovery(
      context: context,
      korean: c.letter,
      gloss: c.romanization,
    );
  }

  void _setMode(int m) {
    if (_mode == m) {
      return;
    }
    HapticService.selectionClick();
    _likeSourceGeneration++;
    _choiceOwner.replaceSource();
    setState(() {
      _sessionInteractions++;
      _mode = m;
      _idx = 0;
      _flipped = false;
    });
    _playCurrentAndPrefetch();
  }

  Future<void> _showCardModeSheet() async {
    final t = AppL10n.of(context);
    await _atelierDialog(
      context,
      t.cHangulSelectionTitle,
      (dialogContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in [
            (0, t.hangulChipConsonants, consonants.length),
            (1, t.hangulChipVowels, vowels.length),
            (2, t.hangulChipSyllables, syllables.length),
          ]) ...[
            CAtelierButton(
              key: ValueKey('hangul-cards-mode-${item.$1}'),
              label: '${item.$2} (${item.$3})',
              face: _mode == item.$1 ? CAtelierFace.jade : CAtelierFace.paper,
              onTap: () {
                _setMode(item.$1);
                Navigator.pop(dialogContext);
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
          CAtelierButton(
            key: const Key('hangul-cards-hard-only'),
            label: '${t.cHangulHardCharacters} (${_hardPool.length})',
            selected: _hardOnly && _hardPool.isNotEmpty,
            onTap: _hardPool.isEmpty
                ? null
                : () {
                    _toggleHardOnly();
                    Navigator.pop(dialogContext);
                  },
          ),
          const SizedBox(height: Spacing.sm),
          CAtelierButton(
            key: const Key('hangul-cards-random'),
            label: t.atelierRandom,
            onTap: () {
              _random();
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  bool _finishing = false;
  Future<void> _finish() async {
    if (!widget.active ||
        !_lifetime.isCurrent ||
        _sessionInteractions == 0 ||
        _finishing) {
      return;
    }
    _finishing = true;
    try {
      await widget.onFinish(_sessionInteractions);
      if (mounted) {
        setState(() => _sessionInteractions = 0);
      }
    } finally {
      _finishing = false;
    }
  }

  @override
  void didUpdateWidget(covariant _CardsTab old) {
    super.didUpdateWidget(old);
    if (!widget.active) {
      _likeSourceGeneration++;
      _choiceOwner.replaceSource();
    }
    if (widget.active && !old.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) {
          _playCurrentAndPrefetch();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _atelierCards(this, context);
  }
}

typedef HangulWritingResult = ({
  int letters,
  int strokes,
  bool strict,
  List<String> glyphs,
});

class _WriteTab extends StatefulWidget {
  const _WriteTab({
    super.key,
    required this.active,
    required this.onFinish,
    required this.speak,
  });
  final bool active;
  final Future<void> Function(HangulWritingResult) onFinish;
  final Future<bool> Function(String) speak;
  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _mode = 0,
      _idx = 0,
      _strokeCount = 0,
      _acceptedStrokes = 0,
      _completedLetters = 0,
      _demoGeneration = 0,
      _demoStep = 0;
  final List<String> _completedGlyphs = [];
  StrokeAttempt? _lastAttempt;
  bool _letterDone = false,
      _demonstrating = true,
      _toolsOpen = false,
      _finishing = false;
  late bool _strict, _auto;
  final _practiceController = TraceCanvasController();
  final _lifetime = LocalDataLifetime.capture();
  Timer? _errorTimer, _advanceTimer;
  static const _errorFlash = Duration(milliseconds: 450);
  @override
  void initState() {
    super.initState();
    _strict = Storage.hangulStrictStrokes;
    _auto = Storage.hangulAutoAdvance;
  }

  List<HangulChar> get _pool => _mode == 0 ? consonants : vowels;
  HangulChar get _current => _pool[_idx];
  List<Stroke> get _targetStrokes => hangulStrokes[_current.letter]!;
  void _pause() {
    _advanceTimer?.cancel();
    _errorTimer?.cancel();
  }

  @override
  void didUpdateWidget(covariant _WriteTab old) {
    super.didUpdateWidget(old);
    if (!widget.active) {
      _pause();
    }
  }

  void _refreshPreferences() {
    if (!mounted) {
      return;
    }
    // Route returns preserve accepted ink. A changed grading rule starts a new
    // attempt, never silently re-labels an already accepted stroke.
    if (_strict != Storage.hangulStrictStrokes) {
      _strict = Storage.hangulStrictStrokes;
      _resetLetter();
    }
    setState(() => _auto = Storage.hangulAutoAdvance);
  }

  void _speakCurrent() {
    if (widget.active) {
      unawaited(widget.speak(_current.letter));
    }
  }

  void _resetLetter() {
    _pause();
    _practiceController.reset();
    setState(() {
      _acceptedStrokes = 0;
      _lastAttempt = null;
      _letterDone = false;
      _demonstrating = true;
      _demoGeneration++;
      _demoStep = 0;
    });
  }

  void _selectAbsolute(int index) {
    HapticService.selectionClick();
    final i = index.clamp(0, consonants.length + vowels.length - 1);
    setState(() {
      _mode = i < consonants.length ? 0 : 1;
      _idx = _mode == 0 ? i : i - consonants.length;
    });
    _resetLetter();
    _speakCurrent();
  }

  void _next() =>
      _selectAbsolute((_mode == 0 ? _idx : consonants.length + _idx) + 1);
  void _prev() =>
      _selectAbsolute((_mode == 0 ? _idx : consonants.length + _idx) - 1);
  void _clearPractice() => _resetLetter();
  void _restartDemo() {
    if (!widget.active || !_lifetime.isCurrent) {
      return;
    }
    _pause();
    setState(() {
      _demonstrating = true;
      _demoGeneration++;
      _demoStep = 0;
    });
  }

  void _demoComplete() {
    if (mounted) {
      setState(() => _demonstrating = false);
      if (_letterDone) {
        _scheduleAdvance();
      }
    }
  }

  void _demonstrateAction() {
    if (!_demonstrating || !SoriMotion.reduceMotion(context)) {
      _restartDemo();
    } else if (_demoStep < _targetStrokes.length - 1) {
      setState(() => _demoStep++);
    } else {
      _demoComplete();
    }
  }

  bool _preferenceSaving = false;
  void _toggleAuto() => unawaited(_savePreference(auto: !_auto));
  Future<void> _savePreference({bool? auto, bool? strict}) async {
    if (_preferenceSaving || !widget.active || !_lifetime.isCurrent) {
      return;
    }
    _preferenceSaving = true;
    void guard() {
      _lifetime.assertCurrent();
      if (!mounted || !widget.active) {
        throw const StaleLocalDataLifetimeException();
      }
    }

    try {
      if (auto != null) {
        await Storage.setHangulAutoAdvance(auto, assertCurrentWrite: guard);
      }
      if (strict != null) {
        await Storage.setHangulStrictStrokes(strict, assertCurrentWrite: guard);
      }
      guard();
      setState(() {
        if (auto != null) {
          _auto = auto;
        }
        if (strict != null) {
          _strict = strict;
        }
      });
      if (strict != null) {
        _resetLetter();
      }
      _advanceTimer?.cancel();
      if (_auto && _letterDone) {
        _scheduleAdvance();
      }
    } on StaleLocalDataLifetimeException {
      /* Account/reset retired this choice. */
    } on Object {
      if (mounted) {
        soriToast(context, AppL10n.of(context).atelierSaveFailed);
      }
    } finally {
      _preferenceSaving = false;
    }
  }

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    if (!_auto ||
        !widget.active ||
        _toolsOpen ||
        !_lifetime.isCurrent ||
        (_mode == 1 && _idx == vowels.length - 1)) {
      return;
    }
    final letter = _current.letter, generation = _demoGeneration;
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted &&
          widget.active &&
          !_toolsOpen &&
          _auto &&
          _letterDone &&
          _lifetime.isCurrent &&
          (ModalRoute.of(context)?.isCurrent ?? false) &&
          _current.letter == letter &&
          _demoGeneration == generation) {
        _next();
      }
    });
  }

  Future<void> _showLetters() async {
    _pause();
    setState(() => _toolsOpen = true);
    final t = AppL10n.of(context), chars = [...consonants, ...vowels];
    try {
      await _atelierDialog(
        context,
        t.cHangulSelectionTitle,
        (dialogContext) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in chars.indexed)
              SizedBox(
                width: 54,
                child: CAtelierButton(
                  key: ValueKey('hangul-writing-letter-${item.$2.letter}'),
                  label: item.$2.letter,
                  child: Text(
                    item.$2.letter,
                    style: CAtelier.text(context, 24, korean: true),
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _selectAbsolute(item.$1);
                  },
                ),
              ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _toolsOpen = false);
      }
    }
  }

  Future<void> _showWriteSettings() async {
    _pause();
    setState(() => _toolsOpen = true);
    final t = AppL10n.of(context);
    try {
      await _atelierDialog(
        context,
        t.hangulCheckModeLabel,
        (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.hangulRulesBody, style: CAtelier.text(context, 14)),
            const SizedBox(height: Spacing.md),
            for (final item in [
              (true, t.hangulCheckModeExam),
              (false, t.hangulCheckModePractice),
            ]) ...[
              CAtelierButton(
                label: item.$2,
                face: _strict == item.$1
                    ? CAtelierFace.jade
                    : CAtelierFace.paper,
                onTap: () {
                  unawaited(_savePreference(strict: item.$1));
                  Navigator.pop(dialogContext);
                },
              ),
              const SizedBox(height: Spacing.sm),
            ],
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _toolsOpen = false);
      }
    }
  }

  void _onStrokeEnd(TraceCanvasSnapshot snapshot, Size size) {
    if (!widget.active ||
        _toolsOpen ||
        _demonstrating ||
        _letterDone ||
        !_lifetime.isCurrent) {
      return;
    }
    setState(() => _strokeCount++);
    _judgeLastStroke(snapshot, size);
  }

  /// 획을 뗄 때마다 **그 획 하나만** 기대 획과 대조한다.
  ///
  /// 예전에는 그은 획 수가 정답 획 수와 같아지는 순간 한 번만 봤고, 틀리면
  /// 아무 말도 하지 않았다 — 테스터(Amor)가 "일부러 틀려도 인식하지 못하고
  /// 그냥 진행된다" 고 본 그대로다.
  void _judgeLastStroke(TraceCanvasSnapshot snapshot, Size canvasSize) {
    if (_letterDone) {
      return;
    }
    final target = _targetStrokes;
    if (target.isEmpty || snapshot.strokes.isEmpty || canvasSize.isEmpty) {
      return;
    }
    final attempt = evaluateStroke(
      target: target,
      expectedIndex: _acceptedStrokes,
      drawn: snapshot.strokes.last,
      canvasSize: canvasSize,
      // 방향은 획순 검사 모드에서만 본다. ㅡ 를 거꾸로 그어도 남는 모양은
      // 같아서, 연습 모드에서까지 막으면 학습이 아니라 시험이 된다.
      checkDirection: _strict,
    );
    if (attempt.ok) {
      _acceptStroke(target.length);
      return;
    }
    _rejectStroke(attempt);
  }

  void _acceptStroke(int total) {
    _errorTimer?.cancel();
    _practiceController.clearErrorGhost();
    setState(() {
      _acceptedStrokes++;
      _lastAttempt = null;
    });
    if (_acceptedStrokes < total) {
      // 중간 획은 햅틱만 — ㅃ(8획)마다 효과음이 나면 소리가 의미를 잃는다.
      HapticService.selectionClick();
      return;
    }
    _completeLetter();
  }

  void _completeLetter() {
    setState(() {
      _letterDone = true;
      if (!_completedGlyphs.contains(_current.letter)) {
        _completedGlyphs.add(_current.letter);
      }
      _completedLetters = _completedGlyphs.length;
    });
    SoundService.correct();
    _scheduleAdvance();
  }

  void _rejectStroke(StrokeAttempt attempt) {
    setState(() => _lastAttempt = attempt);
    if (!_strict) {
      // 연습 모드: 무엇이 틀렸는지 말해주되 지우거나 막지 않는다.
      return;
    }
    SoundService.wrong();
    // 틀린 획은 **동기적으로** 판정 대상에서 빼고 잔상만 잠깐 남긴다.
    // 타이머가 _strokes 를 건드리지 않으므로, 잔상이 남은 동안 빠르게 다시
    // 그려도 엉뚱한 획이 지워지지 않는다.
    _practiceController.rejectLastStroke();
    _errorTimer?.cancel();
    _errorTimer = Timer(_errorFlash, () {
      if (!mounted) {
        return;
      }
      _practiceController.clearErrorGhost();
    });
  }

  Future<void> _finish() async {
    if (!widget.active ||
        !_lifetime.isCurrent ||
        _completedLetters == 0 ||
        _finishing) {
      return;
    }
    _errorTimer?.cancel();
    _advanceTimer?.cancel();
    _finishing = true;
    try {
      await widget.onFinish((
        letters: _completedLetters,
        strokes: _strokeCount,
        strict: _strict,
        glyphs: List<String>.unmodifiable(_completedGlyphs),
      ));
    } finally {
      _finishing = false;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _completedLetters = 0;
      _strokeCount = 0;
      _completedGlyphs.clear();
    });
    _resetLetter();
  }

  /// 힌트 줄은 **절대 비우지 않는다** — 줄 수가 들쭉날쭉하면 캔버스가 위아래로
  /// 튄다. 픽셀 높이를 고정하는 대신 항상 한 줄을 채우는 쪽을 택했다(글자
  /// 배율이 커져도 안 깨진다).
  String _hintText(AppL10n t) {
    if (_targetStrokes.isEmpty) {
      return '';
    }
    if (_letterDone) {
      return t.hangulStrokeLetterDone(_current.letter);
    }
    final attempt = _lastAttempt;
    if (attempt == null) {
      return t.hangulStrokeNextHint(_acceptedStrokes + 1);
    }
    return switch (attempt.verdict) {
      StrokeVerdict.wrongOrder => t.hangulStrokeWrongOrder(
        (attempt.matchedIndex ?? 0) + 1,
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.wrongDirection => t.hangulStrokeWrongDirection(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.tooShort => t.hangulStrokeTooShort,
      StrokeVerdict.offShape => t.hangulStrokeWrongShape(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.ok => t.hangulStrokeNextHint(_acceptedStrokes + 1),
    };
  }

  Color _hintColor() {
    if (_letterDone) {
      return SoriColors.success;
    }
    if (_lastAttempt != null) {
      return SoriColors.danger;
    }
    return CAtelier.muted;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _atelierWriting(this, context);
  }

  @override
  void dispose() {
    _pause();
    _practiceController.dispose();
    super.dispose();
  }
}
