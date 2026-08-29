import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';

void main() {
  test(
    'turntable catalog keeps eight authored and bounded frames per building',
    () {
      expect(
        kIlDuTurntables.keys,
        containsAll(<String>['sarangchae', 'ansarang']),
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
  });
}
