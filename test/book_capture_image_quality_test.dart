import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/services/book_capture_image_quality.dart';

void main() {
  img.Image checkerboard(int width, int height) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = ((x ~/ 4) + (y ~/ 4)).isEven ? 0 : 255;
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    return image;
  }

  test('capture thresholds stay aligned with the product contract', () {
    expect(BookCaptureImageQualityAnalyzer.severeLaplacianVariance, 8);
    expect(BookCaptureImageQualityAnalyzer.warningLaplacianVariance, 25);
    expect(BookCaptureImageQualityAnalyzer.severeContrastRange, 20);
    expect(BookCaptureImageQualityAnalyzer.warningContrastRange, 45);
    expect(BookCaptureImageQualityAnalyzer.maxSampleDimension, 512);
  });

  test('flat low-contrast capture is severe for blur and contrast', () {
    final image = img.Image(width: 64, height: 64);
    img.fill(image, color: img.ColorRgb8(128, 128, 128));

    final quality = BookCaptureImageQualityAnalyzer.analyzeImage(image);

    expect(quality.laplacianVariance, 0);
    expect(quality.contrastRange, 0);
    expect(quality.severeWarnings, contains('image_blur_severe'));
    expect(quality.severeWarnings, contains('image_contrast_severe'));
  });

  test('sharp high-contrast capture clears image quality thresholds', () {
    final quality = BookCaptureImageQualityAnalyzer.analyzeImage(
      checkerboard(96, 72),
    );

    expect(quality.laplacianVariance, greaterThanOrEqualTo(25));
    expect(quality.contrastRange, greaterThanOrEqualTo(45));
    expect(quality.warnings, isEmpty);
  });

  test('metrics are stable for right-angle fixture rotations', () {
    final source = checkerboard(96, 64);
    final baseline = BookCaptureImageQualityAnalyzer.analyzeImage(source);

    for (final angle in <num>[90, 180, 270]) {
      final rotated = BookCaptureImageQualityAnalyzer.analyzeImage(
        img.copyRotate(source, angle: angle),
      );
      expect(
        rotated.laplacianVariance,
        closeTo(baseline.laplacianVariance, 0.001),
        reason: '$angle degrees',
      );
      expect(rotated.contrastRange, baseline.contrastRange);
    }
  });

  test('large images are measured from a maximum 512px sample', () {
    final quality = BookCaptureImageQualityAnalyzer.analyzeImage(
      checkerboard(1024, 256),
    );

    expect(quality.sampleWidth, 512);
    expect(quality.sampleHeight, 128);
  });

  test('invalid encoded image returns a blocking decode warning', () {
    final quality = BookCaptureImageQualityAnalyzer.analyzeBytes(
      Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(quality.decoded, isFalse);
    expect(quality.severeWarnings, ['image_decode_failed']);
  });

  test('file analysis returns a sendable 512px assessment', () async {
    final quality = await BookCaptureImageQualityAnalyzer.analyzeFile(
      File('assets/illustrations/book/book_camera_guide.png'),
    );

    expect(quality.decoded, isTrue);
    expect(quality.sampleWidth, lessThanOrEqualTo(512));
    expect(quality.sampleHeight, lessThanOrEqualTo(512));
  });
}
