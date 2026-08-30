import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable, revisioned address for one synthesized TTS request.
///
/// The same `{voice}|{text}` SHA-1 input is deliberately shared with the
/// Cloud Function and `tool/generate_tts.py`.
final class TtsCacheKey {
  const TtsCacheKey._({
    required this.revision,
    required this.voice,
    required this.hash,
  });

  static const String currentRevision = 'v3';

  factory TtsCacheKey.forRequest({
    required String voice,
    required String text,
  }) {
    final normalizedVoice = voice == 'male' ? 'male' : 'female';
    final normalizedText = text.trim();
    final hash = sha1
        .convert(utf8.encode('$normalizedVoice|$normalizedText'))
        .toString();
    return TtsCacheKey._(
      revision: currentRevision,
      voice: normalizedVoice,
      hash: hash,
    );
  }

  final String revision;
  final String voice;
  final String hash;

  String get storagePath => 'tts/$revision/$voice/$hash.mp3';
  String get localFileName => 'tts_${revision}_${voice}_$hash.mp3';

  /// Same MPEG/ID3 floor the Cloud Function uses before treating bytes as audio.
  static bool isUsableAudio(List<int> data) {
    if (data.length < 32) {
      return false;
    }
    if (data[0] == 0x49 && data[1] == 0x44 && data[2] == 0x33) {
      return true;
    }
    return data[0] == 0xFF && (data[1] & 0xE0) == 0xE0;
  }
}
