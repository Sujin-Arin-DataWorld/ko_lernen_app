import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../models/feedback_completion.dart';
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
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// A3 — "받아쓰기/스펠링"(Typing). 뜻을 보고 한국어를 직접 입력(인출).
/// 정답/오답은 메인 SRS 에 반영. 인식보다 강한 기억 효과.
class CustomPackTypingScreen extends StatefulWidget {
  final String packId;
  const CustomPackTypingScreen({super.key, required this.packId});

  @override
  State<CustomPackTypingScreen> createState() => _CustomPackTypingScreenState();
}

class _CustomPackTypingScreenState extends State<CustomPackTypingScreen>
    with ScreenCoachMixin<CustomPackTypingScreen> {
  final TextEditingController _input = TextEditingController();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];
  List<int> _order = const [];
  int _idx = 0;
  int _score = 0;
  bool? _correct; // null = 미제출
  GameOutcome? _outcome;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

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
    final pack = CustomPackService.getById(widget.packId);
    _pack = pack;
    if (pack != null) {
      _pool = pack.words
          .where(
            (w) =>
                w.korean.trim().isNotEmpty && w.translationDe.trim().isNotEmpty,
          )
          .toList();
      _order = List<int>.generate(_pool.length, (i) => i)
        ..shuffle(math.Random());
    }
    scheduleCoach();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _norm(String s) => s.replaceAll(' ', '').trim();

  void _submit() {
    if (_correct != null) return;
    final word = _pool[_order[_idx]];
    final ok = _norm(_input.text) == _norm(word.korean);
    Storage.srsReview(word.korean, gotIt: ok); // A1 연동
    setState(() {
      _correct = ok;
      if (ok) _score++;
    });
    if (ok) {
      SoundService.correct();
    } else {
      SoundService.wrong();
    }
    TtsService.speak(word.korean);
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
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbTyping)),
        body: Center(
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
      return Scaffold(
        appBar: AppBar(title: Text(t.wbTyping)),
        body: Center(
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

    final s = SoriSurfaces.of(context);
    final word = _pool[_order[_idx]];
    final revealed = _correct != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.wbTyping,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SoriChip(
                      label: '${_idx + 1} / ${_order.length}',
                      accent: SoriColors.info,
                    ),
                    const Spacer(),
                    SoriChip(
                      label: t.quizScore(_score, _order.length),
                      accent: SoriColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  t.wbTypingPrompt,
                  style: TextStyle(fontSize: 13, color: s.textMuted),
                ),
                const SizedBox(height: Spacing.sm),
                SoriCard(
                  variant: SoriCardVariant.hero,
                  accent: SoriColors.accent,
                  tinted: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                    child: Text(
                      word.translationDe,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                TextField(
                  key: _inputKey,
                  controller: _input,
                  autofocus: true,
                  enabled: !revealed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: t.wbTypingHint,
                    border: const OutlineInputBorder(),
                    enabledBorder: revealed
                        ? OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _correct!
                                  ? SoriColors.success
                                  : SoriColors.danger,
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (revealed && !_correct!) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    t.wbTypingAnswer(word.korean),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SoriColors.danger,
                    ),
                  ),
                ],
                if (revealed && _correct!) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '✓',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, color: SoriColors.success),
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
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = ((_score / _order.length) * 100).round();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.quizResultTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
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
                onTap: () => setState(() {
                  _order = List<int>.generate(_pool.length, (i) => i)
                    ..shuffle(math.Random());
                  _idx = 0;
                  _score = 0;
                  _correct = null;
                  _outcome = null;
                  _feedbackCompletion.reset();
                  _input.clear();
                }),
              ),
              SoriButton(
                label: t.customPackResultBack,
                icon: Icons.menu_book_outlined,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
