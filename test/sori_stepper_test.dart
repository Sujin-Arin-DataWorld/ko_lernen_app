import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/stepper.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// §W-G G1.3: `SoriStepper` replaces `soriStageGyeFlow`'s arrow sentence
/// ("Mission abschließen → Laterne → gemeinsame Hanok") with a 3-step visual
/// indicator. This locks its contract: all step labels render, exactly the
/// current step is highlighted with `SoriColors.primary` (the rest muted),
/// an out-of-range `currentStep` clamps instead of throwing, and long
/// labels (the German "Gemeinsame Hanok" step) wrap inside their own third
/// of the row instead of overflowing at a narrow width and large text
/// scale.
void main() {
  const steps = [
    SoriStepData(icon: Icons.flag_outlined, label: 'Mission'),
    SoriStepData(icon: Icons.light_mode_rounded, label: 'Laterne'),
    SoriStepData(icon: Icons.cottage_rounded, label: 'Gemeinsame Hanok'),
  ];

  Widget harness(
    int currentStep, {
    double width = 390,
    double textScale = 1,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SoriStepper(steps: steps, currentStep: currentStep),
      ),
    ),
  );

  Icon stepIcon(WidgetTester tester, int index) => tester.widget<Icon>(
    find.descendant(
      of: find.byKey(ValueKey('sori-stepper-step-$index')),
      matching: find.byIcon(steps[index].icon),
    ),
  );

  testWidgets('renders every step label', (tester) async {
    await tester.pumpWidget(harness(0));
    for (final step in steps) {
      expect(find.text(step.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'highlights exactly the current step with SoriColors.primary, the rest muted',
    (tester) async {
      await tester.pumpWidget(harness(1));
      for (var i = 0; i < steps.length; i++) {
        final icon = stepIcon(tester, i);
        if (i == 1) {
          expect(
            icon.color,
            SoriColors.primary,
            reason: 'current step $i should be SoriColors.primary',
          );
        } else {
          expect(
            icon.color,
            isNot(SoriColors.primary),
            reason: 'non-current step $i should stay muted',
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('moving currentStep re-highlights a different step', (
    tester,
  ) async {
    await tester.pumpWidget(harness(0));
    expect(stepIcon(tester, 0).color, SoriColors.primary);
    expect(stepIcon(tester, 2).color, isNot(SoriColors.primary));

    await tester.pumpWidget(harness(2));
    expect(stepIcon(tester, 0).color, isNot(SoriColors.primary));
    expect(stepIcon(tester, 2).color, SoriColors.primary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an out-of-range currentStep clamps instead of throwing', (
    tester,
  ) async {
    await tester.pumpWidget(harness(99));
    expect(tester.takeException(), isNull);
    expect(stepIcon(tester, steps.length - 1).color, SoriColors.primary);

    await tester.pumpWidget(harness(-5));
    expect(tester.takeException(), isNull);
    expect(stepIcon(tester, 0).color, SoriColors.primary);
  });

  testWidgets(
    'a long label wraps inside its own third at 320dp/200% text without overflow',
    (tester) async {
      await tester.pumpWidget(harness(0, width: 320, textScale: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Gemeinsame Hanok'), findsOneWidget);
    },
  );
}
