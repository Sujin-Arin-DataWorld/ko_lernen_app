import 'package:flutter/material.dart';

import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import 'celebration.dart';
import 'mascot.dart';
import 'tokens.dart';

/// Ergebnis einer Spielrunde — XP + persönliche Bestleistung.
class GameOutcome {
  final int xpGained;
  final int? best;
  final bool isNewBest;
  const GameOutcome({
    required this.xpGained,
    this.best,
    this.isNewBest = false,
  });
}

/// **Einheitliche Belohnung am Spielende.** XP gutschreiben, persönliche
/// Bestleistung aktualisieren, Abschluss-Sound spielen. Jedes Spiel ruft das
/// auf → ein konsistentes Dopamin-Loop statt zufälliger, halbfertiger
/// Belohnungen (genau das ließ die Spiele bisher "halbgar" wirken).
///
/// Selbst-Wettbewerb (persönliche Bestleistung) — **keine Ranglisten**
/// (Team-Regel: kompetitive Leaderboards = Dark-Pattern).
///
/// XP-Konvention (vom Aufrufer berechnet, hier dokumentiert für Konsistenz):
///   • Erkennen (Quiz/Matching): ×4 pro Treffer — Matching nur fehlerfrei voll.
///   • Abruf (Tippen/Cloze): ×5 pro Treffer (Abruf > Erkennen → kleine Prämie).
///   • Chosung: ×4 pro Runde-Treffer. Kkeunmari: Kettenlänge ×10 (20–500).
///   • Wordle: 10 + (übrige Versuche)×5 bei Sieg, 4 bei Niederlage.
Future<GameOutcome> recordGameResult({
  required String gameId,
  required int xp,
  int? score,
  bool higherIsBetter = true,
}) async {
  if (xp > 0) {
    await Storage.addXp(xp);
  }
  var isNewBest = false;
  int? best;
  if (score != null) {
    isNewBest = await Storage.recordGameBest(
      gameId,
      score,
      higherIsBetter: higherIsBetter,
    );
    best = Storage.gameBest(gameId);
  }
  SoundService.complete();
  return GameOutcome(xpGained: xp, best: best, isNewBest: isNewBest);
}

/// **GameOverCard** — einheitlicher, erwachsen-eleganter Abschluss-Körper.
///
/// Maskottchen + Schlagzeile + (optional) Punktestand + XP-Hochzählen +
/// (optional) Rekord-Badge, dazu ein einmaliger Konfetti-Burst beim Erscheinen
/// (reduce-motion-sicher). Spiele behalten ihr eigenes Scaffold; sie geben die
/// Buttons als [actions] hinein (untereinander, mit Abstand gerendert).
class GameOverCard extends StatefulWidget {
  final String headline;
  final String? scoreLabel;
  final int xpGained;

  /// Bereits formatierter Bestleistungs-Text, z. B. "Beste Genauigkeit: 90%".
  final String? bestLabel;
  final bool isNewBest;
  final String? newBestLabel; // z. B. "Neuer Rekord!"

  /// Optionaler Streak-Hinweis (🔥), getrennt vom Rekord-Trophäen-Slot.
  /// Für Konsistenz = "du warst dran" (nicht "gewonnen") → auch bei schwachem
  /// Score tonal stimmig.
  final String? streakLabel;

  final MascotKind mascotKind;
  final MascotEmotion mascotEmotion;
  final bool celebrate; // Burst beim Erscheinen
  final List<Widget> actions;

  const GameOverCard({
    super.key,
    required this.headline,
    required this.xpGained,
    this.scoreLabel,
    this.bestLabel,
    this.isNewBest = false,
    this.newBestLabel,
    this.streakLabel,
    this.mascotKind = MascotKind.tiger,
    this.mascotEmotion = MascotEmotion.celebrate,
    this.celebrate = true,
    this.actions = const [],
  });

  @override
  State<GameOverCard> createState() => _GameOverCardState();
}

class _GameOverCardState extends State<GameOverCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.celebrate) {
        SoriCelebration.burst(context);
      }
      if (SoriMotion.reduceMotion(context)) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Mascot(
                      kind: widget.mascotKind,
                      emotion: widget.mascotEmotion,
                      size: 104,
                      animate: true,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      widget.headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.scoreLabel != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        widget.scoreLabel!,
                        style: TextStyle(fontSize: 15, color: s.textMuted),
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) {
                        final shown = (widget.xpGained * _ctrl.value).round();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: SoriColors.gold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(
                              SoriRadius.pill,
                            ),
                            border: Border.all(
                              color: SoriColors.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '+$shown XP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: SoriColors.gold,
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.isNewBest && widget.newBestLabel != null) ...[
                      const SizedBox(height: Spacing.md),
                      Text(
                        '🏆 ${widget.newBestLabel!}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SoriColors.gold,
                        ),
                      ),
                    ] else if (widget.bestLabel != null) ...[
                      const SizedBox(height: Spacing.md),
                      Text(
                        widget.bestLabel!,
                        style: TextStyle(fontSize: 13, color: s.textMuted),
                      ),
                    ],
                    if (widget.streakLabel != null) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '🔥 ${widget.streakLabel!}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: SoriColors.tiger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          for (var i = 0; i < widget.actions.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            widget.actions[i],
          ],
        ],
      ),
    );
  }
}
