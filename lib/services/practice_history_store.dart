import 'package:flutter/foundation.dart';
import '../models/practice_history.dart';
import 'auth_service.dart';
import 'account/cloud_write_session.dart';
import 'local_data_lifetime.dart';
import 'storage_service.dart';

/// Captured when a screen opens, not after its async completion.
class PracticeHistorySession {
  PracticeHistorySession()
    : _lifetime = LocalDataLifetime.capture(),
      _uid = AuthService.cloudBackupUid,
      _identityEpoch = cloudWriteSessionController.identityEpoch;
  final LocalDataLifetimeLease _lifetime;
  final String? _uid;
  final int _identityEpoch;
  bool get isCurrent =>
      _lifetime.isCurrent &&
      _uid == AuthService.cloudBackupUid &&
      _identityEpoch == cloudWriteSessionController.identityEpoch;
  void assertCurrent() {
    if (!isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
  }
}

abstract final class PracticeHistoryStore {
  static ValueNotifier<int> get changes => Storage.hanokPracticeChanges;
  static PracticeHistorySession session() => PracticeHistorySession();
  static PracticeHistory load() =>
      PracticeHistory.decode(Storage.hanokPracticeRawJson);
  static Future<void> recordViewed(
    PracticeSource source, {
    DateTime? at,
    PracticeHistorySession? session,
  }) {
    final guard = session ?? PracticeHistoryStore.session();
    final item = PracticeItem(
      source: source,
      viewedAt: (at ?? DateTime.now()).toUtc(),
    );
    return _record(item, guard, null);
  }

  static Future<void> recordAttempt(
    PracticeSource source,
    PracticeAttempt attempt, {
    PracticeHistorySession? session,
    PreferenceStringStore? preferences,
  }) {
    // Validate caller data with the same contract used by backup/restore.
    final item = PracticeItem.fromJson(
      PracticeItem(
        source: source,
        assisted: attempt.usedHelp ? attempt : null,
        independent: attempt.usedHelp ? null : attempt,
      ).toJson(),
    );
    return _record(
      item,
      session ?? PracticeHistoryStore.session(),
      preferences,
    );
  }

  static Future<void> _record(
    PracticeItem item,
    PracticeHistorySession session,
    PreferenceStringStore? preferences,
  ) => Storage.mutateHanokPractice(
    (raw) => PracticeHistory.decode(raw).add(item).encode(),
    preferences: preferences,
    assertCurrentWrite: session.assertCurrent,
  );
  static Future<void> mergeCloudJson(
    String raw, {
    void Function()? beforeWrite,
  }) async {
    PracticeHistory.decode(raw);
    await Storage.mutateHanokPractice(
      (local) => PracticeHistory.mergeJson(local, raw),
      assertCurrentWrite: beforeWrite,
    );
  }

  static Future<void> refresh() => Storage.mutateHanokPractice((raw) {
    PracticeHistory.decode(raw);
    return raw;
  });
}
