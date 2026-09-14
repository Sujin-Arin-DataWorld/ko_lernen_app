import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/account/reconciliation_errors.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'support/productive_assessment_fixture.dart';

class RejectableStore implements PreferenceStringStore {
  final values = <String, String>{};
  final cache = <String, String>{};
  bool rejectCanonical = false;
  bool throwCanonical = false;
  bool unknownCanonical = false;
  bool failReload = false;
  Completer<void>? canonicalEntered;
  Completer<void>? releaseCanonical;
  final failure = StateError('platform write failed');

  @override
  bool containsKey(String key) => cache.containsKey(key);
  @override
  String? getString(String key) => cache[key];
  @override
  Future<void> reload() async {
    if (failReload) {
      throw StateError('reload unavailable');
    }
    cache
      ..clear()
      ..addAll(values);
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    cache.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    cache[key] = value;
    if (key == Storage.courseMasterySnapshotPreferenceKey) {
      canonicalEntered?.complete();
      canonicalEntered = null;
      await releaseCanonical?.future;
      if (unknownCanonical) {
        unknownCanonical = false;
        values[key] = value;
        throwCanonical = true;
        throw failure;
      }
      if (throwCanonical) {
        throw failure;
      }
      if (rejectCanonical) {
        return false;
      }
    }
    values[key] = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CurriculumCatalog catalog;
  late List<String> ids;
  late RejectableStore store;
  late CourseMasteryService service;
  late CourseProgressService progress;

  setUpAll(() async {
    catalog = await CurriculumCatalog.load();
    ids = catalog.contentLinks
        .where((link) => link.contentKind == CurriculumContentKind.vocab)
        .map((link) => link.contentId)
        .toSet()
        .take(2)
        .toList();
    expect(ids.length, 2);
  });
  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    store = RejectableStore();
    service = CourseMasteryService(catalog, snapshotPreferences: store);
    await service.initializeForPlacement('a1');
    progress = CourseProgressService(() async => service);
  });

  Future<void> rejectFirstAttempt() async {
    store.rejectCanonical = true;
    await expectLater(
      progress.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.first,
        true,
      ),
      throwsA(isA<PreferenceWriteException>()),
    );
  }

  test('rejected evidence is not published in the service snapshot', () async {
    final durableBefore =
        store.values[Storage.courseMasterySnapshotPreferenceKey];
    await rejectFirstAttempt();
    expect(
      store.values[Storage.courseMasterySnapshotPreferenceKey],
      durableBefore,
    );
    expect(
      service.snapshot.evidence,
      isEmpty,
      reason: 'A rejected write must not publish uncommitted mastery evidence',
    );
  });

  test(
    'a later successful queued write does not save the rejected attempt',
    () async {
      await rejectFirstAttempt();
      store.rejectCanonical = false;
      await progress.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.last,
        true,
      );
      final durable =
          jsonDecode(store.values[Storage.courseMasterySnapshotPreferenceKey]!)
              as Map;
      final savedIds = (durable['evidence'] as List)
          .map((entry) => (entry as Map)['contentId'])
          .toList();
      expect(savedIds, contains(ids.last));
      expect(
        savedIds,
        isNot(contains(ids.first)),
        reason:
            'A rejected attempt must not hitchhike on a later durable write',
      );
    },
  );

  test('pending write keeps confirmed snapshot visible until commit', () async {
    final before = service.snapshot;
    final entered = store.canonicalEntered = Completer<void>();
    final release = store.releaseCanonical = Completer<void>();
    final write = progress.recordContentAttempt(
      CurriculumContentKind.vocab,
      ids.first,
      true,
    );
    await entered.future;
    final pendingSnapshot = service.snapshot;
    release.complete();
    await write;
    expect(pendingSnapshot, same(before));
    expect(
      service.snapshot.evidence.map((e) => e.contentId),
      contains(ids.first),
    );
  });

  test(
    'throwing write preserves the original error and confirmed snapshot',
    () async {
      final before = service.snapshot;
      store.throwCanonical = true;
      await expectLater(
        progress.recordContentAttempt(
          CurriculumContentKind.vocab,
          ids.first,
          true,
        ),
        throwsA(
          isA<PreferenceWriteException>().having(
            (e) => e.cause,
            'original cause',
            same(store.failure),
          ),
        ),
      );
      expect(service.snapshot, same(before));
      store.throwCanonical = false;
      await progress.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.last,
        true,
      );
      expect(
        service.snapshot.evidence.map((e) => e.contentId),
        isNot(contains(ids.first)),
      );
    },
  );

  test(
    'unknown commit blocks reads and mutations until durable recovery',
    () async {
      final before = service.snapshot;
      store.unknownCanonical = true;
      store.failReload = true;
      await expectLater(
        progress.recordContentAttempt(
          CurriculumContentKind.vocab,
          ids.first,
          true,
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      final uncertainDurable =
          store.values[Storage.courseMasterySnapshotPreferenceKey];
      expect(service.snapshot, same(before));
      await expectLater(
        progress.readForDisplay(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      await expectLater(
        progress.recordContentAttempt(
          CurriculumContentKind.vocab,
          ids.last,
          true,
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(
        store.values[Storage.courseMasterySnapshotPreferenceKey],
        uncertainDurable,
      );
      store.failReload = false;
      store.throwCanonical = false;
      await expectLater(
        progress.applyReconciledSnapshot(
          before,
          expectedGeneration: jsonEncode(before.toJson()),
        ),
        throwsA(isA<LocalReconciliationGenerationConflict>()),
      );
      await progress.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.last,
        true,
      );
      expect(
        service.snapshot.evidence.map((e) => e.contentId),
        containsAll(ids),
      );
      expect(
        service.snapshot.toJson(),
        jsonDecode(store.values[Storage.courseMasterySnapshotPreferenceKey]!),
      );
    },
  );

  test(
    'unknown rejected write recovers without replaying rejected evidence',
    () async {
      final before = service.snapshot;
      store.throwCanonical = true;
      store.failReload = true;
      await expectLater(
        progress.recordContentAttempt(
          CurriculumContentKind.vocab,
          ids.first,
          true,
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(service.snapshot, same(before));
      store.throwCanonical = false;
      store.failReload = false;
      await progress.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.last,
        true,
      );
      expect(
        service.snapshot.evidence.map((e) => e.contentId),
        isNot(contains(ids.first)),
      );
      expect(
        service.snapshot.evidence.map((e) => e.contentId),
        contains(ids.last),
      );
      expect(
        service.snapshot.toJson(),
        jsonDecode(store.values[Storage.courseMasterySnapshotPreferenceKey]!),
      );
    },
  );

  test(
    'failed empty initialization never marks synthesized state loaded',
    () async {
      Storage.resetCourseMasteryForTesting();
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      store = RejectableStore()..rejectCanonical = true;
      service = CourseMasteryService(catalog, snapshotPreferences: store);
      final before = service.snapshot;
      await expectLater(
        service.refresh(),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(service.snapshot, same(before));
      store.rejectCanonical = false;
      await service.selectCourseUnit(catalog.courseUnits.first.id);
      expect(
        store.values[Storage.courseMasterySnapshotPreferenceKey],
        isNotNull,
      );
    },
  );

  test(
    'invalid durable refresh does not replace prior confirmed state',
    () async {
      final before = service.snapshot;
      await Storage.setCourseMasteryRawJson(
        jsonEncode({...before.toJson(), 'currentCourseUnitId': 'missing-unit'}),
      );
      await expectLater(service.refresh(), throwsFormatException);
      expect(service.snapshot, same(before));
      await expectLater(
        service.recordContentAttempt(
          CurriculumContentKind.vocab,
          ids.first,
          true,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'placement read retry confirms the owning store after unknown initialization',
    () async {
      Storage.resetCourseMasteryForTesting();
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      store = RejectableStore()
        ..unknownCanonical = true
        ..failReload = true;
      service = CourseMasteryService(catalog, snapshotPreferences: store);
      progress = CourseProgressService(() async => service);
      await expectLater(
        progress.initializeForPlacement('a1'),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      await expectLater(
        progress.captureForPlacementVerification(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      store.failReload = false;
      store.throwCanonical = false;
      final beforeRead = Map<String, String>.of(store.values);
      final capture = await StorageOnboardingCommitGateway(
        courseProgress: progress,
      ).readPlacement();
      expect(capture.canonicalPlacementLevel, LearnerLevel.a1);
      expect(store.values, beforeRead);
    },
  );

  test('refused course selection keeps the confirmed course pointer', () async {
    await service.applyReconciledSnapshot(
      CourseMasterySnapshot(
        curriculumGeneration: catalog.scenarioCorpusGeneration,
        placementLevel: 'a1',
      ),
      expectedGeneration: null,
    );
    final before = service.snapshot;
    store.rejectCanonical = true;
    await expectLater(
      progress.selectCourseUnit('a1_01_greetings_hangul'),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(service.snapshot, same(before));
    expect(service.currentUnit, isNull);
    store.rejectCanonical = false;
    expect(
      (await progress.selectCourseUnit(
        'a1_01_greetings_hangul',
      )).currentCourseUnitId,
      'a1_01_greetings_hangul',
    );
  });

  test(
    'rejected legacy migration retains published state and retries migration',
    () async {
      Storage.resetCourseMasteryForTesting();
      Storage.resetForTesting();
      final legacy = <String, dynamic>{
        ...service.snapshot.toJson(),
        'version': 1,
      };
      SharedPreferences.setMockInitialValues({
        Storage.legacyCourseMasteryPreferenceKey: jsonEncode(legacy),
      });
      await Storage.init();
      store = RejectableStore()..rejectCanonical = true;
      service = CourseMasteryService(catalog, snapshotPreferences: store);
      final before = service.snapshot;
      await expectLater(
        service.refresh(),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(service.snapshot, same(before));
      store.rejectCanonical = false;
      await service.recordContentAttempt(
        CurriculumContentKind.vocab,
        ids.last,
        true,
      );
      expect(service.snapshot.currentCourseUnitId, 'a1_01_greetings_hangul');
      expect(
        service.snapshot.evidence.map((e) => e.contentId),
        contains(ids.last),
      );
    },
  );

  test(
    'rejected productive proof is not published and retry cannot unlock',
    () async {
      final bundle = await CanonicalCourseSegmentLoader.load(
        curriculumCatalog: catalog,
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );
      final definition = bundle
          .productiveAssessments
          .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
      final result = const ProductiveTextAssessmentEngine().evaluate(
        definition: definition,
        input: definition.authoredContextExamples.single,
        occurredAt: DateTime.utc(2026, 8, 16),
      );
      expect(result.passed, isTrue);
      final before = service.snapshot;
      store.rejectCanonical = true;
      await expectLater(
        service.recordProductiveAssessment(
          result: result,
          assessmentCatalog: bundle.productiveAssessments,
          segmentCatalog: bundle.segments,
        ),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(service.snapshot, same(before));
      store.rejectCanonical = false;
      final update = await service.recordProductiveAssessment(
        result: result,
        assessmentCatalog: bundle.productiveAssessments,
        segmentCatalog: bundle.segments,
      );
      expect(update.acceptedEvidence, isNotEmpty);
      expect(update.snapshot.currentCourseUnitId, before.currentCourseUnitId);
      expect(update.snapshot.completedUnitIds, before.completedUnitIds);
    },
  );

  test(
    'rejected project receipt leaves confirmed proof and course intact',
    () async {
      final bundle = await CanonicalCourseSegmentLoader.load(
        curriculumCatalog: catalog,
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );
      final assessments = bundle.productiveAssessments;
      final project = assessments.projects.first;
      final step = project.steps.singleWhere((s) => s.order == 1);
      final unitId = assessments.courseUnitIdForProjectStep(
        project.id,
        step.id,
      );
      final targetIndex = catalog.courseUnits.indexWhere((u) => u.id == unitId);
      await service.applyReconciledSnapshot(
        CourseMasterySnapshot(
          curriculumGeneration: catalog.scenarioCorpusGeneration,
          placementLevel: 'a1',
          completedUnitIds: catalog.courseUnits
              .take(targetIndex + 1)
              .map((u) => u.id)
              .toList(),
        ),
        expectedGeneration: null,
      );
      final introduced = assessments.introducedSourceIdsForStep(
        project.id,
        step.id,
      );
      final result = const ProductiveProjectStepReviewEngine().evaluate(
        catalog: assessments,
        projectId: project.id,
        stepId: step.id,
        reviewedSourceSnippetIds: introduced,
        openedProvenanceSnippetIds: introduced,
      );
      expect(result.passed, isTrue);
      final before = service.snapshot;
      store.rejectCanonical = true;
      await expectLater(
        service.recordProductiveProjectStep(
          result: result,
          assessmentCatalog: assessments,
          segmentCatalog: bundle.segments,
        ),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(service.snapshot, same(before));
      store.rejectCanonical = false;
      final update = await service.recordProductiveProjectStep(
        result: result,
        assessmentCatalog: assessments,
        segmentCatalog: bundle.segments,
      );
      expect(update.snapshot.productiveProjectStepEvidence, hasLength(1));
      expect(update.snapshot.completedUnitIds, before.completedUnitIds);
      expect(update.snapshot.currentCourseUnitId, before.currentCourseUnitId);
    },
  );
}
