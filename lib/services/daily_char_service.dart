import '../data/hangul_data.dart';

/// 매일 결정성으로 1글자 추천 — DOY 기반 rotation.
///
/// Pool: 자음(19) + 모음(15) + 자주 쓰는 음절 16 = 50 chars
/// (rotation 50일 주기 → 매일 다른 글자).
class DailyCharService {
  /// 오늘 추천 글자.
  static String today() {
    final pool = _pool;
    if (pool.isEmpty) return '가';
    final d = DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year)).inDays;
    return pool[dayOfYear % pool.length];
  }

  /// 글자가 자음/모음/음절 중 어느 카테고리?
  static String categoryOf(String char) {
    if (consonants.any((c) => c.letter == char)) return 'consonant';
    if (vowels.any((v) => v.letter == char)) return 'vowel';
    return 'syllable';
  }

  static List<String> get _pool {
    final list = <String>[];
    for (final c in consonants) {
      list.add(c.letter);
    }
    for (final v in vowels) {
      list.add(v.letter);
    }
    for (final s in syllables) {
      list.add(s.letter);
    }
    return list;
  }
}
