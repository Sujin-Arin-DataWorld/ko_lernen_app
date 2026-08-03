import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

class _RejectedCourseMasteryWriteStore implements PreferenceStringStore {
  _RejectedCourseMasteryWriteStore(Map<String, String> initial)
    : _cache = Map<String, String>.from(initial),
      _durable = Map<String, String>.from(initial);

  final Map<String, String> _cache;
  final Map<String, String> _durable;

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<void> reload() async {
    _cache
      ..clear()
      ..addAll(_durable);
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    _durable.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    // Mirrors an optimistic platform cache even though the durable write was
    // rejected. Strict storage must reload this cache before reporting failure.
    _cache[key] = value;
    return false;
  }
}

class _RejectedCanonicalSnapshotWriteStore implements PreferenceStringStore {
  _RejectedCanonicalSnapshotWriteStore(Map<String, String> initial)
    : _cache = Map<String, String>.from(initial),
      _durable = Map<String, String>.from(initial);

  final Map<String, String> _cache;
  final Map<String, String> _durable;

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<void> reload() async {
    _cache
      ..clear()
      ..addAll(_durable);
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    _durable.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _cache[key] = value;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'placement, browse, course location, and legacy level stay separate',
    () async {
      await Storage.setPlacementLevelCode('a2');
      await Storage.setBrowseLevelCode('b1');
      await Storage.setCourseUnitId('a2_01_polite_daily');
      await Storage.setCourseMasteryRawJson('{"version":1}');

      expect(Storage.placementLevelCode, 'a2');
      expect(Storage.userLevelCode, 'a2');
      expect(Storage.browseLevelCode, 'b1');
      expect(Storage.courseUnitId, 'a2_01_polite_daily');
      expect(Storage.courseMasteryRawJson, '{"version":1}');

      await Storage.setBrowseLevelCode('b2');
      expect(Storage.userLevelCode, 'a2');
      expect(Storage.placementLevelCode, 'a2');
    },
  );

