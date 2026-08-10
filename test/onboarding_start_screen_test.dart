import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
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
    'opens the first mission directly without an account interruption',
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
      await tester.pumpAndSettle();

      expect(observer.routeNames, contains('/course/mission'));
      expect(find.byType(BottomSheet), findsNothing);
    },
  );
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
