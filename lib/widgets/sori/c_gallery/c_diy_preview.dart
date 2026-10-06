import 'package:flutter/material.dart';

import 'c_materials.dart';

/// Read-only projection of an existing CustomPack. Integration supplies its ID
/// and usable translated word count; this preview never creates a saved pack.
class CGamePackSnapshot {
  const CGamePackSnapshot({
    required this.id,
    required this.title,
    required this.usableWordCount,
  }) : assert(usableWordCount >= 0);
  final String id;
  final String title;
  final int usableWordCount;
}

class CDiyPackChooser extends StatefulWidget {
  const CDiyPackChooser({
    super.key,
    required this.packs,
    required this.english,
    required this.onCollect,
    required this.onPlay,
  });
  final List<CGamePackSnapshot> packs;
  final bool english;
  final VoidCallback onCollect;
  final void Function(String packId, String mode) onPlay;

  @override
  State<CDiyPackChooser> createState() => _CDiyPackChooserState();
}

class _CDiyPackChooserState extends State<CDiyPackChooser> {
  String? selectedId;
  String t(String de, String en) => widget.english ? en : de;

  @override
  Widget build(BuildContext context) {
    final packs = widget.packs;
    final selected = packs.where((p) => p.id == selectedId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/illustrations/concept_c/diy_pieces.png',
          height: 165,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 10),
        Text(
          t('Deine Wörter. Dein Spiel.', 'Your words. Your game.'),
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: CPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          packs.isEmpty
              ? t(
                  'Speichere beim Lernen Wörter und spiele mit deinem eigenen Wortpaket.',
                  'Save words as you learn, then play with your own vocabulary pack.',
                )
              : t(
                  'Wähle dein gespeichertes Wortpaket.',
                  'Choose your saved pack.',
                ),
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 16,
            height: 1.35,
            color: CPalette.ink,
          ),
        ),
        const SizedBox(height: 16),
        if (packs.isEmpty)
          CMaterialAction(
            label: t('Wörter sammeln', 'Collect words'),
            gold: false,
            onTap: widget.onCollect,
          )
        else ...[
          for (final pack in packs) ...[
            CMaterialAction(
              label: '${pack.title} · ${pack.usableWordCount}',
              gold: selected?.id == pack.id,
              selected: selected?.id == pack.id,
              onTap: () => setState(() => selectedId = pack.id),
            ),
            const SizedBox(height: 10),
          ],
          if (selected != null) ...[
            const SizedBox(height: 8),
            for (final mode in const [
              ('cards', 'Karten', 'Cards', 1),
              ('matching', 'Paare finden', 'Match pairs', 2),
              ('typing', 'Diktat', 'Dictation', 1),
              ('quiz', 'Quiz', 'Quiz', 4),
            ]) ...[
              CMaterialAction(
                label: t(mode.$2, mode.$3),
                gold: false,
                onTap: selected.usableWordCount >= mode.$4
                    ? () => widget.onPlay(selected.id, mode.$1)
                    : null,
              ),
              if (selected.usableWordCount < mode.$4)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    t(
                      'Ab ${mode.$4} Wörtern mit Übersetzung.',
                      'Needs ${mode.$4} translated words.',
                    ),
                    style: const TextStyle(fontSize: 14, color: CPalette.ink),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ],
    );
  }
}
