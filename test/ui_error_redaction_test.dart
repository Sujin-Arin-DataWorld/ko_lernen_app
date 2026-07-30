import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const auditedScreens = [
    'lib/screens/book_result_screen.dart',
    'lib/screens/quests_screen.dart',
    'lib/screens/vocab_packs_screen.dart',
    'lib/screens/vocab_pack_screen.dart',
  ];

  test('all audited loaders use the localized neutral message', () {
    for (final path in auditedScreens) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('e.toString()')));
      expect(source, contains('loadErrorTryAgain'));
    }
  });
}
