import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets('폰(390dp)에서는 배율을 건드리지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late TextScaler seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => SoriTypeScale(child: child!),
      home: Builder(builder: (c) { seen = MediaQuery.textScalerOf(c); return const SizedBox(); }),
    ));
    expect(seen.scale(10), 10);
  });

  testWidgets('태블릿(720dp)에서는 OS 배율 × 1.10', (tester) async {
    tester.view.physicalSize = const Size(720, 1024);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late TextScaler seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => SoriTypeScale(child: child!),
      home: Builder(builder: (c) { seen = MediaQuery.textScalerOf(c); return const SizedBox(); }),
    ));
    expect(seen.scale(10), closeTo(10 * 1.3 * 1.10, 1e-6));
  });

  testWidgets('SoriTextTheme 은 폭과 무관하게 같은 fontSize 를 낸다', (tester) async {
    for (final w in [390.0, 1280.0]) {
      tester.view.physicalSize = Size(w, 900);
      tester.view.devicePixelRatio = 1;
      late double size;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        size = SoriTextTheme.of(c).body.fontSize!;
        return const SizedBox();
      })));
      expect(size, 16, reason: 'width $w');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
