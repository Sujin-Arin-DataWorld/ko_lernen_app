import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final clozeContext =
          destinationForCourseLink(link(CurriculumContentKind.cloze))!.arguments
              as CoursePracticeContext;
      final satzContext =
          destinationForCourseLink(link(CurriculumContentKind.satz))!.arguments
              as CoursePracticeContext;
      expect(clozeContext.contentKind, CurriculumContentKind.cloze);
      expect(satzContext.contentKind, CurriculumContentKind.satz);
      expect(
        courseUnitIdFromActivityRouteArguments(
          clozeContext,
          CurriculumContentKind.cloze,
        ),
        'a1_01_greetings_hangul',
      );
      expect(
        courseUnitIdFromActivityRouteArguments(
          'legacy-unit',
          CurriculumContentKind.satz,
        ),
        'legacy-unit',
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

  test('direct vocab mission resolves the production source pack', () async {
    final catalog = await CurriculumCatalog.load();
    final vocabLink = catalog
        .linksForCourseUnit('a1_01_greetings_hangul')
        .firstWhere((item) => item.contentKind == CurriculumContentKind.vocab);

    final destination = await directDestinationForCourseLink(vocabLink);

    expect(destination?.route, '/vocab/pack');
    final arguments = destination!.arguments as VocabPackRouteArguments;
    expect(arguments.packId, isNotEmpty);
    expect(arguments.courseContext.contentLinkId, vocabLink.id);
    expect(arguments.courseContext.initialContentId, vocabLink.contentId);
  });

  test('direct vocab resolver selects only the exact word pack', () async {
    final vocabLink = link(CurriculumContentKind.vocab);
    final destination = await directDestinationForCourseLink(
      vocabLink,
      vocabPacksLoader: () async => [
        _pack('wrong-pack', 'other'),
        _pack('exact-pack', vocabLink.contentId),
      ],
    );

    final arguments = destination!.arguments as VocabPackRouteArguments;
    expect(destination.route, '/vocab/pack');
    expect(arguments.packId, 'exact-pack');
    expect(arguments.courseContext.contentLinkId, vocabLink.id);
  });

  test(
    'missing mission word never falls back to the pack marketplace',
    () async {
      final destination = await directDestinationForCourseLink(
        link(CurriculumContentKind.vocab),
        vocabPacksLoader: () async => [_pack('wrong-pack', 'other')],
      );

      expect(destination, isNull);
    },
  );
}

VocabPack _pack(String packId, String wordId) => VocabPack(
  id: packId,
  level: 'A1',
  words: [
    Vocab(
      id: wordId,
      korean: '안녕',
      romanization: 'annyeong',
      german: 'Hallo',
      level: 'A1',
      posDe: 'Gruß',
      exampleKorean: '안녕하세요.',
      exampleGerman: 'Guten Tag.',
      topic: 'Begrüßung',
      packId: packId,
      packOrder: 1,
    ),
  ],
);
