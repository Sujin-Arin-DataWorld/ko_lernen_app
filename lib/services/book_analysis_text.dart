import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Pure text-quality boundary shared by OCR and cloud-analysis callers.
///
/// Hangul Sori accepts Korean textbook text with German or English context.
/// Other writing systems are not valid input for this feature and are removed
/// before they can become vocabulary cards, grammar hits, or Korean TTS input.
class BookAnalysisTextPreprocessor {
  const BookAnalysisTextPreprocessor._();

  static const int maxAnalysisCharacters = 5000;

  static PreparedBookAnalysisText prepare(
    String source, {
    int maxCharacters = maxAnalysisCharacters,
  }) {
    final normalized = normalizeNfc(source);
    final keptLines = <String>[];
    var ignoredSegmentCount = 0;
    var removedUnexpectedCharacterCount = 0;
    var removedFormatControlCount = 0;

    for (final rawLine in normalized.split('\n')) {
      final sanitized = sanitizeUnexpectedScripts(rawLine);
      removedUnexpectedCharacterCount += sanitized.removedCharacterCount;
      removedFormatControlCount += sanitized.removedFormatControlCount;
      final line = sanitized.text.trim();
      if (line.isEmpty) {
        if (rawLine.trim().isNotEmpty) {
          ignoredSegmentCount++;
        }
        continue;
      }

      // Textbooks can print a translation after a Korean sentence on the
      // same OCR line. Keep only terminally separated segments containing
      // Hangul while preserving Latin embedded in that Korean segment.
      for (final rawSegment in line.split(RegExp(r'(?<=[.!?。！？])\s+'))) {
        final trimmed = _trimClearStandaloneGloss(rawSegment.trim());
        if (trimmed.removedGloss) {
          ignoredSegmentCount++;
        }
        if (containsHangulSyllable(trimmed.text)) {
          keptLines.add(trimmed.text);
        } else if (rawSegment.trim().isNotEmpty) {
          ignoredSegmentCount++;
        }
      }
    }

    var text = keptLines.join('\n').trim();
    var wasTruncated = false;
    if (maxCharacters > 0 && text.length > maxCharacters) {
      text = _truncateAtBoundary(text, maxCharacters);
      wasTruncated = true;
    }

    final warnings = <String>[
      if (ignoredSegmentCount > 0) 'non_korean_segments_ignored',
      if (removedUnexpectedCharacterCount > 0 || removedFormatControlCount > 0)
        'unexpected_script_filtered',
      if (wasTruncated) 'text_truncated',
      if (text.isEmpty) 'no_korean_text',
    ];
    return PreparedBookAnalysisText(
      text: text,
      warnings: warnings,
      ignoredLineCount: ignoredSegmentCount,
      removedUnexpectedCharacterCount: removedUnexpectedCharacterCount,
      removedFormatControlCount: removedFormatControlCount,
      wasTruncated: wasTruncated,
    );
  }

  static String normalizeNfc(String value) =>
      unorm.nfc(value).replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  static bool containsHangulSyllable(String value) =>
      RegExp(r'[\uAC00-\uD7A3]').hasMatch(normalizeNfc(value));

  static bool containsUnexpectedScript(String value) {
    final inspection = inspect(value);
    return inspection.unsupportedCharacterCount > 0 ||
        inspection.formatControlCount > 0;
  }

  /// Inspects the raw OCR text before unsupported runs are discarded.
  static BookTextInspection inspect(String value) {
    final normalized = normalizeNfc(value);
    var unsupported = 0;
    var formatControls = 0;
    var considered = 0;
    for (final rune in normalized.runes) {
      if (_isWhitespaceRune(rune)) {
        continue;
      }
      considered++;
      if (_isForbiddenFormatRune(rune)) {
        formatControls++;
      } else if (!_isSupportedRune(rune)) {
        unsupported++;
      }
    }
    return BookTextInspection(
      normalizedText: normalized,
      hasKoreanText: RegExp(r'[\uAC00-\uD7A3]').hasMatch(normalized),
      unsupportedCharacterCount: unsupported,
      formatControlCount: formatControls,
      consideredCharacterCount: considered,
    );
  }

