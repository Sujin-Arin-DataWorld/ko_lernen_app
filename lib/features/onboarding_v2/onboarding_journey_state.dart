import '../../models/learner_level.dart';

/// The durable stages of the first-run journey.
///
/// These values are persisted by name. Reorderings are safe, but renaming an
/// existing value requires an explicit decoder migration.
enum OnboardingPhase {
  story,
  setup,
  companion,
  confirmation,
  committing,
  gate,
  complete,
}

/// Stable identifiers for the five mandatory product-story pages.
enum StoryPageId {
  personalCurriculum,
  learn,
  saveAndReview,
  gamesAndRewards,
  heritageJourney,
}

/// Durable commit journal. A stage advances only after the corresponding
/// service state has been read back and verified.
enum OnboardingCommitStage {
  none,
  motivationSaved,
  placementVerified,
  companionSaved,
  completed,
}

/// The release path chosen when this journey is first created.
///
/// This value is durable. Remote Config may change while the app is running or
/// between launches, but an in-progress journey must never mix the mandatory
/// full story with the no-media kill-switch path.
enum OnboardingRolloutMode { full, minimalSafe }

/// Closed failure reasons for the decorative companion confirmation preview.
/// Raw decoder errors, asset paths, and device details never cross the
/// analytics boundary.
enum OnboardingCompanionPreviewFailure { initialization, playback }

/// The four recommendation-only purposes offered by onboarding V2.
enum OnboardingPurpose {
  dailyTravel('daily_travel'),
  peopleCulture('people_culture'),
  studyWork('study_work'),
  kContent('k_content');

  const OnboardingPurpose(this.code);

  final String code;

  static OnboardingPurpose? fromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final purpose in values) {
      if (purpose.code == normalized ||
          purpose.name.toLowerCase() == normalized) {
        return purpose;
      }
    }
    return switch (normalized) {
      // Legacy seven-purpose onboarding is intentionally collapsed into the
      // four V2 recommendation groups. This never changes course difficulty.
      'travel' => OnboardingPurpose.dailyTravel,
      'culture' || 'loved' || 'curious' => OnboardingPurpose.peopleCulture,
      'career' => OnboardingPurpose.studyWork,
      'kpop' || 'kdrama' => OnboardingPurpose.kContent,
      _ => null,
    };
  }

  /// Compatibility value for the existing motivation store.
  String get legacyStorageCode => switch (this) {
    OnboardingPurpose.dailyTravel => 'travel',
    OnboardingPurpose.peopleCulture => 'culture',
    OnboardingPurpose.studyWork => 'career',
    OnboardingPurpose.kContent => 'kdrama',
  };
}

/// The mandatory first-run companion choice. `none` remains a later setting,
/// not an onboarding draft value.
enum OnboardingCompanion {
  taego('tiger'),
  joy('magpie');

  const OnboardingCompanion(this.storageCode);

  final String storageCode;

  static OnboardingCompanion? fromStorageCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'taego' || 'tiger' => OnboardingCompanion.taego,
      'joy' || 'magpie' => OnboardingCompanion.joy,
      _ => null,
    };
  }
}

const Object _notProvided = Object();

/// Immutable, serializable source of truth for onboarding V2.
class OnboardingJourneyState {
  const OnboardingJourneyState({
    required this.schemaVersion,
    required this.rolloutMode,
    required this.phase,
    required this.storyPage,
    required this.purposeDraft,
    required this.levelDraft,
    required this.companionDraft,
    required this.commitStage,
    required this.startEventSent,
    required this.gateIntroAttempted,
    required this.gateIntroConsumed,
    required this.shellEntryEventSent,
    required this.updatedAt,
  });

  static const int currentSchemaVersion = 4;

  final int schemaVersion;
  final OnboardingRolloutMode rolloutMode;
  final OnboardingPhase phase;
  final StoryPageId storyPage;
  final OnboardingPurpose? purposeDraft;
  final LearnerLevel? levelDraft;
  final OnboardingCompanion? companionDraft;
  final OnboardingCommitStage commitStage;
  final bool startEventSent;
  final bool gateIntroAttempted;
  final bool gateIntroConsumed;
  final bool shellEntryEventSent;
  final DateTime updatedAt;

