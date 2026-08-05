import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_catalog.dart';

void main() {
  testWidgets('every canonical map layer is present in Flutter asset bundle', (
    tester,
  ) async {
    for (final layer in kPersonalHanokLayers) {
      final bytes = await rootBundle.load(layer.assetPath);
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '${layer.id} must be bundled for the runtime map',
      );
    }
  });
}
