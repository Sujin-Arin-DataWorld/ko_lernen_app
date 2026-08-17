import '../models/course_mastery.dart';
import '../models/hanok_growth.dart';
import 'course_segment_catalog.dart';
import 'hanok_experience_projector.dart';
import 'hanok_grant_catalog.dart';
import 'hanok_state_service.dart';
import 'productive_assessment_service.dart';
import 'storage_service.dart';

/// Idempotent, presentation-only Living Hanok V1 cutover.
///
/// State is committed first, obsolete reveal ledgers are removed second, and
/// the cutover marker is written last. An interruption at either boundary can
/// safely rerun from CourseMastery without importing legacy progress.
final class HanokCutoverService {
  const HanokCutoverService({
    this.stateService = const HanokStateService(),
    this.projector = const HanokExperienceProjector(),
    this.afterStateSavedForTesting,
    this.afterLegacyClearedForTesting,
  });

  static const String markerValue = '2';

  final HanokStateService stateService;
  final HanokExperienceProjector projector;
  final Future<void> Function()? afterStateSavedForTesting;
  final Future<void> Function()? afterLegacyClearedForTesting;

  Future<HanokState> ensureCutover({
    required CourseMasterySnapshot courseMastery,
    required CourseSegmentCatalog segmentCatalog,
    required ProductiveAssessmentCatalog assessmentCatalog,
    required HanokGrantCatalog grantCatalog,
    required DateTime asOf,
  }) async {
    final existing = stateService.load();
    if (Storage.hanokCutoverRawValue == markerValue) {
      if (existing == null) {
        throw const FormatException(
          'Hanok cutover marker exists without canonical state.',
        );
      }
      return existing;
    }

    final base =
        existing ??
        HanokState.fresh(manifestVersion: grantCatalog.manifestVersion);
    final projection = projector.project(
      courseMastery: courseMastery,
      segmentCatalog: segmentCatalog,
      assessmentCatalog: assessmentCatalog,
      grantCatalog: grantCatalog,
      state: base,
      asOf: asOf,
    );
    final baselineRevealIds = <String>{
      ...base.seenRevealIds,
      for (final grant in projection.earnedGrants) ...grant.revealAssetIds,
    };
    final canonical = base.copyWith(
      manifestVersion: grantCatalog.manifestVersion,
      cutoverVersion: HanokState.currentCutoverVersion,
      seenRevealIds: baselineRevealIds,
    );
    final generation = Storage.hanokStateRawJson;
    await stateService.save(canonical, expectedGeneration: generation);
    await afterStateSavedForTesting?.call();
    await Storage.clearLegacyHanokPresentationState();
    await afterLegacyClearedForTesting?.call();
    await Storage.setHanokCutoverRawValueStrict(markerValue);
    return canonical;
  }
}
