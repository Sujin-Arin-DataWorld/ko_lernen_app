import 'package:flutter/material.dart';

import '../../data/milestone.dart';
import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'celebration.dart';
import 'mascot.dart';
import 'sheet.dart';
import 'tokens.dart';

/// 마일스톤 달성 축하 — 축하 버스트 + 마스코트 + 메시지(showSoriSheet 재사용).
///
/// 호출 전 [Storage.markMilestonesCelebrated]로 1회 가드 마킹(중복 방지)은 호출부 책임.
Future<void> showMilestoneCelebration(
  BuildContext context,
  Milestone milestone,
) async {
  SoriCelebration.burst(context);
  await showSoriSheet<void>(
    context: context,
    builder: (ctx) => _MilestoneBody(milestone: milestone),
  );
}

class _MilestoneBody extends StatelessWidget {
  final Milestone milestone;

  const _MilestoneBody({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Mascot.tiger(
          size: 96,
          emotion: MascotEmotion.celebrate,
          animate: true,
        ),
        const SizedBox(height: Spacing.md),
        Text(milestone.title(t), style: tt.h1, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          milestone.body(t),
          style: tt.body.copyWith(color: s.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        SoriButton.filled(
          label: t.milestoneCta,
          icon: Icons.bolt_rounded,
          fullWidth: true,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: Spacing.xs),
      ],
    );
  }
}
