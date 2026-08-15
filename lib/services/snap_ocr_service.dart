import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'book_analysis_text.dart';

/// On-device OCR for bilingual Korean textbooks.
///
/// ML Kit's Korean option is the combined Latin-and-Korean model, so one pass
/// is used. Running a second Latin recognizer for the same pixels creates
/// conflicting alternatives that cannot be reconciled safely.
class SnapOcrService {
  static const double lowConfidenceThreshold = 0.45;
  static const double severeLowConfidenceRatio = 0.50;
  static const double severeUnsupportedScriptRatio = 0.20;
  static const double severeRotationDegrees = 12;
  static const int minimumRotationLineCount = 3;

  static Future<OcrResult> recognizeKorean(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);

    try {
      final recognized = await recognizer.processImage(input);
      final candidates = <OcrTextBlock>[];
      for (final block in recognized.blocks) {
        if (block.lines.isEmpty) {
          candidates.add(
            OcrTextBlock(
              text: block.text,
              bounds: block.boundingBox,
              script:
                  BookAnalysisTextPreprocessor.containsHangulSyllable(
                    block.text,
                  )
                  ? OcrScript.korean
                  : OcrScript.latin,
              recognizedLanguages: block.recognizedLanguages,
            ),
          );
          continue;
        }
        for (final line in block.lines) {
          candidates.add(
            OcrTextBlock(
              text: line.text,
              bounds: line.boundingBox,
              script:
                  BookAnalysisTextPreprocessor.containsHangulSyllable(line.text)
                  ? OcrScript.korean
                  : OcrScript.latin,
              confidence: line.confidence,
              angle: line.angle,
              recognizedLanguages: line.recognizedLanguages,
            ),
          );
        }
      }

      final quality = evaluateOcrQuality(candidates);
      final blocks = arrangeBlocksForReading(candidates);
      final text = blocks.map((block) => block.text).join('\n').trim();
      if (text.isEmpty ||
          !BookAnalysisTextPreprocessor.containsHangulSyllable(text)) {
        return OcrResult.failure(reason: OcrFailure.noKoreanFound);
      }
      return OcrResult.success(
        text: text,
        blockCount: blocks.length,
        koreanBlockCount: blocks
            .where((block) => block.script == OcrScript.korean)
            .length,
        latinBlockCount: blocks
            .where((block) => block.script == OcrScript.latin)
            .length,
        discardedBlockCount: candidates.length - blocks.length,
        quality: quality,
      );
    } catch (error) {
      return OcrResult.failure(
        reason: OcrFailure.engineError,
        message: '$error',
      );
    } finally {
      await recognizer.close();
    }
  }

  /// Evaluates raw OCR lines before unsupported scripts are removed.
  static OcrQualityAssessment evaluateOcrQuality(
    Iterable<OcrTextBlock> source,
  ) {
    final blocks = source.toList(growable: false);
    var unsupportedCharacters = 0;
    var consideredCharacters = 0;
    final koreanLines = <OcrTextBlock>[];
    final angles = <double>[];

    for (final block in blocks) {
      final inspection = BookAnalysisTextPreprocessor.inspect(block.text);
      unsupportedCharacters += inspection.unsafeCharacterCount;
      consideredCharacters += inspection.consideredCharacterCount;
      if (inspection.hasKoreanText) {
        koreanLines.add(block);
      }
      final angle = block.angle;
      if (angle != null && angle.isFinite) {
        angles.add(_distanceFromUpright(angle));
      }
    }

    final unsupportedRatio = consideredCharacters == 0
        ? 0.0
        : unsupportedCharacters / consideredCharacters;
    final confidenceValues = koreanLines
        .map((line) => line.confidence)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList(growable: false);
    final lowConfidenceCount = confidenceValues
        .where((value) => value < lowConfidenceThreshold)
        .length;
    final lowConfidenceRatio = confidenceValues.isEmpty
        ? null
        : lowConfidenceCount / confidenceValues.length;
    final confidenceUnavailable =
        koreanLines.isNotEmpty && confidenceValues.isEmpty;
    final medianRotation = angles.length < minimumRotationLineCount
        ? null
        : _median(angles);

    final warnings = <String>[
      if (unsupportedCharacters > 0) 'unexpected_script_filtered',
      if (unsupportedRatio >= severeUnsupportedScriptRatio)
        'ocr_unsupported_script_severe',
      if (lowConfidenceCount > 0) 'low_confidence_text',
      if (lowConfidenceRatio != null &&
          lowConfidenceRatio >= severeLowConfidenceRatio)
        'ocr_low_confidence_severe',
      if (confidenceUnavailable) 'ocr_confidence_unavailable',
      if (medianRotation != null && medianRotation > severeRotationDegrees)
        'ocr_rotation_severe',
    ];
    final severeWarnings = <String>[
      if (unsupportedRatio >= severeUnsupportedScriptRatio)
        'ocr_unsupported_script_severe',
      if (lowConfidenceRatio != null &&
          lowConfidenceRatio >= severeLowConfidenceRatio)
        'ocr_low_confidence_severe',
      if (medianRotation != null && medianRotation > severeRotationDegrees)
        'ocr_rotation_severe',
    ];

    return OcrQualityAssessment(
      unsupportedScriptRatio: unsupportedRatio,
      lowConfidenceRatio: lowConfidenceRatio,
      medianRotationDegrees: medianRotation,
      koreanLineCount: koreanLines.length,
      confidenceLineCount: confidenceValues.length,
      warnings: warnings,
      severeWarnings: severeWarnings,
    );
  }

  /// De-duplicates overlapping OCR results and reads pages down each detected
  /// column. One, two and three-column textbook layouts are supported. Wide
  /// headings are emitted between the vertical bands they separate instead of
  /// being assigned to an arbitrary column.
  static List<OcrTextBlock> arrangeBlocksForReading(
    Iterable<OcrTextBlock> source,
  ) {
    final blocks = <OcrTextBlock>[];
    for (final candidate in source) {
      final sanitized = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
        candidate.text,
      );
      final cleaned = sanitized.text.trim();
      if (cleaned.isEmpty) {
        continue;
      }
      final normalized = cleaned.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      final isDuplicate = blocks.any(
        (existing) =>
            existing.text
                    .trim()
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .toLowerCase() ==
                normalized &&
            _intersectionOverUnion(existing.bounds, candidate.bounds) >= 0.65,
      );
      if (!isDuplicate) {
        blocks.add(
          OcrTextBlock(
            text: cleaned,
            bounds: candidate.bounds,
            script: BookAnalysisTextPreprocessor.containsHangulSyllable(cleaned)
                ? OcrScript.korean
                : OcrScript.latin,
            confidence: candidate.confidence,
            angle: candidate.angle,
            recognizedLanguages: candidate.recognizedLanguages,
          ),
        );
      }
    }

    if (blocks.length < 4) {
      return _arrangeBand(blocks);
    }

    final pageLeft = blocks.map((block) => block.bounds.left).reduce(math.min);
    final pageRight = blocks
        .map((block) => block.bounds.right)
        .reduce(math.max);
    final pageWidth = pageRight - pageLeft;
    final widths = blocks.map((block) => block.bounds.width).toList()..sort();
    final medianWidth = widths[widths.length ~/ 2];
    final spanningBlocks =
        blocks
            .where(
              (block) =>
                  pageWidth > 0 &&
                  block.bounds.width >= medianWidth * 1.6 &&
                  block.bounds.width / pageWidth >= 0.72,
            )
            .toList()
          ..sort(_compareWithinColumn);
    if (spanningBlocks.isEmpty) {
      return _arrangeBand(blocks);
    }

    final ordinaryBlocks = blocks
        .where((block) => !spanningBlocks.contains(block))
        .toList(growable: false);
    if (_splitColumns(ordinaryBlocks).length == 1) {
      return _arrangeBand(blocks);
    }

    final ordered = <OcrTextBlock>[];
    var remaining = [...ordinaryBlocks];
    for (final spanning in spanningBlocks) {
      final before = remaining
          .where((block) => block.bounds.center.dy < spanning.bounds.center.dy)
          .toList(growable: false);
      ordered.addAll(_arrangeBand(before));
      ordered.add(spanning);
      remaining = remaining
          .where((block) => block.bounds.center.dy >= spanning.bounds.center.dy)
          .toList(growable: false);
    }
    ordered.addAll(_arrangeBand(remaining));
    return ordered;
  }

  static List<OcrTextBlock> _arrangeBand(List<OcrTextBlock> blocks) {
    final columns = _splitColumns(blocks);
    for (final column in columns) {
      column.sort(_compareWithinColumn);
    }
    return columns.expand((column) => column).toList(growable: false);
  }

  static List<List<OcrTextBlock>> _splitColumns(List<OcrTextBlock> blocks) {
    if (blocks.length < 4) {
      return <List<OcrTextBlock>>[blocks];
    }

    final byCenter = [...blocks]
      ..sort((a, b) => a.bounds.center.dx.compareTo(b.bounds.center.dx));
    final widths = byCenter.map((block) => block.bounds.width).toList()..sort();
    final medianWidth = widths[widths.length ~/ 2];
    final minimumGap = math.max(24.0, medianWidth * 0.7);
    final candidates = <({int index, double gap})>[];
    for (var index = 0; index < byCenter.length - 1; index++) {
      final gap =
          byCenter[index + 1].bounds.center.dx -
          byCenter[index].bounds.center.dx;
      if (gap >= minimumGap) {
        candidates.add((index: index, gap: gap));
      }
    }
    candidates.sort((a, b) => b.gap.compareTo(a.gap));

    if (blocks.length >= 6 && candidates.length >= 2) {
      for (var first = 0; first < candidates.length - 1; first++) {
        for (var second = first + 1; second < candidates.length; second++) {
          final splits = <int>[
            candidates[first].index,
            candidates[second].index,
          ]..sort();
          if (splits[0] >= 1 &&
              splits[1] - splits[0] >= 2 &&
              byCenter.length - splits[1] - 1 >= 2) {
            return <List<OcrTextBlock>>[
              byCenter.sublist(0, splits[0] + 1),
              byCenter.sublist(splits[0] + 1, splits[1] + 1),
              byCenter.sublist(splits[1] + 1),
            ];
          }
        }
      }
    }

    for (final candidate in candidates) {
      if (candidate.index >= 1 && byCenter.length - candidate.index - 1 >= 2) {
        return <List<OcrTextBlock>>[
          byCenter.sublist(0, candidate.index + 1),
          byCenter.sublist(candidate.index + 1),
        ];
      }
    }
    return <List<OcrTextBlock>>[blocks];
  }

  static int _compareWithinColumn(OcrTextBlock a, OcrTextBlock b) {
    final vertical = a.bounds.top.compareTo(b.bounds.top);
    return vertical != 0 ? vertical : a.bounds.left.compareTo(b.bounds.left);
  }

  static double _distanceFromUpright(double value) {
    final normalized = ((value % 180) + 180) % 180;
    return normalized > 90 ? 180 - normalized : normalized;
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _intersectionOverUnion(Rect a, Rect b) {
    final overlap = a.intersect(b);
    if (overlap.isEmpty) {
      return 0;
    }
    final overlapArea = overlap.width * overlap.height;
    final union = a.width * a.height + b.width * b.height - overlapArea;
    return union <= 0 ? 0 : overlapArea / union;
  }
}

