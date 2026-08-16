import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  const repaired = <String>[
    'decoration_chuseok_moon.png',
    'decoration_hangeulday_plaque.png',
    'decoration_kite.png',
    'decoration_seollal_flag.png',
    'decoration_sagunja_guk.png',
  ];

  test('free-placement decorations have genuine transparent pixels', () async {
    for (final name in repaired) {
      final file = File('assets/illustrations/decorations/$name');
      expect(file.existsSync(), isTrue, reason: name);
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels, isNotNull, reason: '$name must decode as RGBA');
      final bytes = pixels!.buffer.asUint8List();
      expect(
        Iterable<int>.generate(
          frame.image.width * frame.image.height,
          (index) => bytes[(index * 4) + 3],
        ).any((alpha) => alpha < 255),
        isTrue,
        reason: '$name still has a baked-in opaque background',
      );
      frame.image.dispose();
      codec.dispose();
    }
  });
}
