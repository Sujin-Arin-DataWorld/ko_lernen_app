import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

abstract interface class AnalyticsConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
}

abstract interface class CrashConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> deleteUnsentReports();
  void recordFlutterFatalError(FlutterErrorDetails details);
  void recordError(Object error, StackTrace stack, {required bool fatal});
}

class FirebaseAnalyticsConsentClient implements AnalyticsConsentClient {
  const FirebaseAnalyticsConsentClient();

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }
}

class FirebaseCrashConsentClient implements CrashConsentClient {
  const FirebaseCrashConsentClient();

  @override
  Future<void> deleteUnsentReports() {
    return FirebaseCrashlytics.instance.deleteUnsentReports();
  }

  @override
  void recordError(Object error, StackTrace stack, {required bool fatal}) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      enabled,
    );
  }
}

/// Consent policy separated from Firebase's static plugin APIs for deterministic
/// lifecycle testing and for keeping error-routing decisions in one place.
class PrivacyConsentController {
  const PrivacyConsentController({
    required this.analyticsConsent,
    required this.crashConsent,
    required this.persistAnalyticsConsent,
    required this.persistCrashConsent,
    required this.analyticsClient,
    required this.crashClient,
    required this.presentFlutterError,
  });

  final bool Function() analyticsConsent;
  final bool Function() crashConsent;
  final Future<void> Function(bool) persistAnalyticsConsent;
  final Future<void> Function(bool) persistCrashConsent;
  final AnalyticsConsentClient analyticsClient;
  final CrashConsentClient crashClient;
  final void Function(FlutterErrorDetails) presentFlutterError;

  /// Applies the already-persisted startup decision. Reports created while
  /// consent was legitimately enabled are deliberately preserved.
  Future<void> applyStored() async {
    await _setAnalyticsCollection(analyticsConsent());
    final enabled = crashConsent();
    if (enabled) {
      await _setCrashCollection(true);
    } else {
      await _disableCrashCollectionAndDeleteReports();
    }
  }

  Future<void> setAnalytics(bool enabled, {bool persist = true}) async {
    if (persist) {
      await persistAnalyticsConsent(enabled);
    }
    await _setAnalyticsCollection(enabled);
  }

  Future<void> setCrash(bool enabled, {bool persist = true}) async {
    final wasEnabled = crashConsent();
    if (persist) {
      await persistCrashConsent(enabled);
    }

    if (!enabled) {
      await _disableCrashCollectionAndDeleteReports();
      return;
    }

    if (persist && !wasEnabled) {
      await _deleteCrashReports();
    }
    await _setCrashCollection(true);
  }

  void handleFlutterError(
    FlutterErrorDetails details, {
    required bool isDebug,
  }) {
    if (!crashConsent()) {
      presentFlutterError(details);
      return;
    }

    if (isDebug) {
      presentFlutterError(details);
    }
    try {
      crashClient.recordFlutterFatalError(details);
    } catch (error) {
      if (!isDebug) {
        presentFlutterError(details);
      }
      debugPrint('PrivacyConsent: crash report skipped — $error');
    }
  }

  bool handlePlatformError(Object error, StackTrace stack) {
    if (!crashConsent()) {
      presentFlutterError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription('uncaught asynchronous error'),
        ),
      );
      return true;
    }

    try {
      crashClient.recordError(error, stack, fatal: true);
    } catch (reportingError) {
      presentFlutterError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription('uncaught asynchronous error'),
        ),
      );
      debugPrint('PrivacyConsent: crash report skipped — $reportingError');
    }
    return true;
  }

  Future<void> _disableCrashCollectionAndDeleteReports() async {
    await _setCrashCollection(false);
    await _deleteCrashReports();
  }

  Future<void> _setAnalyticsCollection(bool enabled) async {
    try {
      await analyticsClient.setCollectionEnabled(enabled);
    } catch (error) {
      debugPrint('PrivacyConsent: analytics toggle skipped — $error');
    }
  }

  Future<void> _setCrashCollection(bool enabled) async {
    try {
      await crashClient.setCollectionEnabled(enabled);
    } catch (error) {
      debugPrint('PrivacyConsent: crashlytics toggle skipped — $error');
    }
  }

  Future<void> _deleteCrashReports() async {
    try {
      await crashClient.deleteUnsentReports();
    } catch (error) {
      debugPrint('PrivacyConsent: crash report deletion skipped — $error');
    }
  }
}

/// Analytics and Crashlytics remain opt-in. The native collection defaults are
/// disabled; this facade applies and persists the user's runtime decision.
class PrivacyConsentService {
  PrivacyConsentService._();

  static final PrivacyConsentController _controller = PrivacyConsentController(
    analyticsConsent: () => Storage.analyticsConsent,
    crashConsent: () => Storage.crashConsent,
    persistAnalyticsConsent: Storage.setAnalyticsConsent,
    persistCrashConsent: Storage.setCrashConsent,
    analyticsClient: const FirebaseAnalyticsConsentClient(),
    crashClient: const FirebaseCrashConsentClient(),
    presentFlutterError: FlutterError.presentError,
  );

  static Future<void> applyStored() {
    return _controller.applyStored();
  }

  static Future<void> setAnalytics(bool enabled, {bool persist = true}) {
    return _controller.setAnalytics(enabled, persist: persist);
  }

  static Future<void> setCrash(bool enabled, {bool persist = true}) {
    if (kIsWeb) {
      if (persist) {
        return Storage.setCrashConsent(enabled);
      }
      return Future<void>.value();
    }
    return _controller.setCrash(enabled, persist: persist);
  }

  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      _controller.handleFlutterError(details, isDebug: kDebugMode);
    };
    PlatformDispatcher.instance.onError = _controller.handlePlatformError;
  }
}
