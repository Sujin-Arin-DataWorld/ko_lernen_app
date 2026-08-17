import 'dart:io';

import 'package:flutter/foundation.dart';
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

  testWidgets('QA estate reference remains outside the Flutter asset bundle', (
    tester,
  ) async {
    const qaPath = 'assets_unused/pending_review/reference_full_estate.png';
    const forbiddenRuntimePath =
        'assets/illustrations/personal_hanok_v2/map/reference_full_estate.png';

    expect(File(qaPath).existsSync(), isTrue);
    expect(File(forbiddenRuntimePath).existsSync(), isFalse);
    await expectLater(
      () async => rootBundle.load(qaPath),
      throwsA(isA<FlutterError>()),
    );
  });
}
