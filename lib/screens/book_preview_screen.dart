import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/book_image_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// Phase 5 (stately-rising-jongga) — OCR-Vorschau + Korrektur.
///
/// Args (Map): `{ text: String, blockCount: int, imagePath: String }`.
/// Nutzer kann den OCR-Text editieren bevor "Analysieren" → result.
class BookPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const BookPreviewScreen({super.key, required this.args});

  @override
  State<BookPreviewScreen> createState() => _BookPreviewScreenState();
}

class _BookPreviewScreenState extends State<BookPreviewScreen> {
  late final TextEditingController _ctrl;
  late final BookPreviewMediaOwner _mediaOwner;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.args['text'] as String? ?? '');
    _mediaOwner = BookPreviewMediaOwner(widget.args['imageLease'] as String?);
  }

  @override
  void dispose() {
    _mediaOwner.release().catchError((Object _) {});
    _ctrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_mediaOwner.transfer()) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _mediaOwner.reclaim();
      return;
    }
    try {
      Navigator.of(context).pushReplacementNamed(
        '/book/result',
        arguments: <String, dynamic>{
          'text': text,
          'imageLease': widget.args['imageLease'],
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
                  onTap: _continue,
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
