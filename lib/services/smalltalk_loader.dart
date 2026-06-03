import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/smalltalk.dart';

/// Lädt und cached den Small-talk-Korpus aus `assets/data/smalltalk.json`.
/// Pattern wie [ScenarioLoader] — best-effort, wirft nie.
class SmalltalkLoader {
  static List<SmalltalkCategory>? _cats;
  static List<SmalltalkPhrase>? _phrases;
  static String? lastError;

  static Future<void> load() async {
    if (_phrases != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/smalltalk.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cats = (json['categories'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SmalltalkCategory.fromJson)
          .toList();
      _phrases = (json['phrases'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SmalltalkPhrase.fromJson)
          .toList();
      lastError = null;
    } catch (e) {
      lastError = 'Small talk konnte nicht geladen werden: $e';
      _cats = [];
      _phrases = [];
    }
  }

  static List<SmalltalkCategory> get categories => _cats ?? const [];
  static List<SmalltalkPhrase> get phrases => _phrases ?? const [];

  /// Phrasen einer Kategorie, optional auf ein Level gefiltert (null = alle).
  static List<SmalltalkPhrase> filter({
    required String category,
    String? level,
  }) =>
      phrases
          .where((p) =>
              p.category == category && (level == null || p.level == level))
          .toList();

  static void reset() {
    _cats = null;
    _phrases = null;
    lastError = null;
  }
}
