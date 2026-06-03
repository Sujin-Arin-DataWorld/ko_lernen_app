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
      // Pro Szenario parsen: eine fehlerhafte Definition darf NICHT die ganze
      // Liste leeren (sonst verschwindet der ganze Szenarien-Hub). Defekte
      // Einträge werden übersprungen statt die App-weite Liste zu werfen.
      final list = <Scenario>[];
      var skipped = 0;
      for (final e in (json['scenarios'] as List? ?? const [])) {
        if (e is! Map<String, dynamic>) {
          skipped++;
          continue;
        }
        try {
          list.add(Scenario.fromJson(e));
        } catch (err) {
          skipped++;
        }
      }
      _cached = list;
      lastError = (list.isEmpty && skipped > 0)
          ? 'Keine gültigen Szenarien ($skipped übersprungen).'
          : null;
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
