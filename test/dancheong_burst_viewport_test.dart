import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_burst.dart';

void main() {
  test(
    'burst stays inside a 360dp Android viewport near the top-right mascot',
    () {
      final placement = DancheongBurstLayout.fit(
        viewport: const Size(360, 760),
        preferredOrigin: const Offset(314, 22),
        intensity: 1,
      );

      expect(placement.maxPaintBounds.left, greaterThanOrEqualTo(12));
      expect(placement.maxPaintBounds.top, greaterThanOrEqualTo(12));
      expect(placement.maxPaintBounds.right, lessThanOrEqualTo(348));
      expect(placement.maxPaintBounds.bottom, lessThanOrEqualTo(748));
      expect(placement.intensity, lessThan(1));
      expect(placement.origin.dx, lessThan(314));
      expect(placement.origin.dy, greaterThan(22));
    },
  );

  test('burst preserves its requested size when the viewport is generous', () {
    final placement = DancheongBurstLayout.fit(
      viewport: const Size(600, 1000),
      preferredOrigin: const Offset(300, 500),
      intensity: 1,
    );

    expect(placement.intensity, 1);
    expect(placement.origin, const Offset(300, 500));
  });

  test('post-fit scale expands a centered burst exactly six times', () {
    const viewport = Size(360, 760);
    const center = Offset(180, 380);
    final fitted = DancheongBurstLayout.fit(
      viewport: viewport,
      preferredOrigin: center,
      intensity: 2.4,
    );
    final enlarged = DancheongBurstLayout.fit(
      viewport: viewport,
      preferredOrigin: center,
      intensity: 2.4,
      postFitScale: 6,
    );

    expect(enlarged.origin, center);
    expect(enlarged.intensity, closeTo(fitted.intensity * 6, 0.000001));
    expect(
      enlarged.maxPaintBounds.width,
      closeTo(fitted.maxPaintBounds.width * 6, 0.000001),
    );
    expect(
      enlarged.maxPaintBounds.height,
      closeTo(fitted.maxPaintBounds.height * 6, 0.000001),
    );
  });
}
