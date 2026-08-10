import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/snap_ocr_service.dart';

void main() {
  OcrTextBlock block(
    String text,
    double left,
    double top, {
    OcrScript script = OcrScript.korean,
  }) => OcrTextBlock(
    text: text,
    bounds: Rect.fromLTWH(left, top, 80, 24),
    script: script,
  );

  test('reads a bilingual two-column page down each column', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('German top', 260, 12, script: OcrScript.latin),
      block('\uD55C\uAE00 top', 20, 10),
      block('German bottom', 260, 80, script: OcrScript.latin),
      block('\uD55C\uAE00 bottom', 20, 76),
    ]);

    expect(ordered.map((item) => item.text), [
      '\uD55C\uAE00 top',
      '\uD55C\uAE00 bottom',
      'German top',
      'German bottom',
    ]);
  });

  test('removes an overlapping duplicate returned by both recognizers', () {
    final ordered = SnapOcrService.arrangeBlocksForReading([
      block('\uD55C\uAD6D', 20, 10),
      block('\uD55C\uAD6D', 20, 10, script: OcrScript.latin),
      block('lesson', 20, 50, script: OcrScript.latin),
    ]);

    expect(ordered.map((item) => item.text), ['\uD55C\uAD6D', 'lesson']);
  });
}
