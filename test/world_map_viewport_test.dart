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
            zonePurpose: _purpose,
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

  testWidgets('03B keeps completed place names and purposes visible on map', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 390,
          child: WorldMapViewport(
            projection: _completeProjection,
            selectedZone: PersonalHanokZone.sarangbang,
            onSelectZone: (_) {},
            onOpenSelectedZone: () {},
            zoneLabel: _label,
            zonePurpose: _purpose,
            mapPlaceLabel: _mapLabel,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );

    for (final zone in const [
      PersonalHanokZone.sarangbang,
      PersonalHanokZone.daecheongmaru,
      PersonalHanokZone.anchae,
      PersonalHanokZone.huwon,
    ]) {
      expect(
        find.byKey(ValueKey('personal-hanok-map-label-${zone.name}')),
        findsOneWidget,
      );
      expect(find.text(_mapLabel(zone)), findsOneWidget);
    }
  });

  testWidgets('03B describes the selected today scene with time and sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 390,
          child: WorldMapViewport(
            projection: _completeProjection,
            selectedZone: PersonalHanokZone.sarangbang,
            onSelectZone: (_) {},
            onOpenSelectedZone: () {},
            zoneLabel: _label,
            zonePurpose: _purpose,
            mapPlaceLabel: _mapLabel,
            todayExpressionKo: '안 맵게 해 주세요.',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );

    expect(find.text('4 minutes · say “안 맵게 해 주세요.”'), findsOneWidget);
    expect(find.text('Go there'), findsOneWidget);
  });
}

final _completeProjection = PersonalHanokProjection.from(
  const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
);

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

String _purpose(PersonalHanokZone zone) => 'Purpose: ${zone.name}';

String _mapLabel(PersonalHanokZone zone) => 'Map purpose: ${zone.name}';
