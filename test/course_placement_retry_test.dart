import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Models a native commit followed by a lost reply and unavailable reload.
/// SharedPreferences itself supplies the real optimistic application cache.
class _PlacementPlatform extends SharedPreferencesStorePlatform {
  final values = <String, Object>{'kl_consent_accepted': true};
  bool loseCanonicalReply = false;
  bool commitBeforeLosingReply = true;
  bool unavailable = false;
  int canonicalWrites = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    if (unavailable) {
      throw StateError('Native preferences unavailable');
    }
    return values.map((key, value) => MapEntry('flutter.$key', value));
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (unavailable) {
      return false;
    }
    final name = key.substring('flutter.'.length);
    if (name == Storage.courseMasterySnapshotPreferenceKey) {
      canonicalWrites++;
      if (loseCanonicalReply) {
        loseCanonicalReply = false;
        if (commitBeforeLosingReply) {
          values[name] = value;
        }
        unavailable = true;
        throw StateError('Native commit reply lost');
      }
    }
    values[name] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (unavailable) {
      return false;
    }
    values.remove(key.substring('flutter.'.length));
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late _PlacementPlatform platform;
  late CourseMasteryService service;
  late CourseProgressService progress;
  late StorageOnboardingCommitGateway gateway;
  late CurriculumCatalog catalog;

  setUpAll(() async {
    catalog = await CurriculumCatalog.load();
  });

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = _PlacementPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    service = CourseMasteryService(catalog);
    progress = CourseProgressService(() async => service);
    gateway = StorageOnboardingCommitGateway(courseProgress: progress);
  });

  tearDown(() {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  Future<void> failPlacement() async {
    platform.loseCanonicalReply = true;
    await expectLater(
      gateway.initializePlacement(LearnerLevel.a1),
      throwsA(isA<PreferenceOutcomeUnknownException>()),
    );
  }

  for (final committed in [false, true]) {
    test(
      'gateway read retry confirms durable placement; committed=$committed',
      () async {
        platform.commitBeforeLosingReply = committed;
        await failPlacement();
        expect(
          service.readForReconciliation,
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        await expectLater(
          gateway.readPlacement(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        final beforeRead = Map<String, Object>.of(platform.values);
        platform.unavailable = false;

        final recovered = await gateway.readPlacement();

        expect(
          recovered.canonicalPlacementLevel,
          committed ? LearnerLevel.a1 : null,
        );
        expect(recovered.placementLevel, committed ? LearnerLevel.a1 : null);
        expect(
          platform.values,
          beforeRead,
          reason:
              'Read recovery must not synthesize, migrate, or rewrite course state.',
        );
        expect(platform.canonicalWrites, 1);
      },
    );
  }

  test('ordinary empty placement read does not load the catalog', () async {
    final emptyGateway = StorageOnboardingCommitGateway(
      courseProgress: CourseProgressService(
        () async => throw StateError('Unexpected catalog loading'),
      ),
    );
    final before = Map<String, Object>.of(platform.values);
    final result = await emptyGateway.readPlacement();
    expect(result.placementLevel, isNull);
    expect(result.courseGeneration, isEmpty);
    expect(platform.values, before);
  });

  test(
    'queued display retry confirms evidence without a course write',
    () async {
      await failPlacement();
      await expectLater(
        progress.readForDisplay(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      final before = Map<String, Object>.of(platform.values);
      platform.unavailable = false;
      final recovered = await progress.readForDisplay();
      expect(recovered?.currentCourseUnitId, 'a1_01_greetings_hangul');
      expect(platform.values, before);
      expect(platform.canonicalWrites, 1);
    },
  );

  test(
    'placement repair confirms canonical before its nonempty read',
    () async {
      await failPlacement();
      final canonical =
          platform.values[Storage.courseMasterySnapshotPreferenceKey]!
              as String;
      platform.unavailable = false;
      await gateway.initializePlacement(
        LearnerLevel.a1,
        expectedGeneration: canonical,
      );
      final result = await gateway.readPlacement();
      expect(result.placementLevel, LearnerLevel.a1);
      expect(result.courseGeneration, canonical);
      expect(platform.canonicalWrites, 1);
    },
  );

  test(
    'real coordinator commit retry recovers its placement preflight',
    () async {
      final repository = SharedPreferencesOnboardingJourneyRepository();
      await repository.save(
        OnboardingJourneyState.initial(DateTime.utc(2026, 9, 10)).copyWith(
          phase: OnboardingPhase.companion,
          purposeDraft: OnboardingPurpose.dailyTravel,
          levelDraft: LearnerLevel.a1,
          companionDraft: OnboardingCompanion.taego,
        ),
      );
      final coordinator = FirstRunCoordinator(
        repository: repository,
        legacyStateReader: const StorageLegacyOnboardingStateReader(),
        commitGateway: gateway,
      );
      platform.loseCanonicalReply = true;
      await expectLater(
        coordinator.commitFromCompanion(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(
        (await repository.load())?.commitStage,
        OnboardingCommitStage.motivationSaved,
      );
      platform.unavailable = false;

      final completed = await coordinator.commitFromCompanion();

      expect(completed.phase, OnboardingPhase.gate);
      expect(completed.commitStage, OnboardingCommitStage.completed);
      expect(Storage.hasCompletedOnboarding, isTrue);
      expect((await gateway.readPlacement()).placementLevel, LearnerLevel.a1);
      expect(
        platform.canonicalWrites,
        1,
        reason:
            'Retry should verify the already durable placement, not replay it.',
      );
      final durable =
          jsonDecode(
                platform.values[Storage.courseMasterySnapshotPreferenceKey]!
                    as String,
              )
              as Map;
      expect(durable['evidence'], isEmpty);
      expect(durable['completedUnitIds'], isEmpty);
    },
  );
}
