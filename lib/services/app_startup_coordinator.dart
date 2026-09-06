import 'account/cloud_write_session.dart';

typedef FirebaseInitializer = Future<bool> Function();
typedef StartupStep = Future<void> Function();
typedef LiveUserIdReader = String? Function();
typedef PendingAccountStateRestorer =
    Future<AccountStartupRestoration> Function(String? liveUid);
typedef LegacyCloudWriteSessionRestorer =
    Future<CloudWriteSession?> Function(String expectedUid);
typedef ReadySessionSynchronizer = void Function(String uid);

Future<void> _noopStartupStep() async {}

enum AccountStartupRestorationKind {
  none,
  switchPending,
  deletion,
  deletionReceiptPending,
  cloudBackupDeletion,
  localCleanupPending,
  feedbackActivationPending,
  blocked,
}

class AccountStartupRestoration {
  const AccountStartupRestoration.none()
    : kind = AccountStartupRestorationKind.none,
      session = null;

  const AccountStartupRestoration.switchPending()
    : kind = AccountStartupRestorationKind.switchPending,
      session = null;

  const AccountStartupRestoration.deletion(this.session)
    : kind = AccountStartupRestorationKind.deletion;

  const AccountStartupRestoration.deletionReceiptPending()
    : kind = AccountStartupRestorationKind.deletionReceiptPending,
      session = null;

  const AccountStartupRestoration.cloudBackupDeletion(this.session)
    : kind = AccountStartupRestorationKind.cloudBackupDeletion;

  const AccountStartupRestoration.localCleanupPending()
    : kind = AccountStartupRestorationKind.localCleanupPending,
      session = null;

  const AccountStartupRestoration.feedbackActivationPending()
    : kind = AccountStartupRestorationKind.feedbackActivationPending,
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
    this.resumeFeedbackOutbox = _noopStartupStep,
    this.resumeFirstDurableLinkBackfill = _noopStartupStep,
    this.resumeCompletedFeedbackActivation = _noopStartupStep,
    this.resumeCloudBackupDeletion = _noopStartupStep,
    this.resumeCloudAutoSync = _noopStartupStep,
    this.resumeAccountDeletionByReceipt = _noopStartupStep,
    this.resumeAccountSwitch = _noopStartupStep,
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
  final StartupStep resumeFeedbackOutbox;
  final StartupStep resumeFirstDurableLinkBackfill;
  final StartupStep resumeCompletedFeedbackActivation;
  final StartupStep resumeCloudBackupDeletion;
  final StartupStep resumeCloudAutoSync;
  final StartupStep resumeAccountDeletionByReceipt;
  final StartupStep resumeAccountSwitch;
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
        case AccountStartupRestorationKind.blocked:
          return true;
        case AccountStartupRestorationKind.switchPending:
          // The switch already signed the primary auth into the target
          // account before the crash/kill; sign back in and best-effort
          // resume the merge, then fall through to normal startup — a
          // deferred merge leaves the session `reconciling`, which
          // synchronizeReadySession below already treats as `blocked`.
          await ensureSignedIn();
          try {
            await resumeAccountSwitch();
          } catch (_) {
            // Logged inside AuthService.resumePendingAccountSwitch.
          }
          break;
        case AccountStartupRestorationKind.cloudBackupDeletion:
          // The persisted cloud-backup deletion owns startup, but its exact
          // request may safely resume here: the journal's request key is
          // idempotent server-side and resume never starts a new deletion.
          if (restoration.session != null) {
            await resumeCloudBackupDeletion();
          }
          return true;
        case AccountStartupRestorationKind.localCleanupPending:
          // The server deletion is complete, but destructive local cleanup is
          // not durably proven. Keep startup fenced for an explicit retry;
          // automatic cleanup could erase data created after an earlier crash.
          return true;
        case AccountStartupRestorationKind.feedbackActivationPending:
          // The handoff marker is written only after local cleanup finishes.
          // Finalizing it is non-destructive and may safely resume at startup.
          // A cold start can have no Firebase identity yet; create the fresh
          // anonymous replacement before the finalizer verifies it. Other
          // journal kinds stay fenced before authentication is touched.
          final currentUid = currentUserId()?.trim();
          if (currentUid == null || currentUid.isEmpty) {
            await ensureSignedIn();
          }
          await resumeCompletedFeedbackActivation();
          final afterActivation = await restore(currentUserId()?.trim());
          if (afterActivation.kind != AccountStartupRestorationKind.none) {
            return true;
          }
          break;
        case AccountStartupRestorationKind.deletion:
          // A receipt-less legacy deletion checkpoint only fences startup.
          // Its authenticated resume may reach Apple token revocation and
          // therefore must remain an explicit Settings action; cold startup
          // must never surprise the user with provider OAuth. Receipt-backed
          // deletions use the capability-only status path below instead.
          return true;
        case AccountStartupRestorationKind.deletionReceiptPending:
          // The user-visible deletion already finished on this device (the
          // Auth identity is already gone, and local cleanup either already
          // ran or fences separately). This is now silent, best-effort
          // background verification only — it must not fence the rest of
          // startup. Run it before ensureSignedIn() below creates any
          // replacement identity, then fall through to normal startup.
          await resumeAccountDeletionByReceipt();
          break;
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
    // This is reachable only when every durable account journal was clear.
    // The production feedback service performs its own fresh deletion-state
    // read as a second gate before touching secure outbox contents.
    await resumeFeedbackOutbox();
    await resumeFirstDurableLinkBackfill();
    await resumeMediaCleanup();
    await resumeBookshelfSync();
    // Reachable only when every durable account journal was clear, so the
    // sync cannot race a deletion resume in the admission lane.
    await resumeCloudAutoSync();
    await initializePremium();
    if (notificationsEnabled()) {
      await enablePush();
    }
    return true;
  }
}
