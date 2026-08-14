import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario.dart';

/// 끝말잇기 (Word Chain) 엔진.
///
/// `assets/data/kkeunmari_pool.json` 의 큐레이션 단어 풀(2,634 단어)을 사용한다.
/// 각 단어에는 `first`/`last` 음절과 `is_dead_end` 메타데이터가 있다.
/// (2026-06-18: OpenSubtitles 자막조각 미번역 2,061개 제거 후 next_count/is_dead_end 재계산.)
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

  /// A verified dictionary word that is not yet represented in the bundled
  /// game pool. The tiger still takes its next turn from the curated pool.
  factory KkeunmariWord.dictionary(String word) {
    final normalized = word.trim();
    return KkeunmariWord(
      word: normalized,
      first: normalized[0],
      last: normalized[normalized.length - 1],
      level: 'dictionary',
      german: '',
      topic: 'dictionary',
      nextCount: 0,
      isDeadEnd: false,
    );
  }
}

class KkeunmariEngine {
  static List<KkeunmariWord>? _cached;
  static final _rng = Random();
  static String? lastError;

  static Future<List<KkeunmariWord>> load() async {
    if (_cached != null) return _cached!;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/kkeunmari_pool.json',
      );
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

  /// Test seam for deterministic level-scope and chain-viability probes.
  /// Production code always populates the pool through [load].
  static void setPoolForTesting(List<KkeunmariWord> words) {
    _cached = List<KkeunmariWord>.unmodifiable(words);
    lastError = null;
  }

  static List<KkeunmariWord> _cumulativePool(LearnerLevel? maxLevel) {
    if (maxLevel == null) {
      return pool;
    }
    return pool.where((word) {
      final wordLevel = LearnerLevel.fromCode(word.level);
      return wordLevel != null && wordLevel.rank <= maxLevel.rank;
    }).toList();
  }

  static List<KkeunmariWord> _availableCandidates(
    Iterable<KkeunmariWord> source,
    Set<String> usedWords, {
    String? requiredFirst,
  }) {
    return source.where((word) {
      if (usedWords.contains(word.word)) {
        return false;
      }
      return requiredFirst == null || word.first == requiredFirst;
    }).toList();
  }

  /// The bundle's `next_count` and `is_dead_end` fields describe the complete
  /// pool. Once a learner-level subset and used-word set are applied, calculate
  /// viability from that live subset instead.
  static int _liveNextCount(
    KkeunmariWord word,
    Iterable<KkeunmariWord> source,
    Set<String> usedWords,
  ) {
    return source
        .where(
          (candidate) =>
              candidate.word != word.word &&
              !usedWords.contains(candidate.word) &&
              candidate.first == word.last,
        )
        .length;
  }

  /// Returns live candidates in fairness order for the current subset.
  ///
  /// `next_count` in the asset describes the complete, unused corpus. A game
  /// turn has a smaller scope: words above the learner level and words already
  /// played are unavailable. Two or more live replies keep the next learner
  /// turn resilient, so prefer those first; one live reply remains a valid
  /// chain and must stay inside the scoped pool before considering fallback.
  static List<KkeunmariWord> _prioritizedLiveCandidates(
    List<KkeunmariWord> candidates,
    Iterable<KkeunmariWord> source,
    Set<String> usedWords,
  ) {
    final liveCounts = <KkeunmariWord, int>{
      for (final word in candidates)
        word: _liveNextCount(word, source, usedWords),
    };
    final safe = candidates
        .where((word) => (liveCounts[word] ?? 0) >= 2)
        .toList();
    if (safe.isNotEmpty) {
      return safe;
    }
    return candidates.where((word) => (liveCounts[word] ?? 0) >= 1).toList();
  }

  /// "안전한" 시작 단어 — 현재 살아 있는 후보 집합 안에 후속 단어가 있는 것을 우선.
  ///
  /// With [maxLevel], candidates first come from the cumulative A1..level
  /// subset. If that subset has no live chain, the full pool is used as a
  /// fallback so a sparse B1/B2 pool cannot create an unwinnable opening.
  static KkeunmariWord pickStart({LearnerLevel? maxLevel}) {
    final usedWords = <String>{};
    final scoped = _cumulativePool(maxLevel);
    final scopedCandidates = _availableCandidates(scoped, usedWords);
    final scopedLive = _prioritizedLiveCandidates(
      scopedCandidates,
      scoped,
      usedWords,
    );
    if (scopedLive.isNotEmpty) {
      return scopedLive[_rng.nextInt(scopedLive.length)];
    }

    final allCandidates = _availableCandidates(pool, usedWords);
    final allLive = _prioritizedLiveCandidates(allCandidates, pool, usedWords);
    final source = allLive.isNotEmpty
        ? allLive
        : (scopedCandidates.isNotEmpty ? scopedCandidates : allCandidates);
    return source[_rng.nextInt(source.length)];
  }

