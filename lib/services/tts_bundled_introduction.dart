import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tts_cache_key.dart';

/// The introduction's first sound, available before any network or disk cache.
///
/// These are the unchanged canonical Firebase Storage bytes for female|가,
/// using the same v3 address and voice as tool/generate_tts.py. This is separate
/// from the scenario first-line manifest because the introduction is no scenario.
final class TtsBundledIntroduction {
  TtsBundledIntroduction._();

  static const assetPath =
      'assets/tts/v3/female/b53adb4789b4e79b8c4236831af9b0e6a4a39952.mp3';
  static const audioSha256 =
      'db6388578346cd1bbee317fbe30c3ab2f35a7243dff2b873ff75e577d3847d68';
  static final _key = TtsCacheKey.forRequest(voice: 'female', text: '가');

  static AssetBundle _bundle = rootBundle;
  static Future<Uint8List?>? _loading;

  static Future<Uint8List?> bytesFor(TtsCacheKey key) {
    if (key.storagePath != _key.storagePath) {
      return Future<Uint8List?>.value(null);
    }
    return _loading ??= _load();
  }

  static Future<Uint8List?> _load() async {
    try {
      // AssetBundle.load throws for missing assets; retain the existing cache
      // fallbacks on any read or integrity failure.
      // https://api.flutter.dev/flutter/services/AssetBundle/load.html
      final data = await _bundle
          .load(assetPath)
          .timeout(const Duration(seconds: 2));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (!TtsCacheKey.isUsableAudio(bytes) ||
          sha256.convert(bytes).toString() != audioSha256) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void resetForTesting({AssetBundle? bundle}) {
    _bundle = bundle ?? rootBundle;
    _loading = null;
  }
}
