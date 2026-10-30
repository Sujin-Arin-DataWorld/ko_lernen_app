import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/gye.dart';
import '../../models/gye_lantern_progress.dart';
import 'tokens.dart';

/// User-approved source and its lighting-only edited sibling. Both use the
/// same transparent 926 x 1698 canvas; no color filter fakes an unlit state.
abstract final class GyeWeeklyLanternAssets {
  static const lit = 'assets/illustrations/gye/weekly_lantern/lit.png';
  static const off = 'assets/illustrations/gye/weekly_lantern/off.png';
}

/// Pure presentation of the existing server-projected weekly state.
///
/// A life promise has one light per accepted anonymous contribution. A legacy
/// pack goal earns one weekly lantern only when the whole goal is complete,
/// matching [GyeLanternProgress.currentStepFor]. Pack counts are never presented
/// as newly earned individual lanterns.
class GyeWeeklyGoalProgress extends StatelessWidget {
  const GyeWeeklyGoalProgress({
    super.key,
    required this.meta,
    this.showHeading = true,
    this.maxLanternWidth = 76,
  });

  final GyeMeta meta;
  final bool showHeading;

  /// Artwork budget only; the verified contribution count is unchanged.
  final double maxLanternWidth;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final progress = GyeLanternProgress.fromMeta(meta, elementCount: 1);
    final usesPromise =
        meta.weeklyPromiseSchemaVersion == 1 &&
        meta.weeklyPromiseId.isNotEmpty &&
        meta.weeklyPromiseTarget > 0;
    if (!progress.hasWeeklyGoal) {
      return Text(t.gyeNoGoal, style: SoriTextTheme.of(context).bodySmall);
    }
    final target = usesPromise ? meta.weeklyPromiseTarget.clamp(1, 5) : 1;
    final done = usesPromise
        ? meta.weeklyPromiseProgress.clamp(0, target)
        : progress.weeklyFraction >= 1
        ? 1
        : 0;
    return GyeWeeklyLanternRow(
      done: done,
      target: target,
      maxLanternWidth: maxLanternWidth,
      heading: showHeading ? t.statsThisWeek : null,
      progressLabel: usesPromise
          ? t.gyePromiseProgress(done, target)
          : '${math.max(0, meta.weeklyGoalProgress)} / ${meta.weeklyGoalPacks}',
    );
  }
}

/// The heading, count and objects each occupy their own measured flow row.
/// This intentionally has no positioned text or fixed text-height rectangle.
class GyeWeeklyLanternRow extends StatelessWidget {
  const GyeWeeklyLanternRow({
    super.key,
    required this.done,
    required this.target,
    this.heading,
    this.progressLabel,
    this.maxLanternWidth = 76,
  });

  final int done;
  final int target;
  final String? heading;
  final String? progressLabel;
  final double maxLanternWidth;

  @override
  Widget build(BuildContext context) {
    final count = target.clamp(0, 5);
    final litCount = done.clamp(0, count);
    final label =
        progressLabel ??
        AppL10n.of(context).gyePromiseProgress(litCount, count);
    final type = SoriTextTheme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: heading == null ? label : '$heading. $label',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (heading != null) ...[
              Text(
                heading!,
                key: const ValueKey('gye-weekly-heading'),
                style: type.label,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              key: const ValueKey('gye-weekly-progress-label'),
              style: type.cardTitle,
            ),
            if (count > 0) ...[
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, bounds) {
                  final columns = math.min(count, 3);
                  final width =
                      ((bounds.maxWidth - (columns - 1) * 12) / columns)
                          .clamp(
                            math.min(48.0, maxLanternWidth),
                            maxLanternWidth,
                          )
                          .toDouble();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < count; index++)
                        SizedBox(
                          key: ValueKey('gye-weekly-lantern-$index'),
                          width: width,
                          height: width * 1698 / 926,
                          child: AnimatedSwitcher(
                            duration: SoriMotion.reduceMotion(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: Image.asset(
                              index < litCount
                                  ? GyeWeeklyLanternAssets.lit
                                  : GyeWeeklyLanternAssets.off,
                              key: ValueKey(index < litCount),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              cacheWidth:
                                  (width *
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ))
                                      .ceil(),
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
