import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/decoration_reward_service.dart';
import '../../services/quest_tracker.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../bojagi_screen.dart';
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
              const SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _HanokShortcuts(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HanokShortcuts extends StatefulWidget {
  const _HanokShortcuts();

  @override
  State<_HanokShortcuts> createState() => _HanokShortcutsState();
}

class _HanokShortcutsState extends State<_HanokShortcuts> {
  String? _questCount;
  late final String _stampCount;
  late final String _bojagiCount;

  @override
  void initState() {
    super.initState();
    final earned = Storage.earnedStamps.toSet();
    _stampCount =
        '${DancheongMotif.values.where((m) => earned.contains(m.name)).length}';
    _bojagiCount = '${DecorationRewardService.openableBoxCount()}';
    QuestTracker.computeAll().then((quests) {
      if (!mounted) {
        return;
      }
      final done = quests.where((q) => q.completed).length;
      final total = quests.where((q) => q.active || q.completed).length;
      setState(() => _questCount = '$done / $total');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            label: t.soriStageQuests,
            count: _questCount,
            onTap: () => Navigator.of(context).pushNamed('/quests'),
            thumb: const RewardThumb(slug: kRewardThumbShowcaseSlug, size: 40),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            label: t.soriStageDojang,
            count: _stampCount,
            onTap: () => Navigator.of(context).pushNamed('/dojangcheop'),
            thumb: Image.asset(
              'assets/illustrations/stamps/stamp_lotus.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(Icons.verified_outlined),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            label: t.soriStageBojagi,
            count: _bojagiCount,
            onTap: () => Navigator.of(context).pushNamed('/bojagi'),
            thumb: Image.asset(
              kBojagiClosed,
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.redeem_rounded, color: SoriColors.gold),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.thumb,
    required this.onTap,
    this.count,
  });

  final String label;
  final Widget thumb;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final semantics = count == null ? label : '$label, $count';
    return Semantics(
      button: true,
      label: semantics,
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(width: 40, height: 40, child: thumb),
            const SizedBox(height: Spacing.xs),
            Text(label, textAlign: TextAlign.center, style: tt.cardTitle),
            if (count != null)
              Text(count!, textAlign: TextAlign.center, style: tt.caption),
          ],
        ),
      ),
    );
  }
}
