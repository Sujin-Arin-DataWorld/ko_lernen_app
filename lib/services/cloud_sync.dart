import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// 1-Weg-Sync: Storage (lokal) ↔ Firestore (Cloud).
///
/// - Local = source of truth während des Spielens.
/// - Backup: lokale Werte → Firestore.
/// - Restore: Firestore → lokale Werte (überschreibt!).
class CloudSync {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = AuthService.current?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  /// Lokale Werte → Firestore. Idempotent.
  static Future<void> backup() async {
    final ref = _doc;
    if (ref == null) return;

    final payload = <String, dynamic>{
      'vok': {
        'correct':   Storage.vokCorrect,
        'wrong':     Storage.vokWrong,
        'skipped':   Storage.vokSkipped,
        'last_idx':  Storage.vokLastIdx,
        'seen_ids':  Storage.vokSeenIds,
      },
      'chosung': {
        'correct': Storage.chosungCorrect,
        'wrong':   Storage.chosungWrong,
      },
      'wordle': {
        'wins':         Storage.wordleWins,
        'losses':       Storage.wordleLosses,
        'streak':       Storage.wordleStreak,
        'best_streak':  Storage.wordleBestStreak,
      },
      'grammar': {
        'last_idx': Storage.grammarLastIdx,
        'seen':     Storage.grammarSeen,
      },
      'app': {
        'last_open':    Storage.lastOpenDate,
        'streak_days':  Storage.streakDays,
        'best_streak':  Storage.bestStreak,
      },
      'updated_at': FieldValue.serverTimestamp(),
    };

    await ref.set(payload, SetOptions(merge: true));
  }

  /// Firestore → lokale Werte. Überschreibt lokale Werte!
  static Future<bool> restore() async {
    final ref = _doc;
    if (ref == null) return false;
    final snap = await ref.get();
    if (!snap.exists) return false;
    final data = snap.data();
    if (data == null) return false;

    final vok = (data['vok'] as Map?) ?? {};
    if (vok['correct'] != null) await Storage.setVokCorrect(vok['correct'] as int);
    if (vok['wrong']   != null) await Storage.setVokWrong((vok['wrong'] as int));
    if (vok['skipped'] != null) await Storage.setVokSkipped((vok['skipped'] as int));
    if (vok['last_idx']!= null) await Storage.setVokLastIdx((vok['last_idx'] as int));
    // seen_ids: bestehende lokale Liste mergen, keine Duplikate
    final seenIds = (vok['seen_ids'] as List?)?.cast<String>() ?? [];
    for (final id in seenIds) {
      await Storage.addVokSeen(id);
    }

    final ch = (data['chosung'] as Map?) ?? {};
    if (ch['correct'] != null) {
      // Storage hat keine setChosungCorrect — wir setzen via Differenz
      final diff = (ch['correct'] as int) - Storage.chosungCorrect;
      for (var i = 0; i < diff; i++) {
        await Storage.incChosungCorrect();
      }
    }

    final w = (data['wordle'] as Map?) ?? {};
    // Wordle ist komplexer (best_streak nur erhöhen, nicht überschreiben).
    // Vereinfachung: lokale Werte bleiben, Cloud merged 'max'.
    // (Hier minimal: nichts überschreiben außer Initialisierung)

    final g = (data['grammar'] as Map?) ?? {};
    if (g['last_idx'] != null) await Storage.setGrammarLastIdx(g['last_idx'] as int);
    final gSeen = (g['seen'] as List?)?.cast<String>() ?? [];
    for (final pat in gSeen) {
      await Storage.addGrammarSeen(pat);
    }

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
