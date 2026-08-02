import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';

void main() {
  ContentLink link(CurriculumContentKind kind) => ContentLink(
    contentKind: kind,
    contentId: 'content_1',
    courseUnitId: 'a1_01_greetings_hangul',
    conceptIds: const ['concept_1'],
    role: ContentLinkRole.practice,
  );

  test('mission navigation keeps a scenario ID and scopes game routes', () {
    expect(
      destinationForCourseLink(link(CurriculumContentKind.scenario))!.route,
      '/scenario',
    );
    expect(
      destinationForCourseLink(link(CurriculumContentKind.scenario))!.arguments,
      'content_1',
    );
    expect(
      destinationForCourseLink(link(CurriculumContentKind.cloze))!.arguments,
      'a1_01_greetings_hangul',
    );
    expect(
      destinationForCourseLink(link(CurriculumContentKind.vocab))!.arguments,
      'a1_01_greetings_hangul',
    );
    expect(
      destinationForCourseLink(link(CurriculumContentKind.satz))!.arguments,
      'a1_01_greetings_hangul',
    );
  });
}
