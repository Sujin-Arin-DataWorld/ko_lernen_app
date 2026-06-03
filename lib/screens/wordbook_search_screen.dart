import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';

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

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(t.wbSearchTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _all.isEmpty
            ? SoriEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: t.wbSearchTitle,
                body: t.wbSearchNoWords,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
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
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: Spacing.lg),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(t.wbPosAll),
                              selected: _pos == null,
                              onSelected: (_) => setState(() => _pos = null),
                            ),
                          ),
                          for (final p in posOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(p),
                                selected: _pos == p,
                                onSelected: (_) => setState(() => _pos = p),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.lg, Spacing.sm, Spacing.lg, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.wbSearchCount(results.length),
                        style: TextStyle(
                            color: s.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? Center(
                            child: Text(t.wbSearchEmpty,
                                style: TextStyle(color: s.textMuted)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xl),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: Spacing.sm),
                            itemBuilder: (_, i) => _WordRow(word: results[i]),
                          ),
                  ),
                ],
              ),
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
    final meaning =
        word.translationDe.isNotEmpty ? word.translationDe : word.translationEn;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        word.korean,
                        style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: s.text),
                      ),
                    ),
                    if (word.posDe.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: SoriColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(SoriRadius.pill),
                        ),
                        child: Text(
                          word.posDe,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: SoriColors.primaryOnLight),
                        ),
                      ),
                    ],
                  ],
                ),
                if (meaning.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meaning,
                      style: TextStyle(fontSize: 13, color: s.textMuted)),
                ],
                if (word.definitionKo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📖 ${word.definitionKo}',
                      style: TextStyle(fontSize: 12, color: s.textDim),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.volume_up_rounded,
                color: SoriColors.primary.withValues(alpha: 0.75)),
            onPressed: () => TtsService.speak(word.korean),
          ),
        ],
      ),
    );
  }
}