  static SanitizedBookText sanitizeUnexpectedScripts(String value) {
    final normalized = normalizeNfc(value);
    final output = StringBuffer();
    var removed = 0;
    var removedFormats = 0;
    var replacingUnsupportedRun = false;
    var lastWasWhitespace = true;

    for (final rune in normalized.runes) {
      if (_isForbiddenFormatRune(rune)) {
        removedFormats++;
        continue;
      }
      if (!_isSupportedRune(rune)) {
        removed++;
        replacingUnsupportedRun = true;
        continue;
      }

      final isWhitespace = _isWhitespaceRune(rune);
      if (replacingUnsupportedRun &&
          !lastWasWhitespace &&
          !isWhitespace &&
          output.isNotEmpty) {
        output.write(' ');
        lastWasWhitespace = true;
      }
      replacingUnsupportedRun = false;

      if (isWhitespace) {
        if (!lastWasWhitespace && output.isNotEmpty) {
          output.write(rune == 0x0a ? '\n' : ' ');
          lastWasWhitespace = true;
        }
      } else {
        output.writeCharCode(rune);
        lastWasWhitespace = false;
      }
    }

    return SanitizedBookText(
      text: output.toString().trim(),
      removedCharacterCount: removed,
      removedFormatControlCount: removedFormats,
    );
  }

  static bool _isForbiddenFormatRune(int rune) {
    return (rune < 0x20 && !_isWhitespaceRune(rune)) ||
        (rune >= 0x7f && rune <= 0x9f) ||
        rune == 0x00ad ||
        rune == 0x061c ||
        rune == 0x200b ||
        rune == 0x200c ||
        rune == 0x200d ||
        rune == 0x200e ||
        rune == 0x200f ||
        (rune >= 0x202a && rune <= 0x202e) ||
        (rune >= 0x2060 && rune <= 0x206f) ||
        rune == 0xfeff;
  }

  static bool _isSupportedRune(int rune) {
    if (_isWhitespaceRune(rune) || _isHangulRune(rune)) {
      return true;
    }
    // Basic and extended Latin, combining marks, digits and common textbook
    // punctuation/symbols. CJK punctuation is allowed, but CJK ideographs are
    // deliberately not.
    return (rune >= 0x0020 && rune <= 0x024f) ||
        (rune >= 0x0300 && rune <= 0x036f) ||
        (rune >= 0x1d00 && rune <= 0x1eff) ||
        (rune >= 0x2000 && rune <= 0x206f) ||
        (rune >= 0x20a0 && rune <= 0x20cf) ||
        (rune >= 0x2100 && rune <= 0x214f) ||
        (rune >= 0x3000 && rune <= 0x303f) ||
        (rune >= 0xff01 && rune <= 0xff65);
  }

  static bool _isWhitespaceRune(int rune) =>
      rune == 0x09 || rune == 0x0a || rune == 0x0d || rune == 0x20;

  static bool _isHangulRune(int rune) =>
      (rune >= 0x1100 && rune <= 0x11ff) ||
      (rune >= 0x3130 && rune <= 0x318f) ||
      (rune >= 0xa960 && rune <= 0xa97f) ||
      (rune >= 0xac00 && rune <= 0xd7a3) ||
      (rune >= 0xd7b0 && rune <= 0xd7ff);

