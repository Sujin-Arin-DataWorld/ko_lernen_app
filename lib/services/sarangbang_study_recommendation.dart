import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/pack_progress.dart';
import '../models/scenario.dart';
import '../models/vocab_pack.dart';
import 'course_progress_service.dart';
import 'curriculum_catalog.dart';
import 'mission_recommender.dart';
import 'pack_progress_service.dart';
import 'review_deck_service.dart';
import 'scenario_loader.dart';
import 'storage_service.dart';

/// The existing recommendation engine's result plus only the scenario record
/// needed to render a scenario title. It is deliberately a read-only value:
/// selecting a learning destination never awards, unlocks, or persists data.
class SarangbangStudyRecommendation {
  final MissionPick? pick;
  final Scenario? scenario;

  const SarangbangStudyRecommendation({required this.pick, this.scenario});
}

/// The established navigation surface for a recommendation.
///
/// Pack access remains an existing entitlement gate; this data value merely
/// identifies where that gate must run before navigation.
class SarangbangStudyDestination {
  final String route;
  final Object? arguments;
  final String? packAccessLevel;

  const SarangbangStudyDestination({
    required this.route,
    this.arguments,
    this.packAccessLevel,
  });

  @override
  bool operator ==(Object other) =>
      other is SarangbangStudyDestination &&
      other.route == route &&
      other.arguments == arguments &&
      other.packAccessLevel == packAccessLevel;

  @override
  int get hashCode => Object.hash(route, arguments, packAccessLevel);
}

/// Pure routing contract shared by the Sarangbang UI and its regression test.
SarangbangStudyDestination? sarangbangDestinationFor(MissionPick? pick) =>
    switch (pick) {
      CoursePick() => const SarangbangStudyDestination(
        route: '/course/mission',
      ),
      PackPick(:final pack) => SarangbangStudyDestination(
        route: '/vocab/pack',
        arguments: pack.id,
        packAccessLevel: pack.level.toUpperCase(),
      ),
      ReviewPick() => const SarangbangStudyDestination(route: '/review'),
      ScenarioPick(:final scenarioId) => SarangbangStudyDestination(
        route: '/scenario',
        arguments: scenarioId,
      ),
      null => null,
    };

/// Loads exactly the inputs the Home recommendation already supplies to
/// [recommendMission], then calls that function unchanged.
///
/// Each data family fails independently. This mirrors Home's best-effort
/// loading: a temporarily unavailable course snapshot must not hide an
/// otherwise valid review or scenario recommendation.
class SarangbangStudyRecommendationLoader {
  const SarangbangStudyRecommendationLoader._();

  static Future<SarangbangStudyRecommendation> load() async {
    final course = await _loadCourseInput();
    final nowNode = await _loadNowNode();
    final scenario = await _loadScenarioInput();
    final dueCount = await _loadDueCount();

    final pick = recommendMission(
      courseUnits: course.units,
      currentCourseUnitId: course.snapshot?.currentCourseUnitId,
      completedUnitIds: course.snapshot?.completedUnitIds.toSet() ?? const {},
      nowNode: nowNode,
      dueCount: dueCount,
      scenario: scenario.current == null
          ? null
          : (id: scenario.current!.id, level: scenario.current!.level),
      scenarioCompleted:
          scenario.current != null &&
          scenario.completed.contains(scenario.current!.id),
      userLevel: scenario.userLevel,
    );
    return SarangbangStudyRecommendation(
      pick: pick,
      scenario: scenario.current,
    );
  }

  static Future<_CourseInput> _loadCourseInput() async {
    try {
      final catalog = await CurriculumCatalog.load();
      final snapshot = await CourseProgressService.shared.refresh();
      return _CourseInput(units: catalog.courseUnits, snapshot: snapshot);
    } catch (_) {
      return const _CourseInput();
    }
  }

  static Future<({VocabPack pack, PackProgress progress})?>
  _loadNowNode() async {
    try {
      const levels = ['A1', 'A2', 'B1', 'B2'];
      String? nowId;
      List<({VocabPack pack, PackProgress progress})> nodes = const [];

      for (final level in levels) {
        final view = await PackProgressService.loadLevelView(level);
        for (final entry in view) {
          if (nowId == null &&
              entry.progress.status != PackStatus.cleared &&
              entry.progress.status != PackStatus.locked) {
            nowId = entry.pack.id;
            nodes = view;
          }
        }
        if (nowId != null) {
          break;
        }
        nodes = view;
      }

      if (nowId == null) {
        return null;
      }
      for (final entry in nodes) {
        if (entry.pack.id == nowId) {
          return entry;
        }
      }
    } catch (_) {
      // A later source (review/scenario) is still allowed to recommend.
    }
    return null;
  }

  static Future<_ScenarioInput> _loadScenarioInput() async {
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completed = Storage.completedScenarios.toSet();
    try {
      final scenarios = await ScenarioLoader.load();
      Scenario? current;
      for (final scenario in scenarios.where(
        (item) => item.level == userLevel,
      )) {
        if (!completed.contains(scenario.id)) {
          current = scenario;
          break;
        }
      }
      if (current == null) {
        for (final scenario in scenarios) {
          if (!completed.contains(scenario.id)) {
            current = scenario;
            break;
          }
        }
      }
      current ??= scenarios.isEmpty ? null : scenarios.first;
      return _ScenarioInput(
        current: current,
        completed: completed,
        userLevel: userLevel,
      );
    } catch (_) {
      return _ScenarioInput(completed: completed, userLevel: userLevel);
    }
  }

  static Future<int> _loadDueCount() async {
    try {
      final all = await ReviewDeckService.allReviewable();
      return Storage.todayGoalIds(all.map((entry) => entry.korean)).length;
    } catch (_) {
      return 0;
    }
  }
}

class _CourseInput {
  final List<CourseUnit> units;
  final CourseMasterySnapshot? snapshot;

  const _CourseInput({this.units = const [], this.snapshot});
}

class _ScenarioInput {
  final Scenario? current;
  final Set<String> completed;
  final LearnerLevel userLevel;

  const _ScenarioInput({
    this.current,
    required this.completed,
    required this.userLevel,
  });
}
