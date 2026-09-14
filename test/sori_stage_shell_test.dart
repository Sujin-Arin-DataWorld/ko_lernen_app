import 'dart:async';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/services/onboarding_companion_service.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_attempt_companion.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'support/sori_stage_pump.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    LearningJourneyObserver.shared.cancel();
    CourseProgressService.shared.resetForTesting();
    Storage.resetForTesting();
    AppShell.requestedStageTab.value = -1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  for (final baselineState in [
    'failed',
    'missing',
    'pending',
    'historical',
    'fresh',
  ]) {
    testWidgets(
      '$baselineState companion baseline never gates ready learning or invents fresh evidence',
      (tester) async {
        final nav = GlobalKey<NavigatorState>();
        final replay = ValueNotifier(0);
        addTearDown(replay.dispose);
        final pending = Completer<CourseMasterySnapshot?>();
        late CourseUnit unit;
        late ContentLink link;
        late CourseMasterySnapshot before;
        Future<void> writeSuccess() async {
          await CourseProgressService.shared.recordContentAttempt(
            link.contentKind,
            link.contentId,
            true,
            courseContext: CoursePracticeContext.fromLink(link),
            conceptId: link.conceptIds.first,
            score: 1,
          );
        }

        await tester.runAsync(() async {
          final catalog = await CurriculumCatalog.load();
          final initialized = await CourseProgressService.shared
              .initializeForPlacement('a1');
          unit = catalog.courseUnits.singleWhere(
            (candidate) => candidate.id == initialized.currentCourseUnitId,
          );
          link = catalog
              .linksForCourseUnit(unit.id)
              .firstWhere(
                (candidate) =>
                    candidate.role == ContentLinkRole.assess &&
                    candidate.contentKind == CurriculumContentKind.scenario,
              );
          if (baselineState != 'fresh') {
            await writeSuccess();
          }
          before = (await CourseProgressService.shared.readForDisplay())!;
        });
        // The setup ran in runAsync; let the widget's zone own the subsequent
        // serialization queue while keeping the actual persisted evidence.
        CourseProgressService.shared.resetForTesting();
        if (baselineState != 'fresh') {
          expect(
            OnboardingCompanionService.shouldOfferAfterAttempt(
              introPreviewSeen: false,
              activeCourseUnitId: unit.id,
              activeCourseLevel: unit.level,
              evidenceIdsBefore: {},
              evidenceAfter: before.evidence,
              contentLinks: [link],
            ),
            isTrue,
            reason:
                'An empty fallback would incorrectly count this persisted historical success.',
          );
        }
        final events = <String>[];
        final focus = LearningFocus(
          today: const TodayLearningSnapshot(pick: null),
          destination: const TodayLearningDestination(route: '/ready/activity'),
          brief: CourseMissionBrief.from(
            unit: unit,
            links: [link],
            scenarios: [],
            isCurrent: true,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: nav,
            navigatorObservers: [LearningJourneyObserver.shared],
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: SoriStageShell(
              replayHomeTour: replay,
              loadTodaySnapshot: () async =>
                  _snapshot(const TodayLearningSnapshot(pick: null)),
              loadReceiptNetworkBefore: () async =>
                  throw StateError('optional receipt unavailable'),
              loadCompanionBefore: () {
                events.add('capture');
                if (baselineState == 'failed') {
                  throw StateError('optional evidence unavailable');
                }
                if (baselineState == 'missing') {
                  return Future<CourseMasterySnapshot?>.value();
                }
                if (baselineState == 'pending') {
                  return pending.future;
                }
                return CourseProgressService.shared.readForDisplay();
              },
            ),
            onGenerateRoute: (_) {
              events.add('route');
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('ready activity')),
              );
            },
          ),
        );
        await pumpSoriStage(tester);
        final caller = tester.element(find.byType(SoriLearningFocus).first);
        final scope = LearningFocusScope.maybeOf(caller)!;
        final returned = scope.open(
          caller,
          focus.destination!,
          focus: focus,
          activityId: 'grammar',
        );
        await pumpSoriStage(tester);
        expect(events, ['capture', 'route']);
        expect(find.text('ready activity'), findsOneWidget);
        if (baselineState == 'fresh') {
          var written = false;
          Object? writeError;
          unawaited(
            writeSuccess().then<void>(
              (_) => written = true,
              onError: (Object error, StackTrace _) {
                writeError = error;
                written = true;
              },
            ),
          );
          for (var frame = 0; frame < 50 && !written; frame++) {
            await pumpSoriStage(tester, frames: 1);
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 1)),
            );
          }
          expect(
            written,
            isTrue,
            reason:
                'The queued course write must settle after the pre-attempt read.',
          );
          expect(writeError, isNull);
        }
        nav.currentState!.pop();
        await pumpSoriStage(tester);
        if (baselineState == 'fresh') {
          await pumpUntilFound(tester, find.byType(FirstVoiceSuccessScreen));
          expect(find.byType(FirstVoiceSuccessScreen), findsOneWidget);
          nav.currentState!.pop();
          await pumpSoriStage(tester);
        }
        await returned;
        expect(find.byType(FirstVoiceSuccessScreen), findsNothing);
        expect(scope.notifier!.launching, isFalse);
        expect(tester.takeException(), isNull);
        if (baselineState == 'pending') {
          expect(
            pending.isCompleted,
            isFalse,
            reason: 'Returning must not wait for optional evidence.',
          );
          pending.complete(before);
          await pumpSoriStage(tester);
          expect(find.byType(FirstVoiceSuccessScreen), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'actual shell return releases launch after stalled ancillary baseline expires',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final baseline = Completer<SoriStageNetworkBeforeFields>();
      final replay = ValueNotifier(0);
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [LearningJourneyObserver.shared],
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageShell(
            replayHomeTour: replay,
            loadReceiptNetworkBefore: () => baseline.future,
            loadTodaySnapshot: () async => SoriStageProgressionSnapshot(
              today: const TodayLearningSnapshot(pick: null),
              hanokCompetence: const HanokCompetenceProjection.empty(),
              quests: [],
              pendingBojagiCount: 0,
              stampCount: 0,
              xp: 0,
              streakDays: 0,
              todayReward: null,
            ),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/failed/activity') {
              throw StateError('route unavailable');
            }
            opened++;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('real activity')),
            );
          },
        ),
      );
      await tester.pump();
      final context = tester.element(find.byType(SoriLearningFocus).first);
      final scope = LearningFocusScope.maybeOf(context)!;
      final first = scope.open(
        context,
        const TodayLearningDestination(route: '/test/activity'),
        activityId: 'chosung',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, 1);
      await scope.open(
        context,
        const TodayLearningDestination(route: '/my_words'),
        activityId: 'my_words',
      );
      expect(
        opened,
        1,
        reason: 'rapid second tap is rejected by the shared guard',
      );
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), 'chosung');
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(scope.notifier!.lastJourneyResult?.abandoned, isTrue);
      expect(baseline.isCompleted, isFalse);
      await tester.pump(const Duration(seconds: 5));
      await first;
      expect(scope.notifier!.launching, isFalse);
      final second = scope.open(
        context,
        const TodayLearningDestination(route: '/my_words'),
        activityId: 'custom_practice',
      );
      await tester.pump();
      expect(opened, 2);
      nav.currentState!.pop();
      await tester.pump(const Duration(seconds: 5));
      await second;
      expect(scope.notifier!.launching, isFalse);
      expect(
        Storage.recentCatalogActivityId(SoriStageTab.games),
        'custom_practice',
      );
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      final rejected = scope.open(
        context,
        const TodayLearningDestination(route: '/failed/activity'),
        activityId: 'listening',
      );
      await tester.pump(const Duration(seconds: 5));
      await rejected;
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      await tester.pumpWidget(const SizedBox());
      replay.dispose();
    },
  );
  testWidgets(
    'delayed Today aggregate replaces caller but unshown receipt and qualifying queued companion survive',
    (tester) async {
      SoundService.playImpl = (_) {};
      addTearDown(SoundService.resetForTesting);
      final nav = GlobalKey<NavigatorState>();
      final replay = ValueNotifier(0);
      addTearDown(replay.dispose);
      final aggregate = Completer<SoriStageProgressionSnapshot>();
      var loads = 0;
      final snapshot = _snapshot(
        const TodayLearningSnapshot(
          pick: null,
          destination: TodayLearningDestination(route: '/grammar'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [
            LearningJourneyObserver.shared,
            soriRouteObserver,
          ],
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageShell(
            replayHomeTour: replay,
            loadTodaySnapshot: () =>
                ++loads == 2 ? aggregate.future : Future.value(snapshot),
            loadReceiptNetworkBefore: () async => (
              hanokCompetence: const HanokCompetenceProjection.empty(),
              quests: <QuestProgress>[],
              gyeLanternCount: 0,
            ),
          ),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('owned activity')),
          ),
        ),
      );
      await pumpSoriStage(tester);
      final caller = tester.element(find.byType(SoriLearningFocus).first);
      final scope = LearningFocusScope.maybeOf(caller)!;
      expect(scope.notifier!.value!.ready, isTrue);
      expect(aggregate.isCompleted, isFalse);
      final returned = scope.open(
        caller,
        scope.notifier!.value!.destination!,
        activityId: 'grammar',
      );
      await pumpSoriStage(tester);
      final journey = LearningJourneyObserver.shared.active!;
      final generation = scope.notifier!.generation;
      // Nested native sheets are not returns to the shell.
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Text('internal result details'),
        ),
      );
      await pumpSoriStage(tester);
      nav.currentState!.pop();
      await pumpSoriStage(tester);
      expect(scope.notifier!.generation, generation);
      expect(LearningJourneyObserver.shared.active, same(journey));
      aggregate.complete(snapshot);
      await pumpSoriStage(tester);
      expect(caller.mounted, isFalse);
      // The real persistence boundary awards XP; no native row presents it.
      await tester.runAsync(() => recordGameResult(gameId: 'grammar', xp: 25));
      expect(Storage.xp, 25);
      const unit = CourseUnit(
        id: 'a1-01',
        level: 'a1',
        order: 0,
        title: CurriculumText(ko: '인사', de: 'Gruß', en: 'Greeting'),
        canDo: CurriculumText(ko: '인사해요', de: 'Ich grüße.', en: 'I greet.'),
      );
      final link = ContentLink(
        id: 'assess-grammar',
        contentKind: CurriculumContentKind.grammar,
        contentId: 'grammar-a',
        courseUnitId: unit.id,
        conceptIds: ['greeting'],
        role: ContentLinkRole.assess,
      );
      final evidence = MasteryEvidence(
        conceptId: 'greeting',
        contentKind: link.contentKind,
        contentId: link.contentId,
        courseUnitId: unit.id,
        missionContentLinkId: link.id,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 9, 14),
        courseEligible: true,
      );
      journey.afterReturn['qualifying-companion'] = (context) =>
          CourseAttemptCompanion.offer(
            context,
            unit: unit,
            evidenceIdsBefore: {},
            links: [link],
            after: CourseMasterySnapshot(evidence: [evidence]),
          );
      nav.currentState!.pop();
      await pumpUntilFound(tester, find.byType(SoriStageRewardReceiptSheet));
      await pumpSoriStage(tester);
      final receipt = tester
          .widget<SoriStageRewardReceiptSheet>(
            find.byType(SoriStageRewardReceiptSheet),
          )
          .receipt;
      expect(
        receipt.items.where((i) => i.kind == SoriRewardKind.xp).single.amount,
        25,
      );
      final refreshed = scope.notifier!.generation;
      await tester.tap(find.byKey(const Key('receipt-close')));
      await pumpSoriStage(tester);
      expect(find.byType(FirstVoiceSuccessScreen), findsOneWidget);
      expect(
        scope.notifier!.generation,
        refreshed,
        reason: 'receipt dismissal must not trigger a second focus load',
      );
      nav.currentState!.pop();
      await pumpSoriStage(tester);
      await returned;
      expect(scope.notifier!.launching, isFalse);
      expect(scope.notifier!.generation, refreshed);
      expect(Storage.xp, 25, reason: 'presentation cannot award twice');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'queued companion for the focused unit is not offered again after Back',
    (tester) async {
      SoundService.playImpl = (_) {};
      addTearDown(SoundService.resetForTesting);
      final nav = GlobalKey<NavigatorState>();
      final replay = ValueNotifier(0);
      addTearDown(replay.dispose);
      const unit = CourseUnit(
        id: 'a1-01',
        level: 'a1',
        order: 0,
        title: CurriculumText(ko: '인사', de: 'Gruß', en: 'Greeting'),
        canDo: CurriculumText(ko: '인사해요', de: 'Ich grüße.', en: 'I greet.'),
      );
      final snapshot = _snapshot(
        const TodayLearningSnapshot(
          pick: null,
          destination: TodayLearningDestination(route: '/owned'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [
            LearningJourneyObserver.shared,
            soriRouteObserver,
          ],
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageShell(
            replayHomeTour: replay,
            loadTodaySnapshot: () async => snapshot,
            loadLearningFocus: () async => LearningFocus(
              today: snapshot.today,
              brief: CourseMissionBrief.from(
                unit: unit,
                links: const <ContentLink>[],
                scenarios: const [],
                isCurrent: true,
              ),
              destination: const TodayLearningDestination(route: '/owned'),
            ),
            loadReceiptNetworkBefore: () async => (
              hanokCompetence: const HanokCompetenceProjection.empty(),
              quests: <QuestProgress>[],
              gyeLanternCount: 0,
            ),
          ),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('owned activity')),
          ),
        ),
      );
      await pumpSoriStage(tester);
      final caller = tester.element(find.byType(SoriLearningFocus).first);
      final scope = LearningFocusScope.maybeOf(caller)!;
      expect(scope.notifier!.value!.ready, isTrue);
      final returned = scope.open(
        caller,
        scope.notifier!.value!.destination!,
        activityId: 'grammar',
      );
      await pumpUntilFound(tester, find.text('owned activity'));
      final journey = LearningJourneyObserver.shared.active!;
      final link = ContentLink(
        id: 'assess-grammar',
        contentKind: CurriculumContentKind.grammar,
        contentId: 'grammar-a',
        courseUnitId: unit.id,
        conceptIds: ['greeting'],
        role: ContentLinkRole.assess,
      );
      final evidence = MasteryEvidence(
        conceptId: 'greeting',
        contentKind: link.contentKind,
        contentId: link.contentId,
        courseUnitId: unit.id,
        missionContentLinkId: link.id,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 9, 14),
        courseEligible: true,
      );
      journey.afterReturn[unit.id] = (context) => CourseAttemptCompanion.offer(
        context,
        unit: unit,
        evidenceIdsBefore: {},
        links: [link],
        after: CourseMasterySnapshot(evidence: [evidence]),
      );
      nav.currentState!.pop();
      await pumpUntilFound(tester, find.byType(FirstVoiceSuccessScreen));
      nav.currentState!.pop();
      await pumpSoriStage(tester);
      expect(find.byType(FirstVoiceSuccessScreen), findsNothing);
      await returned;
      expect(scope.notifier!.launching, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Settings course-start return refreshes the exact shared destination before entering Learn',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final replay = ValueNotifier(0);
      addTearDown(replay.dispose);
      // Preload actual curriculum and initialize the canonical course, as setup does.
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
        await CourseProgressService.shared.initializeForPlacement('a1');
      });
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [
            LearningJourneyObserver.shared,
            soriRouteObserver,
          ],
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageShell(replayHomeTour: replay),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('learning-focus-start')),
      );
      final caller = tester.element(find.byType(SoriLearningFocus).first);
      final controller = LearningFocusScope.maybeOf(caller)!.notifier!;
      expect(controller.value?.brief?.unit.level, 'a1');
      final oldDestination = controller.value!.destination;
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: false,
              ),
            ),
          ),
        ),
      );
      await pumpSoriStage(tester);
      final t = lookupAppL10n(const Locale('en'));
      final start = find.text(t.settingsCourseStartTitle);
      await tester.scrollUntilVisible(
        start,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(start), alignment: .5);
      await pumpSoriStage(tester);
      await tester.tap(start);
      await pumpSoriStage(tester);
      await tester.tap(
        find
            .descendant(
              of: find.byType(SimpleDialogOption),
              matching: find.textContaining('A2'),
            )
            .first,
      );
      await pumpSoriStage(tester);
      await tester.tap(find.text(t.settingsCourseStartConfirmAction));
      await pumpSoriStage(tester);
      await pumpUntilFound(tester, find.textContaining('A2 ·'));
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a2');
      nav.currentState!.pop();
      await pumpSoriStage(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('learning-focus-start')),
      );
      await pumpSoriStage(tester);
      expect(controller.value?.brief?.unit.level, 'a2');
      LearningFocus? expected;
      unawaited(LearningFocus.load().then((value) => expected = value));
      for (var frame = 0; frame < 100 && expected == null; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(expected, isNotNull);
      expect(
        controller.value!.destination!.route,
        expected!.destination!.route,
      );
      final actualArgs =
          controller.value!.destination!.arguments as VocabPackRouteArguments;
      final expectedArgs =
          expected!.destination!.arguments as VocabPackRouteArguments;
      expect(actualArgs.packId, expectedArgs.packId);
      expect(
        actualArgs.courseContext.courseUnitId,
        expectedArgs.courseContext.courseUnitId,
      );
      expect(
        actualArgs.courseContext.contentLinkId,
        expectedArgs.courseContext.contentLinkId,
      );
      expect(
        actualArgs.courseContext.initialContentId,
        expectedArgs.courseContext.initialContentId,
      );
      expect(
        actualArgs.courseContext.contentKind,
        expectedArgs.courseContext.contentKind,
      );
      expect(controller.value!.destination, isNot(oldDestination));
      await tester.tap(find.text('Learn').last);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('learning-focus-start')),
      );
      await pumpSoriStage(tester);
      expect(controller.value?.brief?.unit.id, expected!.brief!.unit.id);
      final learnContext = tester.element(find.byType(SoriLearningFocus).first);
      expect(
        LearningFocusScope.maybeOf(learnContext)!.notifier,
        same(controller),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  // Phase 4: SoriStageFeatureGate 제거 — AppShell은 항상 SoriStageShell.

  testWidgets('390dp shell exposes five roots and profile outside navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AppShell()));
    await tester.pump();

    expect(find.byType(SoriStageShell), findsOneWidget);
    for (final label in const ['Today', 'Learn', 'Games', 'Hanok', 'Gye']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.byTooltip('Profile'), findsOneWidget);
  });

  testWidgets('720dp shell uses a rail and keeps all touch targets at 48dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AppShell()));
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    final profile = tester.getSize(find.byTooltip('Profile'));
    expect(profile.width, greaterThanOrEqualTo(48));
    expect(profile.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tutorial replay returns the new shell to Today', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AppShell()));
    await tester.pump();
    await tester.tap(find.text('Games').last);
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    AppShell.replayHomeTour.value++;
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('typed stage-tab request opens Games and consumes the intent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AppShell()));
    await tester.pump();

    AppShell.openStageTab(2);
    await tester.pump();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(
      AppShell.requestedStageTab.value,
      -1,
      reason: 'Typed guide intents must be consumed exactly once by the shell.',
    );
  });
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

SoriStageProgressionSnapshot _snapshot(TodayLearningSnapshot today) =>
    SoriStageProgressionSnapshot(
      today: today,
      hanokCompetence: const HanokCompetenceProjection.empty(),
      quests: [],
      pendingBojagiCount: 0,
      stampCount: 0,
      xp: 0,
      streakDays: 0,
      todayReward: null,
    );
