import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('SoriPressable activates with Enter and Space', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriPressable(
            haptic: null,
            onTap: () => activations += 1,
            child: const SizedBox(
              width: 120,
              height: 48,
              child: Center(child: Text('Open')),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(activations, 2);
  });

  testWidgets(
    'SoriPressable focus ring uses surface-aware 3 to 1 contrast colors',
    (tester) async {
      final cases =
          <({Brightness brightness, Color expectedRing, List<Color> surfaces})>[
            (
              brightness: Brightness.light,
              expectedRing: SoriColors.primaryDark,
              surfaces: const [
                SoriColors.lightBg,
                SoriColors.lightSurface,
                SoriColors.lightSurfaceAlt,
                SoriColors.lightSurfaceRaised,
              ],
            ),
            (
              brightness: Brightness.dark,
              expectedRing: SoriColors.darkPrimary,
              surfaces: const [
                SoriColors.darkBg,
                SoriColors.darkSurface,
                SoriColors.darkSurfaceAlt,
              ],
            ),
          ];

      for (final entry in cases) {
        for (final surface in entry.surfaces) {
          expect(
            SoriColors.contrastRatio(entry.expectedRing, surface),
            greaterThanOrEqualTo(3),
            reason:
                '${entry.brightness.name} focus ring must contrast with '
                '${surface.toARGB32().toRadixString(16)}',
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: entry.brightness),
            home: Scaffold(
              body: Center(
                child: SoriPressable(
                  key: ValueKey('pressable-${entry.brightness.name}'),
                  haptic: null,
                  onTap: () {},
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('Open')),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final pressable = find.byKey(
          ValueKey('pressable-${entry.brightness.name}'),
        );
        final ring = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: pressable,
                matching: find.byType(DecoratedBox),
              ),
            )
            .singleWhere((box) {
              final decoration = box.decoration;
              return decoration is BoxDecoration &&
                  decoration.border is Border &&
                  (decoration.border! as Border).top.width == 2;
            });
        final border = (ring.decoration as BoxDecoration).border! as Border;
        expect(border.top.color, entry.expectedRing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );
}
