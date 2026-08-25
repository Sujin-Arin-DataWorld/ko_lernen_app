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
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// A3 — "받아쓰기/스펠링"(Typing). 뜻을 보고 한국어를 직접 입력(인출).
/// 정답/오답은 메인 SRS 에 반영. 인식보다 강한 기억 효과.
class CustomPackTypingScreen extends StatefulWidget {
  final String packId;
  final List<ExtractedWord>? words;
  final ValueChanged<String>? speaker;
  const CustomPackTypingScreen({
    super.key,
    required this.packId,
    this.words,
    this.speaker,
  });

  @override
  State<CustomPackTypingScreen> createState() => _CustomPackTypingScreenState();
}

class _CustomPackTypingScreenState extends State<CustomPackTypingScreen>
    with ScreenCoachMixin<CustomPackTypingScreen> {
  final TextEditingController _input = TextEditingController();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];
  List<int> _order = const [];
  String _languageCode = 'de';
  bool _roundInitialized = false;
  int _idx = 0;
  int _score = 0;
  bool? _correct; // null = 미제출
  GameOutcome? _outcome;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;

  // ── 코치마크 타겟 ──
  final GlobalKey _inputKey = GlobalKey();

  @override
  String get coachId => 'cpTyping';

  @override
  bool get coachReady => _pool.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _inputKey,
        title: t.coachCpTypingTitle,
        body: t.coachCpTypingBody,
        icon: Icons.keyboard_alt_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    Analytics.gameStarted(gameType: 'typing');
    _abandonTracker = QuestAbandonTracker(
      questType: 'typing',
      questId: widget.packId,
      lastStepReached: () => 'word_$_idx',
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
        .where(
          (word) =>
              word.korean.trim().isNotEmpty &&
              word.translationFor(languageCode).trim().isNotEmpty,
        )
        .toList();
    _order = List<int>.generate(_pool.length, (index) => index)
      ..shuffle(math.Random());
    _idx = 0;
    _score = 0;
    _correct = null;
    _outcome = null;
    _feedbackCompletion.reset();
    _input.clear();
  }

  @override
  void dispose() {
    _abandonTracker.dispose();
    _input.dispose();
    super.dispose();
  }

  String _norm(String s) => s.replaceAll(' ', '').trim();

  void _submit() {
    if (_correct != null) {
      return;
    }
    final word = _pool[_order[_idx]];
    final ok = _norm(_input.text) == _norm(word.korean);
    Storage.srsReview(word.korean, gotIt: ok); // A1 연동
    if (!ok) {
      // ignore: discarded_futures
      Storage.incrementWrongCount(word.korean);
    }
    setState(() {
      _correct = ok;
      if (ok) {
        _score++;
      }
    });
    if (ok) {
      SoundService.correct();
    } else {
      SoundService.wrong();
    }
    final speaker = widget.speaker;
    if (speaker != null) {
      speaker(word.korean);
    } else {
      TtsService.speak(word.korean);
    }
  }

  void _next() {
    setState(() {
      _idx++;
      _correct = null;
      _input.clear();
    });
    if (_idx >= _order.length) {
      _finish();
    }
  }

  void _restart() {
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _startRoundForLocale(languageCode);
    });
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.customPackTyping(
        packId: widget.packId,
        correct: _score,
        total: _order.length,
      ),
    );
    final pct = ((_score / _order.length) * 100).round();
    final outcome = await recordGameResult(
      gameId: 'cp_typing',
      xp: _score * 5,
      score: pct,
    );
    await Analytics.gameCompleted(
      gameType: 'typing',
      result: pct >= 60 ? 'win' : 'lose',
      score: pct,
    );
    _abandonTracker.markCompleted();
    if (mounted) {
      setState(() => _outcome = outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return SoriStudyFrame(
        title: t.wbTyping,
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
    if (_pool.isEmpty) {
      return SoriStudyFrame(
        title: t.wbTyping,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.keyboard_alt_outlined,
            title: t.wbTyping,
            body: t.wbTypingNeedMore,
          ),
        ),
      );
    }
    if (_idx >= _order.length) {
      return _buildDone(t);
    }

    final tt = SoriTextTheme.of(context);
    final word = _pool[_order[_idx]];
    final revealed = _correct != null;

    return SoriStudyFrame(
      title: t.wbTyping,
      leading: IconButton(
        tooltip: t.btnClose,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      child: SoriAdaptiveStudyBody(
        minHeight: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                SoriChip(
                  label: '${_idx + 1} / ${_order.length}',
                  accent: SoriColors.info,
                ),
                SoriChip(
                  label: t.quizScore(_score, _order.length),
                  accent: SoriColors.success,
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            SoriCard(
              variant: SoriCardVariant.hero,
              accent: SoriColors.accent,
              tinted: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                child: Text(
                  word.translationFor(_languageCode),
                  textAlign: TextAlign.center,
                  style: tt.h1,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Semantics(
              key: const ValueKey('custom-typing-field-state'),
              enabled: !revealed,
              child: SoriTextField(
                fieldKey: _inputKey,
                controller: _input,
                autofocus: true,
                enabled: !revealed,
                textAlign: TextAlign.center,
                style: tt.h2,
                labelText: t.wbTypingPrompt,
                hintText: t.wbTypingHint,
                onSubmitted: (_) => _submit(),
              ),
            ),
            if (revealed) ...[
              const SizedBox(height: Spacing.sm),
              Semantics(
                key: const ValueKey('custom-typing-feedback'),
                liveRegion: true,
                label: _correct!
                    ? t.statsCorrect
                    : '${t.statsWrong}. ${t.wbTypingAnswer(word.korean)}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _correct!
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _correct! ? SoriColors.success : SoriColors.danger,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Flexible(
                      child: Text(
                        _correct!
                            ? t.statsCorrect
                            : t.wbTypingAnswer(word.korean),
                        textAlign: TextAlign.center,
                        style: tt.h3.copyWith(
                          color: _correct!
                              ? SoriColors.primaryOnLight
                              : SoriColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            SoriButton(
              label: revealed ? t.btnNext : t.btnSubmit,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.accent,
              fullWidth: true,
              onTap: revealed ? _next : _submit,
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
          xpGained: _score * 5,
          isNewBest: _outcome?.isNewBest ?? false,
          newBestLabel: t.gameNewBest,
          bestLabel: t.gameBestAccuracy(Storage.gameBest('cp_typing')),
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
