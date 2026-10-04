import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/models/silben_practice.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/sori_speech_stubs.dart';
import 'support/sori_stage_pump.dart';

const h = SilbenWord(
  dir: 'h',
  row: 1,
  col: 0,
  answer: '가나다',
  german: 'across',
  exampleKo: '◯◯◯를 읽어요.',
  exampleDe: 'Lies diese drei Silben.',
  exampleEn: 'Read these three syllables.',
);
const v = SilbenWord(
  dir: 'v',
  row: 0,
  col: 1,
  answer: '차나마',
  german: 'down',
  exampleKo: '',
  exampleDe: '',
);
const p = SilbenPuzzle(
  id: 'help-test',
  rows: 3,
  cols: 3,
  words: [h, v],
  pool: ['가', '나', '다', '차', '마'],
);
Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await pumpSoriStage(tester);
}

Widget host(SilbenReviewRequest? request) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  routes: {
    '/sarangbang': (_) => const Scaffold(body: Text('sarangbang opened')),
  },
  home: SilbenKreuzScreen(
    review: request,
    puzzleLoader: () async => {
      'A1': [p],
    },
  ),
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_silben_kreuz': true});
    Storage.resetForTesting();
    await Storage.init();
    stubSoriSpeech();
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(800, 1280),
  ]) {
    testWidgets('club contact stays on the board edge at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(null));
      await pumpSoriStage(tester);
      final stage = tester.getRect(
        find.byKey(const ValueKey('dokkaebi-motion-stage')),
      );
      final ledge = tester.getRect(
        find.byKey(const ValueKey('dokkaebi-board-ledge')),
      );
      final contact = Offset(
        stage.left + stage.width * .838,
        stage.top + stage.height * .921,
      );
      expect(contact.dy, closeTo(ledge.top, .01));
      expect(contact.dx, inInclusiveRange(ledge.left, ledge.right));
      final cell = tester.getRect(
        find.byKey(const ValueKey('silben-cell-0-1')),
      );
      expect(stage.overlaps(cell), isFalse);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const ValueKey('dokkaebi-introduction')));
      expect(find.text('도깨비'), findsOneWidget);
      expect(PracticeHistoryStore.load().items.single.assisted, isNull);
      expect(PracticeHistoryStore.load().items.single.independent, isNull);
      expect(Storage.xp, 0);
      await tap(tester, find.text('Back to the puzzle'));
      expect(find.byKey(const ValueKey('dokkaebi-hint')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'compact help adds a new sentence and word path, without placing a tile',
    (tester) async {
      await tester.pumpWidget(host(null));
      await pumpSoriStage(tester);
      await tap(tester, find.byKey(const ValueKey('silben-clue-0')));
      expect(find.text(h.exampleKo), findsNothing);
      expect(find.text(h.exampleEn), findsNothing);
      expect(
        tester.getSize(find.byType(PracticeDokkaebiHelp)).height,
        lessThanOrEqualTo(84),
      );
      await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
      expect(find.text(h.exampleKo), findsOneWidget);
      expect(find.text(h.exampleEn), findsOneWidget);
      expect(find.text('3 syllables · Start: row 2, column 1'), findsOneWidget);
      final selected = tester.widget<Semantics>(
        find.byKey(const ValueKey('silben-cell-1-0')),
      );
      expect(selected.properties.label, contains('Open'));
      expect(PracticeHistoryStore.load().items.single.assisted, isNull);
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'opening and reopening a puzzle stores viewing without completion or rewards',
    (tester) async {
      await tester.pumpWidget(host(null));
      await pumpSoriStage(tester);
      final viewed = PracticeHistoryStore.load().items.single;
      expect(viewed.viewedAt, isNotNull);
      expect(viewed.assisted, isNull);
      expect(viewed.independent, isNull);
      expect(Storage.xp, 0);
      expect(Storage.gameBest('skz_a1'), 0);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.celebrate,
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(SilbenReviewRequest(puzzleId: p.id, level: 'a1', revision: 1)),
      );
      await pumpSoriStage(tester);
      final reopened = PracticeHistoryStore.load().items.single;
      expect(reopened.viewedAt!.isBefore(viewed.viewedAt!), isFalse);
      expect(reopened.assisted, isNull);
      expect(reopened.independent, isNull);
      expect(Storage.xp, 0);
      expect(Storage.gameBest('skz_a1'), 0);
    },
  );
  testWidgets(
    'reveal highlights selected crossing without placing it; all assisted occurrences persist',
    (tester) async {
      await tester.pumpWidget(host(null));
      await pumpSoriStage(tester);
      await tap(tester, find.byKey(const ValueKey('silben-clue-0')));
      await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
      await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
      await tap(tester, find.byKey(const ValueKey('dokkaebi-cross-1-1')));
      await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
      expect(find.byKey(const ValueKey('dokkaebi-revealed')), findsOneWidget);
      final cell = tester.widget<Semantics>(
        find.byKey(const ValueKey('silben-cell-1-1')),
      );
      expect(cell.properties.label, contains('Open'));
      for (final entry in [
        ((1, 0), '가'),
        ((1, 1), '나'),
        ((1, 2), '다'),
        ((0, 1), '차'),
        ((2, 1), '마'),
      ]) {
        await tap(
          tester,
          find.byKey(ValueKey('silben-cell-${entry.$1.$1}-${entry.$1.$2}')),
        );
        await tap(tester, find.bySemanticsLabel(entry.$2));
      }
      expect(PracticeHistoryStore.load().items.single.assisted!.hints, {
        'h:1:0': 3,
        'v:0:1': 3,
      });
      expect(Storage.xp, 30);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'assisted game completion links to Sarangbang without a second reward',
    (tester) async {
      await tester.pumpWidget(host(null));
      await pumpSoriStage(tester);
      await tap(tester, find.byKey(const ValueKey('dokkaebi-hint')));
      for (final entry in [
        ((1, 0), '가'),
        ((1, 1), '나'),
        ((1, 2), '다'),
        ((0, 1), '차'),
        ((2, 1), '마'),
      ]) {
        await tap(
          tester,
          find.byKey(ValueKey('silben-cell-${entry.$1.$1}-${entry.$1.$2}')),
        );
        await tap(tester, find.bySemanticsLabel(entry.$2));
      }
      expect(PracticeHistoryStore.load().items.single.assisted, isNotNull);
      expect(Storage.xp, 30);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.celebrate,
        ),
        findsOneWidget,
      );
      final t = AppL10n.of(tester.element(find.byType(SilbenKreuzScreen)));
      final destination = find.text(t.practiceToSarangbang);
      expect(destination, findsOneWidget);
      await tap(tester, destination);
      expect(find.text('sarangbang opened'), findsOneWidget);
      expect(Storage.xp, 30);
      expect(Storage.gameBest('skz_a1'), 1);
    },
  );
  testWidgets(
    'independent replay persists completion without XP or best mutation',
    (tester) async {
      await tester.pumpWidget(
        host(const SilbenReviewRequest(level: 'a1', puzzleId: 'help-test')),
      );
      await pumpSoriStage(tester);
      for (final entry in [
        ((1, 0), '가'),
        ((1, 1), '나'),
        ((1, 2), '다'),
        ((0, 1), '차'),
        ((2, 1), '마'),
      ]) {
        await tap(
          tester,
          find.byKey(ValueKey('silben-cell-${entry.$1.$1}-${entry.$1.$2}')),
        );
        await tap(tester, find.bySemanticsLabel(entry.$2));
      }
      expect(
        PracticeHistoryStore.load().items.single.independent!.variant,
        'replay',
      );
      expect(Storage.xp, 0);
      expect(Storage.gameBest('skz_a1'), 0);
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.celebrate,
        ),
        findsOneWidget,
      );
    },
  );
}
