import 'package:flutter/material.dart';

import '../../services/cloze_loader.dart';
import '../../services/tts_service.dart';
import 'card.dart';
import 'quiz_choice.dart';
import 'tokens.dart';

/// Ein Textstück der Übersetzung: [emph] = das gesuchte Wort (fett + Akzent).
class TextSegment {
  final String text;
  final bool emph;
  const TextSegment(this.text, this.emph);

  @override
  bool operator ==(Object other) =>
      other is TextSegment && other.text == text && other.emph == emph;

  @override
  int get hashCode => Object.hash(text, emph);

  @override
  String toString() => 'TextSegment("$text", emph: $emph)';
}

/// Teilt [sentence] am ersten Vorkommen der Bedeutung [gloss] auf, damit das
/// gesuchte Wort im Satz hervorgehoben werden kann. Rein & testbar.
///
/// - [gloss] wird an `/` in Kandidaten zerlegt (z.B. "lila / violett"),
///   Klammer-Zusätze `(...)` entfernt, getrimmt.
/// - Der erste Kandidat mit einem (Groß/Klein-egal) Teil-Treffer gewinnt.
/// - Kein Treffer / leeres gloss → ein einziges nicht-hervorgehobenes Segment
///   (Satz bleibt unversehrt, kein Crash).
List<TextSegment> splitEmphasis(String sentence, String? gloss) {
  if (sentence.isEmpty) return const [];
  final g = gloss?.trim() ?? '';
  if (g.isEmpty) return [TextSegment(sentence, false)];

  final candidates = <String>[];
  for (final part in [g, ...g.split('/')]) {
    final cleaned = part.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (cleaned.length >= 2 && !candidates.contains(cleaned)) {
      candidates.add(cleaned);
    }
  }

  final lower = sentence.toLowerCase();
  for (final cand in candidates) {
    final at = lower.indexOf(cand.toLowerCase());
    if (at < 0) continue;
    final end = at + cand.length;
    final segs = <TextSegment>[];
    if (at > 0) segs.add(TextSegment(sentence.substring(0, at), false));
    segs.add(TextSegment(sentence.substring(at, end), true)); // Original-Groß/Klein
    if (end < sentence.length) {
      segs.add(TextSegment(sentence.substring(end), false));
    }
    return segs;
  }
  return [TextSegment(sentence, false)];
}

/// Frage-Karte für Lückentext/Tages-Challenge: koreanischer Satz mit Lücke,
/// Übersetzung mit hervorgehobenem gesuchtem Wort, TTS.
class ClozePromptCard extends StatelessWidget {
  final ClozeItem item;
  final String lang;
  final String? gloss;
  const ClozePromptCard({
    super.key,
    required this.item,
    required this.lang,
    required this.gloss,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final baseStyle = TextStyle(fontSize: 15, color: s.textMuted, height: 1.4);
    final emphStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: SoriColors.primary,
      height: 1.4,
    );
    final segments = splitEmphasis(item.meaning(lang), gloss);

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.xl,
          horizontal: Spacing.md,
        ),
        child: Column(
          children: [
            Text(
              item.sentenceKo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.lg),
            Text.rich(
              TextSpan(
                children: [
                  for (final seg in segments)
                    TextSpan(
                      text: seg.text,
                      style: seg.emph ? emphStyle : baseStyle,
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 26),
              tooltip: 'TTS',
              onPressed: () => TtsService.speak(item.fullKo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Antwort-Optionen, die den verfügbaren vertikalen Raum großzügig füllen
/// (kein leerer unterer Bereich), aber bei großer Schrift scrollen.
class ClozeOptionsList extends StatelessWidget {
  final List<String> options;
  final String answer;
  final String? picked;
  final bool revealed;
  final void Function(String) onPick;
  const ClozeOptionsList({
    super.key,
    required this.options,
    required this.answer,
    required this.picked,
    required this.revealed,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final opt in options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                      child: QuizChoice(
                        text: opt,
                        isCorrect: opt == answer,
                        isSelected: picked == opt,
                        revealed: revealed,
                        onSelected: revealed ? null : () => onPick(opt),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
