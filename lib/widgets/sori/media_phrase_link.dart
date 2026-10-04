import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class SoriMediaPhraseLink extends StatelessWidget {
  const SoriMediaPhraseLink({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: const ValueKey('media-phrase-entry'),
      onPressed: () => Navigator.of(context).pushNamed('/media_phrases'),
      icon: const Icon(Icons.play_circle_outline_rounded),
      label: Text(AppL10n.of(context).mediaPhraseTitle),
    ),
  );
}
