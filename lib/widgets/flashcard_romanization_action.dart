import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Shared study preference for curated packs and the learner's saved cards.
class FlashcardRomanizationAction extends StatelessWidget {
  const FlashcardRomanizationAction({
    super.key,
    required this.onFront,
    required this.onChanged,
  });

  final bool onFront;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return PopupMenuButton<bool>(
      tooltip: t.flashcardRomanization,
      icon: const Icon(Icons.translate_rounded),
      initialValue: onFront,
      onSelected: onChanged,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: true,
          checked: onFront,
          child: Text(t.flashcardRomanizationFront),
        ),
        CheckedPopupMenuItem(
          value: false,
          checked: !onFront,
          child: Text(t.flashcardRomanizationBack),
        ),
      ],
    );
  }
}
