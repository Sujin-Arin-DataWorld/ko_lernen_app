import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario.dart';

/// Lädt und cached Szenarien aus `assets/data/scenarios_{level}.json`
/// (6 Level-Shards seit 2026-08-17). Singleton-Pattern wie [DataLoader].
class ScenarioLoader {
  static const List<LearnerLevel> shardLevels = LearnerLevel.values;

  static List<Scenario>? _cached;
  static String? lastError;

  static String shardPath(LearnerLevel level) =>
      'assets/data/scenarios_${level.code}.json';

  /// Parst einen Shard und meldet die Zahl der übersprungenen Einträge.
  /// Eine fehlerhafte Definition darf NICHT die ganze Liste leeren (sonst
  /// verschwindet der ganze Szenarien-Hub).
  static int _parseInto(String raw, List<Scenario> into) {
    var skipped = 0;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in (json['scenarios'] as List? ?? const [])) {
      if (e is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      try {
        into.add(Scenario.fromJson(e));
      } catch (err) {
        skipped++;
      }
    }
    return skipped;
  }

  /// Alle Level. Für Korpus-weite Konsumenten (Kurs-Katalog, Wortschatz-Suche).
  static Future<List<Scenario>> load() async {
    if (_cached != null) {
      return _cached!;
    }
    final list = <Scenario>[];
    var skipped = 0;
    final failed = <String>[];
    for (final level in shardLevels) {
      try {
        skipped += _parseInto(
          await rootBundle.loadString(shardPath(level)),
          list,
        );
      } catch (e) {
        // Ein fehlender Shard darf die anderen fünf Level nicht mitnehmen.
        failed.add(level.code);
      }
    }
    _cached = list;
    if (failed.isNotEmpty) {
      lastError = 'Szenarien-Shards fehlgeschlagen: ${failed.join(", ")}';
    } else if (list.isEmpty && skipped > 0) {
      lastError = 'Keine gültigen Szenarien ($skipped übersprungen).';
    } else {
      lastError = null;
    }
    return list;
  }

  static Scenario? byId(String id) {
    for (final s in (_cached ?? const <Scenario>[])) {
      if (s.id == id) {
        return s;
      }
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
