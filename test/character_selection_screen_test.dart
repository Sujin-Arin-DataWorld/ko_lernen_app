import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

/// 캐릭터 선택 화면 (2026-08-03 일월 무대 리디자인) 스모크.
///
/// 테스트 기본값은 `TigerStageVideo.videoReady == false` → 클립은 정적
/// 폴백 + `fallbackCompleteAfter` 워치독 경로. Mascot `animate: true`는
/// 무한 호흡 애니메이션이라 `pumpAndSettle` 금지 — 유한 `pump`만 쓴다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
  });

  Widget wrap() => const MaterialApp(
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    locale: Locale('de'),
    home: CharacterSelectionScreen(),
  );

  testWidgets('이름·로마자·특성·설명·탭 힌트가 모두 렌더된다', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 900));

    // 이름(한글) — Text.rich 이름줄에만 존재. 로마자(Taego/Joy)는 이름줄과
    // 설명 양쪽에 나올 수 있어 findsWidgets 로 존재만 확인.
    expect(find.textContaining('태고', findRichText: true), findsOneWidget);
    expect(find.textContaining('조이', findRichText: true), findsOneWidget);
    expect(find.textContaining('Taego', findRichText: true), findsWidgets);
    expect(find.textContaining('Joy', findRichText: true), findsWidgets);
    expect(find.text('Verlässlich & mutig'), findsOneWidget);
    expect(find.text('Fröhlich & lebendig'), findsOneWidget);
    // 민속 상징 설명 — 산군(호랑이)·길조(까치).
    expect(find.textContaining('Herr der Berge'), findsOneWidget);
    expect(find.textContaining('Glücksbotin'), findsOneWidget);
    expect(find.text('Tipp deinen Lernfreund an'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('좁은 폭 308px × 글자배율 1.3 에서 오버플로 없음', (tester) async {
    tester.view.physicalSize = const Size(308, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: wrap(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('호랑이 탭 → 정적 확정 화면 → 동의 화면으로 진행', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.textContaining('태고', findRichText: true));
    await tester.pump();

    // 선택 확정 — 영상 대신 정적 대형 마스코트 + 볼드 녹청 캡션.
    // 카드/제목은 걷히고 확정 연출만 남는다.
    expect(find.text('태고가 선택되었습니다.'), findsOneWidget);
    expect(find.text('Tipp deinen Lernfreund an'), findsNothing);

    // _advanceGuard 2400ms 타이머 → 미동의라 ConsentScreen 으로.
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ConsentScreen), findsOneWidget);

    // 화면 해제 — 남은 타이머·애니메이션 정리.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional companion choice can be skipped without a level flow', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: CharacterSelectionScreen(
          optional: true,
          onOptionalComplete: () => completed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Not now'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('companion-option-magpie')));
    await tester.pump();
    expect(find.text('Joy will learn with you.'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pump();

    expect(completed, isTrue);
    expect(Storage.introPreviewSeen, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('kl_preferred_mascot'), isFalse);
    expect(find.byType(ConsentScreen), findsNothing);
  });

  testWidgets('01D keeps both choices visible and confirms the final choice', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: CharacterSelectionScreen(
          optional: true,
          onOptionalComplete: () => completed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    final continueButton = find.byKey(
      const ValueKey('companion-selection-continue'),
    );
    expect(tester.widget<SoriButton>(continueButton).onTap, isNull);

    await tester.tap(find.byKey(const ValueKey('companion-option-tiger')));
    await tester.pump();

    expect(completed, isFalse);
    expect(find.text('Taego will learn with you.'), findsOneWidget);
    expect(tester.widget<SoriButton>(continueButton).onTap, isNotNull);
    expect(
      find.byKey(const ValueKey('companion-option-magpie')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('companion-option-magpie')));
    await tester.pump();

    var preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('kl_preferred_mascot'), isFalse);
    expect(find.text('Joy will learn with you.'), findsOneWidget);
    expect(find.text('Taego will learn with you.'), findsNothing);

    await tester.tap(continueButton);
    await tester.pump();

    expect(completed, isTrue);
    expect(Storage.introPreviewSeen, isTrue);
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_preferred_mascot'), 'magpie');
    expect(tester.takeException(), isNull);
  });

  testWidgets('01D exposes semantic tap actions and selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: Locale('en'),
        home: CharacterSelectionScreen(optional: true),
      ),
    );
    await tester.pump();

    final tiger = find.byKey(const ValueKey('companion-option-tiger'));
    var data = tester.getSemantics(tiger).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isFalse);

    await tester.tap(tiger);
    await tester.pump();

    data = tester.getSemantics(tiger).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });
}
