import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/phase_task.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

class _MemoryStringStore implements PreferenceStringStore {
  final Map<String, String> _values = <String, String>{};

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurriculumCatalog curriculum;
  late PhaseTaskCatalog phases;
  late PhaseTask task;
  late PhaseTaskResult passingResult;
  late PhaseTaskResult failingResult;
  final startedAt = DateTime.utc(2026, 9, 13);

  setUpAll(() async {
    curriculum = await CurriculumCatalog.load();
    phases = await PhaseTaskCatalog.load();
    task = phases.byId('KP01:writing:01');
    passingResult = task.evaluate({
      'name': '유나',
      'country': '한국',
      'occupation': '선생님',
      'introduction': '저는 선생님이에요.',
      'contrast': '저는 학생이 아니에요.',
    }, assessment: true);
    failingResult = task.evaluate(const {}, assessment: true);
  });

  setUp(Storage.resetForTesting);

  CourseMasterySnapshot snapshot(Iterable<PhaseAttemptEvidence> evidence) =>
      CourseMasterySnapshot(
        curriculumGeneration: curriculum.scenarioCorpusGeneration,
        phaseTaskEvidence: evidence.toList(growable: false),
      );

  PhaseAttemptEvidence changed(
    PhaseAttemptEvidence base, {
    required String id,
    required DateTime time,
    double? score,
    List<String>? criteria,
    int? revision,
  }) => PhaseAttemptEvidence.fromJson(
    base.toJson()
      ..['attemptId'] = id
      ..['occurredAt'] = time.toUtc().toIso8601String()
      ..['score'] = score ?? base.score
      ..['passedCriterionIds'] = criteria ?? base.passedCriterionIds
      ..['contentRevision'] = revision ?? base.contentRevision,
  );

  List<PhaseAttemptEvidence> repeatedFailures(int count, {DateTime? time}) => [
    for (var index = 0; index < count; index++)
      failingResult.evidence(
        'failure-${index.toString().padLeft(3, '0')}',
        time ?? startedAt.add(Duration(minutes: index + 1)),
      ),
  ];

  test(
    'direct record caps repeats while retaining an older valid pass',
    () async {
      final pass = passingResult.evidence('passing', startedAt);
      final oversized = snapshot([pass, ...repeatedFailures(350)]);
      final store = _MemoryStringStore();
      await Storage.setCourseMasterySnapshotRawJson(
        jsonEncode(oversized.toJson()),
        preferences: store,
      );
      final service = CourseMasteryService(
        curriculum,
        snapshotPreferences: store,
      );
      var ownershipChecks = 0;

      final recorded = await service.recordPhaseAttempt(
        result: failingResult,
        phaseCatalog: phases,
        attemptId: 'failure-newest',
        occurredAt: startedAt.add(const Duration(days: 1)),
        assertCurrentWrite: () => ownershipChecks++,
      );

      expect(recorded.phaseTaskEvidence, hasLength(302));
      expect(
        recorded.phaseTaskEvidence.any((entry) => entry.attemptId == 'passing'),
        isTrue,
      );
      expect(
        task.passedBy(
          recorded.phaseTaskEvidence.singleWhere(
            (entry) => entry.attemptId == 'passing',
          ),
        ),
        isTrue,
      );
      expect(
        recorded.phaseTaskEvidence.any(
          (entry) => entry.attemptId == 'failure-000',
        ),
        isFalse,
      );
      expect(recorded.phaseTaskEvidence.last.attemptId, 'failure-newest');
      expect(ownershipChecks, greaterThanOrEqualTo(3));
    },
  );

  test('direct record detects an old ID conflict before compaction', () async {
    final oversized = snapshot(repeatedFailures(350));
    final store = _MemoryStringStore();
    await Storage.setCourseMasterySnapshotRawJson(
      jsonEncode(oversized.toJson()),
      preferences: store,
    );
    final service = CourseMasteryService(
      curriculum,
      snapshotPreferences: store,
    );

    await expectLater(
      service.recordPhaseAttempt(
        result: passingResult,
        phaseCatalog: phases,
        attemptId: 'failure-000',
        occurredAt: startedAt,
      ),
      throwsFormatException,
    );
    expect(service.snapshot.phaseTaskEvidence, hasLength(350));
  });

