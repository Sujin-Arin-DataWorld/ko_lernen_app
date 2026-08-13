import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/sori_stage_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  test('Sori Stage feature is default-off with an explicit opt-in seam', () {
    expect(const SoriStageFeatureGate().isEnabled, isFalse);
    expect(const SoriStageFeatureGate(enabled: true).isEnabled, isTrue);
  });

  // 기본값이 레거시 셸을 고른다는 사실은 위 게이트 계약 테스트와
  // screen_smoke_test.dart 의 'app shell renders' 가 함께 커버한다. 레거시 홈은
  // reduce-motion 에도 멈추지 않는 앰비언트 애니메이션이 있어 여기서 셸 전체를
  // 마운트하면 pumpAndSettle 이 타임아웃한다.


  testWidgets('390dp shell exposes five roots and profile outside navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(const AppShell(featureGate: SoriStageFeatureGate(enabled: true))),
    );
    await tester.pump();

    expect(find.byType(SoriStageShell), findsOneWidget);
    for (final label in const ['Today', 'Learn', 'Games', 'Hanok', 'Gye']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.byTooltip('Profile'), findsOneWidget);
  });

  testWidgets('720dp shell uses a rail and keeps all touch targets at 48dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(const AppShell(featureGate: SoriStageFeatureGate(enabled: true))),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    final profile = tester.getSize(find.byTooltip('Profile'));
    expect(profile.width, greaterThanOrEqualTo(48));
    expect(profile.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tutorial replay returns the new shell to Today', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(const AppShell(featureGate: SoriStageFeatureGate(enabled: true))),
    );
    await tester.pump();
    await tester.tap(find.text('Games').last);
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    AppShell.replayHomeTour.value++;
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);
