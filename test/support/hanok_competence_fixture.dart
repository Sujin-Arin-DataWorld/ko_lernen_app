import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';

const _text = CurriculumText(ko: '장면', de: 'Szene', en: 'Scene');

HanokCompetenceProjection hanokCompetenceFixture({
  int a1Completed = 0,
  int a1Total = 4,
  int a2Completed = 0,
  int a2Total = 4,
  int b1Completed = 0,
  int b1Total = 4,
  int b2Completed = 0,
  int b2Total = 4,
}) {
  final units = <CourseUnit>[];
  final completed = <String>[];
  void addLevel(String level, int total, int completedCount) {
    for (var index = 0; index < total; index++) {
      final id = '$level.fixture.${index + 1}';
      units.add(
        CourseUnit(
          id: id,
          level: level,
          order: index + 1,
          title: _text,
          canDo: _text,
        ),
      );
      if (index < completedCount.clamp(0, total)) {
        completed.add(id);
      }
    }
  }

  addLevel('a1', a1Total, a1Completed);
  addLevel('a2', a2Total, a2Completed);
  addLevel('b1', b1Total, b1Completed);
  addLevel('b2', b2Total, b2Completed);
  return HanokCompetenceProjection.fromSnapshot(
    snapshot: CourseMasterySnapshot(completedUnitIds: completed),
    courseUnits: units,
  );
}
