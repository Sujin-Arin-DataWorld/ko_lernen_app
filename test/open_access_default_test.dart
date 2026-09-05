import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no deny-capable pack access boundary remains in app source', () {
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final dart = sourceFiles.map((file) => file.readAsStringSync()).join('\n');

    expect(File('lib/services/pack_access.dart').existsSync(), isFalse);
    expect(dart, isNot(contains('ensurePackAccess')));
    expect(dart, isNot(contains('packAccessLevel')));
  });

  test('store purchase SDK and paywall route are absent from app source', () {
    final dart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(dart, isNot(contains('package:purchases_flutter')));
    expect(dart, isNot(contains("case '/paywall'")));
    expect(File('lib/screens/paywall_screen.dart').existsSync(), isFalse);
  });
}
