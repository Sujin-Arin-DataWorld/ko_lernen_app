import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  testWidgets('게이트가 즉시 열려도 최소 표시 시간(600ms) 전에는 내비게이션하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // §W2-Task6: SplashScreen 이 게이트를 넘기면 실제 라우팅 로직(Storage
        // 기반)이 다음 화면(예: ConsentScreen)을 고른다 — 그 화면이 AppL10n
        // 을 요구하므로, 브리프의 자리표시자 대신 실제 delegates/locales 를
        // 배선한다(mechanical: 브리프 작성 이후 ConsentScreen 이 L10n 을
        // 요구하게 됐다).
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: SplashScreen(
          firstRunCoordinator: FirstRunRuntime.createCoordinator(),
          readyGate: () async {},
          minDisplay: const Duration(milliseconds: 600),
          gateTimeout: const Duration(milliseconds: 1500),
        ),
        routes: {'/next': (_) => const Scaffold(body: Text('NEXT'))},
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  });

  testWidgets('게이트가 절대 안 열려도 상한(1500ms)이 지나면 내비게이션한다', (tester) async {
    final never = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: SplashScreen(
          firstRunCoordinator: FirstRunRuntime.createCoordinator(),
          readyGate: () => never.future,
          minDisplay: const Duration(milliseconds: 600),
          gateTimeout: const Duration(milliseconds: 1500),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
  });
}
