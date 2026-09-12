import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tts_cache_key.dart';
import 'tts_canonical_manifest.dart';

/// Reviewed corpus bytes for Web previews without Firebase app setup.
/// Storage still enforces canonical metadata in storage.rules. No download
/// tokens, user text, credentials, or private paths are sent.
final class TtsPublicWebAudio {
  static Future<Uint8List?> read(
    TtsCacheKey key, {
    required int maxBytes,
    required Duration timeout,
    http.Client? client,
  }) async {
    if (!await TtsCanonicalManifest.contains(key)) return null;
    final transport = client ?? http.Client();
    try {
      return await (() async {
        final uri = Uri(
          scheme: 'https',
          host: 'firebasestorage.googleapis.com',
          pathSegments: [
            'v0',
            'b',
            'ko-lernen-app.firebasestorage.app',
            'o',
            key.storagePath,
          ],
          queryParameters: {'alt': 'media'},
        );
        final request = http.Request('GET', uri)..followRedirects = false;
        final response = await transport.send(request);
        if (response.statusCode != 200 ||
            (response.contentLength != null &&
                response.contentLength! > maxBytes)) {
          return null;
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > maxBytes) return null;
          bytes.add(chunk);
        }
        final data = bytes.takeBytes();
        return TtsCacheKey.isUsableAudio(data) ? data : null;
      })().timeout(timeout);
    } catch (_) {
      return null;
    } finally {
      if (client == null) transport.close();
    }
  }
}
