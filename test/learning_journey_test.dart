import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/sori_stage_reward_receipt_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'support/hanok_competence_fixture.dart';

void main() {
  for (final shownStages in [0, 1, 3]) {
    testWidgets(
      'receipt preserves only unshown Sarangchae stages after $shownStages shown',
      (tester) async {
        final observer = LearningJourneyObserver();
        late Route<dynamic> origin;
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [observer],
            home: Builder(
              builder: (context) {
                origin = ModalRoute.of(context)!;
                return const Text('origin');
              },
            ),
          ),
        );
        final journey = observer.begin(origin)!;
        final attempt = journey.beginAttempt()..complete();
        attempt.shown(SoriRewardKind.xp, 10);
        attempt.shown(SoriRewardKind.hanokProgress, shownStages);
        attempt.shown(SoriRewardKind.hanokProgress, shownStages);
        SoriStageProgressionSnapshot snapshot(int units, int xp) =>
            SoriStageProgressionSnapshot(
              today: const TodayLearningSnapshot(pick: null),
              hanokCompetence: hanokCompetenceFixture(
                a1Completed: units,
                a1Total: 16,
              ),
              quests: const [],
              pendingBojagiCount: 0,
              stampCount: 0,
              xp: xp,
              streakDays: 0,
              todayReward: null,
            );
        final receipt = SoriStageRewardReceiptService.compare(
          activityId: 'course',
          before: snapshot(4, 100),
          after: snapshot(7, 115),
        );
        final remaining = journey.unshown(receipt);
        expect(remaining.receiptId, receipt.receiptId);
        expect(remaining.activityId, receipt.activityId);
        expect(
          remaining.items
              .singleWhere((item) => item.kind == SoriRewardKind.xp)
              .amount,
          5,
        );
        expect(remaining.sarangchaeStageBefore, 4 + shownStages);
        expect(remaining.sarangchaeStageAfter, 7);
        expect(remaining.hasSarangchaeUpgrade, shownStages < 3);
        final stageItems = remaining.items.where(
          (item) => item.kind == SoriRewardKind.hanokProgress,
        );
        if (shownStages == 3) {
          expect(stageItems, isEmpty);
          expect(
            remaining.isEmpty,
            isFalse,
            reason: 'Unshown XP remains without replaying the Hanok upgrade.',
          );
        } else {
          expect(stageItems.single.amount, 3 - shownStages);
        }
      },
    );
  }

  testWidgets(
    'Home confirmation preserves origin identity and scroll through a hub',
    (tester) async {
      final observer = LearningJourneyObserver();
      final nav = GlobalKey<NavigatorState>();
      final scroll = ScrollController();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return ListView(
                controller: scroll,
                children: List.generate(
                  60,
                  (i) => SizedBox(height: 40, child: Text('Learn $i')),
                ),
              );
            },
          ),
        ),
      );
      scroll.jumpTo(280);
      final journey = observer.begin(origin)!;
      nav.currentState!.push(
        MaterialPageRoute(builder: (_) => const Text('hub')),
      );
      await tester.pumpAndSettle();
      var left = 0;
      nav.currentState!.push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            body: SoriHomeAction(
              escape: const SoriHomeEscape(confirmWhen: true),
              onLeave: () => left++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = await AppL10n.delegate.load(const Locale('en'));
      await tester.tap(find.byType(SoriHomeAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.homeActionConfirmStay));
      await tester.pumpAndSettle();
      expect(left, 0);
      expect(observer.active, same(journey));
      await tester.tap(find.byType(SoriHomeAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.homeActionConfirmLeave));
      await tester.pumpAndSettle();
      expect(left, 1);
      expect(origin.isCurrent, true);
      expect(scroll.offset, 280);
      expect(journey.abandoned, true);
      expect(observer.active, isNull);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
    },
  );

  testWidgets(
    'replacement, child, sheet, retry preserve origin until true return',
    (tester) async {
      final observer = LearningJourneyObserver();
      final nav = GlobalKey<NavigatorState>();
      late BuildContext originContext;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              originContext = context;
              return const Text('Learn origin');
            },
          ),
        ),
      );
      final origin = ModalRoute.of(originContext)!;
      final journey = observer.begin(origin)!;
      var returned = false;
      journey.returned.then((_) => returned = true);
      Route<void> page(String label) =>
          MaterialPageRoute(builder: (_) => Text(label));
      nav.currentState!.push(page('pack'));
      await tester.pumpAndSettle();
      nav.currentState!.pushReplacement(page('result'));
      await tester.pumpAndSettle();
      expect(returned, false);
      nav.currentState!.push(page('recall child'));
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(returned, false);
      nav.currentState!.pushReplacement(page('retry'));
      await tester.pumpAndSettle();
      expect(returned, false);
      nav.currentState!.popUntil((route) => identical(route, origin));
      await tester.pumpAndSettle();
      expect(returned, true);
      expect(origin.isCurrent, true);
      expect(find.text('Learn origin'), findsOneWidget);
      expect(observer.active, isNull);
    },
  );

  testWidgets(
    'origin removal cancels; completed attempt survives abandoned retry',
    (tester) async {
      final observer = LearningJourneyObserver();
      final nav = GlobalKey<NavigatorState>();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const Text('origin');
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      journey.beginAttempt().complete(passed: false);
      journey.beginAttempt();
      expect(journey.hadCompletedAttempt, true);
      expect(journey.abandoned, false);
      nav.currentState!.push(
        MaterialPageRoute(builder: (_) => const Text('child')),
      );
      await tester.pumpAndSettle();
      nav.currentState!.removeRoute(origin);
      await tester.pumpAndSettle();
      expect(journey.cancelled, true);
      await journey.returned;
    },
  );

  testWidgets(
    'save work settles after route exit and rewards deduplicate by attempt and identity',
    (tester) async {
      final observer = LearningJourneyObserver();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const Text('origin');
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      final first = journey.beginAttempt()..complete();
      first.shown(SoriRewardKind.xp, 10);
      first.shown(SoriRewardKind.xp, 10); // Duplicate native rebuild.
      first.shown(SoriRewardKind.personalBest, 1, identity: 'cloze');
      final second = journey.beginAttempt()..complete();
      second.shown(SoriRewardKind.personalBest, 1, identity: 'cloze');
      final third = journey.beginAttempt();
      final write = Completer<void>();
      final tracked = trackLearningPersistence(third, write.future);
      var settled = false;
      journey.settle().then((_) => settled = true);
      await tester.pump();
      expect(settled, false);
      write.completeError(StateError('save failed'));
      await expectLater(tracked, throwsStateError);
      await tester.pump();
      expect(settled, true);
      expect(journey.hadSaveFailure, true);
      const copy = SoriLocalizedCopy(de: 'x', en: 'x');
      final remaining = journey.unshown(
        const RewardReceipt(
          activityId: 'cloze',
          receiptId: 'r',
          b2ConstructionStageBefore: 11,
          b2ConstructionStageAfter: 17,
          items: [
            RewardReceiptItem(kind: SoriRewardKind.xp, label: copy, amount: 13),
            RewardReceiptItem(
              kind: SoriRewardKind.personalBest,
              label: copy,
              amount: 1,
              identity: 'cloze',
            ),
            RewardReceiptItem(
              kind: SoriRewardKind.personalBest,
              label: copy,
              amount: 1,
              identity: 'daily',
            ),
            RewardReceiptItem(
              kind: SoriRewardKind.bojagi,
              label: copy,
              amount: 1,
            ),
          ],
        ),
      );
      expect(remaining.items.map((i) => i.amount), [3, 1, 1]);
      expect(remaining.items[1].identity, 'daily');
      expect(remaining.b2ConstructionStageBefore, 11);
      expect(remaining.b2ConstructionStageAfter, 17);
    },
  );
}
