import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _newSlugs = <String>[
  'munbangsau',
  'bok',
  'crane',
  'wadang',
  'yeopjeon',
  'soban',
];

void main() {
  for (final slug in _newSlugs) {
    test('$slug PNG obeys the shared circle and ring contract', () {
      final file = File('assets/illustrations/stamps/stamp_$slug.png');
      expect(file.existsSync(), isTrue);
      final image = img.decodePng(file.readAsBytesSync());
      expect(image, isNotNull);
      expect(image!.width, 1024);
      expect(image.height, 1024);

      for (final point in const [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]) {
        expect(image.getPixel(point.$1, point.$2).a, 0);
      }
      expect(image.getPixel(512, 36).a, greaterThan(0));
      expect(image.getPixel(512, 35).a, 0);

      for (final point in const [
        (512, 64),
        (64, 512),
        (959, 512),
        (512, 959),
      ]) {
        final pixel = image.getPixel(point.$1, point.$2);
        expect((pixel.r - 0xC9).abs(), lessThanOrEqualTo(1));
        expect((pixel.g - 0x22).abs(), lessThanOrEqualTo(1));
        expect((pixel.b - 0x17).abs(), lessThanOrEqualTo(1));
        expect(pixel.a, 255);
      }
      expect(image.getPixel(512, 512).a, 255);
    });

    test('$slug stays within the approved hue families', () {
      final image = img.decodePng(
        File('assets/illustrations/stamps/stamp_$slug.png').readAsBytesSync(),
      )!;
      const palette = <(int, int, int)>[
        (0xC9, 0x22, 0x17),
        (0xF2, 0xEA, 0xD2),
        (0xFF, 0xFD, 0xEF),
        (0x31, 0x4E, 0x9C),
        (0x0C, 0x25, 0x72),
        (0xE9, 0xB8, 0x4A),
        (0xD0, 0x96, 0x2C),
        (0x39, 0x80, 0x5B),
        (0x61, 0xA0, 0x76),
      ];
      var violations = 0;
      var sampled = 0;
      for (var y = 40; y < 984; y += 8) {
        for (var x = 40; x < 984; x += 8) {
          final pixel = image.getPixel(x, y);
          if (pixel.a < 250) {
            continue;
          }
          sampled++;
          final nearest = palette
              .map(
                (color) => math.sqrt(
                  math.pow(pixel.r - color.$1, 2) +
                      math.pow(pixel.g - color.$2, 2) +
                      math.pow(pixel.b - color.$3, 2),
                ),
              )
              .reduce(math.min);
          if (nearest > 115) {
            violations++;
          }
        }
      }
      expect(violations / sampled, lessThan(0.005));
    });
  }
}
