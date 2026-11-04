import '../data/canonical_companion_art.dart';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/grammar.dart';
import '../models/learner_level.dart';
import '../services/data_loader.dart';
import '../services/grammar_choice_quiz.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/grammar_c.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/lazy_scroll_reveal.dart';
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
    this.allowedTargetIds,
    this.planDayLabel,
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

  /// When a grammar plan opens this exercise, restricts only the authored
  /// targets for that day. The option pool remains level-wide by contract.
  final Set<String>? allowedTargetIds;

  /// Optional plan context for the progress caption. Free practice keeps the
  /// existing level-based caption when this is null.
  final String? planDayLabel;

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
          allowedTargetIds: widget.allowedTargetIds,
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
      SoundService.correct();
      return;
    }
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
    revealLazyScrollTarget(
      context: context,
      controller: _questionScroll,
      targetKey: _feedbackKey,
      isMounted: () => mounted,
    );
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
        allowedTargetIds: widget.allowedTargetIds,
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
    return GrammarCFrame(
      title: t.grammarChoiceTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_isDone && (_index > 0 || _answered),
      ),
      eyebrow: t.grammarChoiceEyebrow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      asset: CanonicalCompanionArt.baekhoSeated,
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
      asset: CanonicalCompanionArt.magpieGuide,
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
    final feedbackTitle = isCorrect
        ? t.grammarChoiceCorrect
        : t.grammarChoiceIncorrect(question.target.pattern);
    final usage = question.target.noteFor(languageCode);
    final hasUsage = usage.trim().isNotEmpty;
    final feedbackSemantics = [
      feedbackTitle,
      '${t.grammarChoiceKoreanExampleLabel}: '
          '${question.target.exampleKorean}',
      '${t.grammarChoiceExplanationLabel}: '
          '${question.target.explanationFor(languageCode)}',
      if (hasUsage) '${t.grammarChoiceNoteLabel}: $usage',
    ].join('. ');
    final segments = splitGrammarPrompt(
      example: question.target.exampleFor(languageCode),
      focus: question.target.exampleFocusFor(languageCode),
    );

    final choices = <Widget>[
      for (final option in question.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuizChoice(
            text: option.pattern,
            subtitle: selected == null ? null : option.typeFor(languageCode),
            isCorrect: question.isCorrect(option),
            isSelected: selected?.id == option.id,
            revealed: selected != null,
            minHeight: 48,
            semanticTapEnabled: true,
            surfaceBuilder: GrammarC.choiceSurface,
            textStyle: GrammarC.korean.copyWith(fontSize: 20),
            onSelected: selected == null ? () => _select(option) : null,
          ),
        ),
    ];
    final scrollWholeQuestion = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final header = <Widget>[
      Wrap(
        spacing: 12,
        children: [
          Text(
            t.grammarChoiceEyebrow.toUpperCase(),
            style: GrammarC.body.copyWith(fontSize: 13, color: GrammarC.jade),
          ),
          Text(
            widget.planDayLabel != null
                ? '${widget.planDayLabel} · ${_index + 1} / ${_round.length}'
                : '${_index + 1} / ${_round.length} · $_level',
            style: GrammarC.body.copyWith(fontSize: 13, color: GrammarC.jade),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected == null) ...[
          Text(t.grammarChoiceInstruction, style: GrammarC.body),
          const SizedBox(height: 16),
          GrammarCPaper(
            child: Semantics(
              label: t.grammarChoicePromptSemantics(
                question.target.exampleFor(languageCode),
                question.target.exampleFocusFor(languageCode),
              ),
              child: ExcludeSemantics(
                child: Text.rich(
                  key: const Key('grammar-choice-prompt'),
                  TextSpan(
                    style: GrammarC.heading.copyWith(
                      color: GrammarC.blueInk,
                      fontSize: 21,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    children: [
                      for (final segment in segments)
                        TextSpan(
                          text: segment.text,
                          style: segment.isFocus
                              ? const TextStyle(
                                  color: GrammarC.ink,
                                  fontWeight: FontWeight.w700,
                                  backgroundColor: Color(0x4dc99a40),
                                  decoration: TextDecoration.underline,
                                  decorationColor: GrammarC.gold,
                                  decorationThickness: 2,
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...choices,
        ],
        if (selected != null) ...[
          Semantics(
            key: _feedbackKey,
            container: true,
            liveRegion: true,
            label: feedbackSemantics,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    feedbackTitle,
                    style: GrammarC.heading.copyWith(
                      color: isCorrect ? GrammarC.jade : SoriColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.target.pattern,
                    style: GrammarC.korean.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.target.typeFor(languageCode),
                    style: GrammarC.body.copyWith(color: GrammarC.blueInk),
                  ),
                  GrammarCRail(
                    minHeight: 112,
                    child: Text(
                      question.target.pattern,
                      textAlign: TextAlign.center,
                      style: GrammarC.korean,
                    ),
                  ),
                  GrammarCPaper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t.grammarChoiceKoreanExampleLabel,
                          style: GrammarC.heading.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.target.exampleKorean,
                          style: GrammarC.korean.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.target.exampleFor(languageCode),
                          style: GrammarC.heading.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: GrammarC.blueInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GrammarCSectionLabel(t.grammarChoiceExplanationLabel),
                  const SizedBox(height: 8),
                  Text(
                    question.target.explanationFor(languageCode),
                    style: GrammarC.body,
                  ),
                  if (hasUsage) ...[
                    const SizedBox(height: 12),
                    GrammarCSectionLabel(t.grammarChoiceNoteLabel),
                    const SizedBox(height: 8),
                    Text(usage, style: GrammarC.body),
                  ],
                ],
              ),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _saveError!,
                key: const Key('grammar-choice-save-error'),
                style: GrammarC.body.copyWith(color: SoriColors.danger),
              ),
            ),
          ],
          // Retain the revealed choices for review and accessibility.
          const SizedBox(height: 24),
          ...choices,
        ],
      ],
    );
    final footer = <Widget>[
      if (selected != null) ...[
        const SizedBox(height: 8),
        SoriButton.filled(
          cMaterial: true,
          textStyle: GrammarC.action,
          label: _index + 1 >= _round.length
              ? t.grammarChoiceFinish
              : t.btnNext,
          fullWidth: true,
          onTap: _savingHard ? null : _continue,
        ),
      ],
    ];
    if (scrollWholeQuestion) {
      // Large text can make the progress and action taller than the body.
      // Keep feedback, reviewed choices and the next action in one viewport.
      return SingleChildScrollView(
        controller: _questionScroll,
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...header, content, ...footer],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        Expanded(
          child: SingleChildScrollView(
            controller: _questionScroll,
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            child: content,
          ),
        ),
        ...footer,
      ],
    );
  }

  Widget _buildDone(AppL10n t) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      style: GrammarC.heading.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: Spacing.sm),
                    GrammarCRail(
                      minHeight: 124,
                      child: Text(
                        t.grammarChoiceScore(_score, _round.length),
                        textAlign: TextAlign.center,
                        style: GrammarC.heading.copyWith(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      t.grammarChoicePracticeOnly,
                      textAlign: TextAlign.center,
                      style: GrammarC.body,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            SoriButton.filled(
              cMaterial: true,
              textStyle: GrammarC.action,
              label: t.grammarChoiceAgain,
              fullWidth: true,
              onTap: _restart,
            ),
            const SizedBox(height: Spacing.sm),
            SoriButton.outlined(
              cMaterial: true,
              textStyle: GrammarC.action,
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
