import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'practice_guide.dart';
import 'sori/button.dart';
import 'sori/card.dart';
import 'sori/tokens.dart';

/// Fixed learning entry. It consumes no room slot and grants no reward.
class HanokPracticeEntry extends StatelessWidget {
  const HanokPracticeEntry({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriCard(
      key: const ValueKey('sarangbang-practice-entry'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PracticeGuide(
            dokkaebi: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.practiceHistoryTitle,
                  style: SoriTextTheme.of(context).h3,
                ),
                Text(
                  t.practiceHistoryEmpty,
                  style: SoriTextTheme.of(context).body,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.outlined(
            label: t.practiceHistoryOpen,
            fullWidth: true,
            onTap: () => Navigator.of(context).pushNamed('/hanok/practice'),
          ),
        ],
      ),
    );
  }
}
