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
    // A2 살다 — 사랑방 가구 12 (2026-08-18). 이 목록은 디렉터리를 훑지 않으므로
    // 새 장식은 여기에 직접 넣어야 알파 검사를 받는다.
    'decoration_sabangtakja.png',
    'decoration_boryo_set.png',
    'decoration_bangseok_pair.png',
    'decoration_bandaji.png',
    'decoration_hwaro.png',
    'decoration_deungjan.png',
    'decoration_geomungo.png',
    'decoration_baduk.png',
    'decoration_mokchim.png',
    'decoration_byeongpung_small.png',
    'decoration_gobi.png',
    'decoration_hyangno.png',
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
