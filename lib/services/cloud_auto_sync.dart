import 'package:shared_preferences/shared_preferences.dart';

import 'account/account_failure_diagnostics.dart';
import 'account/cloud_restore_result.dart';
import 'account/cloud_write_session.dart';
import 'auth_service.dart';
import 'cloud_sync.dart';
import 'local_data_lifetime.dart';

/// Best-effort automatic Google/Apple cloud sync at app start.
///
/// Runs additive restore-merge (identical semantics to Settings → Restore)
/// followed by a full backup, at most once per calendar day. Anonymous users
/// are skipped entirely — `cloudBackupUid` is null without a durable link.
///
/// Never invoked inside the cloud-deletion admission lane: the startup
/// coordinator calls it only on the journal-clear path, after bookshelf sync
/// (calling `CloudSync.*` from an `onAdmitted` callback would deadlock the
/// serial `CloudBackupDeletionAuthGate`).
class CloudAutoSync {
  static const lastAutoSyncDayPreferenceKey = 'kl_last_auto_sync_day_v1';

  /// Returns true when a full restore+backup round completed. The daily
  /// throttle is only consumed by a completed backup, so blocked or failed
  /// rounds retry on the next cold start.
  static Future<bool> runStartupSync({
    String? Function()? currentUid,
    Future<CloudRestoreResult> Function()? restore,
    Future<CloudWriteResult> Function()? backup,
    DateTime Function()? now,
    SharedPreferences? preferences,
  }) async {
    final localLifetime = LocalDataLifetime.capture();
    try {
      final uid = (currentUid ?? (() => AuthService.cloudBackupUid))();
      if (uid == null || uid.trim().isEmpty) {
        return false;
      }
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (!localLifetime.isCurrent) {
        return false;
      }
      final today = _dayStamp((now ?? DateTime.now)());
      if (prefs.getString(lastAutoSyncDayPreferenceKey) == today) {
        return false;
      }
      final restoreResult =
          await (restore ??
              () => CloudSync.restoreWithResult(
                localDataLifetime: localLifetime,
              ))();
      if (restoreResult == CloudRestoreResult.blocked ||
          restoreResult == CloudRestoreResult.stale ||
          !localLifetime.isCurrent) {
        return false;
      }
      final backupResult =
          await (backup ??
              () => CloudSync.backupWithResult(
                localDataLifetime: localLifetime,
              ))();
      if (backupResult != CloudWriteResult.completed ||
          !localLifetime.isCurrent) {
        return false;
      }
      final marked = await prefs.setString(lastAutoSyncDayPreferenceKey, today);
      return marked && localLifetime.isCurrent;
    } catch (error) {
      AccountFailureDiagnostics.log('autoSync.failed', error);
      return false;
    }
  }

  static String _dayStamp(DateTime at) {
    final local = at.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
