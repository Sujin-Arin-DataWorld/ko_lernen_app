import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import 'age_gate_service.dart';
import 'locale_service.dart';
import 'storage_service.dart';

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

/// App-wide analytics facade. Event names, parameters and user-property names
/// are GA4-safe (snake_case, ≤ 40 chars — user props ≤ 24 chars, no reserved
/// `firebase_`/`google_`/`ga_` prefix) and carry NO personal data — only short
/// IDs, level codes, enums and bucketed counters. Never pass free text, OCR'd
/// words, pack titles, emails or precise identifiers.
///
/// Consent is age-aware: for self-attested under-16 users no event, screen view
/// or user property is ever sent, even if a stored flag says otherwise
/// (DSGVO Art. 8 — no valid consent without parental authorisation).
class Analytics {
  Analytics._();

  /// Effective consent: the stored opt-in AND the user is not a self-attested
  /// minor. Mirrors the gate [PrivacyConsentService] applies to the SDK itself.
  static bool _consentActive() =>
      Storage.analyticsConsent && !AgeGateService.isUnderMinAge;

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
    await setUserProperty('learner_level', level?.toUpperCase());
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
  }) {
    return logEvent(
      'onboarding_completed',
      parameters: {
        'entry_level': entryLevel.toUpperCase(),
        'has_placement': hasPlacement ? 1 : 0,
      },
    );
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
    return logEvent(
      'lesson_started',
      parameters: {
        'lesson_type': lessonType,
        if (lessonId != null) 'lesson_id': lessonId,
        if (level != null) 'level': level.toUpperCase(),
      },
    );
  }

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
