import '../data/canonical_companion_art.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/custom_pack_service.dart';
import '../services/data_loader.dart';
import '../services/saved_word_localization.dart';
import '../services/tts_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/viewport_pages.dart';
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
    this.boundNotebook = false,
    this.keyboardOpen = false,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.md,
      Spacing.lg,
      Spacing.xl,
    ),
  });

  final EdgeInsets padding;
  final bool boundNotebook;
  final bool keyboardOpen;

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
    // Keep every saved meaning until the active display language is known.
    // Pack recency must not discard a translation that another pack contains.
    final words = <ExtractedWord>[];
    for (final p in CustomPackService.getAll()) {
      for (final w in p.words) {
        if (w.korean.trim().isEmpty) {
          continue;
        }
        words.add(w);
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

  List<ExtractedWord> get _wordsForCurrentLanguage {
    final language = Localizations.localeOf(context).languageCode;
    final byKorean = <String, ExtractedWord>{};
    for (final word in _all) {
      final korean = word.korean.trim();
      final previous = byKorean[korean];
      if (previous == null ||
          (previous.translationFor(language).trim().isEmpty &&
              word.translationFor(language).trim().isNotEmpty)) {
        byKorean[korean] = word;
      }
    }
    return byKorean.values.toList();
  }

  void _clearQuery() {
    _ctrl.clear();
    setState(() => _query = '');
  }

  List<String> get _posOptions {
    final set = <String>{};
    for (final w in _wordsForCurrentLanguage) {
      if (w.posFor(Localizations.localeOf(context).languageCode).isNotEmpty) {
        set.add(w.posDe.trim());
      }
    }
    return set.toList()..sort();
  }

  List<ExtractedWord> _filtered(String? selectedPos) {
    final q = _query.trim().toLowerCase();
    return _wordsForCurrentLanguage.where((w) {
      if (selectedPos != null && w.posDe.trim() != selectedPos) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
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
    final posOptions = _posOptions;
    // A locale change can choose a duplicate with different POS metadata. Only
    // apply filters that are still visible, including for the selected chip.
    final selectedPos = posOptions.contains(_pos) ? _pos : null;
    final results = _filtered(selectedPos);
    final filterMaxHeight = MediaQuery.sizeOf(context).height < 700
        ? 112.0
        : 160.0;
    final pagePadding = widget.padding;
    if (widget.boundNotebook && _all.isNotEmpty) {
      return _boundedSearch(context, t, posOptions, selectedPos, results);
    }

    return _all.isEmpty
        ? Padding(
            padding: pagePadding,
            child: SoriEmptyState(
              asset: CanonicalCompanionArt.magpieGuide,
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
                child: _queryField(t),
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
                                selected: selectedPos == null,
                                icon: selectedPos == null
                                    ? Icons.check_rounded
                                    : null,
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
                                  selected: selectedPos == p,
                                  icon: selectedPos == p
                                      ? Icons.check_rounded
                                      : null,
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
                  child: _resultCount(context, t, results.length),
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
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Spacing.sm),
                        itemBuilder: (_, i) =>
                            _WordRow(word: results[i], onBookPage: false),
                      ),
              ),
            ],
          );
  }

  Widget _queryField(AppL10n t) => SoriTextField(
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
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.clear_rounded),
              onPressed: _clearQuery,
            ),
          ),
  );

  Widget _resultCount(BuildContext context, AppL10n t, int count) => Semantics(
    container: true,
    liveRegion: true,
    label: t.wbSearchCount(count),
    excludeSemantics: true,
    child: Text(
      t.wbSearchCount(count),
      style: SoriTextTheme.of(
        context,
      ).caption.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _boundedSearch(
    BuildContext context,
    AppL10n t,
    List<String> posOptions,
    String? selectedPos,
    List<ExtractedWord> results,
  ) {
    final keyboardOpen = widget.keyboardOpen;
    final padding = widget.padding;
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        keyboardOpen ? 0 : padding.top,
        padding.right,
        Spacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _queryField(t)),
              if (posOptions.isNotEmpty) ...[
                const SizedBox(width: Spacing.xs),
                IconButton(
                  tooltip: t.filterOpenBtn,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  isSelected: selectedPos != null,
                  icon: const Icon(Icons.filter_list_rounded),
                  selectedIcon: const Icon(Icons.filter_alt_rounded),
                  onPressed: () =>
                      _pickPartOfSpeech(t, posOptions, selectedPos),
                ),
              ],
            ],
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: _resultCount(context, t, results.length),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, body) {
                if (results.isEmpty) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      t.wbSearchEmpty,
                      style: SoriTextTheme.of(context).body,
                    ),
                  );
                }
                final showBook =
                    !keyboardOpen &&
                    body.maxWidth >= SoriBreakpoints.wordbookOpenBook &&
                    body.maxHeight >= 350 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 20;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    image: showBook
                        ? const DecorationImage(
                            image: AssetImage(
                              'design_assets/scenarios/open-book.png',
                            ),
                            fit: BoxFit.fill,
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: showBook
                        ? const EdgeInsets.fromLTRB(30, 24, 20, 24)
                        : const EdgeInsets.only(top: Spacing.xs),
                    child: LayoutBuilder(
                      builder: (context, page) => SoriViewportPages(
                        key: ValueKey((_query, selectedPos, language)),
                        sections: [
                          for (final word in results)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.xs,
                              ),
                              child: _resultRow(context, word, page, showBook),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    BuildContext context,
    ExtractedWord word,
    BoxConstraints page,
    bool showBook,
  ) {
    final entries = _wordText(context, word, showBook: showBook);
    final width = (page.maxWidth - 80).clamp(1.0, double.infinity);
    var height = 48.0;
    for (final (text, style) in entries) {
      if (text.trim().isEmpty) {
        continue;
      }
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.localeOf(context),
      )..layout(maxWidth: width);
      height += painter.height + Spacing.xs;
      painter.dispose();
    }
    return _WordRow(
      word: word,
      onBookPage: showBook,
      bounded: true,
      openDetails: height > page.maxHeight - 48
          ? () => _showWordDetails(word)
          : null,
    );
  }

  List<(String, TextStyle)> _wordText(
    BuildContext context,
    ExtractedWord word, {
    bool showBook = false,
  }) {
    final type = SoriTextTheme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final translation = word.translationFor(language);
    return [
      (
        word.korean,
        showBook ? type.koDisplay.copyWith(fontSize: 22) : type.cardTitle,
      ),
      (word.posFor(language), type.caption),
      (
        translation.isNotEmpty
            ? translation
            : AppL10n.of(context).savedTranslationUnavailable,
        _boundedBodyStyle(context),
      ),
      (word.exampleKorean, _boundedBodyStyle(context)),
      (word.definitionKo, type.caption),
    ];
  }

  void _pickPartOfSpeech(AppL10n t, List<String> options, String? selected) {
    final language = Localizations.localeOf(context).languageCode;
    final labels = {
      for (final word in _wordsForCurrentLanguage)
        word.posDe.trim(): word.posFor(language),
    };
    _showPages(
      t.filterTitle,
      (context, body) => [
        for (final option in <String?>[null, ...options])
          ListTile(
            title: Text(option == null ? t.wbPosAll : labels[option] ?? option),
            selected: selected == option,
            trailing: selected == option
                ? const Icon(Icons.check_rounded)
                : null,
            minTileHeight: 48,
            onTap: () {
              setState(() => _pos = option);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  void _showWordDetails(ExtractedWord word) {
    _showPages(
      AppL10n.of(context).catalogDetails,
      (context, body) => [
        for (final (text, style) in _wordText(context, word))
          if (text.trim().isNotEmpty)
            for (final page in soriViewportTextPages(
              context,
              text,
              style: style,
              width: body.maxWidth,
              height: (body.maxHeight - 56).clamp(1.0, double.infinity),
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(page, style: style),
              ),
      ],
    );
  }

  void _showPages(
    String title,
    List<Widget> Function(BuildContext context, BoxConstraints body) sections,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    showSoriDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: SoriTextTheme.of(context).h3),
                  ),
                  const CloseButton(),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, body) =>
                      SoriViewportPages(sections: sections(context, body)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _boundedBodyStyle(BuildContext context) {
  final style = SoriTextTheme.of(context).body;
  return Theme.of(context).platform == TargetPlatform.iOS
      ? style.copyWith(fontSize: 17)
      : style;
}

class _WordRow extends StatelessWidget {
  final ExtractedWord word;
  final bool onBookPage;
  final bool bounded;
  final VoidCallback? openDetails;
  const _WordRow({
    required this.word,
    required this.onBookPage,
    this.bounded = false,
    this.openDetails,
  });

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
    final bodyStyle = bounded
        ? _boundedBodyStyle(context)
        : SoriTextTheme.of(context).bodySmall;
    final ttsLabel = '${t.ttsListen}: ${word.korean}';
    void speak() {
      // ignore: discarded_futures
      TtsService.speak(word.korean);
    }

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stackMetadata =
            constraints.maxWidth - kMinInteractiveDimension <
                SoriAdaptiveWidth.criticalActionRow ||
            textScale >= 1.6;
        final titleAndPartOfSpeech = openDetails != null
            ? _WordTitle(word: word, onBookPage: onBookPage, brief: true)
            : stackMetadata
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WordTitle(word: word, onBookPage: onBookPage),
                  if (partOfSpeech.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    _PartOfSpeech(label: partOfSpeech),
                  ],
                ],
              )
            : Row(
                children: [
                  Flexible(
                    child: _WordTitle(word: word, onBookPage: onBookPage),
                  ),
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
                  if (openDetails == null && meaning.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      meaning,
                      style: bodyStyle.copyWith(color: s.textMuted),
                    ),
                  ],
                  if (openDetails == null &&
                      word.exampleKorean.trim().isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(word.exampleKorean, style: bodyStyle),
                  ],
                  if (openDetails == null && word.definitionKo.isNotEmpty) ...[
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
            if (openDetails != null)
              IconButton(
                tooltip: t.catalogDetails,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: openDetails,
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
                style: onBookPage
                    ? IconButton.styleFrom(
                        backgroundColor: const Color(0xff174d43),
                        side: const BorderSide(
                          color: Color(0xffae844a),
                          width: 1.5,
                        ),
                      )
                    : null,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: onBookPage
                      ? const Color(0xfffaf1df)
                      : SoriColors.primary.withValues(alpha: 0.75),
                ),
                onPressed: speak,
              ),
            ),
          ],
        );
      },
    );
    return onBookPage
        ? Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: content,
          )
        : SoriCard(variant: SoriCardVariant.base, child: content);
  }
}

class _WordTitle extends StatelessWidget {
  const _WordTitle({
    required this.word,
    required this.onBookPage,
    this.brief = false,
  });

  final ExtractedWord word;
  final bool onBookPage;
  final bool brief;

  @override
  Widget build(BuildContext context) {
    final type = SoriTextTheme.of(context);
    return Text(
      word.korean,
      style: onBookPage
          ? type.koDisplay.copyWith(fontSize: 22, fontWeight: FontWeight.w700)
          : type.cardTitle,
    );
  }
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
