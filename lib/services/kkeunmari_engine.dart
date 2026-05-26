import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// 끝말잇기 (Word Chain) 엔진.
///
/// `assets/data/kkeunmari_pool.json` 의 노명사 풀(225 단어)을 사용한다.
/// 각 단어에는 `first`/`last` 음절과 `is_dead_end` 메타데이터가 있다.
///
/// 핵심 규칙:
/// - 사용자가 낸 단어의 [last] 음절 = 호랑이가 낼 단어의 [first] 음절.
/// - 같은 단어 재사용 금지.
/// - `is_dead_end: true` 단어는 다음 차례 응답이 거의 불가능 → 게임 종료.
class KkeunmariWord {
  final String word;
  final String first;
  final String last;
  final String level;
  final String german;
  final String topic;
  final int nextCount;
  final bool isDeadEnd;

  const KkeunmariWord({
    required this.word,
    required this.first,
    required this.last,
    required this.level,
    required this.german,
    required this.topic,
    required this.nextCount,
    required this.isDeadEnd,
  });

  factory KkeunmariWord.fromJson(Map<String, dynamic> j) => KkeunmariWord(
        word: (j['word'] as String?) ?? '',
        first: (j['first'] as String?) ?? '',
        last: (j['last'] as String?) ?? '',
        level: (j['level'] as String?) ?? 'A1',
        german: (j['german'] as String?) ?? '',
        topic: (j['topic'] as String?) ?? '',
        nextCount: (j['next_count'] as num?)?.toInt() ?? 0,
        isDeadEnd: (j['is_dead_end'] as bool?) ?? false,
      );
}

class KkeunmariEngine {
  static List<KkeunmariWord>? _cached;
  static final _rng = Random();
  static String? lastError;

  static Future<List<KkeunmariWord>> load() async {
    if (_cached != null) return _cached!;
    try {
      final raw =
          await rootBundle.loadString('assets/data/kkeunmari_pool.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final list = (j['words'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(KkeunmariWord.fromJson)
          .where((w) => w.word.isNotEmpty)
          .toList();
      _cached = list;
      lastError = null;
      return list;
    } catch (e) {
      lastError = 'Kkeunmari pool konnte nicht geladen werden: $e';
      _cached = [];
      return _cached!;
    }
  }

  static List<KkeunmariWord> get pool => _cached ?? const [];

  /// "안전한" 시작 단어 — 후속 단어가 충분히 많은 것 (next_count ≥ 2)을 우선.
  static KkeunmariWord pickStart() {
    final safe = pool.where((w) => !w.isDeadEnd && w.nextCount >= 2).toList();
    final source = safe.isEmpty ? pool : safe;
    return source[_rng.nextInt(source.length)];
  }

  static KkeunmariWord? findExact(String word) {
    for (final w in pool) {
      if (w.word == word) return w;
    }
    return null;
  }

  /// 호랑이의 다음 단어 — [requiredFirst] 음절로 시작하는 미사용 단어 중 선택.
  /// 사용자에게 너무 가혹하지 않도록 가능하면 dead_end가 아닌 단어를 고른다.
  /// 후보가 0이면 null → 호랑이 패배 (사용자 승).
  static KkeunmariWord? pickTigerNext(
    String requiredFirst,
    Set<String> usedWords,
  ) {
    final candidates = pool
        .where((w) =>
            w.first == requiredFirst && !usedWords.contains(w.word))
        .toList();
    if (candidates.isEmpty) return null;
    // Prefer safe (non-dead-end) so the user has a chance to continue.
    final safe = candidates.where((w) => !w.isDeadEnd).toList();
    final source = safe.isNotEmpty ? safe : candidates;
    return source[_rng.nextInt(source.length)];
  }

  /// 사용자의 다음 단어가 유효한지 검증.
  /// 반환: (유효, 사유 코드 — 'ok' | 'not_in_pool' | 'wrong_start' | 'already_used')
  static (bool valid, String reason, KkeunmariWord? word) validateUserWord(
    String input,
    String requiredFirst,
    Set<String> usedWords,
  ) {
    final w = findExact(input.trim());
    if (w == null) return (false, 'not_in_pool', null);
    if (w.first != requiredFirst) return (false, 'wrong_start', w);
    if (usedWords.contains(w.word)) return (false, 'already_used', w);
    return (true, 'ok', w);
  }

  static void reset() {
    _cached = null;
    lastError = null;
  }
}
