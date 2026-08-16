import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/grounded_book_study_service.dart';
import 'sori/card.dart';
import 'sori/mascot.dart';
import 'sori/mascot_preference.dart';
import 'sori/tokens.dart';

class GroundedBookAskButton extends StatelessWidget {
  const GroundedBookAskButton({
    super.key,
    required this.result,
    required this.target,
  });

  final BookAnalysisResult result;
  final GroundedBookTarget target;

  @override
  Widget build(BuildContext context) {
    final questions = GroundedBookStudyService.questionsForTarget(
      result,
      target,
    );
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    return IconButton(
      key: ValueKey<String>(
        'book-study-ask-${target.type.name}-${target.sourceUnitId}-${target.itemKey}',
      ),
      tooltip: t.bookStudyAskButton,
      icon: const Icon(Icons.question_answer_outlined, size: 20),
      onPressed: () => _showStudySheet(context),
    );
  }

  void _showStudySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.xl,
          ),
          child: GroundedBookStudyCard(result: result, target: target),
        ),
      ),
    );
  }
}

class GroundedBookStudyCard extends StatefulWidget {
  const GroundedBookStudyCard({
    super.key,
    required this.result,
    required this.target,
  });

  final BookAnalysisResult result;
  final GroundedBookTarget target;

  @override
  State<GroundedBookStudyCard> createState() => _GroundedBookStudyCardState();
}

class _GroundedBookStudyCardState extends State<GroundedBookStudyCard> {
  GroundedBookQuestion? _selected;
  bool _showQuizAnswer = false;

  @override
  void didUpdateWidget(covariant GroundedBookStudyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result ||
        !oldWidget.target.matches(widget.target)) {
      _selected = null;
      _showQuizAnswer = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = GroundedBookStudyService.questionsForTarget(
      widget.result,
      widget.target,
    );
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = _selected;
    final answer = selected == null
        ? null
        : GroundedBookStudyService.answer(widget.result, selected);
    return CompanionBuilder(
      builder: (context, kind) =>
          _content(context, questions, answer, kind: kind),
      noneBuilder: (context) => _content(context, questions, answer),
    );
  }

  Widget _content(
    BuildContext context,
    List<GroundedBookQuestion> questions,
    GroundedBookAnswer? answer, {
    MascotKind? kind,
  }) {
    final t = AppL10n.of(context);
    final name = switch (kind) {
      MascotKind.tiger => t.characterRomanTiger,
      MascotKind.magpie => t.characterRomanMagpie,
      _ => null,
    };
    final intro = switch (kind) {
      MascotKind.tiger => t.bookStudyTaegoIntro,
      MascotKind.magpie => t.bookStudyJoyIntro,
      _ => t.bookStudyGenericIntro,
    };
    return SoriCard(
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (kind != null) ...<Widget>[
                Mascot(kind: kind, emotion: MascotEmotion.thinking, size: 54),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name == null
                          ? t.bookStudyAskGenericTitle
                          : t.bookStudyAskTitle(name),
                      style: SoriTextTheme.of(context).h3,
                    ),
                    const SizedBox(height: 2),
                    Text(intro, style: SoriTextTheme.of(context).cardSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          for (final question in questions) ...<Widget>[
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selected = question;
                  _showQuizAnswer = false;
                });
              },
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              child: Text(_questionLabel(t, question.kind)),
            ),
            const SizedBox(height: Spacing.xs),
          ],
          if (answer != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _answerContent(context, t, answer, kind),
          ],
        ],
      ),
    );
  }

  Widget _answerContent(
    BuildContext context,
    AppL10n t,
    GroundedBookAnswer answer,
    MascotKind? kind,
  ) {
    final facts = answer.facts;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: SoriColors.primary.withValues(alpha: 0.20)),
      ),
      child: facts == null
          ? Text(
              t.bookStudyNoEvidence,
              style: SoriTextTheme.of(context).bodySmall,
            )
          : _supportedAnswer(context, t, answer, facts, kind),
    );
  }

  Widget _supportedAnswer(
    BuildContext context,
    AppL10n t,
    GroundedBookAnswer answer,
    GroundedBookFactPayload facts,
    MascotKind? kind,
  ) {
    final isQuiz = answer.question.kind == GroundedBookQuestionKind.quiz;
    final answerLead = switch (kind) {
      MascotKind.tiger => t.bookStudyTaegoAnswerLead,
      MascotKind.magpie => t.bookStudyJoyAnswerLead,
      _ => t.bookStudyGenericIntro,
    };
    final showFacts = !isQuiz || _showQuizAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(answerLead, style: SoriTextTheme.of(context).bodySmall),
        const SizedBox(height: Spacing.sm),
        if (isQuiz) ...<Widget>[
          Text(
            t.bookStudyQuizPrompt,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: Spacing.xs),
          Text(facts.quizPromptEvidence, style: SoriTextTheme.of(context).body),
          if (!_showQuizAnswer) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            OutlinedButton(
              onPressed: () => setState(() => _showQuizAnswer = true),
              child: Text(t.bookStudyShowAnswer),
            ),
          ],
        ],
        if (showFacts) ...<Widget>[
          Text(
            isQuiz ? facts.quizAnswer : facts.koreanEvidence,
            style: SoriTextTheme.of(
              context,
            ).body.copyWith(fontWeight: FontWeight.w800),
          ),
          if (facts.explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(facts.explanation, style: SoriTextTheme.of(context).bodySmall),
          ],
          if (kind == MascotKind.magpie &&
              facts.additionalExample.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              t.bookStudyAdditionalExample,
              style: SoriTextTheme.of(
                context,
              ).caption.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              facts.additionalExample,
              style: SoriTextTheme.of(context).bodySmall,
            ),
          ],
          const SizedBox(height: Spacing.sm),
          Text(
            '${t.bookStudyEvidenceLabel} · ${facts.sourceUnitIds.join(', ')}',
            style: SoriTextTheme.of(context).caption,
          ),
        ],
      ],
    );
  }

  String _questionLabel(AppL10n t, GroundedBookQuestionKind kind) =>
      switch (kind) {
        GroundedBookQuestionKind.explainForm => t.bookStudyAskWhyForm,
        GroundedBookQuestionKind.showExample => t.bookStudyAskExample,
        GroundedBookQuestionKind.compare => t.bookStudyAskCompare,
        GroundedBookQuestionKind.quiz => t.bookStudyAskQuiz,
        GroundedBookQuestionKind.meaning => t.bookStudyAskMeaning,
        GroundedBookQuestionKind.grammarInSentence =>
          t.bookStudyAskGrammarInSentence,
      };
}
