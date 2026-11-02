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
  const TodayLearningCard({
    super.key,
    required this.availableHeight,
    this.compactArt = false,
  });
  final double availableHeight;
  final bool compactArt;

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
    final unitId = focus.brief?.unit.id;
    final editorial = switch (unitId) {
      'a1_01_greetings_hangul' => (
        t.todayMissionGreetingTitle,
        t.todayMissionGreetingBody,
      ),
      'a2_02_plans_proposals' => (
        t.todayMissionPlansTitle,
        t.todayMissionPlansBody,
      ),
      'b2_03_precise_requests' => (
        t.todayMissionRequestsTitle,
        t.todayMissionRequestsBody,
      ),
      'c1_04_play_time_policy' => (
        t.todayMissionPolicyTitle,
        t.todayMissionPolicyBody,
      ),
      'c2_01_interpretation_institutions' => (
        t.todayMissionAuthorityTitle,
        t.todayMissionAuthorityBody,
      ),
      _ => null,
    };
    final title =
        editorial?.$1 ??
        focus.brief?.unit.title.pick(lang) ??
        switch (pick) {
          HangulIntroPick() => t.todayFirstSyllable,
          ReviewPick() => t.todayMissionReviewTitle,
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
      CoursePick() => editorial?.$2 ?? focus.brief?.unit.canDo.pick(lang),
      _ => null,
    };
    final label = switch (pick) {
      HangulIntroPick() => t.todayStartHangul,
      ReviewPick() => t.todayStartReview,
      CoursePick() when focus.brief?.hasStarted == true => t.todayResumeStage,
      _ => t.todayBeginStage,
    };
    final bodyStyle = type.body.copyWith(
      fontSize: 16,
      height: 1.3125,
      color: CPalette.ink,
    );
    final titleStyle = type.h2.copyWith(
      fontSize: 23,
      height: 29 / 23,
      color: CPalette.ink,
    );
    final actionStyle = type.label.copyWith(
      fontSize: 19,
      height: 24 / 19,
      fontWeight: SoriLocaleFonts.of(context).bodyWeight(FontWeight.w600),
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

        // CPaperPanel contributes its 1dp border on each edge as well as the
        // explicit 16dp inset. Measure against that exact text column.
        final width = bounds.maxWidth - 38;
        final meta = [
          if (pick is! ReviewPick) ...[
            if (focus.brief?.unit.level case final level?) level.toUpperCase(),
            if (focus.minutes case final minutes?)
              t.learningFocusMinutes(minutes),
          ],
        ].join(' · ');
        final metaStyle = type.caption.copyWith(
          fontSize: 13,
          height: 18 / 13,
          color: CPalette.mutedInk,
        );
        final eyebrow = pick is ReviewPick
            ? t.reviewHubTitle
            : focus.brief?.hasStarted == true
            ? t.todayResumeStage
            : t.todayNextStage;
        final metaWidth = meta.isEmpty ? 0.0 : math.min(108.0, width * .46);
        final metaHeight = height(eyebrow, metaStyle, width - metaWidth - 8);
        final badgeHeight = meta.isEmpty
            ? 0.0
            : height(meta, metaStyle, metaWidth);
        final headingHeight = height(title, titleStyle, width);
        final contextHeight = description == null
            ? 0.0
            : height(description, bodyStyle, width) + 4;
        final actionHeight = math.max(
          48.0,
          height(label, actionStyle, width - 68) + 16,
        );
        final fixed =
            28 +
            math.max(metaHeight, badgeHeight) +
            6 +
            headingHeight +
            contextHeight +
            6 +
            actionHeight;
        final cardHeight = math.max(
          availableHeight,
          fixed + (compactArt ? 32 : 64),
        );
        return SizedBox(
          key: const ValueKey('today-learning-card'),
          height: cardHeight,
          child: CPaperPanel(
            radius: 18,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            surfaceTexture: const CTexture(CMaterial.paper),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(eyebrow, style: metaStyle)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: metaWidth,
                        child: Text(
                          meta,
                          key: const ValueKey('learning-focus-meta'),
                          textAlign: TextAlign.end,
                          style: metaStyle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        SoriRadius.c5DetailAction,
                      ),
                      child: TodaySubjectArt.forPick(
                        pick,
                        link: focus.brief?.firstLink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                CMaterialAction(
                  key: const ValueKey('learning-focus-start'),
                  label: label,
                  compact: true,
                  exactSurface: true,
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
                      const SizedBox(width: 34),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: actionStyle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const SizedBox(width: 34, child: CArrow(size: 18)),
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
