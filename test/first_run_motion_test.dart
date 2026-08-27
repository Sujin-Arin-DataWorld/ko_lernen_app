import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/motion/transitions.dart';

void main() {
  testWidgets('default transition follows the OS reduced-motion feature', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);

    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    final reduced =
        SoriTransitions.fadeScale<void>((_) => const SizedBox.shrink())
            as TransitionRoute<void>;
    expect(reduced.transitionDuration, Duration.zero);
    expect(reduced.reverseTransitionDuration, Duration.zero);

    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: false,
    );
    final normal =
        SoriTransitions.fadeScale<void>((_) => const SizedBox.shrink())
            as TransitionRoute<void>;
    expect(normal.transitionDuration, const Duration(milliseconds: 420));
    expect(normal.reverseTransitionDuration, const Duration(milliseconds: 280));
  });

  testWidgets('first-run transition is short and honors reduced motion', (
    tester,
  ) async {
    late Route<void> route;

    Future<void> pumpRoute({required bool reduceMotion}) {
      return tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              route = SoriTransitions.firstRun<void>(
                context,
                (_) => const SizedBox.shrink(),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    await pumpRoute(reduceMotion: false);
    final normalRoute = route as TransitionRoute<void>;
    expect(normalRoute.transitionDuration, const Duration(milliseconds: 220));
    expect(
      normalRoute.reverseTransitionDuration,
      const Duration(milliseconds: 200),
    );

    await pumpRoute(reduceMotion: true);
    final reducedRoute = route as TransitionRoute<void>;
    expect(reducedRoute.transitionDuration, Duration.zero);
    expect(reducedRoute.reverseTransitionDuration, Duration.zero);
  });
}
