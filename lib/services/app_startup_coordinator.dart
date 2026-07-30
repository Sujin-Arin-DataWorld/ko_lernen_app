import 'account/cloud_write_session.dart';

typedef FirebaseInitializer = Future<bool> Function();
typedef StartupStep = Future<void> Function();
typedef LiveUserIdReader = String? Function();
typedef CloudWriteSessionRestorer =
    Future<CloudWriteSession?> Function(String expectedUid);
typedef ReadySessionSynchronizer = void Function(String uid);

/// Orders cloud SDK startup without coupling the sequence to Flutter's UI boot.
class AppStartupCoordinator {
  const AppStartupCoordinator({
    required this.initializeFirebase,
    required this.initializeAppCheck,
    required this.ensureSignedIn,
    required this.currentUserId,
    required this.restoreCloudWriteSession,
    required this.synchronizeReadySession,
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
  final CloudWriteSessionRestorer restoreCloudWriteSession;
  final ReadySessionSynchronizer synchronizeReadySession;
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
    await ensureSignedIn();
    final liveUid = currentUserId()?.trim();
    if (liveUid == null || liveUid.isEmpty) {
      return false;
    }
    final restored = await restoreCloudWriteSession(liveUid);
    if (restored != null && restored.mode != CloudWriteMode.ready) {
      await resumeAccountOperation();
      return true;
    }
    synchronizeReadySession(liveUid);
    await resumeBookshelfSync();
    await initializePremium();
    if (notificationsEnabled()) {
      await enablePush();
    }
    return true;
  }
}
