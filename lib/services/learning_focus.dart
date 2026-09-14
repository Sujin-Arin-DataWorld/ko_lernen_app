import 'learning_journey.dart';
import 'package:flutter/foundation.dart';
import '../data/sori_activity_catalog.dart';
import '../models/course_mastery.dart';
import '../models/course_mission_brief.dart';
import '../models/curriculum.dart';
import 'account/cloud_write_session.dart';
import 'course_mission_navigation.dart';
import 'course_progress_service.dart';
import 'curriculum_catalog.dart';
import 'mission_recommender.dart';
import 'scenario_loader.dart';
import 'today_learning_snapshot.dart';

enum LearningFocusFailure { sourceUnavailable, destinationUnavailable }

/// One immutable read-only recommendation shared by Today and Learn.
class LearningFocus {
  const LearningFocus({
    required this.today,
    this.brief,
    this.destination,
    this.minutes,
    this.failure,
  });
  final TodayLearningSnapshot today;
  final CourseMissionBrief? brief;
  final TodayLearningDestination? destination;
  final int? minutes;
  final LearningFocusFailure? failure;
  bool get ready => failure == null && destination != null;
  String? get activityId => activityForRoute(destination?.route)?.id;

  static Future<LearningFocus> load({
    Future<TodayLearningSnapshot> Function()? loadToday,
    Future<CourseMissionBrief> Function(CoursePick)? loadBrief,
    Future<CourseMissionDestination?> Function(ContentLink)? resolve,
  }) async {
    final today = await (loadToday ?? TodayLearningSnapshotLoader.load)();
    if (today.isUnavailable) {
      return LearningFocus(
        today: today,
        failure: LearningFocusFailure.sourceUnavailable,
      );
    }
    CourseMissionBrief? brief;
    TodayLearningDestination? destination = today.destination;
    if (today.pick case final CoursePick pick) {
      brief = await (loadBrief ?? _loadBrief)(pick);
      final link = brief.firstLink;
      CourseMissionDestination? resolved;
      try {
        resolved = link == null
            ? null
            : await (resolve ?? directDestinationForCourseLink)(link);
      } catch (_) {
        return LearningFocus(
          today: today,
          brief: brief,
          failure: LearningFocusFailure.destinationUnavailable,
        );
      }
      destination = resolved == null
          ? null
          : TodayLearningDestination(
              route: resolved.route,
              arguments: resolved.arguments,
            );
      if (destination == null) {
        return LearningFocus(
          today: today,
          brief: brief,
          failure: LearningFocusFailure.destinationUnavailable,
        );
      }
    }
    return LearningFocus(
      today: today,
      brief: brief,
      destination: destination,
      minutes: activityForRoute(destination?.route)?.minutes,
    );
  }

  static Future<CourseMissionBrief> _loadBrief(CoursePick pick) async {
    final catalog = await CurriculumCatalog.load();
    final snapshot = await CourseProgressService.shared.readForDisplay();
    return CourseMissionBrief.from(
      unit: pick.unit,
      links: catalog.linksForCourseUnit(pick.unit.id),
      scenarios: await ScenarioLoader.load(),
      isCurrent: snapshot?.currentCourseUnitId == pick.unit.id,
      snapshot: snapshot ?? const CourseMasterySnapshot.empty(),
    );
  }
}

class LearningFocusController extends ChangeNotifier {
  LearningFocusController({
    Future<LearningFocus> Function()? loader,
    Object? Function()? accountLifetime,
  }) : _loader = loader ?? LearningFocus.load,
       _accountLifetime =
           accountLifetime ?? (() => cloudWriteSessionController.current);
  final Future<LearningFocus> Function() _loader;
  final Object? Function() _accountLifetime;
  LearningFocus? value;
  LearningJourneyResult? lastJourneyResult;
  Object? error;
  bool loading = false;
  bool launching = false;
  int generation = 0;
  bool _disposed = false;
  Future<void>? _request;

  Future<void> refresh({bool force = false}) {
    if (_disposed) {
      return Future.value();
    }
    if (!force && _request != null) {
      return _request!;
    }
    final request = ++generation;
    final account = _accountLifetime();
    loading = true;
    error = null;
    if (force) {
      value = null;
    }
    notifyListeners();
    return _request = (() async {
      try {
        final result = await _loader();
        if (_disposed ||
            request != generation ||
            account != _accountLifetime()) {
          return;
        }
        value = result;
      } catch (failure) {
        if (_disposed ||
            request != generation ||
            account != _accountLifetime()) {
          return;
        }
        value = null;
        error = failure;
      } finally {
        if (!_disposed && request == generation) {
          _request = null;
          loading = false;
          notifyListeners();
        }
      }
    })();
  }

  void recordReturn(LearningJourneyResult result) {
    if (_disposed) {
      return;
    }
    lastJourneyResult = result;
    notifyListeners();
  }

  bool claimLaunch() {
    if (_disposed || launching) {
      return false;
    }
    launching = true;
    notifyListeners();
    return true;
  }

  void releaseLaunch() {
    if (_disposed) {
      return;
    }
    launching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    generation++;
    super.dispose();
  }
}
