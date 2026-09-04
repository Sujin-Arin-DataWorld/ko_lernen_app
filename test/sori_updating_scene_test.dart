import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/updating_scene.dart';

/// §Jin 2026-09-03: `SoriUpdatingScene` gates the temporary "being rebuilt"
/// veil behind `kHanokWorldUpdating` on the Hanok/Gye tabs while the
/// compound-map illustrations are retired. This locks its own contract in
/// isolation: the veil, the message text, the outer image `Semantics`
/// label, the asset `errorBuilder` fallback, and that it renders identically
/// under reduce-motion (it holds no animation, so there is nothing to
/// freeze).
void main() {
  Widget harness({
    String asset = 'assets/illustrations/hanok/estate_overview.webp',
    String message = 'Dein Hanok wird gerade erneuert. Bald wieder da.',
    bool disableAnimations = false,
    Alignment messageAlignment = Alignment.center,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: SizedBox(
          width: 320,
          height: 240,
          child: SoriUpdatingScene(
            asset: asset,
            message: message,
            messageAlignment: messageAlignment,
          ),
        ),
      ),
    ),
  );

  testWidgets('shows a translucent veil over the asset', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.byType(ColoredBox), findsWidgets);
    final veils = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color.a > 0 && box.color.a < 1)
        .toList();
    expect(
      veils,
      isNotEmpty,
      reason: 'expected at least one translucent ColoredBox scrim',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the message under the construction mat', (tester) async {
    const message = 'Der gemeinsame Hof wird gerade erneuert.';
    await tester.pumpWidget(harness(message: message));
    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes the message as an image Semantics label', (
    tester,
  ) async {
    const message = 'Your hanok is being rebuilt. Back soon.';
    await tester.pumpWidget(harness(message: message));
    final semantics = tester.widget<Semantics>(
      find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == message,
          )
          .first,
    );
    expect(semantics.properties.image, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors a custom messageAlignment (Gye card avoids the '
      'progress ring)', (tester) async {
    const alignment = Alignment(0, -0.45);
    await tester.pumpWidget(harness(messageAlignment: alignment));
    final align = tester.widget<Align>(
      find.byKey(const ValueKey('sori-updating-scene-message-align')),
    );
    expect(align.alignment, alignment);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to a ColoredBox when the asset fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(harness(asset: 'assets/does/not/exist.webp'));
    await tester.pump();
    // The Image.asset's errorBuilder swaps in a ColoredBox instead of
    // throwing or leaving a blank/red error box.
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders identically with reduce-motion on (static — no '
      'animation to freeze)', (tester) async {
    const message = 'Dein Hanok wird gerade erneuert. Bald wieder da.';
    await tester.pumpWidget(
      harness(message: message, disableAnimations: false),
    );
    final withoutReduceMotion = tester
        .widgetList<Text>(find.text(message))
        .length;

    await tester.pumpWidget(harness(message: message, disableAnimations: true));
    final withReduceMotion = tester.widgetList<Text>(find.text(message)).length;

    expect(withReduceMotion, equals(withoutReduceMotion));
    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
