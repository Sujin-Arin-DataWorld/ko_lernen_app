import '../models/book_page.dart';
import '../models/vocab.dart';
import 'book_analysis_text.dart';
import 'book_ocr_document.dart';
import 'data_loader.dart';

/// O1 (three-tier OCR gloss resolver) — Owner decision D-6.
///
/// Offline learners photograph a Korean textbook page and get **zero** word
/// meanings today (`_localStub` in `book_analysis_service.dart` always
/// returned `words: const []`). This resolver fills that gap without ever
/// calling the network, using three tiers in priority order:
///
///   ① bundled  — `assets/data/korean_vocab.csv` (2,499 curated headwords),
///      matched after stripping a Korean particle or a verb/adjective
///      conjugation ending from each OCR token.
///   ② pageHint — the German/English gloss the book itself printed next to
///      the word (`BookOcrUnit.foreignHints`, or a Latin-only OCR line that
///      immediately follows a single-word unit in the same OCR block).
///   ③ server   — whatever `analyze_korean_text` already resolved. Passed in
///      via [resolve]'s `serverWords` and always wins on a conflict.
///
/// [resolve] itself only ever performs tiers ① and ②; the caller decides
/// whether tier ③ words are available (offline: none; online: the parsed
/// cloud response).
class BookWordGlossResolver {
  static Map<String, List<Vocab>>? _indexCache;

  /// Korean particles this resolver strips from a candidate token, in no
  /// particular order — the longest one that is actually a suffix of the
  /// token (leaving a non-empty stem) is the one used, tried once.
  static const List<String> kParticleSuffixes = [
    '에서는',
    '에게서',
    '으로는',
    '께서',
    '에게',
    '에서',
    '으로',
    '부터',
    '까지',
    '처럼',
    '보다',
    '이나',
    '한테',
    '은',
    '는',
    '이',
    '가',
    '을',
    '를',
    '에',
    '도',
    '만',
    '의',
    '로',
    '과',
    '와',
    '랑',
    '께',
  ];

  /// Verb/adjective conjugation endings recognised for the stem+다 lookup.
  static const List<String> kVerbEndings = [
    '었어요',
    '았어요',
    '습니다',
    '니다',
    '세요',
    '아요',
    '어요',
    '요',
  ];

  /// Basic vowel-contraction fallbacks: a contracted stem syllable mapped to
  /// the dictionary stem syllable before appending 다 (봐 -> 보다, not 봐다).
  static const Map<String, String> _vowelContractionFallback = {
    '해': '하',
    '봐': '보',
    '와': '오',
    '줘': '주',
  };

  static final RegExp _hangulRun = RegExp(r'[가-힣]+');
  static final RegExp _latinLetter = RegExp(r'[A-Za-zÀ-ɏ]');

  Future<Map<String, List<Vocab>>> _vocabIndex() async {
    final cachedIndex = _indexCache;
    if (cachedIndex != null) return cachedIndex;
    final vocab = await DataLoader.loadVocab();
    final index = <String, List<Vocab>>{};
    for (final entry in vocab) {
      index.putIfAbsent(entry.korean, () => <Vocab>[]).add(entry);
    }
    _indexCache = index;
    return index;
  }

  /// Resolves every Hangul token in [doc]'s analysis units against the
  /// bundled dictionary (tier ①) and, failing that, a same-block printed
  /// gloss (tier ②) — then merges in [serverWords] (tier ③), which always
  /// wins a conflict on the same headword. Results are de-duplicated by
  /// headword.
  Future<List<ExtractedWord>> resolve(
    BookOcrDocument doc, {
    required String targetLang,
    List<ExtractedWord> serverWords = const [],
  }) async {
    final index = await _vocabIndex();
    final resolved = <String, ExtractedWord>{};

    for (final unit in doc.analysisUnits) {
      final tokens = _hangulTokens(unit.korean);
      if (tokens.isEmpty) {
        continue;
      }
      final isSingleWordUnit =
          tokens.length == 1 && !unit.korean.contains(RegExp(r'\s'));

      for (final token in tokens) {
        final match = _resolveAgainstVocab(index, token);
        if (match != null) {
          resolved.putIfAbsent(
            match.vocab.korean,
            () => _wordFromVocab(match.vocab, unit, ambiguous: match.ambiguous),
          );
          continue;
        }
        if (!isSingleWordUnit) {
          continue;
        }
        final hint = _pageHintFor(doc, unit);
        if (hint == null) {
          continue;
        }
        resolved.putIfAbsent(
          unit.korean,
          () => ExtractedWord(
            korean: unit.korean,
            romanization: '',
            posDe: '',
            translationDe: hint,
            translationEn: '',
            exampleKorean: '',
            exampleDe: '',
            savedToPackId: null,
            sourceUnitId: unit.id,
            source: 'pageHint',
            confidence: 0.6,
          ),
        );
      }
    }

    for (final serverWord in serverWords) {
      resolved[serverWord.korean] = serverWord.copyWith(
        source: 'server',
        confidence: 0.9,
      );
    }

    return resolved.values.toList(growable: false);
  }

