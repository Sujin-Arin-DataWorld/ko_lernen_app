import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/module_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('module cards use the readable card type scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const Locale('en'), subtitle: 'Description'));

    expect(tester.widget<Text>(find.text('Title').first).style!.fontSize, 15);
    expect(
      tester.widget<Text>(find.text('Description').first).style!.fontSize,
      12,
    );
    expect(tester.widget<Text>(find.text('NEW')).style!.fontSize, 11);
  });

  // 2026-08-19: 글자 배율은 SoriTypeScale(MaterialApp.builder) 하나로 모았다 —
  // Title/Description 은 SoriTextTheme 을 그대로 쓰므로 fontSize 자체는 이제
  // 폭과 무관하게 고정값을 낸다(태블릿 comfort 배율은 ambient TextScaler 쪽에서
  // 적용되지, 토큰 fontSize 를 더는 부풀리지 않는다 — type_scale_test.dart 가
  // 그 배율 자체를 검증한다). NEW 배지는 `tt.label.copyWith(fontSize: 11 *
  // comfortScale)` 처럼 자체 리터럴을 쓰는 별개 경로라 이 태스크 범위 밖이고,
  // 여전히 태블릿에서 커진다.
  testWidgets('module cards keep a fixed type scale on tablets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const Locale('en'), subtitle: 'Description'));

    expect(tester.widget<Text>(find.text('Title').first).style!.fontSize, 15);
    expect(
      tester.widget<Text>(find.text('Description').first).style!.fontSize,
      12,
    );
    expect(
      tester.widget<Text>(find.text('NEW')).style!.fontSize,
      closeTo(12.1, 0.001),
    );
  });

  testWidgets('module badges use the active locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('DUE'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('NEU'), findsOneWidget);
    expect(find.text('FÄLLIG'), findsOneWidget);
  });
}

Widget _app(Locale locale, {String? subtitle}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: Scaffold(
    body: Column(
      children: [
        ModuleCard(
          icon: Icons.auto_awesome,
          title: 'Title',
          subtitle: subtitle,
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'new',
        ),
        FeaturedModuleCard(
          icon: Icons.refresh,
          title: 'Title',
          subtitle: subtitle,
          accent: SoriColors.primary,
          onTap: () {},
          ribbonType: 'due',
        ),
      ],
    ),
  ),
);
