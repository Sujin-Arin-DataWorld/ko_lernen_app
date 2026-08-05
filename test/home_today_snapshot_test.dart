import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('renders the injected shared today snapshot on Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HomeScreen(
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const ReviewPick(dueCount: 12),
            dueCount: 12,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review 12 words'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('puts one Sarangbang study action before the Hanok preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedRoute;
    await tester.pumpWidget(
      _host(
        HomeScreen(
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const ReviewPick(dueCount: 12),
            dueCount: 12,
          ),
          loadHanokRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final primary = find.byKey(const ValueKey('home-primary-sarangbang'));
    final preview = find.byKey(const ValueKey('home-hanok-preview'));
    expect(primary, findsOneWidget);
    expect(preview, findsOneWidget);
    expect(
      tester.getTopLeft(primary).dy,
      lessThan(tester.getTopLeft(preview).dy),
    );
    expect(find.text('Study in the Sarangbang'), findsOneWidget);

    await tester.tap(find.text('Study in the Sarangbang'));
    await tester.pumpAndSettle();
    expect(openedRoute, '/sarangbang');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

Widget _host(Widget child, {RouteFactory? onGenerateRoute}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateRoute: onGenerateRoute,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
