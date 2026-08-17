import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/custom_pack_corpus_resolver.dart';
import '../services/custom_pack_service.dart';
import '../services/vocab_nuance_service.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'chosung_quiz_screen.dart';
import 'cloze_game_screen.dart';
import 'custom_pack_matching_screen.dart';
import 'custom_pack_play_screen.dart';
import 'custom_pack_quiz_screen.dart';
import 'custom_pack_typing_screen.dart';
import 'pronunciation_studio_screen.dart';
import 'satz_arcade_screen.dart';
import 'scenarios_list_screen.dart';
import 'smalltalk_screen.dart';
import 'speed_match_screen.dart';
import 'vocab_nuance_screen.dart';
import 'word_web_screen.dart';

/// Lets the learner pick notebook words and start existing games that
/// already teach those words. No new sentences are authored here.
class VocabNotebookStudioScreen extends StatefulWidget {
  const VocabNotebookStudioScreen({super.key, required this.packId});

  final String packId;

  @override
  State<VocabNotebookStudioScreen> createState() =>
      _VocabNotebookStudioScreenState();
}

class _VocabNotebookStudioScreenState extends State<VocabNotebookStudioScreen> {
  late final Set<String> _kept;
  CustomPackCorpusMatch _corpus = CustomPackCorpusMatch.empty;
  bool _loading = true;

  CustomPack? get _pack => CustomPackService.getById(widget.packId);

  List<ExtractedWord> get _selected {
    final pack = _pack;
    if (pack == null) {
      return const <ExtractedWord>[];
    }
    return pack.words
        .where((word) => _kept.contains(word.korean))
        .toList(growable: false);
  }

  CustomPackCorpusMatch get _match => _corpus.restrictTo(_kept);

  @override
  void initState() {
    super.initState();
    final pack = _pack;
    _kept = <String>{
      for (final word in pack?.words ?? const <ExtractedWord>[]) word.korean,
    };
    _loadCorpus();
  }

