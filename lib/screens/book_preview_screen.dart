import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/book_analysis_text.dart';
import '../services/book_image_service.dart';
import '../services/book_ocr_document.dart';
import '../services/vocab_notebook_parser.dart';
import '../theme.dart';
import '../widgets/display_sized_file_image.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/viewport_pages.dart';
import '../widgets/sori/window_class.dart';

typedef BookPreviewImageResolver = Future<File?> Function(String? encodedLease);

const double bookPreviewImageMaxHeight = 160;

bool canAnalyzeBookPreviewText({
  required String initialText,
  required String currentText,
  required bool hasSevereCaptureWarning,
}) {
  final inspection = BookAnalysisTextPreprocessor.inspect(currentText);
  if (!inspection.isSafeEditedText) {
    return false;
  }
  if (!hasSevereCaptureWarning) {
    return true;
  }
  return _correctionEvidence(initialText) != _correctionEvidence(currentText);
}

String _correctionEvidence(String value) =>
    BookAnalysisTextPreprocessor.normalizeNfc(
      value,
    ).replaceAll(RegExp(r'[^A-Za-z0-9\u00C0-\u024F\uAC00-\uD7A3]'), '');

Future<File?> resolvePendingBookPreviewImage(String? encodedLease) async {
  try {
    final lease = PendingMediaLease.tryParse(encodedLease);
    if (lease == null || lease.kind != ManagedMediaKind.book) {
      return null;
    }
    return await (await BookImageService.store).resolvePending(lease);
  } on Object {
    return null;
  }
}

/// Phase 5 (stately-rising-jongga) — OCR-Vorschau + Korrektur.
///
/// Args (Map): `{ text: String, blockCount: int, imageLease: String }`.
/// Nutzer kann den OCR-Text editieren bevor "Analysieren" → result.
class BookPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  final BookPreviewImageResolver? imageResolver;

  const BookPreviewScreen({super.key, required this.args, this.imageResolver});

  @override
  State<BookPreviewScreen> createState() => _BookPreviewScreenState();
}

class _BookPreviewScreenState extends State<BookPreviewScreen> {
  late final TextEditingController _ctrl;
  late final BookPreviewMediaOwner _mediaOwner;
  late final Future<File?> _previewImage;
  late final String _initialText;
  late final bool _hasSevereCaptureWarning;
  late bool _canAnalyze;

  @override
  void initState() {
    super.initState();
    _initialText = widget.args['text'] as String? ?? '';
    _ctrl = TextEditingController(text: _initialText);
    _hasSevereCaptureWarning =
        (widget.args['severeQualityWarnings'] as List?)
            ?.whereType<String>()
            .isNotEmpty ??
        false;
    _canAnalyze = canAnalyzeBookPreviewText(
      initialText: _initialText,
      currentText: _ctrl.text,
      hasSevereCaptureWarning: _hasSevereCaptureWarning,
    );
    _ctrl.addListener(_validateText);
    final encodedLease = widget.args['imageLease'];
    final imageLease = encodedLease is String ? encodedLease : null;
    _mediaOwner = BookPreviewMediaOwner(imageLease);
    final imageResolver =
        widget.imageResolver ?? resolvePendingBookPreviewImage;
    _previewImage = Future<File?>.sync(() => imageResolver(imageLease));
  }

  @override
  void dispose() {
    _mediaOwner.release().catchError((Object _) {});
    _ctrl.removeListener(_validateText);
    _ctrl.dispose();
    super.dispose();
  }

  void _validateText() {
    final canAnalyze = canAnalyzeBookPreviewText(
      initialText: _initialText,
      currentText: _ctrl.text,
      hasSevereCaptureWarning: _hasSevereCaptureWarning,
    );
    if (canAnalyze == _canAnalyze || !mounted) {
      return;
    }
    setState(() => _canAnalyze = canAnalyze);
  }

  BookOcrDocument? get _currentDocument =>
      _ctrl.text == _initialText &&
          widget.args['ocrDocument'] is BookOcrDocument
      ? widget.args['ocrDocument'] as BookOcrDocument
      : null;

  bool get _useNotebookPath {
    final mode = widget.args['captureMode'] as String?;
    if (mode == 'notebook') {
      return true;
    }
    if (mode == 'textbook') {
      return false;
    }
    return VocabNotebookParser.parse(
      _ctrl.text,
      document: _currentDocument,
    ).looksLikeNotebook;
  }