  test(
    'distinct partial and malformed assessment outcomes cannot replace a pass',
    () {
      final pass = passingResult.evidence('passing', startedAt);
      final questionIds = task.assessment.questions
          .map((question) => question.id)
          .toList(growable: false);
      final partialA = changed(
        pass,
        id: 'partial-a',
        time: startedAt.add(const Duration(hours: 1)),
        score: 1 / questionIds.length,
        criteria: [questionIds.first],
      );
      final partialB = changed(
        pass,
        id: 'partial-b',
        time: startedAt.add(const Duration(hours: 2)),
        score: 1 / questionIds.length,
        criteria: [questionIds.last],
      );
      final wrongScore = changed(
        pass,
        id: 'wrong-score',
        time: startedAt.add(const Duration(hours: 3)),
        score: .8,
      );
      final unknownCriterion = changed(
        pass,
        id: 'unknown-criterion',
        time: startedAt.add(const Duration(hours: 4)),
        criteria: [...pass.passedCriterionIds, 'unknown-question'],
      );
      final result = CourseMasteryService(curriculum).mergeForReconciliation(
        local: snapshot([
          pass,
          partialA,
          partialB,
          wrongScore,
          unknownCriterion,
          ...repeatedFailures(350),
        ]),
        remote: null,
      );

      expect(result.isValid, isTrue);
      final retained = result.snapshot!.phaseTaskEvidence;
      for (final id in [
        'passing',
        'partial-a',
        'partial-b',
        'wrong-score',
        'unknown-criterion',
      ]) {
        expect(retained.any((entry) => entry.attemptId == id), isTrue);
      }
      expect(task.passedBy(pass), isTrue);
      expect(task.passedBy(wrongScore), isFalse);
      expect(task.passedBy(unknownCriterion), isFalse);
    },
  );

  test('semantic anchors may exceed the repeat-history cap', () {
    final base = passingResult.evidence('revision-001', startedAt);
    final revisions = [
      for (var revision = 1; revision <= 902; revision++)
        changed(
          base,
          id: 'revision-${revision.toString().padLeft(3, '0')}',
          time: startedAt.add(Duration(minutes: revision)),
          revision: revision,
        ),
    ];

    final result = CourseMasteryService(curriculum).mergeForReconciliation(
      local: snapshot(revisions),
      remote: null,
    );

    expect(result.isValid, isTrue);
    expect(result.snapshot!.phaseTaskEvidence, hasLength(902));
  });

  test('merge is commutative at time ties and conflicts before compaction', () {
    final tied = repeatedFailures(310, time: startedAt);
    final local = snapshot([
      for (var index = 0; index < tied.length; index += 2) tied[index],
    ]);
    final remote = snapshot([
      for (var index = 1; index < tied.length; index += 2) tied[index],
    ]);
    final service = CourseMasteryService(curriculum);

    final forward = service.mergeForReconciliation(
      local: local,
      remote: remote,
    );
    final reverse = service.mergeForReconciliation(
      local: remote,
      remote: local,
    );

    expect(forward.isValid, isTrue);
    expect(forward.snapshot!.toJson(), reverse.snapshot!.toJson());
    expect(forward.snapshot!.phaseTaskEvidence, hasLength(301));
    expect(forward.snapshot!.phaseTaskEvidence.last.attemptId, 'failure-309');
    expect(
      forward.snapshot!.phaseTaskEvidence.any(
        (entry) => entry.attemptId == 'failure-000',
      ),
      isFalse,
    );

    final original = failingResult.evidence('conflict', startedAt);
    final altered = changed(
      original,
      id: 'conflict',
      time: startedAt,
      score: .25,
      criteria: const ['synthetic-criterion'],
    );
    final conflicted = service.mergeForReconciliation(
      local: snapshot([original, ...tied]),
      remote: snapshot([altered]),
    );
    expect(conflicted.isValid, isFalse);
    expect(conflicted.conflicts.single.id, 'conflict');
  });
}
