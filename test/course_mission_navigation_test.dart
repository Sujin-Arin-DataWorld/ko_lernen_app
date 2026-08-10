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

  test(
    'mission navigation keeps typed scenario provenance and scopes games',
    () {
      final scenarioLink = link(CurriculumContentKind.scenario);
      final scenarioContext =
          destinationForCourseLink(scenarioLink)!.arguments
              as CoursePracticeContext;
      expect(destinationForCourseLink(scenarioLink)!.route, '/scenario');
      expect(scenarioContext.contentKind, CurriculumContentKind.scenario);
      expect(scenarioContext.initialContentId, 'content_1');
      expect(scenarioIdFromRouteArguments(scenarioContext), 'content_1');
      expect(scenarioIdFromRouteArguments('content_1'), 'content_1');
      expect(
        destinationForCourseLink(link(CurriculumContentKind.cloze))!.arguments,
        'a1_01_greetings_hangul',
      );
      expect(
        destinationForCourseLink(link(CurriculumContentKind.satz))!.arguments,
        'a1_01_greetings_hangul',
      );
    },
  );

  test(
    'mission navigation preserves typed provenance for vocab, grammar, and smalltalk',
    () {
      final grammarLink = link(CurriculumContentKind.grammar);
      final smalltalkLink = link(CurriculumContentKind.smalltalk);
      final vocabLink = link(CurriculumContentKind.vocab);

      final grammarContext =
          destinationForCourseLink(grammarLink)!.arguments
              as CoursePracticeContext;
      final smalltalkContext =
          destinationForCourseLink(smalltalkLink)!.arguments
              as CoursePracticeContext;
      final vocabContext =
          destinationForCourseLink(vocabLink)!.arguments
              as CoursePracticeContext;

      expect(grammarContext.courseUnitId, 'a1_01_greetings_hangul');
      expect(grammarContext.contentKind, CurriculumContentKind.grammar);
      expect(grammarContext.initialContentId, 'content_1');
      expect(grammarContext.contentLinkId, grammarLink.id);
      expect(smalltalkContext.contentKind, CurriculumContentKind.smalltalk);
      expect(smalltalkContext.contentLinkId, smalltalkLink.id);
      expect(vocabContext.contentKind, CurriculumContentKind.vocab);
      expect(vocabContext.contentLinkId, vocabLink.id);
      expect(
        courseUnitIdFromVocabRouteArguments(vocabContext),
        'a1_01_greetings_hangul',
      );
      expect(
        courseUnitIdFromVocabRouteArguments('a1_01_greetings_hangul'),
        'a1_01_greetings_hangul',
      );
      expect(courseUnitIdFromVocabRouteArguments(grammarContext), isNull);
      final matchingPackContext = vocabCourseContextForPack(
        courseContext: vocabContext,
        contentIds: const ['content_1', 'content_2'],
      );
      expect(matchingPackContext, same(vocabContext));
      expect(
        vocabCourseContextForPack(
          courseContext: vocabContext,
          contentIds: const ['content_2'],
        ),
        isNull,
      );
      final packArguments = vocabPackRouteArguments(
        packId: 'a1_greetings',
        courseContext: matchingPackContext,
      );
      expect(vocabPackIdFromRouteArguments(packArguments), 'a1_greetings');
      expect(
        vocabCourseContextFromPackRouteArguments(packArguments),
        same(vocabContext),
      );
      expect(
        vocabPackRouteArguments(packId: 'a1_greetings_2', courseContext: null),
        'a1_greetings_2',
      );
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
