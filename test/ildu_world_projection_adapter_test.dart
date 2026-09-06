import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/services/ildu_world_projection_adapter.dart';

void main() {
  const adapter = IlDuWorldProjectionAdapter();

  test('keeps every estate era available without productive evidence', () {
    final result = adapter.fromExperience(_projection());

    expect(result.hasVerifiedEvidence, isFalse);
    for (final era in IlDuWorldEra.values) {
      expect(result.isAvailable(era), isTrue);
      expect(result.isEarned(era), isFalse);
    }
  });

  test('maps all six canonical growth eras from verified evidence', () {
    const cases = <HanokGrowthEra, IlDuWorldEra>{
      HanokGrowthEra.build: IlDuWorldEra.a1,
      HanokGrowthEra.live: IlDuWorldEra.a2,
      HanokGrowthEra.connect: IlDuWorldEra.b1,
      HanokGrowthEra.share: IlDuWorldEra.b2,
      HanokGrowthEra.care: IlDuWorldEra.c1,
      HanokGrowthEra.transmit: IlDuWorldEra.c2,
    };

    for (final entry in cases.entries) {
      final result = adapter.fromExperience(
        _projection(era: entry.key, verified: const {'can-do-verified'}),
      );
      expect(result.era, entry.value);
      expect(result.hasVerifiedEvidence, isTrue);
      expect(result.isAvailable(entry.value), isTrue);
      expect(result.isEarned(entry.value), isTrue);
      for (final era in IlDuWorldEra.values.where(
        (era) => era.rank > entry.value.rank,
      )) {
        expect(result.isEarned(era), isFalse);
      }
    }
  });
}

HanokExperienceProjection _projection({
  HanokGrowthEra era = HanokGrowthEra.build,
  Set<String> verified = const {},
}) => HanokExperienceProjection(
  verifiedCanDoSegmentIds: verified,
  reassessmentEligibleSegmentIds: const {},
  earnedGrants: const [],
  a1ConstructionStep: 0,
  currentEra: era,
  openedVenues: const {},
  availableDesignOptions: const {},
  activeLoadout: const {},
  weatheringTier: HanokWeatheringTier.fresh,
  nextGrant: null,
  trackProgress: const [],
  roomLayouts: HanokRoomLayoutProjection(active: const {}, dormant: const {}),
);
