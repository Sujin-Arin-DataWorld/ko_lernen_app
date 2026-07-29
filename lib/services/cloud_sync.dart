import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'auth_service.dart';
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
/// Bücherregal: `bookshelf_service` schreibt zwar best-effort einzelne Docs,
/// hatte aber **keinen Restore-Pfad** → seit 2026-06-12 hier als
/// `bookshelf_json` mitgesichert/-wiederhergestellt (Gerätewechsel-Schutz).
class CloudSync {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = AuthService.current?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  /// Reines Backup-Payload (ohne Firestore-I/O, ohne `updated_at`) — testbar.
  @visibleForTesting
  static Map<String, dynamic> buildBackupPayload() => {
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
    'custom_packs_json': Storage.customPacksRawJson,
    'bookshelf_json': Storage.bookshelfRawJson,
  };

  /// Lokale Werte → Firestore. Idempotent.
  static Future<void> backup() async {
    final ref = _doc;
    if (ref == null) return;
    final payload = buildBackupPayload();
    payload['updated_at'] = FieldValue.serverTimestamp();
    await ref.set(payload, SetOptions(merge: true));
  }

  /// Payload → lokale Werte (additiv / max-merge). Testbar ohne Firestore.
  @visibleForTesting
  static Future<void> applyRestorePayload(Map<String, dynamic> data) async {
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
    );
    await _maxMergeInt(vok['wrong'], Storage.vokWrong, Storage.setVokWrong);
    await _maxMergeInt(
      vok['skipped'],
      Storage.vokSkipped,
      Storage.setVokSkipped,
    );
    final cloudVokCursor = _nonNegativeInt(vok['last_idx']);
    if (vocabularyWasUninitialized && cloudVokCursor != null) {
      await Storage.setVokLastIdx(cloudVokCursor);
    }
    for (final id in _stringValues(vok['seen_ids'])) {
      await Storage.addVokSeen(id);
    }

    final ch = _map(data['chosung']);
    await _maxMergeInt(
      ch['correct'],
      Storage.chosungCorrect,
      Storage.setChosungCorrect,
    );
    await _maxMergeInt(
      ch['wrong'],
      Storage.chosungWrong,
      Storage.setChosungWrong,
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
    );
    await _maxMergeInt(
      wordle['losses'],
      Storage.wordleLosses,
      Storage.setWordleLosses,
    );
    await _maxMergeInt(
      wordle['best_streak'],
      Storage.wordleBestStreak,
      Storage.setWordleBestStreak,
    );
    final cloudWordleStreak = _nonNegativeInt(wordle['streak']);
    if (wordleWasUninitialized && cloudWordleStreak != null) {
      await Storage.setWordleStreak(cloudWordleStreak);
      if (cloudWordleStreak > Storage.wordleBestStreak) {
        await Storage.setWordleBestStreak(cloudWordleStreak);
      }
    }

    final grammar = _map(data['grammar']);
    final grammarWasUninitialized =
        Storage.grammarLastIdx == 0 && Storage.grammarSeen.isEmpty;
    final cloudGrammarCursor = _nonNegativeInt(grammar['last_idx']);
    if (grammarWasUninitialized && cloudGrammarCursor != null) {
      await Storage.setGrammarLastIdx(cloudGrammarCursor);
    }
    for (final pat in _stringValues(grammar['seen'])) {
      await Storage.addGrammarSeen(pat);
    }

    final app = _map(data['app']);
    await _maxMergeInt(
      app['best_streak'],
      Storage.bestStreak,
      Storage.setBestStreak,
    );
    final cloudLastOpen = _validIsoDate(app['last_open']);
    final cloudCurrentStreak = _nonNegativeInt(app['streak_days']);
    if (cloudLastOpen != null && cloudCurrentStreak != null) {
      final localLastOpen = _validIsoDate(Storage.lastOpenDate);
      if (localLastOpen == null ||
          cloudLastOpen.date.isAfter(localLastOpen.date)) {
        await Storage.setLastOpenDate(cloudLastOpen.source);
        await Storage.setStreakDays(cloudCurrentStreak);
      } else if (cloudLastOpen.source == localLastOpen.source &&
          cloudCurrentStreak > Storage.streakDays) {
        await Storage.setStreakDays(cloudCurrentStreak);
      }
      if (Storage.streakDays > Storage.bestStreak) {
        await Storage.setBestStreak(Storage.streakDays);
      }
    }

    // ── Fortschritt (additiv / max) ──
    final progress = _map(data['progress']);
    await _maxMergeInt(progress['xp'], Storage.xp, Storage.setXp);
    final lvl = _supportedLevel(progress['level']);
    if (lvl != null && Storage.userLevelCode == null) {
      await Storage.setUserLevelCode(lvl); // aktives Level nicht überschreiben
    }
    for (final stamp in _stringValues(progress['earned_stamps'])) {
      await Storage.addEarnedStamp(stamp); // Union
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
      await Storage.markQuestCompleted(questId, at: parsedAt);
    }

    // ── SRS-Deck & strukturierte Listen: nur lokal LEER ersetzen ──
    final srsJson = _structuredJson(
      data['srs_json'],
      hasExpectedShape: (decoded) => decoded is Map,
    );
    if (srsJson != null && Storage.srsRawJson.isEmpty) {
      await Storage.setSrsRawJson(srsJson);
    }
    final customPacksJson = _structuredJson(
      data['custom_packs_json'],
      hasExpectedShape: (decoded) => decoded is Map,
    );
    if (customPacksJson != null && Storage.customPacksRawJson.isEmpty) {
      await Storage.setCustomPacksRawJson(customPacksJson);
    }
    final bookshelfJson = _structuredJson(
      data['bookshelf_json'],
      hasExpectedShape: (decoded) => decoded is Map,
    );
    if (bookshelfJson != null && Storage.bookshelfRawJson.isEmpty) {
      await Storage.setBookshelfRawJson(bookshelfJson);
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
    Future<void> Function(int) write,
  ) async {
    final cloudInt = _nonNegativeInt(cloudValue);
    if (cloudInt != null && cloudInt > localValue) {
      await write(cloudInt);
    }
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
  static Future<bool> restore() async {
    final ref = _doc;
    if (ref == null) return false;
    final snap = await ref.get();
    if (!snap.exists) return false;
    final data = snap.data();
    if (data == null) return false;
    await applyRestorePayload(data);
    return true;
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
