import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import 'account/cloud_read_result.dart';
import 'account/cloud_restore_result.dart';
import 'account/cloud_write_session.dart';
import 'auth_service.dart';
import 'firestore_progress_service.dart';
import 'storage_service.dart';
import 'stamp_entitlement_reconciler.dart';
import 'vocab_pack_service.dart';

class PackCatalogEntry {
  const PackCatalogEntry({
    required this.packId,
    required this.level,
    required this.wordsTotal,
  });

  final String packId;
  final String level;
  final int wordsTotal;
}

class PackProgressMergeResult {
  const PackProgressMergeResult._({required this.invalidPackIds, this.merged});

  const PackProgressMergeResult.valid(Map<String, PackProgress> merged)
    : this._(invalidPackIds: const [], merged: merged);

  const PackProgressMergeResult.invalid(List<String> invalidPackIds)
    : this._(invalidPackIds: invalidPackIds);

  final List<String> invalidPackIds;
  final Map<String, PackProgress>? merged;

  bool get isValid => invalidPackIds.isEmpty && merged != null;
}

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

  /// Performs a commutative, idempotent monotonic merge after validating each
  /// record against the immutable catalog.
  ///
  /// Attempt counts use max rather than sum because the legacy record has no
  /// stable attempt IDs with which independent attempts could be deduplicated.
  static PackProgressMergeResult mergeForReconciliation({
    required Map<String, PackProgress> local,
    required Map<String, PackProgress> remote,
    required Map<String, PackCatalogEntry> catalog,
  }) {
    final invalid = <String>{};
    for (final entry in [...local.entries, ...remote.entries]) {
      final catalogEntry = catalog[entry.key];
      if (catalogEntry == null ||
          !_validForCatalog(entry.value, catalogEntry)) {
        invalid.add(entry.key);
      }
    }
    if (invalid.isNotEmpty) {
      final sorted = invalid.toList()..sort();
      return PackProgressMergeResult.invalid(sorted);
    }

    final ids = {...local.keys, ...remote.keys}.toList()..sort();
    final merged = <String, PackProgress>{};
    for (final id in ids) {
      final left = local[id];
      final right = remote[id];
      if (left == null) {
        merged[id] = right!;
        continue;
      }
      if (right == null) {
        merged[id] = left;
        continue;
      }
      merged[id] = PackProgress(
        packId: id,
        level: left.level,
        status: left.status.index >= right.status.index
            ? left.status
            : right.status,
        wordsLearned: left.wordsLearned >= right.wordsLearned
            ? left.wordsLearned
            : right.wordsLearned,
        wordsTotal: left.wordsTotal,
        bossAccuracy: left.bossAccuracy >= right.bossAccuracy
            ? left.bossAccuracy
            : right.bossAccuracy,
        attempts: left.attempts >= right.attempts
            ? left.attempts
            : right.attempts,
        clearedAtIso: _earliestClearedAt(left.clearedAtIso, right.clearedAtIso),
      );
    }
    return PackProgressMergeResult.valid(merged);
  }

  static bool _validForCatalog(
    PackProgress progress,
    PackCatalogEntry catalog,
  ) {
    if (progress.packId != catalog.packId ||
        progress.level != catalog.level ||
        progress.wordsTotal != catalog.wordsTotal ||
        progress.wordsTotal < 0 ||
        progress.wordsLearned < 0 ||
        progress.wordsLearned > progress.wordsTotal ||
        progress.attempts < 0 ||
        !progress.bossAccuracy.isFinite ||
        progress.bossAccuracy < 0 ||
        progress.bossAccuracy > 1) {
      return false;
    }
    switch (progress.status) {
      case PackStatus.locked:
      case PackStatus.available:
        return progress.wordsLearned == 0 &&
            progress.attempts == 0 &&
            progress.bossAccuracy == 0 &&
            progress.clearedAtIso == null;
      case PackStatus.inProgress:
        return (progress.wordsLearned > 0 || progress.attempts > 0) &&
            progress.bossAccuracy < bossClearThreshold &&
            (progress.attempts > 0 || progress.bossAccuracy == 0) &&
            progress.clearedAtIso == null;
      case PackStatus.cleared:
        final clearedAt = progress.clearedAtIso == null
            ? null
            : DateTime.tryParse(progress.clearedAtIso!);
        return progress.attempts > 0 &&
            progress.bossAccuracy >= bossClearThreshold &&
            clearedAt != null &&
            clearedAt.isUtc;
    }
  }

  static String? _earliestClearedAt(String? left, String? right) {
    if (left == null) return right;
    if (right == null) return left;
    final leftTime = DateTime.parse(left);
    final rightTime = DateTime.parse(right);
    return leftTime.isBefore(rightTime) ? left : right;
  }

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
    final current =
        get(pack.id) ??
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
  static Future<
    ({PackProgress progress, bool justCleared, VocabPack? nextUnlocked})
  >
  recordBossAttempt(
    VocabPack pack,
    List<VocabPack> allPacksInLevel, {
    required double bossAccuracy,
  }) async {
    final current =
        get(pack.id) ??
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
    final bestAccuracy = bossAccuracy > current.bossAccuracy
        ? bossAccuracy
        : current.bossAccuracy;

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
        if (nextExisting == null || nextExisting.status == PackStatus.locked) {
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
    await pullFromCloudWithResult();
  }

  static Future<CloudWriteResult> pullFromCloudWithResult() async {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      return CloudWriteResult.blocked;
    }
    final result = await pullTypedFromCloudWithSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      loadRemote: () => FirestoreProgressService.loadAllTyped(uid: uid),
      loadLocal: getAll,
      persistLocal: Storage.setManyPackProgressJson,
    );
    if (result == CloudWriteResult.completed) {
      await StampEntitlementReconciler.reconcile(progress: getAll());
    }
    return result;
  }

  static Future<CloudWriteResult> pullTypedFromCloudWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<CloudReadResult<FirestorePackSnapshot>> Function()
    loadRemote,
    required Map<String, PackProgress> Function() loadLocal,
    required Future<void> Function(Map<String, Map<String, dynamic>> progress)
    persistLocal,
  }) async {
    final fence = CloudWriteFence(sessions);
    final expectedSession = fence.readySnapshot(uid);
    if (expectedSession == null) {
      return CloudWriteResult.blocked;
    }
    return (await pullTypedFromCloudWithSessionResult(
      sessions: sessions,
      uid: uid,
      expectedSession: expectedSession,
      loadRemote: loadRemote,
      loadLocal: loadLocal,
      persistLocal: persistLocal,
    )).status;
  }

  /// Restores pack progress with an exact session and reports whether Firestore
  /// contained remote progress rather than only an authoritative absence.
  static Future<CloudRestoreComponentResult>
  pullTypedFromCloudWithSessionResult({
    required CloudWriteSessionController sessions,
    required String uid,
    required CloudWriteSession expectedSession,
    required Future<CloudReadResult<FirestorePackSnapshot>> Function()
    loadRemote,
    required Map<String, PackProgress> Function() loadLocal,
    required Future<void> Function(Map<String, Map<String, dynamic>> progress)
    persistLocal,
  }) async {
    final fence = CloudWriteFence(sessions);
    final initial = fence.verify(expectedSession, uid: uid);
    if (initial != CloudWriteResult.completed) {
      return CloudRestoreComponentResult(status: initial, hasRemoteData: false);
    }
    try {
      final result = await loadRemote();
      final afterRead = fence.verify(expectedSession, uid: uid);
      if (afterRead != CloudWriteResult.completed) {
        return CloudRestoreComponentResult(
          status: afterRead,
          hasRemoteData: false,
        );
      }
      if (result.state == CloudReadState.absent) {
        return const CloudRestoreComponentResult(
          status: CloudWriteResult.completed,
          hasRemoteData: false,
        );
      }
      if (!result.isPresent || result.value == null) {
        return const CloudRestoreComponentResult(
          status: CloudWriteResult.blocked,
          hasRemoteData: false,
        );
      }
      final remote = result.value!.progress;
      final localBefore = loadLocal();
      final merged = <String, Map<String, dynamic>>{
        for (final entry in remote.entries) entry.key: entry.value.toJson(),
        for (final entry in localBefore.entries)
          if (!remote.containsKey(entry.key)) entry.key: entry.value.toJson(),
      };
      final beforeWrite = fence.verify(expectedSession, uid: uid);
      if (beforeWrite != CloudWriteResult.completed) {
        return CloudRestoreComponentResult(
          status: beforeWrite,
          hasRemoteData: false,
        );
      }
      await persistLocal(merged);
      final completed = fence.verify(expectedSession, uid: uid);
      return CloudRestoreComponentResult(
        status: completed,
        hasRemoteData:
            completed == CloudWriteResult.completed && remote.isNotEmpty,
      );
    } catch (_) {
      final current = fence.verify(expectedSession, uid: uid);
      return CloudRestoreComponentResult(
        status: current == CloudWriteResult.completed
            ? CloudWriteResult.blocked
            : current,
        hasRemoteData: false,
      );
    }
  }

  static Future<CloudWriteResult> pullFromCloudWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<Map<String, PackProgress>> Function() loadRemote,
    required Map<String, PackProgress> Function() loadLocal,
    required Future<void> Function(Map<String, Map<String, dynamic>> progress)
    persistLocal,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = fence.readySnapshot(uid);
    if (snapshot == null) {
      return CloudWriteResult.blocked;
    }
    final remote = await loadRemote();
    if (remote.isEmpty) {
      return fence.verify(snapshot, uid: uid);
    }
    final localBefore = loadLocal();
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
    final result = fence.verify(snapshot, uid: uid);
    if (result != CloudWriteResult.completed) {
      return result;
    }
    await persistLocal(merged);
    return fence.verify(snapshot, uid: uid);
  }

  /// Lokal → Firestore (Batch). Idempotent.
  static Future<void> pushToCloud() async {
    await pushToCloudWithResult();
  }

  static Future<CloudWriteResult> pushToCloudWithResult() async {
    final local = getAll();
    if (local.isEmpty) {
      return CloudWriteResult.completed;
    }
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      return CloudWriteResult.blocked;
    }
    final sessions = cloudWriteSessionController;
    return pushToCloudWithSession(
      sessions: sessions,
      uid: uid,
      loadLocal: () => local,
      writeRemote: (progresses) async {
        await FirestoreProgressService.saveManyWithSession(
          progresses,
          sessions: sessions,
          uid: uid,
        );
      },
    );
  }

  /// Uploads locally owned pack progress only for the exact session that
  /// completed a first anonymous-to-durable link. The target UID is derived
  /// from [session], so callers cannot redirect this source upload.
  static Future<CloudWriteResult> uploadLocalProgressForFirstDurableLink({
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    Future<CloudWriteResult> Function(Iterable<PackProgress> progresses)?
    writeRemote,
  }) async {
    final fence = CloudWriteFence(sessions);
    final initial = fence.verify(session, uid: session.uid);
    if (initial != CloudWriteResult.completed) return initial;
    final local = getAll();
    if (local.isEmpty) return fence.verify(session, uid: session.uid);

    var remoteResult = CloudWriteResult.blocked;
    try {
      final fenced = await fence.runWithSnapshot(
        snapshot: session,
        uid: session.uid,
        action: () async {
          remoteResult =
              await (writeRemote ??
                  (progresses) => FirestoreProgressService.saveManyWithSession(
                    progresses,
                    sessions: sessions,
                    uid: session.uid,
                  ))(local.values);
        },
      );
      return fenced == CloudWriteResult.completed ? remoteResult : fenced;
    } catch (_) {
      final afterFailure = fence.verify(session, uid: session.uid);
      return afterFailure == CloudWriteResult.completed
          ? CloudWriteResult.blocked
          : afterFailure;
    }
  }

  static Future<CloudWriteResult> pushToCloudWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Map<String, PackProgress> Function() loadLocal,
    Future<void> Function()? prepareRemote,
    required Future<void> Function(Iterable<PackProgress> progresses)
    writeRemote,
  }) async {
    final local = loadLocal();
    if (local.isEmpty) {
      return CloudWriteResult.completed;
    }
    return CloudWriteFence(sessions).run(
      uid: uid,
      prepare: prepareRemote,
      action: () => writeRemote(local.values),
    );
  }

  // ── Komfort-Wrapper für VocabPackService-Konsumenten ──────────────

  /// Lädt alle Packs eines Levels + deren Fortschritt-Status.
  /// Liefert eine Liste in Pack-Reihenfolge mit korrektem locked/available.
  static Future<List<({VocabPack pack, PackProgress progress})>> loadLevelView(
    String level,
  ) async {
    final packs = await VocabPackService.packsForLevel(level);
    final existing = getAll();
    return packs
        .map((p) => (pack: p, progress: effectiveStatus(p, packs, existing)))
        .toList();
  }
}

// firstOrNull-Polyfill für ältere Dart-Targets ist nicht nötig:
// dart:core Iterable.firstOrNull existiert seit Dart 3.0.
