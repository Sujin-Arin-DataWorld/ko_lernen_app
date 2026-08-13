import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/responsive.dart';
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
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      SoriButton.ghost(
                        label: t.soriStageQuests,
                        onTap: () => Navigator.of(context).pushNamed('/quests'),
                      ),
                      SoriButton.ghost(
                        label: t.soriStageDojang,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/dojangcheop'),
                      ),
                      SoriButton.ghost(
                        label: t.soriStageBojagi,
                        onTap: () => Navigator.of(context).pushNamed('/bojagi'),
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
