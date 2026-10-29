import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/intro_motion.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  testWidgets('contact translates one face without moving its input bounds', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        IntroPressable(
          key: const ValueKey('action'),
          onTap: () => taps++,
          child: const SizedBox(width: 180, height: 58),
        ),
      ),
    );
    final action = find.byKey(const ValueKey('action'));
    final before = tester.getRect(action);
    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump();
    await tester.pump(IntroMotion.press);
    expect(tester.getRect(action), before);
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('sori-press-offset-transform')),
    );
    expect(transform.transform.getTranslation().y, closeTo(1.5, .001));
    expect(transform.transform.entry(0, 0), closeTo(.995, .0001));
    await gesture.up();
    expect(taps, 1, reason: 'Feedback must never delay the real action.');
    await tester.pump();
    await tester.pump(IntroMotion.release);
    expect(_offset(tester), 0);
    expect(tester.getRect(action), before);

    final cancelled = await tester.startGesture(tester.getCenter(action));
    await tester.pump();
    await tester.pump(IntroMotion.press);
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_offset(tester), 0);
  });

  testWidgets('reduced motion cancels contact and keeps keyboard activation', (
    tester,
  ) async {
    var taps = 0;
    Widget action() => IntroPressable(
      key: const ValueKey('action'),
      onTap: () => taps++,
      child: const SizedBox(width: 180, height: 58),
    );
    await tester.pumpWidget(_app(action()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('action'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_offset(tester), greaterThan(0));
    await tester.pumpWidget(_app(action(), reduced: true));
    expect(_offset(tester), 0);
    await gesture.cancel();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_offset(tester), 0);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('translation can be enabled without scaling the face', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SoriPressable(
          pressScale: 1,
          pressOffsetY: 1.5,
          onTap: () {},
          haptic: null,
          child: const SizedBox(width: 180, height: 58),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SoriPressable)),
    );
    await tester.pumpAndSettle();
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('sori-press-offset-transform')),
    );
    expect(transform.transform.entry(0, 0), 1);
    expect(_offset(tester), 1.5);
    await gesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('selection only reveals the existing check within fixed bounds', (
    tester,
  ) async {
    Widget badge(bool selected) => IntroSelectionMotion(
      selected: selected,
      child: const SizedBox(width: 46, height: 46, child: Text('check')),
    );
    await tester.pumpWidget(_app(badge(false)));
    final bounds = tester.getRect(find.byType(IntroSelectionMotion));
    await tester.pumpWidget(_app(badge(true)));
    await tester.pump(const Duration(milliseconds: 90));
    final opacity = tester.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(opacity, inExclusiveRange(0, 1));
    expect(tester.getRect(find.byType(IntroSelectionMotion)), bounds);
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pumpWidget(_app(badge(false), reduced: true));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'scene changes dispose old media and draft updates keep identity',
    (tester) async {
      var disposed = 0;
      Widget scene(String id, {bool reduced = false}) => _app(
        IntroSceneTransition(
          sceneId: id,
          child: _TrackedScene(key: ValueKey(id), onDispose: () => disposed++),
        ),
        reduced: reduced,
      );
      await tester.pumpWidget(scene('sound'));
      await tester.pumpWidget(scene('companion'));
      expect(disposed, 1, reason: 'No outgoing audio subtree may linger.');
      expect(find.byType(_TrackedScene), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 80));
      final halfway = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(halfway, inExclusiveRange(0, 1));
      final state = tester.state(find.byType(_TrackedScene));
      await tester.pumpWidget(scene('companion'));
      expect(tester.state(find.byType(_TrackedScene)), same(state));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, halfway);
      await tester.pumpWidget(scene('companion', reduced: true));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      expect(tester.state(find.byType(_TrackedScene)), same(state));
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('background and inactive routes settle finite scene motion', (
    tester,
  ) async {
    Widget scene(int id, {bool active = true}) => _app(
      TickerMode(
        enabled: active,
        child: IntroSceneTransition(
          sceneId: id,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.pumpWidget(scene(1));
    await tester.pumpWidget(scene(2));
    await tester.pump(const Duration(milliseconds: 40));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(scene(3));
    await tester.pumpWidget(scene(3, active: false));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

double _offset(WidgetTester tester) => tester
    .widget<Transform>(
      find.byKey(const ValueKey('sori-press-offset-transform')),
    )
    .transform
    .getTranslation()
    .y;

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

class _TrackedScene extends StatefulWidget {
  const _TrackedScene({super.key, required this.onDispose});
  final VoidCallback onDispose;

  @override
  State<_TrackedScene> createState() => _TrackedSceneState();
}

class _TrackedSceneState extends State<_TrackedScene> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 100, height: 100);
}
