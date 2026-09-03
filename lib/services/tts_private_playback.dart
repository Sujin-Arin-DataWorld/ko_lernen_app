import 'package:flutter/services.dart';

enum PrivateTtsRoute { bytes, iosMemory, denied }

/// iOS must not use audioplayers BytesSource: that adapter writes a temp file.
/// The app-owned bridge holds AVAudioPlayer(data:) until completion or stop.
final class TtsPrivatePlayback {
  TtsPrivatePlayback([
    this._channel = const MethodChannel('hangul_sori/private_tts'),
  ]);

  final MethodChannel _channel;
  int _nextId = 0;
  int? _activeId;
  int? _pendingStopId;

  static PrivateTtsRoute routeFor(
    TargetPlatform platform, {
    bool isWeb = false,
  }) {
    if (isWeb || platform == TargetPlatform.android) {
      return PrivateTtsRoute.bytes;
    }
    if (platform == TargetPlatform.iOS) {
      return PrivateTtsRoute.iosMemory;
    }
    // Desktop private playback has no audited memory-only backend yet.
    return PrivateTtsRoute.denied;
  }

  Future<bool> play(
    Uint8List bytes, {
    required double rate,
    required double volume,
    required bool Function() isCurrent,
  }) async {
    if (_pendingStopId != null) {
      try {
        await stop();
      } catch (_) {
        return false;
      }
    }
    if (!isCurrent()) {
      return false;
    }
    final id = ++_nextId;
    _activeId = id;
    try {
      final completed = await _channel.invokeMethod<bool>('play', {
        'id': id,
        'bytes': bytes,
        'rate': rate,
        'volume': volume,
      });
      return _activeId == id && isCurrent() && completed == true;
    } catch (_) {
      // Never surface platform error payloads containing personal data.
      return false;
    } finally {
      if (_activeId == id) {
        _activeId = null;
      }
    }
  }

  Future<void> stop() async {
    final id = _activeId ?? _pendingStopId;
    _activeId =
        null; // Fence a completion before crossing the platform channel.
    if (id == null) {
      return;
    }
    _pendingStopId = id;
    await _channel.invokeMethod<void>('stop', {'id': id});
    if (_pendingStopId == id) {
      _pendingStopId = null;
    }
  }
}
