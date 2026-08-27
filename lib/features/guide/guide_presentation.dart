import 'package:flutter/foundation.dart';

import '../../models/guide_contract.dart';

@immutable
final class GuideTopicViewModel {
  const GuideTopicViewModel({
    required this.spec,
    required this.title,
    required this.description,
    required this.availabilityLabel,
    required this.actionLabel,
    required this.isCompleted,
  });

  final GuideTopicSpec spec;
  final String title;
  final String description;
  final String availabilityLabel;
  final String actionLabel;
  final bool isCompleted;
}

@immutable
final class GuideModuleStepViewModel {
  const GuideModuleStepViewModel({required this.number, required this.body});

  final int number;
  final String body;
}

@immutable
final class GuideModuleActionViewModel {
  const GuideModuleActionViewModel({required this.spec, required this.label});

  final GuideModuleActionSpec spec;
  final String label;
}

enum GuideScenarioCategorySectionStatus { loading, ready, empty, failed }

@immutable
final class GuideScenarioCategoryViewModel {
  const GuideScenarioCategoryViewModel({
    required this.destination,
    required this.label,
    required this.countLabel,
  });

  final ScenarioBrowseDestination destination;
  final String label;
  final String countLabel;
}

@immutable
final class GuideScenarioCategorySectionViewModel {
  const GuideScenarioCategorySectionViewModel({
    required this.status,
    required this.title,
    required this.statusLabel,
    required this.categories,
    this.summary,
  });

  final GuideScenarioCategorySectionStatus status;
  final String title;

  /// Localized loading, empty, or failure copy. Ready sections use this as an
  /// assistive label only; their visible stock summary comes from [summary].
  final String statusLabel;
  final String? summary;
  final List<GuideScenarioCategoryViewModel> categories;
}

@immutable
final class GuideTopicModuleViewModel {
  const GuideTopicModuleViewModel({
    required this.topic,
    required this.appBarTitle,
    required this.eyebrow,
    required this.stepsTitle,
    required this.actionsTitle,
    required this.passiveNotice,
    required this.steps,
    required this.actions,
    this.scenarioCategories,
  });

  final GuideTopicViewModel topic;
  final String appBarTitle;
  final String eyebrow;
  final String stepsTitle;
  final String actionsTitle;

  /// Explicitly tells learners that viewing this module is non-destructive.
  final String passiveNotice;
  final List<GuideModuleStepViewModel> steps;
  final List<GuideModuleActionViewModel> actions;

  /// Runtime-stocked scenario shelves. Only the Learn module supplies this
  /// optional section; static guide contracts never guess a shelf or count.
  final GuideScenarioCategorySectionViewModel? scenarioCategories;
}

@immutable
final class GuideHubCopy {
  const GuideHubCopy({
    required this.appBarTitle,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.completedLabel,
  });

  final String appBarTitle;
  final String eyebrow;
  final String title;
  final String description;
  final String completedLabel;
}

@immutable
final class TodayGuideChecklistCopy {
  const TodayGuideChecklistCopy({
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.completedLabel,
    required this.openGuideLabel,
    required this.dismissLabel,
  });

  final String title;
  final String description;
  final String progressLabel;
  final String completedLabel;
  final String openGuideLabel;
  final String dismissLabel;
}

typedef GuideTopicCallback = void Function(GuideTopicSpec topic);
typedef GuideModuleActionCallback =
    void Function(GuideModuleActionViewModel action);
typedef GuideScenarioCategoryCallback =
    void Function(GuideScenarioCategoryViewModel category);

/// Resolves the only callback that a topic may invoke.
///
/// Non-live features are inert by default. Callers must provide an explicit
/// handler to offer a preview or unavailable-state explanation.
GuideTopicCallback? guideTopicActivation({
  required GuideTopicSpec topic,
  required GuideTopicCallback onLiveTopicRequested,
  GuideTopicCallback? onNonLiveTopicRequested,
}) => switch (topic.availability) {
  FeatureAvailability.live => onLiveTopicRequested,
  FeatureAvailability.preview ||
  FeatureAvailability.comingSoon ||
  FeatureAvailability.unavailable => onNonLiveTopicRequested,
};
