import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

/// Regression: Mascot mit umschaltendem [Mascot.animate] (true→false→true)
/// darf keinen "multiple tickers were created"-Fehler werfen.
///
/// _motion wird bei animate=false disposed (=null) und bei animate=true neu
/// erstellt. Mit SingleTickerProviderStateMixin warf die zweite Erstellung;
/// jetzt nutzt _MascotState TickerProviderStateMixin.
void main() {
  Widget mascot(bool animate) => MaterialApp(
        home: Scaffold(
          body: Center(child: Mascot.tiger(animate: animate)),
        ),
      );

  testWidgets('animate-Toggle true→false→true wirft keinen Ticker-Fehler',
      (tester) async {
    await tester.pumpWidget(mascot(true)); // Ticker #1
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(mascot(false)); // dispose → _motion = null
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(mascot(true)); // Ticker #2 (früherer Crash)
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
  });
}
