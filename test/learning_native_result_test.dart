import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    LearningJourneyObserver.shared.cancel();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_preferred_mascot': 'none'});
    await Storage.init();
    MascotPreference.load();
  });
  testWidgets(
    'native GameOverCard acknowledges delayed persisted outcome only while exposed',
    (tester) async {
      final observer = LearningJourneyObserver.shared;
      final nav = GlobalKey<NavigatorState>();
      late Route<dynamic> origin;
      final outcome = ValueNotifier<GameOutcome?>(null);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          theme: AppTheme.light,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const Text('origin');
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      final persisted = await recordGameResult(gameId: 'cloze', xp: 25);
      final attempt = persisted.attempt!;
      expect(Storage.xp, 25);
      nav.currentState!.push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            body: ValueListenableBuilder<GameOutcome?>(
              valueListenable: outcome,
              builder: (_, result, __) => GameOverCard(
                headline: 'Result',
                xpGained: result?.xpGained ?? 0,
                outcome: result,
                rewardReady: result != null,
                celebrate: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const copy = SoriLocalizedCopy(de: 'XP', en: 'XP');
      const receipt = RewardReceipt(
        activityId: 'cloze',
        receiptId: 'r',
        items: [
          RewardReceiptItem(kind: SoriRewardKind.xp, label: copy, amount: 25),
          RewardReceiptItem(
            kind: SoriRewardKind.bojagi,
            label: copy,
            amount: 1,
          ),
        ],
      );
      expect(journey.unshown(receipt).items.first.amount, 25);
      nav.currentState!.push(
        MaterialPageRoute(builder: (_) => const Text('covered')),
      );
      await tester.pumpAndSettle();
      outcome.value = GameOutcome(
        xpGained: 25,
        attempt: attempt,
        gameId: 'cloze',
      );
      await tester.pumpAndSettle();
      expect(journey.unshown(receipt).items.first.amount, 25);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(journey.unshown(receipt).items.map((item) => item.kind), [
        SoriRewardKind.bojagi,
      ]);
      outcome.value = GameOutcome(
        xpGained: 25,
        attempt: attempt,
        gameId: 'cloze',
      );
      await tester.pumpAndSettle();
      expect(journey.unshown(receipt).items, hasLength(1));
      outcome.dispose();
    },
  );
  for (final exitAt in [100, 850]) {
    testWidgets(
      'vocab early return at ${exitAt}ms retains unpresented XP and stamp',
      (tester) async {
        final harness = await _journeyHarness(
          tester,
          size: const Size(900, 1300),
        );
        final attempt = harness.journey.beginAttempt()..complete();
        harness.nav.currentState!.push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => _vocab(attempt),
          ),
        );
        await tester.pump();
        await tester.pump(Duration(milliseconds: exitAt));
        expect(
          harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
          contains(SoriRewardKind.xp),
        );
        if (exitAt == 100) {
          expect(
            harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
            contains(SoriRewardKind.stamp),
          );
        }
        harness.nav.currentState!.pop();
        await tester.pumpAndSettle();
        expect(
          harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
          contains(SoriRewardKind.xp),
        );
      },
    );
  }

  testWidgets(
    'vocab XP is acknowledged only after count and parent entrance finish',
    (tester) async {
      final harness = await _journeyHarness(
        tester,
        size: const Size(900, 1300),
      );
      final attempt = harness.journey.beginAttempt()..complete();
      harness.nav.currentState!.push(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => _vocab(attempt),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
        contains(SoriRewardKind.xp),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(harness.journey.unshown(_vocabReceipt).isEmpty, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'vocab XP below viewport stays eligible until the actual row is scrolled into view',
    (tester) async {
      final harness = await _journeyHarness(tester, size: const Size(390, 400));
      final attempt = harness.journey.beginAttempt()..complete();
      harness.nav.currentState!.push(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => _vocab(attempt),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(
        harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
        contains(SoriRewardKind.xp),
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('vocab-result-xp'))),
        alignment: .5,
      );
      await tester.pump();
      expect(
        harness.journey.unshown(_vocabReceipt).items.map((i) => i.kind),
        isNot(contains(SoriRewardKind.xp)),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('legacy explicitly known zero reward remains visible', (
    tester,
  ) async {
    await _journeyHarness(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: GameOverCard(
            headline: 'Finished',
            xpGained: 0,
            celebrate: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+0 XP'), findsOneWidget);
  });

  testWidgets(
    'painted reward cannot acknowledge a failed persistence attempt',
    (tester) async {
      final harness = await _journeyHarness(tester);
      final attempt = harness.journey.beginAttempt()..failed();
      harness.nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: LearningRewardPresentation(
              attempt: attempt,
              kind: SoriRewardKind.xp,
              amount: 40,
              child: const Text('+40 XP'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.journey.unshown(_vocabReceipt).items.first.amount, 40);
    },
  );
}

const _copy = SoriLocalizedCopy(de: 'XP', en: 'XP');
final _vocabReceipt = RewardReceipt(
  activityId: 'vocab',
  receiptId: 'vocab-r',
  items: [
    const RewardReceiptItem(kind: SoriRewardKind.xp, label: _copy, amount: 40),
    RewardReceiptItem(
      kind: SoriRewardKind.stamp,
      label: _copy,
      amount: 1,
      identity: motifForPackId('a1_01').name,
    ),
  ],
);
Widget _vocab(LearningAttempt attempt) => VocabPackResultScreen(
  packId: 'a1_01',
  actualXpAwarded: 40,
  learningAttempt: attempt,
  bossAccuracy: 1,
  bossCorrect: 10,
  bossTotal: 10,
  quizCorrect: 10,
  quizTotal: 10,
  justCleared: true,
  nextUnlockedPackId: null,
);
Future<({GlobalKey<NavigatorState> nav, LearningJourney journey})>
_journeyHarness(WidgetTester tester, {Size size = const Size(800, 600)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final nav = GlobalKey<NavigatorState>();
  final observer = LearningJourneyObserver.shared;
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
          return const Text('origin');
        },
      ),
    ),
  );
  return (nav: nav, journey: observer.begin(origin)!);
}
