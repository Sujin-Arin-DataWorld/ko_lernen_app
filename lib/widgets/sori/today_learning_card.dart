import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/mission_recommender.dart';
import '../../services/vocab_pack_service.dart';
import 'c_gallery/c_materials.dart';
import 'c_gallery/c_objects.dart';
import 'learning_focus.dart';
import 'today_subject_art.dart';
import 'tokens.dart';

/// The approved Today composition, backed by the shared learning owner.
/// Only the illustration yields space; native text and its tap target do not.
class TodayLearningCard extends StatelessWidget {
  const TodayLearningCard({super.key, required this.availableHeight});
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final scope = LearningFocusScope.maybeOf(context)!;
    final controller = scope.notifier!;
    final focus = controller.value;
    if (controller.loading || focus?.ready != true) {
      return const CPaperPanel(
        child: SoriLearningFocus(
          conceptC: true,
          conceptCompactSummary: true,
          conceptCourseOverview: false,
        ),
      );
    }
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final pick = focus!.today.pick;
    final type = SoriTextTheme.of(context);
    final title =
        focus.brief?.unit.title.pick(lang) ??
        switch (pick) {
          HangulIntroPick() => t.todayFirstSyllable,
          ReviewPick() => t.todayReviewTitle,
          PackPick(:final pack) => VocabPackService.displayLabel(
            pack.id,
            lang: lang,
          ),
          ScenarioPick() =>
            focus.today.scenario?.title.pick(lang) ??
                t.soriStageTodayMissionEyebrow,
          _ => t.soriStageTodayMissionEyebrow,
        };
    final description = switch (pick) {
      HangulIntroPick() => t.todayFirstSyllableBody,
      ReviewPick(:final dueCount) => t.homeReviewDue(dueCount),
      CoursePick() => focus.brief?.unit.canDo.pick(lang),
      _ => null,
    };
    final label = switch (pick) {
      HangulIntroPick() => t.todayStartHangul,
      ReviewPick() => t.todayStartReview,
      CoursePick(started: true) => t.todayContinue,
      _ => t.learningFocusStart,
    };
    final bodyStyle = type.body.copyWith(
      fontSize: 16,
      height: 1.2,
      color: CPalette.ink,
    );
    final titleStyle = type.h2.copyWith(
      fontSize: 24,
      height: 1.12,
      color: CPalette.ink,
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        double height(String text, TextStyle style, double width) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: math.max(1, width));
          final result = painter.height;
          painter.dispose();
          return result;
        }

        final width = bounds.maxWidth - 24;
        final meta = [
          if (focus.brief?.unit.level case final level?) level.toUpperCase(),
          if (focus.minutes case final minutes?)
            t.learningFocusMinutes(minutes),
        ].join(' · ');
        final metaStyle = bodyStyle.copyWith(fontSize: 13);
        final metaHeight = height(t.todayNextStep, metaStyle, width * .50);
        final badgeHeight = meta.isEmpty
            ? 0.0
            : height(meta, metaStyle, width * .45);
        final headingHeight = height(title, titleStyle, width);
        final contextHeight = description == null
            ? 0.0
            : height(description, bodyStyle, width) + 4;
        final actionHeight = math.max(
          48.0,
          height(
                label,
                bodyStyle.copyWith(fontWeight: FontWeight.w700),
                width - 56,
              ) +
              20,
        );
        final fixed =
            24 +
            math.max(metaHeight, badgeHeight) +
            8 +
            headingHeight +
            contextHeight +
            8 +
            actionHeight;
        final cardHeight = math.max(availableHeight, fixed + 82);
        return SizedBox(
          key: const ValueKey('today-learning-card'),
          height: cardHeight,
          child: CPaperPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pick is ReviewPick
                            ? t.reviewHubTitle.toUpperCase()
                            : t.todayNextStep,
                        style: metaStyle,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          meta,
                          textAlign: TextAlign.end,
                          style: metaStyle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    key: const ValueKey('learning-focus-title'),
                    style: titleStyle,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    key: const ValueKey('learning-focus-context'),
                    style: bodyStyle,
                  ),
                ],
                Expanded(
                  child: Padding(
                    key: const ValueKey('learning-focus-art'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TodaySubjectArt.forPick(pick),
                  ),
                ),
                const SizedBox(height: 8),
                CMaterialAction(
                  key: const ValueKey('learning-focus-start'),
                  label: label,
                  compact: true,
                  onTap: controller.launching
                      ? null
                      : () => scope.open(
                          context,
                          focus.destination!,
                          focus: focus,
                          activityId: focus.activityId,
                        ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: bodyStyle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const CArrow(dark: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
