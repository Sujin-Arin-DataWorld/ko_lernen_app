import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/custom_pack_service.dart';
import '../services/sound_service.dart';
import '../services/vocab_nuance_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// Playful comparison of synonyms, register, and Hanja roots using only
/// the words already in the learner's notebook pack.
class VocabNuanceScreen extends StatefulWidget {
  const VocabNuanceScreen({super.key, required this.packId});

  final String packId;

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
    _questions = pack == null
        ? const <VocabNuanceQuestion>[]
        : VocabNuanceService.questionsFor(pack.words, language: language);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final pack = CustomPackService.getById(widget.packId);
    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabNotebookNuanceTitle)),
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
        appBar: AppBar(title: Text(t.vocabNotebookNuanceTitle)),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_idle.png',
            icon: Icons.compare_arrows_rounded,
            title: t.vocabNotebookNuanceEmptyTitle,
            body: t.vocabNotebookNuanceEmptyBody,
          ),
        ),
      );
    }
    if (_index >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabNotebookNuanceTitle)),
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
                    icon: Icons.replay_outlined,
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
      appBar: AppBar(
        title: Text(
          t.vocabNotebookNuanceTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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
                      text: option.hanja.isEmpty
                          ? option.korean
                          : '${option.korean}  ${option.hanja}',
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
                    icon: Icons.arrow_forward_rounded,
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
