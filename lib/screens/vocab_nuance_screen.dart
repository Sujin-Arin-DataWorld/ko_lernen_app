import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/custom_pack_service.dart';
import '../services/sound_service.dart';
import '../services/vocab_nuance_service.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// Playful comparison of synonyms, register, and Hanja roots using only
/// the words already in the learner's notebook pack.
class VocabNuanceScreen extends StatefulWidget {
  const VocabNuanceScreen({super.key, required this.packId, this.words});

  final String packId;
  final List<ExtractedWord>? words;

  @override
  State<VocabNuanceScreen> createState() => _VocabNuanceScreenState();
}

class _VocabNuanceScreenState extends State<VocabNuanceScreen> {
  late final List<VocabNuanceQuestion> _questions;
  int _index = 0;
  int _score = 0;
  String? _picked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questionsReady) {
      return;
    }
    final pack = CustomPackService.getById(widget.packId);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final source = widget.words ?? pack?.words ?? const <ExtractedWord>[];
    _questions = source.isEmpty
        ? const <VocabNuanceQuestion>[]
        : VocabNuanceService.questionsFor(source, language: language);
    _questionsReady = true;
  }

  bool _questionsReady = false;

  void _pick(VocabNuanceQuestion question, String korean) {
    if (_picked != null) {
      return;
    }
    final correct = korean == question.correctKorean;
    if (correct) {
      SoundService.correct();
      HapticFeedback.lightImpact();
    } else {
      SoundService.wrong();
      HapticFeedback.selectionClick();
    }
    setState(() {
      _picked = korean;
      if (correct) {
        _score++;
      }
    });
  }

  void _continue() {
    setState(() {
      _index++;
      _picked = null;
    });
  }

  String _optionLabel(
    VocabNuanceQuestion question,
    VocabNuanceOption option,
    AppL10n t,
  ) {
    switch (question.kind) {
      case VocabNuanceQuestionKind.sharedMeaning:
        return option.hanja.isEmpty ? t.vocabNotebookNoHanja : option.hanja;
      case VocabNuanceQuestionKind.hanjaRoot:
        if (option.meaning.isEmpty) {
          return option.korean;
        }
        return '${option.korean}  ${option.meaning}';
      case VocabNuanceQuestionKind.register:
        return option.korean;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final pack = CustomPackService.getById(widget.packId);
    if (pack == null) {
      return Scaffold(
        appBar: SoriAppBar(
          title: t.vocabNotebookNuanceTitle,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
        ),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: SoriAppBar(
          title: t.vocabNotebookNuanceTitle,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
        ),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.compare_arrows_rounded,
            title: t.vocabNotebookNuanceEmptyTitle,
            body: t.vocabNotebookNuanceEmptyBody,
          ),
        ),
      );
    }
    if (_index >= _questions.length) {
      return Scaffold(
        appBar: SoriAppBar(
          title: t.vocabNotebookNuanceTitle,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
        ),
        body: SafeArea(
          child: SoriCenterClamp(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    t.customPackResultDone,
                    style: SoriTextTheme.of(context).h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.quizScore(_score, _questions.length),
                    style: SoriTextTheme.of(context).body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.lg),
                  SoriButton.filled(
                    label: t.customPackResultAgain,
                    fullWidth: true,
                    onTap: () => setState(() {
                      _index = 0;
                      _score = 0;
                      _picked = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = _questions[_index];
    return Scaffold(
      appBar: SoriAppBar(
        title: t.vocabNotebookNuanceTitle,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${_index + 1} / ${_questions.length}',
                  style: SoriTextTheme.of(context).caption,
                ),
                const SizedBox(height: Spacing.md),
                SoriCard(
                  variant: SoriCardVariant.hero,
                  accent: SoriColors.goldOnLight,
                  child: Text(
                    question.promptFor(language),
                    style: SoriTextTheme.of(context).h3,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                ...question.options.map((option) {
                  final selected = _picked == option.korean;
                  final correct = option.korean == question.correctKorean;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: QuizChoice(
                      text: _optionLabel(question, option, t),
                      isSelected: selected,
                      revealed: _picked != null,
                      isCorrect: correct,
                      onSelected: _picked == null
                          ? () => _pick(question, option.korean)
                          : null,
                    ),
                  );
                }),
                if (_picked != null) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    question.explanationFor(language),
                    style: SoriTextTheme.of(context).body,
                  ),
                  const SizedBox(height: Spacing.md),
                  SoriButton.filled(
                    label: t.btnNext,
                    fullWidth: true,
                    onTap: _continue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
