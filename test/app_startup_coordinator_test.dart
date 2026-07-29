import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';

void main() {
  test(
    'waits for Firebase and auth before starting Premium and Push',
    () async {
      final events = <String>[];
      final firebaseGate = Completer<void>();
      final authGate = Completer<void>();
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async {
          events.add('firebase-start');
          await firebaseGate.future;
          events.add('firebase-done');
          return true;
        },
        ensureSignedIn: () async {
          events.add('auth-start');
          await authGate.future;
          events.add('auth-done');
        },
        initializePremium: () async {
          events.add('premium');
        },
        enablePush: () async {
          events.add('push');
        },
        notificationsEnabled: () => true,
      );

      final startup = coordinator.start();
      await Future<void>.delayed(Duration.zero);
      expect(events, <String>['firebase-start']);

      firebaseGate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(events, <String>['firebase-start', 'firebase-done', 'auth-start']);

      authGate.complete();
      expect(await startup, isTrue);
      expect(events, <String>[
        'firebase-start',
        'firebase-done',
        'auth-start',
        'auth-done',
        'premium',
        'push',
      ]);
    },
  );

  test('skips Push when notifications are disabled', () async {
    final events = <String>[];
    final coordinator = AppStartupCoordinator(
      initializeFirebase: () async {
        events.add('firebase');
        return true;
      },
      ensureSignedIn: () async {
        events.add('auth');
      },
      initializePremium: () async {
        events.add('premium');
      },
      enablePush: () async {
        events.add('push');
      },
      notificationsEnabled: () => false,
    );

    expect(await coordinator.start(), isTrue);
    expect(events, <String>['firebase', 'auth', 'premium']);
  });

  test(
    'does not access dependent SDKs when Firebase initialization fails',
    () async {
      final events = <String>[];
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async {
          events.add('firebase');
          return false;
        },
        ensureSignedIn: () async {
          events.add('auth');
        },
        initializePremium: () async {
          events.add('premium');
        },
        enablePush: () async {
          events.add('push');
        },
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isFalse);
      expect(events, <String>['firebase']);
    },
  );
}
