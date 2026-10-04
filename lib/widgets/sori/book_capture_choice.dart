import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'sheet.dart';
import 'tokens.dart';

/// Both photo entrances use the same descriptions and existing capture routes.
/// Returns the selected route after that route closes, or null when cancelled.
Future<String?> showBookCaptureChoice(BuildContext context) async {
  final t = AppL10n.of(context);
  final route = await showSoriSheet<String>(
    context: context,
    maxTextScaleFactor: 2,
    builder: (sheetContext) {
      final text = SoriTextTheme.of(sheetContext);
      final surfaces = SoriSurfaces.of(sheetContext);
      Widget option(String label, String description, String route) =>
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoriButton(
                  label: label,
                  variant: SoriButtonVariant.outlined,
                  fullWidth: true,
                  onTap: () => Navigator.of(sheetContext).pop(route),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  description,
                  style: text.bodySmall.copyWith(color: surfaces.textMuted),
                ),
              ],
            ),
          );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.myWordsPhotoSheetTitle, style: text.h3),
          const SizedBox(height: Spacing.lg),
          option(t.bookCaptureTitle, t.myWordsPhotoBookOptionSubtitle, '/book'),
          const SizedBox(height: Spacing.sm),
          option(
            t.vocabNotebookTitle,
            t.myWordsPhotoNotebookOptionSubtitle,
            '/vocab_notebook',
          ),
        ],
      );
    },
  );
  if (route != null && context.mounted) {
    await Navigator.of(context).pushNamed<void>(route);
  }
  return route;
}
