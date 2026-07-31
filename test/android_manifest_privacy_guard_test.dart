import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest removes the unused advertising ID permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      matches(
        RegExp(
          r'android:name="com\.google\.android\.gms\.permission\.AD_ID"\s+tools:node="remove"',
        ),
      ),
    );
  });
}
