import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  testWidgets('primary and secondary CTAs meet the readable size contract', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SoriButton.filled(label: 'Weiterlernen', onTap: () {}),
              SoriButton.outlined(label: 'Später', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Weiterlernen')).style!.fontSize, 18);
    expect(
      tester.getSize(find.text('Weiterlernen')).height,
      greaterThanOrEqualTo(21),
    );
    expect(tester.getSize(find.byType(SoriPressable).first).height, 56);
    expect(tester.widget<Text>(find.text('Später')).style!.fontSize, 16);
    expect(tester.getSize(find.byType(SoriPressable).last).height, 48);
  });

  testWidgets('CTAs gain comfortable size on tablets', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoriButton.filled(label: 'Weiterlernen', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Weiterlernen')).style!.fontSize,
      closeTo(19.8, 0.001),
    );
    expect(
      tester.getSize(find.byType(SoriPressable)).height,
      closeTo(61.6, 0.001),
    );
  });

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
