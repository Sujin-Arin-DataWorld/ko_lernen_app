import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import 'firestore_progress_service.dart';
import 'storage_service.dart';
import 'vocab_pack_service.dart';

/// Orchestrator für Pack-Fortschritt — lokal als SoT, Firestore als Backup.
///
/// **Design**:
///  - Lese-Pfad: lokal (`Storage.packProgressJson`) → fast, offline-fähig.
///  - Schreib-Pfad: lokal sofort → Firestore best-effort (fire-and-forget).
///  - Migration: `pullFromCloud()` lädt Firestore-Snapshot ins lokale
///    Storage (initial bei Login / nach App-Reinstall).
///
/// **Unlock-Logik** (Plan §4.2):
///  - Erster Pack jedes Levels: immer `available`.
///  - Sonst: `available` gdw. vorheriger Pack im Level `cleared` ist.
///  - Boss-Genauigkeit ≥ 0.70 → `cleared`.
class PackProgressService {
  /// Boss-Genauigkeit ab der ein Pack als geklärt gilt.
  static const double bossClearThreshold = 0.70;

  // ── Reads ──────────────────────────────────────────────────────────

  /// Fortschritt eines Packs. Null = noch nie gespeichert.
  /// Aufrufer sollte ggf. mit `effectiveStatus()` initialisieren.
  static PackProgress? get(String packId) {
    final json = Storage.packProgressJson(packId);
    if (json == null) return null;
    return PackProgress.fromJson(packId, json);
  }

  /// Alle gespeicherten Pack-Fortschritte. Schlüssel = packId.
  static Map<String, PackProgress> getAll() {
    final raw = Storage.allPackProgressJson();
    return raw.map((k, v) => MapEntry(k, PackProgress.fromJson(k, v)));
  }

  /// Effektiver Status — wenn lokal nichts gespeichert ist, wird
  /// aus der Unlock-Logik abgeleitet (locked / available).
  /// Verwendet [allPacksInLevel] zur Reihenfolge-Bestimmung.
  static PackProgress effectiveStatus(
    VocabPack pack,
    List<VocabPack> allPacksInLevel,
    Map<String, PackProgress> existing,
  ) {
    final stored = existing[pack.id];
    if (stored != null) return stored;
    final status = _isUnlocked(pack, allPacksInLevel, existing)
        ? PackStatus.available
        : PackStatus.locked;
    return PackProgress.fresh(
      packId: pack.id,
      level: pack.level,
      wordsTotal: pack.total,
      status: status,
    );
  }

  /// Berechnet `wordsLearned` für einen Pack aus `Storage.vokSeenIds`.
  /// Verzichtet auf eigenen Counter — leitet von vorhandener Quelle ab.
  static int wordsLearnedIn(VocabPack pack) {
    final seen = Storage.vokSeenIds.toSet();
    return pack.words.where((w) => seen.contains(w.korean)).length;
  }

  // ── Unlock-Logik ───────────────────────────────────────────────────

  /// Public unlock helper — wenn `existing` bereits geladen ist.
  static bool isUnlocked(
    String packId,
    List<VocabPack> allPacksInLevel,
    Map<String, PackProgress> existing,
  ) {
    final pack = allPacksInLevel.where((p) => p.id == packId).firstOrNull;
    if (pack == null) return false;
    return _isUnlocked(pack, allPacksInLevel, existing);
  }

  static bool _isUnlocked(
    VocabPack pack,
    List<VocabPack> allPacksInLevel,
    Map<String, PackProgress> existing,
  ) {
    // Wenn bereits explizit gespeichert → respektieren.
    final stored = existing[pack.id];
    if (stored != null) return stored.status != PackStatus.locked;

    // Reihenfolge: erstes Pack im Level immer unlocked.
    final idx = allPacksInLevel.indexWhere((p) => p.id == pack.id);
    if (idx <= 0) return idx == 0;

    final prev = allPacksInLevel[idx - 1];
    final prevProgress = existing[prev.id];
    return prevProgress?.status == PackStatus.cleared;
  }

  /// Nächster Pack im Level (UI: "Weiter mit nächstem Pack").
  /// Null wenn letzter Pack.
  static VocabPack? nextPackInLevel(
    String packId,
    List<VocabPack> allPacksInLevel,
  ) {
    final idx = allPacksInLevel.indexWhere((p) => p.id == packId);
    if (idx < 0 || idx >= allPacksInLevel.length - 1) return null;
    return allPacksInLevel[idx + 1];
  }

  /// Vorheriger Pack im Level (Unlock-Bedingung anzeigen).
  static VocabPack? previousPackInLevel(
    String packId,
    List<VocabPack> allPacksInLevel,
  ) {
    final idx = allPacksInLevel.indexWhere((p) => p.id == packId);
    if (idx <= 0) return null;
    return allPacksInLevel[idx - 1];
  }

  // ── Writes ─────────────────────────────────────────────────────────