enum OcrScript { korean, latin }

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.bounds,
    required this.script,
    this.confidence,
    this.angle,
    this.recognizedLanguages = const [],
  });

  final String text;
  final Rect bounds;
  final OcrScript script;
  final double? confidence;
  final double? angle;
  final List<String> recognizedLanguages;
}

class OcrQualityAssessment {
  const OcrQualityAssessment({
    required this.unsupportedScriptRatio,
    required this.lowConfidenceRatio,
    required this.medianRotationDegrees,
    required this.koreanLineCount,
    required this.confidenceLineCount,
    required this.warnings,
    required this.severeWarnings,
  });

  static const empty = OcrQualityAssessment(
    unsupportedScriptRatio: 0,
    lowConfidenceRatio: null,
    medianRotationDegrees: null,
    koreanLineCount: 0,
    confidenceLineCount: 0,
    warnings: <String>[],
    severeWarnings: <String>[],
  );

  final double unsupportedScriptRatio;
  final double? lowConfidenceRatio;
  final double? medianRotationDegrees;
  final int koreanLineCount;
  final int confidenceLineCount;
  final List<String> warnings;
  final List<String> severeWarnings;

  bool get confidenceUnavailable =>
      koreanLineCount > 0 && confidenceLineCount == 0;

  bool get isSevere => severeWarnings.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'unsupportedScriptRatio': unsupportedScriptRatio,
    'lowConfidenceRatio': lowConfidenceRatio,
    'medianRotationDegrees': medianRotationDegrees,
    'koreanLineCount': koreanLineCount,
    'confidenceLineCount': confidenceLineCount,
    'confidenceUnavailable': confidenceUnavailable,
    'warnings': warnings,
    'severeWarnings': severeWarnings,
  };
}

