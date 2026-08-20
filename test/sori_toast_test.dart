import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/toast.dart';

void main() {
  testWidgets('rapid notices replace instead of queueing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                soriNotice(context, 'Erste Nachricht');
                soriNotice(context, 'Zweite Nachricht');
              },
              child: const Text('Anzeigen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Anzeigen'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Erste Nachricht'), findsNothing);
    expect(find.text('Zweite Nachricht'), findsOneWidget);
  });

  testWidgets('failure toast remains action-free', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => soriToast(context, 'Fehler'),
              child: const Text('Anzeigen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Anzeigen'));
    await tester.pump();

    expect(find.text('Fehler'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('actionable notice uses a dismissible sheet', (tester) async {
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showSoriActionNotice(
                context: context,
                message: 'Paket wurde gespeichert.',
                dismissLabel: 'Schließen',
                actionLabel: 'Spielen',
                onAction: () => actionCount++,
              ),
              child: const Text('Anzeigen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Anzeigen'));
    await tester.pumpAndSettle();

    expect(find.text('Paket wurde gespeichert.'), findsOneWidget);
    expect(find.text('Schließen'), findsOneWidget);
    expect(find.text('Spielen'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();

    expect(actionCount, 1);
    expect(find.text('Paket wurde gespeichert.'), findsNothing);
  });
}
