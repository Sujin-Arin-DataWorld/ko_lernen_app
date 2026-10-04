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
    final focal = entry != null && focus!.ready && !controller.loading;
    final subject = title.toLowerCase();
    final focalArt =
        subject.contains('coffee') ||
            subject.contains('kaffee') ||
            subject.contains('카페')
        ? SoriArtwork.coffee
        : SoriArtwork.action(entry?.id ?? 'course');
    final foreground = focal ? Colors.white : SoriSurfaces.of(context).text;
    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.h2.copyWith(fontSize: 26, height: 1.3, color: foreground),
        ),
        if (focus?.minutes case final minutes?) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            t.learningFocusMinutes(minutes),
            style: text.bodySmall.copyWith(
              fontSize: 15,
              height: 1.35,
              color: foreground,
            ),
          ),
        ],
      ],
    );
    final startAction = !controller.loading && focus != null && focus.ready
        ? SoriButton(
            label: t.learningFocusStart,
            illustrationAsset: SoriArtwork.action(entry?.id ?? 'course'),
            trailingIcon: Icons.arrow_forward_rounded,
            accent: SoriActivityColors.actionGold,
            fullWidth: true,
            onTap: controller.launching
                ? null
                : () => scope.open(
                    context,
                    focus.destination!,
                    focus: focus,
                    activityId: focus.activityId,
                  ),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (introduction != null) introduction!,
        SoriCard(
          key: const ValueKey('learning-focus-surface'),
          variant: SoriCardVariant.hero,
          backgroundColor: focal ? SoriActivityColors.hanokStage : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry == null || !focus!.ready) ...[
                metadata,
                if (startAction != null) ...[
                  const SizedBox(height: 12),
                  startAction,
                ],
              ] else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final illustration = ClipRRect(
                      borderRadius: SoriRadius.brSm,
                      child: Image.asset(
                        focalArt ?? activityIllustrationAsset(entry.id),
                        width: 160,
                        height: 128,
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
                    if (constraints.maxWidth < SoriBreakpoints.grid ||
                        MediaQuery.textScalerOf(context).scale(16) > 24) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          metadata,
                          Align(
                            alignment: Alignment.centerRight,
                            child: illustration,
                          ),
                          if (startAction != null) ...[
                            const SizedBox(height: 12),
                            startAction,
                          ],
                        ],
                      );
                    }
                    final wideAction =
                        constraints.maxWidth >=
                        SoriAdaptiveWidth.learningFocusActionRow;
                    final hero = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        illustration,
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              metadata,
                              if (wideAction && startAction != null) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: SoriAdaptiveWidth
                                        .learningFocusActionMax,
                                    child: startAction,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                    if (wideAction || startAction == null) {
                      return hero;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [hero, const SizedBox(height: 12), startAction],
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
                        color: focal
                            ? Colors.white
                            : Theme.of(context).brightness == Brightness.dark
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
                          style: text.bodySmall.copyWith(
                            fontSize: 15,
                            color: foreground,
                          ),
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
