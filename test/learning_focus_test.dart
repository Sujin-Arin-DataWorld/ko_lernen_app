import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/theme.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';

const unit = CourseUnit(
  id: 'a1',
  level: 'a1',
  order: 0,
  title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greetings'),
  canDo: CurriculumText(ko: '인사해요', de: 'Ich kann grüßen.', en: 'I can greet.'),
);
final link = ContentLink(
  id: 'v',
  contentKind: CurriculumContentKind.vocab,
  contentId: 'vocab-word',
  courseUnitId: 'a1',
  conceptIds: [],
  role: ContentLinkRole.practice,
);
const today = TodayLearningSnapshot(
  pick: CoursePick(
    unit: unit,
    missionNumber: 1,
    totalMissions: 2,
    fraction: 0,
    started: true,
  ),
  destination: TodayLearningDestination(route: '/course/mission'),
);
void main() {
  for (final state in [
    'loading',
    'error',
    'empty',
    'ready',
    'source unavailable',
    'destination unavailable',
  ]) {
    testWidgets('course overview stays independent when focus is $state', (
      tester,
    ) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_preferred_mascot': 'none'});
      await Storage.init();
      MascotPreference.load();
      final args = VocabPackRouteArguments(
        packId: 'exact-pack',
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final brief = CourseMissionBrief.from(
        unit: unit,
        links: [link],
        scenarios: [],
        isCurrent: true,
      );
      final ready = LearningFocus(
        today: today,
        brief: brief,
        destination: TodayLearningDestination(
          route: '/vocab/pack',
          arguments: args,
        ),
      );
      const empty = LearningFocus(today: TodayLearningSnapshot(pick: null));
      final pending = Completer<LearningFocus>();
      var reads = 0;
      final controller = LearningFocusController(
        loader: () async {
          reads++;
          if (reads > 1) {
            return ready;
          }
          return switch (state) {
            'loading' => pending.future,
            'error' => throw StateError('source read failed'),
            'empty' => empty,
            'source unavailable' => const LearningFocus(
              today: TodayLearningSnapshot(
                pick: null,
                dueCount: 2,
                availability: TodayLearningAvailability.unavailable,
                unavailableReason: TodayLearningUnavailableReason.localData,
              ),
              failure: LearningFocusFailure.sourceUnavailable,
            ),
            'destination unavailable' => LearningFocus(
              today: today,
              brief: brief,
              failure: LearningFocusFailure.destinationUnavailable,
            ),
            _ => ready,
          };
        },
      );
      addTearDown(controller.dispose);
      final refresh = controller.refresh();
      if (state != 'loading') {
        await refresh;
      }
      final opened =
          <
            ({
              TodayLearningDestination destination,
              LearningFocus? focus,
              String? id,
            })
          >[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: LearningFocusScope(
            controller: controller,
            open: (_, destination, {focus, activityId}) async {
              opened.add((
                destination: destination,
                focus: focus,
                id: activityId,
              ));
            },
            child: const Scaffold(
              body: SingleChildScrollView(
                child: SoriLearningFocus(
                  introduction: Text('Shared introduction'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final t = await AppL10n.delegate.load(const Locale('en'));
      final overview = find.byKey(
        const ValueKey('learning-focus-course-overview'),
      );
      expect(find.text('Shared introduction'), findsOneWidget);
      expect(overview, findsOneWidget);
      expect(find.text(t.learningFocusViewCourse), findsOneWidget);
      expect(
        find.text(t.learningFocusCoursePosition('A1', 1)),
        state == 'ready' || state == 'destination unavailable'
            ? findsOneWidget
            : findsNothing,
      );
      expect(
        find.text(t.learningFocusStart),
        state == 'ready' ? findsOneWidget : findsNothing,
      );
      expect(opened, isEmpty);
      await tester.tap(overview);
      expect(opened, hasLength(1));
      expect(opened.single.destination.route, '/path');
      expect(opened.single.destination.arguments, isNull);
      expect(opened.single.focus, isNull);
      expect(opened.single.id, 'course');

      expect(controller.claimLaunch(), isTrue);
      await tester.pump();
      expect(tester.widget<TextButton>(overview).onPressed, isNull);
      controller.releaseLaunch();
      await tester.pump();

      if (state == 'ready') {
        await tester.tap(find.text(t.learningFocusStart));
        expect(opened, hasLength(2));
        expect(opened.last.destination.route, '/vocab/pack');
        expect(identical(opened.last.destination.arguments, args), isTrue);
        expect(identical(opened.last.focus, ready), isTrue);
        expect(opened.last.id, ready.activityId);
      } else if (state == 'loading') {
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text(t.btnRetry), findsNothing);
        pending.complete(empty);
        await refresh;
        await tester.pump();
        expect(find.text(t.soriStageTodayEmpty), findsOneWidget);
        expect(overview, findsOneWidget);
        expect(opened, hasLength(1));
      } else if (state == 'empty') {
        expect(find.text(t.soriStageTodayEmpty), findsOneWidget);
        expect(find.text(t.btnRetry), findsNothing);
      } else {
        expect(
          find.text(
            state == 'destination unavailable'
                ? t.learningFocusDestinationUnavailable
                : t.loadErrorTryAgain,
          ),
          findsOneWidget,
        );
        final safeReview = find.text(t.reviewHubTitle);
        expect(
          safeReview,
          state == 'source unavailable' ? findsOneWidget : findsNothing,
        );
        if (state == 'source unavailable') {
          await tester.tap(safeReview);
          expect(opened.last.destination.route, '/review');
          expect(opened.last.destination.arguments, isNull);
          expect(opened.last.focus, isNull);
          expect(opened.last.id, isNull);
        }
        final launchCount = opened.length;
        await tester.tap(find.text(t.btnRetry));
        await tester.pumpAndSettle();
        expect(reads, 2);
        expect(find.text(t.learningFocusStart), findsOneWidget);
        expect(overview, findsOneWidget);
        expect(opened, hasLength(launchCount));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'Today and Learn render one goal and pass identical exact destination arguments',
    (tester) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_preferred_mascot': 'none'});
      await Storage.init();
      MascotPreference.load();
      final args = VocabPackRouteArguments(
        packId: 'exact-pack',
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final focus = await LearningFocus.load(
        loadToday: () async => today,
        loadBrief: (_) async => CourseMissionBrief.from(
          unit: unit,
          links: [link],
          scenarios: [],
          isCurrent: true,
        ),
        resolve: (_) async =>
            CourseMissionDestination(route: '/vocab/pack', arguments: args),
      );
      final controller = LearningFocusController(loader: () async => focus);
      await controller.refresh();
      final selected = ValueNotifier<int>(0);
      final received = <TodayLearningDestination>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: LearningFocusScope(
            controller: controller,
            open: (context, destination, {focus, activityId}) async {
              received.add(destination);
            },
            child: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (_, tab, __) => Scaffold(
                body: IndexedStack(
                  index: tab,
                  children: const [SoriLearningFocus(), SoriLearningFocus()],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = await AppL10n.delegate.load(const Locale('en'));
      expect(find.text('Greetings'), findsOneWidget);
      await tester.tap(find.text(t.learningFocusStart));
      selected.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Greetings'), findsOneWidget);
      await tester.tap(find.text(t.learningFocusStart));
      expect(received, hasLength(2));
      expect(identical(received[0], received[1]), true);
      expect(identical(received[0].arguments, args), true);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      selected.dispose();
    },
  );

  test(
    'course focus resolves exact first link and preserves typed arguments',
    () async {
      final args = VocabPackRouteArguments(
        packId: 'containing-pack',
        courseContext: CoursePracticeContext.fromLink(link),
      );
      final focus = await LearningFocus.load(
        loadToday: () async => today,
        loadBrief: (_) async => CourseMissionBrief.from(
          unit: unit,
          links: [link],
          scenarios: [],
          isCurrent: true,
        ),
        resolve: (actual) async {
          expect(identical(actual, link), true);
          return CourseMissionDestination(
            route: '/vocab/pack',
            arguments: args,
          );
        },
      );
      expect(focus.destination!.route, '/vocab/pack');
      expect(identical(focus.destination!.arguments, args), true);
      expect(focus.minutes, greaterThan(1));
      expect(focus.ready, true);
    },
  );
  test(
    'failed direct resolution never falls back to another activity',
    () async {
      final focus = await LearningFocus.load(
        loadToday: () async => today,
        loadBrief: (_) async => CourseMissionBrief.from(
          unit: unit,
          links: [link],
          scenarios: [],
          isCurrent: true,
        ),
        resolve: (_) async => null,
      );
      expect(focus.failure, LearningFocusFailure.destinationUnavailable);
      expect(focus.destination, isNull);
    },
  );
  test(
    'shared controller deduplicates reads, rejects stale refresh and locks rapid launches',
    () async {
      final reads = <Completer<LearningFocus>>[];
      var account = 1;
      final controller = LearningFocusController(
        loader: () {
          final read = Completer<LearningFocus>();
          reads.add(read);
          return read.future;
        },
        accountLifetime: () => account,
      );
      final first = controller.refresh();
      final duplicate = controller.refresh();
      expect(reads, hasLength(1));
      expect(identical(first, duplicate), true);
      final second = controller.refresh(force: true);
      reads[1].complete(
        const LearningFocus(today: TodayLearningSnapshot(pick: null)),
      );
      await second;
      final current = controller.value;
      reads[0].complete(const LearningFocus(today: today));
      await first;
      expect(identical(controller.value, current), true);
      expect(controller.claimLaunch(), true);
      expect(controller.claimLaunch(), false);
      controller.releaseLaunch();
      final staleAccount = controller.refresh(force: true);
      account++;
      reads[2].complete(const LearningFocus(today: today));
      await staleAccount;
      expect(controller.value, isNull);
      controller.dispose();
    },
  );
}
