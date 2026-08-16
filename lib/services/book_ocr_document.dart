import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'book_analysis_text.dart';

enum BookOcrUnitRole {
  sentence,
  expression,
  headword,
  grammarMeta,
  speakerLabel,
  instruction,
  exerciseTemplate,
  pageFurniture,
}

class BookOcrLine {
  const BookOcrLine({
    required this.text,
    required this.bounds,
    required this.sourceLineId,
    required this.blockIndex,
    required this.lineIndex,
    this.confidence,
    this.recognizedLanguages = const [],
  });

  final String text;
  final Rect bounds;
  final String sourceLineId;
  final int blockIndex;
  final int lineIndex;
  final double? confidence;
  final List<String> recognizedLanguages;
}

class BookOcrRegion {
  const BookOcrRegion({
    required this.id,
    required this.bounds,
    required this.lines,
  });

  final String id;
  final Rect bounds;
  final List<BookOcrLine> lines;
}

class BookOcrForeignHint {
  const BookOcrForeignHint({
    required this.text,
    required this.relation,
    this.language = 'und',
  });

  final String text;
  final String relation;
  final String language;
}

class BookOcrUnit {
  const BookOcrUnit({
    required this.id,
    required this.role,
    required this.korean,
    required this.bounds,
    required this.sourceLineIds,
    required this.confidence,
    this.foreignHints = const [],
  });

  final String id;
  final BookOcrUnitRole role;
  final String korean;
  final Rect bounds;
  final List<String> sourceLineIds;
  final double? confidence;
  final List<BookOcrForeignHint> foreignHints;

  bool get isAnalysisUnit => switch (role) {
    BookOcrUnitRole.sentence ||
    BookOcrUnitRole.expression ||
    BookOcrUnitRole.headword => true,
    BookOcrUnitRole.grammarMeta ||
    BookOcrUnitRole.speakerLabel ||
    BookOcrUnitRole.instruction ||
    BookOcrUnitRole.exerciseTemplate ||
    BookOcrUnitRole.pageFurniture => false,
  };
}

class BookOcrDocument {
  const BookOcrDocument({required this.regions, required this.units});

  static const int schemaVersion = 2;

  final List<BookOcrRegion> regions;
  final List<BookOcrUnit> units;

  List<BookOcrUnit> get analysisUnits =>
      units.where((unit) => unit.isAnalysisUnit).toList(growable: false);

  String get analysisText =>
      analysisUnits.map((unit) => unit.korean).join('\n').trim();

  /// Privacy-minimized server payload. Printed translations are deliberately
  /// omitted; they are layout hints, never trusted learning answers.
  List<Map<String, dynamic>> toAnalysisRequestUnits() => analysisUnits
      .map(
        (unit) => <String, dynamic>{
          'id': unit.id,
          'kind': unit.role.name,
          'korean': unit.korean,
          'sourceLineIds': unit.sourceLineIds,
          'bbox': <String, double>{
            'left': unit.bounds.left,
            'top': unit.bounds.top,
            'right': unit.bounds.right,
            'bottom': unit.bounds.bottom,
          },
          if (unit.confidence != null) 'confidence': unit.confidence,
        },
      )
      .toList(growable: false);
}

class BookOcrDocumentBuilder {
  const BookOcrDocumentBuilder._();

