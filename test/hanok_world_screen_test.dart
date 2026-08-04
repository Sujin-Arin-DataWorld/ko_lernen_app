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
