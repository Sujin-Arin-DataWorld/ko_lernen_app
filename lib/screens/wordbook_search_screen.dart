import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/custom_pack_service.dart';
import '../services/data_loader.dart';
import '../services/saved_word_localization.dart';
import '../services/tts_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';

/// **Meine Wörter** (v2.0) — durchsucht ALLE selbst gespeicherten Wörter
/// (alle Custom-Packs zusammengeführt) per Text + Wortart-Filter (Kategorie).
class WordbookSearchScreen extends StatelessWidget {
  const WordbookSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
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
      builder: (context, pagePadding) =>
          WordbookSearchBody(padding: pagePadding),
    );
  }
}

/// Search content that can be hosted by a route frame or a tab hub.
class WordbookSearchBody extends StatefulWidget {
  const WordbookSearchBody({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.md,
      Spacing.lg,
      Spacing.xl,
    ),
  });

  final EdgeInsets padding;

  @override
  State<WordbookSearchBody> createState() => _WordbookSearchBodyState();
}

class _WordbookSearchBodyState extends State<WordbookSearchBody> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _pos; // null = Alle
  List<ExtractedWord> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    final vocab = await DataLoader.loadVocab();
    if (mounted) {
      setState(
        () =>
            _all = words.map((word) => localizeSavedWord(word, vocab)).toList(),
      );
    }
  }

  void _clearQuery() {
    _ctrl.clear();
    setState(() => _query = '');
  }

  List<String> get _posOptions {
    final set = <String>{};
    for (final w in _all) {
      if (w.posFor(Localizations.localeOf(context).languageCode).isNotEmpty) {
        set.add(w.posDe.trim());
      }
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
    final results = _filtered;
    final posOptions = _posOptions;
    final filterMaxHeight = MediaQuery.sizeOf(context).height < 700
        ? 112.0
        : 160.0;
    final pagePadding = widget.padding;

    return _all.isEmpty
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
                child: SoriTextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _query = v),
                  hintText: t.wbSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : Semantics(
                          container: true,
                          button: true,
                          enabled: true,
                          label: t.wbSearchClear,
                          onTap: _clearQuery,
                          excludeSemantics: true,
                          child: IconButton(
                            tooltip: t.wbSearchClear,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearQuery,
                          ),
                        ),
                ),
              ),
              if (posOptions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
                  child: LayoutBuilder(
                    builder: (context, constraints) => ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: filterMaxHeight),
                      child: SingleChildScrollView(
                        key: const ValueKey('wordbook-pos-filter-scroll'),
                        primary: false,
                        child: Wrap(
                          spacing: Spacing.xs,
                          runSpacing: Spacing.xs,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: SoriChip(
                                key: const ValueKey('wordbook-pos-all'),
                                label: t.wbPosAll,
                                selected: _pos == null,
                                icon: _pos == null ? Icons.check_rounded : null,
                                variant: SoriChipVariant.outlined,
                                idleBorderColor:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? SoriColors.lightBorderStrong
                                    : SoriColors.darkBorderStrong,
                                maxLines: null,
                                minInteractiveHeight: 48,
                                onTap: () => setState(() => _pos = null),
                              ),
                            ),
                            for (final p in posOptions)
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: SoriChip(
                                  key: ValueKey('wordbook-pos-$p'),
                                  label: _all
                                      .firstWhere(
                                        (word) => word.posDe.trim() == p,
                                      )
                                      .posFor(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
                                      ),
                                  selected: _pos == p,
                                  icon: _pos == p ? Icons.check_rounded : null,
                                  variant: SoriChipVariant.outlined,
                                  idleBorderColor:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? SoriColors.lightBorderStrong
                                      : SoriColors.darkBorderStrong,
                                  maxLines: null,
                                  minInteractiveHeight: 48,
                                  onTap: () => setState(() => _pos = p),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: t.wbSearchCount(results.length),
                    excludeSemantics: true,
                    child: Text(
                      t.wbSearchCount(results.length),
                      style: SoriTextTheme.of(
                        context,
                      ).caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? SoriEmptyState(
                        icon: Icons.search_off_rounded,
                        title: t.wbSearchEmpty,
                        illustrationMaxHeight: 120,
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
          );
  }
}

class _WordRow extends StatelessWidget {
  final ExtractedWord word;
  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final translation = word.translationFor(languageCode);
    final meaning = translation.isNotEmpty
        ? translation
        : t.savedTranslationUnavailable;
    final partOfSpeech = word.posFor(languageCode);
    final ttsLabel = '${t.ttsListen}: ${word.korean}';
    void speak() {
      // ignore: discarded_futures
      TtsService.speak(word.korean);
    }

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
                    if (partOfSpeech.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      _PartOfSpeech(label: partOfSpeech),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Flexible(child: _WordTitle(word: word)),
                    if (partOfSpeech.isNotEmpty) ...[
                      const SizedBox(width: Spacing.sm),
                      Flexible(child: _PartOfSpeech(label: partOfSpeech)),
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
                        style: SoriTextTheme.of(
                          context,
                        ).bodySmall.copyWith(color: s.textMuted),
                      ),
                    ],
                    if (word.definitionKo.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        word.definitionKo,
                        style: SoriTextTheme.of(
                          context,
                        ).caption.copyWith(color: s.textDim),
                      ),
                    ],
                  ],
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: true,
                label: ttsLabel,
                onTap: speak,
                excludeSemantics: true,
                child: IconButton(
                  tooltip: ttsLabel,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: SoriColors.primary.withValues(alpha: 0.75),
                  ),
                  onPressed: speak,
                ),
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
  Widget build(BuildContext context) => SoriChip(
    label: label,
    maxLines: null,
    accent: SoriColors.primary,
    variant: SoriChipVariant.soft,
  );
}
