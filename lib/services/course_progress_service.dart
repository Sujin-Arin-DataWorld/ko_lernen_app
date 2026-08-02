import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';

/// App-scoped, serialized access to the local course-mastery graph.
///
/// Screens can arrive from several routes at once (for example a scenario
/// completion and a vocabulary review). A single service instance plus this
/// queue prevents their read-modify-write cycles from overwriting each other.
class CourseProgressService {
  CourseProgressService(this._serviceLoader);

  factory CourseProgressService.app() => CourseProgressService(() async {
    final catalog = await CurriculumCatalog.load();
    return CourseMasteryService(catalog);
  });

  static final CourseProgressService shared = CourseProgressService.app();

  final Future<CourseMasteryService> Function() _serviceLoader;
  Future<CourseMasteryService>? _serviceFuture;
  Future<void> _tail = Future<void>.value();

  Future<CourseMasteryService> _service() =>
      _serviceFuture ??= _serviceLoader();

  Future<T> _serialized<T>(Future<T> Function(CourseMasteryService) action) {
    final scheduled = _tail.then((_) async => action(await _service()));
    // A rejected write must not poison the queue: the caller still receives
    // its own error, while a later user action can safely retry.
    _tail = scheduled.then<void>((_) {}, onError: (_, __) {});
    return scheduled;
  }

  Future<CourseMasterySnapshot> refresh() =>
      _serialized((service) => service.refresh());

  Future<CourseMasterySnapshot> initializeForPlacement(String levelCode) =>
      _serialized((service) => service.initializeForPlacement(levelCode));

  Future<CourseMasterySnapshot> selectCourseUnit(String courseUnitId) =>
      _serialized((service) => service.selectCourseUnit(courseUnitId));

  Future<Map<String, CourseContentState>> conceptStates(
    Iterable<String> conceptIds,
  ) => _serialized(
    (service) => Future<Map<String, CourseContentState>>.value({
      for (final conceptId in conceptIds)
        conceptId: service.stateForConcept(conceptId),
    }),
  );

  Future<List<RemediationRecommendation>> reviewQueue() => _serialized(
    (service) =>
        Future<List<RemediationRecommendation>>.value(service.reviewQueue),
  );

  Future<CourseUpdate> recordContentAttempt(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect, {
    String? conceptId,
    MasteryErrorReason? errorReason,
    DateTime? occurredAt,
    double? score,
  }) => _serialized(
    (service) => service.recordContentAttempt(
      kind,
      contentId,
      isCorrect,
      conceptId: conceptId,
      errorReason: errorReason,
      occurredAt: occurredAt,
      score: score,
    ),
  );

  Future<CourseUpdate> recordScenarioCheckpoint(
    String scenarioId,
    double score, {
    DateTime? occurredAt,
  }) => _serialized(
    (service) => service.recordScenarioCheckpoint(
      scenarioId,
      score,
      occurredAt: occurredAt,
    ),
  );
}