  void _continue() {
    if (!_canAnalyze) {
      return;
    }
    final useNotebook = _useNotebookPath;
    final prepared = BookAnalysisTextPreprocessor.prepare(_ctrl.text);
    final notebookText = VocabNotebookParser.prepareText(_ctrl.text);
    final hasKorean = useNotebook
        ? BookAnalysisTextPreprocessor.containsHangulSyllable(notebookText)
        : prepared.hasKoreanText;
    if (!hasKorean || !_mediaOwner.transfer()) {
      return;
    }
    try {
      Navigator.of(context).pushReplacementNamed(
        useNotebook ? '/vocab_notebook/result' : '/book/result',
        arguments: <String, dynamic>{
          'text': useNotebook ? notebookText : prepared.text,
          'imageLease': widget.args['imageLease'],
          'qualityWarnings': widget.args['qualityWarnings'],
          'severeQualityWarnings': widget.args['severeQualityWarnings'],
          'discardedBlockCount': widget.args['discardedBlockCount'],
          'ocrQuality': widget.args['ocrQuality'],
          'imageQuality': widget.args['imageQuality'],
          'textQualityWarnings': useNotebook
              ? const <String>[]
              : prepared.warnings,
          'qualityOverrideByTextEdit': _hasSevereCaptureWarning,
          'ocrDocument': _currentDocument,
          if (widget.args['existingPackId'] is String)
            'existingPackId': widget.args['existingPackId'],
          if (useNotebook) 'captureMode': 'notebook',
        },
      );
    } on Object {
      _mediaOwner.reclaim();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args['captureMode'] == 'notebook') {
      return _buildPreview(context);
    }
    return Theme(
      data: AppTheme.light.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xff174d43),
          selectionColor: Color(0x553c886e),
          selectionHandleColor: Color(0xff174d43),
        ),
      ),
      child: Builder(builder: _buildPreview),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final t = AppL10n.of(context);
    final bookPaper = widget.args['captureMode'] != 'notebook';
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final blockCount = widget.args['blockCount'] as int? ?? 0;
    final qualityWarnings =
        (widget.args['qualityWarnings'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    final hint = _useNotebookPath
        ? t.vocabNotebookDesc
        : t.bookPreviewHint(blockCount);
    final warning = _hasSevereCaptureWarning
        ? t.bookPreviewSevereQualityWarning
        : qualityWarnings.isNotEmpty
        ? t.bookPreviewQualityWarning
        : null;

    return SoriStandardFrame(
      appBarTitle: t.bookPreviewTitle,
      cMaterial: bookPaper,
      cPaperBody: bookPaper,
      jadeAppBar: bookPaper,
      maxWidth: SoriMaxWidth.focus,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compactActions = keyboardOpen || viewport.maxHeight < 420;
            final analyze = SoriButton(
              cMaterial: bookPaper,
              label: _useNotebookPath
                  ? t.vocabNotebookPreviewCta
                  : t.bookPreviewAnalyze,
              icon: _useNotebookPath
                  ? Icons.menu_book_outlined
                  : Icons.auto_awesome,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.primary,
              fullWidth: true,
              onTap: _canAnalyze ? _continue : null,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, body) => _previewEditor(
                      context,
                      body,
                      hint: hint,
                      warning: warning,
                      keyboardOpen: keyboardOpen,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (compactActions)
                  Row(
                    children: [
                      Expanded(child: analyze),
                      const SizedBox(width: Spacing.sm),
                      IconButton(
                        tooltip: t.bookPreviewRetake,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.replay_outlined),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  )
                else ...[
                  analyze,
                  const SizedBox(height: Spacing.sm),
                  SoriButton(
                    cMaterial: bookPaper,
                    label: t.bookPreviewRetake,
                    icon: Icons.replay_outlined,
                    variant: SoriButtonVariant.outlined,
                    fullWidth: true,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    final body = SoriTextTheme.of(context).body;
    return Theme.of(context).platform == TargetPlatform.iOS
        ? body.copyWith(fontSize: 17)
        : body;
  }

  Widget _previewEditor(
    BuildContext context,
    BoxConstraints body, {
    required String hint,
    required String? warning,
    required bool keyboardOpen,
  }) {
    final t = AppL10n.of(context);
    final style = _bodyStyle(context);
    double textHeight(String text, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.localeOf(context),
      )..layout(maxWidth: width.clamp(1.0, double.infinity));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final hintHeight = textHeight(hint, body.maxWidth);
    final warningHeight = warning == null
        ? 0.0
        : textHeight(warning, body.maxWidth - 44) + Spacing.lg + 2;
    final noteHeight = hintHeight + warningHeight + Spacing.lg;
    const editorHeight = 88.0;
    final showPhoto =
        !keyboardOpen &&
        body.maxHeight >= noteHeight + bookPreviewImageMaxHeight + editorHeight;
    final showWarning =
        warning != null &&
        (showPhoto ||
            (!keyboardOpen &&
                body.maxHeight >= warningHeight + editorHeight + 56));
    final field = SoriTextField(
      controller: _ctrl,
      labelText: t.bookPreviewEditorLabel,
      hintText: t.bookPreviewTextFieldHint,
      alignLabelWithHint: true,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: style,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPhoto) ...[
          Text(hint, style: style),
          const SizedBox(height: Spacing.sm),
        ],
        if (showWarning) ...[
          _qualityWarning(warning, style),
          const SizedBox(height: Spacing.sm),
        ],
        if (showPhoto) ...[
          _BookPreviewImage(image: _previewImage),
          const SizedBox(height: Spacing.sm),
        ],
        Expanded(
          child: showPhoto
              ? field
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: Spacing.xs),
                    IconButton(
                      tooltip: t.onboardingJourneyPhotoAgain,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        warning != null && !showWarning
                            ? Icons.warning_amber_rounded
                            : Icons.image_outlined,
                      ),
                      onPressed: () => _showPreviewDetails(hint, warning),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _qualityWarning(String warning, TextStyle style) => Container(
    padding: const EdgeInsets.all(Spacing.sm),
    decoration: BoxDecoration(
      color: SoriColors.warning.withValues(alpha: 0.10),
      borderRadius: SoriRadius.brSm,
      border: Border.all(color: SoriColors.warning.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.fact_check_outlined,
          size: 18,
          color: SoriColors.warning,
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(warning, style: style)),
      ],
    ),
  );

  void _showPreviewDetails(String hint, String? warning) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
      context: context,
      builder: (context) {
        final t = AppL10n.of(context);
        final style = _bodyStyle(context);
        return Dialog(
          insetPadding: const EdgeInsets.all(Spacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.bookPreviewTitle,
                        style: SoriTextTheme.of(context).h3,
                      ),
                    ),
                    const CloseButton(),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, body) {
                      final textHeight = (body.maxHeight - 56).clamp(
                        1.0,
                        double.infinity,
                      );
                      return SoriViewportPages(
                        sections: [
                          for (final copy in [
                            if (warning != null) warning,
                            hint,
                          ])
                            for (final page in soriViewportTextPages(
                              context,
                              copy,
                              style: style,
                              width: body.maxWidth,
                              height: textHeight,
                            ))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.sm,
                                ),
                                child: Text(
                                  page,
                                  key: const ValueKey('book-preview-copy'),
                                  style: style,
                                ),
                              ),
                          _BookPreviewImage(
                            image: _previewImage,
                            height: bookPreviewImageMaxHeight.clamp(
                              0.0,
                              (body.maxHeight - 48).clamp(0.0, double.infinity),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookPreviewImage extends StatelessWidget {
  const _BookPreviewImage({
    required this.image,
    this.height = bookPreviewImageMaxHeight,
  });

  final Future<File?> image;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Container(
      key: const ValueKey<String>('book-preview-image-frame'),
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surfaces.surfaceAlt,
        borderRadius: SoriRadius.brMd,
        border: Border.all(color: surfaces.border),
      ),
      child: FutureBuilder<File?>(
        future: image,
        builder: (context, snapshot) {
          final file = snapshot.hasError ? null : snapshot.data;
          if (file == null) {
            return _BookPreviewImageFallback(color: surfaces.textDim);
          }
          return LayoutBuilder(
            builder: (context, constraints) => Image(
              image: DisplaySizedFileImage(
                file,
                constraints.biggest * MediaQuery.devicePixelRatioOf(context),
                BoxFit.contain,
              ),
              key: const ValueKey<String>('book-preview-image'),
              width: double.infinity,
              height: height,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  _BookPreviewImageFallback(color: surfaces.textDim),
            ),
          );
        },
      ),
    );
  }
}

class _BookPreviewImageFallback extends StatelessWidget {
  const _BookPreviewImageFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        key: const ValueKey<String>('book-preview-image-fallback'),
        size: 36,
        color: color,
      ),
    );
  }
}

class BookPreviewMediaOwner {
  BookPreviewMediaOwner(
    this.encodedLease, {
    Future<void> Function(String? encoded)? discard,
  }) : _discard = discard ?? BookImageService.discardEncoded;

  final String? encodedLease;
  final Future<void> Function(String? encoded) _discard;
  _BookPreviewOwnership _ownership = _BookPreviewOwnership.owned;

  bool transfer() {
    if (_ownership != _BookPreviewOwnership.owned) {
      return false;
    }
    _ownership = _BookPreviewOwnership.transferred;
    return true;
  }

  void reclaim() {
    if (_ownership == _BookPreviewOwnership.transferred) {
      _ownership = _BookPreviewOwnership.owned;
    }
  }

  Future<void> release() {
    if (_ownership != _BookPreviewOwnership.owned) {
      return Future<void>.value();
    }
    _ownership = _BookPreviewOwnership.released;
    return _discard(encodedLease);
  }
}

enum _BookPreviewOwnership { owned, transferred, released }
