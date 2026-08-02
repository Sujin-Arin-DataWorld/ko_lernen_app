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
      restorePendingAccountState: (liveUid) async {
        events.add('restore:$liveUid');
        return const AccountStartupRestoration.none();
      },
      synchronizeReadySession: (uid) => events.add('ready:$uid'),
      resumeFeedbackOutbox: () async => events.add('feedback-resume'),
      resumeFirstDurableLinkBackfill: () async =>
          events.add('first-link-resume'),
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
      'restore:uid-live',
      'auth',
      'ready:uid-live',
      'feedback-resume',
      'first-link-resume',
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
        restorePendingAccountState: (liveUid) async {
          events.add('restore:$liveUid');
          return AccountStartupRestoration.deletion(restored);
        },
        synchronizeReadySession: (uid) => events.add('ready:$uid'),
        resumeFeedbackOutbox: () async => events.add('feedback-resume'),
        resumeMediaCleanup: () async => events.add('media-resume'),
        resumeBookshelfSync: () async => events.add('bookshelf-resume'),
        resumeAccountOperation: () async => events.add('resume-existing'),
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, ['app-check', 'restore:uid-live', 'resume-existing']);
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
      restorePendingAccountState: (_) async =>
          const AccountStartupRestoration.none(),
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

  test(
    'replacement journal fences startup before auth creation or ready sync',
    () async {
      final events = <String>[];
      final restored = const CloudWriteSession(
        uid: 'anonymous-source',
        epoch: 12,
        mode: CloudWriteMode.reconciling,
      );
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async => events.add('auth-create'),
        currentUserId: () => 'anonymous-source',
        restorePendingAccountState: (liveUid) async {
          events.add('restore:$liveUid');
          return AccountStartupRestoration.replacement(restored);
        },
        synchronizeReadySession: (uid) => events.add('ready:$uid'),
        resumeMediaCleanup: () async => events.add('media'),
        resumeBookshelfSync: () async => events.add('bookshelf'),
        resumeAccountOperation: () async => events.add('deletion-resume'),
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, <String>['app-check', 'restore:anonymous-source']);
    },
  );

  test('blocked or malformed journal never unfreezes writers', () async {
    final events = <String>[];
    final coordinator = AppStartupCoordinator(
      initializeFirebase: () async => true,
      initializeAppCheck: () async => events.add('app-check'),
      ensureSignedIn: () async => events.add('auth-create'),
      currentUserId: () => null,
      restorePendingAccountState: (liveUid) async {
        events.add('restore:${liveUid ?? 'none'}');
        return const AccountStartupRestoration.blocked();
      },
      synchronizeReadySession: (uid) => events.add('ready:$uid'),
      resumeMediaCleanup: () async => events.add('media'),
      resumeBookshelfSync: () async => events.add('bookshelf'),
      resumeAccountOperation: () async => events.add('deletion-resume'),
      initializePremium: () async => events.add('premium'),
      enablePush: () async => events.add('push'),
      notificationsEnabled: () => true,
    );

    expect(await coordinator.start(), isTrue);
    expect(events, <String>['app-check', 'restore:none']);
  });

  test(
    'remote-complete local cleanup stays fenced for manual recovery',
    () async {
      final events = <String>[];
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async => events.add('auth-create'),
        currentUserId: () => 'new-anonymous',
        restorePendingAccountState: (_) async {
          events.add('restore');
          return const AccountStartupRestoration.localCleanupPending();
        },
        synchronizeReadySession: (uid) => events.add('ready:$uid'),
        resumeFeedbackOutbox: () async => events.add('feedback-resume'),
        resumeMediaCleanup: () async => events.add('media'),
        resumeBookshelfSync: () async => events.add('bookshelf'),
        resumeAccountOperation: () async => events.add('remote-delete-resume'),
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, <String>['app-check', 'restore']);
    },
  );

  test(
    'feedback activation finalization rechecks then continues normal startup',
    () async {
      final events = <String>[];
      var activationPending = true;
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async => events.add('auth-create'),
        currentUserId: () => 'new-anonymous',
        restorePendingAccountState: (_) async {
          events.add('restore');
          return activationPending
              ? const AccountStartupRestoration.feedbackActivationPending()
              : const AccountStartupRestoration.none();
        },
        synchronizeReadySession: (_) => events.add('ready'),
        resumeMediaCleanup: () async => events.add('media'),
        resumeBookshelfSync: () async => events.add('bookshelf'),
        resumeAccountOperation: () async => events.add('pending-remote'),
        resumeCompletedFeedbackActivation: () async {
          events.add('activation-finalize');
          activationPending = false;
        },
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, <String>[
        'app-check',
        'restore',
        'activation-finalize',
        'restore',
        'auth-create',
        'ready',
        'media',
        'bookshelf',
        'premium',
        'push',
      ]);
    },
  );

  test(
    'marker activation creates an anonymous identity before finalization',
    () async {
      final events = <String>[];
      String? liveUid;
      var activationPending = true;
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async {
          events.add('auth-create');
          liveUid = 'new-anonymous';
        },
        currentUserId: () => liveUid,
        restorePendingAccountState: (uid) async {
          events.add('restore:${uid ?? 'none'}');
          return activationPending
              ? const AccountStartupRestoration.feedbackActivationPending()
              : const AccountStartupRestoration.none();
        },
        synchronizeReadySession: (uid) => events.add('ready:$uid'),
        resumeMediaCleanup: () async => events.add('media'),
        resumeBookshelfSync: () async => events.add('bookshelf'),
        resumeAccountOperation: () async => events.add('pending-remote'),
        resumeCompletedFeedbackActivation: () async {
          events.add('activation-finalize:$liveUid');
          activationPending = false;
        },
        initializePremium: () async => events.add('premium'),
        enablePush: () async => events.add('push'),
        notificationsEnabled: () => true,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, <String>[
        'app-check',
        'restore:none',
        'auth-create',
        'activation-finalize:new-anonymous',
        'restore:new-anonymous',
        'auth-create',
        'ready:new-anonymous',
        'media',
        'bookshelf',
        'premium',
        'push',
      ]);
    },
  );

  test(
    'pending remote deletion never runs completed cleanup recovery',
    () async {
      final events = <String>[];
      const restored = CloudWriteSession(
        uid: 'deleted-source',
        epoch: 13,
        mode: CloudWriteMode.cleanupPending,
      );
      final coordinator = AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async => events.add('app-check'),
        ensureSignedIn: () async => events.add('auth-create'),
        currentUserId: () => 'deleted-source',
        restorePendingAccountState: (_) async =>
            const AccountStartupRestoration.deletion(restored),
        synchronizeReadySession: (_) {},
        resumeMediaCleanup: () async {},
        resumeBookshelfSync: () async {},
        resumeAccountOperation: () async => events.add('remote-delete-resume'),
        initializePremium: () async {},
        enablePush: () async {},
        notificationsEnabled: () => false,
      );

      expect(await coordinator.start(), isTrue);
      expect(events, <String>['app-check', 'remote-delete-resume']);
    },
  );
}
