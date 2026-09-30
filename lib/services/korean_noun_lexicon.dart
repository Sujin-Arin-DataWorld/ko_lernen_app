import 'dart:convert';

import 'package:flutter/services.dart';

/// Positive-only offline evidence. Missing words may still be valid Korean.
abstract final class KoreanNounLexicon {
  static Set<String>? _words;

  static Future<Set<String>> load() async {
    if (_words case final words?) {
      return words;
    }
    final raw = await rootBundle.loadString(
      'assets/data/kkeunmari_nouns.json',
      cache: false,
    );
    final document = jsonDecode(raw) as Map<String, dynamic>;
    final words = (document['words'] as List).cast<String>().toSet();
    if (words.isEmpty ||
        words.any((w) => !RegExp(r'^[가-힣]{1,20}$').hasMatch(w))) {
      throw const FormatException('Invalid offline noun index');
    }
    return _words = Set<String>.unmodifiable(words);
  }

  static Future<bool> contains(String word) async =>
      (await load()).contains(word);
}
