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
import 'c_gallery/c_materials.dart';

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
  const SoriLearningFocus({
    super.key,
    this.introduction,
    this.conceptC = false,
    this.conceptArt,
    this.conceptSummary = true,
    this.conceptCourseOverview = true,
    this.conceptArtOnlyAction = false,
    this.conceptCompactSummary = false,
  });
  final Widget? introduction;
  final bool conceptC;
  final Widget? conceptArt;
  final bool conceptSummary;
  final bool conceptCourseOverview;
  final bool conceptArtOnlyAction;
  final bool conceptCompactSummary;
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
    final isCafe =
        subject.contains('coffee') ||
        subject.contains('kaffee') ||
        subject.contains('café') ||
        subject.contains('cafe') ||
        subject.contains('카페');
    final focalArt = isCafe
        ? SoriArtwork.coffee
        : SoriArtwork.action(entry?.id ?? 'course');
    if (conceptC) {
      final body = text.body.copyWith(
        fontSize: 16,
        height: 1.3,
        color: CPalette.ink,
      );
      final compact =
          MediaQuery.sizeOf(context).height < 750 &&
          MediaQuery.textScalerOf(context).scale(16) <= 16;
      final nominalArtHeight = conceptCompactSummary
          ? 160.0
          : (compact ? 88.0 : 146.0);
      final artHeight = nominalArtHeight;
      // The approved book source has 16dp of transparent top canvas at this
      // size. Reclaim 12dp while retaining the full 160dp image and shadow;
      // actual material still begins below the preceding native text.
      final trimBookCanvas =
          conceptCompactSummary &&
          conceptArt == null &&
          !isCafe &&
          focus?.today.pick is CoursePick;
      final contextText = focus?.ready != true
          ? null
          : switch (focus!.today.pick) {
              ReviewPick() => t.homeReviewDue(focus.today.dueCount),
              CoursePick() => focus.brief?.unit.canDo.pick(language),
              _ => null,
            };
      final rawSubjectArt =
          conceptArt ??
          SizedBox(
            key: const ValueKey('learning-focus-art'),
            height: artHeight,
            child: isCafe
                ? CSceneArt(CScene.coffee, height: artHeight)
                : switch (focus?.today.pick) {
                    HangulIntroPick() => const CReferenceArt(
                      CReferencePart.hangul,
                    ),
                    ReviewPick() => CReferenceArt(
                      CReferencePart.review,
                      opticalFit: true,
                    ),
                    _ => const CReferenceArt(CReferencePart.book),
                  },
          );
      final subjectArt = trimBookCanvas
          ? SizedBox(
              height: artHeight - 12,
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minHeight: artHeight,
                maxHeight: artHeight,
                child: rawSubjectArt,
              ),
            )
          : rawSubjectArt;
      VoidCallback? start =
          controller.loading || controller.launching || focus?.ready != true
          ? null
          : () => scope.open(
              context,
              focus!.destination!,
              focus: focus,
              activityId: focus.activityId,
            );
      return Column(
        key: const ValueKey('learning-focus-surface'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (introduction != null) introduction!,
          if (conceptSummary) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  t.soriStageTodayMissionEyebrow,
                  style: body.copyWith(
                    height: conceptCompactSummary ? 1.1 : 1.3,
                  ),
                ),
                if (focus?.minutes case final minutes?)
                  Text(
                    [
                      if (focus?.brief?.unit.level case final level?)
                        level.toUpperCase(),
                      t.learningFocusMinutes(minutes),
                    ].join(' · '),
                    style: body.copyWith(
                      height: conceptCompactSummary ? 1.1 : 1.3,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                title,
                key: const ValueKey('learning-focus-title'),
                style: body.copyWith(
                  fontSize: conceptCompactSummary ? 22 : 25,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            if (conceptCompactSummary &&
                contextText?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                contextText!,
                key: const ValueKey('learning-focus-context'),
                style: body,
              ),
            ],
          ],
          if (focus?.ready == true) ...[
            SizedBox(
              height:
                  conceptCompactSummary &&
                      contextText?.trim().isNotEmpty == true
                  ? 0
                  : 8,
            ),
            if (conceptArtOnlyAction)
              CImageTap(
                key: const ValueKey('learning-focus-start'),
                label: '${t.learningFocusStart}: $title',
                onTap: start,
                child: subjectArt,
              )
            else ...[
              subjectArt,
              const SizedBox(height: 8),
              CMaterialAction(
                key: const ValueKey('learning-focus-start'),
                label: t.learningFocusStart,
                compact: compact,
                onTap: start,
              ),
            ],
          ],
          if (controller.loading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(semanticsLabel: t.speechIndicatorResolving),
          ],
          if (!controller.loading &&
              (controller.error != null || focus?.failure != null)) ...[
            Text(
              focus?.failure == LearningFocusFailure.destinationUnavailable
                  ? t.learningFocusDestinationUnavailable
                  : t.loadErrorTryAgain,
              style: body,
            ),
            const SizedBox(height: 8),
            CMaterialAction(
              label: t.btnRetry,
              compact: true,
              gold: false,
              onTap: () => controller.refresh(force: true),
            ),
            if (focus?.today.isUnavailable == true &&
                (focus?.today.dueCount ?? 0) > 0)
              TextButton(
                onPressed: () => scope.open(
                  context,
                  const TodayLearningDestination(route: '/review'),
                ),
                child: Text(t.reviewHubTitle, style: body),
              ),
          ],
          if (!controller.loading &&
              focus != null &&
              focus.failure == null &&
              !focus.ready)
            Text(t.soriStageTodayEmpty, style: body),
          if (conceptCourseOverview && conceptCompactSummary)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (focus?.brief?.unit case final unit?)
                  Text(
                    t.learningFocusCoursePosition(
                      unit.level.toUpperCase(),
                      switch (focus?.today.pick) {
                        CoursePick(:final missionNumber) => missionNumber,
                        _ => unit.order,
                      },
                    ),
                    style: body,
                  ),
                TextButton(
                  key: const ValueKey('learning-focus-course-overview'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: controller.launching
                      ? null
                      : () => scope.open(
                          context,
                          const TodayLearningDestination(route: '/path'),
                          activityId: 'course',
                        ),
                  child: Text(t.learningFocusViewCourse, style: body),
                ),
              ],
            ),
          if (conceptCourseOverview && !conceptCompactSummary)
            if (focus?.brief?.unit case final unit?) ...[
              const SizedBox(height: 4),
              Text(
                t.learningFocusCoursePosition(
                  unit.level.toUpperCase(),
                  switch (focus?.today.pick) {
                    CoursePick(:final missionNumber) => missionNumber,
                    _ => unit.order,
                  },
                ),
                style: body,
              ),
            ],
          if (conceptCourseOverview && !conceptCompactSummary)
            TextButton(
              key: const ValueKey('learning-focus-course-overview'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: controller.launching
                  ? null
                  : () => scope.open(
                      context,
                      const TodayLearningDestination(route: '/path'),
                      activityId: 'course',
                    ),
              child: Text(t.learningFocusViewCourse, style: body),
            ),
        ],
      );
    }
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
