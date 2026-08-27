import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/learning_semantic_contract.dart';

void main() {
  group('level semantic contract', () {
    test('first-run aligns course start and browse without mastery grants', () {
      final initialization = OnboardingLevelInitialization.aligned(
        LearnerLevel.c1,
      );

      expect(initialization.validateForFirstRun().isValid, isTrue);
      expect(initialization.courseStart.allowedMutations, {
        LevelMutation.courseStartPoint,
      });
      expect(initialization.browseLevel.allowedMutations, {
        LevelMutation.browseFilter,
      });
      expect(
        initialization.courseStart.allowedMutations,
        isNot(contains(LevelMutation.mastery)),
      );
      expect(
        initialization.courseStart.allowedMutations,
        isNot(contains(LevelMutation.rewardInventory)),
      );
    });

    test('course placement rejects fabricated progression side effects', () {
      const plan = LevelChangePlan(
        intent: CourseStartLevelIntent(LearnerLevel.b1),
        declaredMutations: {
          LevelMutation.courseStartPoint,
          LevelMutation.completedUnits,
          LevelMutation.xp,
        },
      );

      final result = plan.validate();
      expect(result.isValid, isFalse);
      expect(result.hasCode('level.forbidden_mutation'), isTrue);
    });

    test('browse level cannot move the course start', () {
      const plan = LevelChangePlan(
        intent: BrowseLevelIntent(LearnerLevel.a2),
        declaredMutations: {
          LevelMutation.browseFilter,
          LevelMutation.courseStartPoint,
        },
      );

      expect(plan.validate().hasCode('level.forbidden_mutation'), isTrue);
    });
  });

  group('heart and bookmark semantic contract', () {
    const grammar = StudyItemSemanticRef(
      itemId: 'grammar.honorific-request',
      type: StudyItemType.grammar,
    );

    test('heart adds a favorite without review or SRS work', () {
      final plan = StudyActionPlan.heart(grammar);

      expect(plan.validate().isValid, isTrue);
      expect(plan.item.type, StudyItemType.grammar);
      expect(plan.declaredMutations, {StudyStoreMutation.favorites});
      expect(
        plan.declaredMutations,
        isNot(contains(StudyStoreMutation.reviewQueue)),
      );
    });

    test('bookmark preserves type and enters only the review queue', () {
      final plan = StudyActionPlan.bookmark(grammar);

      expect(plan.validate().isValid, isTrue);
      expect(plan.item.type, StudyItemType.grammar);
      expect(plan.declaredMutations, {StudyStoreMutation.reviewQueue});
    });

    test('heart contract fails if it silently schedules SRS', () {
      const plan = StudyActionPlan(
        action: StudyActionKind.favorite,
        item: grammar,
        declaredMutations: {
          StudyStoreMutation.favorites,
          StudyStoreMutation.srsSchedule,
        },
      );

      final result = plan.validate();
      expect(result.isValid, isFalse);
      expect(result.hasCode('study.implicit_srs_forbidden'), isTrue);
    });
  });
}
