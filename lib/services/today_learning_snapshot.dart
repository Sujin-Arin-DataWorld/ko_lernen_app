import 'package:connectivity_plus/connectivity_plus.dart';

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
/// This is data only. Pack access is universally open, while navigation still
/// validates the destination; reading a snapshot never writes progress.
class TodayLearningDestination {
  final String route;
  final Object? arguments;

  const TodayLearningDestination({required this.route, this.arguments});

  @override
  bool operator ==(Object other) =>
      other is TodayLearningDestination &&
      other.route == route &&
      other.arguments == arguments;

  @override
  int get hashCode => Object.hash(route, arguments);
}

/// Pure route contract for the existing recommendation engine.
TodayLearningDestination? todayLearningDestinationFor(MissionPick? pick) =>
    switch (pick) {
      CoursePick() => const TodayLearningDestination(route: '/course/mission'),
      PackPick(:final pack) => TodayLearningDestination(
        route: '/vocab/pack',
        arguments: pack.id,
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

/// Production source families that contribute to a Today recommendation.
///
/// Naming the failed family lets the presentation stay conservative without
/// throwing away healthy, read-only inputs that can still help diagnostics.
enum TodayLearningSource { course, pack, scenario, review }

enum TodayLearningAvailability { ready, unavailable }

/// Coarse platform connectivity only. `online` means a network transport is
/// present, not that every server request is guaranteed to succeed.
enum TodayNetworkStatus { online, offline, unknown }

/// Typed reason for a snapshot that cannot be presented as fully refreshed.
/// Local parse/storage failures must never be rendered as an internet outage.
enum TodayLearningUnavailableReason { offline, remoteService, localData }

/// A source that actually performs a remote read can preserve that typed
/// failure without leaking raw exceptions into the presentation layer.
class TodayLearningSourceFailure implements Exception {
  const TodayLearningSourceFailure.remote()
    : reason = TodayLearningUnavailableReason.remoteService;

  const TodayLearningSourceFailure.offline()
    : reason = TodayLearningUnavailableReason.offline;

  final TodayLearningUnavailableReason reason;
}

typedef TodayNetworkStatusReader = Future<TodayNetworkStatus> Function();

/// Read-only platform connectivity used by Home and the snapshot loader.
abstract final class TodayLearningConnectivity {
  static Future<TodayNetworkStatus> currentStatus() async {
    try {
      return _statusFor(await Connectivity().checkConnectivity());
    } catch (_) {
      return TodayNetworkStatus.unknown;
    }
  }

  static Stream<TodayNetworkStatus> get statusChanges =>
      Connectivity().onConnectivityChanged.map(_statusFor).distinct();

  static TodayNetworkStatus _statusFor(List<ConnectivityResult> results) {
    if (results.isEmpty) return TodayNetworkStatus.unknown;
    return results.any((result) => result != ConnectivityResult.none)
        ? TodayNetworkStatus.online
        : TodayNetworkStatus.offline;
  }
}

typedef TodayCourseSourceValue = ({
  List<CourseUnit> units,
  CourseMasterySnapshot? snapshot,
});
typedef TodayNowNodeSourceValue = ({VocabPack pack, PackProgress progress})?;
typedef TodayScenarioSourceValue = ({
  Scenario? current,
  Set<String> completed,
  LearnerLevel userLevel,
});
typedef TodayReviewSourceValue = ({int dueCount, int hardCount});

/// Injectable, read-only production readers used by tests and UX previews.
///
/// A reader must only assemble recommendation inputs. It must not unlock,
/// grant, complete, or otherwise mutate learning progress.
class TodayLearningSourceReaders {
  const TodayLearningSourceReaders({
    required this.course,
    required this.nowNode,
    required this.scenario,
    required this.review,
  });

  final Future<TodayCourseSourceValue> Function() course;
  final Future<TodayNowNodeSourceValue> Function() nowNode;
  final Future<TodayScenarioSourceValue> Function() scenario;
  final Future<TodayReviewSourceValue> Function() review;
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
  final TodayLearningAvailability availability;
  final TodayLearningUnavailableReason? unavailableReason;
  final Set<TodayLearningSource> unavailableSources;

  const TodayLearningSnapshot({
    required this.pick,
    this.scenario,
    this.destination,
    this.dueCount = 0,
    this.hardCount = 0,
    this.presentationRevision = currentPresentationRevision,
    this.availability = TodayLearningAvailability.ready,
    this.unavailableReason,
    this.unavailableSources = const {},
  }) : assert(
         availability == TodayLearningAvailability.ready
             ? unavailableReason == null
             : unavailableReason != null,
       );

  bool get isUnavailable =>
      availability == TodayLearningAvailability.unavailable;

  bool get isOffline =>
      unavailableReason == TodayLearningUnavailableReason.offline;

  factory TodayLearningSnapshot.fromInputs(
    TodayLearningInputs inputs, {
    int hardCount = 0,
    TodayLearningAvailability availability = TodayLearningAvailability.ready,
    TodayLearningUnavailableReason? unavailableReason,
    Set<TodayLearningSource> unavailableSources = const {},
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
      availability: availability,
      unavailableReason: unavailableReason,
      unavailableSources: Set.unmodifiable(unavailableSources),
    );
  }
}

/// Loads the one shared read-only snapshot used by Home and the Sarangbang.
///
/// A failed family keeps its neutral input so healthy readers can still finish,
/// but the returned snapshot is explicitly unavailable. Production UI must not
/// present that partial recommendation as a fully refreshed Today promise.
class TodayLearningSnapshotLoader {
  const TodayLearningSnapshotLoader._();

  static Future<TodayLearningSnapshot> load({
    TodayLearningSourceReaders? readers,
    TodayNetworkStatusReader? networkStatusReader,
  }) async {
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completedScenarios = Storage.completedScenarios.toSet();
    final sourceReaders =
        readers ??
        const TodayLearningSourceReaders(
          course: _loadCourseInput,
          nowNode: _loadNowNode,
          scenario: _loadScenarioInput,
          review: _loadReviewInput,
        );
    final networkFuture = _readNetworkStatus(
      networkStatusReader ?? TodayLearningConnectivity.currentStatus,
    );

    // Start every read before awaiting so a slow source does not serialize the
    // remaining local reads.
    final courseFuture = _capture<TodayCourseSourceValue>(
      sourceReaders.course,
      (units: const <CourseUnit>[], snapshot: null),
    );
    final nowNodeFuture = _capture<TodayNowNodeSourceValue>(
      sourceReaders.nowNode,
      null,
    );
    final scenarioFuture = _capture<TodayScenarioSourceValue>(
      sourceReaders.scenario,
      (current: null, completed: completedScenarios, userLevel: userLevel),
    );
    final reviewFuture = _capture<TodayReviewSourceValue>(
      sourceReaders.review,
      (dueCount: 0, hardCount: 0),
    );

    final course = await courseFuture;
    final nowNode = await nowNodeFuture;
    final scenario = await scenarioFuture;
    final review = await reviewFuture;
    final networkStatus = await networkFuture;

    final unavailableSources = <TodayLearningSource>{
      if (course.failed) TodayLearningSource.course,
      if (nowNode.failed) TodayLearningSource.pack,
      if (scenario.failed) TodayLearningSource.scenario,
      if (review.failed) TodayLearningSource.review,
    };
    final sourceReasons = <TodayLearningUnavailableReason>{
      if (course.failureReason case final reason?) reason,
      if (nowNode.failureReason case final reason?) reason,
      if (scenario.failureReason case final reason?) reason,
      if (review.failureReason case final reason?) reason,
    };
    final unavailableReason = networkStatus == TodayNetworkStatus.offline
        ? TodayLearningUnavailableReason.offline
        : sourceReasons.contains(TodayLearningUnavailableReason.offline)
        ? TodayLearningUnavailableReason.offline
        : sourceReasons.contains(TodayLearningUnavailableReason.remoteService)
        ? TodayLearningUnavailableReason.remoteService
        : sourceReasons.isNotEmpty
        ? TodayLearningUnavailableReason.localData
        : null;

    return TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        courseUnits: course.value.units,
        currentCourseUnitId: course.value.snapshot?.currentCourseUnitId,
        completedUnitIds:
            course.value.snapshot?.completedUnitIds.toSet() ?? const {},
        nowNode: nowNode.value,
        dueCount: review.value.dueCount,
        scenario: scenario.value.current,
        scenarioCompleted:
            scenario.value.current != null &&
            scenario.value.completed.contains(scenario.value.current!.id),
        userLevel: scenario.value.userLevel,
      ),
      hardCount: review.value.hardCount,
      availability: unavailableReason == null
          ? TodayLearningAvailability.ready
          : TodayLearningAvailability.unavailable,
      unavailableReason: unavailableReason,
      unavailableSources: unavailableSources,
    );
  }

  static Future<TodayCourseSourceValue> _loadCourseInput() async {
    final catalog = await CurriculumCatalog.load();
    final snapshot = await CourseProgressService.shared.readForDisplay();
    if (snapshot == null) {
      return (units: const <CourseUnit>[], snapshot: null);
    }
    return (units: catalog.courseUnits, snapshot: snapshot);
  }

  static Future<TodayNowNodeSourceValue> _loadNowNode() async {
    final level =
        (LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1)
            .display;
    final view = await PackProgressService.loadLevelView(level);
    for (final entry in view) {
      if (entry.progress.status != PackStatus.cleared) {
        return entry;
      }
    }
    return null;
  }

  static Future<TodayScenarioSourceValue> _loadScenarioInput() async {
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final completed = Storage.completedScenarios.toSet();
    final scenarios = await ScenarioLoader.load();
    Scenario? current;
    for (final scenario in scenarios.where((item) => item.level == userLevel)) {
      if (!completed.contains(scenario.id)) {
        current = scenario;
        break;
      }
    }
    // Advanced levels do not have dedicated scenario packs yet. Prefer the
    // closest available lower level instead of dropping a C1/C2 learner into
    // the first A1 scenario in the asset.
    if (current == null) {
      for (
        var rank = userLevel.rank - 1;
        rank >= LearnerLevel.a1.rank;
        rank--
      ) {
        final fallbackLevel = LearnerLevel.values[rank];
        for (final scenario in scenarios.where(
          (item) => item.level == fallbackLevel,
        )) {
          if (!completed.contains(scenario.id)) {
            current = scenario;
            break;
          }
        }
        if (current != null) break;
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
    return (current: current, completed: completed, userLevel: userLevel);
  }

  static Future<TodayReviewSourceValue> _loadReviewInput() async {
    final all = await ReviewDeckService.allReviewable();
    final koreans = all.map((entry) => entry.korean);
    final today = ReviewDeckService.todaySelectionForLevel(
      all,
      levelCode: Storage.userLevelCode,
    );
    return (
      dueCount: today.words.length,
      hardCount: Storage.hardIds(koreans).length,
    );
  }
}

class _Captured<T> {
  const _Captured({required this.value, this.failureReason});

  final T value;
  final TodayLearningUnavailableReason? failureReason;
  bool get failed => failureReason != null;
}

Future<_Captured<T>> _capture<T>(Future<T> Function() read, T fallback) async {
  try {
    return _Captured(value: await read());
  } on TodayLearningSourceFailure catch (error) {
    return _Captured(value: fallback, failureReason: error.reason);
  } catch (_) {
    return _Captured(
      value: fallback,
      failureReason: TodayLearningUnavailableReason.localData,
    );
  }
}

Future<TodayNetworkStatus> _readNetworkStatus(
  TodayNetworkStatusReader read,
) async {
  try {
    return await read();
  } catch (_) {
    // A platform probe failure is unknown, not proof that the learner is
    // offline. Healthy local learning remains available.
    return TodayNetworkStatus.unknown;
  }
}
