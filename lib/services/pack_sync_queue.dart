import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/pack_progress.dart';
import 'auth_service.dart';
import 'diagnostics_service.dart';
import 'firestore_progress_service.dart';
import 'storage_service.dart';

/// Debounces the Firestore *backup* mirror of pack progress.
///
/// **Problem (S3, plan §S3)**: `PackProgressService._persist` used to
/// fire-and-forget `FirestoreProgressService.savePack` on every single
/// `recordWordLearned` / `recordBossAttempt` call — one Firestore
/// read + two writes per call, ~90k ops/day at 1k DAU.
///
/// **Fix**: keep only the LATEST [PackProgress] per `packId` in memory and
/// flush to Firestore on the earliest of three triggers:
///  - a `status` transition (any change vs. what was last known for that
///    pack) *or* reaching a terminal status (`cleared`) — flushed
///    immediately regardless of whether a prior status was known, so a
///    "cleared" doc (which drives server-side Gye crediting and
///    cross-device restore/next-pack-unlock) is never left waiting on the
///    idle timer, including right after a cold start (R2/R4 durability
///    review, see [enqueue]);
///  - an idle timer, [idleDuration] (default 30s) after the *last*
///    [enqueue] — a burst of same-status updates (e.g. repeated
///    `recordWordLearned` while flipping cards through a pack) collapses
///    into a single write;
///  - [flushAll], called from the app-lifecycle observer when the app is
///    about to leave the foreground — so nothing pending is lost if the
///    idle timer hasn't fired yet.
///
/// **Durability across a kill (R2/R4)**: every [enqueue] and every
/// completed [flush] pass persists the current pending-id set to
/// [Storage.pendingPackSyncIds]. If the process dies before any trigger
/// flushes a pack, [flushPendingFromStorage] — called once at the next
/// startup — reloads those ids' local JSON and retries.
///
/// Local storage (`Storage.setPackProgressJson`) is untouched by this
/// class and stays synchronous in `PackProgressService._persist` — this
/// queue only debounces the Firestore backup mirror. Local-first,
/// progress-loss-0 is preserved: the worst case of losing a queued entry
/// is a delayed cloud backup, never the local record.
///
/// **No mirror, no Timer**: [enqueue] first checks `canMirror` — by
/// default, a real Firebase app plus a signed-in backup-eligible uid. When
/// that's false (no Firebase app at all, as in most widget/unit tests; or
/// a signed-out learner) [enqueue] is a full no-op — no `_pending` entry,
/// no [Timer]. Arming a 30s [Timer] that could never fire a real save is
/// exactly what left a "Timer still pending after dispose" failure across
/// 55 widget-test files once this queue started scheduling one on every
/// `_persist` call, including in test environments with no Firebase app.
class PackSyncQueue {
  PackSyncQueue({
    Future<void> Function(PackProgress p)? savePack,
    this.idleDuration = const Duration(seconds: 30),
    Timer Function(Duration duration, void Function() callback)? createTimer,
    DateTime Function()? clock,
    bool Function()? canMirror,
  }) : _savePack = savePack ?? FirestoreProgressService.savePack,
       _createTimer = createTimer ?? Timer.new,
       _clock = clock ?? DateTime.now,
       _canMirror = canMirror ?? _defaultCanMirror;

  /// Singleton used by production code. Tests may swap it wholesale via
  /// [resetForTesting] to inject a fake `savePack` / timer / clock.
  static PackSyncQueue instance = PackSyncQueue();

  @visibleForTesting
  static void resetForTesting() {
    instance._idleTimer?.cancel();
    instance = PackSyncQueue();
  }

  final Future<void> Function(PackProgress p) _savePack;
  final Duration idleDuration;
  final Timer Function(Duration duration, void Function() callback)
  _createTimer;
  // Reserved for future use (e.g. timestamping diagnostics) and to satisfy
  // the injectable-clock test seam the design calls for; the debounce logic
  // itself is expressed entirely in terms of [Timer].
  final DateTime Function() _clock;
  final bool Function() _canMirror;

  final Map<String, PackProgress> _pending = {};
  final Map<String, PackStatus> _lastKnownStatus = {};
  Timer? _idleTimer;
  Future<void>? _inFlightFlush;

  /// Test/debug seam: packs currently waiting for a flush.
  @visibleForTesting
  int get pendingCount => _pending.length;

  @visibleForTesting
  DateTime get clockNow => _clock();

  @visibleForTesting
  bool get canMirrorForTesting => _canMirror();

  /// True when a Firestore write for the current user could plausibly
  /// succeed right now: a Firebase app exists *and* someone is signed in
  /// with a backup-eligible uid. When false there is nothing to mirror —
  /// not "mirror later once idle", genuinely nothing (no app, e.g. most
  /// widget/unit tests; or no uid, e.g. a signed-out learner, whose data
  /// the daily `CloudAutoSync` picks up once they do sign in).
  ///
  /// Mirrors `FirestoreProgressService`'s own private `_db` try/catch
  /// exactly (that getter isn't accessible from here — a different session
  /// owns that file for this PR stack) rather than depending on a shared
  /// accessor that doesn't exist yet.
  static bool _defaultCanMirror() =>
      _tryFirestoreInstance() != null && AuthService.cloudBackupUid != null;

