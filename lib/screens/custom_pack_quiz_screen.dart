import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

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
    with ScreenCoachMixin<CustomPackQuizScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];
  List<int> _order = const [];
  int _qIdx = 0;
  int _score = 0;
  List<String> _options = const [];
  String? _picked; // 선택한 답 (null = 미선택)
  GameOutcome? _outcome;
  String _languageCode = 'de';
  bool _roundInitialized = false;
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
    _order = List<int>.generate(_pool.length, (index) => index)..shuffle(_rng);
    _qIdx = 0;
    _score = 0;
    _outcome = null;
    _feedbackCompletion.reset();
    if (_pool.length >= 4) {
      _buildOptions();
    }
  }

  void _buildOptions() {
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

  void _pick(String option) {
    if (_picked != null) {
      return;
    }
    final word = _pool[_order[_qIdx]];
    final correct = word.translationFor(_languageCode).trim();
    final isRight = option == correct;
    setState(() => _picked = option);
    // A1: 노출 기록(책장 타일 "n von m gelernt" 소스) + 퀴즈 결과를 SRS 에 반영.
    Storage.addVokSeen(word.korean);
    Storage.srsReview(word.korean, gotIt: isRight);
    if (isRight) {
      _score++;
      HapticFeedback.lightImpact();
      SoundService.correct();
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      // ignore: discarded_futures
      Storage.incrementWrongCount(word.korean);
    }
    if (SoriMotion.reduceMotion(context)) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      _advance();
    });
  }

  void _advance() {
    if (_picked == null || _qIdx >= _order.length) {
      return;
    }
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
    _feedbackCompletion.complete(
      () => FeedbackCompletion.customPackQuiz(
        packId: widget.packId,
        correct: _score,
        total: _order.length,
      ),
    );
    final pct = ((_score / _order.length) * 100).round();
    final outcome = await recordGameResult(
      gameId: 'cp_quiz',
      xp: _score * 4,
      score: pct,
    );
    if (mounted) {
      setState(() => _outcome = outcome);
    }
  }

  void _restart() {
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _startRoundForLocale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return SoriStudyFrame(
        title: t.wbQuiz,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_front.png',
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }

    if (_pool.length < 4) {
      return SoriStudyFrame(
        title: t.wbQuiz,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
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

    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    final reduceMotion = SoriMotion.reduceMotion(context);
    final word = _pool[_order[_qIdx]];
    final correct = word.translationFor(_languageCode).trim();

    return SoriStudyFrame(
      title: t.wbQuiz,
      leading: IconButton(
        tooltip: t.btnClose,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      child: SoriAdaptiveStudyBody(
        minHeight: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                SoriChip(
                  label: '${_qIdx + 1} / ${_order.length}',
                  accent: SoriColors.accent,
                ),
                SoriChip(
                  label: t.quizScore(_score, _order.length),
                  accent: SoriColors.success,
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              t.quizQuestion,
              style: tt.caption.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.sm),
            SoriCard(
              variant: SoriCardVariant.hero,
              accent: SoriColors.primary,
              tinted: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                child: Column(
                  children: [
                    if (word.imagePath.isNotEmpty) ...[
                      ManagedMediaImage(
                        reference: word.imagePath,
                        width: 220,
                        height: 110,
                        borderRadius: BorderRadius.circular(SoriRadius.md),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                    Text(
                      word.korean,
                      textAlign: TextAlign.center,
                      style: tt.display,
                    ),
                    const SizedBox(height: Spacing.sm),
                    IconButton(
                      tooltip: t.ttsListenTarget(word.korean),
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 26),
                      onPressed: () => TtsService.speak(word.korean),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            if (_picked != null) ...[
              Semantics(
                key: const ValueKey('custom-quiz-feedback'),
                liveRegion: true,
                label: _picked == correct ? t.statsCorrect : t.statsWrong,
                child: Text(
                  _picked == correct ? t.statsCorrect : t.statsWrong,
                  textAlign: TextAlign.center,
                  style: tt.h3.copyWith(
                    color: _picked == correct
                        ? SoriColors.primaryOnLight
                        : SoriColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            // Four choices can exceed a short device viewport once the
            // prompt card is present. Keep the learning prompt visible
            // and make only the answer list scroll, rather than letting
            // the whole result route overflow below the fold.
            Expanded(
              child: SingleChildScrollView(
                child: KeyedSubtree(
                  key: _optionsKey,
                  child: Column(
                    children: [
                      for (final option in _options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: QuizChoice(
                            text: option,
                            isCorrect: option == correct,
                            isSelected: _picked == option,
                            revealed: _picked != null,
                            minHeight: 56,
                            idleBorderColor: SoriColors.primary,
                            semanticTapEnabled: true,
                            onSelected: _picked == null
                                ? () => _pick(option)
                                : null,
                          ),
                        ),
                      if (_picked != null && reduceMotion)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: SoriButton(
                            label: t.btnNext,
                            icon: Icons.arrow_forward_rounded,
                            variant: SoriButtonVariant.filled,
                            accent: SoriColors.accent,
                            fullWidth: true,
                            onTap: _advance,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = ((_score / _order.length) * 100).round();
    return SoriStudyFrame(
      title: t.quizResultTitle,
      automaticallyImplyLeading: false,
      padding: EdgeInsets.zero,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: '${t.quizResultTitle}. ${t.quizScore(_score, _order.length)}',
        child: GameOverCard(
          headline: t.quizResultTitle,
          scoreLabel: t.quizScore(_score, _order.length),
          feedbackContext: _feedbackCompletion.current?.context,
          xpGained: _score * 4,
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
              onTap: _restart,
            ),
            SoriButton(
              label: t.customPackResultBack,
              icon: Icons.menu_book_outlined,
              variant: SoriButtonVariant.outlined,
              fullWidth: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
