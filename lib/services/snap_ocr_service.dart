import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'book_analysis_text.dart';
import 'book_ocr_document.dart';

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
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final temporaryFiles = <File>[];

    try {
      final initialBlocks = await _recognizeFile(imageFile, recognizer);
      final initial = OcrOrientationCandidate(
        quarterTurn: 0,
        blocks: initialBlocks,
      );
      final orientationCandidates = <OcrOrientationCandidate>[initial];
      final retryTurns = _orientationRetryTurns(initial);
      if (retryTurns.isNotEmpty) {
        final bytes = await imageFile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final baked = img.bakeOrientation(decoded);
          for (final turn in retryTurns) {
            final candidateFile = await _writeRotatedCandidate(
              imageFile,
              baked,
              turn,
            );
            temporaryFiles.add(candidateFile);
            final blocks = await _recognizeFile(candidateFile, recognizer);
            orientationCandidates.add(
              OcrOrientationCandidate(quarterTurn: turn, blocks: blocks),
            );
          }
        }
      }

      final selected = selectBestOrientation(orientationCandidates);
      if (selected.quarterTurn != 0) {
        final selectedFile = temporaryFiles.firstWhere(
          (file) => file.path.contains('_q${selected.quarterTurn}.'),
        );
        await imageFile.writeAsBytes(
          await selectedFile.readAsBytes(),
          flush: true,
        );
      }

      var quality = evaluateOcrQuality(selected.blocks);
      if (selected.quarterTurn != 0) {
        quality = quality.withWarning('ocr_orientation_corrected');
      }
      final blocks = arrangeBlocksForReading(selected.blocks);
      final document = BookOcrDocumentBuilder.build(
        blocks.map(
          (block) => BookOcrLine(
            text: block.text,
            bounds: block.bounds,
            sourceLineId: 'block:${block.blockIndex}:line:${block.lineIndex}',
            blockIndex: block.blockIndex,
            lineIndex: block.lineIndex,
            confidence: block.confidence,
            recognizedLanguages: block.recognizedLanguages,
          ),
        ),
      );
      final text = document.analysisText;
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
        discardedBlockCount: selected.blocks.length - blocks.length,
        quality: quality,
        document: document,
        chosenQuarterTurn: selected.quarterTurn,
        orientationRetryCount: orientationCandidates.length - 1,
      );
    } catch (error) {
      return OcrResult.failure(
        reason: OcrFailure.engineError,
        message: '$error',
      );
    } finally {
      for (final file in temporaryFiles) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } on Object {
          // The OS temp cleaner may remove an OCR candidate later.
        }
      }
      await recognizer.close();
    }
  }

  static Future<List<OcrTextBlock>> _recognizeFile(
    File imageFile,
    TextRecognizer recognizer,
  ) async {
    final recognized = await recognizer.processImage(
      InputImage.fromFile(imageFile),
    );
    final candidates = <OcrTextBlock>[];
    for (
      var blockIndex = 0;
      blockIndex < recognized.blocks.length;
      blockIndex++
    ) {
      final block = recognized.blocks[blockIndex];
      if (block.lines.isEmpty) {
        candidates.add(
          OcrTextBlock(
            text: block.text,
            bounds: block.boundingBox,
            script:
                BookAnalysisTextPreprocessor.containsHangulSyllable(block.text)
                ? OcrScript.korean
                : OcrScript.latin,
            recognizedLanguages: block.recognizedLanguages,
            blockIndex: blockIndex,
            lineIndex: 0,
          ),
        );
        continue;
      }
      for (var lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];
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
            blockIndex: blockIndex,
            lineIndex: lineIndex,
          ),
        );
      }
    }
    return candidates;
  }

  static Future<File> _writeRotatedCandidate(
    File source,
    img.Image baked,
    int quarterTurn,
  ) async {
    final rotated = img.copyRotate(baked, angle: quarterTurn.toDouble());
    final extension = source.path.toLowerCase().endsWith('.png')
        ? 'png'
        : 'jpg';
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'hangul_sori_ocr_${DateTime.now().microsecondsSinceEpoch}'
        '_q$quarterTurn.$extension';
    final encoded = extension == 'png'
        ? img.encodePng(rotated)
        : img.encodeJpg(rotated, quality: 100);
    final file = File(path);
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  static List<int> _orientationRetryTurns(OcrOrientationCandidate initial) {
    final blocks = initial.blocks;
    final quality = evaluateOcrQuality(blocks);
    final signedAngle = _signedMedianAngle(blocks);
    final hangulCount = blocks.fold<int>(
      0,
      (sum, block) => sum + _hangulSyllableCount(block.text),
    );

    if (hangulCount == 0 ||
        (quality.lowConfidenceRatio == null && quality.koreanLineCount == 0) ||
        (quality.lowConfidenceRatio != null &&
            quality.lowConfidenceRatio! >= severeLowConfidenceRatio)) {
      return const <int>[90, 180, 270];
    }
    if (signedAngle == null) {
      // With fewer than three angle-bearing lines, orientation evidence is
      // too weak to distinguish an upright short card from 90/270 degrees.
      return const <int>[90, 180, 270];
    }
    final absolute = signedAngle.abs();
    if (absolute >= 135) {
      return const <int>[180];
    }
    if (absolute >= 45) {
      return const <int>[90, 180, 270];
    }
    // ML Kit can occasionally read an upside-down line with angle=0. Always
    // compare one 180-degree candidate so that this case is not silently
    // accepted. Sideways candidates remain conditional to limit latency.
    return const <int>[180];
  }

  @visibleForTesting
  static List<int> orientationRetryTurnsForTesting(
    OcrOrientationCandidate initial,
  ) => _orientationRetryTurns(initial);

  /// Chooses the orientation with the strongest Korean, confidence and
  /// upright-line evidence. A stable tie keeps the unrotated image.
  static OcrOrientationCandidate selectBestOrientation(
    Iterable<OcrOrientationCandidate> source,
  ) {
    final candidates = source.toList(growable: false);
    if (candidates.isEmpty) {
      throw ArgumentError.value(source, 'source', 'must not be empty');
    }
    return candidates.reduce((best, candidate) {
      final bestScore = _orientationScore(best);
      final candidateScore = _orientationScore(candidate);
      if (candidateScore > bestScore + 0.000001) {
        return candidate;
      }
      if ((candidateScore - bestScore).abs() <= 0.000001 &&
          candidate.quarterTurn == 0) {
        return candidate;
      }
      return best;
    });
  }

  static double _orientationScore(OcrOrientationCandidate candidate) {
    final blocks = candidate.blocks;
    if (blocks.isEmpty) {
      return double.negativeInfinity;
    }
    final hangulCount = blocks.fold<int>(
      0,
      (sum, block) => sum + _hangulSyllableCount(block.text),
    );
    final koreanLines = blocks
        .where(
          (block) =>
              BookAnalysisTextPreprocessor.containsHangulSyllable(block.text),
        )
        .length;
    final confidences = blocks
        .map((block) => block.confidence)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList(growable: false);
    final averageConfidence = confidences.isEmpty
        ? 0.5
        : confidences.reduce((left, right) => left + right) /
              confidences.length;
    final angles = blocks
        .map((block) => block.angle)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList(growable: false);
    final uprightRatio = angles.isEmpty
        ? 0.5
        : angles
                  .where(
                    (angle) =>
                        _normalizeSignedAngle(angle).abs() <=
                        severeRotationDegrees,
                  )
                  .length /
              angles.length;
    final quality = evaluateOcrQuality(blocks);
    return hangulCount * 10 +
        koreanLines * 5 +
        averageConfidence * 50 +
        uprightRatio * 100 -
        quality.unsupportedScriptRatio * 100 -
        (quality.medianRotationDegrees ?? 0) * 2;
  }

  static int _hangulSyllableCount(String value) =>
      RegExp(r'[\uAC00-\uD7A3]').allMatches(value).length;

  static double? _signedMedianAngle(Iterable<OcrTextBlock> source) {
    final angles = source
        .map((block) => block.angle)
        .whereType<double>()
        .where((value) => value.isFinite)
        .map(_normalizeSignedAngle)
        .toList(growable: false);
    if (angles.length < minimumRotationLineCount) {
      return null;
    }
    return _median(angles);
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
        angles.add(_normalizeSignedAngle(angle).abs());
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
            blockIndex: candidate.blockIndex,
            lineIndex: candidate.lineIndex,
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

  static double _normalizeSignedAngle(double value) {
    var normalized = ((value % 360) + 360) % 360;
    if (normalized > 180) {
      normalized -= 360;
    }
    return normalized;
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

class OcrOrientationCandidate {
  const OcrOrientationCandidate({
    required this.quarterTurn,
    required this.blocks,
  });

  final int quarterTurn;
  final List<OcrTextBlock> blocks;
}

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.bounds,
    required this.script,
    this.confidence,
    this.angle,
    this.recognizedLanguages = const [],
    this.blockIndex = -1,
    this.lineIndex = -1,
  });

  final String text;
  final Rect bounds;
  final OcrScript script;
  final double? confidence;
  final double? angle;
  final List<String> recognizedLanguages;
  final int blockIndex;
  final int lineIndex;
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

  OcrQualityAssessment withWarning(String warning) => OcrQualityAssessment(
    unsupportedScriptRatio: unsupportedScriptRatio,
    lowConfidenceRatio: lowConfidenceRatio,
    medianRotationDegrees: medianRotationDegrees,
    koreanLineCount: koreanLineCount,
    confidenceLineCount: confidenceLineCount,
    warnings: <String>{...warnings, warning}.toList(growable: false),
    severeWarnings: severeWarnings,
  );

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
    required this.document,
    required this.chosenQuarterTurn,
    required this.orientationRetryCount,
  });

  factory OcrResult.success({
    required String text,
    required int blockCount,
    int koreanBlockCount = 0,
    int latinBlockCount = 0,
    int discardedBlockCount = 0,
    OcrQualityAssessment quality = OcrQualityAssessment.empty,
    BookOcrDocument? document,
    int chosenQuarterTurn = 0,
    int orientationRetryCount = 0,
  }) => OcrResult._(
    text: text,
    blockCount: blockCount,
    koreanBlockCount: koreanBlockCount,
    latinBlockCount: latinBlockCount,
    discardedBlockCount: discardedBlockCount,
    quality: quality,
    failure: null,
    message: null,
    document: document,
    chosenQuarterTurn: chosenQuarterTurn,
    orientationRetryCount: orientationRetryCount,
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
        document: null,
        chosenQuarterTurn: 0,
        orientationRetryCount: 0,
      );

  final String? text;
  final int blockCount;
  final int koreanBlockCount;
  final int latinBlockCount;
  final int discardedBlockCount;
  final OcrQualityAssessment quality;
  final OcrFailure? failure;
  final String? message;
  final BookOcrDocument? document;
  final int chosenQuarterTurn;
  final int orientationRetryCount;

  List<String> get qualityWarnings => quality.warnings;
  List<String> get severeQualityWarnings => quality.severeWarnings;
  bool get isSuccess => failure == null;
}
