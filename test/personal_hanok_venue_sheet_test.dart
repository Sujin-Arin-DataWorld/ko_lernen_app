import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_venue_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_venue_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

void main() {
  testWidgets(
    'keeps Anchae choices usable on a compact phone at 1.3 text scale',
    (tester) async {
      tester.view.physicalSize = const Size(308, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PersonalHanokVenueAction? picked;
      await tester.pumpWidget(
        _host(
          zone: PersonalHanokZone.anchae,
          textScale: 1.3,
          onPicked: (action) => picked = action,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-venue-sheet')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('personal-hanok-venue-anchae')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(SoriSheetShell)).height,
        lessThanOrEqualTo(528.5),
      );
      expect(tester.takeException(), isNull);

      final lastAction = find.byKey(
        const ValueKey('personal-hanok-venue-action-captureBook'),
      );
      await tester.ensureVisible(lastAction);
      expect(tester.getSize(lastAction).height, greaterThanOrEqualTo(44));
      await tester.tap(lastAction);
      await tester.pumpAndSettle();

      expect(picked, PersonalHanokVenueAction.captureBook);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps both Huwon actions reachable on a tablet width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(zone: PersonalHanokZone.huwon, onPicked: (_) {}),
    );
    await tester.tap(find.byKey(const ValueKey('open-venue-sheet')));
    await tester.pumpAndSettle();

    final daily = find.byKey(
      const ValueKey('personal-hanok-venue-action-openDailyCharacter'),
    );
    final quests = find.byKey(
      const ValueKey('personal-hanok-venue-action-openQuests'),
    );
    await tester.ensureVisible(daily);
    await tester.ensureVisible(quests);
    expect(tester.getSize(daily).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(quests).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}

final _completeProjection = PersonalHanokProjection.from(
  const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
);

Widget _host({
  required PersonalHanokZone zone,
  required ValueChanged<PersonalHanokVenueAction> onPicked,
  double textScale = 1,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey('open-venue-sheet'),
          onPressed: () async {
            final action = await showPersonalHanokVenueSheet(
              context: context,
              projection: _completeProjection,
              zone: zone,
              zoneLabel: zone.name,
            );
            if (action != null) {
              onPicked(action);
            }
          },
          child: const Text('open'),
        ),
      ),
    ),
  ),
);
