import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';

const _greeting = CourseUnit(
  id: 'a1_01',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greeting'),
  canDo: CurriculumText(
    ko: '처음 만난 사람에게 인사할 수 있어요.',
    de: 'Ich kann eine neue Person begrüßen.',
    en: 'I can greet someone new.',
  ),
);

const _introduction = CourseUnit(
  id: 'a1_02',
  level: 'a1',
  order: 2,
  title: CurriculumText(ko: '소개', de: 'Vorstellung', en: 'Introduction'),
  canDo: CurriculumText(
    ko: '나를 짧게 소개할 수 있어요.',
    de: 'Ich kann mich kurz vorstellen.',
    en: 'I can introduce myself briefly.',
  ),
);

final _projection = PersonalHanokProjection.from(
  const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
);

const _sceneUnit = CourseUnit(
  id: 'a1_scene',
  level: 'a1',
  order: 3,
  title: CurriculumText(ko: '생활 장면', de: 'Alltagsszene', en: 'Daily scene'),
  canDo: CurriculumText(
    ko: '생활 장면을 안전하게 마칠 수 있어요.',
    de: 'Ich kann eine Alltagsszene sicher abschließen.',
    en: 'I can complete an everyday scene safely.',
  ),
  requiredConceptIds: ['safe_scene'],
  checkpointContentIds: ['scenario:scene_one', 'scenario:scene_two'],
  passThreshold: .7,
);

final _sceneLinks = [
  ContentLink(
    contentKind: CurriculumContentKind.scenario,
    contentId: 'scene_one',
    courseUnitId: _sceneUnit.id,
    conceptIds: const ['safe_scene'],
    role: ContentLinkRole.assess,
  ),
  ContentLink(
    contentKind: CurriculumContentKind.scenario,
    contentId: 'scene_two',
    courseUnitId: _sceneUnit.id,
    conceptIds: const ['safe_scene'],
    role: ContentLinkRole.assess,
  ),
];

const _nextSceneUnit = CourseUnit(
  id: 'a1_next_scene',
  level: 'a1',
  order: 4,
  title: CurriculumText(ko: '다음 장면', de: 'Nächste Szene', en: 'Next scene'),
  canDo: CurriculumText(
    ko: '정중하게 부탁할 수 있어요.',
    de: 'Ich kann höflich um etwas bitten.',
    en: 'I can make a polite request.',
  ),
  requiredConceptIds: ['safe_scene'],
  checkpointContentIds: ['scenario:scene_next'],
);

Scenario _scenario(String id, String expression) => Scenario(
  id: id,
  level: LearnerLevel.a1,
  emoji: '🏠',
  register: Register.polite,
  title: LocalizedText(ko: '생활 장면', de: 'Alltagsszene', en: 'Daily scene'),
  intro: LocalizedText(ko: '', de: 'Eine kurze Szene', en: 'A short scene'),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: [
    QuestSpec(type: QuestType.satzBauen, data: {'targetKo': expression}),
  ],
);

