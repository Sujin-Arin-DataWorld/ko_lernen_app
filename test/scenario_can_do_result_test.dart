import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';

void main() {
  const unit = CourseUnit(
    id: 'a1_01',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '인사', de: 'Gruß', en: 'Greeting'),
    canDo: CurriculumText(
      ko: '처음 만난 사람에게 인사할 수 있어요.',
      de: 'Ich kann eine neue Person begrüßen.',
      en: 'I can greet someone new.',
    ),
    requiredConceptIds: ['concept_greeting'],
    checkpointContentIds: ['scenario:greeting_scene'],
    passThreshold: .7,
  );
  final sceneLink = ContentLink(
    id: 'greeting-scene-assess',
    contentKind: CurriculumContentKind.scenario,
    contentId: 'greeting_scene',
    courseUnitId: unit.id,
    conceptIds: const ['concept_greeting'],
    role: ContentLinkRole.assess,
  );

  ScenarioCheckpointEvidence checkpoint({
    required double score,
    required bool courseEligible,
    String? courseUnitId = 'a1_01',
    String? missionContentLinkId = 'greeting-scene-assess',
    int minute = 0,
  }) => ScenarioCheckpointEvidence(
    scenarioId: 'greeting_scene',
    courseUnitId: courseUnitId,
    missionContentLinkId: missionContentLinkId,
    score: score,
    occurredAt: DateTime.utc(2026, 8, 10, 12, minute),
    courseEligible: courseEligible,
  );

  test('uses the latest eligible checkpoint at the exact threshold', () {
    final result = ScenarioCanDoResult.fromSnapshot(
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [
          checkpoint(score: .2, courseEligible: false),
          checkpoint(score: .7, courseEligible: true, minute: 1),
        ],
      ),
      scenarioId: 'greeting_scene',
      courseUnits: [unit],
      contentLinks: [sceneLink],
    );

    expect(result?.status, ScenarioCanDoStatus.verified);
    expect(result?.courseUnit?.id, unit.id);
  });

  test('marks a saved active checkpoint below threshold for review', () {
    final result = ScenarioCanDoResult.fromSnapshot(
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [checkpoint(score: .69, courseEligible: true)],
      ),
      scenarioId: 'greeting_scene',
      courseUnits: [unit],
      contentLinks: [sceneLink],
    );

    expect(result?.status, ScenarioCanDoStatus.reviewNeeded);
    expect(result?.courseUnit?.canDo.en, 'I can greet someone new.');
  });

  test('keeps free browsing as practice without a course can-do claim', () {
    final result = ScenarioCanDoResult.fromSnapshot(
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [checkpoint(score: 1, courseEligible: false)],
      ),
      scenarioId: 'greeting_scene',
      courseUnits: [unit],
      contentLinks: [sceneLink],
    );

    expect(result?.status, ScenarioCanDoStatus.practiceOnly);
    expect(result?.courseUnit, isNull);
  });

  test('keeps legacy eligible bytes without an exact link as practice', () {
    final result = ScenarioCanDoResult.fromSnapshot(
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [
          checkpoint(
            score: 1,
            courseEligible: true,
            missionContentLinkId: null,
          ),
        ],
      ),
      scenarioId: 'greeting_scene',
      courseUnits: [unit],
      contentLinks: [sceneLink],
    );

    expect(result?.status, ScenarioCanDoStatus.practiceOnly);
    expect(result?.courseUnit, isNull);
  });

  test('does not claim a result when no checkpoint was persisted', () {
    final result = ScenarioCanDoResult.fromSnapshot(
      snapshot: const CourseMasterySnapshot.empty(),
      scenarioId: 'greeting_scene',
      courseUnits: [unit],
      contentLinks: [sceneLink],
    );

    expect(result, isNull);
  });
}
