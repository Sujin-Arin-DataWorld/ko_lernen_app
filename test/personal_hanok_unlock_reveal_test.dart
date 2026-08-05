import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_unlock_reveal.dart';

void main() {
  testWidgets('suppresses only the active construction layer behind a reveal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PersonalHanokMap(
          projection: _completeProjection,
          zoneLabel: (zone) => zone.name,
          suppressedMilestones: const {PersonalHanokMilestone.sadang},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('personal-hanok-layer-sadang')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('personal-hanok-layer-sarangchae')),
      findsOneWidget,
    );
  });

  testWidgets('finishes a normal construction reveal once', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      _host(
        PersonalHanokUnlockReveal(
          projection: _completeProjection,
          milestone: PersonalHanokMilestone.sadang,
          milestoneLabel: 'Sadang',
          onDone: () => completed++,
          duration: const Duration(milliseconds: 80),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('personal-hanok-unlock-reveal')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(completed, 1);
  });

  testWidgets('uses a static, explicit dismissal when motion is reduced', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      _host(
        PersonalHanokUnlockReveal(
          projection: _completeProjection,
          milestone: PersonalHanokMilestone.rearGarden,
          milestoneLabel: 'Huwon',
          onDone: () => completed++,
        ),
        reduceMotion: true,
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(completed, 0);
    await tester.tap(
      find.byKey(const ValueKey('personal-hanok-unlock-reveal-continue')),
    );
    expect(completed, 1);
  });
}

final _completeProjection = PersonalHanokProjection.from(
  const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
);

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Center(child: SizedBox(width: 360, child: child)),
    ),
  ),
);
