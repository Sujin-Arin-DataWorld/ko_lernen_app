import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/gye_weekly_promise_navigation.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

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
    expect(find.text('Anonymous contribution'), findsNWidgets(2));
    expect(
      find.text('Your next contribution can come from Today.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No ranking. No pressure. Nobody can block another learner’s path.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('gye-promise-primary')))
          .variant,
      SoriButtonVariant.filled,
    );
    expect(
      tester
          .widget<SoriButton>(
            find.widgetWithText(SoriButton, 'Send a safe message'),
          )
          .variant,
      SoriButtonVariant.filled,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'promise CTA opens the one active assessed scene with typed provenance',
    (tester) async {
      final sessions = ValueNotifier<CloudWriteSession?>(null);
      addTearDown(sessions.dispose);
      String? openedRoute;
      Object? openedArguments;
      var membersOpened = 0;
      const activeUnit = CourseUnit(
        id: 'a1_04_order_request_object',
        level: 'a1',
        order: 4,
        title: CurriculumText(ko: '주문', de: 'Bestellen', en: 'Ordering'),
        canDo: CurriculumText(
          ko: '공손하게 주문해요.',
          de: 'Ich kann höflich bestellen.',
          en: 'I can order politely.',
        ),
        requiredConceptIds: [
          'concept_object_particle',
          'concept_request_polite',
        ],
      );
      final exactLink = ContentLink(
        id: 'link:e6a9f1197b48c79f58655c9a',
        contentKind: CurriculumContentKind.scenario,
        contentId: 'bunshik_tteokbokki',
        courseUnitId: activeUnit.id,
        conceptIds: const ['concept_object_particle', 'concept_request_polite'],
        role: ContentLinkRole.assess,
      );

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
            memberUpdates: Stream<List<GyeMember>>.value(const []),
            currentMemberUpdates: Stream<GyeMember?>.value(null),
            dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
            blockedUidUpdates: Stream<Set<String>>.value(const {}),
            feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
            loadTodaySnapshot: () async => TodayLearningSnapshot(
              pick: const CoursePick(
                unit: activeUnit,
                missionNumber: 4,
                totalMissions: 36,
                fraction: 0.25,
                started: true,
              ),
              destination: TodayLearningDestination(
                route: '/course/mission',
                arguments: activeUnit.id,
              ),
            ),
            resolvePromiseNavigation: (meta, today) async =>
                GyeWeeklyPromiseNavigation.resolve(
                  meta: meta,
                  today: today,
                  contentLinks: [exactLink],
                ),
            ensureTodayPackAccess: (_) async => true,
            openTodayRoute: (route, arguments) async {
              openedRoute = route;
              openedArguments = arguments;
            },
            onOpenMembers: () => membersOpened++,
            enableCoach: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final sceneCta = find.text('Open today’s scene');
      expect(sceneCta, findsOneWidget);
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('gye-promise-primary')))
          .onTap!();
      await tester.pump();
      expect(openedRoute, '/scenario');
      final context = openedArguments as CoursePracticeContext;
      expect(context.courseUnitId, activeUnit.id);
      expect(context.initialContentId, 'bunshik_tteokbokki');
      expect(context.contentLinkId, exactLink.id);

      expect(find.text('Rules & members'), findsOneWidget);
      tester
          .widget<TextButton>(find.byKey(const ValueKey('gye-rules-members')))
          .onPressed!();
      expect(membersOpened, 1);
    },
  );

  testWidgets('stale promise shows truthful Today fallback copy', (
    tester,
  ) async {
    final sessions = ValueNotifier<CloudWriteSession?>(null);
    addTearDown(sessions.dispose);
    String? openedRoute;
    const staleUnit = CourseUnit(
      id: 'a1_02_self_intro_identity',
      level: 'a1',
      order: 2,
      title: CurriculumText(ko: '소개', de: 'Vorstellen', en: 'Introductions'),
      canDo: CurriculumText(
        ko: '자기소개해요.',
        de: 'Ich kann mich vorstellen.',
        en: 'I can introduce myself.',
      ),
    );

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
              weeklyPromiseProgress: 1,
            ),
          ),
          memberUpdates: Stream<List<GyeMember>>.value(const []),
          currentMemberUpdates: Stream<GyeMember?>.value(null),
          dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
          blockedUidUpdates: Stream<Set<String>>.value(const {}),
          feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const CoursePick(
              unit: staleUnit,
              missionNumber: 2,
              totalMissions: 36,
              fraction: 0.1,
              started: true,
            ),
            destination: TodayLearningDestination(
              route: '/course/mission',
              arguments: staleUnit.id,
            ),
          ),
          resolvePromiseNavigation: (meta, today) async =>
              GyeWeeklyPromiseNavigation.resolve(
                meta: meta,
                today: today,
                contentLinks: const [],
              ),
          ensureTodayPackAccess: (_) async => true,
          openTodayRoute: (route, _) async => openedRoute = route,
          enableCoach: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Go to Today'), findsOneWidget);
    expect(find.text('Open today’s scene'), findsNothing);
    tester
        .widget<SoriButton>(find.byKey(const ValueKey('gye-promise-primary')))
        .onTap!();
    await tester.pump();
    expect(openedRoute, '/course/mission');
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

  testWidgets(
    'German courtyard matches 05B-C at 308dp and 1.3x without identity rows',
    (tester) async {
      tester.view.physicalSize = const Size(308, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final sessions = ValueNotifier<CloudWriteSession?>(
        const CloudWriteSession(
          uid: 'preview-user',
          epoch: 1,
          mode: CloudWriteMode.ready,
        ),
      );
      addTearDown(sessions.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: GyeScreen(
            gyeId: 'ABC234',
            accountSessions: sessions,
            metaUpdates: Stream<GyeMeta?>.value(
              const GyeMeta(
                id: 'ABC234',
                name: 'Mondhof',
                code: 'ABC234',
                ownerId: 'owner',
                weeklyPromiseSchemaVersion: 1,
                weeklyPromiseId: 'cafe_order',
                weeklyPromiseTarget: 3,
                weeklyPromiseProgress: 3,
              ),
            ),
            memberUpdates: Stream<List<GyeMember>>.value(const [
              GyeMember(uid: 'owner', nickname: 'Mina', role: GyeRole.owner),
            ]),
            currentMemberUpdates: Stream<GyeMember?>.value(null),
            dedicationUpdates: Stream<List<GyeDedication>>.value(const []),
            blockedUidUpdates: Stream<Set<String>>.value(const {}),
            feedUpdates: Stream<List<GyeFeedEvent>>.value(const []),
            loadTodaySnapshot: () async =>
                const TodayLearningSnapshot(pick: null),
            resolvePromiseNavigation: (_, _) async =>
                const GyePromiseNavigationResolution(
                  kind: GyePromiseNavigationKind.eligibleScene,
                  destination: TodayLearningDestination(route: '/scenario'),
                ),
            enableCoach: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Diese Woche gemeinsam'), findsOneWidget);
      expect(
        find.text(
          'Jede Person hilft mit einer abgeschlossenen, passenden '
          'Lernhandlung.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Als Beitrag zählt nur die passende kursgebundene Szene mit '
          'mindestens 70 %.',
        ),
        findsOneWidget,
      );
      expect(find.text('Meine heutige Szene öffnen'), findsOneWidget);
      expect(find.text('Anonymer Beitrag'), findsNWidgets(3));
      expect(find.text('Mina'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Heute leuchten drei Laternen.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Euer Hof'), findsOneWidget);
      expect(find.text('Heute leuchten drei Laternen.'), findsOneWidget);
      expect(
        find.text('Ein gemeinsamer Ort für kleine, sichere Ermutigung.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(SoriButton, 'Eine sichere Nachricht senden'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final messageButton = find.widgetWithText(
        SoriButton,
        'Eine sichere Nachricht senden',
      );
      expect(messageButton, findsOneWidget);
      expect(tester.getSize(messageButton).height, greaterThanOrEqualTo(48));
      final messageSemantics = tester
          .getSemantics(messageButton)
          .getSemanticsData();
      expect(messageSemantics.label, 'Eine sichere Nachricht senden');
      expect(messageSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
