import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/pack_access.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

void main() {
  test('every build has open learning access and no purchases', () {
    expect(PremiumService.fullAccessBuild, isTrue);
    expect(PremiumService.hasContentAccess, isTrue);
    expect(PremiumService.purchasesEnabled, isFalse);
  });

  testWidgets('every CEFR pack level passes the shared access boundary', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(await ensurePackAccess(context, level: level), isTrue);
    }
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
