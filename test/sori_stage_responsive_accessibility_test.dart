import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  for (final size in const <Size>[
    Size(320, 640),
    Size(360, 400),
    Size(390, 844),
    Size(600, 960),
    Size(720, 1024),
    Size(1280, 900),
  ]) {
    testWidgets('Sori Stage shell has no layout exception at ${size.width}dp', (
      tester,
    ) async {
      _setViewport(tester, size);
      await tester.pumpWidget(_shellApp(textScale: 1));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Profile'), findsOneWidget);
      final profileSize = tester.getSize(find.byTooltip('Profile'));
      expect(profileSize.width, greaterThanOrEqualTo(48));
      expect(profileSize.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('390dp shell remains usable at 200 percent text', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(_shellApp(textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Gye'), findsWidgets);
  });

  for (final fixture in <({Locale locale, ThemeData theme, String name})>[
    (locale: const Locale('de'), theme: AppTheme.light, name: 'DE light'),
    (locale: const Locale('en'), theme: AppTheme.dark, name: 'EN dark'),
  ]) {
    testWidgets('${fixture.name} catalog supports reduced motion', (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _catalogApp(
          locale: fixture.locale,
          theme: fixture.theme,
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
      expect(
        find.byTooltip(
          fixture.locale.languageCode == 'de' ? 'Profil' : 'Profile',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('catalog meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _catalogApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  // §C-3b: 1280dp에서 카탈로그 오버플로가 재발하지 않는지 검증.
  // §C-1-4 수리 전에는 soriGridColumns가 클램프 전 전체 폭(1280)을 받아
  // 880px 안에 6열 → 18px 오버플로가 발생했다.
  testWidgets('1280dp catalog does not overflow (regression §C-1-4)', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));
    await tester.pumpWidget(
      _catalogApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
  });

  for (final size in const <Size>[
    Size(320, 640),
    Size(390, 844),
    Size(720, 1024),
    Size(1280, 900),
  ]) {
    for (final textScale in const <double>[1, 1.3, 1.6, 2]) {
      testWidgets('catalog fits ${size.width}dp at ${textScale}x text', (
        tester,
      ) async {
        _setViewport(tester, size);
        await tester.pumpWidget(
          _catalogApp(
            locale: const Locale('de'),
            theme: AppTheme.light,
            disableAnimations: true,
            textScale: textScale,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
      });
    }
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _shellApp({required double textScale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: const AppShell(),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

Widget _catalogApp({
  required Locale locale,
  required ThemeData theme,
  required bool disableAnimations,
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: disableAnimations,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);
