import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/module_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets('module cards use the readable card type scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const Locale('en'), subtitle: 'Description'));

    expect(tester.widget<Text>(find.text('Title').first).style!.fontSize, 17);
    expect(
      tester.widget<Text>(find.text('Description').first).style!.fontSize,
      13.5,
    );
    expect(tester.widget<Text>(find.text('NEW')).style!.fontSize, 13);
  });

  // 2026-08-19: 글자 배율은 SoriTypeScale(MaterialApp.builder) 하나로 모았다 —
  // Title/Description 은 SoriTextTheme 을 그대로 쓰므로 fontSize 자체는 이제
  // 폭과 무관하게 고정값을 낸다(태블릿 comfort 배율은 ambient TextScaler 쪽에서
  // 적용되지, 토큰 fontSize 를 더는 부풀리지 않는다 — type_scale_test.dart 가
  // 그 배율 자체를 검증한다). NEW 배지도 리뷰 라운드 1에서 자체
  // `fontSize: 11 * comfortScale` 리터럴을 제거했으므로 이제 같은 규칙을
  // 따른다 — fontSize 는 항상 13 그대로다(2026-09-03 §A5: 11→13 하한 교체).
  testWidgets('module cards keep a fixed type scale on tablets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const Locale('en'), subtitle: 'Description'));

    expect(tester.widget<Text>(find.text('Title').first).style!.fontSize, 17);
    expect(
      tester.widget<Text>(find.text('Description').first).style!.fontSize,
      13.5,
    );
    expect(tester.widget<Text>(find.text('NEW')).style!.fontSize, 13);
  });

  // 리뷰 라운드 1: fontSize 리터럴이 고정이라는 것만으로는 "이중 배율 없음"을
  // 증명하지 못한다 — 실제 앱처럼 SoriTypeScale 을 builder 에 설치한 채로
  // pump 해서, TextStyle.fontSize 는 13 그대로이고 ambient TextScaler 만
  // comfort(태블릿 800dp → ×1.10)를 곱하는 것을 함께 확인한다.
  testWidgets(
    'NEW badge fontSize stays 13 under the real SoriTypeScale builder — comfort only scales the ambient TextScaler',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(const Locale('en'), withTypeScale: true));

      final badgeContext = tester.element(find.text('NEW'));
      final ambientScale = MediaQuery.textScalerOf(badgeContext).scale(13);

      expect(tester.widget<Text>(find.text('NEW')).style!.fontSize, 13);
      expect(ambientScale, closeTo(13 * 1.10, 0.001));
    },
  );

  testWidgets('module badges use the active locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('DUE'), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('NEU'), findsOneWidget);
    expect(find.text('FÄLLIG'), findsOneWidget);
  });

  testWidgets('featured module copy stacks without ellipsis at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title = 'Aussprache und Hörverständnis gemeinsam trainieren';
    const subtitle =
        'Vergleiche vollständige koreanische Beispielsätze in deinem Tempo.';
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 2,
              maxScaleFactor: 2,
              child: SingleChildScrollView(
                child: FeaturedModuleCard(
                  key: const Key('featured-module'),
                  icon: Icons.hearing_rounded,
                  title: title,
                  subtitle: subtitle,
                  accent: SoriColors.primary,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(title)).overflow, isNull);
    expect(tester.widget<Text>(find.text(subtitle)).overflow, isNull);
    await tester.ensureVisible(find.byKey(const Key('featured-module')));
    await tester.tap(find.byKey(const Key('featured-module')));
    expect(tapped, isTrue);
  });
}

Widget _app(Locale locale, {String? subtitle, bool withTypeScale = false}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: withTypeScale
          ? (context, child) => SoriTypeScale(child: child!)
          : null,
      home: _AppHome(subtitle: subtitle),
    );

class _AppHome extends StatelessWidget {
  const _AppHome({this.subtitle});
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
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
  );
}
