import 'dart:io';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR for bilingual Korean textbooks.
///
/// A Korean textbook page typically contains Hangul beside German or English
/// explanations. ML Kit exposes those scripts through separate recognizers, so
/// both are run for the same local image and their blocks are merged into a
/// stable, column-aware reading order. The image itself never leaves the
/// device.
class SnapOcrService {
  /// Recognizes Korean and Latin text in [imageFile]. The method name is kept
  /// for existing capture callers, but it intentionally returns both scripts.
  static Future<OcrResult> recognizeKorean(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final koreanRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );
    final latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final results = await Future.wait([
        koreanRecognizer.processImage(input),
        latinRecognizer.processImage(input),
      ]);
      final korean = results[0];
      final latin = results[1];
      final blocks = arrangeBlocksForReading([
        ...korean.blocks.map(
          (block) => OcrTextBlock(
            text: block.text,
            bounds: block.boundingBox,
            script: OcrScript.korean,
          ),
        ),
        ...latin.blocks.map(
          (block) => OcrTextBlock(
            text: block.text,
            bounds: block.boundingBox,
            script: OcrScript.latin,
          ),
        ),
      ]);
      final text = blocks.map((block) => block.text).join('\n').trim();
      if (text.isEmpty) {
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
      );
    } catch (error) {
      return OcrResult.failure(
        reason: OcrFailure.engineError,
        message: '$error',
      );
    } finally {
      await Future.wait<void>([
        koreanRecognizer.close(),
        latinRecognizer.close(),
      ]);
    }
  }

  /// De-duplicates overlapping script results and keeps two-column pages from
  /// being interleaved line by line. Kept pure so book layouts can be tested
  /// without a device OCR engine.
  static List<OcrTextBlock> arrangeBlocksForReading(
    Iterable<OcrTextBlock> source,
  ) {
    final blocks = <OcrTextBlock>[];
    for (final candidate in source) {
      final cleaned = candidate.text.trim();
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
            script: candidate.script,
          ),
        );
      }
    }

    final columnSplit = _columnSplit(blocks);
    if (columnSplit == null) {
      blocks.sort(_compareWithinColumn);
      return blocks;
    }

    final (left, right) = columnSplit;
    left.sort(_compareWithinColumn);
    right.sort(_compareWithinColumn);
    return [...left, ...right];
  }

  static (List<OcrTextBlock>, List<OcrTextBlock>)? _columnSplit(
    List<OcrTextBlock> blocks,
  ) {
    if (blocks.length < 4) {
      return null;
    }
    final byCenter = [...blocks]
      ..sort((a, b) => a.bounds.center.dx.compareTo(b.bounds.center.dx));
    var largestGap = 0.0;
    var splitAfter = -1;
    for (var index = 0; index < byCenter.length - 1; index++) {
      final gap =
          byCenter[index + 1].bounds.center.dx -
          byCenter[index].bounds.center.dx;
      if (gap > largestGap) {
        largestGap = gap;
        splitAfter = index;
      }
    }
    if (splitAfter < 1 || splitAfter >= byCenter.length - 2) {
      return null;
    }
    final widths = byCenter.map((block) => block.bounds.width).toList()..sort();
    final medianWidth = widths[widths.length ~/ 2];
    if (largestGap < 24 || largestGap < medianWidth * 0.7) {
      return null;
    }
    return (
      byCenter.sublist(0, splitAfter + 1),
      byCenter.sublist(splitAfter + 1),
    );
  }

  static int _compareWithinColumn(OcrTextBlock a, OcrTextBlock b) {
    final vertical = a.bounds.top.compareTo(b.bounds.top);
    return vertical != 0 ? vertical : a.bounds.left.compareTo(b.bounds.left);
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
  });

  final String text;
  final Rect bounds;
  final OcrScript script;
}

enum OcrFailure { noKoreanFound, engineError }

class OcrResult {
  final String? text;
  final int blockCount;
  final int koreanBlockCount;
  final int latinBlockCount;
  final OcrFailure? failure;
  final String? message;

  const OcrResult._({
    required this.text,
    required this.blockCount,
    required this.koreanBlockCount,
    required this.latinBlockCount,
    required this.failure,
    required this.message,
  });

  factory OcrResult.success({
    required String text,
    required int blockCount,
    int koreanBlockCount = 0,
    int latinBlockCount = 0,
  }) => OcrResult._(
    text: text,
    blockCount: blockCount,
    koreanBlockCount: koreanBlockCount,
    latinBlockCount: latinBlockCount,
    failure: null,
    message: null,
  );

  factory OcrResult.failure({required OcrFailure reason, String? message}) =>
      OcrResult._(
        text: null,
        blockCount: 0,
        koreanBlockCount: 0,
        latinBlockCount: 0,
        failure: reason,
        message: message,
      );

  bool get isSuccess => failure == null;
}
