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
              Row(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SoriTextTheme.of(
                        context,
                      ).label.copyWith(color: SoriColors.primary),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: s.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                missionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
