import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_motion.dart';
import 'package:ko_lernen_app/widgets/practice_layout.dart';
import 'package:ko_lernen_app/widgets/practice_magic.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets('hint focus survives motion changes without replaying old help', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    Widget host(bool reduced, int pulse) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: PracticeHintEmphasis(
              pulse: pulse,
              child: TextButton(
                focusNode: focus,
                onPressed: () {},
                child: const Text('Crossing field'),
              ),
            ),
          ),
        ),
      ),
    );
    double visibleHintAlpha() =>
        (tester
                    .widget<DecoratedBox>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is DecoratedBox &&
                            w.position == DecorationPosition.foreground,
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .border!
            .top
            .color
            .a;

    await tester.pumpWidget(host(false, 0));
    focus.requestFocus();
    await tester.pump();
    await tester.pumpWidget(host(false, 1));
    await tester.pump(const Duration(milliseconds: 20));
    expect(visibleHintAlpha(), greaterThan(0));
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(host(false, 0));
    expect(
      visibleHintAlpha(),
      0,
      reason: 'A field leaving the current hint loses its glow immediately.',
    );
    await tester.pumpWidget(host(false, 1));
    await tester.pumpWidget(host(true, 2));
    await tester.pump();
    expect(visibleHintAlpha(), 0);
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(host(false, 2));
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      visibleHintAlpha(),
      0,
      reason: 'Help consumed with motion off must stay consumed.',
    );
    expect(focus.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('depth follows a press without stealing the button or scroll', (
    tester,
  ) async {
    var taps = 0;
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              PracticeMotionSurface(
                interactive: true,
                child: SizedBox(
                  height: 200,
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Open practice'),
                  ),
                ),
              ),
              const SizedBox(height: 1500),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.startGesture(const Offset(600, 130));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('practice-paper-transform')),
          )
          .transform
          .isIdentity(),
      isFalse,
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(taps, 1);
    final dragging = await tester.startGesture(const Offset(600, 130));
    await dragging.moveBy(const Offset(0, -40));
    await dragging.moveBy(const Offset(0, -60));
    await tester.pump();
    await dragging.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(scroll.offset, greaterThan(0));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });

  testWidgets(
    'a disabled raised action cannot move or fire; enabled keeps one action',
    (tester) async {
      var taps = 0;
      Widget host(bool enabled) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: PracticeRaisedAction(
                primary: true,
                child: SoriButton.filled(
                  label: 'Continue',
                  fullWidth: true,
                  onTap: enabled ? () => taps++ : null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(taps, 0);
      expect(find.byType(PracticeMotionSurface), findsNothing);
      expect(find.byType(SoriPressable), findsNothing);
      await tester.pumpWidget(host(true));
      await tester.pump();
      final bounds = tester.getRect(find.byType(PracticeRaisedAction));
      final g = await tester.startGesture(
        tester.getCenter(find.text('Continue')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getRect(find.byType(PracticeRaisedAction)), bounds);
      expect(find.byType(SoriPressable), findsOneWidget);
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('sori-tactile-transform')),
            )
            .transform
            .isIdentity(),
        isFalse,
      );
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  testWidgets(
    'an impact rim preserves its child state and cannot replay on reduction',
    (tester) async {
      var starts = 0;
      var pulse = 0;
      var reduce = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduce),
                child: Scaffold(
                  body: PracticeMagicFrame(
                    pulse: pulse,
                    child: _LifecycleProbe(onStart: () => starts++),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      update(() => pulse++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(starts, 1);
      update(() => reduce = true);
      await tester.pump();
      update(() => pulse++);
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a reading panel stays still while its nested action responds', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: PracticeMotionSurface(
              child: SoriButton.outlined(
                label: 'Show the context',
                onTap: () => calls++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final press = await tester.startGesture(
      tester.getCenter(find.text('Show the context')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('practice-paper-transform')),
          )
          .transform
          .isIdentity(),
      isTrue,
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('sori-tactile-transform')),
          )
          .transform
          .isIdentity(),
      isFalse,
    );
    await press.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('reduced motion retains actions with no perspective transform', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: PracticeMotionSurface(
            enter: true,
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final g = await tester.startGesture(tester.getCenter(find.text('Open')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('practice-paper-transform')),
          )
          .transform
          .isIdentity(),
      isTrue,
    );
    await g.up();
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a quick tap still finishes its press before settling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeMotionSurface(
            interactive: true,
            child: SizedBox(
              height: 150,
              child: TextButton(
                onPressed: () {},
                child: const Text('Quick tap'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Quick tap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('practice-paper-transform')),
          )
          .transform
          .isIdentity(),
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('practice-paper-transform')),
          )
          .transform
          .isIdentity(),
      isTrue,
    );
  });

  testWidgets('the app motion preference also stops the nested button scale', (
    tester,
  ) async {
    await Storage.setReducedMotion(true);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: PracticeRaisedAction(
              child: SoriButton.outlined(
                label: 'A quiet hint',
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('A quiet hint')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(PracticeRaisedAction),
        matching: find.byType(Transform),
      ),
    );
    expect(transforms, isNotEmpty);
    expect(
      transforms.every((transform) => transform.transform.isIdentity()),
      isTrue,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets(
    'decorative tickers stop outside the viewport and in background',
    (tester) async {
      final scroll = ScrollController();
      bool? enabled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scroll,
              children: [
                PracticeViewportGate(
                  child: SizedBox(
                    height: 100,
                    child: Builder(
                      builder: (context) {
                        enabled = TickerMode.valuesOf(context).enabled;
                        return const Text('Motion stage');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(enabled, isTrue);
      scroll.jumpTo(300);
      await tester.pump();
      await tester.pump();
      expect(enabled, isFalse);
      scroll.jumpTo(0);
      await tester.pump();
      await tester.pump();
      expect(enabled, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump();
      expect(enabled, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
    },
  );

  testWidgets('a character frame stops even when only partly clipped', (
    tester,
  ) async {
    final scroll = ScrollController();
    bool? enabled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              PracticeViewportGate(
                requireFullVisibility: true,
                child: SizedBox(
                  height: 176,
                  child: Builder(
                    builder: (context) {
                      enabled = TickerMode.valuesOf(context).enabled;
                      return const Text('Full character');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 1500),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(enabled, isTrue);
    scroll.jumpTo(20);
    await tester.pump();
    await tester.pump();
    expect(enabled, isFalse);
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(enabled, isTrue);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({required this.onStart});
  final VoidCallback onStart;
  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 240, height: 160);
}
