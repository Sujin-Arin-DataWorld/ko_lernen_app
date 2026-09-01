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

  // These v3 objects were repaired in place after a short-audio quality audit.
  // Keep the Firebase Storage address stable, but change the on-device filename
  // once so existing installs do not keep serving the pre-repair MP3 forever.
  static const Set<String> _repairedLocalObjects = {
    'male/d0aa6f25aa4c1abc4afd7d1ab002cb55bc2e9835', // ㄸ -> 뜨
    'male/c17588a37a25849721d35dae4f5d828cc7de18ad', // ㅅ -> 스
    'male/b8bdbdf02eca21ee5d73b752a33ee92bdc8ecdfb', // ㅆ -> 쓰
    'male/3cf9c1367922d7b932bc6ee63a7f0f3dad4fc603', // ㅇ, ㅡ -> 으
    'male/cb86a9f0f9945ff35acf4961de907ef5456c95d2', // ㅈ -> 즈
    'male/5984ad6f79f83f3c4fe380aef8b8f2e85e5fd2dd', // ㅍ -> 프
    'male/7b27abc9b671f2ee0a67c1fe7a3ea7eac747a2f3', // ㅎ -> 흐
    'male/fb11e3d2284d895ded6279715d553f27d8bb2108', // ㅐ -> 애
    'male/57e0698b2094054f7eeb4123d6e3f95bb526430c', // ㅑ -> 야
    'male/f23650e31619922cf6e5eb1844cf3d078dd3ba78', // ㅔ -> 에
    'male/efea22068544b7462809c4604616787a10c63146', // ㅘ -> 와
    'male/b3aad82d33e11a81e3a8ecdab282eb5aa5144144', // ㅙ -> 왜
    'male/cb2f40e9f2b0afd1dccb02b47316c80212aac4ca', // ㅛ -> 요
    'male/b2c63c258d0e6b77ff2e6e0f22796bfdcb634237', // ㅟ -> 위
    'female/cad639c2539393f15c209d28e6fafca1a5b2f1fa', // ㅏ -> 아
    'female/662671c8dd7a7227c19fa2bb6a80461df64613ff', // ㅖ -> 예
    'female/ccac758c8dd0ded66ea779dd1767abd9daaa3db7', // ㅠ -> 유
  };

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
  String get localFileName {
    final repairSuffix = _repairedLocalObjects.contains('$voice/$hash')
        ? '_r1'
        : '';
    return 'tts_${revision}_${voice}_$hash$repairSuffix.mp3';
  }

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
