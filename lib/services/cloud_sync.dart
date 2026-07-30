import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'account/cloud_read_result.dart';
import 'account/cloud_restore_result.dart';
import 'account/cloud_write_session.dart';
import 'auth_service.dart';
import 'bookshelf_service.dart';
import 'cloud_sync_service.dart';
import 'firestore_progress_service.dart';
import 'pack_progress_service.dart';
import 'storage_service.dart';

/// 1-Weg-Sync: Storage (lokal) ↔ Firestore (Cloud, `users/{uid}`).
///
/// - Local = source of truth während des Spielens.
/// - Backup: lokale Werte → Firestore.
/// - Restore: Firestore → lokale Werte — **additiv / max-merge, kein Clobber**.
///
/// Felder: Spiel-Statistik (vok/chosung/wordle/grammar/app) + **Fortschritt
/// (xp/level/stamps/quests) + SRS-Deck + Custom-Packs + Bücherregal**
/// (sonst Verlust bei Reinstall/Gerätewechsel). packs werden separat von
/// `firestore_progress_service` synchronisiert → hier nicht dupliziert.
/// Bookshelf data is canonical in immutable generations owned by
/// `BookshelfService`. `bookshelf_json` is accepted only as legacy restore
/// input and is never emitted by this root-document writer.
class CloudSync {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static Future<CloudWriteResult> Function()? _backupWithResultForTesting;
  static Future<CloudRestoreResult> Function()? _restoreWithResultForTesting;
  static Future<bool> Function()? _restoreForTesting;

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  /// Reines Backup-Payload (ohne Firestore-I/O, ohne `updated_at`) — testbar.
  static Map<String, dynamic> buildBackupPayload() {
    final payload = <String, dynamic>{
      'vok': {
        'correct': Storage.vokCorrect,
        'wrong': Storage.vokWrong,
        'skipped': Storage.vokSkipped,
        'last_idx': Storage.vokLastIdx,
        'seen_ids': Storage.vokSeenIds,
      },
      'chosung': {
        'correct': Storage.chosungCorrect,
        'wrong': Storage.chosungWrong,
      },
      'wordle': {
        'wins': Storage.wordleWins,
        'losses': Storage.wordleLosses,
        'streak': Storage.wordleStreak,
        'best_streak': Storage.wordleBestStreak,
      },
      'grammar': {
        'last_idx': Storage.grammarLastIdx,
        'seen': Storage.grammarSeen,
      },
      'app': {
        'last_open': Storage.lastOpenDate,
        'streak_days': Storage.streakDays,
        'best_streak': Storage.bestStreak,
      },
      // Phase 1~8 Fortschritt (Reinstall/Gerätewechsel-Schutz).
      'progress': {
        'xp': Storage.xp,
        'level': Storage.userLevelCode,
        'earned_stamps': Storage.earnedStamps,
        'quest_completions': Storage.questCompletions,
      },
      'srs_json': Storage.srsRawJson,
    };
    final customPacks = _portableStructuredJson(
      Storage.customPacksRawJson,
      stripBookshelfThumbnail: false,
    );
    if (customPacks != null) {
      payload['custom_packs_json'] = customPacks;
    }
    return payload;
  }

  /// Lokale Werte → Firestore. Idempotent.
  static Future<void> backup() async {
    await backupWithResult();
  }

  static Future<CloudWriteResult> backupWithResult() {
    return AuthService.runCloudBackupDeletionAdmission(
      onAdmitted: _backupWithResultAfterCloudBackupAdmission,
      onBlocked: () async => CloudWriteResult.blocked,
    );
  }

