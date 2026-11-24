import '../data/canonical_companion_art.dart';
import '../services/haptic_service.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
import '../widgets/sori/study_evidence_recovery.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/viewport_pages.dart';

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

class _VocabPackRecallScreenState extends State<VocabPackRecallScreen>
    with StudyEvidenceRecovery<VocabPackRecallScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool _loading = true;
  int _presentation = 0;
  int _loadGeneration = 0;
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
    if (!studyEvidenceAcceptsInput || (_loadGeneration > 0 && _error == null)) {
      return;
    }
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final providedLoader = widget.packLoader;
      final pack = providedLoader != null
          ? await providedLoader(widget.packId)
          : await VocabPackService.findById(widget.packId);
      if (!studyEvidenceAcceptsInput || generation != _loadGeneration) {
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
        _presentation++;
        _directCorrect = 0;
        _hintUsed = false;
        _feedback = null;
        _done = false;
        _missedWordIds.clear();
        _loading = false;
      });
      _focusInput();
    } catch (_) {
      if (!studyEvidenceAcceptsInput || generation != _loadGeneration) {
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
      if (studyEvidenceAcceptsInput && _feedback == null && !_done) {
        _inputFocus.requestFocus();
      }
    });
  }

  Future<void> _submit(int presentation) async {
    if (!studyEvidenceAcceptsInput ||
        _loading ||
        _done ||
        presentation != _presentation ||
        _feedback != null ||
        _input.text.trim().isEmpty) {
      return;
    }
    final word = _current;
    final grade = gradeVocabRecallAnswer(
      submitted: _input.text,
      expected: word.korean,
      usedHint: _hintUsed,
    );
    _presentation++;
    if (!await _recordEvidence(word, grade) || !studyEvidenceAcceptsInput) {
      return;
    }
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
    if (grade.isCorrect) {
      SoundService.correct();
    } else {
      SoundService.wrong();
    }
  }

  Future<void> _showAnswer(int presentation) async {
    if (!studyEvidenceAcceptsInput ||
        _loading ||
        _done ||
        presentation != _presentation ||
        _feedback != null) {
      return;
    }
    final word = _current;
    _presentation++;
    if (!await _recordEvidence(word, revealedVocabRecallAnswer) ||
        !studyEvidenceAcceptsInput) {
      return;
    }
    setState(() {
      _feedback = _RecallFeedback.revealed;
      _missedWordIds.add(word.korean);
    });
    SoundService.wrong();
  }

  Future<bool> _recordEvidence(Vocab word, VocabRecallGrade grade) async {
    final session = widget.recallSession;
    if (session == null ||
        !session.isValidForPack(widget.packId) ||
        grade.evidence == VocabRecallEvidence.none) {
      return true;
    }
    final attempt = session.evidenceAttempt(
      expectedPackId: widget.packId,
      wordId: word.korean,
      gotIt: grade.evidence == VocabRecallEvidence.positive,
    );
    final progress = grade.evidence == VocabRecallEvidence.negative
        ? VocabProgressAttempt(wrongCountId: word.korean)
        : null;
    return saveStudyEvidence(() async {
      if (!await attempt.save() || !studyEvidenceIsCurrent) {
        return false;
      }
      return progress?.save() ?? true;
    });
  }

  void _showHint(int presentation) {
    if (!studyEvidenceAcceptsInput ||
        presentation != _presentation ||
        _feedback != null ||
        _hintUsed) {
      return;
    }
    HapticService.selectionClick();
    setState(() => _hintUsed = true);
  }

  void _next(int presentation) {
    if (!studyEvidenceAcceptsInput ||
        presentation != _presentation ||
        _feedback == null) {
      return;
    }
    _presentation++;
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
    final recovery = studyEvidenceRecoveryFrame(t.vocabPackRecallTitle);
    if (recovery != null) {
      return recovery;
    }
    final generation = _loadGeneration;
    if (_loading) {
      return SoriStudyFrame(
        onLeave: retireStudyEvidence,
        title: t.vocabPackRecallTitle,
        padding: EdgeInsets.zero,
        child: const AppLoading(),
      );
    }
    if (_error != null) {
      return SoriStudyFrame(
        onLeave: retireStudyEvidence,
        title: t.vocabPackRecallTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: _error!,
          onRetry: () {
            if (generation == _loadGeneration && !_loading && _error != null) {
              _load();
            }
          },
        ),
      );
    }
    if (_words.isEmpty) {
      return SoriStudyFrame(
        onLeave: retireStudyEvidence,
        title: t.vocabPackRecallTitle,
        child: Center(
          child: SoriEmptyState(
            asset: CanonicalCompanionArt.baekhoSeated,
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
    final presentation = _presentation;
    final word = _current;
    final lang = Localizations.localeOf(context).languageCode;
    final feedback = _feedback;
    final isLocked = feedback != null;
    final answerWasShown =
        feedback == _RecallFeedback.incorrect ||
        feedback == _RecallFeedback.revealed;
    final tt = SoriTextTheme.of(context);
    final feedbackColor = answerWasShown
        ? SoriColors.danger
        : feedback == _RecallFeedback.correctWithHint
        ? SoriColors.warning
        : SoriColors.success;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    const feedbackKey = Key('vocab-recall-feedback');
    const hintKey = Key('vocab-recall-hint-label');
    const promptKey = Key('vocab-recall-prompt');
    final bodyStyle = tt.body.copyWith(
      fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 17 : 16,
    );
    return SoriStudyFrame(
      onLeave: retireStudyEvidence,
      title: t.vocabPackRecallTitle,
      padding: EdgeInsets.fromLTRB(16, 8, 16, keyboardOpen ? 8 : 16),
      homeEscape: SoriHomeEscape(
        confirmWhen: !_done && (_index > 0 || _feedback != null),
      ),
      actions: const [TtsSpeedAction()],
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = keyboardOpen || box.maxHeight < 330;
          final field = SoriTextField(
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
            style: tt.koDisplay.copyWith(
              fontSize: bodyStyle.fontSize,
              height: 1.4,
            ),
            labelText: t.vocabPackRecallPrompt,
            hintText: t.vocabPackRecallInputHint,
            onChanged: (_) {
              if (studyEvidenceAcceptsInput && presentation == _presentation) {
                setState(() {});
              }
            },
            onSubmitted: (_) {
              // ignore: discarded_futures
              _submit(presentation);
            },
          );
          final submit = SoriButton(
            key: Key(isLocked ? 'vocab-recall-next' : 'vocab-recall-submit'),
            label: isLocked ? t.btnNext : t.btnSubmit,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.accent,
            cMaterial: true,
            fullWidth: true,
            onTap: isLocked
                ? () => _next(presentation)
                : (_input.text.trim().isEmpty
                      ? null
                      : () => _submit(presentation)),
          );
          void reveal() {
            // ignore: discarded_futures
            _showAnswer(presentation);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, pages) {
                    final promptStyle = compact ? bodyStyle : tt.h2;
                    final prompt = soriViewportTextPages(
                      context,
                      word.translationFor(lang),
                      style: promptStyle,
                      width: pages.maxWidth - Spacing.md * 2,
                      height:
                          pages.maxHeight -
                          SoriViewportPages.controlsHeight -
                          Spacing.md * 2,
                    );
                    return SoriViewportPages(
                      centerContent: true,
                      targetSectionKey: isLocked
                          ? feedbackKey
                          : _hintUsed
                          ? hintKey
                          : promptKey,
                      targetRevision: presentation,
                      sections: [
                        if (!compact && !isLocked)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: Row(
                              children: [
                                SoriChip(
                                  label: '${_index + 1} / ${_words.length}',
                                  accent: SoriColors.accent,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    t.vocabPackRecallIntro,
                                    style: bodyStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (feedback != null) ...[
                          Text(
                            _feedbackText(t, feedback),
                            key: feedbackKey,
                            textAlign: TextAlign.center,
                            style: tt.h3.copyWith(color: feedbackColor),
                          ),
                          if (answerWasShown)
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.xs),
                              child: Text(
                                t.vocabPackRecallAnswer(word.korean),
                                textAlign: TextAlign.center,
                                style: tt.h3,
                              ),
                            ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: () {
                              // ignore: discarded_futures
                              TtsService.speak(word.korean);
                            },
                            icon: const Icon(Icons.volume_up_rounded),
                            label: Text(t.vocabPackBossReplayAudio),
                          ),
                        ],
                        for (final (index, text) in prompt.indexed)
                          SoriCard(
                            key: index == 0 ? promptKey : null,
                            variant: SoriCardVariant.compact,
                            accent: SoriColors.accent,
                            tinted: true,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: promptStyle,
                            ),
                          ),
                        if (_hintUsed && !isLocked)
                          Padding(
                            key: hintKey,
                            padding: const EdgeInsets.only(top: Spacing.xs),
                            child: Text(
                              t.vocabPackRecallHintLabel(
                                vocabRecallFirstSyllable(word.korean),
                              ),
                              textAlign: TextAlign.center,
                              style: bodyStyle.copyWith(
                                color: SoriColors.warning,
                              ),
                            ),
                          ),
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: Spacing.md),
                            child: field,
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (!isLocked) ...[const SizedBox(height: Spacing.xs), field],
              const SizedBox(height: Spacing.sm),
              if (compact && !isLocked)
                Row(
                  children: [
                    IconButton(
                      key: const Key('vocab-recall-hint'),
                      tooltip: t.vocabPackRecallHintCta,
                      onPressed: _hintUsed
                          ? null
                          : () => _showHint(presentation),
                      icon: const Icon(Icons.lightbulb_outline),
                    ),
                    IconButton(
                      key: const Key('vocab-recall-show-answer'),
                      tooltip: t.vocabPackRecallShowAnswerCta,
                      onPressed: reveal,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    Expanded(child: submit),
                  ],
                )
              else ...[
                if (!isLocked) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SoriButton(
                          key: const Key('vocab-recall-hint'),
                          label: t.vocabPackRecallHintCta,
                          variant: SoriButtonVariant.outlined,
                          accent: SoriColors.warning,
                          cMaterial: true,
                          onTap: _hintUsed
                              ? null
                              : () => _showHint(presentation),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: SoriButton(
                          key: const Key('vocab-recall-show-answer'),
                          label: t.vocabPackRecallShowAnswerCta,
                          variant: SoriButtonVariant.outlined,
                          accent: SoriColors.danger,
                          cMaterial: true,
                          onTap: reveal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
                submit,
              ],
            ],
          );
        },
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
      onLeave: retireStudyEvidence,
      automaticallyImplyLeading: false,
      title: t.vocabPackRecallTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SoriViewportPages(
              centerContent: true,
              sections: [
                Icon(
                  Icons.keyboard_alt_outlined,
                  size: 64,
                  color: SoriColors.accent,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.vocabPackRecallDoneTitle,
                  textAlign: TextAlign.center,
                  style: tt.h2,
                ),
                const SizedBox(height: Spacing.md),
                SoriCard(
                  variant: SoriCardVariant.compact,
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
                  style: tt.body,
                ),
              ],
            ),
          ),
          if (shouldOfferVocabRecallHardWordPractice(_missedWordIds))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: SoriButton(
                key: const Key('vocab-recall-hard-words'),
                label: t.vocabPackResultHardWordsCta,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.danger,
                cMaterial: true,
                fullWidth: true,
                onTap: () => Navigator.of(context).pushNamed('/hard_words'),
              ),
            ),
          SoriButton(
            key: const Key('vocab-recall-back-to-result'),
            label: t.vocabPackRecallBackToResult,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.primary,
            cMaterial: true,
            fullWidth: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