  bool get hasCompleteSetup => purposeDraft != null && levelDraft != null;

  bool get canCommit => hasCompleteSetup && companionDraft != null;

  factory OnboardingJourneyState.initial(
    DateTime now, {
    OnboardingRolloutMode rolloutMode = OnboardingRolloutMode.full,
  }) {
    return OnboardingJourneyState(
      schemaVersion: currentSchemaVersion,
      rolloutMode: rolloutMode,
      phase: OnboardingPhase.story,
      storyPage: StoryPageId.personalCurriculum,
      purposeDraft: null,
      levelDraft: null,
      companionDraft: null,
      commitStage: OnboardingCommitStage.none,
      startEventSent: false,
      gateIntroAttempted: false,
      gateIntroConsumed: false,
      shellEntryEventSent: false,
      updatedAt: now.toUtc(),
    );
  }

  /// Existing users are migrated straight to the shell. They must not emit a
  /// fresh-install completion event or replay the one-time gate.
  factory OnboardingJourneyState.legacyCompleted({
    required DateTime now,
    OnboardingPurpose? purpose,
    LearnerLevel? level,
    OnboardingCompanion? companion,
  }) {
    return OnboardingJourneyState(
      schemaVersion: currentSchemaVersion,
      rolloutMode: OnboardingRolloutMode.minimalSafe,
      phase: OnboardingPhase.complete,
      storyPage: StoryPageId.heritageJourney,
      purposeDraft: purpose,
      levelDraft: level,
      companionDraft: companion,
      commitStage: OnboardingCommitStage.completed,
      startEventSent: true,
      gateIntroAttempted: true,
      gateIntroConsumed: true,
      shellEntryEventSent: true,
      updatedAt: now.toUtc(),
    );
  }

