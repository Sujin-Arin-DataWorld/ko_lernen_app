import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
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

  test(
    'mission navigation preserves typed provenance for grammar and smalltalk',
    () {
      final grammarLink = link(CurriculumContentKind.grammar);
      final smalltalkLink = link(CurriculumContentKind.smalltalk);

      final grammarContext =
          destinationForCourseLink(grammarLink)!.arguments
              as CoursePracticeContext;
      final smalltalkContext =
          destinationForCourseLink(smalltalkLink)!.arguments
              as CoursePracticeContext;

      expect(grammarContext.courseUnitId, 'a1_01_greetings_hangul');
      expect(grammarContext.contentKind, CurriculumContentKind.grammar);
      expect(grammarContext.initialContentId, 'content_1');
      expect(grammarContext.contentLinkId, grammarLink.id);
      expect(smalltalkContext.contentKind, CurriculumContentKind.smalltalk);
      expect(smalltalkContext.contentLinkId, smalltalkLink.id);
      expect(
        coursePracticeContextFromRouteArguments(
          grammarContext,
          CurriculumContentKind.grammar,
        ),
        same(grammarContext),
      );
      expect(
        coursePracticeContextFromRouteArguments(
          grammarContext,
          CurriculumContentKind.smalltalk,
        ),
        isNull,
      );
      expect(
        coursePracticeContextFromRouteArguments(
          'a1_01_greetings_hangul',
          CurriculumContentKind.grammar,
        ),
        isNull,
      );
    },
  );
}
