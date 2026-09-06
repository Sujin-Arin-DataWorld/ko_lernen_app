import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/widgets/sori/madang_background.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';

void main() {
  testWidgets('uses the legacy courtyard before the compound boundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: .249, b2: 1),
          ),
          zoneLabel: _label,
        ),
      ),
    );

    expect(find.byType(MadangBackground), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-hanok-zone-sarangbang')), findsNothing);
  });

  testWidgets('shows final map targets at the full construction milestone', (
    tester,
  ) async {
    PersonalHanokZone? tapped;
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          ),
          zoneLabel: _label,
          onTapZone: (zone) => tapped = zone,
        ),
      ),
    );

    final sarangbang = find.byKey(
      const ValueKey('personal-hanok-zone-sarangbang'),
    );
    expect(sarangbang, findsOneWidget);
    expect(find.byKey(const ValueKey('personal-hanok-zone-huwon')), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-hanok-zone-gyeRoad')), findsNothing);
    final size = tester.getSize(sarangbang);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));

    await tester.tap(sarangbang);
    expect(tapped, PersonalHanokZone.sarangbang);
  });

  testWidgets('does not expose a building before its own milestone', (tester) async {
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .49),
          ),
          zoneLabel: _label,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('personal-hanok-zone-sarangbang')), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-hanok-zone-anchae')), findsOneWidget);
    expect(find.byKey(const ValueKey('personal-hanok-zone-daecheongmaru')), findsNothing);
    expect(find.byKey(const ValueKey('personal-hanok-zone-sadang')), findsNothing);
  });

  testWidgets('opens the Daecheongmaru target without the Anchae stealing it', (
    tester,
  ) async {
    PersonalHanokZone? tapped;
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: .5),
          ),
          zoneLabel: _label,
          onTapZone: (zone) => tapped = zone,
        ),
      ),
    );

    final daecheong = find.byKey(
      const ValueKey('personal-hanok-zone-daecheongmaru'),
    );
    expect(daecheong, findsOneWidget);

    await tester.tap(daecheong);

    expect(tapped, PersonalHanokZone.daecheongmaru);
  });

  testWidgets('keeps effective 44dp targets disjoint at the compact width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: PersonalHanokProjection.from(
            const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          ),
          zoneLabel: _label,
        ),
        width: 308,
        height: 231,
      ),
    );

    final targets = <({PersonalHanokZone zone, Finder finder})>[
      (
        zone: PersonalHanokZone.sarangbang,
        finder: find.byKey(const ValueKey('personal-hanok-zone-sarangbang')),
      ),
      (
        zone: PersonalHanokZone.daecheongmaru,
        finder: find.byKey(const ValueKey('personal-hanok-zone-daecheongmaru')),
      ),
      (
        zone: PersonalHanokZone.haengrangchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-haengrangchae')),
      ),
      (
        zone: PersonalHanokZone.anchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-anchae')),
      ),
      (
        zone: PersonalHanokZone.anchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-anchae-1')),
      ),
      (
        zone: PersonalHanokZone.huwon,
        finder: find.byKey(const ValueKey('personal-hanok-zone-huwon')),
      ),
      (
        zone: PersonalHanokZone.huwon,
        finder: find.byKey(const ValueKey('personal-hanok-zone-huwon-1')),
      ),
      (
        zone: PersonalHanokZone.sadang,
        finder: find.byKey(const ValueKey('personal-hanok-zone-sadang')),
      ),
    ];

    for (var first = 0; first < targets.length; first++) {
      expect(targets[first].finder, findsOneWidget);
      final firstRect = tester.getRect(targets[first].finder);
      for (var second = first + 1; second < targets.length; second++) {
        if (targets[first].zone == targets[second].zone) {
          continue;
        }
        expect(
          firstRect.overlaps(tester.getRect(targets[second].finder)),
          isFalse,
          reason: 'effective touch target $first overlaps $second',
        );
      }
    }
  });
}

Widget _host(Widget child, {double width = 360, double height = 270}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

String _label(PersonalHanokZone zone) => zone.name;
