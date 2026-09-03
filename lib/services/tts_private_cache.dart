import 'dart:typed_data';

import 'account/cloud_write_session.dart';
import 'tts_cache_key.dart';

/// Personal audio never enters the shared on-disk/public learning cache.
/// Session changes clear bytes synchronously and fence pending completions.
final class TtsPrivateCache {
  TtsPrivateCache({
    required this.sessions,
    DateTime Function()? now,
    this.onInvalidate,
  }) : _now = now ?? DateTime.now {
    sessions.changes.addListener(_sessionChanged);
  }

  final CloudWriteSessionController sessions;
  final DateTime Function() _now;
  final void Function()? onInvalidate;
  final Map<String, ({Uint8List bytes, DateTime expiresAt})> _entries = {};
  int _generation = 0;
  bool _disposed = false;

  Future<Uint8List?> resolve(
    String key, {
    required Future<Uint8List?> Function() fetch,
    DateTime? Function()? serverExpiry,
  }) async {
    final session = sessions.current;
    if (_disposed || session == null || session.mode != CloudWriteMode.ready) {
      return null;
    }
    final generation = _generation;
    final scoped = '${session.uid}|${session.epoch}|$key';
    final cached = _entries[scoped];
    if (cached != null && _now().isBefore(cached.expiresAt)) {
      return cached.bytes;
    }
    _entries.remove(scoped);
    final startedAt = _now();
    final bytes = await fetch();
    if (_disposed ||
        generation != _generation ||
        sessions.current != session ||
        bytes == null ||
        !TtsCacheKey.isUsableAudio(bytes)) {
      return null;
    }
    final localExpiry = startedAt.add(const Duration(hours: 24));
    final remoteExpiry = serverExpiry?.call();
    if (serverExpiry != null && remoteExpiry == null) {
      return null;
    }
    final expiresAt = remoteExpiry != null && remoteExpiry.isBefore(localExpiry)
        ? remoteExpiry
        : localExpiry;
    if (!_now().isBefore(expiresAt)) {
      return null;
    }
    if (_entries.length >= 128) {
      _entries.remove(_entries.keys.first);
    }
    _entries[scoped] = (bytes: bytes, expiresAt: expiresAt);
    return bytes;
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