enum OcrFailure { noKoreanFound, engineError }

class OcrResult {
  const OcrResult._({
    required this.text,
    required this.blockCount,
    required this.koreanBlockCount,
    required this.latinBlockCount,
    required this.discardedBlockCount,
    required this.quality,
    required this.failure,
    required this.message,
  });

  factory OcrResult.success({
    required String text,
    required int blockCount,
    int koreanBlockCount = 0,
    int latinBlockCount = 0,
    int discardedBlockCount = 0,
    OcrQualityAssessment quality = OcrQualityAssessment.empty,
  }) => OcrResult._(
    text: text,
    blockCount: blockCount,
    koreanBlockCount: koreanBlockCount,
    latinBlockCount: latinBlockCount,
    discardedBlockCount: discardedBlockCount,
    quality: quality,
    failure: null,
    message: null,
  );

  factory OcrResult.failure({required OcrFailure reason, String? message}) =>
      OcrResult._(
        text: null,
        blockCount: 0,
        koreanBlockCount: 0,
        latinBlockCount: 0,
        discardedBlockCount: 0,
        quality: OcrQualityAssessment.empty,
        failure: reason,
        message: message,
      );

  final String? text;
  final int blockCount;
  final int koreanBlockCount;
  final int latinBlockCount;
  final int discardedBlockCount;
  final OcrQualityAssessment quality;
  final OcrFailure? failure;
  final String? message;

  List<String> get qualityWarnings => quality.warnings;
  List<String> get severeQualityWarnings => quality.severeWarnings;
  bool get isSuccess => failure == null;
}
