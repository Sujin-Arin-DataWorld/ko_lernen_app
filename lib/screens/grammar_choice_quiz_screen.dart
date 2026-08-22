import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/grammar.dart';
import '../models/learner_level.dart';
import '../services/data_loader.dart';
import '../services/grammar_choice_quiz.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// Standalone grammar recognition practice.
///
/// A learner sees a DE/EN example with its reviewed semantic cue emphasized,
/// then selects one Korean grammar pattern from four same-level choices. This
/// is deliberately free practice: it does not report course evidence, change
/// pack unlocks, grant XP, or write vocabulary SRS credit. A wrong response
/// may still place the pattern in the existing local grammar-hard filter.
class GrammarChoiceQuizScreen extends StatefulWidget {
  const GrammarChoiceQuizScreen({
    super.key,
    this.initialLevel,
    this.grammarLoader,
    this.dataLoaderErrorReader,
    this.markGrammarHard,
    this.randomSeed,
    this.maxQuestions = 10,
  });

  /// A level from the library filter. Invalid or absent values fall back to
  /// the learner's configured level, then the first available level.
  final String? initialLevel;

  /// Test seam. Production reads the reviewed grammar CSV through
  /// [DataLoader.loadGrammar].
  final Future<List<Grammar>> Function()? grammarLoader;

  /// Test seam for the production loader's error boundary. Production reads
  /// [DataLoader.lastError] after an empty [DataLoader.loadGrammar] result,
  /// because that loader catches asset and CSV errors itself.
  final String? Function()? dataLoaderErrorReader;

  /// Test seam for the existing local grammar-hard persistence.
  final Future<void> Function(String pattern)? markGrammarHard;

  /// Test-only reproducibility seam. Production intentionally uses a fresh
  /// random sequence on each opened round.
  final int? randomSeed;

  /// Production keeps a compact ten-question round. Tests may shrink it to
  /// isolate one answer without weakening the production content contract.
  final int maxQuestions;

  @override
  State<GrammarChoiceQuizScreen> createState() =>
      _GrammarChoiceQuizScreenState();
}

class _GrammarChoiceQuizScreenState extends State<GrammarChoiceQuizScreen> {
  late final Random _random;
  final ScrollController _questionScroll = ScrollController();
  final GlobalKey _feedbackKey = GlobalKey();
  List<Grammar> _source = const <Grammar>[];
  List<GrammarChoiceQuestion> _round = const <GrammarChoiceQuestion>[];
  String _level = '';
  int _index = 0;
  int _score = 0;
  Grammar? _selected;
  bool _loading = true;
  String? _loadError;
  bool _savingHard = false;
  String? _saveError;

  GrammarChoiceQuestion? get _question =>
      _index >= 0 && _index < _round.length ? _round[_index] : null;

  bool get _answered => _selected != null;

  bool get _isDone => _round.isNotEmpty && _index >= _round.length;

