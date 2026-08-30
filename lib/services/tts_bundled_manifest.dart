import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tts_cache_key.dart';

/// Validated rootBundle authority for canonical first-dialog TTS audio.
///
/// The manifest never scans arbitrary bundle paths.  Only rows that explicitly
/// declare `bundled: true` can populate this lookup, and every such row is
/// checked for cache-key parity, MP3 shape, and SHA-256 before use.
final class TtsBundledManifest {
  TtsBundledManifest._(this._assetByCacheKey);

  static const String assetPath = 'assets/data/tts_first_line_manifest.json';

  static AssetBundle _bundle = rootBundle;
  static Future<TtsBundledManifest>? _loading;

  final Map<String, String> _assetByCacheKey;

  static Future<TtsBundledManifest> load() {
    return _loading ??= _loadValidated(_bundle);
  }

  String? assetFor(TtsCacheKey key) => _assetByCacheKey[_lookupKey(key)];

  /// Read through the same injectable bundle used for manifest validation.
  static Future<Uint8List> readAsset(String path) async {
    final data = await _bundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @visibleForTesting
  static void resetForTesting({AssetBundle? bundle}) {
    _bundle = bundle ?? rootBundle;
    _loading = null;
  }

  static Future<TtsBundledManifest> _loadValidated(AssetBundle bundle) async {
    final source = await bundle.loadString(assetPath, cache: false);
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('TTS bundled manifest is invalid JSON: $error');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('TTS bundled manifest must be a JSON object');
    }
    if (decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported TTS bundled manifest schema');
    }
    if (decoded['kind'] != 'tts_first_line_manifest') {
      throw const FormatException('Unexpected TTS bundled manifest kind');
    }
    if (decoded['cacheRevision'] != TtsCacheKey.currentRevision) {
      throw const FormatException('TTS bundled manifest cache revision drift');
    }
    final rawItems = decoded['items'];
    if (rawItems is! List<dynamic>) {
      throw const FormatException('TTS bundled manifest items must be a list');
    }
    if (decoded['scenarioCount'] != rawItems.length) {
      throw const FormatException('TTS bundled manifest scenario count drift');
    }

    final assets = <String, String>{};
    final scenarioIds = <String>{};
    var bundledCount = 0;
    for (var index = 0; index < rawItems.length; index++) {
      final raw = rawItems[index];
      if (raw is! Map<String, dynamic>) {
        throw FormatException('TTS manifest item $index must be an object');
      }
      final scenarioId = raw['scenarioId'];
      if (scenarioId is! String || scenarioId.trim().isEmpty) {
        throw FormatException('TTS manifest item $index has no scenario ID');
      }
      if (!scenarioIds.add(scenarioId)) {
        throw FormatException(
          'Duplicate TTS manifest scenario ID: $scenarioId',
        );
      }
      final voice = raw['voice'];
      final text = raw['normalizedText'];
      final hash = raw['cacheHashSha1'];
      final storagePath = raw['storagePath'];
      if ((voice != 'female' && voice != 'male') ||
          text is! String ||
          text.trim().isEmpty ||
          hash is! String ||
          !RegExp(r'^[0-9a-f]{40}$').hasMatch(hash) ||
          storagePath is! String) {
        throw FormatException(
          'TTS manifest item $index has invalid cache fields',
        );
      }
      final key = TtsCacheKey.forRequest(voice: voice as String, text: text);
      if (key.hash != hash || key.storagePath != storagePath) {
        throw FormatException('TTS manifest item $index cache key drift');
      }

      final bundled = raw['bundled'];
      final bundledPath = raw['bundledAssetPath'];
      final expectedSha256 = raw['bundledSha256'];
      if (bundled is! bool) {
        throw FormatException(
          'TTS manifest item $index has invalid bundled flag',
        );
      }
      if (!bundled) {
        if (bundledPath != null || expectedSha256 != null) {
          throw FormatException(
            'TTS manifest item $index declares bytes while bundled is false',
          );
        }
        continue;
      }
      bundledCount += 1;
      if (bundledPath is! String ||
          !bundledPath.startsWith('assets/tts/') ||
          !bundledPath.endsWith('.mp3') ||
          expectedSha256 is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSha256)) {
        throw FormatException(
          'TTS manifest item $index has invalid bundled metadata',
        );
      }
      final ByteData data;
      try {
        data = await bundle.load(bundledPath);
      } catch (error) {
        throw FormatException(
          'TTS manifest item $index declares a missing asset: $bundledPath ($error)',
        );
      }
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (!TtsCacheKey.isUsableAudio(bytes)) {
        throw FormatException(
          'TTS manifest item $index declares invalid MPEG bytes: $bundledPath',
        );
      }
      final actualSha256 = sha256.convert(bytes).toString();
      if (actualSha256 != expectedSha256) {
        throw FormatException(
          'TTS manifest item $index bundled SHA-256 mismatch: $bundledPath',
        );
      }
      final lookup = _lookupKey(key);
      final previous = assets[lookup];
      if (previous != null && previous != bundledPath) {
        throw FormatException(
          'Conflicting duplicate TTS cache key: ${key.storagePath}',
        );
      }
      assets[lookup] = bundledPath;
    }
    if (decoded['bundledCount'] != bundledCount) {
      throw const FormatException('TTS bundled manifest bundled count drift');
    }
    return TtsBundledManifest._(Map.unmodifiable(assets));
  }

  static String _lookupKey(TtsCacheKey key) =>
      '${key.revision}/${key.voice}/${key.hash}';
}

extension TtsBundledCachePath on TtsCacheKey {
  Future<String?> bundledAssetPath() async {
    try {
      return (await TtsBundledManifest.load()).assetFor(this);
    } catch (_) {
      // An invalid/missing manifest must preserve the existing disk → Storage
      // → callable fallback chain.
      return null;
    }
  }
}
