import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium beta unlock is disabled when no build define is supplied', () {
    final source = File('lib/services/premium_service.dart').readAsStringSync();

    expect(
      source,
      contains(
        RegExp(
          r"bool\.fromEnvironment\(\s*'BETA_UNLOCK_ALL'\s*,\s*defaultValue:\s*false,?\s*\)",
        ),
      ),
    );
  });
}
