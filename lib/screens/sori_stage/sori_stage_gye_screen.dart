import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../gye_tab_screen.dart';
import 'sori_stage_common.dart';

class SoriStageGyeScreen extends StatelessWidget {
  const SoriStageGyeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SoriContentClamp(
              maxWidth: 880,
              base: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              builder: (context, padding) => Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoriStageRootHeader(
                      eyebrow: t.soriStageNavGye,
                      title: t.soriStageGyePromise,
                    ),
                    const SizedBox(height: Spacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: SoriActivityColors.collaboration.withValues(
                          alpha: .16,
                        ),
                        borderRadius: BorderRadius.circular(SoriRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_outlined,
                            color: SoriColors.highlight,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              t.soriStageGyeFlow,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(child: GyeTabScreen(embedded: true)),
          ],
        ),
      ),
    );
  }
}
