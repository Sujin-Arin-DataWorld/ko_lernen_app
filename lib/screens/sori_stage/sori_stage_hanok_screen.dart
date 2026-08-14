import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../data/quest_catalog.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../hanok_world_screen.dart';
import 'sori_stage_common.dart';

class SoriStageHanokScreen extends StatelessWidget {
  const SoriStageHanokScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              SoriContentClamp(
                maxWidth: 960,
                base: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                builder: (context, padding) => Padding(
                  padding: padding,
                  child: SoriStageRootHeader(
                    eyebrow: t.soriStageNavHanok,
                    title: t.soriStageHanokTitle,
                    body: t.soriStageHanokBody,
                  ),
                ),
              ),
              Expanded(child: HanokWorldScreen(embedded: true)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: SoriRewardThumb(
                            slug: kQuestCatalog.first.decorationSlug,
                            size: 40,
                          ),
                          label: t.soriStageQuests,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/quests'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: Image.asset(
                            'assets/illustrations/stamps/stamp_lotus.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.approval_outlined, size: 32),
                          ),
                          label: t.soriStageDojang,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/dojangcheop'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: Image.asset(
                            'assets/illustrations/reward/reward_bojagi_closed.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.redeem_rounded, size: 32),
                          ),
                          label: t.soriStageBojagi,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/bojagi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HanokShortcutTile extends StatelessWidget {
  const _HanokShortcutTile({
    required this.thumbnail,
    required this.label,
    required this.onTap,
  });

  final Widget thumbnail;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            thumbnail,
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SoriTextTheme.of(context).cardTitle,
            ),
          ],
        ),
      ),
    );
  }
}
