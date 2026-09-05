import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'support/sori_speech_stubs.dart';

const _horizontal = SilbenWord(
  dir: 'h',
  row: 1,
  col: 0,
  answer: '가나다',
  german: 'across',
  exampleKo: '◯◯◯를 읽어요.',
  exampleDe: 'Read across.',
);

const _vertical = SilbenWord(
  dir: 'v',
  row: 0,
  col: 1,
  answer: '차나마',
  german: 'down',
  exampleKo: '◯◯◯를 읽어요.',
  exampleDe: 'Read down.',
);

const _secondVertical = SilbenWord(
  dir: 'v',
  row: 1,
  col: 2,
  answer: '다라',
  german: 'second down',
  exampleKo: '◯◯를 읽어요.',
  exampleDe: 'Read the second down word.',
);

const _puzzle = SilbenPuzzle(
  id: 'grid-clue-sync',
  rows: 3,
  cols: 3,
  words: [_horizontal, _vertical, _secondVertical],
  pool: ['가', '나', '다', '차', '마', '라', '끝'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoriSpeechStub speechStub;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_silben_kreuz': true});
    await Storage.init();
    speechStub = stubSoriSpeech();
  });

  testWidgets(
    'cell and clue selection stay synchronized with deterministic crossings',
    (tester) async {
      await _pumpPuzzle(tester);

      final horizontalClue = find.byKey(const ValueKey('silben-clue-0'));
      final verticalClue = find.byKey(const ValueKey('silben-clue-1'));
      final secondVerticalClue = find.byKey(const ValueKey('silben-clue-2'));

      await _tapVisible(tester, horizontalClue);
      _expectSelectedClue(tester, horizontalClue);
      _expectSelectedCell(tester, row: 1, col: 0);

      await tester.tap(find.byKey(const ValueKey('silben-cell-1-1')));
      await tester.pumpAndSettle();
      _expectSelectedClue(tester, horizontalClue);
      _expectSelectedCell(tester, row: 1, col: 1);

      await _tapVisible(tester, verticalClue);
      _expectSelectedClue(tester, verticalClue);
      _expectSelectedCell(tester, row: 0, col: 1);

      await _tapVisible(tester, find.bySemanticsLabel('차'));
      await _tapVisible(tester, horizontalClue);
      await _tapVisible(tester, verticalClue);
      _expectSelectedClue(tester, verticalClue);
      _expectSelectedCell(tester, row: 1, col: 1);

      await _tapVisible(tester, secondVerticalClue);
      _expectSelectedClue(tester, secondVerticalClue);
      _expectSelectedCell(tester, row: 1, col: 2);

      // The current word does not contain the main crossing, so declared
      // puzzle order chooses the horizontal word before the vertical word.
      await tester.tap(find.byKey(const ValueKey('silben-cell-1-1')));
      await tester.pumpAndSettle();
      _expectSelectedClue(tester, horizontalClue);
    },
  );

  testWidgets(
    'crossings expose both direction wedges without pointer capture',
    (tester) async {
      await _pumpPuzzle(tester);

      final markerFinder = find.byKey(
        const ValueKey('silben-crossing-wedges-1-1'),
      );
      final marker = tester.widget<SilbenCrossingWedges>(markerFinder);

      expect(marker.directions, orderedEquals(['h', 'v']));
      expect(
        find.descendant(of: markerFinder, matching: find.byType(IgnorePointer)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cell semantics announce position memberships active word and state',
    (tester) async {
      await _pumpPuzzle(tester);

      final horizontalClue = find.byKey(const ValueKey('silben-clue-0'));
      await _tapVisible(tester, horizontalClue);
      await tester.tap(find.byKey(const ValueKey('silben-cell-1-1')));
      await tester.pumpAndSettle();

      expect(
        _semanticsLabel(tester, row: 1, col: 1),
        'Row 2, column 2. Words: Horizontal: across; Vertical: down. '
        'Active word: across. Open.',
      );

      await _tapVisible(tester, find.bySemanticsLabel('끝'));
      expect(_semanticsLabel(tester, row: 1, col: 1), endsWith('Incorrect.'));

      await _tapVisible(tester, find.byKey(const ValueKey('silben-clue-1')));
      await _tapVisible(tester, find.bySemanticsLabel('차'));
      expect(_semanticsLabel(tester, row: 0, col: 1), endsWith('Correct.'));
    },
  );

  testWidgets('selected cell and active lane expose distinct surface states', (
    tester,
  ) async {
    await _pumpPuzzle(tester);
    await _tapVisible(tester, find.byKey(const ValueKey('silben-clue-0')));

    final selected = _cellDecoration(tester, row: 1, col: 0);
    final activeLane = _cellDecoration(tester, row: 1, col: 1);
    final inactive = _cellDecoration(tester, row: 0, col: 1);

    expect((selected.border! as Border).top.width, 2);
    expect(selected.color, SoriColors.info.withValues(alpha: 0.10));
    expect(activeLane.color, SoriColors.info.withValues(alpha: 0.06));
    expect(inactive.color, isNot(SoriColors.info.withValues(alpha: 0.06)));
  });

  testWidgets(
    'completing a word surfaces the clue-card speak indicator at its top-left',
    (tester) async {
      await _pumpPuzzle(tester);

      expect(
        find.byType(SoriSpeechIndicator),
        findsNothing,
        reason: '완성된 단어가 없으면 단서 카드에 인디케이터가 없어야 한다',
      );

      final horizontalClue = find.byKey(const ValueKey('silben-clue-0'));
      await _tapVisible(tester, horizontalClue);
      await _tapVisible(tester, find.bySemanticsLabel('가'));
      await _tapVisible(tester, find.bySemanticsLabel('나'));
      await _tapVisible(tester, find.bySemanticsLabel('다'));

      // T1(1.7/2.9) — 단어 완성 자동 발화(_onTileTap)와 같은 텍스트 규칙
      // (exampleKo 있으면 답+예문)으로 마지막 완성 단어를 가리킨다.
      expect(speechStub.spoken, ['가나다. 가나다를 읽어요.']);

      final indicator = find.byKey(const Key('silben-clue-speak'));
      expect(indicator, findsOneWidget);
      expect(
        tester.widget<SoriSpeechIndicator>(indicator).text,
        '가나다. 가나다를 읽어요.',
      );

      final localStack = find
          .ancestor(of: indicator, matching: find.byType(Stack))
          .first;
      final cardFinder = find.descendant(
        of: localStack,
        matching: find.byType(SoriCard),
      );
      final cardRect = tester.getRect(cardFinder);
      final indicatorRect = tester.getRect(indicator);
      expect(indicatorRect.left - cardRect.left, inInclusiveRange(-1.0, 24.0));
      expect(indicatorRect.top - cardRect.top, inInclusiveRange(-1.0, 24.0));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(720, 1024)]) {
    testWidgets(
      'synchronized puzzle stays usable at ${size.width.toInt()} px',
      (tester) async {
        await _pumpPuzzle(tester, size: size);
        await _tapVisible(tester, find.byKey(const ValueKey('silben-clue-0')));

        expect(
          find.byKey(const ValueKey('silben-crossing-wedges-1-1')),
          findsOneWidget,
        );
        _expectSelectedCell(tester, row: 1, col: 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpPuzzle(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: SilbenKreuzScreen(
        puzzleLoader: () async => const {
          'A1': [_puzzle],
        },
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const ValueKey('silben-cell-1-1')).evaluate().isNotEmpty) {
      break;
    }
  }
  expect(find.byKey(const ValueKey('silben-cell-1-1')), findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _expectSelectedCell(
  WidgetTester tester, {
  required int row,
  required int col,
}) {
  final semantics = tester.widget<Semantics>(
    find.byKey(ValueKey('silben-cell-$row-$col')),
  );
  expect(semantics.properties.selected, isTrue);
}

void _expectSelectedClue(WidgetTester tester, Finder finder) {
  final semantics = tester.widget<Semantics>(finder);
  expect(semantics.properties.selected, isTrue);
}

String _semanticsLabel(
  WidgetTester tester, {
  required int row,
  required int col,
}) => tester
    .widget<Semantics>(find.byKey(ValueKey('silben-cell-$row-$col')))
    .properties
    .label!;

BoxDecoration _cellDecoration(
  WidgetTester tester, {
  required int row,
  required int col,
}) =>
    tester
            .widget<AnimatedContainer>(
              find.byKey(ValueKey('silben-cell-surface-$row-$col')),
            )
            .decoration!
        as BoxDecoration;
