import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_gye': true});
    await Storage.init();
  });

  testWidgets('weekly promise and courtyard stay scrollable on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sessions = ValueNotifier<CloudWriteSession?>(null);
    addTearDown(sessions.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: GyeScreen(
          gyeId: 'ABC234',
          accountSessions: sessions,
          metaUpdates: Stream<GyeMeta?>.value(
            const GyeMeta(
              id: 'ABC234',
              name: 'Moon courtyard',
              code: 'ABC234',
              ownerId: 'owner',
              weeklyGoalPacks: 5,
              weeklyGoalProgress: 3,
            ),
          ),
          memberUpdates: Stream<List<GyeMember>>.value(const [
            GyeMember(uid: 'owner', nickname: 'Mina', role: GyeRole.owner),
          ]),
          currentMemberUpdates: Stream<GyeMember?>.value(null),
          dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
          blockedUidUpdates: Stream<Set<String>>.value(const {}),
          feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text('Keep the courtyard lights on together.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('A shared place for small, safe encouragement.'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('A shared place for small, safe encouragement.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a life promise shows only an anonymous lantern aggregate', (
    tester,
  ) async {
    final sessions = ValueNotifier<CloudWriteSession?>(null);
    addTearDown(sessions.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: GyeScreen(
          gyeId: 'ABC234',
          accountSessions: sessions,
          metaUpdates: Stream<GyeMeta?>.value(
            const GyeMeta(
              id: 'ABC234',
              name: 'Moon courtyard',
              code: 'ABC234',
              ownerId: 'owner',
              weeklyPromiseSchemaVersion: 1,
              weeklyPromiseId: 'cafe_order',
              weeklyPromiseTarget: 3,
              weeklyPromiseProgress: 2,
            ),
          ),
          memberUpdates: Stream<List<GyeMember>>.value(const [
            GyeMember(uid: 'owner', nickname: 'Mina', role: GyeRole.owner),
          ]),
          currentMemberUpdates: Stream<GyeMember?>.value(null),
          dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
          blockedUidUpdates: Stream<Set<String>>.value(const {}),
          feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Let three people practise ordering politely.'),
      findsOneWidget,
    );
    expect(find.text('2 of 3 lanterns are lit'), findsOneWidget);
    expect(find.text('Mina'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('life promise survives the planned width and text-scale matrix', (
    tester,
  ) async {
    const viewports = <Size>[
      Size(308, 680),
      Size(390, 760),
      Size(480, 800),
      Size(720, 960),
      Size(1024, 900),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final textScale in [1.0, 1.3]) {
      for (final viewport in viewports) {
        tester.view.physicalSize = viewport;
        final sessions = ValueNotifier<CloudWriteSession?>(null);
        await tester.pumpWidget(
          MaterialApp(
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
            home: GyeScreen(
              gyeId: 'ABC234',
              accountSessions: sessions,
              metaUpdates: Stream<GyeMeta?>.value(
                const GyeMeta(
                  id: 'ABC234',
                  name: 'Moon courtyard',
                  code: 'ABC234',
                  ownerId: 'owner',
                  weeklyPromiseSchemaVersion: 1,
                  weeklyPromiseId: 'directions',
                  weeklyPromiseTarget: 3,
                  weeklyPromiseProgress: 1,
                ),
              ),
              memberUpdates: Stream<List<GyeMember>>.value(const [
                GyeMember(uid: 'owner', nickname: 'Mina', role: GyeRole.owner),
              ]),
              currentMemberUpdates: Stream<GyeMember?>.value(null),
              dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
              blockedUidUpdates: Stream<Set<String>>.value(const {}),
              feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: '${viewport.width}dp at ${textScale}x text scale',
        );
        sessions.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
