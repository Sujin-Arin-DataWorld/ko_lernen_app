import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/dialog.dart';

void main() {
  testWidgets(
    'dialog keeps 200% content and actions reachable on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            padding: EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showSoriDialog<void>(
                      context: context,
                      builder: (dialogContext) => SoriDialog(
                        title: const Text('Berechtigung erklären'),
                        content: const Text(
                          'Diese längere Erklärung bleibt vollständig erreichbar, '
                          'auch wenn die Systemschrift stark vergrößert ist.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Weiter'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Öffnen'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(SoriDialog), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('barrier dismiss returns focus to the opener', (tester) async {
    final opener = FocusNode();
    addTearDown(opener.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              focusNode: opener,
              autofocus: true,
              onPressed: () => showSoriDialog<void>(
                context: context,
                builder: (_) => const SoriDialog(
                  title: Text('Hinweis'),
                  content: Text('Inhalt'),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(opener.hasFocus, isTrue);

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(SoriDialog), findsNothing);
    expect(opener.hasFocus, isTrue);
  });
}
