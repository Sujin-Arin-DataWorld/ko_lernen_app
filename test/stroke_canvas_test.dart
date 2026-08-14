import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

/// Regression: Buchstabenwechsel im StrokeCanvas darf keinen
/// "multiple tickers were created"-Fehler werfen.
///
/// Früher erzeugte didUpdateWidget bei jedem Buchstabenwechsel einen NEUEN
/// AnimationController (zweiter Ticker) → SingleTickerProviderStateMixin warf.
/// Jetzt wird der eine Controller wiederverwendet (nur Dauer + reset/forward).
void main() {
  Widget canvasFor(String letter) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: StrokeCanvas(letter: letter, strokes: hangulStrokes[letter]!),
      ),
    ),
  );

  testWidgets('Buchstabenwechsel wirft keinen Ticker-Fehler', (tester) async {
    await tester.pumpWidget(canvasFor('ㄱ')); // 1 Strich
    expect(tester.takeException(), isNull);

    // Buchstabe + Strichzahl ändern → didUpdateWidget-Pfad (alter Crash-Punkt).
    await tester.pumpWidget(canvasFor('ㄹ')); // 3 Striche
    expect(tester.takeException(), isNull);

    // Mehrfacher Wechsel hin und her — ein einziger Ticker muss reichen.
    await tester.pumpWidget(canvasFor('ㄷ')); // 2 Striche
    await tester.pumpWidget(canvasFor('ㅇ')); // Kreis-Strich
    await tester.pumpWidget(canvasFor('ㄱ'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tap startet neu (reset+forward) ohne Fehler', (tester) async {
    await tester.pumpWidget(canvasFor('ㅂ'));
    await tester.tap(find.byType(StrokeCanvas));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
