import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/onboarding_first_scene.dart';
import 'package:ko_lernen_app/screens/onboarding_level_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/consent_invite_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart'
    show TigerStageVideo;
import 'package:ko_lernen_app/widgets/sori/card.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    ConsentInviteSheet.resetForTesting();
    // 히어로 영상과 앰비언트 입자는 위젯 테스트에서 살아 있는 타이머를 남긴다.
    TigerStageVideo.videoReady = false;
    SharedPreferences.setMockInitialValues({
      'kl_consent_accepted': true,
      // 추적 동의 시트는 별도 테스트에서 잠근다. 여기서는 레벨 화면까지의
      // 라우트 계약만 본다.
      'kl_consent_invite_shown': true,
    });
    await Storage.init();
  });

  testWidgets('shows one purpose and one start point before the first scene', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.text('What do you need Korean for?'), findsOneWidget);
    expect(find.text('Start my first scene'), findsOneWidget);
    expect(_cardFor(tester, 'Getting around Korea').selected, isTrue);
    expect(_cardFor(tester, "I'm just starting").selected, isTrue);
  });

  testWidgets('changes the visible purpose without adding another CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('Talking with people'));
    await tester.pump();

    expect(_cardFor(tester, 'Talking with people').selected, isTrue);
    expect(_cardFor(tester, 'Getting around Korea').selected, isFalse);
    expect(find.text('Start my first scene'), findsOneWidget);
  });

  testWidgets('opens level selection before the first scene', (tester) async {
    final observer = _RouteObserver();
    await tester.pumpWidget(_host(observer: observer));

    final cta = find.text('Start my first scene');
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    // SoriEntrance 의 520ms 진입 타이머까지 흘려보낸다.
    await tester.pump(const Duration(seconds: 1));

    // 2026-08-23: 레벨 선택이 필수 경로로 돌아왔다. 시작 화면은 더 이상
    // 장면을 직접 열지 않고, 배치를 끝낸 레벨 화면이 동행 선택으로 넘긴다.
    expect(find.byType(OnboardingLevelScreen), findsOneWidget);
    expect(find.byType(ScenarioPlayerScreen), findsNothing);
    expect(observer.routeNames, isNot(contains('/scenario')));
  });

  testWidgets('persists the chosen purpose for the later first scene', (
    tester,
  ) async {
    const cases = <String, String>{
      'Getting around Korea': 'airport_arrival',
      'Talking with people': 'introduce_yourself',
      'Study or work': 'first_class_meeting',
    };

    for (final entry in cases.entries) {
      Storage.resetForTesting();
      ConsentInviteSheet.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_consent_accepted': true,
        'kl_consent_invite_shown': true,
      });
      await Storage.init();
      await tester.pumpWidget(_host());
      await tester.pump();
      if (entry.key != 'Getting around Korea') {
        // §G 히어로 헤더로 하단 옵션이 초기 뷰포트 밖일 수 있다.
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pump();
      }
      final cta = find.text('Start my first scene');
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 장면은 나중에 열리므로, 시작 화면이 남겨야 하는 것은 목적 그 자체다.
      final motivation = learnerMotivationFromId(Storage.motivation);
      expect(motivation, isNotNull, reason: entry.key);
      expect(
        OnboardingFirstScene.forMotivation(motivation!).scenarioId,
        entry.value,
        reason: entry.key,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
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
      builder: (context, child) => MediaQuery(
        // 모션을 끄면 레벨 화면의 벚꽃 입자 루프가 타이머를 남기지 않는다.
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
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
