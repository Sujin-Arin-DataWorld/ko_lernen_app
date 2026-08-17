import '../models/book_page.dart';
import '../services/book_analysis_text.dart';
import '../services/book_ocr_document.dart';
import '../services/custom_pack_import_service.dart';

/// One Korean headword plus the meaning written in the learner's notebook.
class VocabNotebookPair {
  const VocabNotebookPair({
    required this.korean,
    required this.meaning,
    this.sourceLine = '',
  });

  final String korean;
  final String meaning;
  final String sourceLine;
}

class VocabNotebookParseResult {
  const VocabNotebookParseResult({
    required this.pairs,
    required this.hangulLineCount,
    required this.pairLikeLineCount,
  });

  final List<VocabNotebookPair> pairs;
  final int hangulLineCount;
  final int pairLikeLineCount;

  bool get looksLikeNotebook {
    if (pairs.length >= 5) {
      return true;
    }
    if (pairs.length < 4 || hangulLineCount == 0) {
      return false;
    }
    final averageKoreanLength = pairs.fold<int>(
          0,
          (sum, pair) => sum + pair.korean.runes.length,
        ) /
        pairs.length;
    return pairLikeLineCount * 2 >= hangulLineCount && averageKoreanLength <= 12;
  }
}

/// Extracts the exact Korean–meaning pairs from a photographed vocabulary
/// notebook. This path keeps the learner's own translations and does not ask
/// the textbook analyzer to invent new words.
class VocabNotebookParser {
  const VocabNotebookParser._();

  static const int maxPairsPerPhoto = 400;
  static const int maxNotebookCharacters = 20000;

  static final RegExp _hangul = RegExp(r'[\uAC00-\uD7A3]');
  static final RegExp _latin = RegExp(r'[A-Za-z\u00C0-\u024F]');
  static final RegExp _pairSeparator = RegExp(
    r'\s*(?:[-–—=:=/]|→|=>|\t|\s{2,})\s*',
  );
  static final RegExp _leadingIndex = RegExp(
    r'^(?:[-–—•●○▪*]|\d+[.)]|[A-Da-d가-라][.)])\s*',
  );
  static final RegExp _koreanHead = RegExp(
    r'^([\uAC00-\uD7A3]{1,20}(?:하다|되다|이다)?)',
  );

