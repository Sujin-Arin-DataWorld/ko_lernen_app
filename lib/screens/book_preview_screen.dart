import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.args['text'] as String? ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continue() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pushReplacementNamed(
      '/book/result',
      arguments: <String, dynamic>{
        'text': text,
        'imagePath': widget.args['imagePath'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final blockCount = widget.args['blockCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookPreviewTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
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
                          color: s.text.withValues(alpha: 0.20), width: 1),
                      borderRadius: BorderRadius.circular(SoriRadius.md),
                    ),
                    padding: const EdgeInsets.all(Spacing.md),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                          fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '한국어 텍스트…',
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