  @override
  void initState() {
    super.initState();
    _random = widget.randomSeed == null ? Random() : Random(widget.randomSeed!);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final usesProductionLoader = widget.grammarLoader == null;
      final source = await (widget.grammarLoader ?? DataLoader.loadGrammar)();
      final loaderError = usesProductionLoader
          ? DataLoader.lastError
          : widget.dataLoaderErrorReader?.call();
      if (!mounted) {
        return;
      }
      if (source.isEmpty && loaderError != null) {
        setState(() {
          _loading = false;
          _loadError = AppL10n.of(context).loadErrorTryAgain;
        });
        return;
      }
      final level = _resolveLevel(source);
      setState(() {
        _source = source;
        _level = level;
        _round = buildGrammarChoiceRound(
          source: source,
          level: level,
          languageCode: Localizations.localeOf(context).languageCode,
          random: _random,
          maxQuestions: widget.maxQuestions,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  String _resolveLevel(List<Grammar> source) {
    final levels = source.map((grammar) => grammar.level).toSet();
    final requested = LearnerLevel.fromCode(widget.initialLevel)?.display;
    if (requested != null && levels.contains(requested)) {
      return requested;
    }
    final learnerLevel = LearnerLevel.fromCode(Storage.userLevelCode)?.display;
    if (learnerLevel != null && levels.contains(learnerLevel)) {
      return learnerLevel;
    }
    final sorted = levels.toList()..sort();
    return sorted.isEmpty ? '' : sorted.first;
  }

  Future<void> _select(Grammar option) async {
    final question = _question;
    if (question == null || _answered) {
      return;
    }
    final isCorrect = question.isCorrect(option);
    setState(() {
      _selected = option;
      if (isCorrect) {
        _score++;
      }
    });
    _revealFeedback();
    if (isCorrect) {
      HapticFeedback.lightImpact();
      SoundService.correct();
      return;
    }
    HapticFeedback.mediumImpact();
    SoundService.wrong();
    setState(() {
      _savingHard = true;
      _saveError = null;
    });
    try {
      await (widget.markGrammarHard ?? Storage.markGrammarHard)(
        question.target.pattern,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingHard = false;
        _saveError = AppL10n.of(context).grammarChoiceSaveError;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _savingHard = false);
  }

  void _revealFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bringFeedbackIntoView();
    });
  }

  void _bringFeedbackIntoView({bool materializedEnd = false}) {
    if (!mounted) {
      return;
    }
    final feedbackContext = _feedbackKey.currentContext;
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 220),
    );
    if (feedbackContext != null) {
      // The explanation is appended after the options. Bring it into view so
      // the fixed bottom action never asks a learner to continue before they
      // have seen why their choice was right or wrong.
      Scrollable.ensureVisible(
        feedbackContext,
        duration: duration,
        curve: Curves.easeOut,
        alignment: 0.18,
      );
      return;
    }
    if (materializedEnd || !_questionScroll.hasClients) {
      return;
    }
    final end = _questionScroll.position.maxScrollExtent;
    if (duration == Duration.zero) {
      _questionScroll.jumpTo(end);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bringFeedbackIntoView(materializedEnd: true);
      });
      return;
    }
    // ignore: discarded_futures
    _questionScroll
        .animateTo(end, duration: duration, curve: Curves.easeOut)
        .then((_) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _bringFeedbackIntoView(materializedEnd: true);
            });
          }
        });
  }

  void _scrollQuestionToStart() {
    if (_questionScroll.hasClients) {
      _questionScroll.jumpTo(0);
    }
  }

  void _continue() {
    if (!_answered || _savingHard) {
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _saveError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollQuestionToStart(),
    );
  }

  void _restart() {
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _round = buildGrammarChoiceRound(
        source: _source,
        level: _level,
        languageCode: languageCode,
        random: _random,
        maxQuestions: widget.maxQuestions,
      );
      _index = 0;
      _score = 0;
      _selected = null;
      _savingHard = false;
      _saveError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollQuestionToStart(),
    );
  }

  @override
  void dispose() {
    _questionScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      title: t.grammarChoiceTitle,
      eyebrow: t.grammarChoiceEyebrow,
      padding: Spacing.page,
      child: _loading
          ? const Center(child: AppLoading())
          : _loadError != null
          ? _buildLoadFailure(t)
          : _round.isEmpty
          ? _buildEmpty(t)
          : _isDone
          ? _buildDone(t)
          : _buildQuestion(t),
    );
  }

  Widget _buildLoadFailure(AppL10n t) => Center(
    child: SoriEmptyState(
      asset: 'assets/illustrations/mascot/tiger_sitting2.png',
      icon: Icons.error_outline_rounded,
      title: t.grammarChoiceUnavailableTitle,
      body: _loadError,
      ctaLabel: t.btnRetry,
      onCta: () {
        if (widget.grammarLoader == null) {
          DataLoader.resetGrammar();
        }
        setState(() {
          _loading = true;
          _loadError = null;
        });
        _load();
      },
    ),
  );

  Widget _buildEmpty(AppL10n t) => Center(
    child: SoriEmptyState(
      asset: 'assets/illustrations/mascot/magpie_encourage.png',
      icon: Icons.fact_check_outlined,
      title: t.grammarChoiceUnavailableTitle,
      body: t.grammarChoiceUnavailableBody,
      ctaLabel: t.grammarChoiceBack,
      onCta: () => Navigator.of(context).maybePop(),
    ),
  );

  Widget _buildQuestion(AppL10n t) {
    final question = _question!;
    final selected = _selected;
    final isCorrect = selected != null && question.isCorrect(selected);
    final languageCode = Localizations.localeOf(context).languageCode;
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final feedbackTitle = isCorrect
        ? t.grammarChoiceCorrect
        : t.grammarChoiceIncorrect(question.target.pattern);
    final feedbackSemantics = [
      feedbackTitle,
      '${t.grammarChoiceKoreanExampleLabel}: '
          '${question.target.exampleKorean}',
      '${t.grammarChoiceExplanationLabel}: '
          '${question.target.explanationFor(languageCode)}',
    ].join('. ');
    final segments = splitGrammarPrompt(
      example: question.target.exampleFor(languageCode),
      focus: question.target.exampleFocusFor(languageCode),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${_index + 1} / ${_round.length} · $_level', style: tt.caption),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: ListView(
            controller: _questionScroll,
            children: [
              SoriCard(
                variant: SoriCardVariant.hero,
                accent: SoriColors.accent,
                tinted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.grammarChoiceInstruction, style: tt.label),
                    const SizedBox(height: Spacing.md),
                    Semantics(
                      label: t.grammarChoicePromptSemantics(
                        question.target.exampleFor(languageCode),
                        question.target.exampleFocusFor(languageCode),
                      ),
                      child: ExcludeSemantics(
                        child: Text.rich(
                          key: const Key('grammar-choice-prompt'),
                          TextSpan(
                            style: tt.h2.copyWith(color: s.text),
                            children: [
                              for (final segment in segments)
                                TextSpan(
                                  text: segment.text,
                                  style: segment.isFocus
                                      ? tt.h2.copyWith(
                                          color: SoriColors.accent,
                                          decoration: TextDecoration.underline,
                                          decorationColor: SoriColors.accent,
                                          decorationThickness: 2,
                                        )
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              for (final option in question.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: QuizChoice(
                    text: option.pattern,
                    subtitle: selected == null
                        ? null
                        : option.typeFor(languageCode),
                    isCorrect: question.isCorrect(option),
                    isSelected: selected?.id == option.id,
                    revealed: selected != null,
                    minHeight: 56,
                    idleBorderColor: SoriColors.primary,
                    semanticTapEnabled: true,
                    onSelected: selected == null ? () => _select(option) : null,
                  ),
                ),
              if (selected != null) ...[
                const SizedBox(height: Spacing.md),
                Semantics(
                  key: _feedbackKey,
                  container: true,
                  liveRegion: true,
                  label: feedbackSemantics,
                  child: ExcludeSemantics(
                    child: SoriCard(
                      accent: isCorrect
                          ? SoriColors.success
                          : SoriColors.accent,
                      tinted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feedbackTitle,
                            style: tt.h3.copyWith(
                              color: isCorrect
                                  ? SoriColors.primaryOnLight
                                  : SoriColors.accent,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            t.grammarChoiceKoreanExampleLabel,
                            style: tt.caption,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(question.target.exampleKorean, style: tt.h3),
                          const SizedBox(height: Spacing.md),
                          Text(
                            t.grammarChoiceExplanationLabel,
                            style: tt.caption,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            question.target.explanationFor(languageCode),
                            style: tt.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                if (_saveError != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _saveError!,
                      key: const Key('grammar-choice-save-error'),
                      style: tt.bodySmall.copyWith(color: SoriColors.danger),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
              ],
            ],
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: Spacing.sm),
          SoriButton.filled(
            label: _index + 1 >= _round.length
                ? t.grammarChoiceFinish
                : t.btnNext,
            fullWidth: true,
            onTap: _savingHard ? null : _continue,
          ),
        ],
      ],
    );
  }

  Widget _buildDone(AppL10n t) {
    final tt = SoriTextTheme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot.tiger(emotion: MascotEmotion.celebrate, size: 112),
            const SizedBox(height: Spacing.lg),
            Semantics(
              container: true,
              liveRegion: true,
              label: [
                t.grammarChoiceDoneTitle,
                t.grammarChoiceScore(_score, _round.length),
                t.grammarChoicePracticeOnly,
              ].join('. '),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      t.grammarChoiceDoneTitle,
                      textAlign: TextAlign.center,
                      style: tt.h1,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      t.grammarChoiceScore(_score, _round.length),
                      textAlign: TextAlign.center,
                      style: tt.h3,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      t.grammarChoicePracticeOnly,
                      textAlign: TextAlign.center,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            SoriButton.filled(
              label: t.grammarChoiceAgain,
              fullWidth: true,
              onTap: _restart,
            ),
            const SizedBox(height: Spacing.sm),
            SoriButton.outlined(
              label: t.grammarChoiceBack,
              fullWidth: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
