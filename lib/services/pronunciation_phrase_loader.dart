import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/pronunciation_phrase.dart';

/// Loads the reviewed pronunciation corpus. A broken asset fails closed: no
/// empty string can reach TTS or the remote assessment request.
class PronunciationPhraseLoader {
  PronunciationPhraseLoader._();

  static const assetPath = 'assets/data/pronunciation_phrases.json';

  static List<PronunciationPhrase>? _cache;
  static String? lastError;

  static Future<List<PronunciationPhrase>> load() async {
    if (_cache != null) {
      return _cache!;
    }
    try {
      final raw = await rootBundle.loadString(assetPath);
      _cache = parse(raw);
      lastError = null;
      return _cache!;
    } catch (error) {
      lastError = 'Pronunciation phrases could not be loaded: $error';
      _cache = const <PronunciationPhrase>[];
      return _cache!;
    }
  }

  /// Parses the versioned JSON source. This pure seam is shared by tests and
  /// content tooling, while [load] owns the safe runtime fallback.
  static List<PronunciationPhrase> parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'pronunciation_phrases.json must contain an object',
      );
    }

    final root = Map<String, dynamic>.from(decoded);
    final version = root['version'];
    if (version is! int || version < 1) {
      throw const FormatException(
        'pronunciation_phrases.json requires a positive integer version',
      );
    }

    final rawPhrases = root['phrases'];
    if (rawPhrases is! List) {
      throw const FormatException(
        'pronunciation_phrases.json requires a phrases array',
      );
    }

    final ids = <String>{};
    final phrases = <PronunciationPhrase>[];
    for (final entry in rawPhrases) {
      if (entry is! Map) {
        throw const FormatException(
          'Every pronunciation phrase must be an object',
        );
      }
      final phrase = PronunciationPhrase.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (!ids.add(phrase.id)) {
        throw FormatException(
          'Duplicate pronunciation phrase id: ${phrase.id}',
        );
      }
      phrases.add(phrase);
    }
    return List<PronunciationPhrase>.unmodifiable(phrases);
  }

  /// Invalidates a failed or stale bundle before an explicit screen retry.
  static void reset() {
    _cache = null;
    lastError = null;
  }
}
