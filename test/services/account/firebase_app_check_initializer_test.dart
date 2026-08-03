import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/firebase_app_check_initializer.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';

void main() {
  group('FirebaseAppCheckInitializer', () {
    test('uses the configured reCAPTCHA v3 provider on the web', () async {
      Object? capturedWebProvider;
      AndroidProvider? capturedAndroidProvider;
      AppleProvider? capturedAppleProvider;
      final initializer = FirebaseAppCheckInitializer(
        isDebug: false,
        isWeb: true,
        webAppCheckSiteKey: 'test-site-key',
        activate:
            ({
              webProvider,
              required androidProvider,
              required appleProvider,
            }) async {
              capturedWebProvider = webProvider;
              capturedAndroidProvider = androidProvider;
              capturedAppleProvider = appleProvider;
            },
      );

      await initializer.initialize();

      expect(capturedWebProvider, isA<ReCaptchaV3Provider>());
      expect(
        (capturedWebProvider as ReCaptchaV3Provider).siteKey,
        'test-site-key',
      );
      expect(capturedAndroidProvider, AndroidProvider.playIntegrity);
      expect(
        capturedAppleProvider,
        AppleProvider.appAttestWithDeviceCheckFallback,
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
              webProvider,
              required androidProvider,
              required appleProvider,
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
                webProvider,
                required androidProvider,
                required appleProvider,
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
              webProvider,
              required androidProvider,
              required appleProvider,
            }) async {
              capturedWebProvider = webProvider;
              expect(androidProvider, AndroidProvider.debug);
              expect(appleProvider, AppleProvider.debug);
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
                webProvider,
                required androidProvider,
                required appleProvider,
              }) async {
                capturedWebProvider = webProvider;
                expect(androidProvider, AndroidProvider.playIntegrity);
                expect(
                  appleProvider,
                  AppleProvider.appAttestWithDeviceCheckFallback,
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
              webProvider,
              required androidProvider,
              required appleProvider,
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