  static BookOcrDocument build(Iterable<BookOcrLine> source) {
    final lines = source.toList(growable: false);
    final regionLines = <int, List<BookOcrLine>>{};
    for (final line in lines) {
      regionLines.putIfAbsent(line.blockIndex, () => <BookOcrLine>[]).add(line);
    }
    final regions = regionLines.entries
        .map((entry) {
          final members = entry.value;
          var bounds = members.first.bounds;
          for (final line in members.skip(1)) {
            bounds = bounds.expandToInclude(line.bounds);
          }
          return BookOcrRegion(
            id: 'region:${entry.key}',
            bounds: bounds,
            lines: List<BookOcrLine>.unmodifiable(members),
          );
        })
        .toList(growable: false);
    final logicalLines = _formLogicalLines(lines);
    final units = <BookOcrUnit>[];
    var unitIndex = 0;
    for (final line in logicalLines) {
      final sanitized = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
        line.text,
      );
      final safeLine = sanitized.text.trim();
      if (safeLine.isEmpty) {
        continue;
      }

      final speaker = RegExp(
        r'^([\uAC00-\uD7A3]{1,8})\s*[:：]\s*(.+)$',
      ).firstMatch(safeLine);
      var learningText = safeLine;
      if (speaker != null) {
        units.add(
          BookOcrUnit(
            id: 'unit:${unitIndex++}',
            role: BookOcrUnitRole.speakerLabel,
            korean: speaker.group(1)!,
            bounds: line.bounds,
            sourceLineIds: line.sourceLineIds,
            confidence: line.confidence,
          ),
        );
        learningText = speaker.group(2)!.trim();
      }

      final segments = segmentKoreanLearningText(learningText);
      for (final segment in segments) {
        final korean = segment.korean.trim();
        if (korean.isEmpty) {
          continue;
        }
        units.add(
          BookOcrUnit(
            id: 'unit:${unitIndex++}',
            role: classifyBookOcrRole(
              korean,
              hasForeignHint: segment.foreignText.isNotEmpty,
            ),
            korean: korean,
            bounds: line.bounds,
            sourceLineIds: line.sourceLineIds,
            confidence: line.confidence,
            foreignHints: segment.foreignText.isEmpty
                ? const []
                : [
                    BookOcrForeignHint(
                      text: segment.foreignText,
                      relation: 'inline_gloss',
                      language: _hintLanguage(line.recognizedLanguages),
                    ),
                  ],
          ),
        );
      }
    }
    return BookOcrDocument(regions: regions, units: units);
  }

  /// Reflows only soft wraps inside one ML Kit block. Separate blocks, cards,
  /// columns, list items and already complete sentences remain hard borders.
  /// This restores sentence context without reviving the old cross-column
  /// newline concatenation bug.
  static List<_LogicalOcrLine> _formLogicalLines(List<BookOcrLine> lines) {
    final result = <_LogicalOcrLine>[];
    _MutableLogicalOcrLine? active;

    void finishActive() {
      final current = active;
      if (current != null) {
        result.add(current.freeze());
      }
      active = null;
    }

    for (final line in lines) {
      final current = active;
      if (current != null && _isSoftWrap(current, line)) {
        current.append(line);
      } else {
        finishActive();
        active = _MutableLogicalOcrLine(line);
      }
    }
    finishActive();
    return result;
  }

  static bool _isSoftWrap(_MutableLogicalOcrLine current, BookOcrLine next) {
    if (current.blockIndex < 0 || current.blockIndex != next.blockIndex) {
      return false;
    }
    final previousText = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
      current.lastText,
    ).text.trim();
    final nextText = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
      next.text,
    ).text.trim();
    if (previousText.isEmpty ||
        nextText.isEmpty ||
        !BookAnalysisTextPreprocessor.containsHangulSyllable(previousText) ||
        !BookAnalysisTextPreprocessor.containsHangulSyllable(nextText)) {
      return false;
    }
    if (RegExp(r'''[.!?。！？]["'”’)\]]*$''').hasMatch(previousText) ||
        RegExp(r'[:：]$').hasMatch(previousText) ||
        RegExp(r'^(?:[-–—•●○▪*]|\d+[.)]|[A-D가-라][.)])\s*').hasMatch(nextText) ||
        RegExp(r'^[\uAC00-\uD7A3]{1,8}\s*[:：]').hasMatch(nextText)) {
      return false;
    }
    final previousWords = previousText.split(RegExp(r'\s+'));
    if (previousWords.length <= 1 ||
        (previousWords.length <= 4 && previousText.endsWith('다'))) {
      return false;
    }
    final previousSegments = segmentKoreanLearningText(previousText);
    if (previousSegments.length != 1 ||
        previousSegments.single.foreignText.isNotEmpty) {
      return false;
    }

    final previousBounds = current.lastBounds;
    final lineHeight = math.max(previousBounds.height, next.bounds.height);
    if (lineHeight <= 0 ||
        next.bounds.top < previousBounds.top + lineHeight * 0.45 ||
        next.bounds.top - previousBounds.bottom >
            math.max(18, lineHeight * 1.8)) {
      return false;
    }
    final overlap = math.max(
      0,
      math.min(previousBounds.right, next.bounds.right) -
          math.max(previousBounds.left, next.bounds.left),
    );
    final narrowerWidth = math.min(previousBounds.width, next.bounds.width);
    final overlapRatio = narrowerWidth <= 0 ? 0 : overlap / narrowerWidth;
    final alignedStart =
        (previousBounds.left - next.bounds.left).abs() <= lineHeight * 1.5;
    return overlapRatio >= 0.35 || alignedStart;
  }

  static String _hintLanguage(List<String> languages) {
    for (final language in languages) {
      final normalized = language.toLowerCase();
      if (normalized == 'de' || normalized.startsWith('de-')) {
        return 'de';
      }
      if (normalized == 'en' || normalized.startsWith('en-')) {
        return 'en';
      }
    }
    return 'und';
  }
}

