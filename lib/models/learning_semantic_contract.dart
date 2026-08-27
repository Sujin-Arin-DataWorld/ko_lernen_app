import 'learner_level.dart';
import 'onboarding_contract_validation.dart';

enum LevelMutation {
  courseStartPoint,
  browseFilter,
  mastery,
  completedUnits,
  xp,
  rewardInventory,
  heritageProgress,
}

sealed class LearningLevelIntent {
  const LearningLevelIntent(this.level);

  final LearnerLevel level;

  Set<LevelMutation> get allowedMutations;
}

/// Changes where the learner begins, but never fabricates past completion.
final class CourseStartLevelIntent extends LearningLevelIntent {
  const CourseStartLevelIntent(super.level);

  @override
  Set<LevelMutation> get allowedMutations => const {
    LevelMutation.courseStartPoint,
  };
}

/// Changes library and scenario filters without moving course placement.
final class BrowseLevelIntent extends LearningLevelIntent {
  const BrowseLevelIntent(super.level);

  @override
  Set<LevelMutation> get allowedMutations => const {LevelMutation.browseFilter};
}

/// Boundary declaration used before a coordinator applies a level change.
final class LevelChangePlan {
  const LevelChangePlan({
    required this.intent,
    required this.declaredMutations,
  });

  final LearningLevelIntent intent;
  final Set<LevelMutation> declaredMutations;

  ContractValidationResult validate() {
    final unexpected = declaredMutations.difference(intent.allowedMutations);
    if (unexpected.isNotEmpty) {
      return ContractValidationResult([
        ContractViolation(
          code: 'level.forbidden_mutation',
          field: intent.runtimeType.toString(),
          message: 'Level intent declares forbidden mutations: $unexpected.',
        ),
      ]);
    }
    if (!declaredMutations.containsAll(intent.allowedMutations)) {
      return ContractValidationResult([
        ContractViolation(
          code: 'level.missing_expected_mutation',
          field: intent.runtimeType.toString(),
          message: 'Level intent must declare its exact state boundary.',
        ),
      ]);
    }
    return const ContractValidationResult.valid();
  }
}

/// First-run initializes both independent meanings to the same learner choice.
final class OnboardingLevelInitialization {
  const OnboardingLevelInitialization({
    required this.courseStart,
    required this.browseLevel,
  });

  factory OnboardingLevelInitialization.aligned(LearnerLevel level) {
    return OnboardingLevelInitialization(
      courseStart: CourseStartLevelIntent(level),
      browseLevel: BrowseLevelIntent(level),
    );
  }

  final CourseStartLevelIntent courseStart;
  final BrowseLevelIntent browseLevel;

  ContractValidationResult validateForFirstRun() {
    if (courseStart.level != browseLevel.level) {
      return const ContractValidationResult([
        ContractViolation(
          code: 'level.first_run_not_aligned',
          field: 'onboardingLevelInitialization',
          message: 'First-run course and browse levels must start aligned.',
        ),
      ]);
    }
    return const ContractValidationResult.valid();
  }
}

enum StudyItemType { word, grammar, sentence }

final class StudyItemSemanticRef {
  const StudyItemSemanticRef({required this.itemId, required this.type});

  final String itemId;
  final StudyItemType type;
}

enum StudyActionKind { favorite, bookmark }

enum StudyStoreMutation { favorites, reviewQueue, srsSchedule }

/// Declares the exact persistence boundary for a heart or bookmark action.
final class StudyActionPlan {
  const StudyActionPlan({
    required this.action,
    required this.item,
    required this.declaredMutations,
  });

  factory StudyActionPlan.heart(StudyItemSemanticRef item) {
    return StudyActionPlan(
      action: StudyActionKind.favorite,
      item: item,
      declaredMutations: const {StudyStoreMutation.favorites},
    );
  }

  factory StudyActionPlan.bookmark(StudyItemSemanticRef item) {
    return StudyActionPlan(
      action: StudyActionKind.bookmark,
      item: item,
      declaredMutations: const {StudyStoreMutation.reviewQueue},
    );
  }

  final StudyActionKind action;
  final StudyItemSemanticRef item;
  final Set<StudyStoreMutation> declaredMutations;

  Set<StudyStoreMutation> get _expectedMutations => switch (action) {
    StudyActionKind.favorite => const {StudyStoreMutation.favorites},
    StudyActionKind.bookmark => const {StudyStoreMutation.reviewQueue},
  };

  ContractValidationResult validate() {
    final violations = <ContractViolation>[];
    if (!isStableSemanticId(item.itemId)) {
      violations.add(
        ContractViolation(
          code: 'study.invalid_item_id',
          field: item.itemId,
          message: 'Study items need stable semantic ids.',
        ),
      );
    }
    if (declaredMutations.length != _expectedMutations.length ||
        !declaredMutations.containsAll(_expectedMutations)) {
      violations.add(
        ContractViolation(
          code: 'study.action_semantics_mismatch',
          field: action.name,
          message: 'Heart and bookmark storage semantics must remain distinct.',
        ),
      );
    }
    if (declaredMutations.contains(StudyStoreMutation.srsSchedule)) {
      violations.add(
        ContractViolation(
          code: 'study.implicit_srs_forbidden',
          field: action.name,
          message: 'Neither action may silently schedule SRS work.',
        ),
      );
    }
    return ContractValidationResult(List.unmodifiable(violations));
  }
}
