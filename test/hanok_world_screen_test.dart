import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/widgets/sori/madang_background.dart';

void main() {
  test('canonical completed room zones open their own interiors', () {
    expect(hanokRouteForZone(PersonalHanokZone.anchae), '/hanok/anbang');
    expect(
      hanokRouteForZone(PersonalHanokZone.daecheongmaru),
      '/hanok/daecheong',
    );
  });

  testWidgets('keeps the legacy courtyard before the estate gate opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: .24, b2: 1),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MadangBackground), findsOneWidget);
    expect(
      find.byKey(const ValueKey('personal-hanok-zone-sarangbang')),
      findsNothing,
    );
  });

  testWidgets('opens the exact completed estate zone supplied by the map', (
    tester,
  ) async {
    PersonalHanokZone? opened;
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          onOpenZone: (zone) => opened = zone,
        ),
      ),
    );
    await tester.pump();

    final sarangbang = find.byKey(
      const ValueKey('personal-hanok-zone-sarangbang'),
    );
    expect(sarangbang, findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(sarangbang);

    expect(opened, PersonalHanokZone.sarangbang);
  });

  testWidgets(
    'keeps the Gye road noninteractive and uses the separate shared-courtyard bridge',
    (tester) async {
      String? openedRoute;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          onGenerateRoute: (settings) {
            openedRoute = settings.name;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: SizedBox()),
            );
          },
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: HanokWorldScreen(
              loadRatios: () async =>
                  const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(hanokRouteForZone(PersonalHanokZone.gyeRoad), isNull);
      final bridge = find.byKey(const ValueKey('hanok-world-gye-bridge'));
      await tester.scrollUntilVisible(bridge, 280);
      await tester.ensureVisible(bridge);
      await tester.pumpAndSettle();
      expect(bridge, findsOneWidget);

      await tester.tap(bridge);
      await tester.pumpAndSettle();

      expect(openedRoute, '/gye/hub');
    },
  );

  testWidgets('offers every finished place through an accessible place list', (
    tester,
  ) async {
    PersonalHanokZone? opened;
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          onOpenZone: (zone) => opened = zone,
        ),
      ),
    );
    await tester.pump();

    final daecheong = find.byKey(
      const ValueKey('hanok-world-place-daecheongmaru'),
    );
    await tester.scrollUntilVisible(daecheong, 280);
    expect(daecheong, findsOneWidget);

    await tester.tap(daecheong);

    expect(opened, PersonalHanokZone.daecheongmaru);
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
