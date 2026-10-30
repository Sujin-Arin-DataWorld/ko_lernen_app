import 'practice_scholar_art.dart';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/smalltalk_context_case.dart';
import 'sori/card.dart';
import 'sori/tokens.dart';

class SmalltalkPracticeEntry extends StatelessWidget {
  const SmalltalkPracticeEntry({super.key, this.level});
  final String? level;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: SoriCard(
        key: const ValueKey('smalltalk-context-entry'),
        semanticLabel: AppL10n.of(context).practiceToneTitle,
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              height: 48,
              child: PracticeScholarArt(pose: PracticeScholarPose.inviting),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                AppL10n.of(context).practiceToneTitle,
                style: SoriTextTheme.of(context).label,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).pushNamed(
          '/smalltalk/context',
          arguments: SmalltalkContextRequest(level: level?.toLowerCase()),
        ),
      ),
    ),
  );
}
