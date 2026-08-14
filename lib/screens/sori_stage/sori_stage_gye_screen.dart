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
                    const SizedBox(height: Spacing.sm),
                    Container(
                      width: double.infinity,
                      // §P5-1 밀도 패스 — 390×844 스크롤 없는 CTA 도달.
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                        vertical: Spacing.md,
                      ),
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
                              // §P5-1-5: raw TextStyle(w700) → 토큰 수렴.
                              style: SoriTextTheme.of(context).label,
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
