import 'dart:convert';

import '../models/course_mastery.dart';
import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import 'account/reconciliation_errors.dart';
import 'course_mastery_service.dart';
import 'course_segment_catalog.dart';
import 'curriculum_catalog.dart';
import 'productive_assessment_service.dart';
import 'storage_service.dart';

/// A validated local course snapshot together with the canonical generation
/// captured after any required legacy migration has durably completed.
class CourseMasteryLocalCapture {
  const CourseMasteryLocalCapture({
    required this.snapshot,
    required this.canonicalGeneration,
  });

  final CourseMasterySnapshot? snapshot;
  final String canonicalGeneration;
}

/// One coherent view of the course graph and its scalar mirrors.
///
/// Onboarding placement verification must not read a scalar before a queued
/// course write and the canonical graph after it. Keeping this capture inside
/// [CourseProgressService]'s queue makes every field belong to one generation.
class CoursePlacementVerificationCapture {
  const CoursePlacementVerificationCapture({
    required this.snapshot,
    required this.canonicalGeneration,
    required this.placementLevelCode,
    required this.currentCourseUnitId,
    required this.browseLevelCode,
  });

  final CourseMasterySnapshot? snapshot;
  final String canonicalGeneration;
  final String? placementLevelCode;
  final String? currentCourseUnitId;
  final String? browseLevelCode;
}

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

  /// Waits for every admitted course mutation, performs a destructive local
  /// storage wipe, then drops the in-memory graph before later callers run.
  ///
  /// Clearing preferences outside this queue is racy: an earlier fire-and-
  /// forget course write can otherwise finish after the wipe and resurrect
  /// the deleted learner graph. Later course operations are queued behind this
  /// barrier and therefore construct a fresh service from the wiped storage.
  Future<void> runLocalStorageWipeBarrier(
    Future<void> Function() wipeStorage,
  ) => _serializedOperation(() async {
    try {
      await wipeStorage();
    } finally {
      _serviceFuture = null;
    }
  });

  Future<T> _serialized<T>(Future<T> Function(CourseMasteryService) action) {
    return _serializedOperation(() async => action(await _service()));
  }

  Future<T> _serializedOperation<T>(Future<T> Function() action) {
    final scheduled = _tail.then((_) => action());
    // A rejected write must not poison the queue: the caller still receives
    // its own error, while a later user action can safely retry.
    _tail = scheduled.then<void>((_) {}, onError: (_, __) {});
    return scheduled;
  }

  Future<CourseMasterySnapshot> refresh() =>
      _serialized((service) => service.refresh());

  /// Read-only screen load. Unlike [refresh], this never synthesizes or
  /// persists a canonical snapshot when the learner has not started a course.
  Future<CourseMasterySnapshot?> readForDisplay() =>
      _serialized((service) async => service.readForDisplay());

  /// Serializes capture with learner actions so a backup or account
  /// reconciliation sees either the preexisting validated v2 state or the
  /// generation written by a completed legacy migration, never an in-between
  /// set of mirrors.
  Future<CourseMasteryLocalCapture> captureForCloudReconciliation() =>
      _serialized((service) async {
        final snapshot = await service.migrateForCloudCapture();
        return CourseMasteryLocalCapture(
          snapshot: snapshot,
          canonicalGeneration: Storage.courseMasterySnapshotRawJson,
        );
      });

  /// Captures a crash-safe placement read-back for the onboarding journal.
  ///
  /// A retained V1 graph is promoted through the same non-mirroring migration
  /// used by account reconciliation. This preserves its evidence while leaving
  /// the independent legacy account/library level untouched until the learner
  /// confirms setup.
  Future<CoursePlacementVerificationCapture>
  captureForPlacementVerification() => _serializedOperation(() async {
    CourseMasteryService? loadedService;
    Future<CourseMasteryService> service() async =>
        loadedService ??= await _service();

    if (Storage.courseMasterySnapshotRawJson.trim().isEmpty &&
        Storage.legacyCourseMasteryRawJson.trim().isNotEmpty) {
      await (await service()).migrateForCloudCapture();
    }
    final canonicalGeneration = Storage.courseMasterySnapshotRawJson;
    final snapshot = canonicalGeneration.trim().isEmpty
        ? null
        : (await service()).readForDisplay();
    return CoursePlacementVerificationCapture(
      snapshot: snapshot,
      canonicalGeneration: canonicalGeneration,
      placementLevelCode: Storage.dedicatedCoursePlacementLevelCode,
      currentCourseUnitId: Storage.courseUnitId,
      browseLevelCode: Storage.browseLevelCode,
    );
  });

  Future<CourseMasterySnapshot> initializeForPlacement(
    String levelCode, {
    bool syncBrowseLevel = false,
    bool preserveHistory = false,
    String? expectedGeneration,
  }) => _serialized(
    (service) => service.initializeForPlacement(
      levelCode,
      syncBrowseLevel: syncBrowseLevel,
      preserveHistory: preserveHistory,
      expectedGeneration: expectedGeneration,
    ),
  );

  /// Repairs placement mirrors from an unchanged canonical graph when a
  /// process stopped between SharedPreferences writes; otherwise performs the
  /// normal placement initialization.
  ///
  /// Both the decision and write run in the course queue. The caller's raw
  /// canonical generation fences the entire operation, so a newer learner
  /// action cannot be replaced by a repair based on an older onboarding read.
  Future<CourseMasterySnapshot> initializeOrRepairForPlacement(
    String levelCode, {
    bool preserveHistory = false,
    String? expectedGeneration,
  }) => _serialized((service) async {
    final normalizedLevel = levelCode.trim().toLowerCase();
    final canonicalGeneration = Storage.courseMasterySnapshotRawJson;
    if (expectedGeneration != null &&
        canonicalGeneration != expectedGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
    final canonical = canonicalGeneration.trim().isEmpty
        ? null
        : service.readForDisplay();
    if (canonical?.placementLevel == normalizedLevel) {
      void assertExpectedGeneration() {
        if (expectedGeneration != null &&
            Storage.courseMasterySnapshotRawJson != expectedGeneration) {
          throw const LocalReconciliationGenerationConflict();
        }
      }

      return service.applyReconciledSnapshot(
        canonical!,
        expectedGeneration: expectedGeneration,
        assertCurrentWrite: expectedGeneration == null
            ? null
            : assertExpectedGeneration,
      );
    }
    return service.initializeForPlacement(
      levelCode,
      syncBrowseLevel: false,
      preserveHistory: preserveHistory,
      expectedGeneration: expectedGeneration,
    );
  });

  Future<CourseMasterySnapshot> selectCourseUnit(String courseUnitId) =>
      _serialized((service) => service.selectCourseUnit(courseUnitId));

  Future<CourseMasterySnapshot> applyReconciledSnapshot(
    CourseMasterySnapshot snapshot, {
    required String? expectedGeneration,
    void Function()? assertCurrentWrite,
  }) => _serialized(
    (service) => service.applyReconciledSnapshot(
      snapshot,
      expectedGeneration: expectedGeneration,
      assertCurrentWrite: assertCurrentWrite,
    ),
  );

  Future<CourseMasterySnapshot> mergeCloudSnapshotJson(
    String raw, {
    required String? expectedGeneration,
    void Function()? beforeRead,
    void Function()? beforeWrite,
  }) => _serialized((service) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'Course mastery cloud data must be an object.',
      );
    }
    final remote = CourseMasterySnapshot.decodeAndMigrate(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
    beforeRead?.call();
    final local = service.readForReconciliation();
    final result = service.mergeForReconciliation(local: local, remote: remote);
    if (!result.isValid) {
      final details = result.conflicts
          .map((conflict) => '${conflict.kind.name}:${conflict.id}')
          .join(',');
      throw FormatException('Course mastery merge conflicts: $details');
    }
    beforeWrite?.call();
    return service.applyReconciledSnapshot(
      result.snapshot!,
      expectedGeneration: expectedGeneration,
    );
  });

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
    CoursePracticeContext? courseContext,
    String? conceptId,
    MasteryErrorReason? errorReason,
    DateTime? occurredAt,
    double? score,
  }) => _serialized(
    (service) => service.recordContentAttempt(
      kind,
      contentId,
      isCorrect,
      courseContext: courseContext,
      conceptId: conceptId,
      errorReason: errorReason,
      occurredAt: occurredAt,
      score: score,
    ),
  );

  Future<CourseUpdate> recordScenarioCheckpoint(
    String scenarioId,
    double score, {
    CoursePracticeContext? courseContext,
    DateTime? occurredAt,
  }) => _serialized(
    (service) => service.recordScenarioCheckpoint(
      scenarioId,
      score,
      courseContext: courseContext,
      occurredAt: occurredAt,
    ),
  );

  /// Productive proof uses a separate serialized write path and cannot invoke
  /// sequential course advancement during reassessment.
  Future<ProductiveCourseUpdate> recordProductiveAssessment({
    required ProductiveAssessmentResult result,
    required ProductiveAssessmentCatalog assessmentCatalog,
    required CourseSegmentCatalog segmentCatalog,
  }) => _serialized(
    (service) => service.recordProductiveAssessment(
      result: result,
      assessmentCatalog: assessmentCatalog,
      segmentCatalog: segmentCatalog,
    ),
  );

  /// Project source-review receipts use the same serialized CourseMastery
  /// writer as productive seals but never advance the course pointer.
  Future<ProductiveProjectStepUpdate> recordProductiveProjectStep({
    required ProductiveProjectStepReviewResult result,
    required ProductiveAssessmentCatalog assessmentCatalog,
    required CourseSegmentCatalog segmentCatalog,
  }) => _serialized(
    (service) => service.recordProductiveProjectStep(
      result: result,
      assessmentCatalog: assessmentCatalog,
      segmentCatalog: segmentCatalog,
    ),
  );
}
