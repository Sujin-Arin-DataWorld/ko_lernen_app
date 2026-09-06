import '../models/hanok_growth.dart';
import '../models/ildu_world_manifest.dart';
import '../models/personal_hanok.dart';

/// Presentation-only state for the Ildu map.
///
/// This adapter never writes course state and never treats onboarding level
/// selection as ownership. The canonical path consumes verified productive
/// evidence from [HanokExperienceProjection]. The legacy bridge is deliberately
/// fail-closed and reads only completed, non-bypassed course units already
/// exposed by [PersonalHanokProjection.competence].
class IlDuWorldProjection {
  final IlDuWorldEra era;
  final bool hasVerifiedEvidence;
  final Set<String> earnedGrantIds;

  const IlDuWorldProjection({
    required this.era,
    required this.hasVerifiedEvidence,
    this.earnedGrantIds = const <String>{},
  });

  bool isAvailable(IlDuWorldEra requiredEra) =>
      hasVerifiedEvidence && era.rank >= requiredEra.rank;
}

class IlDuWorldProjectionAdapter {
  const IlDuWorldProjectionAdapter();

  IlDuWorldProjection fromExperience(HanokExperienceProjection projection) {
    return IlDuWorldProjection(
      era: switch (projection.currentEra) {
        HanokGrowthEra.build => IlDuWorldEra.a1,
        HanokGrowthEra.live => IlDuWorldEra.a2,
        HanokGrowthEra.connect => IlDuWorldEra.b1,
        HanokGrowthEra.share => IlDuWorldEra.b2,
        HanokGrowthEra.care => IlDuWorldEra.c1,
        HanokGrowthEra.transmit => IlDuWorldEra.c2,
      },
      hasVerifiedEvidence: projection.verifiedCanDoSegmentIds.isNotEmpty,
      earnedGrantIds: projection.earnedGrantIds,
    );
  }

  /// Temporary compatibility bridge until the reviewed productive-assessment
  /// catalog is promoted. Placement bypasses and legacy pack ratios are never
  /// consulted, so a chosen starting level cannot reveal a building.
  IlDuWorldProjection fromPersonalHanok(PersonalHanokProjection projection) {
    final competence = projection.competence;
    if (competence == null || !competence.hasVerifiedStructure) {
      return const IlDuWorldProjection(
        era: IlDuWorldEra.a1,
        hasVerifiedEvidence: false,
      );
    }
    final era = competence.b2Ratio > 0
        ? IlDuWorldEra.b2
        : competence.b1Ratio > 0
        ? IlDuWorldEra.b1
        : competence.a2Ratio > 0
        ? IlDuWorldEra.a2
        : IlDuWorldEra.a1;
    return IlDuWorldProjection(era: era, hasVerifiedEvidence: true);
  }
}
