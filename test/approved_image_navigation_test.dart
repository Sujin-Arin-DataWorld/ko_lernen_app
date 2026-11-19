import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/image_navigation_bar.dart';

const _labels = ['Today', 'Learn', 'Games', 'Hanok', 'Gye'];
const _assets = [
  ApprovedChromeAssets.today,
  ApprovedChromeAssets.learn,
  ApprovedChromeAssets.games,
  ApprovedChromeAssets.hanok,
  ApprovedChromeAssets.gye,
];

void main() {
  test('learning book matches the latest explicit user attachment', () {
    expect(
      sha256
          .convert(File(ApprovedChromeAssets.learn).readAsBytesSync())
          .toString(),
      'c4db0fd39d3b16c79db99ce75b1fccbea1eaf9acda64c52ed40bb6c4c8fc0b42',
    );
  });

  test('all nine bundled originals retain their recorded source bytes', () {
    final provenance =
        jsonDecode(
              File(
                'docs/assets/APPROVED_CHROME_20261030.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final assets = provenance['assets'] as List<dynamic>;
    expect(assets, hasLength(9));
    for (final record in assets.cast<Map<String, dynamic>>()) {
      expect(
        sha256
            .convert(File(record['asset'] as String).readAsBytesSync())
            .toString(),
        record['sha256'],
        reason: record['asset'] as String,
      );
      expect(record['alpha_extrema'][0], 0);
      expect(record['byte_identical'], isTrue);
    }
  });

  testWidgets(
    'five image-only destinations retain accessible names and targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      await _pump(tester, selected);
      expect(tester.takeException(), isNull);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.labelBehavior, NavigationDestinationLabelBehavior.alwaysHide);
      expect(bar.indicatorColor, Colors.transparent);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (var index = 0; index < _assets.length; index++) {
        final destination = _destination(index);
        final rect = tester.getRect(destination);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        final data = tester.getSemantics(destination).getSemanticsData();
        expect(data.label, contains(_labels[index]));
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          data.flagsCollection.isSelected,
          index == 0 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
        );
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(find.byTooltip(_labels[index]), findsOneWidget);
      }
      for (var index = 1; index < _assets.length; index++) {
        await tester.tap(_destination(index));
        await tester.pumpAndSettle();
        expect(selected.value, index);
        expect(
          tester
              .getSemantics(_destination(index))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          index,
        );
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'press depth follows contact and selection settles without loops',
    (tester) async {
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      await _pump(tester, selected);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(_depth(tester, 1), greaterThan(0));
      expect(selected.value, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected.value, 1);
      expect(_depth(tester, 1), lessThan(0));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('reduced motion retains selection with no spatial transform', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await _pump(tester, selected, reducedMotion: true);
    final gesture = await tester.startGesture(
      tester.getCenter(_destination(1)),
    );
    await tester.pump();
    expect(_depth(tester, 1), 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected.value, 1);
    expect(_depth(tester, 1), 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'backgrounding clears contact and resumes the same selected tab',
    (tester) async {
      final selected = ValueNotifier(2);
      addTearDown(selected.dispose);
      await _pump(tester, selected);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(1)),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(selected.value, 2);
      expect(_depth(tester, 1), 0);
      await gesture.cancel();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(selected.value, 2);
      expect(_depth(tester, 1), 0);
      expect(_depth(tester, 2), lessThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard activation reaches the same five real destinations', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await _pump(tester, selected);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected.value, 1);
  });

  testWidgets('switching image tabs preserves owner-held page state', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await _pump(tester, selected, retainPages: true);
    await tester.enterText(
      find.byKey(const ValueKey('saved-draft')),
      '한국어 draft',
    );
    await tester.tap(_destination(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment'));
    await tester.pump();
    await tester.tap(_destination(0));
    await tester.pumpAndSettle();
    expect(find.text('한국어 draft'), findsOneWidget);
    await tester.tap(_destination(1));
    await tester.pumpAndSettle();
    expect(find.text('Count 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _destination(int index) =>
    find.byKey(ValueKey('sori-image-destination-${_assets[index]}'));

double _depth(WidgetTester tester, int index) => tester
    .widget<Transform>(
      find.byKey(ValueKey('sori-navigation-depth-${_assets[index]}')).first,
    )
    .transform
    .storage[13];

Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<int> selected, {
  bool reducedMotion = false,
  bool retainPages = false,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          disableAnimations: reducedMotion,
        ),
        child: ValueListenableBuilder(
          valueListenable: selected,
          builder: (_, value, __) => Scaffold(
            body: retainPages
                ? IndexedStack(
                    index: value,
                    children: const [
                      TextField(key: ValueKey('saved-draft')),
                      _RetainedCounter(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  )
                : const SizedBox(),
            bottomNavigationBar: SoriImageNavigationBar(
              selectedIndex: value,
              onDestinationSelected: (index) => selected.value = index,
              labels: _labels,
              assets: _assets,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RetainedCounter extends StatefulWidget {
  const _RetainedCounter();

  @override
  State<_RetainedCounter> createState() => _RetainedCounterState();
}

class _RetainedCounterState extends State<_RetainedCounter> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('Count $_count'),
      TextButton(
        onPressed: () => setState(() => _count++),
        child: const Text('Increment'),
      ),
    ],
  );
}
