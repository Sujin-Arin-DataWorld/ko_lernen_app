import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../models/vocab_pack.dart';
import '../services/sound_service.dart';
import '../services/pack_session_srs_ledger.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_pack_service.dart';
import '../services/vocab_recall_evidence.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// Optional, direct Korean typing practice for a current pack's Boss words.
///
/// This comes after the Pack result and never changes clear, unlock, stamp, or
/// XP behaviour. Boss remains the pack's four-choice recognition assessment;
/// this surface adds a separate, stronger typed-recall opportunity. A valid
/// current-pack session is supplied by the result route so reopen attempts
/// share the same ephemeral SRS evidence ledger. Missing or mismatched route
/// state remains useful practice but intentionally writes no learning data.
class VocabPackRecallScreen extends StatefulWidget {
  final String packId;
  final Future<VocabPack?> Function(String packId)? packLoader;
  final math.Random? orderRng;
  final PackRecallSession? recallSession;

  const VocabPackRecallScreen({
    super.key,
    required this.packId,
    this.packLoader,
    this.orderRng,
    this.recallSession,
  });

  @override
  State<VocabPackRecallScreen> createState() => _VocabPackRecallScreenState();
}

enum _RecallFeedback { correct, correctWithHint, incorrect, revealed }

class _VocabPackRecallScreenState extends State<VocabPackRecallScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool _loading = true;
  String? _error;
  List<Vocab> _words = const [];
  int _index = 0;
  int _directCorrect = 0;
  bool _hintUsed = false;
  bool _done = false;
  _RecallFeedback? _feedback;
  final Set<String> _missedWordIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final providedLoader = widget.packLoader;
      final pack = providedLoader != null
          ? await providedLoader(widget.packId)
          : await VocabPackService.findById(widget.packId);
      if (!mounted) {
        return;
      }
      if (pack == null) {
        setState(() {
          _loading = false;
          _error = AppL10n.of(context).loadErrorTryAgain;
        });
        return;
      }
      setState(() {
        _words = shuffledVocabRecallWords(
          pack.bossWords,
          rng: widget.orderRng ?? math.Random(),
        );
        _index = 0;
        _directCorrect = 0;
        _hintUsed = false;
        _feedback = null;
        _done = false;
        _missedWordIds.clear();
        _loading = false;
      });
      _focusInput();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  Vocab get _current => _words[_index];

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _feedback == null && !_done) {
        _inputFocus.requestFocus();
      }
    });
  }

  Future<void> _submit() async {
    if (_feedback != null || _input.text.trim().isEmpty) {
      return;
    }
    final word = _current;
    final grade = gradeVocabRecallAnswer(
      submitted: _input.text,
      expected: word.korean,
      usedHint: _hintUsed,
    );
    setState(() {
      if (grade.isCorrect) {
        _feedback = _hintUsed
            ? _RecallFeedback.correctWithHint
            : _RecallFeedback.correct;
        if (grade.evidence == VocabRecallEvidence.positive) {
          _directCorrect++;
        }
      } else {
        _feedback = _RecallFeedback.incorrect;
        _missedWordIds.add(word.korean);
      }
    });
    await _recordEvidence(word, grade);
    if (!mounted) {
      return;
    }
    if (grade.isCorrect) {
      HapticFeedback.lightImpact();
      SoundService.correct();
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
    }
  }

  Future<void> _showAnswer() async {
    if (_feedback != null) {
      return;
    }
    final word = _current;
    setState(() {
      _feedback = _RecallFeedback.revealed;
      _missedWordIds.add(word.korean);
    });
    await _recordEvidence(word, revealedVocabRecallAnswer);
    if (!mounted) {
      return;
    }
    HapticFeedback.mediumImpact();
    SoundService.wrong();
  }

  Future<void> _recordEvidence(Vocab word, VocabRecallGrade grade) async {
    final session = widget.recallSession;
    if (session == null || !session.isValidForPack(widget.packId)) {
      return;
    }
    switch (grade.evidence) {
      case VocabRecallEvidence.positive:
        final action = session.recordPositiveFor(
          expectedPackId: widget.packId,
          wordId: word.korean,
        );
        if (action.writesSrs) {
          await Storage.srsReview(word.korean, gotIt: action.gotIt!);
        }
        return;
      case VocabRecallEvidence.negative:
        final action = session.recordNegativeFor(
          expectedPackId: widget.packId,
          wordId: word.korean,
        );
        if (action.writesSrs) {
          await Storage.srsReview(word.korean, gotIt: action.gotIt!);
        }
        // The ledger coalesces SRS scheduling only. Every genuine miss keeps
        // the existing wrong-count behavior, but practice-only route payloads
        // return above without recording either kind of learning evidence.
        await Storage.incrementWrongCount(word.korean);
        return;
      case VocabRecallEvidence.none:
        return;
    }
  }

  void _showHint() {
    if (_feedback != null || _hintUsed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _hintUsed = true);
  }

  void _next() {
    if (_feedback == null) {
      return;
    }
    if (_index + 1 >= _words.length) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _hintUsed = false;
      _feedback = null;
      _input.clear();
    });
    _focusInput();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return SoriStudyFrame(
        title: t.vocabPackRecallTitle,
        padding: EdgeInsets.zero,
        child: const AppLoading(),
      );
    }
    if (_error != null) {
      return SoriStudyFrame(
        title: t.vocabPackRecallTitle,
        padding: EdgeInsets.zero,
        child: AppError(message: _error!, onRetry: _load),
      );
    }
    if (_words.isEmpty) {
      return SoriStudyFrame(
        title: t.vocabPackRecallTitle,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.keyboard_alt_outlined,
            title: t.vocabPackRecallTitle,
            body: t.vocabPackRecallNoBossWords,
          ),
        ),
      );
    }
    if (_done) {
      return _buildDone(t);
    }
    return _buildPrompt(t);
  }

  Widget _buildPrompt(AppL10n t) {
    final word = _current;
    final lang = Localizations.localeOf(context).languageCode;
    final feedback = _feedback;
    final isLocked = feedback != null;
    final answerWasShown =
        feedback == _RecallFeedback.incorrect ||
        feedback == _RecallFeedback.revealed;
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final feedbackColor = answerWasShown
        ? SoriColors.danger
        : feedback == _RecallFeedback.correctWithHint
        ? SoriColors.warning
        : SoriColors.success;

    return SoriStudyFrame(
      title: t.vocabPackRecallTitle,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SoriChip(
                        label: '${_index + 1} / ${_words.length}',
                        accent: SoriColors.accent,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(t.vocabPackRecallIntro, style: tt.caption),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    t.vocabPackRecallPrompt,
                    textAlign: TextAlign.center,
                    style: tt.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: s.textMuted,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriCard(
                    variant: SoriCardVariant.hero,
                    accent: SoriColors.accent,
                    tinted: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.xl,
                        horizontal: Spacing.md,
                      ),
                      child: Text(
                        word.translationFor(lang),
                        textAlign: TextAlign.center,
                        style: tt.display.copyWith(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SoriTextField(
                    fieldKey: const Key('vocab-recall-input'),
                    controller: _input,
                    focusNode: _inputFocus,
                    autofocus: true,
                    enabled: !isLocked,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    style: tt.h1,
                    labelText: t.vocabPackRecallPrompt,
                    hintText: t.vocabPackRecallInputHint,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      // ignore: discarded_futures
                      _submit();
                    },
                  ),
                  if (_hintUsed && !isLocked) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      t.vocabPackRecallHintLabel(
                        vocabRecallFirstSyllable(word.korean),
                      ),
                      key: const Key('vocab-recall-hint-label'),
                      textAlign: TextAlign.center,
                      style: tt.label.copyWith(color: SoriColors.warning),
                    ),
                  ],
                  if (feedback != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      _feedbackText(t, feedback),
                      textAlign: TextAlign.center,
                      style: tt.h3.copyWith(color: feedbackColor),
                    ),
                    if (answerWasShown) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        t.vocabPackRecallAnswer(word.korean),
                        textAlign: TextAlign.center,
                        style: tt.h3,
                      ),
                    ],
                    const SizedBox(height: Spacing.xs),
                    TextButton.icon(
                      onPressed: () {
                        // ignore: discarded_futures
                        TtsService.speak(word.korean);
                      },
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(t.vocabPackBossReplayAudio),
                    ),
                  ],
                  const Spacer(),
                  if (!isLocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SoriButton(
                            key: const Key('vocab-recall-hint'),
                            label: t.vocabPackRecallHintCta,
                            variant: SoriButtonVariant.outlined,
                            accent: SoriColors.warning,
                            onTap: _hintUsed ? null : _showHint,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: SoriButton(
                            key: const Key('vocab-recall-show-answer'),
                            label: t.vocabPackRecallShowAnswerCta,
                            variant: SoriButtonVariant.outlined,
                            accent: SoriColors.danger,
                            onTap: _showAnswer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  SoriButton(
                    key: Key(
                      isLocked ? 'vocab-recall-next' : 'vocab-recall-submit',
                    ),
                    label: isLocked ? t.btnNext : t.btnSubmit,
                    variant: SoriButtonVariant.filled,
                    accent: SoriColors.accent,
                    fullWidth: true,
                    onTap: isLocked
                        ? _next
                        : (_input.text.trim().isEmpty ? null : _submit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _feedbackText(AppL10n t, _RecallFeedback feedback) {
    switch (feedback) {
      case _RecallFeedback.correct:
        return t.vocabPackRecallCorrect;
      case _RecallFeedback.correctWithHint:
        return t.vocabPackRecallCorrectWithHint;
      case _RecallFeedback.incorrect:
        return t.vocabPackRecallIncorrect;
      case _RecallFeedback.revealed:
        return t.vocabPackRecallRevealed;
    }
  }

  Widget _buildDone(AppL10n t) {
    final tt = SoriTextTheme.of(context);
    return SoriStudyFrame(
      automaticallyImplyLeading: false,
      title: t.vocabPackRecallTitle,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.keyboard_alt_outlined,
                    size: 72,
                    color: SoriColors.accent,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    t.vocabPackRecallDoneTitle,
                    textAlign: TextAlign.center,
                    style: tt.h2,
                  ),
                  const SizedBox(height: Spacing.md),
                  SoriCard(
                    variant: SoriCardVariant.hero,
                    accent: SoriColors.accent,
                    tinted: true,
                    child: Text(
                      t.vocabPackRecallDoneScore(_directCorrect, _words.length),
                      textAlign: TextAlign.center,
                      style: tt.numeral.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.vocabPackRecallReviewLater,
                    textAlign: TextAlign.center,
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: Spacing.xl),
                  if (shouldOfferVocabRecallHardWordPractice(_missedWordIds))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: SoriButton(
                        key: const Key('vocab-recall-hard-words'),
                        label: t.vocabPackResultHardWordsCta,
                        variant: SoriButtonVariant.outlined,
                        accent: SoriColors.danger,
                        fullWidth: true,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/hard_words'),
                      ),
                    ),
                  SoriButton(
                    key: const Key('vocab-recall-back-to-result'),
                    label: t.vocabPackRecallBackToResult,
                    variant: SoriButtonVariant.filled,
                    accent: SoriColors.primary,
                    fullWidth: true,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
