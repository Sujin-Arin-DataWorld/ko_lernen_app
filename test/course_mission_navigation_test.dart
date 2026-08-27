import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

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

  group('activeScenarioCheckpointContext', () {
    test('활성 유닛의 체크포인트 시나리오면 컨텍스트를 유도한다', () async {
      final catalog = _miniCheckpointCatalog();
      final snapshot = const CourseMasterySnapshot(
        currentCourseUnitId: 'a1_01_greetings_hangul',
      );
      final context = await activeScenarioCheckpointContext(
        'airport_arrival',
        catalog: catalog,
        snapshot: snapshot,
      );
      expect(context, isNotNull);
      expect(context!.courseUnitId, 'a1_01_greetings_hangul');
      expect(context.contentKind, CurriculumContentKind.scenario);
      expect(context.initialContentId, 'airport_arrival');
    });

    test('활성 유닛이 없으면 null', () async {
      final catalog = _miniCheckpointCatalog();
      final context = await activeScenarioCheckpointContext(
        'airport_arrival',
        catalog: catalog,
        snapshot: const CourseMasterySnapshot.empty(),
      );
      expect(context, isNull);
    });

    test('시나리오가 활성 유닛의 체크포인트가 아니면 null (브라우즈 유지)', () async {
      final catalog = _miniCheckpointCatalog();
      final snapshot = const CourseMasterySnapshot(
        currentCourseUnitId: 'a1_01_greetings_hangul',
      );
      final context = await activeScenarioCheckpointContext(
        'unrelated_scenario',
        catalog: catalog,
        snapshot: snapshot,
      );
      expect(context, isNull);
    });

    // T6 리뷰 요구사항: 이 함수는 course_mastery_service.recordScenarioCheckpoint
    // 내부 판정을 그대로 미러링한다는 문서 주석 하나로만 서비스와 연결돼 있었다.
    // 미러와 실제 서비스가 갈라져도 겉보기 단위 테스트는 계속 통과할 수 있으므로,
    // 유도된 컨텍스트를 실제 서비스에 흘려 넣어 courseEligible이 참이 되는지 직접
    // 왕복 검증한다 — 둘 사이에 드리프트가 생기면 이 테스트가 시끄럽게 실패한다.
    test(
      '유도된 컨텍스트를 실제 서비스에 넣으면 courseEligible이 참이 된다 (T6 미러-서비스 계약 회귀 가드)',
      () async {
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        addTearDown(Storage.resetForTesting);

        final catalog = _miniCheckpointCatalog();
        final service = CourseMasteryService(catalog);
        await service.initializeForPlacement('a1');
        expect(service.currentUnit?.id, 'a1_01_greetings_hangul');

        final context = await activeScenarioCheckpointContext(
          'airport_arrival',
          catalog: catalog,
          snapshot: service.snapshot,
        );
        expect(context, isNotNull);

        final update = await service.recordScenarioCheckpoint(
          'airport_arrival',
          1.0,
          courseContext: context,
        );

        expect(
          update.snapshot.scenarioCheckpoints.last.courseEligible,
          isTrue,
        );
      },
    );
  });
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

/// Mirrors the shape of `test/course_mastery_test.dart`'s private `_catalog()`
/// fixture (that helper cannot be reused across libraries), trimmed to the
/// single active unit + single checkpoint scenario this suite needs: unit
/// `a1_01_greetings_hangul` declares `checkpointContentIds:
/// ['scenario:airport_arrival']`, so the manifest's checkpoint-declaration
/// pass mints one exact `assess` edge for that scenario automatically.
CurriculumCatalog _miniCheckpointCatalog() {
  const unitId = 'a1_01_greetings_hangul';
  const conceptId = 'concept_greeting_politeness';
  const grammarId = 'grammar_greetings';
  final manifest = <String, dynamic>{
    'version': 1,
    'courseUnits': [
      {
        'id': unitId,
        'level': 'a1',
        'order': 1,
        'title': {'ko': '인사', 'de': 'Gruß', 'en': 'Greeting'},
        'canDo': {
          'ko': '인사할 수 있어요.',
          'de': 'Ich kann grüßen.',
          'en': 'I can greet.',
        },
        'requiredConceptIds': [conceptId],
        'checkpointContentIds': ['scenario:airport_arrival'],
        'isPilot': true,
      },
    ],
    'concepts': [
      {
        'id': conceptId,
        'level': 'a1',
        'kind': 'speechStyle',
        'title': {'ko': conceptId, 'de': conceptId, 'en': conceptId},
        'explanation': {'ko': conceptId, 'de': conceptId, 'en': conceptId},
      },
    ],
    'surfaceForms': const [],
    'formFamilies': const [],
    'contentLinks': const [],
    'vocabPackUnitMap': const {},
    'smalltalkCategoryUnitMap': const {},
    'smalltalkCheckpointPhraseMap': const {},
    'clozeTopicUnitMap': const {},
    'grammarRuleMap': {
      grammarId: {
        'courseUnitId': unitId,
        'conceptIds': [conceptId],
      },
    },
  };
  final grammar = <Grammar>[
    Grammar(
      id: grammarId,
      pattern: 'pattern_0',
      level: 'a1',
      typeDe: 'Test',
      explanationDe: '',
      exampleKorean: '',
      exampleGerman: '',
      note: '',
    ),
  ];
  final scenarios = <Scenario>[
    Scenario(
      id: 'airport_arrival',
      level: LearnerLevel.fromCode('a1')!,
      emoji: '💬',
      register: Register.polite,
      title: const LocalizedText(ko: '연습', de: 'Übung', en: 'Practice'),
      intro: const LocalizedText(ko: '연습', de: 'Übung', en: 'Practice'),
      vocab: const [],
      grammarIds: const [grammarId],
      dialog: const [],
      quests: const [],
      courseUnitId: unitId,
      speechStyle: SpeechStyle.polite,
      relationshipContext: 'service',
      intent: 'practice',
      conceptIds: const [conceptId],
    ),
  ];
  return CurriculumCatalog.fromDataForTesting(
    manifestJson: manifest,
    vocab: const [],
    grammar: grammar,
    smalltalk: const [],
    cloze: const [],
    satz: const [],
    scenarios: scenarios,
  );
}
