import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    VoidCallback? action, {
    bool reduced = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: SoriPressable(
              key: const ValueKey('physical-cta'),
              onTap: action,
              haptic: null,
              pressScale: .99,
              surfaceDepth: 4,
              child: const SizedBox(
                width: 180,
                height: 64,
                child: Text('Anhören'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  double scale(WidgetTester tester) => tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(SoriPressable),
          matching: find.byType(Transform),
        ),
      )
      .map((t) => t.transform.entry(0, 0))
      .reduce((a, b) => a < b ? a : b);

  testWidgets(
    'contact responds before tap recognition; cancel never activates',
    (tester) async {
      var calls = 0;
      await mount(tester, () => calls++);
      final pointer = await tester.startGesture(
        tester.getCenter(find.byType(SoriPressable)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 32));
      expect(scale(tester), lessThan(1));
      expect(calls, 0);
      await pointer.cancel();
      await tester.pumpAndSettle();
      expect(scale(tester), 1);
      expect(calls, 0);
      await tester.tap(find.byType(SoriPressable));
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );

  testWidgets('disabling a held CTA prevents stale activation', (tester) async {
    var calls = 0;
    await mount(tester, () => calls++);
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(SoriPressable)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await mount(tester, null);
    await pointer.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(scale(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion has no touch, hover or focus displacement', (
    tester,
  ) async {
    var calls = 0;
    await mount(tester, () => calls++, reduced: true);
    final rect = tester.getRect(find.text('Anhören'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(SoriPressable)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Anhören')), rect);
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(SoriPressable)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(scale(tester), 1);
    expect(tester.getRect(find.text('Anhören')), rect);
    await pointer.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    await mouse.removePointer();
  });
}
