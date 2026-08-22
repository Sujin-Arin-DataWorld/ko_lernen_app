import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  testWidgets('explicit button label is announced once with a tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriButton.filled(label: 'Weiterlernen', onTap: () {}),
        ),
      ),
    );

    final data = tester
        .getSemantics(find.byType(SoriButton))
        .getSemanticsData();
    expect(data.label, 'Weiterlernen');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('optional assistive label adds context without changing copy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriButton.outlined(
            label: 'Anhören',
            semanticLabel: '안녕하세요 anhören',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Anhören'), findsOneWidget);
    final data = tester
        .getSemantics(find.byType(SoriButton))
        .getSemanticsData();
    expect(data.label, '안녕하세요 anhören');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

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

    // 2026-08-19: 글자 배율은 SoriTypeScale(MaterialApp.builder) 하나로 모았다
    // — 이 테스트는 builder 를 안 쓰므로 fontSize 는 이제 comfort 배율 없이
    // 그대로 나온다. 높이·패딩의 comfort 배율은 button.dart 에 남아 있다.
    expect(tester.widget<Text>(find.text('Weiterlernen')).style!.fontSize, 18);
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

  testWidgets('default CTA preserves its full label at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const label = 'Mit deinem nächsten persönlichen Lernschritt weitermachen';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 2,
                maxScaleFactor: 2,
                child: const SoriButton.filled(label: label),
              ),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(label));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.getSize(find.text(label)).height, greaterThan(60));
    expect(tester.takeException(), isNull);
  });
}
