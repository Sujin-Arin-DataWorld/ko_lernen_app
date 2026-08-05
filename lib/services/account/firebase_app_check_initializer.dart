import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseAppCheckActivator =
    Future<void> Function({
      WebProvider? providerWeb,
      required AndroidAppCheckProvider providerAndroid,
      required AppleAppCheckProvider providerApple,
    });

typedef FirebaseAppCheckInitializerFactory =
    FirebaseAppCheckInitializer Function({
      required FirebaseAppCheckActivator activate,
    });

/// Raised before protected Firebase calls when a configured Web app has no
/// build-time App Check reCAPTCHA v3 site key.
class FirebaseAppCheckConfigurationException implements Exception {
  const FirebaseAppCheckConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'FirebaseAppCheckConfigurationException: $message';
}

class FirebaseAppCheckInitializer {
  FirebaseAppCheckInitializer({
    required this.isDebug,
    required this.activate,
    this.isWeb = kIsWeb,
    this.webAppCheckSiteKey = '',
  });

  factory FirebaseAppCheckInitializer.production() {
    return FirebaseAppCheckInitializer.productionWithActivator(
      activate:
          ({providerWeb, required providerAndroid, required providerApple}) {
            return FirebaseAppCheck.instance.activate(
              providerWeb: providerWeb,
              providerAndroid: providerAndroid,
              providerApple: providerApple,
            );
          },
    );
  }

  /// Reuses the production Web key/provider policy for an additional Firebase
  /// app, such as the isolated account-reconciliation target.
  factory FirebaseAppCheckInitializer.productionWithActivator({
    required FirebaseAppCheckActivator activate,
    bool isDebug = kDebugMode,
    bool isWeb = kIsWeb,
    String webAppCheckSiteKey = const String.fromEnvironment(
      'FIREBASE_WEB_APP_CHECK_SITE_KEY',
    ),
  }) {
    return FirebaseAppCheckInitializer(
      isDebug: isDebug,
      isWeb: isWeb,
      webAppCheckSiteKey: webAppCheckSiteKey,
      activate: activate,
    );
  }

  final bool isDebug;
  final bool isWeb;
  final String webAppCheckSiteKey;
  final FirebaseAppCheckActivator activate;

  Future<void> initialize() {
    final WebProvider? providerWeb;
    if (isWeb) {
      final siteKey = webAppCheckSiteKey.trim();
      if (siteKey.isEmpty) {
        throw const FirebaseAppCheckConfigurationException(
          'Web Firebase is configured but FIREBASE_WEB_APP_CHECK_SITE_KEY is missing.',
        );
      }
      providerWeb = ReCaptchaV3Provider(siteKey);
    } else {
      providerWeb = null;
    }

    return activate(
      providerWeb: providerWeb,
      providerAndroid: isDebug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: isDebug
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
}
