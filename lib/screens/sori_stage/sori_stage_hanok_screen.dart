import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../bojagi_screen.dart' show kBojagiClosed;
import '../hanok_world_screen.dart';
import 'sori_stage_common.dart';

/// Quests 숏컷용 대표 장식 — reward_thumb 공용화가 오기 전 직접 경로.
const String _kQuestShortcutThumb =
    'assets/illustrations/decorations/decoration_maehwa.png';

const String _kDojangShortcutThumb =
    'assets/illustrations/stamps/stamp_lotus.png';

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
                  // UI overhaul 2 §P5-2: 고스트 버튼 → 일러스트 숏컷 타일 3.
                  // 카운트 배선은 후속 — 1차는 타일+라벨만.
                  child: Row(
                    children: [
                      Expanded(
                        child: _HanokShortcutTile(
                          asset: _kQuestShortcutThumb,
                          label: t.soriStageQuests,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/quests'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: _HanokShortcutTile(
                          asset: _kDojangShortcutThumb,
                          label: t.soriStageDojang,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/dojangcheop'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: _HanokShortcutTile(
                          asset: kBojagiClosed,
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
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: SoriSurfaces.of(context).textMuted,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.cardTitle,
            ),
          ],
        ),
      ),
    );
  }
}
