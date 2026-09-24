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
///   ① bundled  — `assets/data/korean_vocab.csv`,
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

  /// Common complete particle chains, matched once rather than recursively.
  /// Bundled nominal headwords can host these particles. Adverbs are limited
  /// to auxiliary chains. Exact words and single-particle phrases stay first.
  static const List<String> _particleChains = [
    '에게서는',
    '에게서도',
    '에게서만',
    '한테서는',
    '한테서도',
    '한테서만',
    '에서만은',
    '으로만은',
    '로만은',
    '에서도',
    '에서만',
    '에게는',
    '에게도',
    '에게만',
    '한테는',
    '한테도',
    '한테만',
    '으로도',
    '으로만',
    '까지는',
    '까지도',
    '까지만',
    '부터는',
    '부터도',
    '부터만',
    '에는',
    '에도',
    '에만',
    '로는',
    '로도',
    '로만',
    '만은',
    '만도',
  ];

  static const Set<String> _nominalPartsOfSpeech = {
    'Nomen',
    'Substantiv',
    'Pronomen',
    'Zahlwort',
  };

  // Time words such as 오늘/내일 are Adverb entries in the bundled corpus.
  // Allow auxiliary chains, but not case chains such as 빨리에게도.
  // Copula hosts remain restricted to the nominal parts of speech above.
  static const Set<String> _adverbParticleChains = {
    '까지는',
    '까지도',
    '까지만',
    '부터는',
    '부터도',
    '부터만',
    '만은',
    '만도',
  };

  /// Complete copula forms; true means the contracted form requires a
  /// vowel-final nominal (친구예요, but not 학생예요). The uncontracted
  /// 이에요/이어요 forms also remain valid after vowels.
  static const Map<String, bool> _copulaForms = {
    '이었습니다': false,
    '였습니다': true,
    '이었어요': false,
    '였어요': true,
    '이에요': false,
    '이어요': false,
    '입니다': false,
    '입니까': false,
    '이었다': false,
    '였다': true,
    '예요': true,
    '여요': true,
    '이다': false,
  };

  /// Basic vowel-contraction fallbacks: a contracted stem syllable mapped to
  /// the dictionary stem syllable before appending 다 (봐 -> 보다, not 봐다).
  static const Map<String, String> _vowelContractionFallback = {
    '해': '하',
    '봐': '보',
    '와': '오',
    '줘': '주',
  };

  /// Common irregular/contraction bases before polite 요 or past ㅆ어요.
  /// These are morphological aliases, never meanings: a real bundled
  /// Verb/Adjektiv must still supply the entry. Do not infer irregularity
  /// solely from a final consonant (잡다, for example, is regular).
  static const Map<String, String> _inflectedPredicateBases = {
    '도와': '돕다',
    '추워': '춥다',
    '더워': '덥다',
    '아름다워': '아름답다',
    '쉬워': '쉽다',
    '어려워': '어렵다',
    '매워': '맵다',
    '몰라': '모르다',
    '불러': '부르다',
    '달라': '다르다',
    '빨라': '빠르다',
    '게을러': '게으르다',
    '서툴러': '서투르다',
    '배불러': '배부르다',
    '골라': '고르다',
    '써': '쓰다',
    '커': '크다',
    '바빠': '바쁘다',
    '예뻐': '예쁘다',
    '슬퍼': '슬프다',
    '그래': '그렇다',
    '들어': '듣다',
    '걸어': '걷다',
  };

  /// Case/locative particles that, when they end the token immediately
  /// preceding a NOUN/VERB(-ADJEKTIV) homograph (예: 가요 = "팝송" 명사 또는
  /// 가다의 -아/어요 활용형), signal that the verb reading is meant — see
  /// [_disambiguateNounVerbHomograph].
  static const List<String> kCaseLocativeParticles = [
    '에서',
    '으로',
    '까지',
    '부터',
    '에',
    '을',
    '를',
    '로',
    '도',
  ];

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

      String? previousToken;
      for (final token in tokens) {
        final match = _resolveAgainstVocab(
          index,
          token,
          previousToken: previousToken,
        );
        previousToken = token;
        if (match != null) {
          // One row represents every occurrence of this headword on the page.
          // An exact occurrence elsewhere does not disambiguate this surface.
          // Keep the first meaning/source, but never drop a later ambiguity.
          resolved.update(
            match.vocab.korean,
            (existing) => existing.copyWith(
              ambiguous: existing.ambiguous || match.ambiguous,
              alternativeHeadword: existing.alternativeHeadword.isNotEmpty
                  ? existing.alternativeHeadword
                  : match.alternativeHeadword,
            ),
            ifAbsent: () => _wordFromVocab(
              match.vocab,
              unit,
              ambiguous: match.ambiguous,
              alternativeHeadword: match.alternativeHeadword,
            ),
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

  List<String> _hangulTokens(String text) => _hangulRun
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList(growable: false);

  _VocabMatch? _resolveAgainstVocab(
    Map<String, List<Vocab>> index,
    String token, {
    String? previousToken,
  }) {
    final exact = index[token];
    if (exact != null && exact.isNotEmpty) {
      final homograph = _disambiguateNounVerbHomograph(
        index,
        token,
        exact,
        previousToken: previousToken,
      );
      return homograph ?? _VocabMatch(exact.first, exact.length > 1);
    }
    final stripped = _stripLongestParticle(token);
    var hit = stripped != null ? index[stripped] : null;
    if (hit == null || hit.isEmpty) {
      final stem = _stripLongestParticle(token, suffixes: _particleChains);
      final chain = stem == null ? null : token.substring(stem.length);
      hit = index[stem]
          ?.where(
            (entry) =>
                _nominalPartsOfSpeech.contains(entry.posDe) ||
                (entry.posDe == 'Adverb' &&
                    _adverbParticleChains.contains(chain)),
          )
          .toList(growable: false);
    }
    if (hit == null || hit.isEmpty) {
      hit = _copulaMatches(index, token);
    }
    if (hit.isEmpty) {
      hit = _predicateMatches(index, token);
    }
    if (hit.isEmpty) {
      return null;
    }
    final primary = hit.first;
    final alternatives = hit.where((word) => word.korean != primary.korean);
    return _VocabMatch(
      primary,
      hit.length > 1,
      alternativeHeadword: alternatives.isEmpty
          ? ''
          : alternatives.first.korean,
    );
  }

  List<Vocab> _predicateMatches(Map<String, List<Vocab>> index, String token) {
    final candidates = <String>{..._verbHeadwordCandidates(token)};
    for (final entry in _inflectedPredicateBases.entries) {
      final base = entry.key;
      // Every explicit base ends in an open Hangul syllable. Adding jongseong
      // ssang-siot yields the past base: 도와 -> 도왔, 몰라 -> 몰랐.
      final past =
          base.substring(0, base.length - 1) +
          String.fromCharCode(base.codeUnitAt(base.length - 1) + 20);
      if (token == '$base요' || token == '$past어요') {
        candidates.add(entry.value);
      }
    }
    return [
      for (final candidate in candidates)
        ...?index[candidate]?.where(
          (word) => word.posDe == 'Verb' || word.posDe == 'Adjektiv',
        ),
    ];
  }

  List<Vocab> _copulaMatches(Map<String, List<Vocab>> index, String token) {
    final stem = _stripLongestParticle(token, suffixes: _copulaForms.keys);
    if (stem == null) {
      return const [];
    }
    final ending = token.substring(stem.length);
    final lastSyllable = stem.codeUnitAt(stem.length - 1);
    if (_copulaForms[ending]! && (lastSyllable - 0xAC00) % 28 != 0) {
      return const [];
    }
    // A lexical predicate such as 효율적이다 keeps its dictionary entry.
    // Otherwise only a real bundled nominal can supply the meaning.
    final predicates = index['$stem이다']
        ?.where((entry) => entry.posDe == 'Verb' || entry.posDe == 'Adjektiv')
        .toList(growable: false);
    if (predicates != null && predicates.isNotEmpty) {
      return predicates;
    }
    return index[stem]
            ?.where((entry) => _nominalPartsOfSpeech.contains(entry.posDe))
            .toList(growable: false) ??
        const [];
  }

  /// Bundled-tier (tier ①) homograph guard. [token] exactly matches a NOUN
  /// headword ([nounHit]) but may *also* parse, via [_verbHeadwordCandidates],
  /// as an inflected form of a *different* VERB/ADJEKTIV headword (예: 가요 =
  /// "팝송" 명사 그대로거나 가다의 -아/어요 활용형). Grammar decides which
  /// reading the learner needs, not headword lookup order:
  ///   - 직전 토큰이 처소/목적 조사(에·을·를·에서·으로·로·까지·부터·도)로
  ///     끝나면 동사 표제어를 채택한다 ("학교에 가요" -> 가다).
  ///   - 문맥(같은 분석 단위 내 이전 토큰)이 아예 없는 독립된 표제어 줄
  ///     (예: 단어장 한 줄에 "가요"만 있는 경우)도 동사 표제어를 채택한다 —
  ///     이는 particle/verb-ending fallback이 이 노출을 원래 담당하던 기존
  ///     동작을 그대로 보존하기 위함이다.
  ///   - 그 밖의 경우(이전 토큰은 있으나 처소/목적 조사로 끝나지 않음)에는
  ///     명사를 유지하되 [ExtractedWord.ambiguous] 를 세우고 놓친 동사
  ///     표제어를 [ExtractedWord.alternativeHeadword] 로 남긴다.
  /// Returns null when there is no competing verb reading at all, so the
  /// caller falls back to its normal exact-match behaviour unchanged.
  _VocabMatch? _disambiguateNounVerbHomograph(
    Map<String, List<Vocab>> index,
    String token,
    List<Vocab> nounHit, {
    required String? previousToken,
  }) {
    if (nounHit.first.posDe != 'Nomen') {
      return null;
    }
    Vocab? verbHeadword;
    for (final candidate in _verbHeadwordCandidates(token)) {
      if (candidate == token) {
        continue;
      }
      final verbHit = index[candidate];
      if (verbHit == null || verbHit.isEmpty) {
        continue;
      }
      final candidatePos = verbHit.first.posDe;
      if (candidatePos == 'Verb' || candidatePos == 'Adjektiv') {
        verbHeadword = verbHit.first;
        break;
      }
    }
    if (verbHeadword == null) {
      return null;
    }
    final prefersVerb =
        previousToken == null ||
        kCaseLocativeParticles.any(previousToken.endsWith);
    if (prefersVerb) {
      return _VocabMatch(verbHeadword, false);
    }
    return _VocabMatch(
      nounHit.first,
      true,
      alternativeHeadword: verbHeadword.korean,
    );
  }

  /// Longest-match-once particle stripping. Tries the token itself is
  /// handled by the caller (direct index lookup); this only produces the
  /// single stripped candidate, if any particle suffix actually applies.
  String? _stripLongestParticle(
    String token, {
    Iterable<String> suffixes = kParticleSuffixes,
  }) {
    String? longestSuffix;
    for (final suffix in suffixes) {
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
    String alternativeHeadword = '',
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
    alternativeHeadword: alternativeHeadword,
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
  const _VocabMatch(
    this.vocab,
    this.ambiguous, {
    this.alternativeHeadword = '',
  });

  final Vocab vocab;
  final bool ambiguous;
  final String alternativeHeadword;
}
