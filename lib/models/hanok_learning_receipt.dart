import 'course_mastery.dart';
import 'curriculum.dart';
import 'scenario.dart';

/// Read-only proof shown in the Hanok and Sarangbang.
///
/// This is a projection of already persisted course evidence. It never writes
/// mastery, rewards, room placement, or construction unlocks.
class HanokLearningReceipt {
  static const int defaultScenesPerBeam = 2;

  final int safeSceneCount;
  final int safeScenesTowardNextBeam;
  final int scenesPerBeam;
  final int plannedBeamCount;
  final int earnedExpressionCount;
  final String? latestSafeScenarioId;
  final String? latestSafeExpressionKo;
  final String? nextScenarioId;
  final String? nextExpressionKo;

  const HanokLearningReceipt({
    this.safeSceneCount = 0,
    this.safeScenesTowardNextBeam = 0,
    this.scenesPerBeam = defaultScenesPerBeam,
    this.plannedBeamCount = 0,
    this.earnedExpressionCount = 0,
    this.latestSafeScenarioId,
    this.latestSafeExpressionKo,
    this.nextScenarioId,
    this.nextExpressionKo,
  });

  const HanokLearningReceipt.empty() : this();

  factory HanokLearningReceipt.fromSnapshot({
    required CourseMasterySnapshot snapshot,
    required Iterable<CourseUnit> courseUnits,
    required Iterable<ContentLink> contentLinks,
    Iterable<Scenario> scenarios = const <Scenario>[],
    CourseUnit? nextUnit,
    int scenesPerBeam = defaultScenesPerBeam,
  }) {
    assert(scenesPerBeam > 0);
    final normalizedScenesPerBeam = scenesPerBeam <= 0
        ? defaultScenesPerBeam
        : scenesPerBeam;
    final unitsById = <String, CourseUnit>{
      for (final unit in courseUnits) unit.id: unit,
    };
    final scenariosById = <String, Scenario>{
      for (final scenario in scenarios) scenario.id: scenario,
    };
    final assessSceneLinks = <String, Set<String>>{};
    for (final link in contentLinks) {
      final unit = unitsById[link.courseUnitId];
      if (link.contentKind != CurriculumContentKind.scenario ||
          unit == null ||
          !link.exactlyAssesses(unit)) {
        continue;
      }
      assessSceneLinks
          .putIfAbsent(
            _sceneKey(link.courseUnitId, link.contentId),
            () => <String>{},
          )
          .add(link.id);
    }
    final assessSceneKeys = assessSceneLinks.keys.toSet();
    final latestByScene = <String, ScenarioCheckpointEvidence>{};
    for (final checkpoint in snapshot.scenarioCheckpoints) {
      final unitId = checkpoint.courseUnitId;
      if (!checkpoint.courseEligible ||
          checkpoint.missionContentLinkId == null ||
          unitId == null) {
        continue;
      }
      final unit = unitsById[unitId];
      final contentId = 'scenario:${checkpoint.scenarioId}';
      final key = _sceneKey(unitId, checkpoint.scenarioId);
      if (unit == null ||
          !unit.checkpointContentIds.contains(contentId) ||
          !assessSceneKeys.contains(key) ||
          !assessSceneLinks[key]!.contains(checkpoint.missionContentLinkId) ||
          !checkpoint.score.isFinite ||
          checkpoint.score < 0 ||
          checkpoint.score > 1) {
        continue;
      }
      final previous = latestByScene[key];
      if (previous == null ||
          checkpoint.occurredAt.isAfter(previous.occurredAt)) {
        latestByScene[key] = checkpoint;
      }
    }
    final safeScenes =
        latestByScene.values
            .where((checkpoint) {
              final unit = unitsById[checkpoint.courseUnitId];
              return unit != null && checkpoint.score >= unit.passThreshold;
            })
            .toList(growable: false)
          ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    final safeSceneCount = safeScenes.length;
    final safeScenesTowardNextBeam = safeSceneCount == 0
        ? 0
        : ((safeSceneCount - 1) % normalizedScenesPerBeam) + 1;
    final plannedBeamCount = safeSceneCount == 0
        ? 0
        : ((safeSceneCount - 1) ~/ normalizedScenesPerBeam) + 1;

    var earnedExpressionCount = 0;
    String? latestSafeScenarioId;
    String? latestSafeExpressionKo;
    for (final checkpoint in safeScenes) {
      final expression = hanokExpressionForScenario(
        scenariosById[checkpoint.scenarioId],
      );
      if (expression == null) {
        continue;
      }
      earnedExpressionCount++;
      latestSafeScenarioId = checkpoint.scenarioId;
      latestSafeExpressionKo = expression;
    }

    String? nextScenarioId;
    String? nextExpressionKo;
    if (nextUnit != null) {
      for (final checkpointKey in nextUnit.checkpointContentIds) {
        const prefix = 'scenario:';
        if (!checkpointKey.startsWith(prefix)) {
          continue;
        }
        final scenarioId = checkpointKey.substring(prefix.length);
        if (!assessSceneKeys.contains(_sceneKey(nextUnit.id, scenarioId))) {
          continue;
        }
        final expression = hanokExpressionForScenario(
          scenariosById[scenarioId],
        );
        if (expression == null) {
          continue;
        }
        nextScenarioId = scenarioId;
        nextExpressionKo = expression;
        break;
      }
    }

    return HanokLearningReceipt(
      safeSceneCount: safeSceneCount,
      safeScenesTowardNextBeam: safeScenesTowardNextBeam,
      scenesPerBeam: normalizedScenesPerBeam,
      plannedBeamCount: plannedBeamCount,
      earnedExpressionCount: earnedExpressionCount,
      latestSafeScenarioId: latestSafeScenarioId,
      latestSafeExpressionKo: latestSafeExpressionKo,
      nextScenarioId: nextScenarioId,
      nextExpressionKo: nextExpressionKo,
    );
  }
}

/// Chooses one Korean expression that the scenario actually asks the learner
/// to produce. A learner-dialog line is an honest fallback for older scenes
/// without a productive quest; no UI copy is synthesized here.
String? hanokExpressionForScenario(Scenario? scenario) {
  if (scenario == null) {
    return null;
  }
  for (final quest in scenario.quests) {
    if (quest.type != QuestType.satzBauen && quest.type != QuestType.diktat) {
      continue;
    }
    final expression = quest.data['targetKo']?.toString().trim() ?? '';
    if (expression.isNotEmpty) {
      return expression;
    }
  }
  for (final line in scenario.dialog) {
    final expression = line.ko.trim();
    if (line.speaker == 'user' && expression.isNotEmpty) {
      return expression;
    }
  }
  return null;
}

String _sceneKey(String unitId, String scenarioId) =>
    '$unitId\u0000$scenarioId';
