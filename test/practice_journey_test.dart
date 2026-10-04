import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_learning_receipt.dart';
import 'package:ko_lernen_app/models/silben_practice.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/screens/hanok_practice_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_context_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_context_catalog.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';
import 'support/sori_stage_pump.dart';

Widget host(Widget home, String language) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(language),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: home,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => switch (settings.name) {
      '/sarangbang' => SarangbangStudyScreen(
        loadTodaySnapshot: () async =>
            TodayLearningSnapshot(pick: const ReviewPick(dueCount: 0)),
        loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
        loadRoomState: () async => const SarangbangRoomState(),
      ),
      '/hanok/practice' => const HanokPracticeScreen(),
      '/smalltalk/context' => SmalltalkContextScreen(
        request: settings.arguments! as SmalltalkContextRequest,
      ),
      '/wordle' => SilbenKreuzScreen(
        review: settings.arguments! as SilbenReviewRequest,
      ),
      _ => throw StateError('Unexpected practice destination ${settings.name}'),
    },
  ),
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
  await tester.pump();
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await pumpSoriStage(tester);
}

Future<void> finishContext(WidgetTester tester) async {
  await tap(tester, find.byKey(const ValueKey('context-intent-ask')));
  await tap(tester, find.byKey(const ValueKey('context-expression-plan')));
  for (final index in [1, 0, 2]) {
    await tap(tester, find.byKey(ValueKey('context-token-$index')));
  }
  await tap(tester, find.byKey(const ValueKey('context-check')));
  expect(find.byKey(const ValueKey('context-complete')), findsOneWidget);
}

void main() {
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_silben_kreuz': true,
    });
    Storage.resetForTesting();
    await Storage.init();
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    addTearDown(SoundService.resetForTesting);
    rootBundle.clear();
    SilbenPuzzleLoader.reset();
    await SmalltalkContextCatalog.load();
    await SilbenPuzzleLoader.load();
  });
  for (final language in ['de', 'en']) {
    testWidgets(
      '$language Smalltalk returns through the room for independent transfer',
      (tester) async {
        await tester.pumpWidget(
          host(
            const SmalltalkContextScreen(
              request: SmalltalkContextRequest(caseId: 'invite_friend'),
            ),
            language,
          ),
        );
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('context-intent-ask')),
        );
        await finishContext(tester);
        final t = AppL10n.of(
          tester.element(find.byType(SmalltalkContextScreen)),
        );
        expect(PracticeHistoryStore.load().items.single.assisted, isNotNull);
        await tap(
          tester,
          find.widgetWithText(SoriButton, t.practiceToSarangbang),
        );
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('sarangbang-practice-entry')),
        );
        await tap(
          tester,
          find.widgetWithText(SoriButton, t.practiceHistoryOpen),
        );
        final open = find.byKey(
          ValueKey(
            'practice-open-${PracticeHistoryStore.load().items.single.source.key}',
          ),
        );
        await pumpUntilFound(tester, open);
        await tap(tester, open);
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('context-intent-ask')),
        );
        await finishContext(tester);
        final item = PracticeHistoryStore.load().items.single;
        expect(item.assisted, isNotNull);
        expect(item.independent!.variant, 'transfer');
        expect(item.independent!.hints, isEmpty);
        expect(Storage.xp, 0);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        Storage.resetForTesting();
        await Storage.init();
        await tester.pumpWidget(host(const HanokPracticeScreen(), language));
        await pumpUntilFound(tester, open);
        expect(PracticeHistoryStore.load().items.single.independent, isNotNull);
        expect(PracticeHistoryStore.load().items.single.assisted, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '$language assisted puzzle returns through the room for unrewarded replay',
      (tester) async {
        final puzzles = await tester.runAsync(SilbenPuzzleLoader.load);
        final puzzle = puzzles!['A1']!.first;
        await tester.pumpWidget(host(const SilbenKreuzScreen(), language));
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('dokkaebi-hint')),
        );
        await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
        Future<void> solve() async {
          for (final entry in puzzle.solution.entries) {
            await tap(
              tester,
              find.byKey(
                ValueKey('silben-cell-${entry.key.$1}-${entry.key.$2}'),
              ),
            );
            await tap(tester, find.bySemanticsLabel(entry.value).first);
          }
        }

        await solve();
        final t = AppL10n.of(tester.element(find.byType(SilbenKreuzScreen)));
        await tap(
          tester,
          find.widgetWithText(SoriButton, t.practiceToSarangbang),
        );
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('sarangbang-practice-entry')),
        );
        await tap(
          tester,
          find.widgetWithText(SoriButton, t.practiceHistoryOpen),
        );
        final open = find.byKey(
          ValueKey('practice-open-silben:${puzzle.id}:1'),
        );
        await pumpUntilFound(tester, open);
        await tap(tester, open);
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('dokkaebi-hint')),
        );
        await solve();
        final item = PracticeHistoryStore.load().items.single;
        expect(item.assisted!.variant, 'game');
        expect(item.independent!.variant, 'replay');
        expect(item.independent!.hints, isEmpty);
        expect(Storage.xp, 30);
        expect(Storage.gameBest('skz_a1'), 1);
        expect(tester.takeException(), isNull);
        await tap(
          tester,
          find.widgetWithText(SoriButton, t.practiceHistoryOpen),
        );
        await pumpUntilFound(tester, open);
        expect(find.textContaining(t.practiceIndependent), findsOneWidget);
        expect(find.textContaining(t.practiceAssisted), findsOneWidget);
        expect(Storage.xp, 30);
      },
    );
  }
}
