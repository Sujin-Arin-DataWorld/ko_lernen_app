import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/scenario_can_do_result.dart';
import 'card.dart';
import 'tokens.dart';

/// Shows an outcome derived from a persisted scenario checkpoint. The card has
/// no action and no storage dependency, so it cannot turn a UI visit into
/// mastery or completion evidence.
class CanDoResultCard extends StatelessWidget {
  const CanDoResultCard({super.key, required this.result});

  final ScenarioCanDoResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final (
      IconData icon,
      Color accent,
      String title,
      String body,
    ) = switch (result.status) {
      ScenarioCanDoStatus.verified => (
        Icons.verified_outlined,
        SoriColors.success,
        t.scenarioCanDoVerifiedTitle,
        t.scenarioCanDoVerifiedBody,
      ),
      ScenarioCanDoStatus.reviewNeeded => (
        Icons.replay_outlined,
        SoriColors.warning,
        t.scenarioCanDoReviewTitle,
        t.scenarioCanDoReviewBody,
      ),
      ScenarioCanDoStatus.practiceOnly => (
        Icons.menu_book_outlined,
        SoriColors.primary,
        t.scenarioCanDoPracticeTitle,
        t.scenarioCanDoPracticeBody,
      ),
    };
    final canDo = result.isVerified
        ? result.courseUnit?.canDo.pick(languageCode)
        : null;

    return Semantics(
      container: true,
      label: title,
      child: ExcludeSemantics(
        child: SoriCard(
          variant: SoriCardVariant.base,
          accent: accent,
          tinted: true,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SoriTextTheme.of(
                        context,
                      ).h3.copyWith(color: accent),
                    ),
                    if (canDo != null && canDo.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        canDo,
                        style: SoriTextTheme.of(
                          context,
                        ).body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: Spacing.xs),
                    Text(body, style: SoriTextTheme.of(context).bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
