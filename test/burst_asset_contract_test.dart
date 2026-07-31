import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('celebration sheets are bundled and decode at their expected size', () async {
    for (final asset in const [
      'assets/illustrations/burst/burst_coins.png',
      'assets/illustrations/burst/burst_pouches.png',
    ]) {
      final bytes = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();

      expect(frame.image.width, 900, reason: asset);
      expect(frame.image.height, 600, reason: asset);

      frame.image.dispose();
      codec.dispose();
    }
  });
}