class BookOcrTextSegment {
  const BookOcrTextSegment({required this.korean, required this.foreignText});

  final String korean;
  final String foreignText;
}

/// Extracts Korean learning islands while preserving Latin tokens that are
/// part of a Korean clause (for example `Berlin에`, `AI를`, or `K-pop 음악`).
/// Plain DE/EN prose is retained only as a non-persisted structural hint.
List<BookOcrTextSegment> segmentKoreanLearningText(String value) {
  final tokens = RegExp(
    r'\S+',
  ).allMatches(value).map((match) => match.group(0)!).toList();
  final segments = <_MutableSegment>[];
  _MutableSegment? current;
  String? pendingHyphenatedLatin;

  void finishCurrent() {
    final active = current;
    if (active != null && active.koreanTokens.isNotEmpty) {
      segments.add(active);
    }
    current = null;
  }

  for (final token in tokens) {
    final hasHangul = BookAnalysisTextPreprocessor.containsHangulSyllable(
      token,
    );
    if (hasHangul) {
      if (current == null) {
        current = _MutableSegment();
        final pending = pendingHyphenatedLatin;
        if (pending != null) {
          current!.koreanTokens.add(pending);
          pendingHyphenatedLatin = null;
        }
      }
      current!.koreanTokens.add(token);
      continue;
    }

    if (_isKeepableLatinToken(token)) {
      if (current != null) {
        current!.koreanTokens.add(token);
      } else {
        pendingHyphenatedLatin = token;
      }
      continue;
    }

    if (current != null && _isKoreanPunctuationToken(token)) {
      current!.koreanTokens.add(token);
      continue;
    }

    pendingHyphenatedLatin = null;
    if (current != null) {
      finishCurrent();
    }
    if (segments.isNotEmpty && _hasLatinLetter(token)) {
      segments.last.foreignTokens.add(token);
    } else if (segments.isNotEmpty && segments.last.foreignTokens.isNotEmpty) {
      segments.last.foreignTokens.add(token);
    }
  }
  finishCurrent();

  return segments
      .map(
        (segment) => BookOcrTextSegment(
          korean: _cleanSegment(segment.koreanTokens.join(' ')),
          foreignText: _cleanForeignHint(segment.foreignTokens.join(' ')),
        ),
      )
      .where((segment) => segment.korean.isNotEmpty)
      .toList(growable: false);
}

BookOcrUnitRole classifyBookOcrRole(
  String value, {
  required bool hasForeignHint,
}) {
  final text = value.trim();
  if (text.isEmpty) {
    return BookOcrUnitRole.pageFurniture;
  }
  if (RegExp(r'^[-–—]\s*[\uAC00-\uD7A3]').hasMatch(text) ||
      RegExp(r'[-–—]?[\uAC00-\uD7A3]+/[\uAC00-\uD7A3]+').hasMatch(text)) {
    return BookOcrUnitRole.grammarMeta;
  }
  if (RegExp(r'_{2,}|…{2,}|^[A-D가-라]\s*[.)]').hasMatch(text)) {
    return BookOcrUnitRole.exerciseTemplate;
  }
  if (RegExp(r'^제?\s*\d+\s*(과|장|단원)(?:\s+.*)?[.!?。！？]?$').hasMatch(text)) {
    return BookOcrUnitRole.pageFurniture;
  }
  if (RegExp(
    r'^(다음|보기|알맞은|맞는|틀린|빈칸|연결|고르|쓰|읽|대답|완성)|'
    r'^(괄호|그림|표|주어진).*(하세요|해\s*보세요|고르세요|쓰세요|완성하세요)'
    r'[.!?。！？]?$|'
    r'^(어휘|단어|표현|문법|문장|대화|발음)(을|를)?\s*'
    r'(배우|배웁|익히|익힙|연습하|연습합|완성하|읽|쓰|말하|들어)|'
    r'(익혀|배워|연습해)\s*봅시다[.!?。！？]?$',
  ).hasMatch(text)) {
    return BookOcrUnitRole.instruction;
  }
  if (!RegExp(r'[.!?。！？]$').hasMatch(text) &&
      text.endsWith('다') &&
      text.split(RegExp(r'\s+')).length <= 4) {
    return BookOcrUnitRole.expression;
  }
  if (RegExp(r'(요|니다|니까|까요|죠|다|자|세요|십시오)[.!?。！？]?["”’)]*$').hasMatch(text)) {
    return BookOcrUnitRole.sentence;
  }
  if (hasForeignHint && text.split(RegExp(r'\s+')).length <= 3) {
    return BookOcrUnitRole.headword;
  }
  if (text.split(RegExp(r'\s+')).length <= 4) {
    return BookOcrUnitRole.expression;
  }
  return BookOcrUnitRole.sentence;
}