  Future<void> _loadCorpus() async {
    final pack = _pack;
    if (pack == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    try {
      final match = await CustomPackCorpusResolver.forWords(
        pack.words.map((word) => word.korean),
        fallbackWords: pack.words,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _corpus = match;
        _loading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pack = _pack;
    if (pack == null) {
      return Scaffold(
        appBar: SoriAppBar(title: t.vocabNotebookStudioTitle),
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

    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final selected = _selected;
    final match = _match;
    final nuanceCount = VocabNuanceService.questionsFor(
      selected,
      language: language,
    ).length;
    final surfaces = SoriSurfaces.of(context);

    return Scaffold(
      appBar: SoriAppBar(title: t.vocabNotebookStudioTitle),
      body: SafeArea(
        child: SoriCenterClamp(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Text(
                t.vocabNotebookStudioHint,
                style: SoriTextTheme.of(context).body,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SoriButton.ghost(
                      label: t.vocabNotebookStudioSelectAll,
                      onTap: () => setState(() {
                        _kept
                          ..clear()
                          ..addAll(pack.words.map((word) => word.korean));
                      }),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: SoriButton.ghost(
                      label: t.vocabNotebookStudioSelectNone,
                      onTap: () {
                        setState(() {
                          _kept.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              ...pack.words.map((word) {
                final kept = _kept.contains(word.korean);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: SoriCard(
                    variant: SoriCardVariant.compact,
                    accent: kept ? SoriColors.primary : SoriColors.info,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(word.korean, style: SoriTextTheme.of(context).h3),
                              const SizedBox(height: 2),
                              Text(
                                language == 'en' && word.translationEn.isNotEmpty
                                    ? word.translationEn
                                    : word.translationDe,
                                style: SoriTextTheme.of(context).bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: kept
                              ? t.vocabNotebookDropWord
                              : t.vocabNotebookKeepWord,
                          onPressed: () {
                            setState(() {
                              if (kept) {
                                _kept.remove(word.korean);
                              } else {
                                _kept.add(word.korean);
                              }
                            });
                          },
                          icon: Icon(
                            kept
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: kept ? SoriColors.primary : surfaces.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: Spacing.lg),
              Text(
                t.vocabNotebookStudioOwnGames,
                style: SoriTextTheme.of(context).h3,
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.filled(
                label: t.wbStudyCards,
                fullWidth: true,
                onTap: selected.isEmpty
                    ? null
                    : () => _openPage(
                        CustomPackPlayScreen(
                          packId: pack.id,
                          words: selected,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbMatching,
                fullWidth: true,
                onTap: selected.length < 2
                    ? null
                    : () => _openPage(
                        CustomPackMatchingScreen(
                          packId: pack.id,
                          words: selected,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbTyping,
                fullWidth: true,
                accent: SoriColors.accent,
                onTap: selected.isEmpty
                    ? null
                    : () => _openPage(
                        CustomPackTypingScreen(
                          packId: pack.id,
                          words: selected,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbQuiz,
                fullWidth: true,
                accent: SoriColors.accent,
                onTap: selected.length < 4
                    ? null
                    : () => _openPage(
                        CustomPackQuizScreen(
                          packId: pack.id,
                          words: selected,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.vocabNotebookNuanceCta,
                fullWidth: true,
                accent: SoriColors.goldOnLight,
                onTap: nuanceCount == 0
                    ? null
                    : () => _openPage(
                        VocabNuanceScreen(
                          packId: pack.id,
                          words: selected,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                t.vocabNotebookStudioCorpusGames,
                style: SoriTextTheme.of(context).h3,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                t.vocabNotebookStudioCorpusHint,
                style: SoriTextTheme.of(context).caption.copyWith(
                  color: surfaces.textMuted,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...<Widget>[
                SoriButton.outlined(
                  label: t.vocabNotebookStudioCloze(match.cloze.length),
                  fullWidth: true,
                  onTap: match.cloze.isEmpty
                      ? null
                      : () => _openPage(ClozeGameScreen(items: match.cloze)),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioSatz(match.satz.length),
                  fullWidth: true,
                  onTap: match.satz.isEmpty
                      ? null
                      : () => _openPage(SatzArcadeScreen(items: match.satz)),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioSpeed(match.vocab.length),
                  fullWidth: true,
                  onTap: match.vocab.length < 2
                      ? null
                      : () => _openPage(SpeedMatchScreen(items: match.vocab)),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioChosung(match.chosung.length),
                  fullWidth: true,
                  onTap: match.chosung.isEmpty
                      ? null
                      : () => _openPage(ChosungQuizScreen(deck: match.chosung)),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioSmalltalk(match.smalltalk.length),
                  fullWidth: true,
                  onTap: match.smalltalk.isEmpty
                      ? null
                      : () => _openPage(
                          SmalltalkScreen(phrases: match.smalltalk),
                        ),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioPronunciation(
                    match.pronunciation.length,
                  ),
                  fullWidth: true,
                  onTap: match.pronunciation.isEmpty
                      ? null
                      : () => _openPage(
                          PronunciationStudioScreen(
                            phrases: match.pronunciation,
                          ),
                        ),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioScenarios(match.scenarios.length),
                  fullWidth: true,
                  onTap: match.scenarios.isEmpty
                      ? null
                      : () => _openPage(
                          ScenariosListScreen(
                            loadScenarios: () async => match.scenarios,
                            ignoreLevelLock: true,
                          ),
                        ),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookStudioWordWeb(match.wordWeb.length),
                  fullWidth: true,
                  onTap: match.wordWeb.isEmpty
                      ? null
                      : () => _openPage(
                          WordWebScreen(
                            clusterLoader: () async => match.wordWeb,
                            seenLoader: () => {
                              for (final cluster in match.wordWeb)
                                cluster.sourceKo,
                            },
                          ),
                        ),
                ),
                if (!match.hasCuratedItems && selected.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.vocabNotebookStudioNoCorpus,
                    style: SoriTextTheme.of(context).caption.copyWith(
                      color: surfaces.textMuted,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
