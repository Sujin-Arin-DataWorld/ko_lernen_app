import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize < 30 ? 2 : 1.5);

  @override
  double get textScaleFactor => 2;
}

void main() {
  testWidgets('shared busy glyph preserves SoriButton paint and tap lock', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriButton.filled(
            label: 'Save',
            loading: true,
            onTap: () => calls++,
          ),
        ),
      ),
    );
    final glyph = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(glyph.strokeWidth, 2);
    expect(glyph.value, isNull);
    expect(
      glyph.valueColor!.value,
      tester
          .widget<SoriLoadingIndicator>(find.byType(SoriLoadingIndicator))
          .color,
    );
    await tester.tap(find.byType(SoriButton));
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  Future<void> open(
    WidgetTester tester, {
    required bool artwork,
    TextScaler scaler = const TextScaler.linear(2),
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: scaler,
            padding: const EdgeInsets.only(top: 44, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: SoriTextAction(
              label: 'Open',
              onPressed: () => showSoriSheet<void>(
                context: context,
                presentation: artwork
                    ? const SoriSheetPresentation(
                        backgroundColor: Color(0xfffff2dc),
                        constraints: BoxConstraints(maxWidth: 402),
                      )
                    : null,
                builder: (sheet) => artwork
                    ? SafeArea(
                        top: false,
                        child: Column(
                          key: const Key('sheet-content'),
                          children: [
                            const Expanded(child: Center(child: Text('Body'))),
                            SoriTextAction(
                              key: const Key('sheet-dismiss'),
                              label: 'Close',
                              onPressed: () => Navigator.of(sheet).pop(),
                            ),
                          ],
                        ),
                      )
                    : const Text('Body'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('default sheet still uses its padded shell and 130% clamp', (
    tester,
  ) async {
    await open(tester, artwork: false);
    expect(find.byType(SoriSheetShell), findsOneWidget);
    final scaler = MediaQuery.textScalerOf(tester.element(find.text('Body')));
    expect(scaler.scale(16), closeTo(20.8, .001));
    expect(scaler.scale(40), closeTo(52, .001));
    expect(tester.takeException(), isNull);
  });

  for (final scaler in [const TextScaler.linear(2), const _NonlinearScaler()]) {
    testWidgets('artwork sheet preserves $scaler and a reachable safe close', (
      tester,
    ) async {
      await open(tester, artwork: true, scaler: scaler);
      expect(find.byType(SoriSheetShell), findsNothing);
      final actual = MediaQuery.textScalerOf(tester.element(find.text('Body')));
      expect(actual, same(scaler));
      expect(actual.scale(16), scaler.scale(16));
      expect(actual.scale(40), scaler.scale(40));
      final content = tester.getRect(find.byKey(const Key('sheet-content')));
      expect(content.top, greaterThanOrEqualTo(44));
      expect(content.bottom, lessThanOrEqualTo(640 - 34));
      expect(content.height, lessThanOrEqualTo(640 * .88));
      final close = find.byKey(const Key('sheet-dismiss'));
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('artwork close remains above keyboard and bottom safe inset', (
    tester,
  ) async {
    await open(tester, artwork: true, keyboard: 220);
    final content = tester.getRect(find.byKey(const Key('sheet-content')));
    expect(content.top, greaterThanOrEqualTo(44));
    expect(content.bottom, lessThanOrEqualTo(640 - 220 - 34));
    await tester.tap(find.byKey(const Key('sheet-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared text action retains label, target and disabled state', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SoriTextAction(label: 'Active', onPressed: () => calls++),
              const SoriTextAction(label: 'Disabled', onPressed: null),
            ],
          ),
        ),
      ),
    );
    for (final action in find.byType(SoriTextAction).evaluate()) {
      expect(
        tester.getSize(find.byWidget(action.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.tap(find.text('Active'));
    await tester.tap(find.text('Disabled'));
    expect(calls, 1);
  });
}
