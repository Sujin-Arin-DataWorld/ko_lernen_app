import 'package:flutter/material.dart';

import '../data/hanja_lexicon.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/custom_pack.dart';
import '../services/book_ocr_document.dart';
import '../services/custom_pack_service.dart';
import '../services/vocab_notebook_parser.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// Review the exact pairs taken from a photographed vocabulary notebook,
/// then save them as a custom pack and start playful practice.
class VocabNotebookResultScreen extends StatefulWidget {
  const VocabNotebookResultScreen({super.key, required this.args});

  final Map<String, dynamic> args;

  @override
  State<VocabNotebookResultScreen> createState() =>
      _VocabNotebookResultScreenState();
}

class _VocabNotebookResultScreenState extends State<VocabNotebookResultScreen> {
  late final List<VocabNotebookPair> _pairs;
  late final Set<int> _kept;
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  String get _text => widget.args['text'] as String? ?? '';
  String? get _existingPackId => widget.args['existingPackId'] as String?;

  @override
  void initState() {
    super.initState();
    final document = widget.args['ocrDocument'] is BookOcrDocument
        ? widget.args['ocrDocument'] as BookOcrDocument
        : null;
    _pairs = VocabNotebookParser.parse(_text, document: document).pairs;
    _kept = <int>{for (var i = 0; i < _pairs.length; i++) i};
    final existing = _existingPackId == null
        ? null
        : CustomPackService.getById(_existingPackId!);
    _nameCtrl = TextEditingController(text: existing?.displayName() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<VocabNotebookPair> get _selected =>
      _kept.map((index) => _pairs[index]).toList(growable: false);

  Future<CustomPack?> _persist(AppL10n t) async {
    if (_selected.isEmpty || _saving) {
      return null;
    }
    setState(() => _saving = true);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final words = VocabNotebookParser.toExtractedWords(
      _selected,
      translationLanguage: language,
    );
    CustomPack? pack;
    final existingId = _existingPackId;
    if (existingId != null && CustomPackService.getById(existingId) != null) {
      pack = await CustomPackService.addWords(existingId, words);
    } else {
      var name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        name = t.vocabNotebookDefaultName;
      }
      pack = await CustomPackService.createFromWords(name: name, words: words);
    }
    if (!mounted) {
      return pack;
    }
    setState(() => _saving = false);
    if (pack == null) {
      soriToast(context, t.vocabNotebookSaveFailed);
    }
    return pack;
  }

  bool _isNotebookFlowRoute(Route<dynamic> route) {
    final name = route.settings.name;
    return name == '/vocab_notebook' ||
        name == '/book/preview' ||
        name == '/vocab_notebook/result' ||
        name == '/vocab_notebook/practice';
  }

  Future<void> _saveAndPractice(AppL10n t) async {
    final pack = await _persist(t);
    if (pack == null || !mounted) {
      return;
    }
    await Navigator.of(context).pushNamedAndRemoveUntil(
      '/vocab_notebook/practice',
      (route) => !_isNotebookFlowRoute(route),
      arguments: pack.id,
    );
  }

  Future<void> _saveAndAddPhoto(AppL10n t) async {
    final pack = await _persist(t);
    if (pack == null || !mounted) {
      return;
    }
    await Navigator.of(context).pushNamedAndRemoveUntil(
      '/vocab_notebook',
      (route) => !_isNotebookFlowRoute(route),
      arguments: <String, dynamic>{'existingPackId': pack.id},
    );
  }

  Widget _buildActions(AppL10n t) {
    final disabled = _selected.isEmpty || _saving;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoriButton.filled(
          label: t.vocabNotebookPracticeCta,
          fullWidth: true,
          onTap: disabled ? null : () => _saveAndPractice(t),
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton.outlined(
          label: t.vocabNotebookAddPhoto,
          fullWidth: true,
          onTap: disabled ? null : () => _saveAndAddPhoto(t),
        ),
      ],
    );
  }