  static String prepareText(String source) {
    final normalized = BookAnalysisTextPreprocessor.normalizeNfc(source);
    final kept = <String>[];
    for (final rawLine in normalized.split('\n')) {
      final sanitized = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
        rawLine,
      ).text.trim();
      if (sanitized.isEmpty) {
        continue;
      }
      if (_hangul.hasMatch(sanitized) || _latin.hasMatch(sanitized)) {
        kept.add(sanitized);
      }
    }
    var text = kept.join('\n').trim();
    if (text.length > maxNotebookCharacters) {
      text = text.substring(0, maxNotebookCharacters);
    }
    return text;
  }

  static VocabNotebookParseResult parse(
    String source, {
    BookOcrDocument? document,
  }) {
    final text = prepareText(source);
    final seen = <String>{};
    final pairs = <VocabNotebookPair>[];

    void addPair(String korean, String meaning, String sourceLine) {
      final safeKorean = sanitizeCustomPackKoreanWord(korean);
      final safeMeaning = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
        meaning,
      ).text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (safeKorean.isEmpty ||
          !_hangul.hasMatch(safeKorean) ||
          safeKorean.runes.length > 20 ||
          safeMeaning.isEmpty ||
          !_latin.hasMatch(safeMeaning) ||
          !seen.add(safeKorean)) {
        return;
      }
      if (pairs.length >= maxPairsPerPhoto) {
        return;
      }
      pairs.add(
        VocabNotebookPair(
          korean: safeKorean,
          meaning: safeMeaning,
          sourceLine: sourceLine,
        ),
      );
    }

    if (document != null) {
      for (final unit in document.units) {
        if (unit.role != BookOcrUnitRole.headword) {
          continue;
        }
        for (final hint in unit.foreignHints) {
          addPair(unit.korean, hint.text, unit.korean);
        }
      }
    }

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    var hangulLineCount = 0;
    var pairLikeLineCount = 0;
    String? pendingKorean;

    for (final rawLine in lines) {
      final line = rawLine.replaceFirst(_leadingIndex, '').trim();
      if (line.isEmpty) {
        continue;
      }
      if (_hangul.hasMatch(line)) {
        hangulLineCount++;
      }

      final inline = _splitInlinePair(line);
      if (inline != null) {
        pairLikeLineCount++;
        pendingKorean = null;
        addPair(inline.$1, inline.$2, rawLine);
        continue;
      }

      if (_isKoreanHeadwordLine(line)) {
        pendingKorean = _koreanHead.firstMatch(line)?.group(1) ?? line;
        continue;
      }

      if (pendingKorean != null &&
          !_hangul.hasMatch(line) &&
          _latin.hasMatch(line)) {
        pairLikeLineCount++;
        addPair(pendingKorean, line, '$pendingKorean $line');
        pendingKorean = null;
        continue;
      }
      pendingKorean = null;
    }

    return VocabNotebookParseResult(
      pairs: List<VocabNotebookPair>.unmodifiable(pairs),
      hangulLineCount: hangulLineCount,
      pairLikeLineCount: pairLikeLineCount,
    );
  }

  static List<ExtractedWord> toExtractedWords(
    Iterable<VocabNotebookPair> pairs, {
    required String translationLanguage,
  }) {
    final language = translationLanguage == 'en' ? 'en' : 'de';
    return pairs
        .map(
          (pair) => ExtractedWord.manual(
            korean: pair.korean,
            translationDe: pair.meaning,
            translationEn: language == 'en' ? pair.meaning : '',
            translationLanguage: language,
          ),
        )
        .toList(growable: false);
  }

  static (String, String)? _splitInlinePair(String line) {
    final parts = line.split(_pairSeparator);
    if (parts.length >= 2) {
      final korean = parts.first.trim();
      final meaning = parts.sublist(1).join(' ').trim();
      if (_isKoreanHeadwordLine(korean) &&
          _latin.hasMatch(meaning) &&
          !_isMostlyKorean(meaning)) {
        return (korean, meaning);
      }
    }

    final match = _koreanHead.firstMatch(line);
    if (match == null) {
      return null;
    }
    final korean = match.group(1)!;
    final rest = line.substring(match.end).trim();
    if (rest.isEmpty || !_latin.hasMatch(rest) || _isMostlyKorean(rest)) {
      return null;
    }
    if (!RegExp(r'^[\s,;:.\-–—/]+').hasMatch(' $rest') &&
        !rest.startsWith(RegExp(r'[A-Za-z\u00C0-\u024F]'))) {
      return null;
    }
    return (korean, rest.replaceFirst(RegExp(r'^[\s,;:.\-–—/]+'), ''));
  }

  static bool _isKoreanHeadwordLine(String line) {
    if (!_hangul.hasMatch(line) || line.runes.length > 20) {
      return false;
    }
    final letters = line.replaceAll(RegExp(r'[\s\-–—()]'), '');
    if (letters.isEmpty) {
      return false;
    }
    final hangulCount = RegExp(r'[\uAC00-\uD7A3]').allMatches(letters).length;
    return hangulCount * 2 >= letters.runes.length && !_latin.hasMatch(line);
  }

  static bool _isMostlyKorean(String value) {
    final letters = value.replaceAll(RegExp(r'\s+'), '');
    if (letters.isEmpty) {
      return false;
    }
    final hangulCount = RegExp(r'[\uAC00-\uD7A3]').allMatches(letters).length;
    return hangulCount * 2 >= letters.runes.length;
  }
}
