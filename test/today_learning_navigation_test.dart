import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/today_learning_navigation.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  test('does nothing when a completed day has no destination', () async {
    var gateCalls = 0;
    var routeCalls = 0;

    final opened = await TodayLearningNavigation.open(
      null,
      ensurePackAccess: (_) async {
        gateCalls++;
        return true;
      },
      openRoute: (_, __) async => routeCalls++,
    );

    expect(opened, isFalse);
    expect(gateCalls, 0);
    expect(routeCalls, 0);
  });

  test(
    'opens a non-pack destination with its exact route and arguments',
    () async {
      String? route;
      Object? arguments;
      var gateCalls = 0;

      final opened = await TodayLearningNavigation.open(
        const TodayLearningDestination(
          route: '/scenario',
          arguments: 'at_cafe',
        ),
        ensurePackAccess: (_) async {
          gateCalls++;
          return true;
        },
        openRoute: (value, args) async {
          route = value;
          arguments = args;
        },
      );

      expect(opened, isTrue);
      expect(gateCalls, 0);
      expect(route, '/scenario');
      expect(arguments, 'at_cafe');
    },
  );

  test(
    'keeps Course and Review on their established routes without a gate',
    () async {
      final openedRoutes = <(String, Object?)>[];
      var gateCalls = 0;

      for (final destination in const [
        TodayLearningDestination(route: '/course/mission'),
        TodayLearningDestination(route: '/review'),
      ]) {
        final opened = await TodayLearningNavigation.open(
          destination,
          ensurePackAccess: (_) async {
            gateCalls++;
            return true;
          },
          openRoute: (route, arguments) async {
            openedRoutes.add((route, arguments));
          },
        );

        expect(opened, isTrue);
      }

      expect(gateCalls, 0);
      expect(openedRoutes, [('/course/mission', null), ('/review', null)]);
    },
  );

  test('opens a pack only after the existing access gate allows it', () async {
    final events = <String>[];

    final opened = await TodayLearningNavigation.open(
      const TodayLearningDestination(
        route: '/vocab/pack',
        arguments: 'a2_cafe',
        packAccessLevel: 'A2',
      ),
      ensurePackAccess: (level) async {
        events.add('gate:$level');
        return true;
      },
      openRoute: (route, arguments) async {
        events.add('route:$route:$arguments');
      },
    );

    expect(opened, isTrue);
    expect(events, ['gate:A2', 'route:/vocab/pack:a2_cafe']);
  });

  test(
    'does not open a pack when the existing access gate rejects it',
    () async {
      var routeCalls = 0;

      final opened = await TodayLearningNavigation.open(
        const TodayLearningDestination(
          route: '/vocab/pack',
          arguments: 'a2_cafe',
          packAccessLevel: 'A2',
        ),
        ensurePackAccess: (_) async => false,
        openRoute: (_, __) async => routeCalls++,
      );

      expect(opened, isFalse);
      expect(routeCalls, 0);
    },
  );
}
