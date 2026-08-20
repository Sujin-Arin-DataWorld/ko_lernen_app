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
    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return SoriStudyFrame(
      title: t.wordWebQuizTitle,
      child: _items.isEmpty
          ? _buildEmpty(t)
          : _done
          ? _buildDone(t)
          : _buildQuestion(t, lang),
    );
  }

  Widget _buildQuestion(AppL10n t, String lang) {
    final cur = _current!;
    final prompt = cur.kind == WordRelationKind.expression
        ? cur.promptGloss(lang)
        : cur.sourceKo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${_idx + 1} / ${_items.length}',
              style: SoriTextTheme.of(context).caption,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                _hint(t, cur),
                style: SoriTextTheme.of(context).caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.accent,
          tinted: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Text(
              prompt,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).display,
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Expanded(
          child: ListView.separated(
            itemCount: cur.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (_, i) => QuizChoice(
              key: ValueKey('word-web-option-${cur.options[i]}'),
              text: cur.options[i],
              isCorrect: cur.options[i] == cur.answerKo,
              isSelected: _selected == i,
              revealed: _locked,
              minHeight: 56,
              onSelected: _locked ? null : () => _select(i),
            ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot.tiger(emotion: MascotEmotion.celebrate, size: 120),
          const SizedBox(height: Spacing.lg),
          Text(t.wordWebQuizDoneTitle, style: SoriTextTheme.of(context).h2),
          const SizedBox(height: Spacing.sm),
          Text(t.wordWebQuizScore(_score, _items.length)),
          const SizedBox(height: Spacing.xl),
          SoriButton(
            label: t.btnClose,
            variant: SoriButtonVariant.filled,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
