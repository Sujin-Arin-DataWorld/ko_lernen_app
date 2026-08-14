import '../../data/quest_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/dancheong_motif.dart';
import '../../services/quest_tracker.dart';
import '../../services/storage_service.dart';
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
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);

    // Counts for shortcuts
    final earned = Storage.earnedStamps.toSet();
    const motifs = DancheongMotif.values;
    final stampCount = motifs.where((m) => earned.contains(m.name)).length;

    final quests = QuestTracker.allWithProgress();
    final doneQuests = quests.where((q) => q.completed).length;
    final totalQuests = quests.where((q) => q.active || q.completed).length;

    final pendingBojagi = Storage.pendingRewardBoxesCount;

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
                      // 1. Quests tile
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: const RewardThumb(
                            slug: 'reward_roof_chwimi',
                            earned: true,
                          ),
                          title: t.soriStageQuests,
                          subtitle: '$doneQuests / $totalQuests',
                          onTap: () => Navigator.of(context).pushNamed('/quests'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      // 2. Dojang tile
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: Image.asset(
                            'assets/illustrations/stamps/stamp_lotus.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.approval_rounded,
                              size: 24,
                              color: SoriColors.primary,
                            ),
                          ),
                          title: t.soriStageDojang,
                          subtitle: t.dojangProgress(stampCount, motifs.length),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/dojangcheop'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      // 3. Bojagi tile
                      Expanded(
                        child: _HanokShortcutTile(
                          thumbnail: Image.asset(
                            'assets/illustrations/reward/reward_bojagi_closed.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.redeem_rounded,
                              size: 24,
                              color: SoriColors.goldOnLight,
                            ),
                          ),
                          title: t.soriStageBojagi,
                          subtitle: pendingBojagi > 0
                              ? '${t.soriStageBojagi} · $pendingBojagi'
                              : '-',
                          onTap: () => Navigator.of(context).pushNamed('/bojagi'),
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
  final Widget thumbnail;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HanokShortcutTile({
    required this.thumbnail,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: Center(child: thumbnail),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              title,
              style: tt.cardTitle.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: tt.caption.copyWith(
                color: s.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
