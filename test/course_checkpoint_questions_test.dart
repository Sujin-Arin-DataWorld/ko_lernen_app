import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_checkpoint_questions.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DataLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  test(
    'course context scopes grammar and smalltalk to its graph mission',
    () async {
      final catalog = await CurriculumCatalog.load();
      final grammarLink = catalog.contentLinks.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.grammar &&
            link.courseUnitId == 'a1_03_topic_subject_particles',
      );
      final smalltalkLink = catalog.contentLinks.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.smalltalk &&
            link.courseUnitId == 'a1_04_order_request_object',
      );

      final grammarIds = courseContentIdsForContext(
        catalog: catalog,
        courseContext: CoursePracticeContext.fromLink(grammarLink),
        kind: CurriculumContentKind.grammar,
      );
      final smalltalkIds = courseContentIdsForContext(
        catalog: catalog,
        courseContext: CoursePracticeContext.fromLink(smalltalkLink),
        kind: CurriculumContentKind.smalltalk,
      );

      expect(grammarIds, contains(grammarLink.contentId));
      expect(grammarIds, isNot(contains(smalltalkLink.contentId)));
      expect(smalltalkIds, contains(smalltalkLink.contentId));
      expect(smalltalkIds, isNotEmpty);

      final tampered = CoursePracticeContext(
        courseUnitId: grammarLink.courseUnitId,
        contentKind: CurriculumContentKind.grammar,
        initialContentId: grammarLink.contentId,
        contentLinkId: smalltalkLink.id,
      );
      expect(
        courseContentIdsForContext(
          catalog: catalog,
          courseContext: tampered,
          kind: CurriculumContentKind.grammar,
        ),
        isEmpty,
      );
      expect(
        courseContentIdsForContext(
          catalog: catalog,
          courseContext: null,
          kind: CurriculumContentKind.grammar,
        ),
        isNull,
      );

      final otherGrammarLink = catalog.contentLinks.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.grammar &&
            link.contentId != grammarLink.contentId,
      );
      final swappedInitialContent = CoursePracticeContext(
        courseUnitId: grammarLink.courseUnitId,
        contentKind: CurriculumContentKind.grammar,
        initialContentId: otherGrammarLink.contentId,
        contentLinkId: grammarLink.id,
      );
      expect(
        courseContentIdsForContext(
          catalog: catalog,
          courseContext: swappedInitialContent,
          kind: CurriculumContentKind.grammar,
        ),
        isEmpty,
      );
      expect(
        courseAssessmentLinksForContext(
          catalog: catalog,
          courseContext: swappedInitialContent,
          kind: CurriculumContentKind.grammar,
        ),
        isEmpty,
      );
    },
  );

  test(
    'only an assess route exposes smalltalk checkpoint evidence links',
    () async {
      final catalog = await CurriculumCatalog.load();
      final practiceLink = catalog.contentLinks.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.smalltalk &&
            link.courseUnitId == 'a1_04_order_request_object' &&
            link.role == ContentLinkRole.practice,
      );
      final assessLink = catalog.contentLinks.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.smalltalk &&
            link.courseUnitId == 'a2_02_plans_proposals' &&
            link.role == ContentLinkRole.assess,
      );

      expect(
        courseAssessmentLinksForContext(
          catalog: catalog,
          courseContext: CoursePracticeContext.fromLink(practiceLink),
          kind: CurriculumContentKind.smalltalk,
        ),
        isEmpty,
      );

      final assessments = courseAssessmentLinksForContext(
        catalog: catalog,
        courseContext: CoursePracticeContext.fromLink(assessLink),
        kind: CurriculumContentKind.smalltalk,
      );
      expect(
        assessments.keys,
        containsAll(<String>['smalltalk_a2_0015', 'smalltalk_a2_0022']),
      );
      expect(
        assessments.values.every(
          (link) =>
              link.role == ContentLinkRole.assess &&
              link.conceptIds.length == 1 &&
              link.conceptIds.single == 'concept_proposal_casual',
        ),
        isTrue,
      );
    },
  );

  test(
    'grammar checkpoint choices are deterministic and credit one source',
    () async {
      final grammar = await DataLoader.loadGrammar();

      for (final target in grammar) {
        final question = GrammarCheckpointQuestion.forGrammar(
          target: target,
          candidates: grammar,
        );

        expect(question.contentId, target.id);
        expect(question.optionIds, contains(target.id));
        expect(
          question.optionIds.toSet(),
          hasLength(question.optionIds.length),
        );
        expect(question.optionIds, hasLength(3));
        expect(question.isCorrect(target.id), isTrue);
        expect(
          question.isCorrect(
            question.optionIds.firstWhere((id) => id != target.id),
          ),
          isFalse,
        );
        expect(
          GrammarCheckpointQuestion.forGrammar(
            target: target,
            candidates: grammar,
          ).optionIds,
          orderedEquals(question.optionIds),
        );
      }
    },
  );

  test(
    'a single scoped grammar card stays study-only until it has a distractor',
    () async {
      final grammar = await DataLoader.loadGrammar();
      final question = GrammarCheckpointQuestion.forGrammar(
        target: grammar.first,
        candidates: [grammar.first],
      );

      expect(question.optionIds, orderedEquals([grammar.first.id]));
      expect(question.canRecordEvidence, isFalse);
    },
  );

  test(
    'smalltalk relationship checkpoint is available for every source line',
    () async {
      await SmalltalkLoader.load();

      for (final phrase in SmalltalkLoader.phrases) {
        final question = SmalltalkRelationshipCheckpoint.forPhrase(phrase);

        expect(question.contentId, phrase.id);
        expect(question.options, contains(phrase.relationshipContext));
        expect(question.options, hasLength(3));
        expect(question.isCorrect(phrase.relationshipContext), isTrue);
        expect(
          question.isCorrect(
            question.options.firstWhere(
              (context) => context != phrase.relationshipContext,
            ),
          ),
          isFalse,
        );
      }
    },
  );
}
