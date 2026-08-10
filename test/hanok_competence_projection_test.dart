import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';

const _text = CurriculumText(ko: '장면', de: 'Szene', en: 'Scene');

CourseUnit _unit(String id, String level, int order) =>
    CourseUnit(id: id, level: level, order: order, title: _text, canDo: _text);

void main() {
  test(
    'counts only completed known units, never bypasses or browse history',
    () {
      final units = [
        _unit('a1_01', 'a1', 1),
        _unit('a1_02', 'a1', 2),
        _unit('a1_03', 'a1', 3),
        _unit('a1_04', 'a1', 4),
      ];
      final projection = HanokCompetenceProjection.fromSnapshot(
        snapshot: CourseMasterySnapshot(
          completedUnitIds: const ['a1_01', 'unknown', 'a1_01'],
          bypassedPrerequisiteUnitIds: const ['a1_02'],
          scenarioCheckpoints: [
            ScenarioCheckpointEvidence(
              scenarioId: 'browse_only',
              score: 1,
              occurredAt: DateTime.utc(2026),
            ),
          ],
        ),
        courseUnits: units,
      );

      expect(projection.completedUnitCount, 1);
      expect(projection.totalUnitCount, 4);
      expect(projection.a1Ratio, .25);
      expect(projection.stage, HanokStage.foundation);
    },
  );

  test(
    'a completed course path can raise structure without changing study',
    () {
      final units = [
        for (var index = 1; index <= 4; index++)
          _unit('a1_$index', 'a1', index),
        for (var index = 1; index <= 4; index++)
          _unit('a2_$index', 'a2', index),
      ];
      final competence = HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_1', 'a1_2', 'a1_3', 'a1_4', 'a2_1'],
        ),
        courseUnits: units,
      );
      final personal = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        competence: competence,
      );

      expect(competence.stage, HanokStage.tileRoofPartial);
      expect(personal.legacyStage, HanokStage.empty);
      expect(personal.structureStage, HanokStage.tileRoofPartial);
      expect(personal.studyFraction, 0);
    },
  );

  test('never pools partial pack and course levels into a new structure', () {
    final competence = HanokCompetenceProjection.fromSnapshot(
      snapshot: const CourseMasterySnapshot(completedUnitIds: ['a2_01']),
      courseUnits: [_unit('a1_01', 'a1', 1), _unit('a2_01', 'a2', 1)],
    );
    final personal = PersonalHanokProjection.from(
      const LevelRatios(a1: 1, a2: 0, b1: 0, b2: 0),
      competence: competence,
    );

    expect(competence.stage, HanokStage.empty);
    expect(personal.structureStage, HanokStage.thatchRoof);
    expect(personal.usesCompoundMap, isFalse);
  });

  test(
    'a complete course path opens the same map milestones as legacy study',
    () {
      final units = [
        _unit('a1_01', 'a1', 1),
        _unit('a2_01', 'a2', 1),
        for (var index = 1; index <= 4; index++)
          _unit('b1_$index', 'b1', index),
      ];
      final competence = HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot(
          completedUnitIds: ['a1_01', 'a2_01', 'b1_1'],
        ),
        courseUnits: units,
      );
      final personal = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        competence: competence,
      );

      expect(competence.stage, HanokStage.gate);
      expect(personal.usesCompoundMap, isTrue);
      expect(personal.isUnlocked(PersonalHanokMilestone.sotdaeulmun), isTrue);
    },
  );
}