  static ({String text, bool removedGloss}) _trimClearStandaloneGloss(
    String value,
  ) {
    var line = value;
    var removed = false;
    if (!containsHangulSyllable(line)) {
      return (text: '', removedGloss: false);
    }

    // Remove a standalone Latin label in brackets before Korean source text.
    // Korean grammar notation such as "(으)ㄹ" is preserved.
    final bracketedPrefix = RegExp(
      r'^\s*[\(\[][^\)\]]*[\)\]]\s*(?=[\s\S]*[\uAC00-\uD7A3])',
    ).firstMatch(line);
    if (bracketedPrefix != null &&
        !containsHangulSyllable(bracketedPrefix.group(0)!)) {
      line = line.substring(bracketedPrefix.end).trimLeft();
      removed = true;
    }

    // Remove an explicit Latin lesson/header prefix. A mere space is not a
    // delimiter: "K-pop 음악" and "Berlin에" must remain intact.
    final leading = RegExp(
      r'^[A-Za-z\u00C0-\u024F0-9][A-Za-z\u00C0-\u024F0-9\s().,\-\u2013\u2014]{0,80}'
      r'(?:\s*[:;|=]\s*|\s+[\-\u2013\u2014]\s+)(?=[\uAC00-\uD7A3])',
    ).firstMatch(line);
    if (leading != null) {
      line = line.substring(leading.end).trimLeft();
      removed = true;
    }

    // Remove only bracketed Latin text at the end. Korean grammar notation
    // such as "(으)ㄹ" contains Hangul and is therefore preserved.
    final bracketed = RegExp(
      r'''\s*[\(\[\{]\s*[A-Za-z\u00C0-\u024F0-9][A-Za-z\u00C0-\u024F0-9\s.,!?'/"\-\u2013\u2014]*\s*[\)\]\}]\s*$''',
    ).firstMatch(line);
    if (bracketed != null &&
        containsHangulSyllable(line.substring(0, bracketed.start))) {
      line = line.substring(0, bracketed.start).trimRight();
      removed = true;
    }

    // A trailing gloss needs an explicit delimiter. Do not mistake the hyphen
    // inside "K-pop" for a translation boundary.
    final trailing = RegExp(
      r'''(?:\s+[\-\u2013\u2014]\s+|\s*[:;|=]\s*)[A-Za-z\u00C0-\u024F][A-Za-z\u00C0-\u024F0-9\s.,!?'/"\-\u2013\u2014]*$''',
    ).firstMatch(line);
    if (trailing != null &&
        containsHangulSyllable(line.substring(0, trailing.start))) {
      line = line.substring(0, trailing.start).trimRight();
      removed = true;
    }

    return (text: line.trim(), removedGloss: removed);
  }

  static String _truncateAtBoundary(String value, int maxCharacters) {
    var truncated = value.substring(0, maxCharacters);
    final boundary = truncated.lastIndexOf(RegExp(r'[\n.!?。！？ ]'));
    if (boundary >= (maxCharacters * 0.75).floor()) {
      truncated = truncated.substring(0, boundary + 1);
    }
    return truncated.trim();
  }
}

class BookTextInspection {
  const BookTextInspection({
    required this.normalizedText,
    required this.hasKoreanText,
    required this.unsupportedCharacterCount,
    required this.formatControlCount,
    required this.consideredCharacterCount,
  });

  final String normalizedText;
  final bool hasKoreanText;
  final int unsupportedCharacterCount;
  final int formatControlCount;
  final int consideredCharacterCount;

  int get unsafeCharacterCount =>
      unsupportedCharacterCount + formatControlCount;

  double get unsupportedRatio => consideredCharacterCount == 0
      ? 0
      : unsafeCharacterCount / consideredCharacterCount;

  bool get isSafeEditedText => hasKoreanText && unsafeCharacterCount == 0;
}

class PreparedBookAnalysisText {
  const PreparedBookAnalysisText({
    required this.text,
    required this.warnings,
    required this.ignoredLineCount,
    required this.removedUnexpectedCharacterCount,
    required this.removedFormatControlCount,
    required this.wasTruncated,
  });

  final String text;
  final List<String> warnings;
  final int ignoredLineCount;
  final int removedUnexpectedCharacterCount;
  final int removedFormatControlCount;
  final bool wasTruncated;

  bool get hasKoreanText => text.isNotEmpty;
}

class SanitizedBookText {
  const SanitizedBookText({
    required this.text,
    required this.removedCharacterCount,
    required this.removedFormatControlCount,
  });

  final String text;
  final int removedCharacterCount;
  final int removedFormatControlCount;
}
