import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
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
}
