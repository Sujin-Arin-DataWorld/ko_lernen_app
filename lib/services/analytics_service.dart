import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../features/onboarding_v2/onboarding_journey_state.dart';
import '../models/guide_contract.dart';
import '../models/learner_level.dart';
import 'age_gate_service.dart';
import 'locale_service.dart';
import 'storage_service.dart';

/// Why a learner left a mandatory onboarding story page. The closed enum is
/// intentionally separate from navigation route names so analytics can never
/// receive an arbitrary string.
enum OnboardingStoryExit { continued, previous, dropped }

enum OnboardingFlowVariant { full, minimalSafe }

enum OnboardingGateResult { completed, skipped, error, fallback }

/// The first broad learning surface observed after analytics consent became
/// effective in this local app-data lifetime. These are deliberately
/// product-area buckets, never route names, content IDs, answers, or learner
/// text.
enum ConsentedFirstLearningAction {
  course,
  hangul,
  scenario,
  vocabulary,
  grammar,
  listeningPronunciation,
  game,
  personalBook,
}

enum GuideEntryAnalyticsSurface { todayChecklist, guideHub }

enum GuideTodayCardAction { dismissed, restored }

/// Delivery channel for analytics events, kept separate from Firebase's static
/// plugin APIs so routing stays deterministically testable and so the app never
/// crashes when Firebase is not initialised (web / startup race): touching
/// [FirebaseAnalytics.instance] before `Firebase.initializeApp` throws, and the
/// controller below swallows that.
abstract interface class AnalyticsEventClient {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });
  Future<void> logScreenView({required String screenName});
  Future<void> setUserProperty({required String name, required String? value});
}

class FirebaseAnalyticsEventClient implements AnalyticsEventClient {
  const FirebaseAnalyticsEventClient();

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> logScreenView({required String screenName}) {
    return FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }

  @override
  Future<void> setUserProperty({required String name, required String? value}) {
    return FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }
}

/// Analytics events run only while consent is active. On top of the SDK-level
/// gate ([PrivacyConsentService] calls `setAnalyticsCollectionEnabled`), this
/// controller checks the stored consent and swallows every error, so a logging
/// call can never break a user flow or delay it in a way the caller notices.
class AnalyticsController {
  const AnalyticsController({required this.hasConsent, required this.client});

  final bool Function() hasConsent;
  final AnalyticsEventClient client;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      if (!hasConsent()) {
        return;
      }
      await client.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics: event "$name" skipped — $error');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      if (!hasConsent()) {
        return;
      }
      await client.logScreenView(screenName: screenName);
    } catch (error) {
      debugPrint('Analytics: screen_view "$screenName" skipped — $error');
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    try {
      if (!hasConsent()) {
        return;
      }
      await client.setUserProperty(name: name, value: value);
    } catch (error) {
      debugPrint('Analytics: user property "$name" skipped — $error');
    }
  }
}

/// Durable, consent-aware deduplication for the first observed learning action.
/// It deliberately keeps no pre-consent queue and persists only a one-bit claim
/// marker, never an analytics payload.
class ConsentedFirstLearningActionTracker {
  ConsentedFirstLearningActionTracker({
    required this.canCollect,
    required this.hasCompletedOnboarding,
    required this.readPurpose,
    required this.claimDurably,
    required this.record,
  });

  final bool Function() canCollect;
  final bool Function() hasCompletedOnboarding;
  final OnboardingPurpose? Function() readPurpose;
  final Future<bool> Function() claimDurably;
  final Future<void> Function(
    ConsentedFirstLearningAction action,
    OnboardingPurpose? purpose,
  )
  record;

  bool _reserved = false;

  @visibleForTesting
  bool get hasReserved => _reserved;

  @visibleForTesting
  void resetInMemory() => _reserved = false;

  Future<void> observe(ConsentedFirstLearningAction action) async {
    // Crucially, neither the in-memory reservation nor durable marker is
    // touched while collection is barred. A later opt-in observes only a later
    // action; nothing is replayed.
    if (_reserved || !hasCompletedOnboarding() || !canCollect()) {
      return;
    }
    // Reserve synchronously before the first await so concurrent observations
    // in this isolate cannot race for the claim.
    _reserved = true;
    try {
      if (!await claimDurably()) {
        return;
      }
      await record(action, readPurpose());
    } catch (error) {
      // Analytics and its durable marker must never break a learning flow. A
      // known failed write can be retried after a fresh app start; an unknown
      // write outcome remains fail-closed for this process.
      debugPrint('Analytics: first learning action skipped — $error');
    }
  }
}

