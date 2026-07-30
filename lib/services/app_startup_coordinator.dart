import 'account/cloud_write_session.dart';

typedef FirebaseInitializer = Future<bool> Function();
typedef StartupStep = Future<void> Function();
typedef LiveUserIdReader = String? Function();
typedef PendingAccountStateRestorer =
    Future<AccountStartupRestoration> Function(String? liveUid);
typedef LegacyCloudWriteSessionRestorer =
    Future<CloudWriteSession?> Function(String expectedUid);
typedef ReadySessionSynchronizer = void Function(String uid);

enum AccountStartupRestorationKind {
  none,
  replacement,
  deletion,
  cloudBackupDeletion,
  localCleanupPending,
  blocked,
}

class AccountStartupRestoration {
  const AccountStartupRestoration.none()
    : kind = AccountStartupRestorationKind.none,
      session = null;

  const AccountStartupRestoration.replacement(this.session)
    : kind = AccountStartupRestorationKind.replacement;

  const AccountStartupRestoration.deletion(this.session)
    : kind = AccountStartupRestorationKind.deletion;

  const AccountStartupRestoration.cloudBackupDeletion(this.session)
    : kind = AccountStartupRestorationKind.cloudBackupDeletion;

  const AccountStartupRestoration.localCleanupPending()
    : kind = AccountStartupRestorationKind.localCleanupPending,
      session = null;

  const AccountStartupRestoration.blocked()
    : kind = AccountStartupRestorationKind.blocked,
      session = null;

  final AccountStartupRestorationKind kind;
  final CloudWriteSession? session;
}

/// Orders cloud SDK startup without coupling the sequence to Flutter's UI boot.
class AppStartupCoordinator {
  const AppStartupCoordinator({
    required this.initializeFirebase,
    required this.initializeAppCheck,
    required this.ensureSignedIn,
    required this.currentUserId,
    this.restorePendingAccountState,
    this.restoreCloudWriteSession,
    required this.synchronizeReadySession,
    required this.resumeMediaCleanup,
    required this.resumeBookshelfSync,
    required this.resumeAccountOperation,
    required this.initializePremium,
    required this.enablePush,
    required this.notificationsEnabled,
  });

  final FirebaseInitializer initializeFirebase;
  final StartupStep initializeAppCheck;
  final StartupStep ensureSignedIn;
  final LiveUserIdReader currentUserId;
  final PendingAccountStateRestorer? restorePendingAccountState;
  final LegacyCloudWriteSessionRestorer? restoreCloudWriteSession;
  final ReadySessionSynchronizer synchronizeReadySession;
  final StartupStep resumeMediaCleanup;
  final StartupStep resumeBookshelfSync;
  final StartupStep resumeAccountOperation;
  final StartupStep initializePremium;
  final StartupStep enablePush;
  final bool Function() notificationsEnabled;

  /// Returns false when Firebase is unavailable. Dependent SDKs are not touched.
  Future<bool> start() async {
    if (!await initializeFirebase()) {
      return false;
    }

    // App Check must be active before auth-derived operation restoration or any
    // other protected Firebase-backed startup step.
    await initializeAppCheck();
    if (restorePendingAccountState case final restore?) {
      final restoration = await restore(currentUserId()?.trim());
      switch (restoration.kind) {
        case AccountStartupRestorationKind.replacement:
        case AccountStartupRestorationKind.cloudBackupDeletion:
        case AccountStartupRestorationKind.localCleanupPending:
        case AccountStartupRestorationKind.blocked:
          return true;
        case AccountStartupRestorationKind.deletion:
          if (restoration.session != null) {
            await resumeAccountOperation();
          }
          return true;
        case AccountStartupRestorationKind.none:
          break;
      }
    }

    await ensureSignedIn();
    final liveUid = currentUserId()?.trim();
    if (liveUid == null || liveUid.isEmpty) {
      return false;
    }
    if (restoreCloudWriteSession case final legacyRestore?) {
      final restored = await legacyRestore(liveUid);
      if (restored != null) {
        await resumeAccountOperation();
        return true;
      }
    }
    synchronizeReadySession(liveUid);
    await resumeMediaCleanup();
    await resumeBookshelfSync();
    await initializePremium();
    if (notificationsEnabled()) {
      await enablePush();
    }
    return true;
  }
}
