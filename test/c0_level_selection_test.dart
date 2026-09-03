import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/learner_level_selection.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';

Scenario _scenario(String id, LearnerLevel level, {bool playable = true}) {
  return Scenario(
    id: id,
    level: level,
    emoji: '호',
    register: Register.polite,
    title: LocalizedText(ko: id, de: id, en: id),
    intro: const LocalizedText(ko: '', de: '', en: ''),
    vocab: const [],
    grammarIds: const [],
    dialog: playable
        ? const [
            DialogLine(speaker: 'teacher', ko: '안녕', de: 'Hallo', en: 'Hi'),
          ]
        : const [],
    quests: const [],
  );
}

KkeunmariWord _word(String word, String level) {
  return KkeunmariWord(
    word: word,
    first: word[0],
    last: word[word.length - 1],
    level: level,
    german: word,
    topic: 'test',
    // Deliberately global-looking metadata: the engine must derive safety from
    // the current learner subset and used-word set instead.
    nextCount: 99,
    isDeadEnd: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('C0 stored-level normalization', () {
    test('converts persisted lower-case codes to the display spelling', () {
      expect(learnerLevelDisplayForStoredCode('a2'), 'A2');
      expect(learnerLevelDisplayForStoredCode('b1'), 'B1');
      expect(learnerLevelDisplayForStoredCode('B2'), 'B2');
      expect(learnerLevelDisplayForStoredCode('c1'), 'C1');
      expect(learnerLevelDisplayForStoredCode('C2'), 'C2');
      expect(learnerLevelDisplayForStoredCode(null), 'A1');
    });
  });

  group('C0 listening selection', () {
    test('prefers an exact user-level scenario over earlier source rows', () {
      final selected = selectInitialListeningScenario([
        _scenario('a1-first', LearnerLevel.a1),
        _scenario('b2-exact', LearnerLevel.b2),
      ], LearnerLevel.b2);

      expect(selected?.id, 'b2-exact');
    });

    test(
      'uses the closest lower playable level instead of falling back to A1',
      () {
        final selected = selectInitialListeningScenario([
          _scenario('a1-first', LearnerLevel.a1),
          _scenario('b1-closest', LearnerLevel.b1),
        ], LearnerLevel.b2);

        expect(selected?.id, 'b1-closest');
      },
    );

    test(
      'ignores an exact-level scenario without dialog before using a lower level',
      () {
        final selected = selectInitialListeningScenario([
          _scenario('a1-first', LearnerLevel.a1),
          _scenario('a2-closest', LearnerLevel.a2),
          _scenario('b1-empty', LearnerLevel.b1, playable: false),
        ], LearnerLevel.b1);

        expect(selected?.id, 'a2-closest');
      },
    );
  });

  group('C0 kkeunmari level scope', () {
    setUp(KkeunmariEngine.reset);
    tearDown(KkeunmariEngine.reset);

    test(
      'keeps starts inside the cumulative subset when it has a live chain',
      () {
        KkeunmariEngine.setPoolForTesting([
          _word('가방', 'A1'),
          _word('방울', 'B1'),
          _word('울음', 'B1'),
          _word('음식', 'B2'),
        ]);

        final start = KkeunmariEngine.pickStart(maxLevel: LearnerLevel.b1);
        final level = LearnerLevel.fromCode(start.level);

        expect(level, isNotNull);
        expect(level!.rank, lessThanOrEqualTo(LearnerLevel.b1.rank));
      },
    );

    test(
      'prefers a scoped start with two live replies over a one-reply chain',
      () {
        KkeunmariEngine.setPoolForTesting([
          _word('가방', 'B1'),
          _word('방울', 'B1'),
          _word('방문', 'B1'),
          _word('나비', 'B1'),
          _word('비누', 'B1'),
        ]);

        final start = KkeunmariEngine.pickStart(maxLevel: LearnerLevel.b1);

        // All fixture records report the same global-looking nextCount. The
        // engine must derive the current subset count: 가방→방울/방문 wins
        // over 나비→비누, so the fairness choice is deterministic.
        expect(start.word, '가방');
      },
    );

    test(
      'recomputes a tiger reply after used words remove safe continuations',
      () {
        KkeunmariEngine.setPoolForTesting([
          _word('나무', 'B1'),
          _word('무지', 'B1'),
          _word('무릎', 'B1'),
          _word('나비', 'B1'),
          _word('비누', 'B1'),
        ]);

        final tiger = KkeunmariEngine.pickTigerNext('나', {
          '무지',
          '무릎',
        }, maxLevel: LearnerLevel.b1);

        expect(
          KkeunmariEngine.nextCountFor('나', {
            '무지',
            '무릎',
          }, maxLevel: LearnerLevel.b1),
          1,
        );

        // 나무 originally has two replies, but both are now used. 나비 retains
        // one live reply and must be preferred over the stranded alternative.
        expect(tiger?.word, '나비');
      },
    );

    test('reports no reply after used words exhaust the live subset', () {
      KkeunmariEngine.setPoolForTesting([
        _word('나무', 'B1'),
        _word('무지', 'B1'),
        _word('무릎', 'B1'),
      ]);

      expect(
        KkeunmariEngine.nextCountFor('무', {
          '나무',
          '무지',
          '무릎',
        }, maxLevel: LearnerLevel.b1),
        0,
      );
    });

    test(
      'uses the full pool only when a sparse subset cannot form an opening chain',
      () {
        KkeunmariEngine.setPoolForTesting([
          _word('가방', 'B1'),
          _word('방울', 'B2'),
        ]);

        final start = KkeunmariEngine.pickStart(maxLevel: LearnerLevel.b1);

        // 가방 has no B1 reply, but the B2 방울 fallback makes the opening
        // playable. A stale global `nextCount` must not decide this.
        expect(start.word, '가방');
      },
    );

    test(
      'chooses a full-pool tiger reply when scoped candidates have no live follow-up',
      () {
        KkeunmariEngine.setPoolForTesting([
          _word('나비', 'B1'),
          _word('나무', 'B2'),
          _word('무지', 'B1'),
        ]);

        final tiger = KkeunmariEngine.pickTigerNext(
          '나',
          const <String>{},
          maxLevel: LearnerLevel.b1,
        );

        // 나비 is level-eligible but strands the user inside B1. 나무 is the
        // full-pool fallback with a live B1 response (무지).
        expect(tiger?.word, '나무');
      },
    );
  });

  group('C0 exact-level game defaults', () {
    testWidgets('chosung selects the persisted B1 level, not its A1 default', (
      tester,
    ) async {
      await _setStoredLevel('b1');
      await tester.runAsync(DataLoader.loadVocab);

      await tester.pumpWidget(_screenApp(const ChosungQuizScreen()));
      await _pumpUntil(tester, find.byType(SoriChromeRow));
      await tester.tap(find.byKey(const Key('chosung-level-selector')));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('sori-level-sheet-B1')),
      );

      expect(
        tester
            .widget<SoriChip>(find.byKey(const ValueKey('sori-level-sheet-B1')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<SoriChip>(find.byKey(const ValueKey('sori-level-sheet-A1')))
            .selected,
        isFalse,
      );
    });

    testWidgets('chosung wraps all level chips on a narrow scaled layout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _setStoredLevel('c2');
      await tester.runAsync(DataLoader.loadVocab);

      await tester.pumpWidget(
        _screenApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: const ChosungQuizScreen(),
            ),
          ),
        ),
      );
      await _pumpUntil(tester, find.byType(SoriChromeRow));
      await tester.tap(find.byKey(const Key('chosung-level-selector')));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('sori-level-sheet-C2')),
      );

      expect(tester.takeException(), isNull);
      final chipTops = <double>{
        for (final level in const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
          tester.getTopLeft(find.byKey(ValueKey('sori-level-sheet-$level'))).dy,
      };
      expect(chipTops.length, greaterThan(1));
    });

    testWidgets('silben selects the persisted B2 level, not its A1 default', (
      tester,
    ) async {
      await _setStoredLevel('b2');
      await tester.runAsync(SilbenPuzzleLoader.load);

      await tester.pumpWidget(_screenApp(const SilbenKreuzScreen()));
      await _pumpUntil(tester, find.byType(SoriChromeRow));
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('sori-level-sheet-B2')),
      );

      expect(
        tester
            .widget<SoriChip>(find.byKey(const ValueKey('sori-level-sheet-B2')))
            .selected,
        isTrue,
      );
    });

    testWidgets(
      'silben keeps cell semantics and a non-motion wrong cue at reduced motion',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _setStoredLevel('a1');
        final puzzles = await tester.runAsync(SilbenPuzzleLoader.load);
        final puzzle = puzzles!['A1']!.first;
        final cell = puzzle.solution.keys.first;
        final answer = puzzle.solution[cell]!;
        final wrongTile = puzzle.pool.firstWhere((tile) => tile != answer);

        await tester.pumpWidget(
          _screenApp(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(2),
                ),
                child: const SilbenKreuzScreen(),
              ),
            ),
          ),
        );
        await _pumpUntil(tester, find.byType(SoriChromeRow));

        expect(find.textContaining('A1 ·'), findsOneWidget);
        final cellFinder = find.byKey(
          ValueKey('silben-cell-${cell.$1}-${cell.$2}'),
        );
        final cellSemantics = tester.widget<Semantics>(cellFinder);
        expect(
          cellSemantics.properties.label,
          contains('Row ${cell.$1 + 1}, column ${cell.$2 + 1}'),
        );
        expect(cellSemantics.properties.label, contains('Words:'));
        expect(cellSemantics.properties.label, endsWith('Open.'));
        await tester.ensureVisible(cellFinder);
        await tester.tap(cellFinder);
        await tester.ensureVisible(find.bySemanticsLabel(wrongTile).first);
        expect(
          tester.getSize(find.bySemanticsLabel(wrongTile).first),
          const Size(46, 46),
        );
        await tester.tap(find.bySemanticsLabel(wrongTile).first);
        await tester.pump();

        expect(
          tester.widget<Semantics>(cellFinder).properties.label,
          endsWith('Incorrect.'),
        );

        final levelChrome = find.byType(SoriChromeRow);
        // §B2(2026-09-03): the frame's own leading close action now also
        // renders Icons.close_rounded, so this must scope to the cell that
        // actually shows the wrong-answer cue.
        expect(
          find.descendant(
            of: cellFinder,
            matching: find.byIcon(Icons.close_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.byType(TweenAnimationBuilder<double>),
          findsNothing,
          reason: '오답은 아이콘으로 남고 흔들림은 모션 감소에서 없어야 한다.',
        );
        expect(tester.takeException(), isNull);
        expect(levelChrome, findsOneWidget);

        await tester.pump(const Duration(milliseconds: 700));
        semantics.dispose();
      },
    );
  });
}

Future<void> _setStoredLevel(String level) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'kl_user_level': level,
    'kl_tut_chosung': true,
    'kl_tut_silben_kreuz': true,
  });
  await Storage.init();
}

Widget _screenApp(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var index = 0; index < attempts; index++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}
