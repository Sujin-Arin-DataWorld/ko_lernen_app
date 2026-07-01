import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/cloze_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// **Tages-Challenge (오늘의 도전)** — ein datums-gesetztes Lückentext-Puzzle.
///
/// Alle Nutzer:innen bekommen dasselbe Tagesset (Seed = Tag). Tägliche Gewohnheit
/// schlägt jede Einzel-Funktion (Forschung); Belohnung = Bonus-XP + persönlicher
/// Tages-Streak. **Keine Rangliste** (Selbst-Wettbewerb, kein Dark-Pattern).
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  /// Tages-Seed: lokale Tage seit Epoche → deterministisch. Lokal (nicht UTC),
  /// damit Puzzle-Tag und Streak-Tag (Storage nutzt lokales Datum) niemals
  /// um Mitternacht auseinanderlaufen.
  static int dailySeed(DateTime now) => DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(2020, 1, 1)).inDays;

  /// Deterministische Tagesauswahl (rein, testbar).
  static List<ClozeItem> pickDaily(List<ClozeItem> all, int seed, int count) {
    final copy = [...all]..shuffle(Random(seed));
    return copy.take(count).toList();
  }

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  static const _count = 10;
  static const _completionBonus = 20;

  List<ClozeItem> _round = const [];
  bool _loading = true;
  bool _alreadyDone = false; // heute schon erledigt → Übungsmodus, kein Bonus
  int _idx = 0;
  int _score = 0;
  String? _picked;
  GameOutcome? _outcome;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ClozeLoader.load();
    if (!mounted) return;
    final round = DailyChallengeScreen.pickDaily(
      all,
      DailyChallengeScreen.dailySeed(DateTime.now()),
      _count,
    );
    setState(() {
      _round = round;
      _alreadyDone = Storage.dailyChallengeDoneToday();
      _loading = false;
    });
  }

  void _pick(ClozeItem item, String option) {
    if (_picked != null) return;
    final ok = option == item.answer;
    setState(() => _picked = option);
    Storage.srsReview(item.answer, gotIt: ok);
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
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    // Bonus nur beim ERSTEN Abschluss heute (kein Doppel-Bonus beim Üben).
    final firstToday = !Storage.dailyChallengeDoneToday();
    final bonus = firstToday ? _completionBonus : 0;
    if (firstToday) {
      await Storage.markDailyChallengeDone();
    }
    final outcome = await recordGameResult(
      gameId: 'daily',
      xp: _score * 5 + bonus,
      score: pct,
    );
    if (mounted) {
      setState(() {
        _outcome = outcome;
        _streak = Storage.dailyChallengeStreak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.dailyTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Index-only Guard (wie cloze/satz_arcade): _outcome wird erst nach den
    // async SharedPreferences-Writes gesetzt — ohne diese Reihenfolge gäbe es
    // im Fenster _idx==length && _outcome==null einen RangeError auf _round[_idx].
    // _buildDone liest _outcome defensiv (?.), rendert also auch während des
    // kurzen Fensters korrekt.
    if (_idx >= _round.length) {
      return _buildDone(t);
    }
    if (_round.isEmpty) {
      // Defensive: cloze.json leer/fehlend → kein RangeError.
      return Scaffold(
        appBar: AppBar(title: Text(t.dailyTitle)),
        body: Center(
          child: Text(t.clozeEmptyBody, textAlign: TextAlign.center),
        ),
      );
    }

    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final item = _round[_idx];
    final options = item.options(
      DailyChallengeScreen.dailySeed(DateTime.now()) + _idx,
    );
    final revealed = _picked != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.dailyTitle,
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
                  if (_alreadyDone) ...[
                    SoriChip(
                      label: t.dailyAlreadyDone,
                      icon: Icons.check_circle_rounded,
                      accent: SoriColors.gold,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
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

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.dailyTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: GameOverCard(
            headline: t.quizResultTitle,
            scoreLabel: t.quizScore(_score, _round.length),
            // tatsächlich gutgeschriebener Wert (eine Quelle der Wahrheit).
            xpGained: _outcome?.xpGained ?? (_score * 5),
            // echter Genauigkeits-Rekord (vom recordGameResult), nicht der Streak.
            isNewBest: _outcome?.isNewBest ?? false,
            newBestLabel: t.gameNewBest,
            // Streak nur, wenn HEUTE neu abgeschlossen (nicht im Übungsmodus).
            streakLabel: _alreadyDone ? null : t.dailyStreak(_streak),
            mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
            mascotEmotion: pct >= 50
                ? MascotEmotion.celebrate
                : MascotEmotion.worry,
            celebrate: pct >= 50,
            actions: [
              SoriButton(
                label: t.btnClose,
                icon: Icons.check_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.gold,
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
