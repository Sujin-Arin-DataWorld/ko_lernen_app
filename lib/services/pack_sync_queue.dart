import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/pack_progress.dart';
import 'diagnostics_service.dart';
import 'firestore_progress_service.dart';

/// Debounces the Firestore *backup* mirror of pack progress.
///
/// **Problem (S3, plan §S3)**: `PackProgressService._persist` used to
/// fire-and-forget `FirestoreProgressService.savePack` on every single
/// `recordWordLearned` / `recordBossAttempt` call — one Firestore
/// read + two writes per call, ~90k ops/day at 1k DAU.
///
/// **Fix**: keep only the LATEST [PackProgress] per `packId` in memory and
/// flush to Firestore on the earliest of three triggers:
///  - a `status` transition (any change, including reaching `cleared`) —
///    flushed immediately so cross-device state (next-pack unlock, the
///    "cleared" stamp) shows up promptly;
///  - an idle timer, [idleDuration] (default 30s) after the *last*
///    [enqueue] — a burst of same-status updates (e.g. repeated
///    `recordWordLearned` while flipping cards through a pack) collapses
///    into a single write;
///  - [flushAll], called from the app-lifecycle observer when the app is
///    about to leave the foreground — so nothing pending is lost if the
///    idle timer hasn't fired yet.
///
/// Local storage (`Storage.setPackProgressJson`) is untouched by this
/// class and stays synchronous in `PackProgressService._persist` — this
/// queue only debounces the Firestore backup mirror. Local-first,
/// progress-loss-0 is preserved: the worst case of losing a queued entry
/// (e.g. the process is killed before any trigger fires) only delays the
/// cloud backup, never the local record.
class PackSyncQueue {
  PackSyncQueue({
    Future<void> Function(PackProgress p)? savePack,
    this.idleDuration = const Duration(seconds: 30),
    Timer Function(Duration duration, void Function() callback)? createTimer,
    DateTime Function()? clock,
  }) : _savePack = savePack ?? FirestoreProgressService.savePack,
       _createTimer = createTimer ?? Timer.new,
       _clock = clock ?? DateTime.now;

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

  final Map<String, PackProgress> _pending = {};
  final Map<String, PackStatus> _lastKnownStatus = {};
  Timer? _idleTimer;
  Future<void>? _inFlightFlush;

  /// Test/debug seam: packs currently waiting for a flush.
  @visibleForTesting
  int get pendingCount => _pending.length;

  @visibleForTesting
  DateTime get clockNow => _clock();

  /// Records the latest known state for `p.packId`, replacing whatever was
  /// queued before. Triggers an immediate [flush] when `p.status` differs
  /// from the last state this queue has seen for that pack; otherwise
  /// (re)starts the idle timer.
  void enqueue(PackProgress p) {
    _pending[p.packId] = p;
    final previousStatus = _lastKnownStatus[p.packId];
    _lastKnownStatus[p.packId] = p.status;
    final isTransition = previousStatus != null && previousStatus != p.status;

    _idleTimer?.cancel();
    if (isTransition) {
      _idleTimer = null;
      unawaited(flush());
      return;
    }
    _idleTimer = _createTimer(idleDuration, () {
      unawaited(flush());
    });
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
  }
}