void main() {
  test(
    'keeps verified and next course abilities separate from visual stage',
    () {
      final narrative = HanokBuildNarrative.fromSnapshot(
        projection: _projection,
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_01'],
          currentCourseUnitId: 'a1_02',
        ),
        courseUnits: [_greeting, _introduction],
      );

      expect(narrative.projection.legacyStage.name, 'foundation');
      expect(narrative.verifiedUnit?.id, 'a1_01');
      expect(narrative.nextUnit?.id, 'a1_02');
    },
  );

  test('does not describe placement-bypassed units as verified ability', () {
    final narrative = HanokBuildNarrative.fromSnapshot(
      projection: _projection,
      snapshot: const CourseMasterySnapshot(
        bypassedPrerequisiteUnitIds: ['a1_01'],
        currentCourseUnitId: 'a1_02',
      ),
      courseUnits: [_greeting, _introduction],
    );

    expect(narrative.verifiedUnit, isNull);
    expect(narrative.nextUnit?.id, 'a1_02');
  });

  test(
    'uses course order rather than snapshot list order for the latest can-do',
    () {
      final narrative = HanokBuildNarrative.fromSnapshot(
        projection: _projection,
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_02', 'a1_01'],
        ),
        courseUnits: [_introduction, _greeting],
      );

      expect(narrative.verifiedUnit?.id, 'a1_02');
      expect(narrative.nextUnit, isNull);
    },
  );

  test('makes no ability claim for unknown durable IDs', () {
    final narrative = HanokBuildNarrative.fromSnapshot(
      projection: _projection,
      snapshot: const CourseMasterySnapshot(
        completedUnitIds: ['unknown'],
        currentCourseUnitId: 'stale',
      ),
      courseUnits: [_greeting, _introduction],
    );

    expect(narrative.hasVerifiedCanDo, isFalse);
    expect(narrative.hasNextCanDo, isFalse);
  });

  test('counts only latest eligible declared assess scenes toward a beam', () {
    final narrative = HanokBuildNarrative.fromSnapshot(
      projection: _projection,
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_one',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: _sceneLinks[0].id,
            score: .6,
            occurredAt: DateTime.utc(2026, 8, 10),
            courseEligible: true,
          ),
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_one',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: _sceneLinks[0].id,
            score: .8,
            occurredAt: DateTime.utc(2026, 8, 11),
            courseEligible: true,
          ),
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_two',
            courseUnitId: _sceneUnit.id,
            score: 1,
            occurredAt: DateTime.utc(2026, 8, 11),
          ),
          ScenarioCheckpointEvidence(
            scenarioId: 'stale_scene',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: 'stale-scene-link',
            score: 1,
            occurredAt: DateTime.utc(2026, 8, 11),
            courseEligible: true,
          ),
        ],
      ),
      courseUnits: const [_sceneUnit],
      contentLinks: _sceneLinks,
    );

    expect(narrative.safeSceneCount, 1);
    expect(narrative.safeScenesTowardNextBeam, 1);
    expect(narrative.scenesPerBeam, 2);
    expect(narrative.plannedBeamCount, 1);
  });

  test(
    'a later failed attempt removes an earlier scene from safe progress',
    () {
      final narrative = HanokBuildNarrative.fromSnapshot(
        projection: _projection,
        snapshot: CourseMasterySnapshot(
          scenarioCheckpoints: [
            ScenarioCheckpointEvidence(
              scenarioId: 'scene_one',
              courseUnitId: _sceneUnit.id,
              missionContentLinkId: _sceneLinks[0].id,
              score: .9,
              occurredAt: DateTime.utc(2026, 8, 10),
              courseEligible: true,
            ),
            ScenarioCheckpointEvidence(
              scenarioId: 'scene_one',
              courseUnitId: _sceneUnit.id,
              missionContentLinkId: _sceneLinks[0].id,
              score: .69,
              occurredAt: DateTime.utc(2026, 8, 11),
              courseEligible: true,
            ),
          ],
        ),
        courseUnits: const [_sceneUnit],
        contentLinks: _sceneLinks,
      );

      expect(narrative.safeSceneCount, 0);
      expect(narrative.safeScenesTowardNextBeam, 0);
      expect(narrative.plannedBeamCount, 0);
    },
  );

  test('two distinct latest safe scenes fill the current beam goal', () {
    final narrative = HanokBuildNarrative.fromSnapshot(
      projection: _projection,
      snapshot: CourseMasterySnapshot(
        scenarioCheckpoints: [
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_one',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: _sceneLinks[0].id,
            score: .7,
            occurredAt: DateTime.utc(2026, 8, 10),
            courseEligible: true,
          ),
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_two',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: _sceneLinks[1].id,
            score: .85,
            occurredAt: DateTime.utc(2026, 8, 11),
            courseEligible: true,
          ),
        ],
      ),
      courseUnits: const [_sceneUnit],
      contentLinks: _sceneLinks,
    );

    expect(narrative.safeSceneCount, 2);
    expect(narrative.safeScenesTowardNextBeam, 2);
    expect(narrative.plannedBeamCount, 1);
  });

  test('keeps actual earned and next-scene expressions in the receipt', () {
    final nextLink = ContentLink(
      contentKind: CurriculumContentKind.scenario,
      contentId: 'scene_next',
      courseUnitId: _nextSceneUnit.id,
      conceptIds: const ['safe_scene'],
      role: ContentLinkRole.assess,
    );
    final narrative = HanokBuildNarrative.fromSnapshot(
      projection: _projection,
      snapshot: CourseMasterySnapshot(
        currentCourseUnitId: _nextSceneUnit.id,
        scenarioCheckpoints: [
          ScenarioCheckpointEvidence(
            scenarioId: 'scene_one',
            courseUnitId: _sceneUnit.id,
            missionContentLinkId: _sceneLinks[0].id,
            score: .9,
            occurredAt: DateTime.utc(2026, 8, 11),
            courseEligible: true,
          ),
        ],
      ),
      courseUnits: const [_sceneUnit, _nextSceneUnit],
      contentLinks: [..._sceneLinks, nextLink],
      scenarios: [
        _scenario('scene_one', '안 맵게 해 주세요.'),
        _scenario('scene_next', '천천히 말해 주세요.'),
      ],
    );

    expect(narrative.receipt.earnedExpressionCount, 1);
    expect(narrative.receipt.latestSafeScenarioId, 'scene_one');
    expect(narrative.receipt.latestSafeExpressionKo, '안 맵게 해 주세요.');
    expect(narrative.receipt.nextScenarioId, 'scene_next');
    expect(narrative.receipt.nextExpressionKo, '천천히 말해 주세요.');
  });
}
