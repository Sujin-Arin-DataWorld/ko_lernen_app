import 'course_mission_step_plan.dart';
import 'curriculum.dart';
import 'scenario.dart';

/// A short, read-only departure contract for one real course mission.
///
/// The same captured graph links drive the visible order, time estimate, and
/// primary action. The brief cannot synthesize progress or completion.
class CourseMissionBrief {
  const CourseMissionBrief._({
    required this.unit,
    required this.visibleSteps,
    required this.totalStepCount,
    required this.targetScenario,
    required this.isCurrent,
  });

  factory CourseMissionBrief.from({
    required CourseUnit unit,
    required Iterable<ContentLink> links,
    required Iterable<Scenario> scenarios,
    required bool isCurrent,
    int visibleStepLimit = 3,
  }) {
    final plan = CourseMissionStepPlan.fromLinks(links);
    final limit = visibleStepLimit.clamp(0, plan.steps.length);
    final visibleSteps = <CourseMissionBriefStep>[
      for (final step in plan.steps.take(limit))
        CourseMissionBriefStep(
          link: step.link,
          displayIndex: step.displayIndex,
          total: step.total,
          estimatedMinutes: courseMissionMinutesFor(step.link.contentKind),
        ),
    ];
    CourseMissionStep? scenarioLink;
    for (final step in plan.steps) {
      if (step.link.contentKind == CurriculumContentKind.scenario) {
        scenarioLink = step;
        break;
      }
    }
    final scenarioById = <String, Scenario>{
      for (final scenario in scenarios) scenario.id: scenario,
    };

    return CourseMissionBrief._(
      unit: unit,
      visibleSteps: List.unmodifiable(visibleSteps),
      totalStepCount: plan.steps.length,
      targetScenario: scenarioLink == null
          ? null
          : scenarioById[scenarioLink.link.contentId],
      isCurrent: isCurrent,
    );
  }

  final CourseUnit unit;
  final List<CourseMissionBriefStep> visibleSteps;
  final int totalStepCount;
  final Scenario? targetScenario;
  final bool isCurrent;

  int get visibleEstimatedMinutes =>
      visibleSteps.fold(0, (total, step) => total + step.estimatedMinutes);

  int get remainingStepCount => totalStepCount - visibleSteps.length;

  ContentLink? get firstLink =>
      visibleSteps.isEmpty ? null : visibleSteps.first.link;
}

class CourseMissionBriefStep {
  const CourseMissionBriefStep({
    required this.link,
    required this.displayIndex,
    required this.total,
    required this.estimatedMinutes,
  });

  final ContentLink link;
  final int displayIndex;
  final int total;
  final int estimatedMinutes;
}

int courseMissionMinutesFor(CurriculumContentKind kind) => switch (kind) {
  CurriculumContentKind.vocab => 1,
  CurriculumContentKind.grammar => 2,
  CurriculumContentKind.cloze => 2,
  CurriculumContentKind.satz => 2,
  CurriculumContentKind.scenario => 1,
  CurriculumContentKind.smalltalk => 1,
};
