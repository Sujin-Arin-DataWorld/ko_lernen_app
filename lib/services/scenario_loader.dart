import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
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

  /// §W2-Task7 (검수#6): 순수 함수 — 외부 상태를 뮤테이션하지 않는다.
  /// compute() 로 isolate 에 보내면 인자와 반환값만 복사되므로, 예전
  /// `_parseInto(raw, into)` 처럼 호출자의 리스트를 직접 채우는 방식은
  /// isolate 경계에서 그 변경분이 소실된다(복사본만 바뀐다) — 반드시
  /// 리턴값(튜플)으로만 결과를 전달한다.
  ///
  /// 에러 처리: 파싱 불가 항목(Map 이 아니거나 fromJson 실패)은 건너뛰고
  /// (skipped 카운트) 나머지 유효한 항목은 보존한다 — 하나 깨졌다고 전체
  /// 샤드가 비어선 안 된다.
  static (List<Scenario>, int) _parseShard(String raw) {
    final scenarios = <Scenario>[];
    var skipped = 0;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in (json['scenarios'] as List? ?? const [])) {
      if (e is! Map<String, dynamic>) {
        skipped++;
        continue;
      }
      try {
        scenarios.add(Scenario.fromJson(e));
      } catch (err) {
        skipped++;
      }
    }
    return (scenarios, skipped);
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
        final raw = await rootBundle.loadString(shardPath(level));
        final (parsed, shardSkipped) = await compute(_parseShard, raw);
        list.addAll(parsed);
        skipped += shardSkipped;
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

  /// Wie viele Level-Shards gleichzeitig im Speicher bleiben dürfen (Spec §6).
  static const int maxResidentShards = 2;

  static final Map<LearnerLevel, List<Scenario>> _shards = {};
  static final List<LearnerLevel> _lru = [];

  /// Resident shards, ältester zuerst. Test-Seam.
  static List<LearnerLevel> get residentLevels => List.unmodifiable(_lru);

  /// Lädt nur den Shard eines Levels. Das Regal (Hören) braucht die anderen
  /// fünf Level nicht — bei 3.600 Szenarien wären das 22 MB statt 3,7 MB.
  static Future<List<Scenario>> loadLevel(LearnerLevel level) async {
    final full = _cached;
    if (full != null) {
      // Voller Korpus liegt schon: kein zweites Lesen derselben Daten.
      return full.where((s) => s.level == level).toList();
    }
    final resident = _shards[level];
    if (resident != null) {
      _touch(level);
      return resident;
    }
    final list = <Scenario>[];
    try {
      final raw = await rootBundle.loadString(shardPath(level));
      final (parsed, _) = await compute(_parseShard, raw);
      list.addAll(parsed);
      lastError = null;
    } catch (e) {
      lastError = 'Szenarien (${level.code}) konnten nicht geladen werden: $e';
    }
    _shards[level] = list;
    _touch(level);
    while (_lru.length > maxResidentShards) {
      _shards.remove(_lru.removeAt(0));
    }
    return list;
  }

  static void _touch(LearnerLevel level) {
    _lru.remove(level);
    _lru.add(level);
  }

  static Scenario? byId(String id) {
    for (final s in (_cached ?? const <Scenario>[])) {
      if (s.id == id) {
        return s;
      }
    }
    for (final shard in _shards.values) {
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    return null;
  }

  /// §W2-Task7 (P5-1): id 기준으로 시나리오를 찾되, 전체 코퍼스가 아직
  /// 캐시돼 있지 않으면 [preferredLevel] 샤드부터 먼저 읽는다.
  /// `scenario_player_screen.dart` 는 예전에 `load()`(전체 6샤드)를 부른
  /// 뒤 `byId()` 로 걸러냈다 — id 하나를 찾으려고 매번 전 코퍼스를 당겼다.
  static Future<Scenario?> findById(
    String id, {
    LearnerLevel? preferredLevel,
  }) async {
    if (_cached != null) {
      return byId(id);
    }
    if (preferredLevel != null) {
      final shard = await loadLevel(preferredLevel);
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    for (final level in shardLevels) {
      if (level == preferredLevel) {
        continue;
      }
      final shard = await loadLevel(level);
      for (final s in shard) {
        if (s.id == id) {
          return s;
        }
      }
    }
    return null;
  }

  static List<Scenario> byLevel(LearnerLevel level) =>
      (_cached ?? const <Scenario>[]).where((s) => s.level == level).toList();

  /// Cache invalidieren — z.B. nach reset oder Hot-Reload.
  static void reset() {
    _cached = null;
    _shards.clear();
    _lru.clear();
    lastError = null;
  }
}