  Widget _buildResultHeader(BuildContext context, AppL10n t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            t.vocabNotebookResultHint(_selected.length),
            style: SoriTextTheme.of(context).bodySmall,
          ),
        ),
        if (_existingPackId == null) ...[
          const SizedBox(height: Spacing.md),
          SoriTextField(
            controller: _nameCtrl,
            labelText: t.bookshelfCreatePackName,
            hintText: t.vocabNotebookDefaultName,
          ),
        ],
        const SizedBox(height: Spacing.md),
      ],
    );
  }

  Widget _buildPairCard(BuildContext context, AppL10n t, int index) {
    final pair = _pairs[index];
    final kept = _kept.contains(index);
    final hanja = HanjaLexicon.lookup(pair.korean);
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final nuance = hanja?.nuanceFor(language) ?? '';
    final actionLabel = kept
        ? t.vocabNotebookDropWord
        : t.vocabNotebookKeepWord;
    final surfaces = SoriSurfaces.of(context);
    void toggleKept() {
      setState(() {
        if (kept) {
          _kept.remove(index);
        } else {
          _kept.add(index);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: kept ? SoriColors.primary : SoriColors.info,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoriSpeakable(
                    text: pair.korean,
                    child: Text(
                      pair.korean,
                      style: SoriTextTheme.of(context).h3,
                    ),
                  ),
                  if (hanja != null && hanja.hanja.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hanja.hanja,
                      style: SoriTextTheme.of(context).bodySmall.copyWith(
                        color: surfaces.brightness == Brightness.light
                            ? SoriColors.goldOnLight
                            : SoriColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.xs),
                  Text(
                    pair.meaning,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                  if (nuance.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      nuance,
                      style: SoriTextTheme.of(
                        context,
                      ).caption.copyWith(color: surfaces.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Semantics(
              key: ValueKey('vocab-notebook-pair-toggle-$index'),
              container: true,
              button: true,
              selected: kept,
              label: actionLabel,
              onTap: toggleKept,
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: actionLabel,
                  constraints: const BoxConstraints(
                    minWidth: kMinInteractiveDimension,
                    minHeight: kMinInteractiveDimension,
                  ),
                  onPressed: toggleKept,
                  icon: Icon(
                    kept ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: kept ? SoriColors.primary : surfaces.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_pairs.isEmpty) {
      return SoriStandardFrame(
        appBarTitle: t.vocabNotebookTitle,
        maxWidth: SoriMaxWidth.form,
        padding: const EdgeInsets.all(Spacing.lg),
        builder: (context, resolvedPadding) => Padding(
          padding: resolvedPadding,
          child: Center(
            child: SoriEmptyState(
              asset: 'assets/illustrations/book/book_error.png',
              icon: Icons.menu_book_outlined,
              title: t.vocabNotebookEmptyTitle,
              body: t.vocabNotebookEmptyBody,
              ctaLabel: t.bookPreviewRetake,
              onCta: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final inlineActions =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
        MediaQuery.sizeOf(context).height < 700;
    final actions = _buildActions(t);

    return SoriStandardFrame(
      appBarTitle: t.vocabNotebookTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, resolvedPadding) {
        if (inlineActions) {
          return ListView(
            key: const ValueKey('vocab-notebook-result-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: resolvedPadding,
            children: [
              _buildResultHeader(context, t),
              for (var index = 0; index < _pairs.length; index++)
                _buildPairCard(context, t, index),
              const SizedBox(height: Spacing.md),
              actions,
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                resolvedPadding.left,
                resolvedPadding.top,
                resolvedPadding.right,
                0,
              ),
              child: _buildResultHeader(context, t),
            ),
            Expanded(
              child: ListView.builder(
                key: const ValueKey('vocab-notebook-result-scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  resolvedPadding.left,
                  0,
                  resolvedPadding.right,
                  resolvedPadding.bottom,
                ),
                itemCount: _pairs.length,
                itemBuilder: (context, index) =>
                    _buildPairCard(context, t, index),
              ),
            ),
          ],
        );
      },
      bottomNavigationBar: inlineActions
          ? null
          : SoriBottomActionArea(child: actions),
    );
  }
}
