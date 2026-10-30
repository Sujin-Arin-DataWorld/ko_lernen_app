import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Measures actual opaque source pixels, including the hat and feet.
class CompanionInkBounds {
  const CompanionInkBounds(this.sourceSize, this.ink);
  final Size sourceSize;
  final Rect ink;

  static Future<CompanionInkBounds> load(String asset) async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var left = image.width;
    var top = image.height;
    var right = 0;
    var bottom = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (rgba.getUint8((y * image.width + x) * 4 + 3) < 16) {
          continue;
        }
        if (x < left) {
          left = x;
        }
        if (x >= right) {
          right = x + 1;
        }
        if (y < top) {
          top = y;
        }
        if (y >= bottom) {
          bottom = y + 1;
        }
      }
    }
    final result = CompanionInkBounds(
      Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        right.toDouble(),
        bottom.toDouble(),
      ),
    );
    image.dispose();
    codec.dispose();
    return result;
  }

  Rect inContainedImage(Rect imageWidget) {
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, imageWidget.size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      imageWidget,
    );
    final scale = destination.width / sourceSize.width;
    return Rect.fromLTRB(
      destination.left + ink.left * scale,
      destination.top + ink.top * scale,
      destination.left + ink.right * scale,
      destination.top + ink.bottom * scale,
    );
  }
}

void expectCompanionInkWithin(Rect ink, Rect slot) {
  expect(
    ink.left,
    greaterThanOrEqualTo(slot.left - 0.01),
    reason: 'Left source pixels must stay inside $slot; ink=$ink',
  );
  expect(
    ink.top,
    greaterThanOrEqualTo(slot.top - 0.01),
    reason: 'Hat/head source pixels must stay inside $slot; ink=$ink',
  );
  expect(
    ink.right,
    lessThanOrEqualTo(slot.right + 0.01),
    reason: 'Right source pixels must stay inside $slot; ink=$ink',
  );
  expect(
    ink.bottom,
    lessThanOrEqualTo(slot.bottom + 0.01),
    reason: 'Feet/source pixels must stay inside $slot; ink=$ink',
  );
}
