typedef FirebaseInitializer = Future<bool> Function();
typedef StartupStep = Future<void> Function();

/// Orders cloud SDK startup without coupling the sequence to Flutter's UI boot.
class AppStartupCoordinator {
  const AppStartupCoordinator({
    required this.initializeFirebase,
    required this.ensureSignedIn,
    required this.initializePremium,
    required this.enablePush,
    required this.notificationsEnabled,
  });

  final FirebaseInitializer initializeFirebase;
  final StartupStep ensureSignedIn;
  final StartupStep initializePremium;
  final StartupStep enablePush;
  final bool Function() notificationsEnabled;

  /// Returns false when Firebase is unavailable. Dependent SDKs are not touched.
  Future<bool> start() async {
    if (!await initializeFirebase()) {
      return false;
    }

    await ensureSignedIn();
    await initializePremium();
    if (notificationsEnabled()) {
      await enablePush();
    }
    return true;
  }
}
