import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/account/reconciliation_errors.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'fresh install does not restore the implicit Taego fallback as a draft',
    () async {
      final snapshot = await const StorageLegacyOnboardingStateReader().read();

      expect(Storage.selectedCompanion, 'tiger');
      expect(Storage.explicitSelectedCompanion, isNull);
      expect(snapshot.companion, isNull);
    },
  );

  test(
    'a real legacy companion remains available as a migration draft',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_preferred_mascot': 'magpie'});
      await Storage.init();

      final snapshot = await const StorageLegacyOnboardingStateReader().read();

      expect(snapshot.companion, OnboardingCompanion.joy);
    },
  );

  test(
    'production snapshot detects and repairs a partial companion write',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        Storage.selectedCompanionPreferenceKey: 'tiger',
        Storage.companionVisiblePreferenceKey: false,
        'kl_preferred_mascot': 'none',
      });
      await Storage.init();
      var reloads = 0;
      final gateway = StorageOnboardingCommitGateway(
        onCompanionSaved: (_) async => reloads++,
      );

      final partial = await gateway.readCompanionCommitSnapshot();

      expect(partial.companion, OnboardingCompanion.taego);
      expect(partial.identityExplicitlyStored, isTrue);
      expect(partial.visible, isFalse);
      expect(partial.legacyMirror, isNull);
      expect(partial.matches(OnboardingCompanion.taego), isFalse);

      await gateway.saveCompanion(OnboardingCompanion.taego);
      final repaired = await gateway.readCompanionCommitSnapshot();

      expect(repaired.matches(OnboardingCompanion.taego), isTrue);
      expect(Storage.companionVisible, isTrue);
      expect(Storage.preferredMascot, 'tiger');
      expect(reloads, 1);
    },
  );

  test('purpose read-back requires the second-write commit marker', () async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_motivation': 'daily'});
    await Storage.init();
    final gateway = StorageOnboardingCommitGateway();

    expect(await gateway.readPurpose(), isNull);

    await gateway.savePurpose(OnboardingPurpose.dailyTravel);
    Storage.resetForTesting();
    await Storage.init();

    expect(await gateway.readPurpose(), OnboardingPurpose.dailyTravel);
    expect(Storage.motivationAsked, isTrue);
  });

  test(
    'placement read-back rejects scalar mirrors without a canonical graph',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        Storage.placementLevelPreferenceKey: 'b1',
        Storage.courseUnitPreferenceKey: 'orphaned-unit',
        Storage.browseLevelPreferenceKey: 'b1',
      });
      await Storage.init();
      final gateway = StorageOnboardingCommitGateway();

      final snapshot = await gateway.readPlacement();

      expect(snapshot.placementLevel, isNull);
      expect(snapshot.browseLevel, LearnerLevel.b1);
      expect(snapshot.hasCourseHistory, isFalse);
    },
  );

  test(
    'placement read-back promotes legacy placement and resets retired progress',
    () async {
      const completedUnitId = 'a1_01_greetings_hangul';
      const currentUnitId = 'a1_02_self_intro_identity';
      final legacy = jsonEncode({
        'version': 1,
        'placementLevel': 'a1',
        'currentCourseUnitId': currentUnitId,
        'completedUnitIds': [completedUnitId],
      });
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'b2',
        Storage.legacyCourseMasteryPreferenceKey: legacy,
      });
      await Storage.init();
      final gateway = StorageOnboardingCommitGateway();

      final snapshot = await gateway.readPlacement();
      // Prove the graph is durable rather than satisfied only by Storage's
      // optimistic in-memory cache.
      Storage.resetForTesting();
      await Storage.init();
      final restartedGateway = StorageOnboardingCommitGateway(
        courseProgress: CourseProgressService.app(),
      );
      final restartedSnapshot = await restartedGateway.readPlacement();
      final canonical = jsonDecode(Storage.courseMasterySnapshotRawJson) as Map;

      expect(snapshot.placementLevel, LearnerLevel.a1);
      expect(snapshot.courseGeneration, isNotEmpty);
      expect(snapshot.hasCourseHistory, isFalse);
      expect(restartedSnapshot.placementLevel, LearnerLevel.a1);
      expect(restartedSnapshot.hasCourseHistory, isFalse);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
      expect(Storage.courseUnitId, completedUnitId);
      expect(canonical['curriculumGeneration'], 'canonical_120_v1');
      expect(canonical['completedUnitIds'], isEmpty);
      expect(Storage.legacyCourseMasteryRawJson, legacy);
      expect(Storage.userLevelCode, 'b2');
    },
  );

  test(
    'placement verification captures one generation behind queued writes',
    () async {
      final progress = CourseProgressService.app();
      await progress.initializeForPlacement('a1');
      final gateway = StorageOnboardingCommitGateway(courseProgress: progress);

      final queuedPlacementChange = progress.initializeForPlacement('a2');
      final capturedPlacement = gateway.readPlacement();

      await queuedPlacementChange;
      final snapshot = await capturedPlacement;
      expect(snapshot.placementLevel, LearnerLevel.a2);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a2');
      expect(Storage.courseUnitId, startsWith('a2_'));
    },
  );

  test(
    'same canonical placement repairs torn mirrors after generation reset',
    () async {
      const completedUnitId = 'a1_01_greetings_hangul';
      const currentUnitId = 'a1_02_self_intro_identity';
      final legacy = jsonEncode({
        'version': 1,
        'placementLevel': 'a1',
        'currentCourseUnitId': currentUnitId,
        'completedUnitIds': [completedUnitId],
      });
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        Storage.legacyCourseMasteryPreferenceKey: legacy,
      });
      await Storage.init();
      final progress = CourseProgressService.app();
      final gateway = StorageOnboardingCommitGateway(courseProgress: progress);
      final promoted = await gateway.readPlacement();
      final canonicalBeforeRepair = Storage.courseMasterySnapshotRawJson;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(Storage.placementLevelPreferenceKey, 'b2');
      await preferences.remove(Storage.courseUnitPreferenceKey);
      Storage.resetCachesAfterExternalWrite();

      final torn = await gateway.readPlacement();

      expect(promoted.placementLevel, LearnerLevel.a1);
      expect(torn.placementLevel, isNull);
      expect(torn.canonicalPlacementLevel, LearnerLevel.a1);
      expect(torn.hasCourseHistory, isFalse);

      await gateway.initializePlacement(
        LearnerLevel.a1,
        expectedGeneration: torn.courseGeneration,
      );
      final repaired = await gateway.readPlacement();
      final canonicalAfterRepair =
          jsonDecode(Storage.courseMasterySnapshotRawJson)
              as Map<String, dynamic>;

      expect(repaired.placementLevel, LearnerLevel.a1);
      expect(repaired.canonicalPlacementLevel, LearnerLevel.a1);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
      expect(Storage.courseUnitId, completedUnitId);
      expect(Storage.courseMasterySnapshotRawJson, canonicalBeforeRepair);
      expect(canonicalAfterRepair['completedUnitIds'], isEmpty);
    },
  );

  test('mirror repair rejects a stale canonical generation', () async {
    final progress = CourseProgressService.app();
    await progress.initializeForPlacement('a1');
    final gateway = StorageOnboardingCommitGateway(courseProgress: progress);
    final stale = await gateway.readPlacement();
    await progress.initializeForPlacement('a2');

    await expectLater(
      gateway.initializePlacement(
        LearnerLevel.a1,
        expectedGeneration: stale.courseGeneration,
      ),
      throwsA(isA<LocalReconciliationGenerationConflict>()),
    );

    final current = await gateway.readPlacement();
    expect(current.placementLevel, LearnerLevel.a2);
    expect(current.canonicalPlacementLevel, LearnerLevel.a2);
  });

  test(
    'browse-only evidence does not block an explicit placement choice',
    () async {
      final progress = CourseProgressService.app();
      await progress.initializeForPlacement('a1');
      await progress.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_a1_action_location_particle',
        true,
        occurredAt: DateTime.utc(2026, 8, 26, 12),
      );
      final gateway = StorageOnboardingCommitGateway(courseProgress: progress);

      final snapshot = await gateway.readPlacement();

      expect(snapshot.placementLevel, LearnerLevel.a1);
      expect(snapshot.hasCourseHistory, isFalse);
    },
  );

  test('legacy completion uses its bool as the final marker and never writes '
      'sessionCount', () async {
    final gateway = StorageOnboardingCommitGateway(
      clock: () => DateTime.utc(2026, 8, 26, 12, 30),
    );

    await gateway.markLegacyOnboardingComplete();
    Storage.resetForTesting();
    await Storage.init();

    expect(await gateway.isLegacyOnboardingComplete(), isTrue);
    expect(Storage.lastActivityTime, '2026-08-26T12:30:00.000Z');
    expect(Storage.sessionCount, 0);
  });

  test(
    'strict onboarding bool write rejects an optimistic cache-only result',
    () async {
      final store = _RejectingBoolStore(initial: false);

      await expectLater(
        Storage.setHasCompletedOnboardingStrict(true, preferences: store),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(store.getBool('kl_onboarding_completed'), isFalse);
      expect(store.reloadCalls, 1);
    },
  );

  test('strict onboarding bool write accepts a false return after durable '
      'read-back confirms the value', () async {
    final store = _FalseButDurableBoolStore(initial: false);

    await Storage.setHasCompletedOnboardingStrict(true, preferences: store);

    expect(store.getBool('kl_onboarding_completed'), isTrue);
    expect(store.reloadCalls, 1);
  });
}

class _RejectingBoolStore implements PreferenceBoolStore {
  _RejectingBoolStore({required bool initial})
    : _disk = initial,
      _cache = initial;

  final bool _disk;
  bool _cache;
  int reloadCalls = 0;

  @override
  bool containsKey(String key) => true;

  @override
  bool? getBool(String key) => _cache;

  @override
  Future<void> reload() async {
    reloadCalls++;
    _cache = _disk;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _cache = value;
    return false;
  }
}

class _FalseButDurableBoolStore implements PreferenceBoolStore {
  _FalseButDurableBoolStore({required bool initial})
    : _disk = initial,
      _cache = initial;

  bool _disk;
  bool _cache;
  int reloadCalls = 0;

  @override
  bool containsKey(String key) => true;

  @override
  bool? getBool(String key) => _cache;

  @override
  Future<void> reload() async {
    reloadCalls++;
    _cache = _disk;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _cache = value;
    _disk = value;
    return false;
  }
}
