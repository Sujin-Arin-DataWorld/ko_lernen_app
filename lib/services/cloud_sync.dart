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
/// (xp/level/stamps/quests) + SRS-Deck + Custom-Packs** (sonst Verlust bei
/// Reinstall/Gerätewechsel). packs/bookshelf werden separat von
/// `firestore_progress_service` / `bookshelf_service` synchronisiert → hier
/// nicht dupliziert.
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
    final vok = (data['vok'] as Map?) ?? const {};
    if (vok['correct'] != null) await Storage.setVokCorrect(vok['correct'] as int);
    if (vok['wrong'] != null) await Storage.setVokWrong(vok['wrong'] as int);
    if (vok['skipped'] != null) await Storage.setVokSkipped(vok['skipped'] as int);
    if (vok['last_idx'] != null) await Storage.setVokLastIdx(vok['last_idx'] as int);
    for (final id in (vok['seen_ids'] as List?)?.cast<String>() ?? const []) {
      await Storage.addVokSeen(id);
    }

    final ch = (data['chosung'] as Map?) ?? const {};
    if (ch['correct'] != null) {
      final diff = (ch['correct'] as int) - Storage.chosungCorrect;
      for (var i = 0; i < diff; i++) {
        await Storage.incChosungCorrect();
      }
    }

    // wordle: lokale Werte bleiben (best_streak nur erhöhen — Original-Verhalten).

    final g = (data['grammar'] as Map?) ?? const {};
    if (g['last_idx'] != null) await Storage.setGrammarLastIdx(g['last_idx'] as int);
    for (final pat in (g['seen'] as List?)?.cast<String>() ?? const []) {
      await Storage.addGrammarSeen(pat);
    }

    // ── Fortschritt (additiv / max) ──
    final prog = (data['progress'] as Map?) ?? const {};
    final cloudXp = (prog['xp'] as num?)?.toInt();
    if (cloudXp != null && cloudXp > Storage.xp) {
      await Storage.addXp(cloudXp - Storage.xp); // nur erhöhen
    }
    final lvl = prog['level'] as String?;
    if (lvl != null && lvl.isNotEmpty && Storage.userLevelCode == null) {
      await Storage.setUserLevelCode(lvl); // aktives Level nicht überschreiben
    }
    for (final s
        in (prog['earned_stamps'] as List?)?.cast<String>() ?? const []) {
      await Storage.addEarnedStamp(s); // Union
    }
    final qc = (prog['quest_completions'] as Map?) ?? const {};
    for (final e in qc.entries) {
      if (!Storage.hasQuestCompleted(e.key)) {
        await Storage.markQuestCompleted(
          e.key,
          at: DateTime.tryParse(e.value as String? ?? ''),
        );
      }
    }

    // ── SRS-Deck & Custom-Packs: nur wenn lokal LEER (kein Clobber) ──
    final srsJson = data['srs_json'] as String?;
    if (srsJson != null && srsJson.isNotEmpty && Storage.srsRawJson.isEmpty) {
      await Storage.setSrsRawJson(srsJson);
    }
    final cpJson = data['custom_packs_json'] as String?;
    if (cpJson != null &&
        cpJson.isNotEmpty &&
        Storage.customPacksRawJson.isEmpty) {
      await Storage.setCustomPacksRawJson(cpJson);
    }
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
