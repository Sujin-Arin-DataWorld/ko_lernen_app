import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/book_analysis_text.dart';
import '../services/book_image_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

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

  void _continue() {
    if (!_canAnalyze) {
      return;
    }
    final prepared = BookAnalysisTextPreprocessor.prepare(_ctrl.text);
    if (!prepared.hasKoreanText || !_mediaOwner.transfer()) {
      return;
    }
    try {
      Navigator.of(context).pushReplacementNamed(
        '/book/result',
        arguments: <String, dynamic>{
          'text': prepared.text,
          'imageLease': widget.args['imageLease'],
          'qualityWarnings': widget.args['qualityWarnings'],
          'severeQualityWarnings': widget.args['severeQualityWarnings'],
          'discardedBlockCount': widget.args['discardedBlockCount'],
          'ocrQuality': widget.args['ocrQuality'],
          'imageQuality': widget.args['imageQuality'],
          'textQualityWarnings': prepared.warnings,
          'qualityOverrideByTextEdit': _hasSevereCaptureWarning,
        },
      );
    } on Object {
      _mediaOwner.reclaim();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final blockCount = widget.args['blockCount'] as int? ?? 0;
    final qualityWarnings =
        (widget.args['qualityWarnings'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.bookPreviewTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.bookPreviewHint(blockCount),
                  style: TextStyle(fontSize: 13, color: s.textMuted),
                ),
                if (qualityWarnings.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: SoriColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(SoriRadius.sm),
                      border: Border.all(
                        color: SoriColors.warning.withValues(alpha: 0.35),
                      ),
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
                        Expanded(
                          child: Text(
                            _hasSevereCaptureWarning
                                ? t.bookPreviewSevereQualityWarning
                                : t.bookPreviewQualityWarning,
                            style: TextStyle(fontSize: 12, color: s.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                _BookPreviewImage(image: _previewImage),
                const SizedBox(height: Spacing.md),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: s.text.withValues(alpha: 0.20),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(SoriRadius.md),
                    ),
                    padding: const EdgeInsets.all(Spacing.md),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.bookPreviewTextFieldHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                SoriButton(
                  label: t.bookPreviewAnalyze,
                  icon: Icons.auto_awesome,
                  variant: SoriButtonVariant.filled,
                  accent: SoriColors.primary,
                  fullWidth: true,
                  onTap: _canAnalyze ? _continue : null,
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton(
                  label: t.bookPreviewRetake,
                  icon: Icons.replay_outlined,
                  variant: SoriButtonVariant.outlined,
                  accent: SoriColors.info,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPreviewImage extends StatelessWidget {
  const _BookPreviewImage({required this.image});

  final Future<File?> image;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Container(
      key: const ValueKey<String>('book-preview-image-frame'),
      height: bookPreviewImageMaxHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surfaces.surfaceAlt,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: surfaces.border),
      ),
      child: FutureBuilder<File?>(
        future: image,
        builder: (context, snapshot) {
          final file = snapshot.hasError ? null : snapshot.data;
          if (file == null) {
            return _BookPreviewImageFallback(color: surfaces.textDim);
          }
          return Image.file(
            file,
            key: const ValueKey<String>('book-preview-image'),
            width: double.infinity,
            height: bookPreviewImageMaxHeight,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                _BookPreviewImageFallback(color: surfaces.textDim),
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
