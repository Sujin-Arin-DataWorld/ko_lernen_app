import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/learner_level.dart';

void main() {
  group('GuideTopicCatalog', () {
    test('declares exactly the six stable guide topics', () {
      expect(GuideTopicCatalog.validate().isValid, isTrue);
      expect(GuideTopicCatalog.all, hasLength(6));
      expect(
        GuideTopicCatalog.all.map((topic) => topic.id).toSet(),
        GuideTopicId.values.toSet(),
      );
      expect(
        GuideTopicCatalog.all.map((topic) => topic.analyticsSurface).toSet(),
        GuideAnalyticsSurface.values.toSet(),
      );
    });

    test('publishes the unified study library as a live destination', () {
      final topic = GuideTopicCatalog.all.singleWhere(
        (item) => item.id == GuideTopicId.cardsAndMemory,
      );

      expect(topic.availability, FeatureAvailability.live);
      expect(topic.featureFlag, GuideFeatureFlag.unifiedStudyLibrary);
      expect(topic.completionMode, GuideCompletionMode.destinationOpened);
      expect(
        (topic.destination as StudyLibraryDestination).semanticId,
        StudyLibrarySemanticId.myWords,
      );
    });

    test(
      'book permissions are destination requirements, not route strings',
      () {
        final topic = GuideTopicCatalog.all.singleWhere(
          (item) => item.id == GuideTopicId.myBook,
        );

        expect(topic.destination, isA<StudyLibraryDestination>());
        expect(topic.requiredPermissions, {GuidePermissionRequirement.camera});
        expect(topic.requiredConsents, {
          GuideConsentRequirement.privacyAccepted,
        });
      },
    );

    test('start and settings topics open real settings instead of looping', () {
      for (final id in [
        GuideTopicId.personalizedStart,
        GuideTopicId.settings,
      ]) {
        final topic = GuideTopicCatalog.all.singleWhere(
          (item) => item.id == id,
        );
        expect(
          topic.destination,
          const SettingsSectionDestination(SettingsSectionTarget.courseStart),
        );
      }
    });
  });

  group('GuideModuleCatalog', () {
    test('declares typed actions for all six topics', () {
      expect(GuideModuleCatalog.validate().isValid, isTrue);
      expect(
        GuideModuleCatalog.byTopic.keys.toSet(),
        GuideTopicId.values.toSet(),
      );

      for (final topic in GuideTopicCatalog.all) {
        final actions = GuideModuleCatalog.byTopic[topic.id]!;
        expect(actions, isNotEmpty, reason: topic.id.stableId);
        expect(
          actions.where((action) => action.completesTopic),
          hasLength(1),
          reason: topic.id.stableId,
        );
        expect(
          _destinationFingerprint(
            actions.singleWhere((action) => action.completesTopic).destination,
          ),
          _destinationFingerprint(topic.destination),
          reason: topic.id.stableId,
        );
      }
    });

    test(
      'keeps runtime-stocked scenario shelves out of the static catalog',
      () {
        final destinations = GuideModuleCatalog.byTopic.values
            .expand((actions) => actions)
            .map((action) => action.destination);

        expect(destinations.whereType<ScenarioBrowseDestination>(), isEmpty);
        expect(
          destinations.whereType<SoriStageTabDestination>().any(
            (destination) => destination.tab == SoriStageTabTarget.learn,
          ),
          isTrue,
        );
      },
    );

    test('book capture requirements stay on its action only', () {
      final actions = GuideModuleCatalog.byTopic[GuideTopicId.myBook]!;
      final capture = actions.singleWhere(
        (action) => action.id == GuideModuleActionId.captureTextbook,
      );
      final library = actions.singleWhere(
        (action) => action.id == GuideModuleActionId.studyLibrary,
      );

      expect(capture.requiredPermissions, {GuidePermissionRequirement.camera});
      expect(capture.requiredConsents, {
        GuideConsentRequirement.privacyAccepted,
      });
      expect(library.requiredPermissions, isEmpty);
      expect(library.requiredConsents, isEmpty);
    });
  });

  test('scenario browse destination preserves level and semantic shelf', () {
    const destination = ScenarioBrowseDestination(
      level: LearnerLevel.b2,
      shelfId: 'b2_friends',
    );

    expect(destination.level, LearnerLevel.b2);
    expect(destination.shelfId, 'b2_friends');
  });

  test('scenario browse destination rejects a mismatched level prefix', () {
    const spec = GuideTopicSpec(
      id: GuideTopicId.learn,
      localizationKey: 'guideTopicLearn',
      destination: ScenarioBrowseDestination(
        level: LearnerLevel.a1,
        shelfId: 'b2_friends',
      ),
      availability: FeatureAvailability.live,
      requiredConsents: {},
      requiredPermissions: {},
      surfaces: {GuideSurface.guideHub},
      completionMode: GuideCompletionMode.destinationOpened,
      analyticsSurface: GuideAnalyticsSurface.learn,
    );

    expect(
      spec.validate().hasCode('guide.scenario_shelf_level_mismatch'),
      isTrue,
    );
  });

  group('RewardPreviewSpec', () {
    test('accepts a read-only catalog projection', () {
      const spec = RewardPreviewSpec(
        activityId: 'vocab_packs',
        localizationKey: 'guideRewardPreviewExample',
        possibleRewards: {
          RewardPreviewKind.xp,
          RewardPreviewKind.quest,
          RewardPreviewKind.stamp,
        },
      );

      expect(spec.validate().isValid, isTrue);
    });

    test('fails when the activity is absent from the production catalog', () {
      const spec = RewardPreviewSpec(
        activityId: 'scenario.practice',
        localizationKey: 'guideRewardPreviewExample',
        possibleRewards: {RewardPreviewKind.xp},
      );

      final result = spec.validate();
      expect(result.isValid, isFalse);
      expect(result.hasCode('reward_preview.unknown_activity'), isTrue);
    });

    test('fails when declared rewards differ from the catalog contract', () {
      const spec = RewardPreviewSpec(
        activityId: 'vocab_packs',
        localizationKey: 'guideRewardPreviewExample',
        possibleRewards: {RewardPreviewKind.xp, RewardPreviewKind.stamp},
      );

      final result = spec.validate();
      expect(result.isValid, isFalse);
      expect(result.hasCode('reward_preview.catalog_mismatch'), isTrue);
    });

    test('fails when a preview declares learner-state mutations', () {
      const spec = RewardPreviewSpec(
        activityId: 'vocab_packs',
        localizationKey: 'guideRewardPreviewExample',
        possibleRewards: {
          RewardPreviewKind.xp,
          RewardPreviewKind.quest,
          RewardPreviewKind.stamp,
        },
        declaredMutations: {
          RewardPreviewMutation.xp,
          RewardPreviewMutation.heritageProgress,
        },
      );

      final result = spec.validate();
      expect(result.isValid, isFalse);
      expect(result.hasCode('reward_preview.mutation_forbidden'), isTrue);
    });
  });
}

String _destinationFingerprint(GuideDestination destination) =>
    switch (destination) {
      SoriStageTabDestination(:final tab) => 'stage:${tab.name}',
      SettingsSectionDestination(:final section) => 'settings:${section.name}',
      HangulTargetDestination(:final target) => 'hangul:${target.name}',
      ScenarioBrowseDestination(:final level, :final shelfId) =>
        'scenario:${level.code}:$shelfId',
      StudyLibraryDestination(:final semanticId) =>
        'library:${semanticId.name}',
      HeritageDestination(:final estateId) => 'heritage:$estateId',
    };
