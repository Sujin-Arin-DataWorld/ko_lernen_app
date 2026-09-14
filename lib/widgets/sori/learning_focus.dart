import 'package:flutter/material.dart';
import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/learning_focus.dart';
import '../../services/today_learning_snapshot.dart';
import '../../services/mission_recommender.dart';
import '../../services/vocab_pack_service.dart';
import 'button.dart';
import 'card.dart';
import 'tokens.dart';
import 'window_class.dart';
import 'activity_illustration.dart';

class LearningFocusScope extends InheritedNotifier<LearningFocusController> {
  const LearningFocusScope({
    super.key,
    required LearningFocusController controller,
    required this.open,
    required super.child,
  }) : super(notifier: controller);
  final Future<void> Function(
    BuildContext context,
    TodayLearningDestination destination, {
    LearningFocus? focus,
    String? activityId,
  })
  open;
  static LearningFocusScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LearningFocusScope>();
}

class SoriLearningFocus extends StatelessWidget {
  const SoriLearningFocus({super.key, this.introduction});
  final Widget? introduction;
  @override
  Widget build(BuildContext context) {
    final scope = LearningFocusScope.maybeOf(context)!;
    final controller = scope.notifier!;
    final focus = controller.value;
    final t = AppL10n.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final text = SoriTextTheme.of(context);
    final title =
        focus?.brief?.unit.title.pick(language) ??
        switch (focus?.today.pick) {
          HangulIntroPick() => t.screenHangulTitle,
          PackPick(:final pack) => VocabPackService.displayLabel(
            pack.id,
            lang: language,
          ),
          ReviewPick() => t.reviewHubTitle,
          ScenarioPick() =>
            focus?.today.scenario?.title.pick(language) ??
                t.soriStageTodayMissionEyebrow,
          _ => t.soriStageTodayMissionEyebrow,
        };
    final entry = activityForRoute(focus?.destination?.route);
    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.h2.copyWith(fontSize: 21, height: 1.35)),
        if (focus?.minutes case final minutes?) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            t.learningFocusMinutes(minutes),
            style: text.bodySmall.copyWith(fontSize: 15, height: 1.35),
          ),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (introduction != null) introduction!,
        SoriCard(
          key: const ValueKey('learning-focus-surface'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry == null || !focus!.ready)
                metadata
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final illustration = ClipRRect(
                      borderRadius: SoriRadius.brSm,
                      child: Image.asset(
                        activityIllustrationAsset(entry.id),
                        width: 128,
                        height: 96,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => SizedBox(
                          width: 128,
                          height: 96,
                          child: Center(
                            child: Text(
                              t.catalogImageUnavailable,
                              style: text.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                    if (constraints.maxWidth <
                            SoriAdaptiveWidth.learningFocusHeroRow ||
                        MediaQuery.textScalerOf(context).scale(16) > 24) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          illustration,
                          const SizedBox(height: Spacing.md),
                          metadata,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        illustration,
                        const SizedBox(width: Spacing.md),
                        Expanded(child: metadata),
                      ],
                    );
                  },
                ),
              if (controller.loading) ...[
                const SizedBox(height: Spacing.md),
                LinearProgressIndicator(
                  semanticsLabel: t.speechIndicatorResolving,
                ),
              ],
              if (!controller.loading &&
                  (controller.error != null || focus?.failure != null)) ...[
                Text(
                  focus?.failure == LearningFocusFailure.destinationUnavailable
                      ? t.learningFocusDestinationUnavailable
                      : t.loadErrorTryAgain,
                ),
                SoriButton(
                  label: t.btnRetry,
                  onTap: () => controller.refresh(force: true),
                ),
                if (focus?.today.isUnavailable == true &&
                    (focus?.today.dueCount ?? 0) > 0)
                  TextButton(
                    onPressed: () => scope.open(
                      context,
                      const TodayLearningDestination(route: '/review'),
                    ),
                    child: Text(t.reviewHubTitle),
                  ),
              ],
              if (!controller.loading && focus != null && focus.ready) ...[
                const SizedBox(height: 12),
                SoriButton(
                  label: t.learningFocusStart,
                  onTap: controller.launching
                      ? null
                      : () => scope.open(
                          context,
                          focus.destination!,
                          focus: focus,
                          activityId: focus.activityId,
                        ),
                ),
              ],
              if (!controller.loading &&
                  focus != null &&
                  focus.failure == null &&
                  !focus.ready)
                Text(t.soriStageTodayEmpty),
              LayoutBuilder(
                builder: (context, constraints) {
                  final course = TextButton(
                    key: const ValueKey('learning-focus-course-overview'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: controller.launching
                        ? null
                        : () => scope.open(
                            context,
                            const TodayLearningDestination(route: '/path'),
                            activityId: 'course',
                          ),
                    child: Text(
                      t.learningFocusViewCourse,
                      style: text.bodySmall.copyWith(
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? SoriColors.primaryOnDark
                            : SoriColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                  final unit = focus?.brief?.unit;
                  final position = unit == null
                      ? null
                      : Text(
                          t.learningFocusCoursePosition(
                            unit.level.toUpperCase(),
                            switch (focus?.today.pick) {
                              CoursePick(:final missionNumber) => missionNumber,
                              _ => unit.order,
                            },
                          ),
                          style: text.bodySmall.copyWith(fontSize: 15),
                        );
                  if (constraints.maxWidth <
                          SoriAdaptiveWidth.learningFocusFooterRow ||
                      MediaQuery.textScalerOf(context).scale(16) >= 24) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [if (position != null) position, course],
                    );
                  }
                  return Row(
                    children: [
                      if (position != null) Expanded(child: position),
                      Flexible(child: course),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
