import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'account_transition_journal.dart';
import 'cloud_write_session.dart';

typedef AccountTransitionJournalReader =
    Future<AccountTransitionJournal?> Function();

class SharedPreferencesAccountTransitionJournalReader {
  const SharedPreferencesAccountTransitionJournalReader();

  static const key = AccountTransitionJournal.storageKey;

  Future<AccountTransitionJournal?> call() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final raw = preferences.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid account transition journal.');
    }
    return AccountTransitionJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

enum _MediaCleanupAuthorization { localOnly, ready, reconciled }

/// Authorizes irreversible media cleanup against both volatile session state
/// and the durable account-transition journal.
///
/// A missing in-memory session is not sufficient proof that an account
/// transition is absent: immediately after process restart the journal can be
/// restored before the session controller is rehydrated.
class MediaCleanupGate {
  const MediaCleanupGate(this.sessions);

  final CloudWriteSessionController sessions;

  Future<CloudWriteResult> run({
    String? uid,
    CloudWriteSession? session,
    required AccountTransitionJournalReader readJournal,
    bool provenLocalOnly = false,
    required Future<void> Function() prepare,
    required Future<void> Function() delete,
  }) async {
    final selectedSession = session ?? sessions.current;
    final initial = await _authorize(
      uid: uid,
      session: selectedSession,
      readJournal: readJournal,
      provenLocalOnly: provenLocalOnly,
    );
    if (initial.result != CloudWriteResult.completed) {
      return initial.result;
    }

    await prepare();

    final beforeDelete = await _authorize(
      uid: uid,
      session: selectedSession,
      readJournal: readJournal,
      provenLocalOnly: provenLocalOnly,
      expected: initial.authorization,
    );
    if (beforeDelete.result != CloudWriteResult.completed) {
      return beforeDelete.result;
    }

    try {
      await delete();
    } catch (error, stackTrace) {
      final afterFailure = await _authorize(
        uid: uid,
        session: selectedSession,
        readJournal: readJournal,
        provenLocalOnly: provenLocalOnly,
        expected: initial.authorization,
      );
      if (afterFailure.result != CloudWriteResult.completed) {
        return afterFailure.result;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    final afterDelete = await _authorize(
      uid: uid,
      session: selectedSession,
      readJournal: readJournal,
      provenLocalOnly: provenLocalOnly,
      expected: initial.authorization,
    );
    return afterDelete.result;
  }

  Future<_AuthorizationResult> _authorize({
    required String? uid,
    required CloudWriteSession? session,
    required AccountTransitionJournalReader readJournal,
    required bool provenLocalOnly,
    _MediaCleanupAuthorization? expected,
  }) async {
    AccountTransitionJournal? journal;
    try {
      journal = await readJournal();
    } on Object {
      return const _AuthorizationResult(CloudWriteResult.blocked);
    }

    if (session == null) {
      if (sessions.current != null ||
          sessions.hasBeenActivated ||
          !provenLocalOnly ||
          journal != null) {
        return const _AuthorizationResult(CloudWriteResult.blocked);
      }
      return _matchExpected(_MediaCleanupAuthorization.localOnly, expected);
    }

    if (uid == null || uid.trim().isEmpty || session.uid != uid) {
      return const _AuthorizationResult(CloudWriteResult.stale);
    }
    if (!_isCurrent(session)) {
      return const _AuthorizationResult(CloudWriteResult.stale);
    }

    if (journal == null) {
      if (session.mode != CloudWriteMode.ready) {
        return const _AuthorizationResult(CloudWriteResult.blocked);
      }
      return _matchExpected(_MediaCleanupAuthorization.ready, expected);
    }

    if (journal.session != session ||
        journal.reconciliationCheckpoint !=
            ReconciliationCheckpoint.completed) {
      return const _AuthorizationResult(CloudWriteResult.blocked);
    }
    return _matchExpected(_MediaCleanupAuthorization.reconciled, expected);
  }

  _AuthorizationResult _matchExpected(
    _MediaCleanupAuthorization authorization,
    _MediaCleanupAuthorization? expected,
  ) {
    if (expected != null && expected != authorization) {
      return const _AuthorizationResult(CloudWriteResult.blocked);
    }
    return _AuthorizationResult(
      CloudWriteResult.completed,
      authorization: authorization,
    );
  }

  bool _isCurrent(CloudWriteSession session) {
    try {
      sessions.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }
}

class _AuthorizationResult {
  const _AuthorizationResult(this.result, {this.authorization});

  final CloudWriteResult result;
  final _MediaCleanupAuthorization? authorization;
}