  /// `wordsLearned` aktualisieren (z.B. nach jeder Stage-1-Karte).
  ///
  /// Setzt Status auf `inProgress` wenn bisher `available`. Lockt nicht.
  static Future<void> recordWordLearned(
    VocabPack pack, {
    int? overrideCount,
  }) async {
    final current = get(pack.id) ??
        PackProgress.fresh(
          packId: pack.id,
          level: pack.level,
          wordsTotal: pack.total,
          status: PackStatus.available,
        );

    final newCount = overrideCount ?? wordsLearnedIn(pack);

    final updated = current.copyWith(
      status: current.status == PackStatus.cleared
          ? PackStatus.cleared
          : (newCount > 0 ? PackStatus.inProgress : current.status),
      wordsLearned: newCount,
      wordsTotal: pack.total,
    );
    await _persist(updated);
  }

  /// Boss-Versuch eintragen — entscheidet Cleared / inProgress.
  ///
  /// [bossAccuracy] 0.0..1.0
  /// [bossCorrect], [bossTotal] — werden NICHT separat gespeichert,
  ///   nur Accuracy + Attempt-Count.
  ///
  /// Returns: aktualisierter Pack + ob Cleared-Übergang erfolgte
  /// (für UI-Zelebration).
  static Future<({PackProgress progress, bool justCleared, VocabPack? nextUnlocked})>
      recordBossAttempt(
    VocabPack pack,
    List<VocabPack> allPacksInLevel, {
    required double bossAccuracy,
  }) async {
    final current = get(pack.id) ??
        PackProgress.fresh(
          packId: pack.id,
          level: pack.level,
          wordsTotal: pack.total,
          status: PackStatus.available,
        );

    final wasCleared = current.status == PackStatus.cleared;
    final nowCleared = bossAccuracy >= bossClearThreshold;
    final attempts = current.attempts + 1;
    // Best-attempt: speichere höchste Genauigkeit, nicht letzte.
    final bestAccuracy =
        bossAccuracy > current.bossAccuracy ? bossAccuracy : current.bossAccuracy;

    // **Status-Regel** (Plan §4.2 + handover spec):
    //   - Einmal cleared → immer cleared (auch wenn spätere Versuche
    //     unter 70 % liegen). Plays-store-vibes: ein verdientes 도장 wird
    //     nie aberkannt.
    //   - Sonst: nowCleared ? cleared : inProgress.
    final nextStatus = wasCleared || nowCleared
        ? PackStatus.cleared
        : PackStatus.inProgress;

    final updated = current.copyWith(
      status: nextStatus,
      attempts: attempts,
      bossAccuracy: bestAccuracy,
      clearedAtIso: wasCleared
          ? current.clearedAtIso
          : (nowCleared ? DateTime.now().toUtc().toIso8601String() : null),
    );
    await _persist(updated);

    VocabPack? unlockedNext;
    if (!wasCleared && nowCleared) {
      // Nächsten Pack auf "available" setzen (sofern noch locked).
      final next = nextPackInLevel(pack.id, allPacksInLevel);
      if (next != null) {
        final nextExisting = get(next.id);
        if (nextExisting == null ||
            nextExisting.status == PackStatus.locked) {
          await _persist(
            PackProgress.fresh(
              packId: next.id,
              level: next.level,
              wordsTotal: next.total,
              status: PackStatus.available,
            ),
          );
          unlockedNext = next;
        }
      }
    }

    return (
      progress: updated,
      justCleared: !wasCleared && nowCleared,
      nextUnlocked: unlockedNext,
    );
  }

  static Future<void> _persist(PackProgress p) async {
    await Storage.setPackProgressJson(p.packId, p.toJson());
    // Fire-and-forget Firestore sync.
    // ignore: discarded_futures, unawaited_futures
    FirestoreProgressService.savePack(p);
  }

  // ── Cloud-Sync (Backup / Restore) ──────────────────────────────────

  /// Firestore → lokal. Aufrufen bei Login / nach Reinstall.
  /// Behält lokale Werte, wenn Firestore-Eintrag fehlt.
  static Future<void> pullFromCloud() async {
    final remote = await FirestoreProgressService.loadAll();
    if (remote.isEmpty) return;
    final localBefore = getAll();
    final merged = <String, Map<String, dynamic>>{};
    for (final entry in remote.entries) {
      merged[entry.key] = entry.value.toJson();
    }
    // Lokale-only Einträge erhalten:
    for (final entry in localBefore.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value.toJson();
      }
    }
    await Storage.setManyPackProgressJson(merged);
  }

  /// Lokal → Firestore (Batch). Idempotent.
  static Future<void> pushToCloud() async {
    final local = getAll();
    if (local.isEmpty) return;
    await FirestoreProgressService.saveMany(local.values);
  }

  // ── Komfort-Wrapper für VocabPackService-Konsumenten ──────────────

  /// Lädt alle Packs eines Levels + deren Fortschritt-Status.
  /// Liefert eine Liste in Pack-Reihenfolge mit korrektem locked/available.
  static Future<List<({VocabPack pack, PackProgress progress})>>
      loadLevelView(String level) async {
    final packs = await VocabPackService.packsForLevel(level);
    final existing = getAll();
    return packs
        .map((p) => (
              pack: p,
              progress: effectiveStatus(p, packs, existing),
            ))
        .toList();
  }
}

// firstOrNull-Polyfill für ältere Dart-Targets ist nicht nötig:
// dart:core Iterable.firstOrNull existiert seit Dart 3.0.
