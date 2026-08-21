import 'course_mission_step_plan.dart';
import 'course_mastery.dart';
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
    required this.isCompleted,
    required this.estimatedMinutesToScene,
    required this.firstLink,
  });

  factory CourseMissionBrief.from({
    required CourseUnit unit,
    required Iterable<ContentLink> links,
    required Iterable<Scenario> scenarios,
    required bool isCurrent,
    CourseMasterySnapshot snapshot = const CourseMasterySnapshot.empty(),
    int visibleStepLimit = 3,
  }) {
    final plan = CourseMissionStepPlan.fromLinks(links);
    final linksByPhase = <CourseMissionPhase, List<ContentLink>>{
      for (final kind in CourseMissionPhase.values) kind: <ContentLink>[],
    };
    for (final step in plan.steps) {
      linksByPhase[_phaseFor(step.link, unit)]!.add(step.link);
    }
    linksByPhase[CourseMissionPhase.scene]!.sort((left, right) {
      final rank = _sceneLinkRank(
        left,
        unit,
      ).compareTo(_sceneLinkRank(right, unit));
      if (rank != 0) return rank;
      return left.id.compareTo(right.id);
    });
    final allPhases = <_MissionPhase>[
      for (final kind in CourseMissionPhase.values)
        if (linksByPhase[kind]!.isNotEmpty)
          _MissionPhase(
            kind,
            List.unmodifiable(linksByPhase[kind]!),
            unit,
            snapshot,
          ),
    ];
    final phases = allPhases
        .where((phase) => !_isPhaseResolved(phase, unit, snapshot))
        .toList();
    final limit = visibleStepLimit.clamp(0, phases.length);
    final visibleSteps = <CourseMissionBriefStep>[
      for (var index = 0; index < limit; index++)
        CourseMissionBriefStep(
          link: phases[index].representativeLink,
          phase: phases[index].kind,
          displayIndex:
              allPhases.indexWhere(
                (phase) => phase.kind == phases[index].kind,
              ) +
              1,
          total: allPhases.length,
          estimatedMinutes: _minutesForPhase(phases[index].kind),
        ),
    ];
    final scenePhases = phases.where(
      (phase) => phase.kind == CourseMissionPhase.scene,
    );
    final scenarioLink = scenePhases.isEmpty
        ? null
        : scenePhases.first.representativeLink;
    final scenarioById = <String, Scenario>{
      for (final scenario in scenarios) scenario.id: scenario,
    };
    var minutesToScene = 0;
    for (final phase in phases) {
      minutesToScene += _minutesForPhase(phase.kind);
      if (phase.kind == CourseMissionPhase.scene) break;
    }

    return CourseMissionBrief._(
      unit: unit,
      visibleSteps: List.unmodifiable(visibleSteps),
      totalStepCount: phases.length,
      targetScenario: scenarioLink == null
          ? null
          : scenarioById[scenarioLink.contentId],
      isCurrent: isCurrent,
      isCompleted: snapshot.completedUnitIds.contains(unit.id),
      estimatedMinutesToScene: minutesToScene,
      firstLink: phases.isEmpty ? null : phases.first.representativeLink,
    );
  }

  final CourseUnit unit;
  final List<CourseMissionBriefStep> visibleSteps;
  final int totalStepCount;
  final Scenario? targetScenario;
  final bool isCurrent;
  final bool isCompleted;
  final int estimatedMinutesToScene;
  final ContentLink? firstLink;

  int get remainingStepCount => totalStepCount - visibleSteps.length;
}

enum CourseMissionPhase { listen, build, checkpoint, scene }

int _sceneLinkRank(ContentLink link, CourseUnit unit) {
  final declaredIndex = unit.checkpointContentIds.indexOf(link.contentKey);
  if (declaredIndex >= 0 && link.exactlyAssesses(unit)) {
    return declaredIndex * 2;
  }
  if (link.role == ContentLinkRole.assess && declaredIndex >= 0) {
    return declaredIndex * 2 + 1;
  }
  if (link.role == ContentLinkRole.assess) {
    return unit.checkpointContentIds.length * 2;
  }
  return unit.checkpointContentIds.length * 2 + 1;
}