/// App-wide analytics facade. Event names, parameters and user-property names
/// are GA4-safe (snake_case, ≤ 40 chars — user props ≤ 24 chars, no reserved
/// `firebase_`/`google_`/`ga_` prefix) and carry NO personal data — only short
/// IDs, level codes, enums and bucketed counters. Never pass free text, OCR'd
/// words, pack titles, emails or precise identifiers.
///
/// Consent is age-aware: until eligibility is positively established, no event,
/// screen view or user property is ever sent, even if a stored flag says
/// otherwise (DSGVO Art. 8 — no valid consent without parental authorisation).
class Analytics {
  Analytics._();

  static final ConsentedFirstLearningActionTracker
  _consentedFirstLearningActionTracker = ConsentedFirstLearningActionTracker(
    canCollect: () => canCollect,
    hasCompletedOnboarding: () => Storage.hasCompletedOnboarding,
    readPurpose: () => OnboardingPurpose.fromCode(Storage.motivation),
    claimDurably: Storage.claimConsentedFirstLearningAction,
    record: _sendConsentedFirstLearningAction,
  );

  @visibleForTesting
  static void resetConsentedFirstLearningActionForTesting() {
    _consentedFirstLearningActionTracker.resetInMemory();
  }

  /// Effective consent: the stored opt-in AND the conservative local age gate
  /// has positively established eligibility. Unknown age fails closed; it is
  /// never treated as adult. Mirrors [PrivacyConsentService].
  static bool _consentActive() =>
      Storage.analyticsConsent && AgeGateService.isGyeAllowed;

  /// Whether best-effort product analytics may be attempted right now.
  ///
  /// Callers that persist an at-most-once delivery marker use this before
  /// consuming the marker. The actual client still repeats the same consent
  /// check immediately before every SDK call, so revocation always wins.
  static bool get canCollect => _consentActive();

