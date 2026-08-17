import 'package:flutter/material.dart';

import '../data/hanja_lexicon.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/custom_pack.dart';
import '../services/book_ocr_document.dart';
import '../services/custom_pack_service.dart';
import '../services/vocab_notebook_parser.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

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
    _nameCtrl = TextEditingController(
      text: existing?.displayName() ?? '',
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.vocabNotebookSaveFailed)),
      );
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    if (_pairs.isEmpty) {
      return Scaffold(
        appBar: SoriAppBar(title: t.vocabNotebookTitle),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/book/book_error.png',
            icon: Icons.menu_book_outlined,
            title: t.vocabNotebookEmptyTitle,
            body: t.vocabNotebookEmptyBody,
            ctaLabel: t.bookPreviewRetake,
            onCta: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SoriAppBar(title: t.vocabNotebookTitle),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  t.vocabNotebookResultHint(_selected.length),
                  style: TextStyle(fontSize: 13, color: s.textMuted),
                ),
                const SizedBox(height: Spacing.md),
                if (_existingPackId == null) ...<Widget>[
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: t.bookshelfCreatePackName,
                      hintText: t.vocabNotebookDefaultName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: _pairs.length,
                    itemBuilder: (context, index) {
                      final pair = _pairs[index];
                      final kept = _kept.contains(index);
                      final hanja = HanjaLexicon.lookup(pair.korean);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: SoriCard(
                          variant: SoriCardVariant.compact,
                          accent: kept ? SoriColors.primary : SoriColors.info,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      pair.korean,
                                      style: SoriTextTheme.of(context).h3,
                                    ),
                                    if (hanja != null &&
                                        hanja.hanja.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 2),
                                      Text(
                                        hanja.hanja,
                                        style: SoriTextTheme.of(context)
                                            .bodySmall
                                            .copyWith(
                                              color: SoriColors.gold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      pair.meaning,
                                      style: SoriTextTheme.of(context).bodySmall,
                                    ),
                                    if (hanja != null &&
                                        hanja.nuanceFor(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'en'
                                              ? 'en'
                                              : 'de',
                                        ).isNotEmpty) ...<Widget>[
                                      const SizedBox(height: Spacing.xs),
                                      Text(
                                        hanja.nuanceFor(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'en'
                                              ? 'en'
                                              : 'de',
                                        ),
                                        style: SoriTextTheme.of(context)
                                            .caption
                                            .copyWith(color: s.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: kept
                                    ? t.vocabNotebookDropWord
                                    : t.vocabNotebookKeepWord,
                                onPressed: () {
                                  setState(() {
                                    if (kept) {
                                      _kept.remove(index);
                                    } else {
                                      _kept.add(index);
                                    }
                                  });
                                },
                                icon: Icon(
                                  kept
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: kept
                                      ? SoriColors.primary
                                      : s.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SoriButton.filled(
                  label: t.vocabNotebookPracticeCta,
                  fullWidth: true,
                  onTap: _selected.isEmpty || _saving
                      ? null
                      : () => _saveAndPractice(t),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.vocabNotebookAddPhoto,
                  fullWidth: true,
                  onTap: _selected.isEmpty || _saving
                      ? null
                      : () => _saveAndAddPhoto(t),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
