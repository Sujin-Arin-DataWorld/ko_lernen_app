import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/sori_stage_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  for (final size in const <Size>[
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
  home: const AppShell(featureGate: SoriStageFeatureGate(enabled: true)),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

Widget _catalogApp({
  required Locale locale,
  required ThemeData theme,
  required bool disableAnimations,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);
