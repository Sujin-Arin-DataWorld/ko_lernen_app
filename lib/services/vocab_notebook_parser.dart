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

enum _LeftoverKind { korean, latin }

class _LeftoverLine {
  const _LeftoverLine({
    required this.kind,
    required this.text,
    required this.raw,
  });

  final _LeftoverKind kind;
  final String text;
  final String raw;
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
    r'\s*(?:[-–—=:=/·]|→|=>|\t|\s{2,})\s*',
  );
  static final RegExp _leadingIndex = RegExp(
    r'^(?:[-–—•●○▪*]|\d+[.)]|[A-Da-d가-라][.)])\s*',
  );
  static final RegExp _emptyParens = RegExp(r'\(\s*\)');
  static final RegExp _trailingHeadPunct = RegExp(r'[\s,;:.\-–—/()]+$');

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
        kept.add(_stripEmptyParens(sanitized));
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
      final safeKorean = _cleanKoreanHead(korean);
      final safeMeaning = _cleanMeaning(meaning);
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

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    var hangulLineCount = 0;
    var pairLikeLineCount = 0;
    final leftover = <_LeftoverLine>[];

    for (final rawLine in lines) {
      final line = rawLine.replaceFirst(_leadingIndex, '').trim();
      if (line.isEmpty) {
        continue;
      }
      if (_hangul.hasMatch(line)) {
        hangulLineCount++;
      }

      final inline = _extractInlinePairs(line);
      if (inline.isNotEmpty) {
        pairLikeLineCount++;
        for (final pair in inline) {
          addPair(pair.$1, pair.$2, rawLine);
        }
        continue;
      }

      if (_isKoreanHeadwordLine(line)) {
        leftover.add(
          _LeftoverLine(
            kind: _LeftoverKind.korean,
            text: _cleanKoreanHead(line),
            raw: rawLine,
          ),
        );
        continue;
      }

      if (!_hangul.hasMatch(line) && _latin.hasMatch(line)) {
        leftover.add(
          _LeftoverLine(
            kind: _LeftoverKind.latin,
            text: _cleanMeaning(line),
            raw: rawLine,
          ),
        );
        continue;
      }
    }

    final leftoverPairs = _pairLeftoverLines(leftover);
    pairLikeLineCount += leftoverPairs.length;
    for (final pair in leftoverPairs) {
      addPair(pair.$1, pair.$2, pair.$3);
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

  static List<(String, String)> _extractInlinePairs(String line) {
    final pairs = <(String, String)>[];
    var remaining = _stripEmptyParens(line).trim();
    while (remaining.isNotEmpty) {
      final found = _splitOneInlinePair(remaining);
      if (found == null) {
        break;
      }
      pairs.add((found.$1, found.$2));
      remaining = found.$3.trim();
    }
    return pairs;
  }

  static (String, String, String)? _splitOneInlinePair(String line) {
    final parts = line.split(_pairSeparator);
    if (parts.length >= 2) {
      final korean = parts.first.trim();
      final meaningAndRest = parts.sublist(1).join(' ').trim();
      if (_isKoreanHeadwordLine(korean)) {
        final cut = _cutMeaningAtNextKoreanHead(meaningAndRest);
        if (cut != null) {
          return (korean, cut.$1, cut.$2);
        }
      }
    }

    final paren = RegExp(r'^(.+?)\s*\(([^)]*)\)\s*(.*)$').firstMatch(line);
    if (paren != null) {
      final korean = paren.group(1)!.trim();
      final inside = paren.group(2)!.trim();
      final after = paren.group(3)!.trim();
      if (_isKoreanHeadwordLine(korean) &&
          inside.isNotEmpty &&
          _latin.hasMatch(inside) &&
          !_isMostlyKorean(inside)) {
        return (korean, inside, after);
      }
      if (_isKoreanHeadwordLine(korean) && inside.isEmpty && after.isNotEmpty) {
        return _splitOneInlinePair('$korean $after');
      }
    }

    final latinMatch = _latin.firstMatch(line);
    if (latinMatch != null && latinMatch.start > 0) {
      final korean = line
          .substring(0, latinMatch.start)
          .replaceFirst(_trailingHeadPunct, '')
          .trim();
      final meaningAndRest = line.substring(latinMatch.start).trim();
      if (_isKoreanHeadwordLine(korean) && !_isMostlyKorean(meaningAndRest)) {
        final cut = _cutMeaningAtNextKoreanHead(meaningAndRest);
        if (cut != null) {
          return (korean, cut.$1, cut.$2);
        }
      }
    }
    return null;
  }

  static (String, String)? _cutMeaningAtNextKoreanHead(String meaningAndRest) {
    final hangul = _hangul.firstMatch(meaningAndRest);
    if (hangul == null) {
      if (_latin.hasMatch(meaningAndRest) && !_isMostlyKorean(meaningAndRest)) {
        return (meaningAndRest.trim(), '');
      }
      return null;
    }
    final before = meaningAndRest.substring(0, hangul.start).trim();
    final fromHangul = meaningAndRest.substring(hangul.start).trim();
    if (before.isEmpty ||
        !_latin.hasMatch(before) ||
        _isMostlyKorean(before)) {
      return null;
    }
    return (before, fromHangul);
  }

  static List<(String, String, String)> _pairLeftoverLines(
    List<_LeftoverLine> leftover,
  ) {
    final pairs = <(String, String, String)>[];
    var index = 0;
    while (index < leftover.length) {
      final current = leftover[index];
      if (current.kind == _LeftoverKind.korean &&
          index + 1 < leftover.length &&
          leftover[index + 1].kind == _LeftoverKind.latin) {
        pairs.add((
          current.text,
          leftover[index + 1].text,
          '${current.raw} ${leftover[index + 1].raw}',
        ));
        index += 2;
        continue;
      }

      if (current.kind != _LeftoverKind.korean) {
        index++;
        continue;
      }

      var koreanEnd = index;
      while (koreanEnd < leftover.length &&
          leftover[koreanEnd].kind == _LeftoverKind.korean) {
        koreanEnd++;
      }
      var latinEnd = koreanEnd;
      while (latinEnd < leftover.length &&
          leftover[latinEnd].kind == _LeftoverKind.latin) {
        latinEnd++;
      }
      final koreanRun = koreanEnd - index;
      final latinRun = latinEnd - koreanEnd;
      var koreanStart = index;
      var zipCount = 0;
      if (koreanRun >= 2 && latinRun >= 2 && koreanRun == latinRun) {
        zipCount = koreanRun;
      } else if (koreanRun >= 3 && latinRun >= 2 && koreanRun == latinRun + 1) {
        koreanStart = index + 1;
        zipCount = latinRun;
      } else if (koreanRun >= 2 && latinRun >= 3 && latinRun == koreanRun + 1) {
        zipCount = koreanRun;
      }
      if (zipCount == 0) {
        index++;
        continue;
      }
      for (var offset = 0; offset < zipCount; offset++) {
        final korean = leftover[koreanStart + offset];
        final latin = leftover[koreanEnd + offset];
        pairs.add((
          korean.text,
          latin.text,
          '${korean.raw} ${latin.raw}',
        ));
      }
      index = latinEnd;
    }
    return pairs;
  }

  static bool _isKoreanHeadwordLine(String line) {
    final cleaned = _stripEmptyParens(line);
    if (!_hangul.hasMatch(cleaned) || cleaned.runes.length > 20) {
      return false;
    }
    if (_latin.hasMatch(cleaned)) {
      return false;
    }
    final letters = cleaned.replaceAll(RegExp(r'[\s\-–—()]'), '');
    if (letters.isEmpty) {
      return false;
    }
    final hangulCount = RegExp(r'[\uAC00-\uD7A3]').allMatches(letters).length;
    return hangulCount * 2 >= letters.runes.length;
  }

  static bool _isMostlyKorean(String value) {
    final letters = value.replaceAll(RegExp(r'\s+'), '');
    if (letters.isEmpty) {
      return false;
    }
    final hangulCount = RegExp(r'[\uAC00-\uD7A3]').allMatches(letters).length;
    return hangulCount * 2 >= letters.runes.length;
  }

  static String _stripEmptyParens(String value) =>
      value.replaceAll(_emptyParens, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _cleanKoreanHead(String value) {
    final sanitized = sanitizeCustomPackKoreanWord(value);
    return _stripEmptyParens(sanitized).replaceFirst(_trailingHeadPunct, '');
  }

  static String _cleanMeaning(String value) {
    var meaning = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
      value,
    ).text.replaceAll(RegExp(r'\s+'), ' ').trim();
    meaning = _stripEmptyParens(meaning);
    if (RegExp(r'^\([^)]+\)$').hasMatch(meaning)) {
      meaning = meaning.substring(1, meaning.length - 1).trim();
    }
    return meaning;
  }
}