class _MissionPhase {
  const _MissionPhase(this.kind, this.links, this.unit, this.snapshot);

  final CourseMissionPhase kind;
  final List<ContentLink> links;
  final CourseUnit unit;
  final CourseMasterySnapshot snapshot;

  ContentLink get representativeLink {
    if (kind == CourseMissionPhase.scene) {
      for (final link in links) {
        if (link.exactlyAssesses(unit) &&
            !_checkpointPassed(link, unit, snapshot)) {
          return link;
        }
      }
      return links.firstWhere(
        (link) => link.exactlyAssesses(unit),
        orElse: () => links.first,
      );
    }
    if (kind != CourseMissionPhase.build) return links.first;
    const preference = [
      CurriculumContentKind.cloze,
      CurriculumContentKind.satz,
      CurriculumContentKind.grammar,
      CurriculumContentKind.smalltalk,
    ];
    for (final contentKind in preference) {
      for (final link in links) {
        if (link.contentKind == contentKind) return link;
      }
    }
    return links.first;
  }
}

CourseMissionPhase _phaseFor(ContentLink link, CourseUnit unit) {
  if (link.contentKind == CurriculumContentKind.vocab) {
    return CourseMissionPhase.listen;
  }
  if (link.contentKind == CurriculumContentKind.scenario) {
    return CourseMissionPhase.scene;
  }
  if (unit.checkpointContentIds.contains(link.contentKey) &&
      link.exactlyAssesses(unit)) {
    return CourseMissionPhase.checkpoint;
  }
  return CourseMissionPhase.build;
}

int _minutesForPhase(CourseMissionPhase kind) => switch (kind) {
  CourseMissionPhase.listen => 1,
  CourseMissionPhase.build => 2,
  CourseMissionPhase.checkpoint => 1,
  CourseMissionPhase.scene => 1,
};

bool _isPhaseResolved(
  _MissionPhase phase,
  CourseUnit unit,
  CourseMasterySnapshot snapshot,
) =>
    snapshot.completedUnitIds.contains(unit.id) ||
    (phase.kind == CourseMissionPhase.scene
        ? false
        : phase.links.any((link) => _isResolved(link, unit, snapshot)));

bool _checkpointPassed(
  ContentLink link,
  CourseUnit unit,
  CourseMasterySnapshot snapshot,
) {
  if (!unit.checkpointContentIds.contains(link.contentKey)) return true;
  final matching =
      snapshot.scenarioCheckpoints
          .where(
            (item) =>
                item.courseEligible &&
                item.courseUnitId == unit.id &&
                item.missionContentLinkId == link.id &&
                item.scenarioId == link.contentId,
          )
          .toList(growable: false)
        ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
  return matching.isNotEmpty && matching.first.score >= unit.passThreshold;
}

bool _isResolved(
  ContentLink link,
  CourseUnit unit,
  CourseMasterySnapshot snapshot,
) {
  if (snapshot.completedUnitIds.contains(unit.id)) return true;
  if (link.contentKind == CurriculumContentKind.scenario) {
    return _checkpointPassed(link, unit, snapshot);
  }
  if (link.conceptIds.isEmpty) return false;
  for (final conceptId in link.conceptIds) {
    final matching =
        snapshot.evidence
            .where(
              (item) =>
                  (link.role == ContentLinkRole.assess
                      ? item.courseEligible &&
                            item.missionContentLinkId == link.id
                      : item.missionContentLinkId == link.id) &&
                  item.courseUnitId == unit.id &&
                  item.contentKind == link.contentKind &&
                  item.contentId == link.contentId &&
                  item.conceptId == conceptId,
            )
            .toList(growable: false)
          ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    if (matching.isEmpty || !matching.first.isCorrect) return false;
    if (link.contentKind == CurriculumContentKind.vocab &&
        (matching.first.score == null ||
            matching.first.score! < unit.passThreshold)) {
      return false;
    }
  }
  return true;
}

class CourseMissionBriefStep {
  const CourseMissionBriefStep({
    required this.link,
    required this.phase,
    required this.displayIndex,
    required this.total,
    required this.estimatedMinutes,
  });

  final ContentLink link;
  final CourseMissionPhase phase;
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
