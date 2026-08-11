import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/silben_puzzle.dart';

/// Silben-Kreuz 퍼즐 번들 로더 — smalltalk_loader 와 같은 정적 캐시 패턴.
class SilbenPuzzleLoader {
  SilbenPuzzleLoader._();

  static Map<String, List<SilbenPuzzle>>? _cache;

  /// 레벨(A1/A2/B1/B2) → 퍼즐 목록. 항목 단위 try/catch: 깨진 퍼즐 1개가
  /// 전체 게임을 죽이지 않는다 (scenario_loader 관례).
  static Future<Map<String, List<SilbenPuzzle>>> load() async {
    if (_cache != null) {
      return _cache!;
    }
    final raw = await rootBundle.loadString('assets/data/silben_puzzles.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final levels = json['levels'] as Map<String, dynamic>? ?? {};
    final out = <String, List<SilbenPuzzle>>{};
    for (final entry in levels.entries) {
      final list = <SilbenPuzzle>[];
      for (final item in entry.value as List) {
        try {
          list.add(SilbenPuzzle.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // 깨진 항목은 건너뛴다 — 생성기 검증이 있으므로 사실상 발생 안 함.
        }
      }
      out[entry.key] = list;
    }
    _cache = out;
    return out;
  }
}
