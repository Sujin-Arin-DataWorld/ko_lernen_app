import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/main.dart' show kAppSupportedOrientations;

void main() {
  test('allows the two portrait and two landscape device orientations', () {
    expect(kAppSupportedOrientations, hasLength(4));
    expect(
      kAppSupportedOrientations,
      containsAll(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  });
}
