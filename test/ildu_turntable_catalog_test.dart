import 'dart:convert';
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
          'ansarang',
          'changgo',
          'anchae',
          'anchae-store',
          'gokgan',
          'toilet-north',
          'toilet-south',
          'main-gate',
          'araechae',
          'jungmunganchae',
          'sadang',
          'sadang-gate',
          'hyeopmun-west',
          'hyeopmun-east',
        ]),
      );

      for (final entry in kIlDuTurntables.entries) {
        final spec = entry.value;
        expect(spec.anchorId, entry.key);
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
    final spec = kIlDuChanggoTurntable;
    for (var direction = 0; direction < 8; direction++) {
      expect(spec.directionForDegrees(direction * 45), direction);
    }
    expect(spec.directionForDegrees(360), 0);
    expect(spec.directionForDegrees(-45), 7);
    expect(kIlDuChanggoTurntable.directionForDegrees(90), 2);
    expect(kIlDuSotdaeulmunTurntable.directionForDegrees(3), 0);
    expect(kIlDuAnchaeTurntable.directionForDegrees(90), 2);
    expect(kIlDuAraechaeTurntable.directionForDegrees(315), 7);
    expect(kIlDuSadangTurntable.directionForDegrees(90), 2);
    expect(kIlDuSadangmunTurntable.directionForDegrees(315), 7);
    expect(kIlDuAnchaeStoreTurntable.directionForDegrees(90), 2);
    expect(kIlDuGokganTurntable.directionForDegrees(315), 7);
    expect(kIlDuToiletNorthTurntable.directionForDegrees(180), 4);
  });

  test(
    'each native set keeps one stable viewport across all eight directions',
    () {
      for (final spec in kIlDuTurntables.values) {
        expect(spec.frames.map((f) => f.sourceSize).toSet(), hasLength(1));
        expect(spec.frames.map((f) => f.displayBounds).toSet(), hasLength(1));
      }
    },
  );
  test('north and south toilets and east and west gates retain distinct native models', () {
    for (final pair in [
      (kIlDuToiletNorthTurntable, kIlDuToiletSouthTurntable),
      (kIlDuHyeopmunWestTurntable, kIlDuHyeopmunEastTurntable),
    ]) {
      expect(
        pair.$1.frames
            .map((f) => f.assetPath)
            .toSet()
            .intersection(pair.$2.frames.map((f) => f.assetPath).toSet()),
        isEmpty,
      );
    }
  });
  test('runtime frames match native export provenance hashes', () {
    final receipt = jsonDecode(
      File('docs/hanok_r16/RUNTIME_RETIREMENT_20261125.json')
          .readAsStringSync(),
    );
    final records = receipt['runtimeFiles'] as Map<String, dynamic>;
    for (final spec in kIlDuTurntables.values) {
      for (final frame in spec.frames) {
        expect(
          sha256.convert(File(frame.assetPath).readAsBytesSync()).toString(),
          records[frame.assetPath]['sha256'],
        );
      }
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