class _MutableSegment {
  final List<String> koreanTokens = [];
  final List<String> foreignTokens = [];
}

bool _isKeepableLatinToken(String token) {
  final stripped = token.replaceAll(
    RegExp(r'''^[\(\[\{"'“‘]+|[\)\]\}"'”’.,!?;:]+$'''),
    '',
  );
  if (RegExp(r'^\d{1,2}[:.]\d{2}$').hasMatch(stripped)) {
    return true;
  }
  // The acceptance contract explicitly preserves `K-pop`. Other standalone
  // hyphenated Latin tokens are ambiguous (`U-Bahn`, `E-Mail`, `X-Achse`) and
  // therefore stay out unless a human confirms them in the preview.
  return stripped.toLowerCase() == 'k-pop';
}

bool _hasLatinLetter(String value) =>
    RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(value);

String _cleanSegment(String value) => value
    .replaceAllMapped(RegExp(r'\s+([,.!?;:。！？])'), (match) => match.group(1)!)
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _isKoreanPunctuationToken(String value) =>
    RegExp(r'^[,.!?;:。！？]+$').hasMatch(value);

String _cleanForeignHint(String value) => value
    .replaceAll(RegExp(r'^[\s.,;:|=\-–—]+|[\s.,;:|=\-–—]+$'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class _LogicalOcrLine {
  const _LogicalOcrLine({
    required this.text,
    required this.bounds,
    required this.sourceLineIds,
    required this.blockIndex,
    required this.confidence,
    required this.recognizedLanguages,
  });

  final String text;
  final Rect bounds;
  final List<String> sourceLineIds;
  final int blockIndex;
  final double? confidence;
  final List<String> recognizedLanguages;
}

class _MutableLogicalOcrLine {
  _MutableLogicalOcrLine(BookOcrLine line)
    : textParts = <String>[line.text],
      bounds = line.bounds,
      lastBounds = line.bounds,
      lastText = line.text,
      blockIndex = line.blockIndex,
      sourceLineIds = <String>[line.sourceLineId],
      recognizedLanguages = <String>{...line.recognizedLanguages},
      confidenceTotal = line.confidence ?? 0,
      confidenceCount = line.confidence == null ? 0 : 1;

  final List<String> textParts;
  Rect bounds;
  Rect lastBounds;
  String lastText;
  final int blockIndex;
  final List<String> sourceLineIds;
  final Set<String> recognizedLanguages;
  double confidenceTotal;
  int confidenceCount;

  void append(BookOcrLine line) {
    textParts.add(line.text);
    bounds = bounds.expandToInclude(line.bounds);
    lastBounds = line.bounds;
    lastText = line.text;
    sourceLineIds.add(line.sourceLineId);
    recognizedLanguages.addAll(line.recognizedLanguages);
    final confidence = line.confidence;
    if (confidence != null) {
      confidenceTotal += confidence;
      confidenceCount++;
    }
  }

  _LogicalOcrLine freeze() => _LogicalOcrLine(
    text: textParts.join(' '),
    bounds: bounds,
    sourceLineIds: List<String>.unmodifiable(sourceLineIds),
    blockIndex: blockIndex,
    confidence: confidenceCount == 0 ? null : confidenceTotal / confidenceCount,
    recognizedLanguages: List<String>.unmodifiable(recognizedLanguages),
  );
}
