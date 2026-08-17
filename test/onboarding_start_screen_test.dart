import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/onboarding_first_scene.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
  });

  testWidgets('shows one purpose and one start point before the first scene', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.text('What do you want to speak Korean for?'), findsOneWidget);
    expect(find.text('Open my first scene'), findsOneWidget);
    expect(_cardFor(tester, 'Getting around Korea').selected, isTrue);
    expect(_cardFor(tester, 'I am just starting').selected, isTrue);
  });

  testWidgets('changes the visible purpose without adding another CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('Talking with people'));
    await tester.pump();

    expect(_cardFor(tester, 'Talking with people').selected, isTrue);
    expect(_cardFor(tester, 'Getting around Korea').selected, isFalse);
    expect(find.text('Open my first scene'), findsOneWidget);
  });

  testWidgets(
    'opens the selected purpose scene directly without an account interruption',
    (tester) async {
      final observer = _RouteObserver();
      await tester.pumpWidget(
        _host(
          observer: observer,
          screen: OnboardingStartScreen(startNewLearner: (_) async {}),
        ),
      );

      final cta = find.text('Open my first scene');
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(observer.routeNames, contains('/scenario'));
      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);
      final player = tester.widget<ScenarioPlayerScreen>(
        find.byType(ScenarioPlayerScreen),
      );
      expect(player.mode, ScenarioPlayerMode.onboardingFirstScene);
      expect(player.courseContext, isNull);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets('each purpose resolves to its own first real-life scene', (
    tester,
  ) async {
    const cases = <String, String>{
      'Getting around Korea': 'airport_arrival',
      'Talking with people': 'introduce_yourself',
      'Study or work': 'first_class_meeting',
    };

    for (final entry in cases.entries) {
      OnboardingFirstScene? opened;
      await tester.pumpWidget(
        _host(
          screen: OnboardingStartScreen(
            startNewLearner: (_) async {},
            openFirstScene: (context, scene) async => opened = scene,
          ),
        ),
      );
      await tester.pump();
      if (entry.key != 'Getting around Korea') {
        // §G 히어로 헤더로 하단 옵션이 초기 뷰포트 밖일 수 있다.
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pump();
      }
      final cta = find.text('Open my first scene');
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pump();

      expect(opened?.scenarioId, entry.value, reason: entry.key);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('success screen opens only from the completed scene summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        screen: OnboardingStartScreen(
          initialMotivation: LearnerMotivation.loved,
          startNewLearner: (_) async {},
        ),
      ),
    );

    final cta = find.text('Open my first scene');
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final player = tester.widget<ScenarioPlayerScreen>(
      find.byType(ScenarioPlayerScreen),
    );
    final callback = player.onCompleted;
    expect(callback, isNotNull);
    await callback!(
      const ScenarioCompletionSummary(
        firstSuccess: ScenarioFirstSuccess(
          phrase: '저는 레나예요.',
          kind: ScenarioFirstSuccessKind.completion,
        ),
        passed: 7,
        total: 7,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(tester.takeException(), isNull);
    expect(find.byType(FirstVoiceSuccessScreen), findsOneWidget);
    final success = tester.widget<FirstVoiceSuccessScreen>(
      find.byType(FirstVoiceSuccessScreen),
    );
    expect(success.phrase, '저는 레나예요.');
    expect(success.canDo, 'Build your sentence');
    expect(success.completedTasks, 7);
    expect(success.totalTasks, 7);
    expect(find.text('안녕하세요.'), findsNothing);
  });
}

Widget _host({NavigatorObserver? observer, OnboardingStartScreen? screen}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      navigatorObservers: [if (observer != null) observer],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      ),
      home: screen ?? const OnboardingStartScreen(),
    );

SoriCard _cardFor(WidgetTester tester, String text) => tester.widget<SoriCard>(
  find.ancestor(of: find.text(text), matching: find.byType(SoriCard)).first,
);

class _RouteObserver extends NavigatorObserver {
  final routeNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    routeNames.add(newRoute?.settings.name);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
