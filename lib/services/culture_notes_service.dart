import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// K-Culture 연결 노트 — 단어에 붙는 문화 배경(장르/문화 수준의 검증 가능한 사실).
///
/// 소스: `assets/data/culture_notes.json`. ⚠️ 특정 곡/드라마 가사 인용은 정확성
/// 검증(Jin) 후에만 추가 — 현재 시드는 환각 위험 없는 문화 사실만(§0).
class CultureNote {
  final String ko;
  final String kind; // kpop | drama | culture | film
  final String de;
  final String en;

  const CultureNote({
    required this.ko,
    required this.kind,
    required this.de,
    required this.en,
  });

  factory CultureNote.fromJson(Map<String, dynamic> j) => CultureNote(
    ko: j['ko'] as String? ?? '',
    kind: j['kind'] as String? ?? 'culture',
    de: j['de'] as String? ?? '',
    en: j['en'] as String? ?? '',
  );

  /// UI 언어 텍스트(폴백 독일어).
  String text(String lang) => lang == 'en' && en.isNotEmpty ? en : de;
}

class CultureNotesService {
  CultureNotesService._();

  static Map<String, CultureNote>? _byKo;

  static Future<void> load() async {
    if (_byKo != null) {
      return;
    }
    final raw = await rootBundle.loadString('assets/data/culture_notes.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = (data['notes'] as List? ?? const [])
        .map((e) => CultureNote.fromJson(e as Map<String, dynamic>))
        .where((n) => n.ko.isNotEmpty)
        .toList();
    _byKo = {for (final n in list) n.ko: n};
  }

  /// 로드된 전 노트(테스트/무결성 검사). 미로드 시 빈 맵.
  static Map<String, CultureNote> get all => _byKo ?? const {};

  /// 단어에 대한 노트(없으면 null). [load] 선행 필요.
  static CultureNote? noteFor(String korean) => _byKo?[korean.trim()];

  /// 테스트용 리셋.
  static void resetForTesting() => _byKo = null;
}
