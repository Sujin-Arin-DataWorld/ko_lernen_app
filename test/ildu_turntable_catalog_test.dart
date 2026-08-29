import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';

void main() {
  test(
    'turntable catalog keeps eight authored and bounded frames per anchor',
    () {
      expect(
        kIlDuTurntables.keys,
        containsAll(<String>[
          'sarangchae',
          'ansarang',
          'main-gate',
          'araechae',
        ]),
      );

      for (final spec in kIlDuTurntables.values) {
        expect(spec.frames, hasLength(8));
        expect(
          spec.frames.map((frame) => frame.assetPath).toSet(),
          hasLength(8),
        );
        for (final frame in spec.frames) {
          expect(
            File(frame.assetPath).existsSync(),
            isTrue,
            reason: frame.assetPath,
          );
          expect(frame.contentBounds.left, greaterThanOrEqualTo(0));
          expect(frame.contentBounds.top, greaterThanOrEqualTo(0));
          expect(
            frame.contentBounds.right,
            lessThanOrEqualTo(frame.sourceSize.width),
          );
          expect(
            frame.contentBounds.bottom,
            lessThanOrEqualTo(frame.sourceSize.height),
          );
          expect(frame.contentBounds.width, greaterThan(0));
          expect(frame.contentBounds.height, greaterThan(0));
          expect(frame.displayBounds.left, greaterThanOrEqualTo(0));
          expect(frame.displayBounds.top, greaterThanOrEqualTo(0));
          expect(
            frame.displayBounds.right,
            lessThanOrEqualTo(frame.sourceSize.width),
          );
          expect(
            frame.displayBounds.bottom,
            lessThanOrEqualTo(frame.sourceSize.height),
          );
          expect(
            frame.displayBounds.left,
            lessThanOrEqualTo(frame.contentBounds.left),
          );
          expect(
            frame.displayBounds.top,
            lessThanOrEqualTo(frame.contentBounds.top),
          );
          expect(
            frame.displayBounds.right,
            greaterThanOrEqualTo(frame.contentBounds.right),
          );
          expect(
            frame.displayBounds.bottom,
            greaterThanOrEqualTo(frame.contentBounds.bottom),
          );

          final image = img.decodePng(File(frame.assetPath).readAsBytesSync());
          expect(image, isNotNull, reason: frame.assetPath);
          expect(image!.width, frame.sourceSize.width);
          expect(image.height, frame.sourceSize.height);
          expect(
            _alphaBounds(image),
            frame.contentBounds,
            reason: '${frame.assetPath} alpha bounds drifted',
          );
          expect(frame.contentBounds.left, greaterThan(0));
          expect(frame.contentBounds.top, greaterThan(0));
          expect(frame.contentBounds.right, lessThan(frame.sourceSize.width));
          expect(frame.contentBounds.bottom, lessThan(frame.sourceSize.height));
        }
      }
    },
  );

  test('manifest degrees select the matching 45 degree frame', () {
    final spec = kIlDuSarangchaeTurntable;
    for (var direction = 0; direction < 8; direction++) {
      expect(spec.directionForDegrees(direction * 45), direction);
    }
    expect(spec.directionForDegrees(360), 0);
    expect(spec.directionForDegrees(-45), 7);
    expect(kIlDuSotdaeulmunTurntable.directionForDegrees(3), 0);
    expect(kIlDuAraechaeTurntable.directionForDegrees(315), 7);
  });

  test('Araechae preserves one authored canvas, viewport, and ground line', () {
    const expectedViewport = Rect.fromLTRB(448, 274, 2111, 1259);
    expect(
      kIlDuAraechaeTurntable.frames.map((frame) => frame.sourceSize).toSet(),
      <Size>{const Size(2560, 1440)},
    );
    expect(
      kIlDuAraechaeTurntable.frames.map((frame) => frame.displayBounds).toSet(),
      <Rect>{expectedViewport},
    );
    expect(
      kIlDuAraechaeTurntable.frames
          .map((frame) => frame.contentBounds.bottom)
          .toSet(),
      <double>{1259},
    );
  });

  test('Araechae runtime frames are exact copies of the review masters', () {
    const reviewRoot =
        'assets_unused/pending_review/personal_hanok_v3/'
        'changgo_turnaround_v1/';
    for (final frame in kIlDuAraechaeTurntable.frames) {
      final runtime = File(frame.assetPath);
      final reviewName = runtime.uri.pathSegments.last.replaceFirst(
        'ildu_',
        '',
      );
      final review = File('$reviewRoot$reviewName');
      expect(review.existsSync(), isTrue, reason: review.path);
      expect(
        sha256.convert(runtime.readAsBytesSync()),
        sha256.convert(review.readAsBytesSync()),
        reason: '${runtime.path} must remain byte-identical to ${review.path}',
      );
    }
  });
}

Rect _alphaBounds(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a == 0) {
        continue;
      }
      if (x < left) {
        left = x;
      }
      if (y < top) {
        top = y;
      }
      if (x > right) {
        right = x;
      }
      if (y > bottom) {
        bottom = y;
      }
    }
  }
  if (right < left || bottom < top) {
    return Rect.zero;
  }
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    (right + 1).toDouble(),
    (bottom + 1).toDouble(),
  );
}