  static final AnalyticsController _controller = AnalyticsController(
    hasConsent: _consentActive,
    client: const FirebaseAnalyticsEventClient(),
  );

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _controller.logEvent(name, parameters: parameters);
  }

  static Future<void> logScreenView(String screenName) {
    return _controller.logScreenView(screenName);
  }

  static Future<void> setUserProperty(String name, String? value) {
    return _controller.setUserProperty(name, value);
  }

  /// Pushes the current non-PII segmentation properties. Safe to call anytime
  /// (no-ops without consent); call once at startup and after level/locale/
  /// streak/notification changes. Keeps every report segmentable by who the
  /// learner is without collecting anything identifying.
  static Future<void> syncUserProperties() async {
    final level = Storage.userLevelCode;
    final purpose = OnboardingPurpose.fromCode(Storage.motivation);
    await setUserProperty('learner_level', level?.toUpperCase());
    await setUserProperty('learning_purpose', purpose?.code);
    await setUserProperty('ui_language', localeNotifier.value?.languageCode);
    await setUserProperty(
      'notif_opt_in',
      Storage.notificationsEnabled ? 'true' : 'false',
    );
    await setUserProperty('streak_bucket', _streakBucket(Storage.streakDays));
  }

  static String _streakBucket(int days) {
    if (days <= 0) {
      return '0';
    }
    if (days < 7) {
      return '1-6';
    }
    if (days < 30) {
      return '7-29';
    }
    return '30plus';
  }

  // ── Typed events already wired ──────────────────────────────────────────
  /// A vocab pack's boss round was completed. [accuracyPct] is 0–100,
  /// [firstClear] marks the very first time this pack was cleared.
  static Future<void> packCompleted({
    required String packId,
    required int accuracyPct,
    required bool firstClear,
  }) {
    unawaited(
      _recordConsentedFirstLearningAction(
        ConsentedFirstLearningAction.vocabulary,
      ),
    );
    return logEvent(
      'pack_completed',
      parameters: {
        'pack_id': packId,
        'accuracy_pct': accuracyPct,
        'first_clear': firstClear ? 1 : 0,
      },
    );
  }

  /// The learner picked a starting level during onboarding.
  static Future<void> onboardingLevelSelected(String levelCode) {
    return logEvent(
      'onboarding_level_selected',
      parameters: {'level': levelCode.toUpperCase()},
    );
  }

  /// "책 한 컷" analysis finished. [offline] is true when only the on-device
  /// stub answered (no protected server analysis).
  static Future<void> bookCaptureAnalyzed({
    required String targetLang,
    required int words,
    required int grammar,
    required int sentences,
    required bool offline,
    required String resultStatus,
    required String warningBucket,
    String ocrQuality = 'unmeasured',
  }) {
    unawaited(
      _recordConsentedFirstLearningAction(
        ConsentedFirstLearningAction.personalBook,
      ),
    );
    return logEvent(
      'book_capture_analyzed',
      parameters: bookCaptureAnalysisParameters(
        targetLang: targetLang,
        words: words,
        grammar: grammar,
        sentences: sentences,
        offline: offline,
        resultStatus: resultStatus,
        warningBucket: warningBucket,
        ocrQuality: ocrQuality,
      ),
    );
  }

  static Map<String, Object> bookCaptureAnalysisParameters({
    required String targetLang,
    required int words,
    required int grammar,
    required int sentences,
    required bool offline,
    required String resultStatus,
    required String warningBucket,
    required String ocrQuality,
  }) => {
    'target_lang': targetLang,
    'words': words,
    'grammar': grammar,
    'sentences': sentences,
    'offline': offline ? 1 : 0,
    'result_status': resultStatus,
    'warning_bucket': warningBucket,
    'ocr_quality': ocrQuality,
  };

  /// A custom word pack was created. [source] is `from_page` (from a captured
  /// book page) or `empty` (blank manual pack).
  static Future<void> customPackCreated(String source) {
    unawaited(
      _recordConsentedFirstLearningAction(
        ConsentedFirstLearningAction.personalBook,
      ),
    );
    return logEvent('custom_pack_created', parameters: {'source': source});
  }

  /// A study group (계) was created.
  static Future<void> gyeCreated() => logEvent('gye_created');

  /// The user joined an existing study group (계).
  static Future<void> gyeJoined() => logEvent('gye_joined');

  // ── Typed events for the redesigned UI to call ──────────────────────────
  // These carry no PII: [lessonId]/[packId]/[gameType]/[featureName] are bounded
  // internal identifiers or enums, never user text. Wire the calls into the new
  // screens; the schema lives in docs/ANALYTICS_PRIVACY_PLAN.md.

  /// Onboarding first screen shown. [entryPoint]: fresh_install / reinstall.
  static Future<void> onboardingStarted({String? entryPoint}) {
    return logEvent(
      'onboarding_start',
      parameters: {if (entryPoint != null) 'entry_point': entryPoint},
    );
  }

  /// User reached home after onboarding. Top-of-funnel close.
  static Future<void> onboardingCompleted({
    required String entryLevel,
    required bool hasPlacement,
    OnboardingPurpose? purpose,
  }) {
    return logEvent(
      'onboarding_completed',
      parameters: onboardingCompletedParameters(
        entryLevel: entryLevel,
        hasPlacement: hasPlacement,
        purpose: purpose,
      ),
    );
  }

  static Map<String, Object> onboardingCompletedParameters({
    required String entryLevel,
    required bool hasPlacement,
    OnboardingPurpose? purpose,
  }) => {
    'entry_level': entryLevel.toUpperCase(),
    'has_placement': hasPlacement ? 1 : 0,
    if (purpose != null) 'purpose': purpose.code,
  };

  /// A mandatory product-story page became visible. [page] is a closed enum;
  /// no localized copy or route name is sent.
  static Future<void> onboardingStoryReached(StoryPageId page) {
    return logEvent(
      'onboarding_story_reached',
      parameters: onboardingStoryReachedParameters(page),
    );
  }

  static Map<String, Object> onboardingStoryReachedParameters(
    StoryPageId page,
  ) => {'page': _storyPageValue(page)};

  /// Records bucketed active time when the learner actually leaves a story
  /// page. `dropped` includes route disposal/app exit; exact timestamps are
  /// deliberately never sent.
  static Future<void> onboardingStoryDwell({
    required StoryPageId page,
    required Duration duration,
    required OnboardingStoryExit exit,
  }) {
    return logEvent(
      'onboarding_story_dwell',
      parameters: onboardingStoryDwellParameters(
        page: page,
        duration: duration,
        exit: exit,
      ),
    );
  }

  static Map<String, Object> onboardingStoryDwellParameters({
    required StoryPageId page,
    required Duration duration,
    required OnboardingStoryExit exit,
  }) => {
    'page': _storyPageValue(page),
    'duration_bucket': _storyDwellBucket(duration),
    'exit': exit.name,
  };

  static Future<void> onboardingPurposeSelectedV2(OnboardingPurpose purpose) {
    return _onboardingSelection(onboardingPurposeSelectionParameters(purpose));
  }

  static Map<String, Object> onboardingPurposeSelectionParameters(
    OnboardingPurpose purpose,
  ) => {'kind': 'purpose', 'value': purpose.code};

  static Future<void> onboardingLevelSelectedV2(LearnerLevel level) {
    return _onboardingSelection(onboardingLevelSelectionParameters(level));
  }

  static Map<String, Object> onboardingLevelSelectionParameters(
    LearnerLevel level,
  ) => {'kind': 'level', 'value': level.code.toUpperCase()};

  static Future<void> onboardingCompanionSelectedV2(
    OnboardingCompanion companion,
  ) {
    return _onboardingSelection(
      onboardingCompanionSelectionParameters(companion),
    );
  }

  static Map<String, Object> onboardingCompanionSelectionParameters(
    OnboardingCompanion companion,
  ) => {'kind': 'companion', 'value': companion.name};

  static Future<void> _onboardingSelection(Map<String, Object> parameters) {
    return logEvent('onboarding_selection', parameters: parameters);
  }

  /// An explicit decoder failure in the decorative companion confirmation
  /// preview. The CTA remains independent from media, and raw errors, device
  /// details, and asset paths are intentionally discarded.
  static Future<void> onboardingCompanionPreviewFailed(
    OnboardingCompanionPreviewFailure failure,
  ) {
    return logEvent(
      'onboarding_companion_preview_fail',
      parameters: onboardingCompanionPreviewFailureParameters(failure),
    );
  }

  static Map<String, Object> onboardingCompanionPreviewFailureParameters(
    OnboardingCompanionPreviewFailure failure,
  ) => {'reason': failure.name};

  /// Active time in the V2 journey widget, measured only at a successful
  /// commit boundary. A resumed session starts a new bucket rather than
  /// persisting a precise timestamp.
  static Future<void> onboardingTotalDuration({
    required Duration duration,
    required OnboardingFlowVariant flow,
  }) {
    return logEvent(
      'onboarding_duration',
      parameters: onboardingDurationParameters(duration: duration, flow: flow),
    );
  }

  static Map<String, Object> onboardingDurationParameters({
    required Duration duration,
    required OnboardingFlowVariant flow,
  }) => {
    'duration_bucket': _onboardingDurationBucket(duration),
    'flow': switch (flow) {
      OnboardingFlowVariant.full => 'full',
      OnboardingFlowVariant.minimalSafe => 'minimal_safe',
    },
  };

  /// One terminal outcome per gate presentation. Video initialization errors
  /// that successfully continue via the code scene are reported as
  /// [OnboardingGateResult.fallback], while journal failures are `error`.
  static Future<void> onboardingGateResult(OnboardingGateResult result) {
    return logEvent(
      'onboarding_gate_result',
      parameters: onboardingGateResultParameters(result),
    );
  }

  static Map<String, Object> onboardingGateResultParameters(
    OnboardingGateResult result,
  ) => {'result': result.name};

  /// Sends the already-durably-claimed first broad learning action. Keeping
  /// this private prevents callers from bypassing the once-only tracker.
  static Future<void> _sendConsentedFirstLearningAction(
    ConsentedFirstLearningAction action,
    OnboardingPurpose? purpose,
  ) {
    return logEvent(
      'consented_first_learning_action',
      parameters: consentedFirstLearningActionParameters(action, purpose),
    );
  }

  static Map<String, Object> consentedFirstLearningActionParameters(
    ConsentedFirstLearningAction action,
    OnboardingPurpose? purpose,
  ) => {
    'action': switch (action) {
      ConsentedFirstLearningAction.course => 'course',
      ConsentedFirstLearningAction.hangul => 'hangul',
      ConsentedFirstLearningAction.scenario => 'scenario',
      ConsentedFirstLearningAction.vocabulary => 'vocabulary',
      ConsentedFirstLearningAction.grammar => 'grammar',
      ConsentedFirstLearningAction.listeningPronunciation =>
        'listening_pronunciation',
      ConsentedFirstLearningAction.game => 'game',
      ConsentedFirstLearningAction.personalBook => 'personal_book',
    },
    'purpose': purpose?.code ?? 'unknown',
  };

  static Future<void> _recordConsentedFirstLearningAction(
    ConsentedFirstLearningAction action,
  ) => _consentedFirstLearningActionTracker.observe(action);

  /// Records a successful learning-surface start through a closed product-area
  /// enum. Screen implementations must never pass route names or learner data.
  static Future<void> learningActionStarted(
    ConsentedFirstLearningAction action,
  ) => _recordConsentedFirstLearningAction(action);

  static Future<void> guideTopicOpened({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
    required GuideTopicOpenState openState,
  }) {
    return logEvent(
      guideTopicOpenedEventName,
      parameters: guideTopicOpenedParameters(
        topic: topic,
        entrySurface: entrySurface,
        openState: openState,
      ),
    );
  }

  static const String guideHubOpenedEventName = 'guide_hub_opened';
  static const String guideTopicOpenedEventName = 'guide_topic_opened';

  static Future<void> guideHubOpened() {
    return logEvent(
      guideHubOpenedEventName,
      parameters: guideHubOpenedParameters(),
    );
  }

  static Map<String, Object> guideHubOpenedParameters() => {
    'surface': 'guide_hub',
  };

  static Map<String, Object> guideTopicOpenedParameters({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
    required GuideTopicOpenState openState,
  }) => {
    ...guideTopicParameters(topic: topic, entrySurface: entrySurface),
    'open_state': switch (openState) {
      GuideTopicOpenState.firstOpen => 'first_open',
      GuideTopicOpenState.reopen => 'reopen',
    },
  };

  static const String guideTopicClosedEventName = 'guide_topic_closed';

  static Future<void> guideTopicClosed({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
  }) {
    return logEvent(
      guideTopicClosedEventName,
      parameters: guideTopicParameters(
        topic: topic,
        entrySurface: entrySurface,
      ),
    );
  }

  static Future<void> guideTopicCompleted({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
  }) {
    return logEvent(
      'guide_topic_completed',
      parameters: guideTopicParameters(
        topic: topic,
        entrySurface: entrySurface,
      ),
    );
  }

  static Map<String, Object> guideTopicParameters({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
  }) => {
    // Keep the pre-V2 `surface` key for dashboard continuity. Its value is a
    // closed topic identity; `entry_surface` says where the action happened.
    'surface': topic.name,
    'entry_surface': switch (entrySurface) {
      GuideEntryAnalyticsSurface.todayChecklist => 'today_checklist',
      GuideEntryAnalyticsSurface.guideHub => 'guide_hub',
    },
  };

  static Future<void> guideTodayCardAction(GuideTodayCardAction action) {
    return logEvent(
      'guide_today_card_action',
      parameters: guideTodayCardActionParameters(action),
    );
  }

  static Map<String, Object> guideTodayCardActionParameters(
    GuideTodayCardAction action,
  ) => {'action': action.name};

  static const String guideRoutingFailedEventName = 'guide_routing_failed';

  static Future<void> guideRoutingFailed({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
    required GuideRoutingAction action,
    required GuideRoutingFailureReason reason,
  }) {
    return logEvent(
      guideRoutingFailedEventName,
      parameters: guideRoutingFailureParameters(
        topic: topic,
        entrySurface: entrySurface,
        action: action,
        reason: reason,
      ),
    );
  }

  static Map<String, Object> guideRoutingFailureParameters({
    required GuideAnalyticsSurface topic,
    required GuideEntryAnalyticsSurface entrySurface,
    required GuideRoutingAction action,
    required GuideRoutingFailureReason reason,
  }) => {
    ...guideTopicParameters(topic: topic, entrySurface: entrySurface),
    'action': switch (action) {
      GuideRoutingAction.topic => 'topic',
      GuideRoutingAction.courseStart => 'course_start',
      GuideRoutingAction.browseLevel => 'browse_level',
      GuideRoutingAction.hangulOverview => 'hangul_overview',
      GuideRoutingAction.hangulCards => 'hangul_cards',
      GuideRoutingAction.hangulWrite => 'hangul_write',
      GuideRoutingAction.learnStage => 'learn_stage',
      GuideRoutingAction.captureTextbook => 'capture_textbook',
      GuideRoutingAction.studyLibrary => 'study_library',
      GuideRoutingAction.gamesStage => 'games_stage',
      GuideRoutingAction.hanokStage => 'hanok_stage',
      GuideRoutingAction.companion => 'companion',
      GuideRoutingAction.voiceSpeed => 'voice_speed',
      GuideRoutingAction.guideSettings => 'guide_settings',
      GuideRoutingAction.scenarioCategory => 'scenario_category',
    },
    'reason': switch (reason) {
      GuideRoutingFailureReason.unavailable => 'unavailable',
      GuideRoutingFailureReason.consent => 'consent',
      GuideRoutingFailureReason.invalidDestination => 'invalid_destination',
      GuideRoutingFailureReason.navigation => 'navigation',
      GuideRoutingFailureReason.rollback => 'rollback',
    },
  };

  static String _storyPageValue(StoryPageId page) => switch (page) {
    StoryPageId.personalCurriculum => 'personal_curriculum',
    StoryPageId.learn => 'learn',
    StoryPageId.saveAndReview => 'save_and_review',
    StoryPageId.gamesAndRewards => 'games_and_rewards',
    StoryPageId.heritageJourney => 'heritage_journey',
  };

  static String _storyDwellBucket(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 3) {
      return 'under_3s';
    }
    if (seconds < 10) {
      return '3_9s';
    }
    if (seconds < 30) {
      return '10_29s';
    }
    return '30s_plus';
  }

  static String _onboardingDurationBucket(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 30) {
      return 'under_30s';
    }
    if (seconds < 60) {
      return '30_59s';
    }
    if (seconds < 180) {
      return '1_2m';
    }
    if (seconds < 300) {
      return '3_4m';
    }
    return '5m_plus';
  }

  /// Placement diagnostic finished.
  static Future<void> placementCompleted({
    required String resultLevel,
    required int correct,
    required int total,
  }) {
    return logEvent(
      'placement_completed',
      parameters: {
        'result_level': resultLevel.toUpperCase(),
        'correct_count': correct,
        'total_count': total,
      },
    );
  }

  /// A lesson (hangul/grammar/vocab/scenario) was opened.
  static Future<void> lessonStarted({
    required String lessonType,
    String? lessonId,
    String? level,
  }) {
    final firstAction = firstLearningActionForLessonType(lessonType);
    if (firstAction != null) {
      unawaited(_recordConsentedFirstLearningAction(firstAction));
    }
    return logEvent(
      'lesson_started',
      parameters: {
        'lesson_type': lessonType,
        if (lessonId != null) 'lesson_id': lessonId,
        if (level != null) 'level': level.toUpperCase(),
      },
    );
  }

  /// Maps bounded lesson-type identifiers to the closed first-action buckets.
  /// Unknown values never flow into first-action analytics.
  @visibleForTesting
  static ConsentedFirstLearningAction? firstLearningActionForLessonType(
    String lessonType,
  ) => switch (lessonType) {
    'course' => ConsentedFirstLearningAction.course,
    'hangul' => ConsentedFirstLearningAction.hangul,
    'scenario' || 'smalltalk' => ConsentedFirstLearningAction.scenario,
    'vocab' => ConsentedFirstLearningAction.vocabulary,
    'grammar' => ConsentedFirstLearningAction.grammar,
    'listening' ||
    'pronunciation' ||
    'media_phrase' => ConsentedFirstLearningAction.listeningPronunciation,
    _ => null,
  };

  /// A lesson was finished.
  static Future<void> lessonCompleted({
    required String lessonType,
    String? lessonId,
    String? level,
    bool firstTime = false,
  }) {
    return logEvent(
      'lesson_completed',
      parameters: {
        'lesson_type': lessonType,
        if (lessonId != null) 'lesson_id': lessonId,
        if (level != null) 'level': level.toUpperCase(),
        'first_time': firstTime ? 1 : 0,
      },
    );
  }

  /// A quiz/boss/game-quiz finished. [accuracyPct] 0–100. Logs both the raw
  /// metric and a low-cardinality band so distributions chart cleanly.
  static Future<void> quizCompleted({
    required String quizType,
    required int accuracyPct,
    String? level,
    bool? pass,
  }) {
    return logEvent(
      'quiz_completed',
      parameters: {
        'quiz_type': quizType,
        'accuracy_pct': accuracyPct,
        'accuracy_band': _accuracyBand(accuracyPct),
        if (level != null) 'level': level.toUpperCase(),
        if (pass != null) 'pass': pass ? 1 : 0,
      },
    );
  }

  static String _accuracyBand(int pct) {
    if (pct >= 100) {
      return '100';
    }
    if (pct >= 80) {
      return '80-99';
    }
    if (pct >= 60) {
      return '60-79';
    }
    return '0-59';
  }

  /// A minigame began. [gameType]: chosung/wordle/kkeunmari/matching/typing.
  static Future<void> gameStarted({required String gameType, String? level}) {
    unawaited(
      _recordConsentedFirstLearningAction(ConsentedFirstLearningAction.game),
    );
    return logEvent(
      'game_started',
      parameters: {
        'game_type': gameType,
        if (level != null) 'level': level.toUpperCase(),
      },
    );
  }

  /// A minigame ended. [result]: win/lose/quit.
  static Future<void> gameCompleted({
    required String gameType,
    required String result,
    int? score,
  }) {
    return logEvent(
      'game_completed',
      parameters: {
        'game_type': gameType,
        'result': result,
        if (score != null) 'score': score,
      },
    );
  }

  /// A smaller feature was opened. Umbrella event — discriminate on the
  /// low-cardinality [featureName] enum instead of minting one event per
  /// feature (protects the 500-event-name budget).
  static Future<void> featureUsed(String featureName, {String? surface}) {
    return logEvent(
      'feature_used',
      parameters: {
        'feature_name': featureName,
        if (surface != null) 'surface': surface,
      },
    );
  }

  /// TTS playback was triggered. [contentType]: word/sentence/dialogue.
  static Future<void> ttsPlayed({
    required String contentType,
    String? sourceFeature,
  }) {
    return logEvent(
      'tts_played',
      parameters: {
        'content_type': contentType,
        if (sourceFeature != null) 'source_feature': sourceFeature,
      },
    );
  }

  /// A word was saved to the wordbook. [source]: book_capture/quiz/lesson/manual.
  static Future<void> wordbookAdded({required String source, int count = 1}) {
    return logEvent(
      'wordbook_add',
      parameters: {'source': source, 'count': count},
    );
  }

  /// The learning streak incremented. [days] is a numeric metric (do not
  /// register it as a high-cardinality dimension).
  static Future<void> streakExtended(int days) {
    return logEvent('streak_extended', parameters: {'streak_length': days});
  }

  /// The streak crossed a milestone threshold (3/7/14/30/50/100 …).
  static Future<void> streakMilestone(int milestoneDays) {
    return logEvent(
      'streak_milestone',
      parameters: {'milestone_days': milestoneDays},
    );
  }

  /// The daily goal was met. [goalType]: xp/lessons/minutes.
  static Future<void> dailyGoalMet({required String goalType, int? goalValue}) {
    return logEvent(
      'daily_goal_met',
      parameters: {
        'goal_type': goalType,
        if (goalValue != null) 'goal_value': goalValue,
      },
    );
  }

  // ── Monetization hooks (wire now, activate when subscriptions launch) ────
  /// A paywall was shown. [placement]: onboarding/pack_lock/streak_freeze/…
  static Future<void> paywallViewed({required String placement}) {
    return logEvent('paywall_viewed', parameters: {'placement': placement});
  }

  /// The user initiated a purchase (tapped buy). Revenue is recorded
  /// server-side by RevenueCat as `purchase` — never put revenue here.
  static Future<void> subscribeStarted({
    required String productId,
    String? placement,
  }) {
    return logEvent(
      'subscribe_started',
      parameters: {
        'product_id': productId,
        if (placement != null) 'placement': placement,
      },
    );
  }

  // ── Drop-off funnel (onboarding step / abandon / hanok loop) ────────────
  /// A single onboarding screen was reached. Complements `onboarding_start`/
  /// `onboarding_completed` with per-screen granularity so drop-off between
  /// specific steps is visible, not just top-of-funnel vs completion.
  static Future<void> tutorialStep({
    required int stepNumber,
    required String stepName,
  }) {
    return logEvent(
      'tutorial_step',
      parameters: {'step_number': stepNumber, 'step_name': stepName},
    );
  }

  /// A lesson/quiz/game screen was left before it produced a completion
  /// event. [lastStepReached] is a bounded in-screen marker (question index,
  /// stage name, …), never free text. See [QuestAbandonTracker] — this is
  /// the more actionable drop-off signal vs [questFailed]: a user just
  /// closing the screen mid-way (no error, no wrong answer) usually means
  /// the screen itself lost them, not the content's difficulty.
  static Future<void> questAbandoned({
    required String questType,
    String? questId,
    required String lastStepReached,
  }) {
    return logEvent(
      'quest_abandon',
      parameters: {
        'quest_type': questType,
        if (questId != null) 'quest_id': questId,
        'last_step_reached': lastStepReached,
      },
    );
  }

  /// A lesson/quiz/game ended in failure with a distinguishable cause.
  /// [failReason] is a low-cardinality enum (`accuracy_below_threshold`,
  /// `timeout`, …) — this is content-difficulty signal, complementary to
  /// [questAbandoned].
  static Future<void> questFailed({
    required String questType,
    required String failReason,
  }) {
    return logEvent(
      'quest_fail',
      parameters: {'quest_type': questType, 'fail_reason': failReason},
    );
  }

  /// The learner opened a decorating/building surface (사랑방/마당).
  /// [roomType]: sarangbang/madang.
  static Future<void> hanokBuildStarted({required String roomType}) {
    return logEvent('hanok_build_start', parameters: {'room_type': roomType});
  }

  /// A decoration/sticker/stamp was newly placed into a room layout (not a
  /// move or re-selection of an existing placement). [itemType]: the
  /// [RoomAssetKind] name (decoration/sticker/stamp). [itemId] is a bounded
  /// catalog slug, never user text.
  static Future<void> itemPlaced({
    required String itemType,
    required String itemId,
  }) {
    return logEvent(
      'item_placed',
      parameters: {'item_type': itemType, 'item_id': itemId},
    );
  }

  /// Owned decorations that are still unplaced after a while. Logged at most
  /// once per calendar day, one call per non-empty age bucket present (never
  /// per item, to keep volume low). [daysSinceEarnedBucket]: 0-2/3-6/7-13/
  /// 14-29/30plus.
  static Future<void> rewardUnused({
    required String rewardType,
    required String daysSinceEarnedBucket,
  }) {
    return logEvent(
      'reward_unused',
      parameters: {
        'reward_type': rewardType,
        'days_since_earned': daysSinceEarnedBucket,
      },
    );
  }
}

/// Registers named routes as `screen_view` events. Deliberately routes through
/// the [Analytics] wrapper instead of Firebase's `FirebaseAnalyticsObserver` so
/// nothing that could throw is constructed before Firebase is initialised or on
/// web where Firebase may be absent.
class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _log(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _log(previousRoute);
    }
  }

  void _log(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    unawaited(Analytics.logScreenView(name));
  }
}

/// Shared observer instance registered on the app's [Navigator].
final AnalyticsRouteObserver analyticsRouteObserver = AnalyticsRouteObserver();
