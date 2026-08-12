import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('burst sheets finish preloading before the first app frame', () {
    final source = File('lib/main.dart').readAsStringSync();
    final preload = source.indexOf('await DancheongBurst.preload();');
    final runAppCall = source.indexOf('runApp(const KoLernenApp());');

    expect(preload, greaterThanOrEqualTo(0));
    expect(runAppCall, greaterThan(preload));
  });
}
