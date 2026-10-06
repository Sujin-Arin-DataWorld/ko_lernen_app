import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/screens/sori_stage/c_stage_chrome.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_objects.dart';

import 'support/real_fonts.dart';
import 'support/c_fonts.dart';

// Compact root prioritizes a real group goal or the optional entry action.
const _bottomTabReserve = 80.0;
const _viewportSize = Size(390, 844);

void main() {
  late CulturalGlossary glossary;

  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await loadCFonts();
  });
  setUpAll(() async {
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_gye_tab': true,
    });
    await Storage.init();
    // §W-J2: `CulturalHelpButton` gates on `CulturalGlossaryRepository.load()`
    // (a real rootBundle JSON read cached process-wide) — inject a
    // synchronous-after-one-await catalog so its `?` button resolves on
    // schedule instead of depending on incidental cache-warming order from
    // whichever test happens to run first.
    CulturalGlossaryRepository.setLoaderForTesting(() async => glossary);
  });

  tearDown(CulturalGlossaryRepository.resetForTesting);

  Widget app({
    double textScale = 1,
    Future<List<GyeMeta>> Function()? loadGyeMetas,
  }) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // §W-G: `GyeHanok`'s pulse animation repeats forever
        // (`AnimationController.repeat(reverse: true)`) when motion is not
        // reduced — this test never needs that decoration and it would
        // make `pumpAndSettle()` time out, so every fixture disables
        // animations up front instead of chasing bounded `pump()` counts
        // per test.
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: SoriStageGyeScreen(loadGyeMetas: loadGyeMetas),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = _viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'C empty state: native header, approved scene and join CTA fit at 390x844',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(app(loadGyeMetas: () async => const []));
      await settle(tester);

      final t = await AppL10n.delegate.load(const Locale('de'));
      final fold = _viewportSize.height - _bottomTabReserve;

      final header = find.byType(CStageHeader);
      final poster = find.byType(CSceneArt);
      final cta = find.byKey(const ValueKey('gye-empty-start'));

      expect(header, findsOneWidget);
      expect(poster, findsOneWidget);
      expect(cta, findsOneWidget, reason: 'CTA는 스크롤 없이 첫 화면에서 빌드돼야 한다');
      expect(find.text(t.gyeMembersN(4)), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('c-gye-board')),
          matching: cta,
        ),
        findsOneWidget,
      );

      for (final finder in [header, poster, cta]) {
        final rect = tester.getRect(finder);
        expect(
          rect.bottom,
          lessThanOrEqualTo(fold),
          reason: '$finder bottom ${rect.bottom} exceeds the fold $fold',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C actual group: native name, actual member count and lit lanterns share one board',
    (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        app(
          loadGyeMetas: () async => const [
            GyeMeta(
              id: 'g1',
              name: 'Unser Hanok',
              code: 'ABC123',
              ownerId: 'u1',
              memberCount: 3,
              // §W-G2 item 1: 이번 주 목표를 완주한 계 — 스텝퍼가 이 데이터를
              // 보고 step 1(등불 획득)을 가리켜야 한다
              // (`GyeLanternProgress.currentStepFor`).
              weeklyGoalPacks: 5,
              weeklyGoalProgress: 5,
            ),
          ],
        ),
      );
      await settle(tester);

      final fold = _viewportSize.height - _bottomTabReserve;

      final header = find.byType(CStageHeader);
      final firstCard = find.byKey(const ValueKey('gye-card-g1'));

      expect(header, findsOneWidget);
      expect(
        firstCard,
        findsOneWidget,
        reason: '첫 계 카드는 스크롤 없이 첫 화면에서 빌드돼야 한다',
      );

      for (final finder in [header]) {
        final rect = tester.getRect(finder);
        expect(
          rect.bottom,
          lessThanOrEqualTo(fold),
          reason: '$finder bottom ${rect.bottom} exceeds the fold $fold',
        );
      }
      final cardRect = tester.getRect(firstCard);
      expect(
        cardRect.top,
        lessThanOrEqualTo(fold - 24),
        reason:
            'first gye card top ${cardRect.top} does not peek 24dp into '
            'the fold $fold',
      );

      expect(find.text('5 / 5'), findsOneWidget);
      final t = AppL10n.of(tester.element(firstCard));
      expect(find.text(t.gyeMembersN(3)), findsOneWidget);
      expect(find.text(t.gyeMembersN(4)), findsNothing);
      expect(
        tester
            .widgetList<CLantern>(find.byType(CLantern))
            .every((lamp) => lamp.lit),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'C group board scrolls as one surface and retains all actual groups and actions',
    (tester) async {
      setViewport(tester);
      // 계 1개는 390×844에서 이미 스크롤 없이 다 들어간다(위 "1 gye" 테스트
      // 실측) — `maxScrollExtent`가 0이면 600dp 드래그도 아무것도 움직이지
      // 않는다. 실제로 스크롤할 여지를 만들기 위해 계 5개로 콘텐츠를
      // 늘린다(접힘 동작 자체를 검증하는 목적이지 목록 길이는 무관).
      await tester.pumpWidget(
        app(
          loadGyeMetas: () async => List<GyeMeta>.generate(
            5,
            (i) => GyeMeta(
              id: 'g$i',
              name: 'Unser Hanok $i',
              code: 'ABC12$i',
              ownerId: 'u1',
              memberCount: 3,
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final board = find.byKey(const ValueKey('c-gye-board'));
      expect(board, findsOneWidget);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        greaterThan(0),
      );
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('gye-card-g$i')), findsOneWidget);
      }
      final join = find.byKey(const ValueKey('gye-empty-start'));
      await tester.ensureVisible(join);
      await tester.pumpAndSettle();
      expect(join.hitTestable(), findsOneWidget);
      expect(
        find.descendant(of: board, matching: find.byType(CMaterialAction)),
        findsNWidgets(7),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C group actions remain reachable at textScale 2', (
    tester,
  ) async {
    setViewport(tester);
    await tester.pumpWidget(
      app(textScale: 2, loadGyeMetas: () async => const []),
    );
    await settle(tester);

    expect(find.byType(CSceneArt), findsOneWidget);
    final action = find.byKey(const ValueKey('gye-empty-start'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
