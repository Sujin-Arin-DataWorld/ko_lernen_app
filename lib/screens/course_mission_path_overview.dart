import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/tokens.dart';

class CourseMissionPathOverview extends StatelessWidget {
  const CourseMissionPathOverview({super.key, required this.steps});

  final List<CourseMissionStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final visible = steps.take(3).toList(growable: false);
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.courseMissionPath, style: SoriTextTheme.of(context).h3),
          const SizedBox(height: Spacing.sm),
          for (final step in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text.rich(
                TextSpan(
                  text: '${step.displayIndex}. ',
                  style: SoriTextTheme.of(
                    context,
                  ).label.copyWith(color: SoriColors.primary),
                  children: [
                    TextSpan(
                      text: _roleLabel(step.link.role, t),
                      style: SoriTextTheme.of(context).label,
                    ),
                    TextSpan(
                      text: ' · ${_contentLabel(step.link.contentKind, t)}',
                      style: SoriTextTheme.of(context).bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (steps.length > visible.length)
            Text(
              t.missionContextStep(visible.length, steps.length),
              style: SoriTextTheme.of(
                context,
              ).bodySmall.copyWith(color: SoriSurfaces.of(context).textMuted),
            ),
        ],
      ),
    );
  }

  String _roleLabel(ContentLinkRole role, AppL10n t) => switch (role) {
    ContentLinkRole.introduce => t.courseStateIntroduced,
    ContentLinkRole.practice => t.courseStatePractice,
    ContentLinkRole.assess => t.courseMissionCheck,
    ContentLinkRole.review => t.courseStateReviewDue,
  };

  String _contentLabel(CurriculumContentKind kind, AppL10n t) => switch (kind) {
    CurriculumContentKind.vocab => t.coursePracticeVocab,
    CurriculumContentKind.grammar => t.coursePracticeGrammar,
    CurriculumContentKind.cloze => t.coursePracticeCloze,
    CurriculumContentKind.satz => t.coursePracticeSatz,
    CurriculumContentKind.scenario => t.coursePracticeScenario,
    CurriculumContentKind.smalltalk => t.coursePracticeSmalltalk,
  };
}
