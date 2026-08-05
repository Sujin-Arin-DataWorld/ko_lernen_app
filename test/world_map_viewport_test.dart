import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';
import 'package:ko_lernen_app/widgets/sori/world_map_viewport.dart';

void main() {
  testWidgets('uses a side detail panel at the tablet breakpoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 720,
          child: WorldMapViewport(
            projection: PersonalHanokProjection.from(
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
            ),
            selectedZone: PersonalHanokZone.sarangbang,
            onSelectZone: (_) {},
            onOpenSelectedZone: () {},
            zoneLabel: _label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );

    final map = find.byType(PersonalHanokMap);
    final panel = find.byKey(const ValueKey('hanok-world-selection-panel'));
    expect(map, findsOneWidget);
    expect(panel, findsOneWidget);
    expect(tester.getTopLeft(panel).dy, tester.getTopLeft(map).dy);
    expect(tester.getTopLeft(panel).dx, greaterThan(tester.getTopLeft(map).dx));
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Scaffold(body: child),
  ),
);

String _label(PersonalHanokZone zone) => zone.name;
