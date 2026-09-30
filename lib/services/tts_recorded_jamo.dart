import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'tts_cache_key.dart';

/// Jin's human recordings prepared for the Hangul letter lessons.
///
/// Only callers that explicitly request [voiceTag] use these bytes. A missing
/// or altered asset falls through to the normal TTS path.
final class TtsRecordedJamo {
  TtsRecordedJamo._();

  static const voiceTag = 'recorded-jamo';

  // The user listened to and accepted ㄷ, ㅡ, and ㅢ separately.
  static const letters = <String>{'ㄷ', 'ㅡ', 'ㅢ'};

  static bool hasLetter(String letter) => letters.contains(letter);

  static bool hasCarrier(String syllable) => _assets.containsKey(syllable);

  static const _assets = <String, (String, String)>{
    '드': (
      'de',
      '287bb1e345148d7e9b65f15bc020ccbb818b9fc921c374d1a2ad323b96c31459',
    ),
    '으': (
      'eu',
      '5f2027f947407b9a8256333037ceb4d43282bb7250e5a25c6839e54bdd431c8d',
    ),
    '의': (
      'ui',
      'cd08f26226a7b4813592938d298080a60480dc9ef6a9f8e71e6d5f1a4cdd801a',
    ),
  };

  static final Map<String, Future<Uint8List?>> _loading = {};

  static Future<Uint8List?> bytesForCarrier(String text) =>
      _loading.putIfAbsent(text.trim(), () => _load(text.trim()));

  static Future<Uint8List?> _load(String text) async {
    final entry = _assets[text];
    if (entry == null) {
      return null;
    }
    try {
      final data = await rootBundle.load(
        'assets/tts/recorded_jamo/${entry.$1}.mp3',
      );
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (!TtsCacheKey.isUsableAudio(bytes)) {
        return null;
      }
      if (sha256.convert(bytes).toString() != entry.$2) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
