import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/share_slip.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('두루마리는 9:16이고 검정 외곽선이 없다', () async {
    final png = await ShareSlipRenderer.renderPng(
      korean: '안녕하세요',
      gloss: 'Guten Tag',
    );
    expect(png.length, greaterThan(800));
    expect(png[0], 0x89);
    expect(png[1], 0x50);

    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width / image.height, closeTo(9 / 16, 0.01));

    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    final data = bytes!.buffer.asUint8List();

    Color at(int x, int y) {
      final i = (y * image.width + x) * 4;
      return Color.fromARGB(data[i + 3], data[i], data[i + 1], data[i + 2]);
    }

    bool isBlackOutline(Color c) {
      return (c.r * 255) < 20 &&
          (c.g * 255) < 20 &&
          (c.b * 255) < 20 &&
          (c.a * 255) > 200;
    }

    expect(isBlackOutline(at(0, 0)), isFalse);
    expect(isBlackOutline(at(image.width - 1, 0)), isFalse);
    expect(isBlackOutline(at(0, image.height - 1)), isFalse);
    expect(isBlackOutline(at(image.width - 1, image.height - 1)), isFalse);

    final mid = at(image.width ~/ 2, (image.height * 0.12).round());
    expect(
      mid.computeLuminance(),
      greaterThan(SoriColors.lightText.computeLuminance()),
    );
    image.dispose();
    codec.dispose();
  });
}