  static Future<CloudWriteResult>
  _backupWithResultAfterCloudBackupAdmission() async {
    final override = _backupWithResultForTesting;
    if (override != null) return override();
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      return CloudWriteResult.blocked;
    }
    DocumentReference<Map<String, dynamic>>? ref;
    Map<String, dynamic>? payload;
    return backupWithSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      prepare: () async {
        ref = _db.collection('users').doc(uid);
        payload = buildBackupPayload()
          ..['updated_at'] = FieldValue.serverTimestamp()
          ..['sync_revision'] = FieldValue.increment(1)
          ..['reconciliation_operation_id'] = FieldValue.delete()
          ..['reconciliation_payload_hash'] = FieldValue.delete();
      },
      write: () => ref!.set(payload!, SetOptions(merge: true)),
    );
  }

  @visibleForTesting
  static Future<CloudWriteResult> backupWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<void> Function() prepare,
    required Future<void> Function() write,
  }) {
    return CloudWriteFence(
      sessions,
    ).run(uid: uid, prepare: prepare, action: write);
  }

  /// Payload → lokale Werte (additiv / max-merge). Testbar ohne Firestore.
  static Future<void> applyRestorePayload(
    Map<String, dynamic> data, {
    void Function()? beforeWrite,
  }) {
    return _applyRestorePayload(data, beforeWrite: beforeWrite);
  }

  static Future<void> applyReconciledRestorePayload(
    Map<String, dynamic> data, {
    required String uid,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) async {
    sessions.assertCurrent(session);
    if (session.mode != CloudWriteMode.reconciling) {
      throw StateError(
        'Validated legacy restore requires a reconciling session.',
      );
    }
    if (session.uid != uid) {
      throw StateError('Validated bookshelf restore UID does not match.');
    }
    await _applyRestorePayload(
      data,
      beforeWrite: () => sessions.assertCurrent(session),
      validateLegacyBookshelfRestore: (restoredJson) {
        sessions.assertCurrent(session);
        BookshelfService.validateParentOnlyLegacyRestore(restoredJson);
      },
      onValidatedLegacyBookshelfRestored: (restoredJson) async {
        sessions.assertCurrent(session);
        await BookshelfService.recordValidatedParentOnlyLegacyRestore(
          uid: uid,
          restoredJson: restoredJson,
          session: session,
          sessions: sessions,
        );
        sessions.assertCurrent(session);
      },
    );
  }

  static Future<void> _applyRestorePayload(
    Map<String, dynamic> data, {
    void Function()? beforeWrite,
    void Function(String restoredJson)? validateLegacyBookshelfRestore,
    Future<void> Function(String restoredJson)?
    onValidatedLegacyBookshelfRestored,
  }) async {
    final vok = _map(data['vok']);
    final vocabularyWasUninitialized =
        Storage.vokCorrect == 0 &&
        Storage.vokWrong == 0 &&
        Storage.vokSkipped == 0 &&
        Storage.vokLastIdx == 0 &&
        Storage.vokSeenIds.isEmpty;
    await _maxMergeInt(
      vok['correct'],
      Storage.vokCorrect,
      Storage.setVokCorrect,
      beforeWrite: beforeWrite,
    );
    await _maxMergeInt(
      vok['wrong'],
      Storage.vokWrong,
      Storage.setVokWrong,
      beforeWrite: beforeWrite,
    );
    await _maxMergeInt(
      vok['skipped'],
      Storage.vokSkipped,
      Storage.setVokSkipped,
      beforeWrite: beforeWrite,
    );
    final cloudVokCursor = _nonNegativeInt(vok['last_idx']);
    if (vocabularyWasUninitialized && cloudVokCursor != null) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setVokLastIdx(cloudVokCursor),
      );
    }
    for (final id in _stringValues(vok['seen_ids'])) {
      await _guardedWrite(beforeWrite, () => Storage.addVokSeen(id));
    }

    final ch = _map(data['chosung']);
    await _maxMergeInt(
      ch['correct'],
      Storage.chosungCorrect,
      Storage.setChosungCorrect,
      beforeWrite: beforeWrite,
    );
    await _maxMergeInt(
      ch['wrong'],
      Storage.chosungWrong,
      Storage.setChosungWrong,
      beforeWrite: beforeWrite,
    );

    final wordle = _map(data['wordle']);
    final wordleWasUninitialized =
        Storage.wordleWins == 0 &&
        Storage.wordleLosses == 0 &&
        Storage.wordleStreak == 0 &&
        Storage.wordleBestStreak == 0;
    await _maxMergeInt(
      wordle['wins'],
      Storage.wordleWins,
      Storage.setWordleWins,
      beforeWrite: beforeWrite,
    );
    await _maxMergeInt(
      wordle['losses'],
      Storage.wordleLosses,
      Storage.setWordleLosses,
      beforeWrite: beforeWrite,
    );
    await _maxMergeInt(
      wordle['best_streak'],
      Storage.wordleBestStreak,
      Storage.setWordleBestStreak,
      beforeWrite: beforeWrite,
    );
    final cloudWordleStreak = _nonNegativeInt(wordle['streak']);
    if (wordleWasUninitialized && cloudWordleStreak != null) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setWordleStreak(cloudWordleStreak),
      );
      if (cloudWordleStreak > Storage.wordleBestStreak) {
        await _guardedWrite(
          beforeWrite,
          () => Storage.setWordleBestStreak(cloudWordleStreak),
        );
      }
    }

    final grammar = _map(data['grammar']);
    final grammarWasUninitialized =
        Storage.grammarLastIdx == 0 && Storage.grammarSeen.isEmpty;
    final cloudGrammarCursor = _nonNegativeInt(grammar['last_idx']);
    if (grammarWasUninitialized && cloudGrammarCursor != null) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setGrammarLastIdx(cloudGrammarCursor),
      );
    }
    for (final pat in _stringValues(grammar['seen'])) {
      await _guardedWrite(beforeWrite, () => Storage.addGrammarSeen(pat));
    }

    final app = _map(data['app']);
    await _maxMergeInt(
      app['best_streak'],
      Storage.bestStreak,
      Storage.setBestStreak,
      beforeWrite: beforeWrite,
    );
    final cloudLastOpen = _validIsoDate(app['last_open']);
    final cloudCurrentStreak = _nonNegativeInt(app['streak_days']);
    if (cloudLastOpen != null && cloudCurrentStreak != null) {
      final localLastOpen = _validIsoDate(Storage.lastOpenDate);
      if (localLastOpen == null ||
          cloudLastOpen.date.isAfter(localLastOpen.date)) {
        await _guardedWrite(
          beforeWrite,
          () => Storage.setLastOpenDate(cloudLastOpen.source),
        );
        await _guardedWrite(
          beforeWrite,
          () => Storage.setStreakDays(cloudCurrentStreak),
        );
      } else if (cloudLastOpen.source == localLastOpen.source &&
          cloudCurrentStreak > Storage.streakDays) {
        await _guardedWrite(
          beforeWrite,
          () => Storage.setStreakDays(cloudCurrentStreak),
        );
      }
      if (Storage.streakDays > Storage.bestStreak) {
        await _guardedWrite(
          beforeWrite,
          () => Storage.setBestStreak(Storage.streakDays),
        );
      }
    }

    // ── Fortschritt (additiv / max) ──
    final progress = _map(data['progress']);
    await _maxMergeInt(
      progress['xp'],
      Storage.xp,
      Storage.setXp,
      beforeWrite: beforeWrite,
    );
    final lvl = _supportedLevel(progress['level']);
    if (lvl != null && Storage.userLevelCode == null) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setUserLevelCode(lvl),
      ); // aktives Level nicht überschreiben
    }
    for (final stamp in _stringValues(progress['earned_stamps'])) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.addEarnedStamp(stamp),
      ); // Union
    }
    final questCompletions = _map(progress['quest_completions']);
    for (final entry in questCompletions.entries) {
      final questId = entry.key;
      final completedAt = entry.value;
      if (questId is! String || completedAt is! String) {
        continue;
      }
      final parsedAt = _strictUtcTimestamp(completedAt);
      if (questId.isEmpty ||
          parsedAt == null ||
          Storage.hasQuestCompleted(questId)) {
        continue;
      }
      await _guardedWrite(
        beforeWrite,
        () => Storage.markQuestCompleted(questId, at: parsedAt),
      );
    }

    // ── SRS-Deck & strukturierte Listen: nur lokal LEER ersetzen ──
    final srsJson = _structuredJson(
      data['srs_json'],
      hasExpectedShape: (decoded) => decoded is Map,
    );
    if (srsJson != null && Storage.srsRawJson.isEmpty) {
      await _guardedWrite(beforeWrite, () => Storage.setSrsRawJson(srsJson));
    }
    final customPacksJson = _portableRestoreJson(
      data['custom_packs_json'],
      stripBookshelfThumbnail: false,
    );
    if (customPacksJson != null && Storage.customPacksRawJson.isEmpty) {
      await _guardedWrite(
        beforeWrite,
        () => Storage.setCustomPacksRawJson(customPacksJson),
      );
    }
    final bookshelfJson = _portableRestoreJson(
      data['bookshelf_json'],
      stripBookshelfThumbnail: true,
    );
    if (bookshelfJson != null && Storage.bookshelfRawJson.isEmpty) {
      validateLegacyBookshelfRestore?.call(bookshelfJson);
      await _guardedWrite(
        beforeWrite,
        () => Storage.setBookshelfRawJson(bookshelfJson),
      );
      await onValidatedLegacyBookshelfRestored?.call(bookshelfJson);
    } else if (bookshelfJson != null &&
        onValidatedLegacyBookshelfRestored != null &&
        Storage.bookshelfRawJson == bookshelfJson) {
      // A prior strict local write may have succeeded while the durable
      // approval write failed. Revalidate and complete the approval on retry.
      validateLegacyBookshelfRestore?.call(bookshelfJson);
      await onValidatedLegacyBookshelfRestored(bookshelfJson);
    }
  }

  static Map<dynamic, dynamic> _map(Object? value) {
    return value is Map ? value : const {};
  }

  static int? _nonNegativeInt(Object? value) {
    if (value is int) {
      return value >= 0 ? value : null;
    }
    if (value is num && value.isFinite && value == value.truncate()) {
      final integer = value.toInt();
      return integer >= 0 ? integer : null;
    }
    return null;
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _supportedLevel(Object? value) {
    final level = _nonEmptyString(value)?.toLowerCase();
    return const {'a1', 'a2', 'b1', 'b2'}.contains(level) ? level : null;
  }

  static DateTime? _strictUtcTimestamp(String value) {
    if (!RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(?:\d{3})?Z$',
    ).hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
      return null;
    }
    return parsed;
  }

  static String? _structuredJson(
    Object? value, {
    required bool Function(Object? decoded) hasExpectedShape,
  }) {
    final json = _nonEmptyString(value);
    if (json == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(json);
      return hasExpectedShape(decoded) ? json : null;
    } on FormatException {
      return null;
    }
  }

  static String? _portableStructuredJson(
    String source, {
    required bool stripBookshelfThumbnail,
  }) {
    if (source.trim().isEmpty) {
      return source;
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return null;
      }
      return jsonEncode(
        _stripLocalMedia(
          decoded,
          stripBookshelfThumbnail: stripBookshelfThumbnail,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  static String? _portableRestoreJson(
    Object? value, {
    required bool stripBookshelfThumbnail,
  }) {
    final source = _nonEmptyString(value);
    if (source == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return null;
      }
      return jsonEncode(
        _stripLocalMedia(
          decoded,
          stripBookshelfThumbnail: stripBookshelfThumbnail,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic> _stripLocalMedia(
    Map<dynamic, dynamic> source, {
    required bool stripBookshelfThumbnail,
  }) {
    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Malformed portable collection.');
      }
      final owner = <String, dynamic>{};
      for (final field in (entry.value as Map).entries) {
        if (field.key is! String) {
          throw const FormatException('Malformed portable entry.');
        }
        final key = field.key as String;
        if (stripBookshelfThumbnail && key == 'localThumbnailPath') {
          continue;
        }
        if (key == 'words') {
          if (field.value is! List) {
            throw const FormatException('Malformed portable words.');
          }
          owner[key] = (field.value as List).map((word) {
            if (word is! Map) {
              throw const FormatException('Malformed portable word.');
            }
            final portableWord = <String, dynamic>{};
            for (final wordField in word.entries) {
              if (wordField.key is! String) {
                throw const FormatException('Malformed portable word field.');
              }
              if (wordField.key != 'imagePath') {
                portableWord[wordField.key as String] = wordField.value;
              }
            }
            return portableWord;
          }).toList();
        } else {
          owner[key] = field.value;
        }
      }
      result[entry.key as String] = owner;
    }
    return result;
  }

  static Iterable<String> _stringValues(Object? value) sync* {
    if (value is! List) {
      return;
    }
    for (final item in value) {
      if (item is String && item.isNotEmpty) {
        yield item;
      }
    }
  }

  static Future<void> _maxMergeInt(
    Object? cloudValue,
    int localValue,
    Future<void> Function(int) write, {
    void Function()? beforeWrite,
  }) async {
    final cloudInt = _nonNegativeInt(cloudValue);
    if (cloudInt != null && cloudInt > localValue) {
      beforeWrite?.call();
      await write(cloudInt);
    }
  }

  static Future<void> _guardedWrite(
    void Function()? beforeWrite,
    Future<void> Function() write,
  ) async {
    beforeWrite?.call();
    await write();
  }

  static _IsoDate? _validIsoDate(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-'
                '${parsed.month.toString().padLeft(2, '0')}-'
                '${parsed.day.toString().padLeft(2, '0')}' !=
            value) {
      return null;
    }
    return _IsoDate(source: value, date: parsed);
  }

  /// Firestore → lokale Werte (additiv).
  /// Kept for existing callers that only need a success boolean. New UI code
  /// must use [restoreWithResult] so an empty backup is never confused with a
  /// blocked or stale admission.
  static Future<bool> restore() async =>
      (await restoreWithResult()) == CloudRestoreResult.completed;

  static Future<CloudRestoreResult> restoreWithResult() async {
    try {
      return await AuthService.runCloudBackupDeletionAdmission(
        onAdmitted: _restoreWithResultAfterCloudBackupAdmission,
        onBlocked: () async => CloudRestoreResult.blocked,
      );
    } catch (_) {
      return CloudRestoreResult.blocked;
    }
  }

  static Future<CloudRestoreResult>
  _restoreWithResultAfterCloudBackupAdmission() async {
    final typedOverride = _restoreWithResultForTesting;
    if (typedOverride != null) return typedOverride();
    final legacyOverride = _restoreForTesting;
    if (legacyOverride != null) {
      // Compatibility for old boolean test callers: `false` historically
      // represented a non-restored backup, which maps to the old no-data UI.
      return (await legacyOverride())
          ? CloudRestoreResult.completed
          : CloudRestoreResult.empty;
    }
    final uid = AuthService.cloudBackupUid;
    if (uid == null) return CloudRestoreResult.blocked;
    return restoreWithSessionResult(
      sessions: cloudWriteSessionController,
      uid: uid,
      readAccount: () => CloudSyncService.readAccountDocument(uid: uid),
      applyAccount: (data, beforeWrite) {
        final accountData = Map<String, dynamic>.from(data)
          ..remove('bookshelf_json');
        return applyRestorePayload(accountData, beforeWrite: beforeWrite);
      },
      restoreBookshelf: (expectedSession) {
        return BookshelfService.restoreRemoteForSessionWithResult(
          uid: uid,
          expectedSession: expectedSession,
          sessions: cloudWriteSessionController,
        );
      },
      restorePacks: (expectedSession) {
        return PackProgressService.pullTypedFromCloudWithSessionResult(
          sessions: cloudWriteSessionController,
          uid: uid,
          expectedSession: expectedSession,
          loadRemote: () => FirestoreProgressService.loadAllTyped(uid: uid),
          loadLocal: PackProgressService.getAll,
          persistLocal: Storage.setManyPackProgressJson,
        );
      },
    );
  }

  @visibleForTesting
  static void overrideOperationsForTesting({
    Future<CloudWriteResult> Function()? backupWithResult,
    Future<CloudRestoreResult> Function()? restoreWithResult,
    Future<bool> Function()? restore,
  }) {
    _backupWithResultForTesting = backupWithResult;
    _restoreWithResultForTesting = restoreWithResult;
    _restoreForTesting = restore;
  }

  @visibleForTesting
  static void resetOperationsForTesting() {
    _backupWithResultForTesting = null;
    _restoreWithResultForTesting = null;
    _restoreForTesting = null;
  }

  static Future<CloudWriteResult> restoreWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<CloudReadResult<Map<String, dynamic>>> Function()
    readAccount,
    required Future<void> Function(
      Map<String, dynamic> data,
      void Function() beforeWrite,
    )
    applyAccount,
    required Future<CloudWriteResult> Function(
      CloudWriteSession expectedSession,
    )
    restoreBookshelf,
  }) async {
    final result = await restoreWithSessionResult(
      sessions: sessions,
      uid: uid,
      readAccount: readAccount,
      applyAccount: applyAccount,
      restoreBookshelf: (expectedSession) async {
        final status = await restoreBookshelf(expectedSession);
        return CloudRestoreComponentResult(
          status: status,
          hasRemoteData: false,
        );
      },
      restorePacks: (_) async => const CloudRestoreComponentResult(
        status: CloudWriteResult.completed,
        hasRemoteData: false,
      ),
    );
    return switch (result) {
      CloudRestoreResult.completed => CloudWriteResult.completed,
      CloudRestoreResult.stale => CloudWriteResult.stale,
      CloudRestoreResult.empty ||
      CloudRestoreResult.blocked => CloudWriteResult.blocked,
    };
  }

  static Future<CloudRestoreResult> restoreWithSessionResult({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<CloudReadResult<Map<String, dynamic>>> Function()
    readAccount,
    required Future<void> Function(
      Map<String, dynamic> data,
      void Function() beforeWrite,
    )
    applyAccount,
    required Future<CloudRestoreComponentResult> Function(
      CloudWriteSession expectedSession,
    )
    restoreBookshelf,
    required Future<CloudRestoreComponentResult> Function(
      CloudWriteSession expectedSession,
    )
    restorePacks,
  }) async {
    final fence = CloudWriteFence(sessions);
    final expectedSession = fence.readySnapshot(uid);
    if (expectedSession == null) return CloudRestoreResult.blocked;
    try {
      final remote = await readAccount();
      final afterRead = fence.verify(expectedSession, uid: uid);
      if (afterRead != CloudWriteResult.completed) {
        return _restoreResultForWrite(afterRead);
      }
      var hasRootBackup = false;
      if (remote.state == CloudReadState.present && remote.value != null) {
        await applyAccount(
          remote.value!,
          () => sessions.assertCurrent(expectedSession),
        );
        final afterAccount = fence.verify(expectedSession, uid: uid);
        if (afterAccount != CloudWriteResult.completed) {
          return _restoreResultForWrite(afterAccount);
        }
        hasRootBackup = true;
      } else if (remote.state != CloudReadState.absent) {
        return CloudRestoreResult.blocked;
      }
      final bookshelf = await restoreBookshelf(expectedSession);
      if (bookshelf.status != CloudWriteResult.completed) {
        return _restoreResultForWrite(bookshelf.status);
      }
      final packs = await restorePacks(expectedSession);
      if (packs.status != CloudWriteResult.completed) {
        return _restoreResultForWrite(packs.status);
      }
      final afterComponents = fence.verify(expectedSession, uid: uid);
      if (afterComponents != CloudWriteResult.completed) {
        return _restoreResultForWrite(afterComponents);
      }
      return hasRootBackup || bookshelf.hasRemoteData || packs.hasRemoteData
          ? CloudRestoreResult.completed
          : CloudRestoreResult.empty;
    } catch (_) {
      final current = fence.verify(expectedSession, uid: uid);
      return _restoreResultForWrite(
        current == CloudWriteResult.completed
            ? CloudWriteResult.blocked
            : current,
      );
    }
  }

  static CloudRestoreResult _restoreResultForWrite(CloudWriteResult result) {
    return switch (result) {
      CloudWriteResult.completed => CloudRestoreResult.completed,
      CloudWriteResult.blocked => CloudRestoreResult.blocked,
      CloudWriteResult.stale => CloudRestoreResult.stale,
    };
  }

  /// Zeitstempel des letzten Cloud-Backups (zur Anzeige in Settings).
  static Future<DateTime?> lastBackupAt() async {
    final ref = _doc;
    if (ref == null) return null;
    try {
      final snap = await ref.get();
      final ts = snap.data()?['updated_at'] as Timestamp?;
      return ts?.toDate();
    } catch (_) {
      return null;
    }
  }
}

class _IsoDate {
  const _IsoDate({required this.source, required this.date});

  final String source;
  final DateTime date;
}
