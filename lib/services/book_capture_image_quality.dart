import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

BookCaptureImageQuality _analyzeBookCaptureBytes(Uint8List bytes) =>
    BookCaptureImageQualityAnalyzer.analyzeBytes(bytes);

/// Local-only capture quality metrics. No image bytes leave the device.
abstract final class BookCaptureImageQualityAnalyzer {
  static const int maxSampleDimension = 512;
  static const double severeLaplacianVariance = 8;
  static const double warningLaplacianVariance = 25;
  static const double severeContrastRange = 20;
  static const double warningContrastRange = 45;

  static Future<BookCaptureImageQuality> analyzeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await compute(_analyzeBookCaptureBytes, bytes);
    } on Object {
      return BookCaptureImageQuality.decodeFailure();
    }
  }

  static BookCaptureImageQuality analyzeBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return BookCaptureImageQuality.decodeFailure();
      }
      return analyzeImage(decoded);
    } on Object {
      return BookCaptureImageQuality.decodeFailure();
    }
  }

  /// Public pure seam for deterministic fixtures and regression tests.
  static BookCaptureImageQuality analyzeImage(img.Image source) {
    var sampled = img.bakeOrientation(source);
    final longest = math.max(sampled.width, sampled.height);
    if (longest > maxSampleDimension) {
      if (sampled.width >= sampled.height) {
        sampled = img.copyResize(
          sampled,
          width: maxSampleDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        sampled = img.copyResize(
          sampled,
          height: maxSampleDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    if (sampled.width < 3 || sampled.height < 3) {
      return BookCaptureImageQuality.decodeFailure();
    }

    final luminance = Float64List(sampled.width * sampled.height);
    final histogram = List<int>.filled(256, 0);
    for (var y = 0; y < sampled.height; y++) {
      for (var x = 0; x < sampled.width; x++) {
        final value = (sampled.getPixel(x, y).luminanceNormalized * 255)
            .round()
            .clamp(0, 255);
        luminance[y * sampled.width + x] = value.toDouble();
        histogram[value]++;
      }
    }

    final p05 = _percentile(histogram, 0.05);
    final p95 = _percentile(histogram, 0.95);
    final contrast = (p95 - p05).toDouble();

    var laplacianSum = 0.0;
    var laplacianSquareSum = 0.0;
    var laplacianCount = 0;
    for (var y = 1; y < sampled.height - 1; y++) {
      for (var x = 1; x < sampled.width - 1; x++) {
        final center = luminance[y * sampled.width + x];
        final laplacian =
            4 * center -
            luminance[(y - 1) * sampled.width + x] -
            luminance[(y + 1) * sampled.width + x] -
            luminance[y * sampled.width + x - 1] -
            luminance[y * sampled.width + x + 1];
        laplacianSum += laplacian;
        laplacianSquareSum += laplacian * laplacian;
        laplacianCount++;
      }
    }
    final mean = laplacianSum / laplacianCount;
    final variance = math.max(
      0,
      laplacianSquareSum / laplacianCount - mean * mean,
    );

    final warnings = <String>[];
    final severeWarnings = <String>[];
    if (variance < severeLaplacianVariance) {
      warnings.add('image_blur_severe');
      severeWarnings.add('image_blur_severe');
    } else if (variance < warningLaplacianVariance) {
      warnings.add('image_blur_warning');
    }
    if (contrast < severeContrastRange) {
      warnings.add('image_contrast_severe');
      severeWarnings.add('image_contrast_severe');
    } else if (contrast < warningContrastRange) {
      warnings.add('image_contrast_warning');
    }

    return BookCaptureImageQuality(
      laplacianVariance: variance.toDouble(),
      contrastRange: contrast,
      sampleWidth: sampled.width,
      sampleHeight: sampled.height,
      warnings: warnings,
      severeWarnings: severeWarnings,
      decoded: true,
    );
  }

  static int _percentile(List<int> histogram, double percentile) {
    final total = histogram.fold<int>(0, (sum, count) => sum + count);
    final target = math.max(1, (total * percentile).ceil());
    var seen = 0;
    for (var value = 0; value < histogram.length; value++) {
      seen += histogram[value];
      if (seen >= target) {
        return value;
      }
    }
    return histogram.length - 1;
  }
}

class BookCaptureImageQuality {
  const BookCaptureImageQuality({
    required this.laplacianVariance,
    required this.contrastRange,
    required this.sampleWidth,
    required this.sampleHeight,
    required this.warnings,
    required this.severeWarnings,
    required this.decoded,
  });

  factory BookCaptureImageQuality.decodeFailure() =>
      const BookCaptureImageQuality(
        laplacianVariance: 0,
        contrastRange: 0,
        sampleWidth: 0,
        sampleHeight: 0,
        warnings: <String>['image_decode_failed'],
        severeWarnings: <String>['image_decode_failed'],
        decoded: false,
      );

  final double laplacianVariance;
  final double contrastRange;
  final int sampleWidth;
  final int sampleHeight;
  final List<String> warnings;
  final List<String> severeWarnings;
  final bool decoded;

  bool get isSevere => severeWarnings.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'laplacianVariance': laplacianVariance,
    'contrastRange': contrastRange,
    'sampleWidth': sampleWidth,
    'sampleHeight': sampleHeight,
    'decoded': decoded,
    'warnings': warnings,
    'severeWarnings': severeWarnings,
  };
}
