import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

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
}

/// App-wide analytics facade. Event names and parameters are GA4-safe
/// (snake_case, ≤ 40 chars, no reserved `firebase_`/`google_`/`ga_` prefix) and
/// carry no personal data — only short IDs, level codes and counters.
class Analytics {
  Analytics._();

  static final AnalyticsController _controller = AnalyticsController(
    hasConsent: () => Storage.analyticsConsent,
    client: const FirebaseAnalyticsEventClient(),
  );

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _controller.logEvent(name, parameters: parameters);
  }

  static Future<void> logScreenView(String screenName) {
    return _controller.logScreenView(screenName);
  }

  // ── Typed core-funnel events ────────────────────────────────────────────
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
      parameters: {'level': levelCode},
    );
  }

  /// "책 한 컷" analysis finished. [offline] is true when only the on-device
  /// stub answered (no protected server analysis).
  static Future<void> bookCaptureAnalyzed({
    required String targetLang,
    required int words,
    required bool offline,
  }) {
    return logEvent(
      'book_capture_analyzed',
      parameters: {
        'target_lang': targetLang,
        'words': words,
        'offline': offline ? 1 : 0,
      },
    );
  }

  /// A custom word pack was created. [source] is `from_page` (from a captured
  /// book page) or `empty` (blank manual pack).
  static Future<void> customPackCreated(String source) {
    return logEvent('custom_pack_created', parameters: {'source': source});
  }

  /// A study group (계) was created.
  static Future<void> gyeCreated() => logEvent('gye_created');

  /// The user joined an existing study group (계).
  static Future<void> gyeJoined() => logEvent('gye_joined');
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
