// Development target: production routes and assets, separate localhost origin.
// No Firebase startup, account operation, upload or mock course completion.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/services/locale_service.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Storage.setSndMaster(false);
  await Storage.setHapticsEnabled(false);
  final query = Uri.base.queryParameters;
  await Storage.setReducedMotion(query['reduce'] == '1');
  localeNotifier.value = Locale(query['lang'] == 'en' ? 'en' : 'de');
  // First-run flags concern this isolated local preview only.
  await Storage.setTutSeen('home_tour');
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(
    SharedPreferencesOnboardingJourneyRepository.preferenceKey,
  )) {
    await SharedPreferencesOnboardingJourneyRepository().save(
      OnboardingJourneyState.initial(DateTime.now()).copyWith(
        phase: OnboardingPhase.complete,
        beginnerDraft: true,
        levelDraft: LearnerLevel.a1,
        companionDraft: OnboardingCompanion.taego,
        commitStage: OnboardingCommitStage.completed,
        gateIntroAttempted: true,
        gateIntroConsumed: true,
      ),
    );
  }
  await Future.wait([
    CurriculumCatalog.load(),
    LearningPhaseCatalog.load(),
    VocabPackService.loadAll(),
  ]);
  // Real empty A1 placement, as created by onboarding. No completed units,
  // attempts, mastery evidence or XP are synthesized for this local origin.
  if (await CourseProgressService.shared.readForDisplay() == null) {
    await CourseProgressService.shared.initializeForPlacement(
      'a1',
      preserveHistory: true,
      expectedGeneration: '',
    );
  }
  try {
    await YeopjeonService.loadCurrent();
  } catch (_) {
    /* Surface errors stay visible. */
  }
  TigerStageVideo.videoReady = true;
  // Explicit test box is seeded once. Reload/replay preserves the receipt.
  if (query['box'] == '1' && !prefs.containsKey('c_review_box_seeded')) {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await prefs.setBool('c_review_box_seeded', true);
  }
  final route = query['route'] ?? '/';
  runApp(
    KoLernenApp(
      startRoute: route,
      reviewTextScaler: query['scale'] == '2'
          ? const TextScaler.linear(2)
          : null,
      firstRunCoordinator: FirstRunCoordinator(
        repository: SharedPreferencesOnboardingJourneyRepository(),
        legacyStateReader: const _ReviewLegacyFixture(),
        commitGateway: StorageOnboardingCommitGateway(),
      ),
    ),
  );
}

// Ephemeral review fixture, not a consent write or a production-gate change.
// It allows the root of a direct local route to represent an existing learner.
class _ReviewLegacyFixture implements LegacyOnboardingStateReader {
  const _ReviewLegacyFixture();
  @override
  Future<LegacyOnboardingSnapshot> read() async =>
      const LegacyOnboardingSnapshot(
        consentAccepted: true,
        hasCompletedOnboarding: true,
        userLevel: LearnerLevel.a1,
        companion: OnboardingCompanion.taego,
      );
}
