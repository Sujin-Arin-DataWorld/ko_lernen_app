import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tts_cache_key.dart';

/// Validated rootBundle authority for canonical first-dialog TTS audio.
///
/// The manifest never scans arbitrary bundle paths.  Only rows that explicitly
/// declare `bundled: true` can populate this lookup.  [load] only validates
/// *metadata* (schema/key/path-format/duplicate keys) — it never touches the
/// declared mp3 bytes.  Actual bytes are read, MP3-shape-checked, and
/// SHA-256-verified lazily, one row at a time, the first time [bytesFor] is
/// asked for that key; the outcome (bytes or null) is memoised so a repeated
/// request never re-reads or re-hashes the asset.  This keeps first-utterance
/// latency independent of how many rows the manifest declares.
final class TtsBundledManifest {
  TtsBundledManifest._(this._rowsByCacheKey);

  static const String assetPath = 'assets/data/tts_first_line_manifest.json';

  static AssetBundle _bundle = rootBundle;
  static Future<TtsBundledManifest>? _loading;

  final Map<String, _BundledRow> _rowsByCacheKey;

  /// Per-key memoised outcome of a bytes resolution attempt (bytes, or null
  /// on any read/validation failure). Absence of a key here just means
  /// "not requested yet" — see [_bytesLoading] for in-flight de-duplication.
  final Map<String, Uint8List?> _bytesCache = <String, Uint8List?>{};
  final Map<String, Future<Uint8List?>> _bytesLoading =
      <String, Future<Uint8List?>>{};

  static Future<TtsBundledManifest> load() {
    return _loading ??= _loadValidated(_bundle);
  }

  String? assetFor(TtsCacheKey key) => _rowsByCacheKey[_lookupKey(key)]?.path;

  /// Lazily loads, validates (MP3 shape + SHA-256), and memoises the bytes
  /// declared for [key]'s row. Never throws — a missing row, a missing
  /// asset, an MPEG-shape failure, or a hash mismatch all resolve to `null`
  /// so callers fall through to the existing disk → Storage → callable
  /// chain. Concurrent requests for the same key share one underlying read.
  Future<Uint8List?> bytesFor(TtsCacheKey key) {
    final lookup = _lookupKey(key);
    if (_bytesCache.containsKey(lookup)) {
      return Future<Uint8List?>.value(_bytesCache[lookup]);
    }
    return _bytesLoading.putIfAbsent(lookup, () => _resolveBytes(lookup));
  }

  Future<Uint8List?> _resolveBytes(String lookup) async {
    Uint8List? resolved;
    try {
      resolved = await _readAndValidate(lookup);
    } finally {
      _bytesCache[lookup] = resolved;
      _bytesLoading.remove(lookup);
    }
    return resolved;
  }

  Future<Uint8List?> _readAndValidate(String lookup) async {
    final row = _rowsByCacheKey[lookup];
    if (row == null) {
      return null;
    }
    try {
      final data = await _bundle.load(row.path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (!TtsCacheKey.isUsableAudio(bytes)) {
        return null;
      }
      if (sha256.convert(bytes).toString() != row.sha256) {
        return null;
      }
      return bytes;
    } catch (_) {
      // Missing/corrupt declared asset — never throw out of bytesFor.
      return null;
    }
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

    final rows = <String, _BundledRow>{};
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
      // Bytes are intentionally NOT read here — existence, MPEG shape, and
      // SHA-256 are all checked lazily per-key in bytesFor(). Only the
      // metadata shape (path prefix/suffix, 64-hex sha) and duplicate-key
      // conflicts are validated eagerly at load() time.
      final lookup = _lookupKey(key);
      final previous = rows[lookup];
      if (previous != null && previous.path != bundledPath) {
        throw FormatException(
          'Conflicting duplicate TTS cache key: ${key.storagePath}',
        );
      }
      rows[lookup] = _BundledRow(bundledPath, expectedSha256);
    }
    if (decoded['bundledCount'] != bundledCount) {
      throw const FormatException('TTS bundled manifest bundled count drift');
    }
    return TtsBundledManifest._(Map.unmodifiable(rows));
  }

  static String _lookupKey(TtsCacheKey key) =>
      '${key.revision}/${key.voice}/${key.hash}';
}

/// One manifest-declared bundled row: the asset path to read and the
/// SHA-256 the bytes must hash to. Validated for format at [load] time;
/// the bytes themselves are only fetched lazily via [TtsBundledManifest.bytesFor].
final class _BundledRow {
  const _BundledRow(this.path, this.sha256);
  final String path;
  final String sha256;
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
