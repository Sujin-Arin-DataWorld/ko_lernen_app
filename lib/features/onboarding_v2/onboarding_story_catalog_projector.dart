import 'package:flutter/foundation.dart';

import '../../data/sori_activity_catalog.dart';
import '../../models/heritage_journey_contract.dart';
import '../../models/sori_stage_progression.dart';

/// One possible reward, projected from the existing Sori activity catalog.
///
/// The projection deliberately carries no receipt, amount, grant callback, or
/// learner-state service. It can describe what an activity contract permits,
/// but it cannot award anything.
@immutable
final class OnboardingRewardCatalogExample {
  const OnboardingRewardCatalogExample({
    required this.kind,
    required this.label,
    required this.activityIds,
  });

  final SoriRewardKind kind;
  final SoriLocalizedCopy label;
  final List<String> activityIds;
}

/// Immutable, read-only reward examples for the onboarding story.
@immutable
final class OnboardingRewardCatalogProjection {
  const OnboardingRewardCatalogProjection({
    required this.sourceCatalogEntryCount,
    required this.examples,
  });

  final int sourceCatalogEntryCount;
  final List<OnboardingRewardCatalogExample> examples;

  /// This projection is intentionally incapable of changing learner state.
  bool get mutatesLearnerState => false;
}

/// Immutable values from the approved heritage source registry.
@immutable
final class OnboardingHeritageCatalogProjection {
  const OnboardingHeritageCatalogProjection({
    required this.descriptorVersion,
    required this.displayUnit,
    required this.estateId,
    required this.officialName,
    required this.availability,
    required this.sources,
    required this.hasRuntimeAsset,
  });

  final String descriptorVersion;
  final HeritageProgressDisplayUnit displayUnit;
  final String estateId;
  final String officialName;
  final HeritageAvailability availability;
  final List<HeritageSourceReference> sources;
  final bool hasRuntimeAsset;
}

enum OnboardingCatalogProjectionAvailability { available, unavailable }

/// A fail-closed catalog projection boundary for mandatory onboarding pages.
///
/// Invalid runtime contracts produce [unavailable] with no partial values. The
/// presentation layer can therefore keep navigation available without showing
/// a reward label, heritage name, source, or asset that failed validation.
@immutable
final class OnboardingCatalogProjectionResult<T extends Object> {
  const OnboardingCatalogProjectionResult.available(T value)
    : projection = value;

  const OnboardingCatalogProjectionResult.unavailable() : projection = null;

  final T? projection;

  OnboardingCatalogProjectionAvailability get availability => projection == null
      ? OnboardingCatalogProjectionAvailability.unavailable
      : OnboardingCatalogProjectionAvailability.available;

  bool get isAvailable =>
      availability == OnboardingCatalogProjectionAvailability.available;
}

/// Converts the two existing runtime catalogs into display-only onboarding
/// values. No storage, progress, XP, quest, inventory, or reward service is
/// imported here, keeping previews structurally non-mutating.
abstract final class OnboardingStoryCatalogProjector {
  static OnboardingCatalogProjectionResult<OnboardingRewardCatalogProjection>
  projectRewards({Iterable<ActivityCatalogEntry>? catalog}) {
    try {
      final entries = List<ActivityCatalogEntry>.unmodifiable(
        catalog ?? soriActivityCatalog,
      );
      if (entries.isEmpty) {
        return const OnboardingCatalogProjectionResult.unavailable();
      }
      final examplesByKind =
          <
            SoriRewardKind,
            ({SoriLocalizedCopy label, List<String> activityIds})
          >{};

      for (final activity in entries) {
        if (activity.id.trim().isEmpty ||
            activity.reward.activityId != activity.id) {
          return const OnboardingCatalogProjectionResult.unavailable();
        }
        for (final item in activity.reward.items) {
          if (item.kind == SoriRewardKind.none) {
            continue;
          }
          if (!_hasUsableRewardLabel(item.label)) {
            return const OnboardingCatalogProjectionResult.unavailable();
          }
          final existing = examplesByKind[item.kind];
          if (existing == null) {
            examplesByKind[item.kind] = (
              label: item.label,
              activityIds: <String>[activity.id],
            );
            continue;
          }
          if (!_sameRewardLabel(existing.label, item.label)) {
            return const OnboardingCatalogProjectionResult.unavailable();
          }
          existing.activityIds.add(activity.id);
        }
      }

      if (examplesByKind.isEmpty) {
        return const OnboardingCatalogProjectionResult.unavailable();
      }
      return OnboardingCatalogProjectionResult.available(
        OnboardingRewardCatalogProjection(
          sourceCatalogEntryCount: entries.length,
          examples: List<OnboardingRewardCatalogExample>.unmodifiable(
            examplesByKind.entries.map(
              (entry) => OnboardingRewardCatalogExample(
                kind: entry.key,
                label: entry.value.label,
                activityIds: List<String>.unmodifiable(entry.value.activityIds),
              ),
            ),
          ),
        ),
      );
    } on Object {
      return const OnboardingCatalogProjectionResult.unavailable();
    }
  }

  static OnboardingCatalogProjectionResult<OnboardingHeritageCatalogProjection>
  projectIlduGotaek({HeritageJourneyDescriptor? descriptor}) {
    try {
      final source = descriptor ?? HeritageJourneyCatalog.ilduGotaekPreview;
      final validation = source.validate();
      if (!validation.isValid) {
        return const OnboardingCatalogProjectionResult.unavailable();
      }
      final chapters = source.chapters
          .where(
            (candidate) =>
                candidate.estateId == HeritageJourneyCatalog.ilduGotaekEstateId,
          )
          .toList(growable: false);
      if (chapters.length != 1) {
        return const OnboardingCatalogProjectionResult.unavailable();
      }
      final chapter = chapters.single;
      if (source.displayUnit != HeritageProgressDisplayUnit.previewOnly ||
          chapter.availability != HeritageAvailability.preview ||
          chapter.assetAuthority.hasRuntimeAsset) {
        return const OnboardingCatalogProjectionResult.unavailable();
      }

      return OnboardingCatalogProjectionResult.available(
        OnboardingHeritageCatalogProjection(
          descriptorVersion: source.descriptorVersion,
          displayUnit: source.displayUnit,
          estateId: chapter.estateId,
          officialName: chapter.officialName,
          availability: chapter.availability,
          sources: List<HeritageSourceReference>.unmodifiable(chapter.sources),
          hasRuntimeAsset: chapter.assetAuthority.hasRuntimeAsset,
        ),
      );
    } on Object {
      return const OnboardingCatalogProjectionResult.unavailable();
    }
  }

  static bool _hasUsableRewardLabel(SoriLocalizedCopy label) =>
      label.key != null &&
      label.de.trim().isNotEmpty &&
      label.en.trim().isNotEmpty;

  static bool _sameRewardLabel(
    SoriLocalizedCopy left,
    SoriLocalizedCopy right,
  ) => left.key == right.key && left.de == right.de && left.en == right.en;
}
