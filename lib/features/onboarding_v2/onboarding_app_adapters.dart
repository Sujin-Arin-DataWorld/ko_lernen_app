import '../../models/learner_level.dart';
import '../../services/course_progress_service.dart';
import '../../services/storage_service.dart';
import 'first_run_coordinator.dart';
import 'onboarding_journey_state.dart';

/// Read-only adapter for pre-V2 keys. No `sessionCount` or intro-preview flag
/// participates in the migration decision.
class StorageLegacyOnboardingStateReader
    implements LegacyOnboardingStateReader {
  const StorageLegacyOnboardingStateReader();

  @override
  Future<LegacyOnboardingSnapshot> read() async {
    final explicitCompanion = Storage.explicitSelectedCompanion;
    final legacyCompanion = OnboardingCompanion.fromStorageCode(
      Storage.preferredMascot,
    );
    return LegacyOnboardingSnapshot(
      consentAccepted: Storage.consentAccepted,
      hasCompletedOnboarding: Storage.hasCompletedOnboarding,
      userLevel: LearnerLevel.fromCode(Storage.userLevelCode),
      purpose: OnboardingPurpose.fromCode(Storage.motivation),
      // A fresh install has neither value. Do not turn Storage's presentation
      // fallback into a draft the learner never explicitly chose.
      companion:
          OnboardingCompanion.fromStorageCode(explicitCompanion) ??
          legacyCompanion,
    );
  }
}

/// Production commit adapter for the existing course and preference services.
///
/// This deliberately does not call [OnboardingFlowService]: that legacy helper
/// emits analytics before AppShell's first frame. It also never awards XP,
/// badges, quests, or Hanok progress.
class StorageOnboardingCommitGateway
    implements
        OnboardingCommitGateway,
        OnboardingCompanionCommitSnapshotReader {
  factory StorageOnboardingCommitGateway({
    CourseProgressService? courseProgress,
    DateTime Function()? clock,
    Future<void> Function(OnboardingCompanion)? onCompanionSaved,
  }) {
    return StorageOnboardingCommitGateway._(
      courseProgress ?? CourseProgressService.shared,
      clock ?? DateTime.now,
      onCompanionSaved,
    );
  }

  StorageOnboardingCommitGateway._(
    this._courseProgress,
    this._clock,
    this._onCompanionSaved,
  );

  final CourseProgressService _courseProgress;
  final DateTime Function() _clock;
  final Future<void> Function(OnboardingCompanion)? _onCompanionSaved;

  @override
  Future<bool> hasConsent() async => Storage.consentAccepted;

  @override
  Future<OnboardingPurpose?> readPurpose() async {
    // The bool is the second-write commit marker. A process that stopped after
    // only writing the value must retry the complete purpose transaction.
    if (!Storage.motivationAsked) return null;
    return OnboardingPurpose.fromCode(Storage.motivation);
  }

  @override
  Future<void> savePurpose(OnboardingPurpose purpose) async {
    await Storage.setMotivationStrict(purpose.legacyStorageCode);
    await Storage.setMotivationAskedStrict();
  }

  @override
  Future<OnboardingPlacementSnapshot> readPlacement() async {
    // Promotion and every verification field are captured in the course
    // writer's queue. Reading them separately can observe two generations and
    // falsely trigger destructive placement initialization.
    final capture = await _courseProgress.captureForPlacementVerification();
    final scalarPlacement = LearnerLevel.fromCode(capture.placementLevelCode);
    final canonicalPlacement = LearnerLevel.fromCode(
      capture.snapshot?.placementLevel,
    );
    LearnerLevel? verifiedPlacement;
    // The canonical course graph is the final commit marker for the atomic
    // placement transaction. Scalar mirrors alone are never sufficient.
    if (capture.canonicalGeneration.trim().isNotEmpty) {
      if (canonicalPlacement == scalarPlacement &&
          capture.snapshot?.currentCourseUnitId ==
              capture.currentCourseUnitId) {
        verifiedPlacement = canonicalPlacement;
      }
    }
    return OnboardingPlacementSnapshot(
      placementLevel: verifiedPlacement,
      canonicalPlacementLevel: canonicalPlacement,
      browseLevel: LearnerLevel.fromCode(capture.browseLevelCode),
      courseGeneration: capture.canonicalGeneration,
      hasCourseHistory:
          capture.snapshot?.completedUnitIds.isNotEmpty == true ||
          capture.snapshot?.evidence.any(
                (evidence) => evidence.courseEligible,
              ) ==
              true ||
          capture.snapshot?.scenarioCheckpoints.any(
                (checkpoint) => checkpoint.courseEligible,
              ) ==
              true ||
          capture.snapshot?.productiveEvidence.isNotEmpty == true ||
          capture.snapshot?.productiveProjectStepEvidence.isNotEmpty == true,
    );
  }

  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) async {
    await _courseProgress.initializeOrRepairForPlacement(
      level.code,
      preserveHistory: true,
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) {
    return Storage.setBrowseLevelCodeStrict(level.code);
  }

  @override
  Future<OnboardingCompanion?> readCompanion() async {
    return OnboardingCompanion.fromStorageCode(Storage.selectedCompanion);
  }

  @override
  Future<OnboardingCompanionCommitSnapshot>
  readCompanionCommitSnapshot() async {
    final explicitCompanion = Storage.explicitSelectedCompanion;
    return OnboardingCompanionCommitSnapshot(
      companion: OnboardingCompanion.fromStorageCode(explicitCompanion),
      identityExplicitlyStored: explicitCompanion != null,
      visible: Storage.companionVisible,
      legacyMirror: OnboardingCompanion.fromStorageCode(
        Storage.preferredMascot,
      ),
    );
  }

  @override
  Future<void> saveCompanion(OnboardingCompanion companion) async {
    await Storage.setSelectedCompanionStrict(companion.storageCode);
    await Storage.setCompanionVisibleStrict(true);
    // Keep the pre-V2 preference as a compatibility mirror for callers that
    // have not migrated to the identity/visibility split yet.
    await Storage.setPreferredMascotStrict(companion.storageCode);
    await _onCompanionSaved?.call(companion);
  }

  @override
  Future<bool> isLegacyOnboardingComplete() async {
    return Storage.hasCompletedOnboarding;
  }

  @override
  Future<void> markLegacyOnboardingComplete() async {
    // Completion is the final commit marker. If the process dies between the
    // two writes, the coordinator observes `false` and safely retries both.
    await Storage.setLastActivityTimeStrict(_clock().toUtc().toIso8601String());
    await Storage.setHasCompletedOnboardingStrict(true);
  }
}