  List<String> _hangulTokens(String text) =>
      _hangulRun.allMatches(text).map((m) => m.group(0)!).toList(growable: false);

  _VocabMatch? _resolveAgainstVocab(
    Map<String, List<Vocab>> index,
    String token,
  ) {
    var hit = index[token];
    if (hit == null || hit.isEmpty) {
      final stripped = _stripLongestParticle(token);
      if (stripped != null) {
        hit = index[stripped];
      }
    }
    if (hit == null || hit.isEmpty) {
      for (final candidate in _verbHeadwordCandidates(token)) {
        final verbHit = index[candidate];
        if (verbHit != null && verbHit.isNotEmpty) {
          hit = verbHit;
          break;
        }
      }
    }
    if (hit == null || hit.isEmpty) {
      return null;
    }
    return _VocabMatch(hit.first, hit.length > 1);
  }

  /// Longest-match-once particle stripping. Tries the token itself is
  /// handled by the caller (direct index lookup); this only produces the
  /// single stripped candidate, if any particle suffix actually applies.
  String? _stripLongestParticle(String token) {
    String? longestSuffix;
    for (final suffix in kParticleSuffixes) {
      if (token.length <= suffix.length || !token.endsWith(suffix)) {
        continue;
      }
      if (longestSuffix == null || suffix.length > longestSuffix.length) {
        longestSuffix = suffix;
      }
    }
    if (longestSuffix == null) {
      return null;
    }
    return token.substring(0, token.length - longestSuffix.length);
  }

  /// Verb/adjective stem candidates ending in 다, longest-ending-match once,
  /// with a small vowel-contraction fallback (봐 -> 보다, not 봐다).
  List<String> _verbHeadwordCandidates(String token) {
    String? longestEnding;
    for (final ending in kVerbEndings) {
      if (token.length <= ending.length || !token.endsWith(ending)) {
        continue;
      }
      if (longestEnding == null || ending.length > longestEnding.length) {
        longestEnding = ending;
      }
    }
    if (longestEnding == null) {
      return const [];
    }
    final stem = token.substring(0, token.length - longestEnding.length);
    if (stem.isEmpty) {
      return const [];
    }
    final candidates = <String>['$stem다'];
    final contracted = _vowelContractionFallback[stem];
    if (contracted != null) {
      candidates.add('$contracted다');
    }
    return candidates;
  }

  ExtractedWord _wordFromVocab(
    Vocab vocab,
    BookOcrUnit unit, {
    required bool ambiguous,
  }) => ExtractedWord(
    korean: vocab.korean,
    romanization: vocab.romanization,
    posDe: vocab.posDe,
    translationDe: vocab.german,
    translationEn: vocab.english,
    translationLanguage: 'de',
    exampleKorean: vocab.exampleKorean,
    exampleDe: vocab.exampleGerman,
    exampleEn: vocab.exampleEnglish,
    savedToPackId: null,
    sourceUnitId: unit.id,
    source: 'bundled',
    confidence: 1.0,
    ambiguous: ambiguous,
  );

  /// Tier ②. Only ever called for a single-word unit (no spaces). Prefers an
  /// inline hint already captured on the same OCR line (`unit.foreignHints`,
  /// e.g. "학교 - School"); otherwise looks at the very next physical OCR
  /// line in the same block/region — the common "word list" layout where the
  /// gloss is printed directly under the Korean word. A hint is accepted
  /// only when it is Latin-only (no Hangul); anything else, or a line that
  /// is not immediately adjacent, is ignored.
  String? _pageHintFor(BookOcrDocument doc, BookOcrUnit unit) {
    for (final hint in unit.foreignHints) {
      if (_isLatinOnlyGloss(hint.text)) {
        return hint.text.trim();
      }
    }
    if (unit.sourceLineIds.isEmpty) {
      return null;
    }
    final lastLineId = unit.sourceLineIds.last;
    for (final region in doc.regions) {
      final lineIndex = region.lines.indexWhere(
        (line) => line.sourceLineId == lastLineId,
      );
      if (lineIndex == -1) {
        continue;
      }
      if (lineIndex + 1 >= region.lines.length) {
        return null;
      }
      final nextLineText = region.lines[lineIndex + 1].text;
      return _isLatinOnlyGloss(nextLineText) ? nextLineText.trim() : null;
    }
    return null;
  }

  bool _isLatinOnlyGloss(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (BookAnalysisTextPreprocessor.containsHangulSyllable(trimmed)) {
      return false;
    }
    return _latinLetter.hasMatch(trimmed);
  }
}

class _VocabMatch {
  const _VocabMatch(this.vocab, this.ambiguous);

  final Vocab vocab;
  final bool ambiguous;
}
