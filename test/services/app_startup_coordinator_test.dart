import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';

void main() {
  test('activates App Check before any protected startup call', () async {
    final events = <String>[];
    final coordinator = AppStartupCoordinator(
      initializeFirebase: () async {
        events.add('firebase');
        return true;
      },
      initializeAppCheck: () async => events.add('app-check'),
      ensureSignedIn: () async => events.add('auth'),
      currentUserId: () => 'uid-live',
      restoreCloudWriteSession: (expectedUid) async {
        events.add('restore:$expectedUid');
        return null;
      },
      synchronizeReadySession: (uid) => events.add('ready:$uid'),
      resumeMediaCleanup: () async => events.add('media-resume'),
      resumeBookshelfSync: () async => events.add('bookshelf-resume'),
      resumeAccountOperation: () async => events.add('protected-resume'),
      initializePremium: () async => events.add('premium'),
      enablePush: () async => events.add('push'),
      notificationsEnabled: () => true,
    );

    expect(await coordinator.start(), isTrue);
    expect(events, [
      'firebase',
      'app-check',
      'auth',
      'restore:uid-live',
      'ready:uid-live',
      'media-resume',
      'bookshelf-resume',
      'premium',
      'push',
    ]);
    expect(events.indexOf('app-check'), lessThan(events.indexOf('premium')));
  });

  test(
    'restores with live auth UID and resumes a frozen operation only',
    () async {
      final events = <String>[];
      final restored = const CloudWriteSession(
        uid: 'uid-live',
        epoch: 7,
        mode: CloudWriteMode.blocked,
      );
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async => events.add('auth'),
        currentUserId: () => 'uid-live',
        restoreCloudWriteSession: (expectedUid) async {
          events.add('restore:$expectedUid');
          return restored;
        },
        synchronizeReadySession: (uid) => events.add('ready:$uid'),
        resumeMediaCleanup: () async => events.add('media-resume'),
        resumeBookshelfSync: () async => events.add('bookshelf-resume'),
        resumeAccountOperation: () async => events.add('resume-existing'),
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, [
        'app-check',
        'auth',
        'restore:uid-live',
        'resume-existing',
      ]);
    },
  );

  test('does not touch Firebase-backed startup when App Check fails', () async {
    final events = <String>[];
    final coordinator = AppStartupCoordinator(
      initializeFirebase: () async => true,
      initializeAppCheck: () async {
        events.add('app-check');
        throw StateError('activation failed');
      },
      ensureSignedIn: () async => events.add('auth'),
      currentUserId: () => 'uid-live',
      restoreCloudWriteSession: (_) async => null,
      synchronizeReadySession: (_) {},
      resumeMediaCleanup: () async => events.add('media-resume'),
      resumeBookshelfSync: () async => events.add('bookshelf-resume'),
      resumeAccountOperation: () async => events.add('resume'),
      initializePremium: () async => events.add('premium'),
      enablePush: () async => events.add('push'),
      notificationsEnabled: () => true,
    );

    await expectLater(coordinator.start(), throwsStateError);
    expect(events, ['app-check']);
  });
}
