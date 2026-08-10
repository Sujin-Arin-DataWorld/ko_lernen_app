import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'card.dart';
import 'tokens.dart';

/// A plain-language boundary between browsing a course and proving a can-do.
///
/// This is disclosure only. It never reads or writes progress, so placement
/// bypasses and history-only exploration cannot acquire a completion claim by
/// visiting the path.
class CourseProgressEvidenceNote extends StatelessWidget {
  const CourseProgressEvidenceNote({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: SoriColors.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.pathEvidenceTitle, style: text.label),
                const SizedBox(height: 2),
                Text(t.pathEvidenceBody, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
