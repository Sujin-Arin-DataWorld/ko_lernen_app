import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  testWidgets('full-width primary CTA can opt into two lines', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const label = 'Mit deinem Lernweg weitermachen';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: SoriButton.filled(
                label: label,
                fullWidth: true,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text(label)).maxLines, 2);
    expect(tester.takeException(), isNull);
  });
}
