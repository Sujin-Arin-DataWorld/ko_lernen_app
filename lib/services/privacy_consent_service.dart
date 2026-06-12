import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// **PrivacyConsentService** — Analytics/Crashlytics **Opt-in** (TTDSG §25,
/// DSGVO Art. 7).
///
/// Die SDK-Erhebung ist im AndroidManifest / Info.plist deaktiviert
/// (`firebase_analytics_collection_enabled=false` usw.) und wird **nur** nach
/// expliziter Einwilligung zur Laufzeit aktiviert. Einwilligung ist jederzeit
/// in den Einstellungen widerrufbar (DSGVO Art. 7 Abs. 3).
///
/// Quelle der Wahrheit: [Storage.analyticsConsent] / [Storage.crashConsent]
/// (Default false). [applyStored] stellt den Zustand nach jedem App-Start
/// wieder her, da die Manifest-Flags die Erhebung sonst dauerhaft blockieren.
class PrivacyConsentService {
  PrivacyConsentService._();

  /// Gespeicherte Einwilligung auf die Firebase-SDKs anwenden.
  /// Nach `Firebase.initializeApp()` aufrufen (best-effort, wirft nie).
  static Future<void> applyStored() async {
    await setAnalytics(Storage.analyticsConsent, persist: false);
    await setCrash(Storage.crashConsent, persist: false);
  }

  /// Analytics-Einwilligung setzen (+ optional persistieren).
  static Future<void> setAnalytics(bool enabled, {bool persist = true}) async {
    if (persist) {
      await Storage.setAnalyticsConsent(enabled);
    }
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      // Firebase nicht initialisiert (z. B. Web-Dev ohne Config) → still.
      debugPrint('PrivacyConsent: analytics toggle skipped — $e');
    }
  }

  /// Crashlytics-Einwilligung setzen (+ optional persistieren).
  static Future<void> setCrash(bool enabled, {bool persist = true}) async {
    if (persist) {
      await Storage.setCrashConsent(enabled);
    }
    if (kIsWeb) {
      return; // Crashlytics wird auf Web nicht unterstützt.
    }
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
    } catch (e) {
      debugPrint('PrivacyConsent: crashlytics toggle skipped — $e');
    }
  }
}
