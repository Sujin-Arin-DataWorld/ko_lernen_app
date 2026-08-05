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

/// The established learning surface for a recommendation.
///
/// This is data only. Pack access remains an existing entitlement gate at the
/// point of navigation; reading a snapshot neither grants access nor writes
/// progress.
class TodayLearningDestination {
  final String route;
  final Object? arguments;
  final String? packAccessLevel;

  const TodayLearningDestination({
    required this.route,
    this.arguments,
    this.packAccessLevel,
  });

  @override
  bool operator ==(Object other) =>
      other is TodayLearningDestination &&
      other.route == route &&
      other.arguments == arguments &&
      other.packAccessLevel == packAccessLevel;

  @override
  int get hashCode => Object.hash(route, arguments, packAccessLevel);
}

/// Pure route contract for the existing recommendation engine.
TodayLearningDestination? todayLearningDestinationFor(MissionPick? pick) =>
    switch (pick) {
      CoursePick() => const TodayLearningDestination(route: '/course/mission'),
      PackPick(:final pack) => TodayLearningDestination(
        route: '/vocab/pack',
        arguments: pack.id,
        packAccessLevel: pack.level.toUpperCase(),
      ),
      ReviewPick() => const TodayLearningDestination(route: '/review'),
      ScenarioPick(:final scenarioId) => TodayLearningDestination(
        route: '/scenario',
        arguments: scenarioId,
      ),
      null => null,
    };

/// The exact, already-established inputs of [recommendMission].
///
/// A facade owns input assembly so Home and the Sarangbang cannot drift apart
/// in priority, course evidence, review thresholds, or scenario eligibility.
class TodayLearningInputs {
  final List<CourseUnit> courseUnits;
  final String? currentCourseUnitId;
  final Set<String> completedUnitIds;
  final ({VocabPack pack, PackProgress progress})? nowNode;
  final int dueCount;
  final Scenario? scenario;
  final bool scenarioCompleted;
  final LearnerLevel userLevel;

  TodayLearningInputs({
    List<CourseUnit> courseUnits = const [],
    this.currentCourseUnitId,
    Set<String> completedUnitIds = const {},
    this.nowNode,
    this.dueCount = 0,
    this.scenario,
    this.scenarioCompleted = false,
    required this.userLevel,
  }) : courseUnits = List.unmodifiable(courseUnits),
       completedUnitIds = Set.unmodifiable(completedUnitIds);
}

/// A read-only answer to “what should I learn next today?”.
///
/// It does not persist completion, alter a reward, unlock a course, or choose
/// a new route scheme. [presentationRevision] only versions the UI-facing
/// contract, never learner progress or cloud state.
class TodayLearningSnapshot {
  static const int currentPresentationRevision = 1;

  final MissionPick? pick;
  final Scenario? scenario;
  final TodayLearningDestination? destination;
  final int dueCount;
  final int hardCount;
  final int presentationRevision;

  const TodayLearningSnapshot({
    required this.pick,
    this.scenario,
    this.destination,
    this.dueCount = 0,
    this.hardCount = 0,
    this.presentationRevision = currentPresentationRevision,
  });

  factory TodayLearningSnapshot.fromInputs(
    TodayLearningInputs inputs, {
    int hardCount = 0,
  }) {
    final pick = recommendMission(
      courseUnits: inputs.courseUnits,
      currentCourseUnitId: inputs.currentCourseUnitId,
      completedUnitIds: inputs.completedUnitIds,
      nowNode: inputs.nowNode,
      dueCount: inputs.dueCount,
      scenario: inputs.scenario == null
          ? null
          : (id: inputs.scenario!.id, level: inputs.scenario!.level),
      scenarioCompleted: inputs.scenarioCompleted,
      userLevel: inputs.userLevel,
    );
    return TodayLearningSnapshot(
      pick: pick,
      scenario: inputs.scenario,
      destination: todayLearningDestinationFor(pick),
      dueCount: inputs.dueCount,
      hardCount: hardCount,
    );
  }
}

/// Loads the one shared read-only snapshot used by Home and the Sarangbang.
///
/// Each source family fails closed to its existing neutral input so a course
/// read failure cannot hide an otherwise valid review or scenario suggestion.
class TodayLearningSnapshotLoader {
  const TodayLearningSnapshotLoader._();

  static Future<TodayLearningSnapshot> load() async {
    final courseFuture = _loadCourseInput();
    final nowNodeFuture = _loadNowNode();
    final scenarioFuture = _loadScenarioInput();
    final reviewFuture = _loadReviewInput();

    final course = await courseFuture;
    final nowNode = await nowNodeFuture;
    final scenario = await scenarioFuture;
    final review = await reviewFuture;

    return TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        courseUnits: course.units,
        currentCourseUnitId: course.snapshot?.currentCourseUnitId,
        completedUnitIds: course.snapshot?.completedUnitIds.toSet() ?? const {},
        nowNode: nowNode,
        dueCount: review.dueCount,
        scenario: scenario.current,
        scenarioCompleted:
            scenario.current != null &&
            scenario.completed.contains(scenario.current!.id),
        userLevel: scenario.userLevel,
      ),
      hardCount: review.hardCount,
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
      for (final level in levels) {
        final view = await PackProgressService.loadLevelView(level);
        for (final entry in view) {
          if (entry.progress.status != PackStatus.cleared &&
              entry.progress.status != PackStatus.locked) {
            return entry;
          }
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

  static Future<_ReviewInput> _loadReviewInput() async {
    try {
      final all = await ReviewDeckService.allReviewable();
      final koreans = all.map((entry) => entry.korean);
      return _ReviewInput(
        dueCount: Storage.todayGoalIds(koreans).length,
        hardCount: Storage.hardIds(koreans).length,
      );
    } catch (_) {
      return const _ReviewInput();
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

class _ReviewInput {
  final int dueCount;
  final int hardCount;

  const _ReviewInput({this.dueCount = 0, this.hardCount = 0});
}