  static KkeunmariWord? findExact(String word) {
    for (final w in pool) {
      if (w.word == word) return w;
    }
    return null;
  }

  /// 호랑이의 다음 단어 — [requiredFirst] 음절로 시작하는 미사용 단어 중 선택.
  /// Candidate set the tiger may use for this turn.
  ///
  /// The returned list uses the same cumulative-scope, live-chain and
  /// full-pool fallback rules as [pickTigerNext]. Keeping the choice in one
  /// place means the UI's dynamic next-count cannot disagree with the move
  /// the tiger will actually make.
  static List<KkeunmariWord> _tigerCandidates(
    String requiredFirst,
    Set<String> usedWords, {
    LearnerLevel? maxLevel,
  }) {
    final scoped = _cumulativePool(maxLevel);
    final scopedCandidates = _availableCandidates(
      scoped,
      usedWords,
      requiredFirst: requiredFirst,
    );
    final scopedLive = _prioritizedLiveCandidates(
      scopedCandidates,
      scoped,
      usedWords,
    );
    if (scopedLive.isNotEmpty) {
      return scopedLive;
    }

    final allCandidates = _availableCandidates(
      pool,
      usedWords,
      requiredFirst: requiredFirst,
    );
    if (allCandidates.isEmpty) {
      return const [];
    }
    final allLive = _prioritizedLiveCandidates(allCandidates, pool, usedWords);
    return allLive.isNotEmpty
        ? allLive
        : (scopedCandidates.isNotEmpty ? scopedCandidates : allCandidates);
  }

  /// Current number of viable tiger replies under the active learner scope.
  ///
  /// This deliberately does *not* read a record's persisted `next_count`.
  /// Used words and the cumulative A1..current-level subset change every
  /// turn, so only the live candidate list is authoritative in play.
  static int nextCountFor(
    String requiredFirst,
    Set<String> usedWords, {
    LearnerLevel? maxLevel,
  }) => _tigerCandidates(requiredFirst, usedWords, maxLevel: maxLevel).length;

  /// Selects a fair tiger reply from the current live candidate set.
  ///
  /// A null return means no allowed reply exists → tiger is stuck and the
  /// learner wins the turn.
  static KkeunmariWord? pickTigerNext(
    String requiredFirst,
    Set<String> usedWords, {
    LearnerLevel? maxLevel,
  }) {
    final source = _tigerCandidates(
      requiredFirst,
      usedWords,
      maxLevel: maxLevel,
    );
    if (source.isEmpty) {
      return null;
    }
    return source[_rng.nextInt(source.length)];
  }

  /// 사용자의 다음 단어가 유효한지 검증.
  /// 반환: (유효, 사유 코드 — 'ok' | 'not_in_pool' | 'wrong_start' | 'already_used' | 'not_korean')
  ///
  /// **v2 (2026-05-29)**: validation 우선순위 재배치 — wrong_start를 not_in_pool보다
  /// 먼저 검사해 사용자에게 더 즉시적인 피드백. 또한 한글이 아닌 입력은
  /// 별도 사유로 분리해 안내가 명확하도록 함.
  static (bool valid, String reason, KkeunmariWord? word) validateUserWord(
    String input,
    String requiredFirst,
    Set<String> usedWords,
  ) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return (false, 'not_in_pool', null);
    // Hangul only check (Unicode 0xAC00..0xD7A3 syllable block)
    final isHangul = trimmed.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3);
    if (!isHangul) return (false, 'not_korean', null);
    // wrong_start first — most actionable hint
    if (trimmed[0] != requiredFirst) return (false, 'wrong_start', null);
    final w = findExact(trimmed);
    if (w == null) return (false, 'not_in_pool', null);
    if (usedWords.contains(w.word)) return (false, 'already_used', w);
    return (true, 'ok', w);
  }

  static void reset() {
    _cached = null;
    lastError = null;
  }
}
