import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/today_learning_navigation.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  test('does nothing when a completed day has no destination', () async {
    var routeCalls = 0;

    final opened = await TodayLearningNavigation.open(
      null,
      openRoute: (_, __) async => routeCalls++,
    );

    expect(opened, isFalse);
    expect(routeCalls, 0);
  });

  test(
    'opens a non-pack destination with its exact route and arguments',
    () async {
      String? route;
      Object? arguments;

      final opened = await TodayLearningNavigation.open(
        const TodayLearningDestination(
          route: '/scenario',
          arguments: 'at_cafe',
        ),
        openRoute: (value, args) async {
          route = value;
          arguments = args;
        },
      );

      expect(opened, isTrue);
      expect(route, '/scenario');
      expect(arguments, 'at_cafe');
    },
  );

  test(
    'keeps Course and Review on their established routes without a gate',
    () async {
      final openedRoutes = <(String, Object?)>[];

      for (final destination in const [
        TodayLearningDestination(route: '/course/mission'),
        TodayLearningDestination(route: '/review'),
      ]) {
        final opened = await TodayLearningNavigation.open(
          destination,
          openRoute: (route, arguments) async {
            openedRoutes.add((route, arguments));
          },
        );

        expect(opened, isTrue);
      }

      expect(openedRoutes, [('/course/mission', null), ('/review', null)]);
    },
  );

  test('opens a pack directly without an access gate', () async {
    final events = <String>[];

    final opened = await TodayLearningNavigation.open(
      const TodayLearningDestination(
        route: '/vocab/pack',
        arguments: 'a2_cafe',
      ),
      openRoute: (route, arguments) async {
        events.add('route:$route:$arguments');
      },
    );

    expect(opened, isTrue);
    expect(events, ['route:/vocab/pack:a2_cafe']);
  });
}
