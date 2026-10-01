import '../services/haptic_service.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/hangul_util.dart';
import 'sori/pressable.dart';
import 'sori/tokens.dart';

/// The first consonants and vowels learners combine in the basic Hangul chart.
/// Other letters remain available in the adjacent consonant/vowel grids.
const basicSyllableConsonants = <String>[
  'ㄱ',
  'ㄴ',
  'ㄷ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅅ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];
const basicSyllableVowels = <String>[
  'ㅏ',
  'ㅑ',
  'ㅓ',
  'ㅕ',
  'ㅗ',
  'ㅛ',
  'ㅜ',
  'ㅠ',
  'ㅡ',
  'ㅣ',
];

class HangulSyllableTable extends StatefulWidget {
  const HangulSyllableTable({super.key, required this.speak});

  final Future<bool> Function(String syllable) speak;

  @override
  State<HangulSyllableTable> createState() => _HangulSyllableTableState();
}

class _HangulSyllableTableState extends State<HangulSyllableTable> {
  final ScrollController _horizontalScroll = ScrollController();
  String _consonant = 'ㄱ';
  String _vowel = 'ㅏ';

  String get _syllable => composeHangulSyllable(_consonant, _vowel, '')!;

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _play(String syllable) async {
    try {
      await widget.speak(syllable);
    } catch (_) {
      // Audio errors are reported by the shared speech service. The chart
      // remains usable for reading and composing syllables while offline.
    }
  }

  void _select(String consonant, String vowel) {
    final syllable = composeHangulSyllable(consonant, vowel, '');
    if (syllable == null) {
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _consonant = consonant;
      _vowel = vowel;
    });
    unawaited(_play(syllable));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final type = SoriTextTheme.of(context);
    final extent = math.max(
      56.0,
      math.min(84.0, MediaQuery.textScalerOf(context).scale(28) + 24),
    );
    const gap = Spacing.sm;

    Widget header(String letter, {required bool consonant}) => Container(
      width: extent,
      height: extent,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: consonant
            ? SoriColors.info.withValues(alpha: 0.18)
            : SoriColors.gold.withValues(alpha: 0.20),
        borderRadius: SoriRadius.brSm,
      ),
      child: Text(
        letter,
        style: type.koDisplay.copyWith(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: surfaces.text,
        ),
      ),
    );

    Widget syllableCell(String consonant, String vowel) {
      final syllable = composeHangulSyllable(consonant, vowel, '')!;
      final selected = consonant == _consonant && vowel == _vowel;
      return Semantics(
        key: ValueKey('hangul-syllable-$syllable'),
        button: true,
        selected: selected,
        label: '$consonant + $vowel = $syllable',
        hint: t.hangulPronounceBtn,
        onTap: () => _select(consonant, vowel),
        child: ExcludeSemantics(
          child: SoriPressable(
            haptic: null,
            onTap: () => _select(consonant, vowel),
            child: Material(
              color: selected ? SoriColors.primary : surfaces.surface,
              shape: RoundedRectangleBorder(
                borderRadius: SoriRadius.brSm,
                side: BorderSide(
                  color: selected ? SoriColors.primaryDark : surfaces.border,
                ),
              ),
              child: SizedBox(
                width: extent,
                height: extent,
                child: Center(
                  child: Text(
                    syllable,
                    maxLines: 1,
                    style: type.koDisplay.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : surfaces.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.hangulSyllableTableHint, style: type.bodySmall),
        const SizedBox(height: Spacing.md),
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: surfaces.surface,
            borderRadius: SoriRadius.brLg,
            border: Border.all(color: surfaces.border),
          ),
          child: Row(
            children: [
              Text(
                _syllable,
                key: const Key('hangul-syllable-selected'),
                style: type.koDisplay.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: SoriColors.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  '$_consonant + $_vowel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(color: surfaces.textMuted),
                ),
              ),
              IconButton.filledTonal(
                tooltip: t.hangulPronounceBtn,
                onPressed: () => unawaited(_play(_syllable)),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(width: extent, height: extent + gap),
                for (final consonant in basicSyllableConsonants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: header(consonant, consonant: true),
                  ),
              ],
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Scrollbar(
                controller: _horizontalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: gap),
                        child: Row(
                          children: [
                            for (final vowel in basicSyllableVowels)
                              Padding(
                                padding: const EdgeInsets.only(right: gap),
                                child: header(vowel, consonant: false),
                              ),
                          ],
                        ),
                      ),
                      for (final consonant in basicSyllableConsonants)
                        Padding(
                          padding: const EdgeInsets.only(bottom: gap),
                          child: Row(
                            children: [
                              for (final vowel in basicSyllableVowels)
                                Padding(
                                  padding: const EdgeInsets.only(right: gap),
                                  child: syllableCell(consonant, vowel),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