  OnboardingJourneyState copyWith({
    int? schemaVersion,
    OnboardingRolloutMode? rolloutMode,
    OnboardingPhase? phase,
    StoryPageId? storyPage,
    Object? purposeDraft = _notProvided,
    Object? levelDraft = _notProvided,
    Object? companionDraft = _notProvided,
    OnboardingCommitStage? commitStage,
    bool? startEventSent,
    bool? gateIntroAttempted,
    bool? gateIntroConsumed,
    bool? shellEntryEventSent,
    DateTime? updatedAt,
  }) {
    return OnboardingJourneyState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rolloutMode: rolloutMode ?? this.rolloutMode,
      phase: phase ?? this.phase,
      storyPage: storyPage ?? this.storyPage,
      purposeDraft: identical(purposeDraft, _notProvided)
          ? this.purposeDraft
          : purposeDraft as OnboardingPurpose?,
      levelDraft: identical(levelDraft, _notProvided)
          ? this.levelDraft
          : levelDraft as LearnerLevel?,
      companionDraft: identical(companionDraft, _notProvided)
          ? this.companionDraft
          : companionDraft as OnboardingCompanion?,
      commitStage: commitStage ?? this.commitStage,
      startEventSent: startEventSent ?? this.startEventSent,
      gateIntroAttempted: gateIntroAttempted ?? this.gateIntroAttempted,
      gateIntroConsumed: gateIntroConsumed ?? this.gateIntroConsumed,
      shellEntryEventSent: shellEntryEventSent ?? this.shellEntryEventSent,
      updatedAt: (updatedAt ?? this.updatedAt).toUtc(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'rolloutMode': rolloutMode.name,
      'phase': phase.name,
      'storyPage': storyPage.name,
      'purposeDraft': purposeDraft?.code,
      'levelDraft': levelDraft?.code,
      'companionDraft': companionDraft?.storageCode,
      'commitStage': commitStage.name,
      'startEventSent': startEventSent,
      'gateIntroAttempted': gateIntroAttempted,
      'gateIntroConsumed': gateIntroConsumed,
      'shellEntryEventSent': shellEntryEventSent,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory OnboardingJourneyState.fromJson(Map<String, Object?> json) {
    final storedSchema = _intValue(json['schemaVersion']) ?? 1;
    if (storedSchema > currentSchemaVersion) {
      throw FormatException(
        'Unsupported onboarding schema version $storedSchema.',
      );
    }

    final phase =
        _enumByName(OnboardingPhase.values, json['phase']) ??
        OnboardingPhase.story;
    final storedRolloutMode = _enumByName(
      OnboardingRolloutMode.values,
      json['rolloutMode'],
    );
    if (storedSchema == currentSchemaVersion && storedRolloutMode == null) {
      throw const FormatException(
        'Current onboarding schema requires a recognized rollout mode.',
      );
    }
    final rolloutMode =
        storedRolloutMode ??
        (storedSchema < currentSchemaVersion && phase == OnboardingPhase.story
            ? OnboardingRolloutMode.full
            : OnboardingRolloutMode.minimalSafe);

    final decoded = OnboardingJourneyState(
      schemaVersion: currentSchemaVersion,
      rolloutMode: rolloutMode,
      phase: phase,
      storyPage:
          _enumByName(StoryPageId.values, json['storyPage']) ??
          StoryPageId.personalCurriculum,
      purposeDraft: OnboardingPurpose.fromCode(
        json['purposeDraft']?.toString(),
      ),
      levelDraft: LearnerLevel.fromCode(json['levelDraft']?.toString()),
      companionDraft: OnboardingCompanion.fromStorageCode(
        json['companionDraft']?.toString(),
      ),
      commitStage:
          _enumByName(OnboardingCommitStage.values, json['commitStage']) ??
          OnboardingCommitStage.none,
      // V1-V3 did not have a durable start marker. Suppress a late event when
      // those already-started journeys resume after this migration.
      startEventSent: storedSchema < 4 || json['startEventSent'] == true,
      gateIntroAttempted: json['gateIntroAttempted'] == true,
      gateIntroConsumed: json['gateIntroConsumed'] == true,
      // A completed V1-V3 journey predates this field but may already have
      // entered the shell. Suppress a duplicate completion event. In-progress
      // journeys still retain the opportunity to emit after their first real
      // AppShell frame.
      shellEntryEventSent:
          (storedSchema < 4 && phase == OnboardingPhase.complete) ||
          json['shellEntryEventSent'] == true,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    return decoded._normalized();
  }

  OnboardingJourneyState _normalized() {
    if (gateIntroConsumed || phase == OnboardingPhase.complete) {
      return copyWith(
        phase: OnboardingPhase.complete,
        commitStage: OnboardingCommitStage.completed,
        gateIntroAttempted: true,
        gateIntroConsumed: true,
      );
    }

    if (phase == OnboardingPhase.companion && !hasCompleteSetup) {
      return copyWith(
        phase: OnboardingPhase.setup,
        commitStage: OnboardingCommitStage.none,
      );
    }

    if ((phase == OnboardingPhase.confirmation ||
            phase == OnboardingPhase.committing ||
            phase == OnboardingPhase.gate) &&
        !canCommit) {
      return copyWith(
        phase: hasCompleteSetup
            ? OnboardingPhase.companion
            : OnboardingPhase.setup,
        commitStage: OnboardingCommitStage.none,
      );
    }

    if (phase == OnboardingPhase.gate &&
        commitStage != OnboardingCommitStage.completed) {
      return copyWith(phase: OnboardingPhase.committing);
    }

    return this;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingJourneyState &&
            other.schemaVersion == schemaVersion &&
            other.rolloutMode == rolloutMode &&
            other.phase == phase &&
            other.storyPage == storyPage &&
            other.purposeDraft == purposeDraft &&
            other.levelDraft == levelDraft &&
            other.companionDraft == companionDraft &&
            other.commitStage == commitStage &&
            other.startEventSent == startEventSent &&
            other.gateIntroAttempted == gateIntroAttempted &&
            other.gateIntroConsumed == gateIntroConsumed &&
            other.shellEntryEventSent == shellEntryEventSent &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    rolloutMode,
    phase,
    storyPage,
    purposeDraft,
    levelDraft,
    companionDraft,
    commitStage,
    startEventSent,
    gateIntroAttempted,
    gateIntroConsumed,
    shellEntryEventSent,
    updatedAt,
  );
}

T? _enumByName<T extends Enum>(List<T> values, Object? raw) {
  final name = raw?.toString();
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}
