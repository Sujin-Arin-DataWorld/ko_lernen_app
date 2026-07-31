import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../services/cloze_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// **Lückentext (Cloze)** — das fehlende Wort im echten Satz wählen.
///
/// Kontext-Abruf schlägt isolierte Karteikarten (Forschung), füllt aktiv die
/// dünnen B1/B2-Inhalte, und ist für Erwachsene zufriedenstellender als reines
/// Wiedererkennen. Sätze + Übersetzungen stammen aus geprüften Vokabel-
/// Beispielen (assets/data/cloze.json).
class ClozeGameScreen extends StatefulWidget {
  const ClozeGameScreen({super.key});

  @override
  State<ClozeGameScreen> createState() => _ClozeGameScreenState();
}

class _ClozeGameScreenState extends State<ClozeGameScreen> {
  static const _roundSize = 10;
  static const _levels = ['a1', 'a2', 'b1', 'b2'];

  List<ClozeItem> _all = const [];
  bool _loading = true;
  String? _level; // null = alle
  int _roundId = 0;

  List<ClozeItem> _round = const [];
  int _idx = 0;
  int _score = 0;
  String? _picked;
  GameOutcome? _outcome;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ClozeLoader.load();
    if (!mounted) return;
    // Startlevel = Nutzerlevel, falls es dafür Items gibt; sonst alle.
    final user = Storage.userLevelCode;
    final start = (user != null && all.any((c) => c.level == user))
        ? user
        : null;
    setState(() {
      _all = all;
      _level = start;
      _loading = false;
    });
    _newRound();
  }

  void _newRound() {
    final pool = ClozeLoader.filter(_all, _level)..shuffle();
    setState(() {
      _roundId++;
      _round = pool.take(_roundSize).toList();
      _idx = 0;
      _score = 0;
      _picked = null;
      _outcome = null;
      _feedbackCompletion.reset();
    });
  }

  void _setLevel(String? level) {
    _level = level;
    _newRound();
  }

  void _pick(ClozeItem item, String option) {
    if (_picked != null) return;
    final ok = option == item.answer;
    setState(() => _picked = option);
    Storage.srsReview(item.answer, gotIt: ok); // Kontext-Abruf → Haupt-SRS
    if (ok) {
      _score++;
      HapticFeedback.lightImpact();
      SoundService.correct();
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
    }
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _idx++;
        _picked = null;
      });
      if (_idx >= _round.length) _finish();
    });
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.cloze(
        contentLabel: AppL10n.of(context).clozeTitle,
        level: _level,
        correct: _score,
        total: _round.length,
      ),
    );
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    final outcome = await recordGameResult(
      gameId: 'cloze',
      xp: _score * 5,
      score: pct,
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.clozeTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_round.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.clozeTitle)),
        body: SoriScreenBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: _levelBar(t),
                ),
                Expanded(
                  child: Center(
                    child: SoriEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: t.clozeTitle,
                      body: t.clozeEmptyBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_idx >= _round.length) {
      return _buildDone(t);
    }

    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final item = _round[_idx];
    final options = item.options(_roundId * 100 + _idx);
    final revealed = _picked != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.clozeTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriCenterClamp(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _levelBar(t),
                  Row(
                    children: [
                      SoriChip(
                        label: '${_idx + 1} / ${_round.length}',
                        accent: SoriColors.info,
                      ),
                      const Spacer(),
                      SoriChip(
                        label: t.quizScore(_score, _round.length),
                        accent: SoriColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    t.clozeInstruction,
                    style: TextStyle(fontSize: 13, color: s.textMuted),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriCard(
                    variant: SoriCardVariant.hero,
                    accent: SoriColors.primary,
                    tinted: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.lg,
                        horizontal: Spacing.sm,
                      ),
                      child: Column(
                        children: [
                          Text(
                            item.sentenceKo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            item.meaning(lang),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: s.textMuted),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, size: 24),
                            onPressed: () => TtsService.speak(item.fullKo),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final opt in options)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.sm,
                              ),
                              child: QuizChoice(
                                text: opt,
                                isCorrect: opt == item.answer,
                                isSelected: _picked == opt,
                                revealed: revealed,
                                onSelected: revealed
                                    ? null
                                    : () => _pick(item, opt),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelBar(AppL10n t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          _levelChip(t.clozeLevelAll, _level == null, () => _setLevel(null)),
          for (final lv in _levels) ...[
            const SizedBox(width: Spacing.sm),
            _levelChip(lv.toUpperCase(), _level == lv, () => _setLevel(lv)),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(String label, bool selected, VoidCallback onTap) {
    return SoriChip(
      label: label,
      accent: SoriColors.primary,
      selected: selected,
      variant: selected ? SoriChipVariant.filled : SoriChipVariant.soft,
      onTap: onTap,
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.clozeTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: GameOverCard(
            headline: t.quizResultTitle,
            scoreLabel: t.quizScore(_score, _round.length),
            feedbackContext: _feedbackCompletion.current?.context,
            xpGained: _score * 5,
            isNewBest: _outcome?.isNewBest ?? false,
            newBestLabel: t.gameNewBest,
            bestLabel: t.gameBestAccuracy(Storage.gameBest('cloze')),
            mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
            mascotEmotion: pct >= 50
                ? MascotEmotion.celebrate
                : MascotEmotion.worry,
            celebrate: pct >= 50, // schlechte Runde → kein Konfetti (Tonalität)
            actions: [
              SoriButton(
                label: t.quizAgain,
                icon: Icons.refresh_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: _newRound,
              ),
              SoriButton(
                label: t.btnClose,
                variant: SoriButtonVariant.ghost,
                fullWidth: true,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
