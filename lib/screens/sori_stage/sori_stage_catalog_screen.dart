import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';

class SoriStageCatalogScreen extends StatelessWidget {
  const SoriStageCatalogScreen({super.key, required this.tab});

  final SoriStageTab tab;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final entries = soriActivityCatalog.where((entry) => entry.tab == tab);
    final isGames = tab == SoriStageTab.games;
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: 880,
            base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            builder: (context, padding) => ListView(
              padding: padding,
              children: [
                SoriStageRootHeader(
                  eyebrow: isGames ? t.soriStageNavGames : t.soriStageNavLearn,
                  title: isGames
                      ? t.soriStageGamesTitle
                      : t.soriStageLearnTitle,
                  body: isGames ? t.soriStageGamesBody : t.soriStageLearnBody,
                ),
                const SizedBox(height: Spacing.xl),
                for (final entry in entries) _ActivityListRow(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityListRow extends StatelessWidget {
  const _ActivityListRow({required this.entry});

  final ActivityCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final color = soriActivityColor(entry.colorRole);
    final title = localCopy(context, entry.title);
    final rewards = entry.reward.items
        .map((item) => localCopy(context, item.label))
        .join(' · ');
    final unlocked = entry.unlock.isUnlocked;
    return Semantics(
      button: unlocked,
      label: t.soriStageOpenActivity(title),
      child: InkWell(
        onTap: unlocked
            ? () => Navigator.of(
                context,
              ).pushNamed(entry.route, arguments: entry.arguments)
            : null,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(SoriRadius.md),
            border: Border.all(color: color.withValues(alpha: .55)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                ),
                child: Icon(
                  soriActivityIcon(entry.iconName),
                  color: _onColor(entry.colorRole),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          t.soriStageMinutes(entry.minutes),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(localCopy(context, entry.description)),
                    if (rewards.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.redeem_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${t.soriStagePossibleReward}: $rewards',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Icon(
                unlocked
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _onColor(SoriActivityColorRole role) => switch (role) {
    SoriActivityColorRole.speaking ||
    SoriActivityColorRole.reward ||
    SoriActivityColorRole.listening ||
    SoriActivityColorRole.review => SoriColors.lightText,
    _ => Colors.white,
  };
}
