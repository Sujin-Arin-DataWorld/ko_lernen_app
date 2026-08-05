import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/firebase_app_check_initializer.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';

void main() {
  group('FirebaseAppCheckInitializer', () {
    test('uses the configured reCAPTCHA v3 provider on the web', () async {
      Object? capturedWebProvider;
      AndroidAppCheckProvider? capturedAndroidProvider;
      AppleAppCheckProvider? capturedAppleProvider;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: false,
        isWeb: true,
        webAppCheckSiteKey: 'test-site-key',
        activate:
            ({
              providerWeb,
              required providerAndroid,
              required providerApple,
            }) async {
              capturedWebProvider = providerWeb;
              capturedAndroidProvider = providerAndroid;
              capturedAppleProvider = providerApple;
            },
      );

      await initializer.initialize();

      expect(capturedWebProvider, isA<ReCaptchaV3Provider>());
      expect(
        (capturedWebProvider as ReCaptchaV3Provider).siteKey,
        'test-site-key',
      );
      expect(capturedAndroidProvider, isA<AndroidPlayIntegrityProvider>());
      expect(
        capturedAppleProvider,
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
    });

    test('fails closed on the web when the App Check site key is absent', () {
      var activationCount = 0;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: false,
        isWeb: true,
        webAppCheckSiteKey: '  ',
        activate:
            ({
              providerWeb,
              required providerAndroid,
              required providerApple,
            }) async {
              activationCount += 1;
            },
      );

      expect(
        initializer.initialize,
        throwsA(isA<FirebaseAppCheckConfigurationException>()),
      );
      expect(activationCount, 0);
    });

    test(
      'missing Web key stops protected cloud startup after Firebase',
      () async {
        final events = <String>[];
        final initializer = FirebaseAppCheckInitializer(
          isDebug: false,
          isWeb: true,
          webAppCheckSiteKey: '',
          activate:
              ({
                providerWeb,
                required providerAndroid,
                required providerApple,
              }) async {
                events.add('activate');
              },
        );
        final coordinator = AppStartupCoordinator(
          initializeFirebase: () async {
            events.add('firebase');
            return true;
          },
          initializeAppCheck: initializer.initialize,
          ensureSignedIn: () async => events.add('auth'),
          currentUserId: () => 'uid-live',
          synchronizeReadySession: (uid) => events.add('ready:$uid'),
          resumeMediaCleanup: () async => events.add('media'),
          resumeBookshelfSync: () async => events.add('bookshelf'),
          resumeAccountOperation: () async => events.add('account-operation'),
          initializePremium: () async => events.add('premium'),
          enablePush: () async => events.add('push'),
          notificationsEnabled: () => true,
        );

        await expectLater(
          coordinator.start(),
          throwsA(isA<FirebaseAppCheckConfigurationException>()),
        );

        expect(events, ['firebase']);
      },
    );

    test('does not pass a web provider to Android or Apple builds', () async {
      Object? capturedWebProvider;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: true,
        isWeb: false,
        webAppCheckSiteKey: 'not-used-on-native',
        activate:
            ({
              providerWeb,
              required providerAndroid,
              required providerApple,
            }) async {
              capturedWebProvider = providerWeb;
              expect(providerAndroid, isA<AndroidDebugProvider>());
              expect(providerApple, isA<AppleDebugProvider>());
            },
      );

      await initializer.initialize();

      expect(capturedWebProvider, isNull);
    });

    test(
      'uses the production Web provider configuration for a secondary app',
      () async {
        Object? capturedWebProvider;
        final initializer = FirebaseAppCheckInitializer.productionWithActivator(
          isDebug: false,
          isWeb: true,
          webAppCheckSiteKey: 'secondary-test-site-key',
          activate:
              ({
                providerWeb,
                required providerAndroid,
                required providerApple,
              }) async {
                capturedWebProvider = providerWeb;
                expect(providerAndroid, isA<AndroidPlayIntegrityProvider>());
                expect(
                  providerApple,
                  isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
                );
              },
        );

        await initializer.initialize();

        expect(capturedWebProvider, isA<ReCaptchaV3Provider>());
        expect(
          (capturedWebProvider as ReCaptchaV3Provider).siteKey,
          'secondary-test-site-key',
        );
      },
    );

    test('secondary app activation fails closed without the Web site key', () {
      var activationCount = 0;
      final initializer = FirebaseAppCheckInitializer.productionWithActivator(
        isDebug: false,
        isWeb: true,
        webAppCheckSiteKey: '',
        activate:
            ({
              providerWeb,
              required providerAndroid,
              required providerApple,
            }) async {
              activationCount += 1;
            },
      );

      expect(
        initializer.initialize,
        throwsA(isA<FirebaseAppCheckConfigurationException>()),
      );
      expect(activationCount, 0);
    });
  });
}
