import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import '../services/word_relation_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/lazy_scroll_reveal.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// Free-practice quiz over a filtered word-web set.
///
/// No course evidence. The round only scores locally and speaks the answer.
class WordWebQuizScreen extends StatefulWidget {
  const WordWebQuizScreen({
    super.key,
    required this.clusters,
    this.distractorClusters,
    this.quizBuilder,
  });

  final List<WordRelationCluster> clusters;
  final List<WordRelationCluster>? distractorClusters;
  final List<WordRelationQuizItem> Function(List<WordRelationCluster> clusters)?
  quizBuilder;

  @override
  State<WordWebQuizScreen> createState() => _WordWebQuizScreenState();
}

class _WordWebQuizScreenState extends State<WordWebQuizScreen> {
  final ScrollController _questionScroll = ScrollController();
  final GlobalKey _feedbackKey = GlobalKey();
  late final List<WordRelationQuizItem> _items;
  int _idx = 0;
  int _score = 0;
  int _selected = -1;
  bool _locked = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _items =
        widget.quizBuilder?.call(widget.clusters) ??
        WordRelationService.buildQuiz(
          clusters: widget.clusters,
          distractorClusters: widget.distractorClusters,
        );
  }

  WordRelationQuizItem? get _current =>
      (_idx >= 0 && _idx < _items.length) ? _items[_idx] : null;

  String _hint(AppL10n t, WordRelationQuizItem item) {
    switch (item.kind) {
      case WordRelationKind.synonym:
        return t.wordWebQuizHintSynonym;
      case WordRelationKind.antonym:
        return t.wordWebQuizHintAntonym;
      case WordRelationKind.related:
        return t.wordWebQuizHintRelated;
      case WordRelationKind.expression:
        return t.wordWebQuizHintExpression;
    }
  }

  void _select(int i) {
    final cur = _current;
    if (cur == null || _locked) {
      return;
    }
    final isCorrect = cur.options[i] == cur.answerKo;
    setState(() {
      _selected = i;
      _locked = true;
    });
    if (isCorrect) {
      _score++;
      HapticFeedback.lightImpact();
      SoundService.correct();
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
    }
    TtsService.speak(cur.answerKo);
    _revealFeedback();
    if (SoriMotion.reduceMotion(context)) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) {
        return;
      }
      _advanceAfterFeedback();
    });
  }

  void _revealFeedback() {
    revealLazyScrollTarget(
      context: context,
      controller: _questionScroll,
      targetKey: _feedbackKey,
      isMounted: () => mounted,
    );
  }

  void _advanceAfterFeedback() {
    if (!_locked || _done) {
      return;
    }
    if (_idx + 1 >= _items.length) {
      setState(() => _done = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SoriCelebration.burst(context);
        }
      });
      return;
    }
    setState(() {
      _idx++;
      _selected = -1;
      _locked = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_questionScroll.hasClients) {
        _questionScroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _questionScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final progress = !_done && _items.isNotEmpty
        ? '${_idx + 1} / ${_items.length}'
        : null;

    return SoriStudyFrame(
      title: t.wordWebQuizTitle,
      homeEscape: SoriHomeEscape(confirmWhen: !_done && (_idx > 0 || _locked)),
      eyebrow: progress,
      padding: Spacing.page,
      child: _items.isEmpty
          ? _buildEmpty(t)
          : SoriAdaptiveStudyBody(
              minHeight: 480,
              child: _done ? _buildDone(t) : _buildQuestion(t, lang),
            ),
    );
  }

  Widget _buildQuestion(AppL10n t, String lang) {
    final cur = _current!;
    final prompt = cur.kind == WordRelationKind.expression
        ? cur.promptGloss(lang)
        : cur.sourceKo;
    final tt = SoriTextTheme.of(context);
    final isCorrect = _selected >= 0 && cur.options[_selected] == cur.answerKo;
    final feedback = isCorrect
        ? t.wordWebQuizCorrectFeedback(cur.answerKo)
        : t.wordWebQuizWrongFeedback(cur.answerKo);
    final reduceMotion = SoriMotion.reduceMotion(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_hint(t, cur), style: tt.label),
        const SizedBox(height: Spacing.md),
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.accent,
          tinted: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Text(prompt, textAlign: TextAlign.center, style: tt.display),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Expanded(
          child: ListView(
            controller: _questionScroll,
            children: [
              for (var i = 0; i < cur.options.length; i++) ...[
                QuizChoice(
                  key: ValueKey('word-web-option-${cur.options[i]}'),
                  text: cur.options[i],
                  isCorrect: cur.options[i] == cur.answerKo,
                  isSelected: _selected == i,
                  revealed: _locked,
                  minHeight: 56,
                  idleBorderColor: SoriColors.primary,
                  semanticTapEnabled: true,
                  onSelected: _locked ? null : () => _select(i),
                ),
                if (i + 1 < cur.options.length)
                  const SizedBox(height: Spacing.sm),
              ],
              if (_locked) ...[
                const SizedBox(height: Spacing.md),
                Semantics(
                  key: _feedbackKey,
                  container: true,
                  liveRegion: true,
                  label: feedback,
                  child: ExcludeSemantics(
                    child: SoriCard(
                      accent: isCorrect
                          ? SoriColors.success
                          : SoriColors.danger,
                      tinted: true,
                      child: Text(feedback, style: tt.h3),
                    ),
                  ),
                ),
                if (reduceMotion) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriButton.filled(
                    label: _idx + 1 >= _items.length
                        ? t.wordWebQuizFinish
                        : t.btnNext,
                    fullWidth: true,
                    onTap: _advanceAfterFeedback,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(AppL10n t) {
    return Center(
      child: SoriEmptyState(
        asset: 'assets/illustrations/mascot/magpie_encourage.png',
        icon: Icons.hub_outlined,
        title: t.wordWebQuizEmptyTitle,
        body: t.wordWebQuizEmptyBody,
        ctaLabel: t.btnClose,
        onCta: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final tt = SoriTextTheme.of(context);
    final score = t.wordWebQuizScore(_score, _items.length);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot.tiger(emotion: MascotEmotion.celebrate, size: 120),
            const SizedBox(height: Spacing.lg),
            Semantics(
              container: true,
              liveRegion: true,
              label: '${t.wordWebQuizDoneTitle}. $score',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      t.wordWebQuizDoneTitle,
                      textAlign: TextAlign.center,
                      style: tt.h1,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(score, textAlign: TextAlign.center, style: tt.h3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            SoriButton.filled(
              label: t.btnClose,
              fullWidth: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
