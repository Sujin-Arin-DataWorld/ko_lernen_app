import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_story_catalog_projector.dart';
import 'package:ko_lernen_app/models/heritage_journey_contract.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';

void main() {
  group('OnboardingStoryCatalogProjector rewards', () {
    test('derives examples from the immutable activity catalog', () {
      final originalEntries = List<ActivityCatalogEntry>.of(
        soriActivityCatalog,
      );
      final originalContracts = [
        for (final entry in soriActivityCatalog) entry.reward,
      ];

      final result = OnboardingStoryCatalogProjector.projectRewards();
      final projection = result.projection!;

      expect(result.isAvailable, isTrue);
      expect(projection.sourceCatalogEntryCount, soriActivityCatalog.length);
      expect(projection.examples.map((example) => example.kind).toSet(), {
        SoriRewardKind.xp,
        SoriRewardKind.hanokProgress,
        SoriRewardKind.questProgress,
        SoriRewardKind.stamp,
        SoriRewardKind.personalBest,
      });
      expect(
        projection.examples.any(
          (example) => example.kind == SoriRewardKind.bojagi,
        ),
        isFalse,
        reason: 'Undeclared rewards must never appear in onboarding.',
      );
      expect(projection.mutatesLearnerState, isFalse);

      for (var index = 0; index < originalEntries.length; index += 1) {
        expect(
          identical(soriActivityCatalog[index], originalEntries[index]),
          isTrue,
        );
        expect(
          identical(
            soriActivityCatalog[index].reward,
            originalContracts[index],
          ),
          isTrue,
        );
      }
      expect(
        () => projection.examples.add(projection.examples.first),
        throwsUnsupportedError,
      );
      expect(
        () => projection.examples.first.activityIds.add('forbidden-write'),
        throwsUnsupportedError,
      );
    });

    test('fails closed for inconsistent labels of one reward kind', () {
      const canonical = RewardContractItem(
        kind: SoriRewardKind.xp,
        label: SoriLocalizedCopy(
          de: 'Lern-XP',
          en: 'Learning XP',
          key: SoriCopyKey.rewardXp,
        ),
      );
      const inconsistent = RewardContractItem(
        kind: SoriRewardKind.xp,
        label: SoriLocalizedCopy(
          de: 'Nicht belegte Punkte',
          en: 'Unverified points',
          key: SoriCopyKey.rewardXp,
        ),
      );

      final result = OnboardingStoryCatalogProjector.projectRewards(
        catalog: [
          _rewardActivity('reward-source-a', canonical),
          _rewardActivity('reward-source-b', inconsistent),
        ],
      );

      expect(result.isAvailable, isFalse);
      expect(result.projection, isNull);
    });
  });

  group('OnboardingStoryCatalogProjector Ildu Gotaek', () {
    test('consumes the registry as an asset-free source-backed preview', () {
      final descriptor = HeritageJourneyCatalog.ilduGotaekPreview;
      final result = OnboardingStoryCatalogProjector.projectIlduGotaek();
      final projection = result.projection!;

      expect(result.isAvailable, isTrue);
      expect(projection.descriptorVersion, descriptor.descriptorVersion);
      expect(projection.displayUnit, HeritageProgressDisplayUnit.previewOnly);
      expect(projection.estateId, HeritageJourneyCatalog.ilduGotaekEstateId);
      expect(projection.officialName, descriptor.chapters.single.officialName);
      expect(projection.availability, HeritageAvailability.preview);
      expect(projection.hasRuntimeAsset, isFalse);
      expect(projection.sources, hasLength(2));
      expect(projection.sources.map((source) => source.url.toString()), [
        'https://heritage.go.kr/heri/cul/culSelectDetail.do?ccbaAsno=0001860000000&ccbaCpno=1483801860000&ccbaCtcd=38&ccbaKdcd=18&pageNo=1_1_1_0',
        'https://korean.visitkorea.or.kr/detail/rem_detail.do?cotid=15a9cb58-9217-49d5-b21b-a1457c14918c',
      ]);
      expect(
        projection.sources.every(
          (source) =>
              source.institution.isNotEmpty &&
              source.sourceYear > 0 &&
              source.title.isNotEmpty &&
              source.author.isNotEmpty &&
              source.license.authority == HeritageUseAuthority.citationOnly,
        ),
        isTrue,
      );
      expect(
        () => projection.sources.add(projection.sources.first),
        throwsUnsupportedError,
      );
    });

    test('fails closed for an invalid descriptor', () {
      final result = OnboardingStoryCatalogProjector.projectIlduGotaek(
        descriptor: _invalidHeritageDescriptor(),
      );

      expect(result.isAvailable, isFalse);
      expect(result.projection, isNull);
    });

    test('fails closed when the Ildu chapter is missing', () {
      final result = OnboardingStoryCatalogProjector.projectIlduGotaek(
        descriptor: _heritageDescriptorWithoutIldu(),
      );

      expect(result.isAvailable, isFalse);
      expect(result.projection, isNull);
    });

    test('fails closed for an asset-authority violation', () {
      final result = OnboardingStoryCatalogProjector.projectIlduGotaek(
        descriptor: _heritageDescriptorWithPendingAsset(),
      );

      expect(result.isAvailable, isFalse);
      expect(result.projection, isNull);
    });
  });
}

ActivityCatalogEntry _rewardActivity(String id, RewardContractItem reward) =>
    ActivityCatalogEntry(
      id: id,
      tab: SoriStageTab.games,
      title: SoriLocalizedCopy(de: id, en: id),
      description: SoriLocalizedCopy(de: id, en: id),
      route: '/test-reward',
      minutes: 1,
      colorRole: SoriActivityColorRole.reward,
      iconName: 'test',
      reward: RewardContract(
        activityId: id,
        condition: const SoriLocalizedCopy(
          de: 'Beim Abschluss',
          en: 'On completion',
          key: SoriCopyKey.finishSession,
        ),
        items: [reward],
      ),
    );

EstateChapter _heritageChapter({
  String estateId = HeritageJourneyCatalog.ilduGotaekEstateId,
  HeritageAssetAuthority assetAuthority = const HeritageAssetAuthority.none(),
}) {
  final approved = HeritageJourneyCatalog.ilduGotaekPreview.chapters.single;
  return EstateChapter(
    estateId: estateId,
    officialName: approved.officialName,
    availability: HeritageAvailability.preview,
    sources: approved.sources,
    assetAuthority: assetAuthority,
    learningBeatBinding: approved.learningBeatBinding,
    progress: approved.progress,
    cultureStoryLocalizationKey: approved.cultureStoryLocalizationKey,
  );
}

HeritageJourneyDescriptor _invalidHeritageDescriptor() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'not a stable descriptor version',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [_heritageChapter()],
    );

HeritageJourneyDescriptor _heritageDescriptorWithoutIldu() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'other-estate-preview-v1',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [_heritageChapter(estateId: 'other-estate')],
    );

HeritageJourneyDescriptor _heritageDescriptorWithPendingAsset() =>
    HeritageJourneyDescriptor(
      descriptorVersion: 'ildu-pending-asset-v1',
      displayUnit: HeritageProgressDisplayUnit.previewOnly,
      totalDisplayUnits: null,
      chapters: [
        _heritageChapter(
          assetAuthority: const HeritageAssetAuthority(
            status: HeritageAssetReviewStatus.pendingReview,
            runtimeAssetPath: 'assets/pending_review/ildu.png',
            authorityVersion: null,
            approvedBy: null,
            approvedAtIso: null,
          ),
        ),
      ],
    );
