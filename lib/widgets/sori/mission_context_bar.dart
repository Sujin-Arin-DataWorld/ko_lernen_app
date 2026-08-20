import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/course_mission_step_plan.dart';
import 'progress.dart';
import 'tokens.dart';

/// Read-only context for a learning surface reached from an active course
/// mission. It deliberately has no action or storage dependency: the screen
/// that owns a learner's answer remains the only place that can write evidence.
class MissionContextBar extends StatelessWidget {
  const MissionContextBar({
    super.key,
    required this.missionTitle,
    required this.step,
  });

  final String missionTitle;
  final CourseMissionStep step;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final progressLabel = t.missionContextStep(step.displayIndex, step.total);

    return Semantics(
      container: true,
      label: '${t.missionContextLabel}: $missionTitle',
      value: progressLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: s.surfaceAlt,
            border: Border.all(color: s.border),
            borderRadius: SoriRadius.brMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final stackHeader =
                      textScale >= 1.6 ||
                      constraints.maxWidth < SoriBreakpoints.missionHeaderStack;
                  final missionLabel = Row(
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 18,
                        color: SoriColors.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Flexible(
                        child: Text(
                          t.missionContextLabel,
                          style: SoriTextTheme.of(
                            context,
                          ).label.copyWith(color: SoriColors.primary),
                        ),
                      ),
                    ],
                  );
                  final progress = Text(
                    progressLabel,
                    textAlign: stackHeader ? TextAlign.start : TextAlign.end,
                    style: SoriTextTheme.of(
                      context,
                    ).bodySmall.copyWith(color: s.textMuted),
                  );
                  if (stackHeader) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        missionLabel,
                        const SizedBox(height: Spacing.xs),
                        progress,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: missionLabel),
                      const SizedBox(width: Spacing.sm),
                      Flexible(child: progress),
                    ],
                  );
                },
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                missionTitle,
                style: SoriTextTheme.of(
                  context,
                ).body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Spacing.sm),
              SoriProgressBar(
                value: step.progress,
                thickness: 6,
                color: SoriColors.primary,
                animated: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
