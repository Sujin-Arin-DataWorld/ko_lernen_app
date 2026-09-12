import '../models/hanok_growth.dart';
import '../models/ildu_world_manifest.dart';

/// Presentation-only state for the Ildu map.
///
/// This adapter never writes course state and never treats onboarding level
/// selection as ownership. The canonical path consumes verified productive
/// evidence from [HanokExperienceProjection].
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
}
