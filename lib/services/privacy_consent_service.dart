import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'age_gate_service.dart';
import 'storage_service.dart';

abstract interface class AnalyticsConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
}

abstract interface class CrashConsentClient {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> deleteUnsentReports();
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  });
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
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  }) {
    return FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return FirebaseCrashlytics.instance.recordFlutterFatalError(details);
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
    if (!enabled) {
      if (persist) {
        await persistCrashConsent(false);
      }
      await _disableCrashCollectionAndDeleteReports();
      return;
    }

    if (persist && !wasEnabled) {
      await _deleteCrashReportsRequired();
      await _setCrashCollectionRequired(true);
      try {
        await persistCrashConsent(true);
      } catch (_) {
        await _setCrashCollection(false);
        await _deleteCrashReports();
        rethrow;
      }
      return;
    }

    if (persist) {
      await persistCrashConsent(true);
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
    unawaited(_recordFlutterError(details, presentOnFailure: !isDebug));
  }

  Future<void> _recordFlutterError(
    FlutterErrorDetails details, {
    required bool presentOnFailure,
  }) async {
    try {
      await crashClient.recordFlutterFatalError(details);
    } catch (error) {
      if (presentOnFailure) {
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

    unawaited(_recordPlatformError(error, stack));
    return true;
  }

  Future<void> _recordPlatformError(Object error, StackTrace stack) async {
    try {
      await crashClient.recordError(error, stack, fatal: true);
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

  Future<void> _deleteCrashReportsRequired() {
    return crashClient.deleteUnsentReports();
  }

  Future<void> _setCrashCollectionRequired(bool enabled) {
    return crashClient.setCollectionEnabled(enabled);
  }
}

/// Analytics and Crashlytics remain opt-in. The native collection defaults are
/// disabled; this facade applies and persists the user's runtime decision.
class PrivacyConsentService {
  PrivacyConsentService._();

  /// Notifies live app shells when analytics becomes legally available.
  ///
  /// First-run deliberately asks for analytics only after the learner has
  /// built some trust. The onboarding completion marker therefore stays
  /// pending at the first home frame and is retried when this value becomes
  /// true. It never flips true for an unknown-age user or a self-attested
  /// minor.
  static final ValueNotifier<bool> analyticsEnabled = ValueNotifier<bool>(
    false,
  );

  static final PrivacyConsentController _controller = PrivacyConsentController(
    // DSGVO Art. 8: only a positively passed local age gate can make optional
    // collection effective. Unknown age fails closed just like under-16.
    analyticsConsent: () =>
        Storage.analyticsConsent && AgeGateService.isGyeAllowed,
    crashConsent: () => Storage.crashConsent && AgeGateService.isGyeAllowed,
    persistAnalyticsConsent: Storage.setAnalyticsConsent,
    persistCrashConsent: Storage.setCrashConsent,
    analyticsClient: const FirebaseAnalyticsConsentClient(),
    crashClient: const FirebaseCrashConsentClient(),
    presentFlutterError: FlutterError.presentError,
  );

  static Future<void> applyStored() async {
    await _controller.applyStored();
    analyticsEnabled.value =
        Storage.analyticsConsent && AgeGateService.isGyeAllowed;
  }

  static Future<void> setAnalytics(bool enabled, {bool persist = true}) async {
    // Unknown age and self-attested minors can never activate collection;
    // persist false so the disabled state remains provable.
    final allowed = enabled && AgeGateService.isGyeAllowed;
    await _controller.setAnalytics(allowed, persist: persist);
    analyticsEnabled.value = allowed;
  }

  static Future<void> setCrash(bool enabled, {bool persist = true}) {
    final allowed = enabled && AgeGateService.isGyeAllowed;
    if (kIsWeb) {
      if (persist) {
        return Storage.setCrashConsent(allowed);
      }
      return Future<void>.value();
    }
    return _controller.setCrash(allowed, persist: persist);
  }

  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      _controller.handleFlutterError(details, isDebug: kDebugMode);
    };
    PlatformDispatcher.instance.onError = _controller.handlePlatformError;
  }
}