  static FirebaseFirestore? _tryFirestoreInstance() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Records the latest known state for `p.packId`, replacing whatever was
  /// queued before, and persists the pending-id set (durability gap B — a
  /// kill right after this call still leaves the id in
  /// [Storage.pendingPackSyncIds] for [flushPendingFromStorage] to pick up).
  ///
  /// Triggers an immediate [flush] when either:
  ///  - the status differs from the last one known for this pack, where
  ///    "last known" prefers the caller-supplied [previousStatus] (which
  ///    `PackProgressService._persist` reads from `Storage` *before*
  ///    overwriting it with `p`, so it reflects the true pre-write value
  ///    even on the very first `enqueue` call of a fresh process/queue —
  ///    the naive approach of reading `Storage` for the first sighting
  ///    *inside* this method doesn't work: by the time `enqueue` runs,
  ///    `_persist` has already overwritten local storage with `p` itself),
  ///    falling back to this queue's own in-memory history and then, only
  ///    for a caller that supplies neither, a lazy one-time read of
  ///    `Storage` (best-effort for callers outside `_persist`); or
  ///  - [PackProgress.status] is [PackStatus.cleared] — unconditionally,
  ///    regardless of any previous-status bookkeeping, since that's the one
  ///    status server-side crediting and cross-device restore depend on.
  ///
  /// Otherwise (re)starts the idle timer.
  ///
  /// When [canMirrorForTesting] (i.e. [_canMirror]) is false — no Firebase
  /// app, or nobody signed in — this returns immediately without touching
  /// `_pending`, `_lastKnownStatus`, `Storage.pendingPackSyncIds`, or
  /// arming a [Timer] at all. Before this queue existed, `_persist`'s
  /// fire-and-forget `savePack` was already a silent no-op in exactly that
  /// situation (`FirestoreProgressService` checks the same two things
  /// itself); the difference is this queue used to still *schedule a real
  /// 30s Timer* regardless, which a torn-down widget-test tree then saw as
  /// "still pending" and failed the test on — see the 55-file CI failure
  /// this guard fixes.
  void enqueue(PackProgress p, {PackStatus? previousStatus}) {
    if (!_canMirror()) {
      return;
    }
    _pending[p.packId] = p;
    unawaited(_syncPendingIdsToStorage());

    final effectivePrevious =
        previousStatus ??
        _lastKnownStatus[p.packId] ??
        _seedStatusFromStorage(p.packId);
    _lastKnownStatus[p.packId] = p.status;

    final changed =
        effectivePrevious != null && effectivePrevious != p.status;
    final isTerminal = p.status == PackStatus.cleared;

    _idleTimer?.cancel();
    if (changed || isTerminal) {
      _idleTimer = null;
      unawaited(flush());
      return;
    }
    _idleTimer = _createTimer(idleDuration, () {
      unawaited(flush());
    });
  }

  PackStatus? _seedStatusFromStorage(String packId) {
    final persisted = Storage.packProgressJson(packId);
    if (persisted == null) {
      return null;
    }
    return PackProgress.fromJson(packId, persisted).status;
  }

  /// Flushes every pack currently queued, once each, sequentially. A
  /// concurrent call while a flush is already running returns the same
  /// in-flight future rather than starting a second pass.
  Future<void> flush() {
    final inFlight = _inFlightFlush;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _flush();
    _inFlightFlush = future;
    return future.whenComplete(() {
      _inFlightFlush = null;
    });
  }

  /// Alias for [flush] called from the app-lifecycle observer on
  /// pause/detach/hide, so a pending pack isn't lost if the app is killed
  /// before the idle timer fires.
  Future<void> flushAll() => flush();

  /// Recovers packs orphaned by a process kill that happened before any
  /// trigger flushed them (durability gap B). Reads
  /// [Storage.pendingPackSyncIds], reloads each id's local JSON via
  /// [Storage.packProgressJson], re-enqueues it in memory, and flushes.
  ///
  /// An id with no recoverable local JSON is dropped (nothing left to
  /// sync). Call this once at startup, and only once cloud backup is
  /// actually usable (see the call site in `main.dart` for why that can't
  /// simply be "after `_startCloudServices()`" — its completion isn't
  /// awaited by the caller) — an id left untouched here just stays in
  /// `Storage` for the next launch to retry.
  ///
  /// Respects the same [_canMirror] guard as [enqueue]: if mirroring isn't
  /// currently possible, this is a no-op and leaves every id exactly where
  /// it was in `Storage` for a later call to try again.
  Future<void> flushPendingFromStorage() async {
    if (!_canMirror()) {
      return;
    }
    final ids = Storage.pendingPackSyncIds;
    for (final packId in ids) {
      if (_pending.containsKey(packId)) {
        continue; // Already tracked (e.g. a re-entrant call).
      }
      final json = Storage.packProgressJson(packId);
      if (json == null) {
        continue; // Nothing local left to recover; dropped by the sync below.
      }
      final progress = PackProgress.fromJson(packId, json);
      _pending[packId] = progress;
      _lastKnownStatus[packId] = progress.status;
    }
    await flush();
  }

  Future<void> _syncPendingIdsToStorage() =>
      Storage.setPendingPackSyncIds(_pending.keys.toList()..sort());

  Future<void> _flush() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    // Snapshot the keys up front: an enqueue() that arrives while this loop
    // awaits a save stays queued for the *next* trigger instead of being
    // swept up half-written.
    final packIds = _pending.keys.toList(growable: false);
    for (final packId in packIds) {
      final progress = _pending[packId];
      if (progress == null) {
        continue; // Already flushed by a re-entrant call.
      }
      try {
        await _savePack(progress);
        // Only drop it if nothing newer replaced it while this awaited.
        if (identical(_pending[packId], progress)) {
          _pending.remove(packId);
        }
      } catch (error, stackTrace) {
        // ignore: discarded_futures
        await DiagnosticsService.reportSwallowed(
          'pack_sync_queue.flush',
          error,
          stackTrace,
        );
        // Left queued — retried on the next enqueue/idle/flushAll trigger.
      }
    }
    // Reflect the post-flush state (removals and retained failures alike)
    // in Storage — durability gap B.
    await _syncPendingIdsToStorage();
  }
}
