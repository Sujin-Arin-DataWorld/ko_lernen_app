import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario.dart';

/// Lädt und cached Szenarien aus `assets/data/scenarios.json`.
/// Singleton-Pattern wie [DataLoader].
class ScenarioLoader {
  static List<Scenario>? _cached;
  static String? lastError;

  static Future<List<Scenario>> load() async {
    if (_cached != null) return _cached!;
    try {
      final raw = await rootBundle.loadString('assets/data/scenarios.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['scenarios'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Scenario.fromJson)
          .toList();
      _cached = list;
      lastError = null;
      return list;
    } catch (e) {
      lastError = 'Szenarien konnten nicht geladen werden: $e';
      _cached = [];
      return _cached!;
    }
  }

  static Scenario? byId(String id) {
    for (final s in (_cached ?? const <Scenario>[])) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<Scenario> byLevel(LearnerLevel level) =>
      (_cached ?? const <Scenario>[]).where((s) => s.level == level).toList();

  /// Cache invalidieren — z.B. nach reset oder Hot-Reload.
  static void reset() {
    _cached = null;
    lastError = null;
  }
}
