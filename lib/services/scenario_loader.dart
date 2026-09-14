import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario.dart';

/// Lädt und cached Szenarien aus `assets/data/scenarios_{level}.json`
/// (6 Level-Shards seit 2026-08-17). Singleton-Pattern wie [DataLoader].
class ScenarioLoader {
  static const List<LearnerLevel> shardLevels = LearnerLevel.values;

  static List<Scenario>? _cached;
  static Future<List<Scenario>>? _pending;
  static int _generation = 0;
  static final Map<LearnerLevel, Future<(List<Scenario>, int)>>
  _pendingShardParses = {};
  static String? lastError;
  static String? _fullCorpusError;

  /// Failure of the cached full corpus, independent of later level reads.
  static String? get fullCorpusError => _fullCorpusError;

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
  static Future<List<Scenario>> load() {
    if (_cached != null) {
      return Future.value(_cached!);
    }
    return _pending ??= _loadAll(_generation);
  }

  static Future<List<Scenario>> _loadAll(int generation) async {
    final list = <Scenario>[];
    var skipped = 0;
    final failed = <String>[];
    for (final level in shardLevels) {
      try {
        final (parsed, shardSkipped) = await _loadShard(level, generation);
        list.addAll(parsed);
        skipped += shardSkipped;
      } catch (e) {
        // Ein fehlender Shard darf die anderen fünf Level nicht mitnehmen.
        failed.add(level.code);
      }
    }
    if (generation == _generation) {
      _cached = list;
      _pending = null;
      if (failed.isNotEmpty) {
        _fullCorpusError =
            'Szenarien-Shards fehlgeschlagen: ${failed.join(", ")}';
      } else if (list.isEmpty && skipped > 0) {
        _fullCorpusError = 'Keine gültigen Szenarien ($skipped übersprungen).';
      } else {
        _fullCorpusError = null;
      }
      lastError = _fullCorpusError;
    }
    return list;
  }

  /// Full-corpus and level readers share the same pending isolate parse.
  /// A reset separates generations, including readers still finishing a corpus.
  static Future<(List<Scenario>, int)> _loadShard(
    LearnerLevel level,
    int generation,
  ) {
    if (generation != _generation) {
      return _readShard(level, generation);
    }
    return _pendingShardParses.putIfAbsent(
      level,
      () => _readShard(level, generation),
    );
  }

  static Future<(List<Scenario>, int)> _readShard(
    LearnerLevel level,
    int generation,
  ) async {
    try {
      final raw = await rootBundle.loadString(shardPath(level));
      return await compute(_parseShard, raw);
    } finally {
      if (generation == _generation) {
        _pendingShardParses.remove(level);
      }
    }
  }

  /// Wie viele Level-Shards gleichzeitig im Speicher bleiben dürfen (Spec §6).
  static const int maxResidentShards = 2;

  static final Map<LearnerLevel, List<Scenario>> _shards = {};
  static final List<LearnerLevel> _lru = [];

  /// Resident shards, ältester zuerst. Test-Seam.
  static List<LearnerLevel> get residentLevels => List.unmodifiable(_lru);

  /// Lädt nur den Shard eines Levels. Das Regal (Hören) braucht die anderen
  /// fünf Level nicht — bei 3.600 Szenarien wären das 22 MB statt 3,7 MB.
  static Future<List<Scenario>> loadLevel(LearnerLevel level) =>
      _loadLevel(level, _generation);

  static Future<List<Scenario>> _loadLevel(
    LearnerLevel level,
    int generation,
  ) async {
    if (generation == _generation) {
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
    }
    List<Scenario> list;
    String? failure;
    try {
      final (parsed, _) = await _loadShard(level, generation);
      list = parsed;
    } catch (e) {
      list = <Scenario>[];
      failure = 'Szenarien (${level.code}) konnten nicht geladen werden: $e';
    }
    if (generation == _generation) {
      lastError = failure;
      _shards[level] = list;
      _touch(level);
      while (_lru.length > maxResidentShards) {
        _shards.remove(_lru.removeAt(0));
      }
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
    // Keep one generation across every await in this multi-level search.
    final generation = _generation;
    if (_cached != null) {
      return byId(id);
    }
    if (preferredLevel != null) {
      final shard = await _loadLevel(preferredLevel, generation);
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
      final shard = await _loadLevel(level, generation);
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
    _generation++;
    _cached = null;
    _pending = null;
    _pendingShardParses.clear();
    _shards.clear();
    _lru.clear();
    lastError = null;
    _fullCorpusError = null;
    for (final level in shardLevels) {
      rootBundle.evict(shardPath(level));
    }
  }
}
