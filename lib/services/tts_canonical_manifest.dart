import 'dart:convert';

import 'package:flutter/services.dart';

import 'tts_cache_key.dart';

/// Client optimization only. The server independently confirms public scope.
final class TtsCanonicalManifest {
  TtsCanonicalManifest._();
  static Future<Set<String>>? _keys;

  static Future<bool> contains(TtsCacheKey key) async {
    try {
      return (await (_keys ??= _load())).contains('${key.voice}/${key.hash}');
    } catch (_) {
      // Never treat an unknown/malformed manifest as permission for public IO.
      _keys = null;
      return false;
    }
  }

  static Future<Set<String>> _load() async {
    final data =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/tts_canonical_manifest.json',
              ),
            )
            as Map<String, dynamic>;
    if (data['schemaVersion'] != 1 || data['cacheRevision'] != 'v3') {
      throw const FormatException('Unsupported canonical TTS manifest');
    }
    final voices = data['voices'] as Map<String, dynamic>;
    final result = <String>{};
    for (final voice in ['female', 'male']) {
      for (final hash in voices[voice] as List<dynamic>) {
        if (hash is! String || !RegExp(r'^[a-f0-9]{40}$').hasMatch(hash)) {
          throw const FormatException('Invalid canonical TTS hash');
        }
        result.add('$voice/$hash');
      }
    }
    return result;
  }
}
