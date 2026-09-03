import 'dart:typed_data';

import 'account/cloud_write_session.dart';
import 'tts_cache_key.dart';

typedef TtsPrivateServerTiming = ({int serverNowMillis, int expiresAtMillis});

/// Bytes and their original validity travel together; cache hits never mint a
/// new deadline. A resolved payload is also revoked by clear/session/dispose.
final class TtsPrivateAudio {
  TtsPrivateAudio._(this.bytes, this.session, this._remaining);
  final Uint8List bytes;
  final CloudWriteSession session;
  final Duration Function() _remaining;
  Duration get remaining => _remaining();
  bool get isCurrent => remaining > Duration.zero;
}

final class _PrivateDeadline {
  _PrivateDeadline(
    this.budget,
    this.startedWall,
    this.startedElapsed,
    this.now,
    this.elapsed,
  ) : lastWall = startedWall,
      lastElapsed = startedElapsed;
  final Duration budget;
  final DateTime startedWall;
  final Duration startedElapsed;
  final DateTime Function() now;
  final Duration Function() elapsed;
  DateTime lastWall;
  Duration lastElapsed;
  bool expired = false;

  Duration get remaining {
    if (expired) {
      return Duration.zero;
    }
    final wall = now();
    final monotonic = elapsed();
    if (wall.isBefore(lastWall) || monotonic < lastElapsed) {
      expired = true;
      return Duration.zero;
    }
    lastWall = wall;
    lastElapsed = monotonic;
    final wallAge = wall.difference(startedWall);
    final monotonicAge = monotonic - startedElapsed;
    final age = wallAge > monotonicAge ? wallAge : monotonicAge;
    if (age >= budget) {
      expired = true;
      return Duration.zero;
    }
    return budget - age;
  }
}

/// Personal audio never enters the shared on-disk/public learning cache.
/// Session changes clear bytes synchronously and fence pending completions.
final class TtsPrivateCache {
  TtsPrivateCache({
    required this.sessions,
    DateTime Function()? now,
    Duration Function()? elapsed,
    this.onInvalidate,
  }) : _now = now ?? DateTime.now,
       _elapsed = elapsed ?? _monotonicNow {
    sessions.changes.addListener(_sessionChanged);
  }

  final CloudWriteSessionController sessions;
  final DateTime Function() _now;
  static final Stopwatch _clock = Stopwatch()..start();
  static Duration _monotonicNow() => _clock.elapsed;
  final Duration Function() _elapsed;
  final void Function()? onInvalidate;
  final Map<String, TtsPrivateAudio> _entries = {};
  int _generation = 0;
  bool _disposed = false;

  Future<TtsPrivateAudio?> resolve(
    String key, {
    required Future<Uint8List?> Function() fetch,
    required TtsPrivateServerTiming? Function() serverTiming,
  }) async {
    final session = sessions.current;
    if (_disposed || session == null || session.mode != CloudWriteMode.ready) {
      return null;
    }
    final generation = _generation;
    final scoped = '${session.uid}|${session.epoch}|$key';
    final cached = _entries[scoped];
    if (cached != null && cached.isCurrent) {
      return cached;
    }
    _entries.remove(scoped);
    final startedAt = _now();
    final startedElapsed = _elapsed();
    final bytes = await fetch();
    if (_disposed ||
        generation != _generation ||
        sessions.current != session ||
        bytes == null ||
        !TtsCacheKey.isUsableAudio(bytes)) {
      return null;
    }
    final timing = serverTiming();
    if (timing == null || timing.serverNowMillis < 0) {
      return null;
    }
    final remainingMillis = timing.expiresAtMillis - timing.serverNowMillis;
    if (remainingMillis <= 0 ||
        remainingMillis > const Duration(hours: 24).inMilliseconds) {
      return null;
    }
    // Subtract the entire request duration, not just response transit. This is
    // deliberately conservative and independent of device/server clock skew.
    final deadline = _PrivateDeadline(
      Duration(milliseconds: remainingMillis),
      startedAt,
      startedElapsed,
      _now,
      _elapsed,
    );
    final audio = TtsPrivateAudio._(
      bytes,
      session,
      () =>
          !_disposed && generation == _generation && sessions.current == session
          ? deadline.remaining
          : Duration.zero,
    );
    if (!audio.isCurrent) {
      return null;
    }
    if (_entries.length >= 128) {
      _entries.remove(_entries.keys.first);
    }
    _entries[scoped] = audio;
    return audio;
  }

  void clear() {
    _generation++;
    _entries.clear();
  }

  void _sessionChanged() {
    clear();
    onInvalidate?.call();
  }

  void dispose() {
    sessions.changes.removeListener(_sessionChanged);
    _disposed = true;
    clear();
  }
}
