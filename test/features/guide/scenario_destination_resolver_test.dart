import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/learner_level.dart';

void main() {
  testWidgets('valid typed scenario destination is forwarded and accepted', (
    tester,
  ) async {
    const destination = ScenarioBrowseDestination(
      level: LearnerLevel.b1,
      shelfId: 'b1_team',
    );
    Object? receivedArguments;

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: SizedBox(key: ValueKey('resolver-anchor'))),
        onGenerateRoute: (settings) {
          if (settings.name != '/scenarios') {
            return null;
          }
          receivedArguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                const Scaffold(body: SizedBox(key: ValueKey('scenario-route'))),
          );
        },
      ),
    );
    final context = tester.element(
      find.byKey(const ValueKey('resolver-anchor')),
    );

    final opened = GuideDestinationResolver.openScenarioCategory(
      context,
      destination,
    );
    await tester.pumpAndSettle();

    expect(receivedArguments, same(destination));
    expect(find.byKey(const ValueKey('scenario-route')), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('scenario-route'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(await opened, isTrue);
  });

  testWidgets('invalid typed scenario destination is rejected before routing', (
    tester,
  ) async {
    var routeRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: SizedBox(key: ValueKey('resolver-anchor'))),
        onGenerateRoute: (settings) {
          routeRequested = true;
          return null;
        },
      ),
    );
    final context = tester.element(
      find.byKey(const ValueKey('resolver-anchor')),
    );

    final result = await GuideDestinationResolver.resolve(
      context,
      _topic(
        const ScenarioBrowseDestination(
          level: LearnerLevel.b1,
          shelfId: 'a1_eat',
        ),
      ),
    );

    expect(result.didOpen, isFalse);
    expect(result.failureReason, GuideRoutingFailureReason.invalidDestination);
    expect(routeRequested, isFalse);
  });

  testWidgets('same-level but non-catalog shelf is rejected before routing', (
    tester,
  ) async {
    var routeRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: SizedBox(key: ValueKey('resolver-anchor'))),
        onGenerateRoute: (settings) {
          routeRequested = true;
          return null;
        },
      ),
    );
    final context = tester.element(
      find.byKey(const ValueKey('resolver-anchor')),
    );

    final result = await GuideDestinationResolver.resolveScenarioCategory(
      context,
      const ScenarioBrowseDestination(
        level: LearnerLevel.b1,
        shelfId: 'b1_guessed',
      ),
    );

    expect(result.didOpen, isFalse);
    expect(result.failureReason, GuideRoutingFailureReason.invalidDestination);
    expect(routeRequested, isFalse);
  });

  testWidgets(
    'caught scenario navigation error returns only navigation reason',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: SizedBox(key: ValueKey('resolver-anchor')),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/scenarios') {
              throw StateError('sensitive route failure detail');
            }
            return null;
          },
        ),
      );
      final context = tester.element(
        find.byKey(const ValueKey('resolver-anchor')),
      );

      final result = await GuideDestinationResolver.resolveScenarioCategory(
        context,
        const ScenarioBrowseDestination(
          level: LearnerLevel.b1,
          shelfId: 'b1_team',
        ),
      );

      expect(result.didOpen, isFalse);
      expect(result.failureReason, GuideRoutingFailureReason.navigation);
      expect(tester.takeException(), isNull);
    },
  );
}

GuideTopicSpec _topic(ScenarioBrowseDestination destination) => GuideTopicSpec(
  id: GuideTopicId.learn,
  localizationKey: 'guideTopicLearn',
  destination: destination,
  availability: FeatureAvailability.live,
  requiredConsents: const {},
  requiredPermissions: const {},
  surfaces: const {GuideSurface.guideHub},
  completionMode: GuideCompletionMode.destinationOpened,
  analyticsSurface: GuideAnalyticsSurface.learn,
);
