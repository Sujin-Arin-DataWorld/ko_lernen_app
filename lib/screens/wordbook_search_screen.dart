import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';

/// **Meine Wörter** (v2.0) — durchsucht ALLE selbst gespeicherten Wörter
/// (alle Custom-Packs zusammengeführt) per Text + Wortart-Filter (Kategorie).
class WordbookSearchScreen extends StatefulWidget {
  const WordbookSearchScreen({super.key});

  @override
  State<WordbookSearchScreen> createState() => _WordbookSearchScreenState();
}

class _WordbookSearchScreenState extends State<WordbookSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _pos; // null = Alle
  List<ExtractedWord> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Alle Custom-Pack-Wörter zusammenführen + per koreanischem String dedupen.
    final seen = <String>{};
    final words = <ExtractedWord>[];
    for (final p in CustomPackService.getAll()) {
      for (final w in p.words) {
        if (w.korean.trim().isEmpty) continue;
        if (seen.add(w.korean)) words.add(w);
      }
    }
    setState(() => _all = words);
  }

  List<String> get _posOptions {
    final set = <String>{};
    for (final w in _all) {
      if (w.posDe.trim().isNotEmpty) set.add(w.posDe.trim());
    }
    return set.toList()..sort();
  }

  List<ExtractedWord> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((w) {
      if (_pos != null && w.posDe.trim() != _pos) return false;
      if (q.isEmpty) return true;
      return w.korean.toLowerCase().contains(q) ||
          w.translationDe.toLowerCase().contains(q) ||
          w.translationEn.toLowerCase().contains(q) ||
          w.romanization.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final results = _filtered;
    final posOptions = _posOptions;

    return SoriStandardFrame(
      appBarTitle: t.wbSearchTitle,
      actions: const [TtsSpeedAction()],
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xl,
      ),
      builder: (context, pagePadding) => _all.isEmpty
          ? Padding(
              padding: pagePadding,
              child: SoriEmptyState(
                asset: 'assets/illustrations/mascot/magpie_wave.png',
                icon: Icons.bookmark_border_rounded,
                title: t.wbSearchTitle,
                body: t.wbSearchNoWords,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding.left,
                    pagePadding.top,
                    pagePadding.right,
                    Spacing.sm,
                  ),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: t.wbSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: s.surface,
                      border: const OutlineInputBorder(
                        borderRadius: SoriRadius.brMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (posOptions.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: pagePadding.left,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: Spacing.xs),
                            child: ChoiceChip(
                              label: Text(t.wbPosAll),
                              selected: _pos == null,
                              onSelected: (_) => setState(() => _pos = null),
                            ),
                          ),
                          for (final p in posOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: Spacing.xs),
                              child: ChoiceChip(
                                label: Text(p),
                                selected: _pos == p,
                                onSelected: (_) => setState(() => _pos = p),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding.left,
                    Spacing.sm,
                    pagePadding.right,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.wbSearchCount(results.length),
                      style: SoriTextTheme.of(
                        context,
                      ).caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Text(
                            t.wbSearchEmpty,
                            style: TextStyle(color: s.textMuted),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            pagePadding.left,
                            Spacing.sm,
                            pagePadding.right,
                            pagePadding.bottom,
                          ),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Spacing.sm),
                          itemBuilder: (_, i) => _WordRow(word: results[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final ExtractedWord word;
  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final meaning = word.translationDe.isNotEmpty
        ? word.translationDe
        : word.translationEn;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stackMetadata =
              constraints.maxWidth - kMinInteractiveDimension <
                  SoriAdaptiveWidth.criticalActionRow ||
              textScale >= 1.6;
          final titleAndPartOfSpeech = stackMetadata
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WordTitle(word: word),
                    if (word.posDe.trim().isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      _PartOfSpeech(label: word.posDe),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Flexible(child: _WordTitle(word: word)),
                    if (word.posDe.trim().isNotEmpty) ...[
                      const SizedBox(width: Spacing.sm),
                      Flexible(child: _PartOfSpeech(label: word.posDe)),
                    ],
                  ],
                );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleAndPartOfSpeech,
                    if (meaning.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        meaning,
                        style: TextStyle(fontSize: 13, color: s.textMuted),
                      ),
                    ],
                    if (word.definitionKo.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        word.definitionKo,
                        style: TextStyle(fontSize: 12, color: s.textDim),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: SoriColors.primary.withValues(alpha: 0.75),
                ),
                onPressed: () => TtsService.speak(word.korean),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WordTitle extends StatelessWidget {
  const _WordTitle({required this.word});

  final ExtractedWord word;

  @override
  Widget build(BuildContext context) =>
      Text(word.korean, style: SoriTextTheme.of(context).cardTitle);
}

class _PartOfSpeech extends StatelessWidget {
  const _PartOfSpeech({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.sm,
      vertical: Spacing.xs,
    ),
    decoration: BoxDecoration(
      color: SoriColors.primary.withValues(alpha: 0.12),
      borderRadius: SoriRadius.brPill,
    ),
    child: Text(
      label,
      style: SoriTextTheme.of(context).caption.copyWith(
        fontWeight: FontWeight.w700,
        color: SoriColors.primaryOnLight,
      ),
    ),
  );
}