  test(
    'course mastery cache stays at the last durable value after a rejected write',
    () async {
      const durable = '{"version":1,"marker":"durable"}';
      const rejected = '{"version":1,"marker":"rejected"}';
      await Storage.setCourseMasteryRawJson(durable);
      final store = _RejectedCourseMasteryWriteStore({
        Storage.courseMasteryPreferenceKey: durable,
      });

      await expectLater(
        Storage.setCourseMasteryRawJson(rejected, preferences: store),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(Storage.courseMasteryRawJson, durable);
      expect(store.getString(Storage.courseMasteryPreferenceKey), durable);
    },
  );

  test('refresh migrates a v1 snapshot into the canonical v2 key', () async {
    const legacy =
        '{"version":1,"placementLevel":"a1",'
        '"currentCourseUnitId":"a1_01_greetings_hangul"}';
    await _seedCoursePreferences({
      Storage.legacyCourseMasteryPreferenceKey: legacy,
    });

    final snapshot = await CourseMasteryService(_catalog()).refresh();

    expect(snapshot.version, 2);
    expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
    expect(Storage.legacyCourseMasteryRawJson, legacy);
  });

  test(
    'refresh creates a canonical v2 snapshot from legacy scalar mirrors',
    () async {
      await _seedCoursePreferences({
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: 'a1_01_greetings_hangul',
      });

      final snapshot = await CourseMasteryService(_catalog()).refresh();

      expect(snapshot.version, 2);
      expect(snapshot.placementLevel, 'a1');
      expect(snapshot.currentCourseUnitId, 'a1_01_greetings_hangul');
      expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
    },
  );

  test(
    'refresh rejects a future v2 snapshot without overwriting stored data',
    () async {
      const canonical = '{"version":3}';
      const legacy =
          '{"version":1,"placementLevel":"a1",'
          '"currentCourseUnitId":"a1_01_greetings_hangul"}';
      await _seedCoursePreferences({
        Storage.courseMasterySnapshotPreferenceKey: canonical,
        Storage.legacyCourseMasteryPreferenceKey: legacy,
      });

      await expectLater(
        CourseMasteryService(_catalog()).refresh(),
        throwsA(isA<FormatException>()),
      );

      expect(Storage.courseMasterySnapshotRawJson, canonical);
      expect(Storage.legacyCourseMasteryRawJson, legacy);
    },
  );

  test(
    'refresh rejects fractional canonical versions without overwriting either snapshot',
    () async {
      const legacy =
          '{"version":1,"placementLevel":"a1",'
          '"currentCourseUnitId":"a1_01_greetings_hangul"}';
      for (final canonical in const ['{"version":1.5}', '{"version":2.5}']) {
        await _seedCoursePreferences({
          Storage.courseMasterySnapshotPreferenceKey: canonical,
          Storage.legacyCourseMasteryPreferenceKey: legacy,
        });

        await expectLater(
          CourseMasteryService(_catalog()).refresh(),
          throwsA(isA<FormatException>()),
        );

        expect(Storage.courseMasterySnapshotRawJson, canonical);
        expect(Storage.legacyCourseMasteryRawJson, legacy);
      }
    },
  );

  test('codec rejects non-finite schema versions', () {
    for (final version in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => CourseMasterySnapshot.decodeAndMigrate({'version': version}),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('v2 codec reports a nonnumeric checkpoint score as format data', () {
    expect(
      () => CourseMasterySnapshot.decodeAndMigrate({
        'version': 2,
        'completedUnitIds': <String>[],
        'bypassedPrerequisiteUnitIds': <String>[],
        'evidence': <Object>[],
        'scenarioCheckpoints': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'bad-checkpoint',
            'scenarioId': 'airport_arrival',
            'score': 'bad',
            'occurredAt': '2026-08-03T09:00:00.000Z',
            'courseEligible': false,
          },
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'rejected canonical write leaves compatibility mirrors unchanged',
    () async {
      const oldCanonical = '{"version":2,"marker":"durable"}';
      const oldPlacement = 'a2';
      const oldCurrentUnit = 'a2_01_polite_daily';
      await Storage.setPlacementLevelCode(oldPlacement);
      await Storage.setCourseUnitId(oldCurrentUnit);
      await Storage.setCourseMasterySnapshotRawJson(oldCanonical);
      final store = _RejectedCanonicalSnapshotWriteStore({
        Storage.courseMasterySnapshotPreferenceKey: oldCanonical,
      });

      await expectLater(
        CourseMasteryService(
          _catalog(),
          snapshotPreferences: store,
        ).initializeForPlacement('a1'),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(Storage.placementLevelCode, oldPlacement);
      expect(Storage.courseUnitId, oldCurrentUnit);
      expect(Storage.courseMasterySnapshotRawJson, oldCanonical);
    },
  );

  test(
    'completed reconciled snapshot clears its dedicated course-unit mirror',
    () async {
      await Storage.setCourseUnitId('b2_01_official');
      final progress = CourseProgressService(
        () async => CourseMasteryService(_catalog()),
      );
      final completed = CourseMasterySnapshot(
        placementLevel: 'a1',
        completedUnitIds: const [
          'a1_01_greetings_hangul',
          'a1_02_self_intro_identity',
          'a1_03_topic_subject_particles',
          'a1_04_order_request_object',
          'a2_01_polite_daily',
          'b1_01_workplace',
          'b2_01_official',
        ],
      );

      await progress.applyReconciledSnapshot(
        completed,
        expectedGeneration: null,
      );

      expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
      expect(Storage.courseUnitId, isNull);
    },
  );

  test(
    'failed canonical completed write does not clear course or unrelated mirrors',
    () async {
      const oldCanonical = '{"version":2,"marker":"durable"}';
      const oldCurrentUnit = 'b2_01_official';
      await Storage.setBrowseLevelCode('b1');
      await Storage.setUserLevelCode('b2');
      await Storage.setCourseUnitId(oldCurrentUnit);
      await Storage.setCourseMasterySnapshotRawJson(oldCanonical);
      final store = _RejectedCanonicalSnapshotWriteStore({
        Storage.courseMasterySnapshotPreferenceKey: oldCanonical,
      });

      await expectLater(
        CourseMasteryService(
          _catalog(),
          snapshotPreferences: store,
        ).applyReconciledSnapshot(
          _completedSnapshot(),
          expectedGeneration: null,
        ),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(Storage.courseUnitId, oldCurrentUnit);
      expect(Storage.browseLevelCode, 'b1');
      expect(Storage.userLevelCode, 'b2');
      expect(Storage.courseMasterySnapshotRawJson, oldCanonical);
    },
  );

  test(
    'round-trips eligible evidence and advances at the pilot checkpoint',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');

      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(1),
      );
      final update = await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        occurredAt: _time(2),
      );

      expect(update.newlyUnlockedUnit?.id, 'a1_02_self_intro_identity');
      expect(update.currentUnit?.id, 'a1_02_self_intro_identity');
      expect(Storage.courseUnitId, 'a1_02_self_intro_identity');
      expect(Storage.courseMasteryRawJson, isNotEmpty);

      final reloaded = CourseMasteryService(_catalog());
      final snapshot = await reloaded.refresh();
      expect(snapshot.completedUnitIds, contains('a1_01_greetings_hangul'));
      expect(snapshot.evidence, hasLength(1));
      expect(snapshot.evidence.single.courseEligible, isTrue);
      expect(
        reloaded.stateForConcept('concept_greeting_politeness'),
        CourseContentState.checkpointPassed,
      );
    },
  );

  test(
    'app-scoped progress service serializes concurrent activity writes',
    () async {
      final progress = CourseProgressService(
        () async => CourseMasteryService(_catalog()),
      );
      await progress.initializeForPlacement('a1');

      await Future.wait([
        progress.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_greetings',
          true,
          conceptId: 'concept_greeting_politeness',
          occurredAt: _time(1),
        ),
        progress.recordScenarioCheckpoint(
          'airport_arrival',
          .70,
          occurredAt: _time(2),
        ),
      ]);

      final snapshot = await progress.refresh();
      expect(snapshot.currentCourseUnitId, 'a1_02_self_intro_identity');
      expect(snapshot.completedUnitIds, contains('a1_01_greetings_hangul'));
    },
  );

  test(
    'exactly 70 percent concept evidence and scenario score unlock',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');
      for (var index = 0; index < 10; index++) {
        await service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_greetings',
          index < 7,
          conceptId: 'concept_greeting_politeness',
          occurredAt: _time(index + 1),
        );
      }

      final below = await service.recordScenarioCheckpoint(
        'airport_arrival',
        .69,
        occurredAt: _time(11),
      );
      expect(below.currentUnit?.id, 'a1_01_greetings_hangul');

      final boundary = await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        occurredAt: _time(12),
      );
      expect(boundary.newlyUnlockedUnit?.id, 'a1_02_self_intro_identity');
    },
  );

  test(
    'all four A1 pilot missions accept their linked evidence and checkpoints',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');
      const grammarIds = <String>[
        'grammar_greetings',
        'grammar_identity',
        'grammar_topic_particle',
        'grammar_object_particle',
      ];
      const conceptIds = <String>[
        'concept_greeting_politeness',
        'concept_identity_formal',
        'concept_topic_particle',
        'concept_object_particle',
      ];
      const scenarioIds = <String>[
        'airport_arrival',
        'introduce_yourself',
        'mart_grocery',
        'bunshik_tteokbokki',
      ];
      const expectedNext = <String>[
        'a1_02_self_intro_identity',
        'a1_03_topic_subject_particles',
        'a1_04_order_request_object',
        'a2_01_polite_daily',
      ];

      for (var index = 0; index < grammarIds.length; index++) {
        await service.recordContentAttempt(
          CurriculumContentKind.grammar,
          grammarIds[index],
          true,
          conceptId: conceptIds[index],
          occurredAt: _time(index * 2 + 1),
        );
        final update = await service.recordScenarioCheckpoint(
          scenarioIds[index],
          .70,
          occurredAt: _time(index * 2 + 2),
        );
        expect(update.newlyUnlockedUnit?.id, expectedNext[index]);
        expect(update.currentUnit?.id, expectedNext[index]);
      }
    },
  );

  test(
    'future free-browse evidence is retained but cannot unlock a mission',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');

      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_object_particle',
        true,
        conceptId: 'concept_object_particle',
        occurredAt: _time(1),
      );
      final afterFutureCheckpoint = await service.recordScenarioCheckpoint(
        'bunshik_tteokbokki',
        1,
        occurredAt: _time(2),
      );
      expect(afterFutureCheckpoint.currentUnit?.id, 'a1_01_greetings_hangul');
      expect(service.snapshot.evidence.single.courseEligible, isFalse);
      expect(
        service.snapshot.scenarioCheckpoints.single.courseEligible,
        isFalse,
      );

      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(3),
      );
      final currentCheckpoint = await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        occurredAt: _time(4),
      );
      expect(
        currentCheckpoint.newlyUnlockedUnit?.id,
        'a1_02_self_intro_identity',
      );
    },
  );

  test(
    'free-browse correct streaks stay preview until the linked mission is active',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');

      for (var index = 0; index < 4; index++) {
        await service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_object_particle',
          true,
          conceptId: 'concept_object_particle',
          occurredAt: _time(index + 1),
        );
      }
      expect(
        service.stateForConcept('concept_object_particle'),
        CourseContentState.preview,
      );

      for (var index = 0; index < 3; index++) {
        await service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_identity',
          true,
          conceptId: 'concept_identity_formal',
          occurredAt: _time(index + 10),
        );
      }
      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(20),
      );
      await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        occurredAt: _time(21),
      );

      expect(service.currentUnit?.id, 'a1_02_self_intro_identity');
      expect(
        service.stateForConcept('concept_identity_formal'),
        CourseContentState.introduced,
      );
    },
  );

  test(
    'each scenario checkpoint must independently meet the unit threshold',
    () async {
      final service = CourseMasteryService(
        _catalog(firstUnitHasTwoCheckpoints: true),
      );
      await service.initializeForPlacement('a1');
      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(1),
      );
      await service.recordScenarioCheckpoint(
        'airport_arrival',
        .40,
        occurredAt: _time(2),
      );
      final update = await service.recordScenarioCheckpoint(
        'introduce_yourself',
        1,
        occurredAt: _time(3),
      );

      expect(update.newlyUnlockedUnit, isNull);
      expect(update.currentUnit?.id, 'a1_01_greetings_hangul');
    },
  );

  test(
    'two checkpoints at the exact 70 percent boundary unlock together',
    () async {
      final service = CourseMasteryService(
        _catalog(firstUnitHasTwoCheckpoints: true),
      );
      await service.initializeForPlacement('a1');
      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(1),
      );
      await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        occurredAt: _time(2),
      );
      final update = await service.recordScenarioCheckpoint(
        'introduce_yourself',
        .70,
        occurredAt: _time(3),
      );

      expect(update.newlyUnlockedUnit?.id, 'a1_02_self_intro_identity');
    },
  );

  test(
    'bounded history preserves active unlock inputs and unresolved correction',
    () async {
      final futureEvidence = <MasteryEvidence>[
        for (var index = 0; index < CourseMasteryService.evidenceCap; index++)
          MasteryEvidence(
            conceptId: 'concept_object_particle',
            contentKind: CurriculumContentKind.grammar,
            contentId: 'grammar_object_particle',
            courseUnitId: 'a1_04_order_request_object',
            isCorrect: true,
            occurredAt: _time(index + 10),
          ),
      ];
      final futureCheckpoints = <ScenarioCheckpointEvidence>[
        for (var index = 0; index < CourseMasteryService.evidenceCap; index++)
          ScenarioCheckpointEvidence(
            scenarioId: 'bunshik_tteokbokki',
            courseUnitId: 'a1_04_order_request_object',
            score: 1,
            occurredAt: _time(index + 400),
          ),
      ];
      await Storage.setCourseMasteryRawJson(
        jsonEncode(
          CourseMasterySnapshot(
            placementLevel: 'a1',
            currentCourseUnitId: 'a1_01_greetings_hangul',
            evidence: [
              MasteryEvidence(
                conceptId: 'concept_greeting_politeness',
                contentKind: CurriculumContentKind.grammar,
                contentId: 'grammar_greetings',
                courseUnitId: 'a1_01_greetings_hangul',
                isCorrect: true,
                occurredAt: _time(1),
                courseEligible: true,
              ),
              MasteryEvidence(
                conceptId: 'concept_greeting_politeness',
                contentKind: CurriculumContentKind.grammar,
                contentId: 'grammar_greetings',
                courseUnitId: 'a1_01_greetings_hangul',
                isCorrect: false,
                occurredAt: _time(2),
                errorReason: MasteryErrorReason.speechStyle,
                courseEligible: true,
              ),
              ...futureEvidence,
            ],
            scenarioCheckpoints: [
              ScenarioCheckpointEvidence(
                scenarioId: 'airport_arrival',
                courseUnitId: 'a1_01_greetings_hangul',
                score: .70,
                occurredAt: _time(3),
                courseEligible: true,
              ),
              ...futureCheckpoints,
            ],
          ).toJson(),
        ),
      );

      final service = CourseMasteryService(_catalog());
      await service.refresh();
      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_object_particle',
        true,
        conceptId: 'concept_object_particle',
        occurredAt: _time(800),
      );
      await service.recordScenarioCheckpoint(
        'bunshik_tteokbokki',
        1,
        occurredAt: _time(801),
      );

      expect(
        service.snapshot.evidence,
        hasLength(CourseMasteryService.evidenceCap),
      );
      expect(
        service.snapshot.scenarioCheckpoints,
        hasLength(CourseMasteryService.evidenceCap),
      );
      expect(
        service.snapshot.evidence.where(
          (item) => item.courseUnitId == 'a1_01_greetings_hangul',
        ),
        hasLength(2),
      );
      expect(
        service.snapshot.scenarioCheckpoints.any(
          (item) => item.courseEligible && item.scenarioId == 'airport_arrival',
        ),
        isTrue,
      );
      expect(
        service.reviewQueue.map((item) => item.conceptId),
        contains('concept_greeting_politeness'),
      );

      await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(802),
      );
      final update = await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greetings',
        true,
        conceptId: 'concept_greeting_politeness',
        occurredAt: _time(803),
      );

      expect(update.newlyUnlockedUnit?.id, 'a1_02_self_intro_identity');
    },
  );

  test(
    'particle errors return a real correction link and a correct retry clears it',
    () async {
      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');
      await _advanceToObjectParticleUnit(service);

      final incorrect = await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_object_particle',
        false,
        conceptId: 'concept_object_particle',
        errorReason: MasteryErrorReason.particleRole,
        occurredAt: _time(7),
      );
      final recommendation = incorrect.remediation;
      expect(recommendation, isNotNull);
      expect(recommendation!.conceptId, 'concept_object_particle');
      expect(recommendation.contentLink, isNotNull);
      expect(
        recommendation.contentLink!.conceptIds,
        contains('concept_object_particle'),
      );
      expect(
        recommendation.contentLink!.role,
        anyOf(ContentLinkRole.practice, ContentLinkRole.review),
      );
      expect(
        service.stateForConcept('concept_object_particle'),
        CourseContentState.reviewDue,
      );

      final corrected = await service.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_object_particle',
        true,
        conceptId: 'concept_object_particle',
        occurredAt: _time(8),
      );
      expect(corrected.remediation, isNull);
      expect(service.reviewQueue, isEmpty);
    },
  );

  test(
    'audited pilot scenario quest records one targeted correction',
    () async {
      final catalog = await CurriculumCatalog.load();
      final service = CourseMasteryService(catalog);
      await service.initializeForPlacement('a1');

      final update = await service.recordContentAttempt(
        CurriculumContentKind.scenario,
        'introduce_yourself',
        false,
        conceptId: 'concept_hangul_batchim',
        errorReason: MasteryErrorReason.batchim,
        occurredAt: _time(50),
      );

      expect(update.remediation?.conceptId, 'concept_hangul_batchim');
      expect(
        service.reviewQueue.map((item) => item.conceptId),
        contains('concept_hangul_batchim'),
      );

      await service.recordContentAttempt(
        CurriculumContentKind.scenario,
        'introduce_yourself',
        true,
        conceptId: 'concept_hangul_batchim',
        occurredAt: _time(51),
      );
      expect(service.reviewQueue, isEmpty);
    },
  );

  test(
    'rejects invalid catalog, concept/content IDs, timestamps, scores, and raw evidence',
    () async {
      final invalid = CourseMasteryService(_catalog(withInvalidLink: true));
      expect(
        () => invalid.initializeForPlacement('a1'),
        throwsA(isA<FormatException>()),
      );

      final service = CourseMasteryService(_catalog());
      await service.initializeForPlacement('a1');
      expect(
        () => service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_greetings',
          true,
          conceptId: 'not_a_concept',
          occurredAt: _time(1),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'not_a_content_id',
          true,
          conceptId: 'concept_greeting_politeness',
          occurredAt: _time(1),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.recordContentAttempt(
          CurriculumContentKind.grammar,
          'grammar_greetings',
          true,
          conceptId: 'concept_greeting_politeness',
          occurredAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.recordScenarioCheckpoint('airport_arrival', 1.1),
        throwsA(isA<FormatException>()),
      );

      await Storage.setCourseMasteryRawJson(
        jsonEncode({
          'version': 1,
          'evidence': [
            {
              'conceptId': 'concept_greeting_politeness',
              'contentKind': 'invalid_kind',
              'contentId': 'grammar_greetings',
              'isCorrect': true,
              'occurredAt': _time(1).toIso8601String(),
            },
          ],
        }),
      );
      expect(
        () => CourseMasteryService(_catalog()).refresh(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'refresh rejects forged current and bypass states before eligible evidence can count',
    () async {
      await Storage.setCourseMasteryRawJson(
        jsonEncode({
          'version': 1,
          'placementLevel': 'a1',
          'currentCourseUnitId': 'b2_01_official',
          'completedUnitIds': const <String>[],
          'bypassedPrerequisiteUnitIds': const <String>[],
          'evidence': [
            MasteryEvidence(
              conceptId: 'concept_b2_official',
              contentKind: CurriculumContentKind.grammar,
              contentId: 'grammar_b2_official',
              courseUnitId: 'b2_01_official',
              isCorrect: true,
              occurredAt: _time(1),
              courseEligible: true,
            ).toJson(),
          ],
          'scenarioCheckpoints': const <Map<String, dynamic>>[],
        }),
      );
      expect(
        () => CourseMasteryService(_catalog()).refresh(),
        throwsA(isA<FormatException>()),
      );

      await Storage.setCourseMasteryRawJson(
        jsonEncode({
          'version': 1,
          'placementLevel': 'a1',
          'currentCourseUnitId': 'a1_01_greetings_hangul',
          'completedUnitIds': ['a1_01_greetings_hangul'],
          'bypassedPrerequisiteUnitIds': const <String>[],
        }),
      );
      expect(
        () => CourseMasteryService(_catalog()).refresh(),
        throwsA(isA<FormatException>()),
      );

      await Storage.setCourseMasteryRawJson(
        jsonEncode({
          'version': 1,
          'placementLevel': 'a2',
          'currentCourseUnitId': 'a2_01_polite_daily',
          'completedUnitIds': const <String>[],
          'bypassedPrerequisiteUnitIds': ['a1_04_order_request_object'],
        }),
      );
      expect(
        () => CourseMasteryService(_catalog()).refresh(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'direct placement records explicit bypasses instead of fake completions',
    () async {
      final service = CourseMasteryService(_catalog());
      final a2 = await service.initializeForPlacement('a2');
      expect(a2.currentCourseUnitId, 'a2_01_polite_daily');
      expect(
        a2.bypassedPrerequisiteUnitIds,
        containsAll(<String>[
          'a1_01_greetings_hangul',
          'a1_02_self_intro_identity',
          'a1_03_topic_subject_particles',
          'a1_04_order_request_object',
        ]),
      );

      final snapshot = await service.initializeForPlacement('b1');

      expect(snapshot.currentCourseUnitId, 'b1_01_workplace');
      expect(snapshot.completedUnitIds, isEmpty);
      expect(
        snapshot.bypassedPrerequisiteUnitIds,
        containsAll(<String>[
          'a1_01_greetings_hangul',
          'a1_02_self_intro_identity',
          'a1_03_topic_subject_particles',
          'a1_04_order_request_object',
          'a2_01_polite_daily',
        ]),
      );
      expect(Storage.placementLevelCode, 'b1');
      expect(Storage.userLevelCode, 'b1');
      expect(Storage.courseUnitId, 'b1_01_workplace');

      final b2 = await service.initializeForPlacement('b2');
      expect(b2.currentCourseUnitId, 'b2_01_official');
      expect(b2.completedUnitIds, isEmpty);
      expect(
        b2.bypassedPrerequisiteUnitIds,
        containsAll(<String>[
          'a1_01_greetings_hangul',
          'a2_01_polite_daily',
          'b1_01_workplace',
        ]),
      );
    },
  );
}

CourseMasterySnapshot _completedSnapshot() => const CourseMasterySnapshot(
  completedUnitIds: [
    'a1_01_greetings_hangul',
    'a1_02_self_intro_identity',
    'a1_03_topic_subject_particles',
    'a1_04_order_request_object',
    'a2_01_polite_daily',
    'b1_01_workplace',
    'b2_01_official',
  ],
);

DateTime _time(int second) => DateTime.utc(2026, 8, 2, 12, 0, second);

Future<void> _seedCoursePreferences(Map<String, Object> values) async {
  Storage.resetForTesting();
  Storage.resetCourseMasteryForTesting();
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
}

Future<void> _advanceToObjectParticleUnit(CourseMasteryService service) async {
  const grammarIds = <String>[
    'grammar_greetings',
    'grammar_identity',
    'grammar_topic_particle',
  ];
  const conceptIds = <String>[
    'concept_greeting_politeness',
    'concept_identity_formal',
    'concept_topic_particle',
  ];
  const scenarioIds = <String>[
    'airport_arrival',
    'introduce_yourself',
    'mart_grocery',
  ];
  for (var index = 0; index < grammarIds.length; index++) {
    await service.recordContentAttempt(
      CurriculumContentKind.grammar,
      grammarIds[index],
      true,
      conceptId: conceptIds[index],
      occurredAt: _time(index * 2 + 1),
    );
    await service.recordScenarioCheckpoint(
      scenarioIds[index],
      .70,
      occurredAt: _time(index * 2 + 2),
    );
  }
  expect(service.currentUnit?.id, 'a1_04_order_request_object');
}

CurriculumCatalog _catalog({
  bool withInvalidLink = false,
  bool firstUnitHasTwoCheckpoints = false,
}) {
  final units = <Map<String, dynamic>>[
    {
      'id': 'a1_01_greetings_hangul',
      'level': 'a1',
      'order': 1,
      'title': {'ko': '인사', 'de': 'Gruß', 'en': 'Greeting'},
      'canDo': {
        'ko': '인사할 수 있어요.',
        'de': 'Ich kann grüßen.',
        'en': 'I can greet.',
      },
      'requiredConceptIds': ['concept_greeting_politeness'],
      'checkpointContentIds': firstUnitHasTwoCheckpoints
          ? const ['scenario:airport_arrival', 'scenario:introduce_yourself']
          : const ['scenario:airport_arrival'],
      'isPilot': true,
    },
    {
      'id': 'a1_02_self_intro_identity',
      'level': 'a1',
      'order': 2,
      'prerequisiteUnitIds': ['a1_01_greetings_hangul'],
      'title': {'ko': '소개', 'de': 'Vorstellung', 'en': 'Introduction'},
      'canDo': {
        'ko': '소개해요.',
        'de': 'Ich stelle mich vor.',
        'en': 'I introduce myself.',
      },
      'requiredConceptIds': ['concept_identity_formal'],
      'checkpointContentIds': ['scenario:introduce_yourself'],
      'isPilot': true,
    },
    {
      'id': 'a1_03_topic_subject_particles',
      'level': 'a1',
      'order': 3,
      'prerequisiteUnitIds': ['a1_02_self_intro_identity'],
      'title': {'ko': '은/는', 'de': 'Thema', 'en': 'Topic'},
      'canDo': {
        'ko': '구분해요.',
        'de': 'Ich unterscheide.',
        'en': 'I distinguish.',
      },
      'requiredConceptIds': ['concept_topic_particle'],
      'checkpointContentIds': ['scenario:mart_grocery'],
      'isPilot': true,
    },
    {
      'id': 'a1_04_order_request_object',
      'level': 'a1',
      'order': 4,
      'prerequisiteUnitIds': ['a1_03_topic_subject_particles'],
      'title': {'ko': '주문', 'de': 'Bestellen', 'en': 'Order'},
      'canDo': {'ko': '주문해요.', 'de': 'Ich bestelle.', 'en': 'I order.'},
      'requiredConceptIds': ['concept_object_particle'],
      'checkpointContentIds': ['scenario:bunshik_tteokbokki'],
      'isPilot': true,
    },
    {
      'id': 'a2_01_polite_daily',
      'level': 'a2',
      'order': 1,
      'prerequisiteUnitIds': ['a1_04_order_request_object'],
      'title': {
        'ko': '해요체',
        'de': 'Höfliche Alltagssprache',
        'en': 'Polite daily speech',
      },
      'canDo': {
        'ko': '말해요.',
        'de': 'Ich spreche höflich.',
        'en': 'I speak politely.',
      },
      'requiredConceptIds': ['concept_a2_polite'],
      'checkpointContentIds': ['scenario:a2_daily'],
    },
    {
      'id': 'b1_01_workplace',
      'level': 'b1',
      'order': 1,
      'prerequisiteUnitIds': ['a2_01_polite_daily'],
      'title': {'ko': '직장', 'de': 'Arbeit', 'en': 'Work'},
      'canDo': {'ko': '일해요.', 'de': 'Ich arbeite.', 'en': 'I work.'},
      'requiredConceptIds': ['concept_b1_work'],
      'checkpointContentIds': ['scenario:b1_work'],
    },
    {
      'id': 'b2_01_official',
      'level': 'b2',
      'order': 1,
      'prerequisiteUnitIds': ['b1_01_workplace'],
      'title': {'ko': '공식', 'de': 'Offiziell', 'en': 'Official'},
      'canDo': {'ko': '설명해요.', 'de': 'Ich erkläre.', 'en': 'I explain.'},
      'requiredConceptIds': ['concept_b2_official'],
      'checkpointContentIds': ['scenario:b2_official'],
    },
  ];

  final unitList = units.toList(growable: false);
  final concepts = <Map<String, dynamic>>[
    _concept('concept_greeting_politeness', 'a1', 'speechStyle'),
    _concept('concept_identity_formal', 'a1', 'conjugation'),
    _concept('concept_topic_particle', 'a1', 'particle'),
    _concept('concept_object_particle', 'a1', 'particle'),
    _concept('concept_a2_polite', 'a2', 'speechStyle'),
    _concept('concept_b1_work', 'b1', 'situation'),
    _concept('concept_b2_official', 'b2', 'speechStyle'),
  ];
  final scenarioIds = <String>[
    'airport_arrival',
    'introduce_yourself',
    'mart_grocery',
    'bunshik_tteokbokki',
    'a2_daily',
    'b1_work',
    'b2_official',
  ];
  final conceptIds = concepts.map((item) => item['id']! as String).toList();
  final grammar = <Grammar>[
    for (var index = 0; index < scenarioIds.length; index++)
      Grammar(
        id: _grammarId(index),
        pattern: 'pattern_$index',
        level: unitList[index]['level']! as String,
        typeDe: 'Test',
        explanationDe: '',
        exampleKorean: '',
        exampleGerman: '',
        note: '',
      ),
  ];
  final scenarios = <Scenario>[
    for (var index = 0; index < scenarioIds.length; index++)
      Scenario(
        id: scenarioIds[index],
        level: LearnerLevel.fromCode(unitList[index]['level']! as String)!,
        emoji: '💬',
        register: Register.polite,
        title: const LocalizedText(ko: '연습', de: 'Übung', en: 'Practice'),
        intro: const LocalizedText(ko: '연습', de: 'Übung', en: 'Practice'),
        vocab: const [],
        grammarIds: [_grammarId(index)],
        dialog: const [],
        quests: const [],
        courseUnitId: unitList[index]['id']! as String,
        speechStyle: SpeechStyle.polite,
        relationshipContext: 'service',
        intent: 'practice',
        conceptIds: [conceptIds[index]],
      ),
  ];
  final grammarRuleMap = <String, Map<String, dynamic>>{
    for (var index = 0; index < grammar.length; index++)
      _grammarId(index): {
        'courseUnitId': unitList[index]['id'],
        'conceptIds': [conceptIds[index]],
      },
  };
  final manifest = <String, dynamic>{
    'version': 1,
    'courseUnits': unitList,
    'concepts': concepts,
    'surfaceForms': const [],
    'formFamilies': const [],
    'contentLinks': [
      {
        'id': 'object_particle_repair',
        'contentKind': 'grammar',
        'contentId': 'grammar_object_particle',
        'courseUnitId': 'a1_04_order_request_object',
        'conceptIds': ['concept_object_particle'],
        'role': 'practice',
      },
      if (firstUnitHasTwoCheckpoints)
        {
          'id': 'greeting_second_checkpoint',
          'contentKind': 'scenario',
          'contentId': 'introduce_yourself',
          'courseUnitId': 'a1_01_greetings_hangul',
          'conceptIds': ['concept_greeting_politeness'],
          'role': 'assess',
        },
      if (withInvalidLink)
        {
          'id': 'invalid_link',
          'contentKind': 'grammar',
          'contentId': 'not_real',
          'courseUnitId': 'a1_01_greetings_hangul',
          'conceptIds': ['concept_greeting_politeness'],
          'role': 'practice',
        },
    ],
    'vocabPackUnitMap': const {},
    'smalltalkCategoryUnitMap': const {},
    'clozeTopicUnitMap': const {},
    'grammarRuleMap': grammarRuleMap,
  };
  return CurriculumCatalog.fromDataForTesting(
    manifestJson: manifest,
    vocab: const [],
    grammar: grammar,
    smalltalk: const [],
    cloze: const [],
    satz: const [],
    scenarios: scenarios,
  );
}

Map<String, dynamic> _concept(String id, String level, String kind) => {
  'id': id,
  'level': level,
  'kind': kind,
  'title': {'ko': id, 'de': id, 'en': id},
  'explanation': {'ko': id, 'de': id, 'en': id},
};

String _grammarId(int index) => switch (index) {
  0 => 'grammar_greetings',
  1 => 'grammar_identity',
  2 => 'grammar_topic_particle',
  3 => 'grammar_object_particle',
  4 => 'grammar_a2_polite',
  5 => 'grammar_b1_work',
  _ => 'grammar_b2_official',
};
