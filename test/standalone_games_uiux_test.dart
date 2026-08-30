import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
late ByteData _assetManifest;

const _viewports = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

const _vocab = <Vocab>[
  Vocab(
    korean: '가방',
    romanization: 'gabang',
    german: 'Schultasche',
    english: 'school bag',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '가방이 있어요.',
    exampleGerman: 'Da ist eine Tasche.',
    topic: 'test',
  ),
  Vocab(
    korean: '나무',
    romanization: 'namu',
    german: 'großer Baum',
    english: 'large tree',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '나무가 커요.',
    exampleGerman: 'Der Baum ist groß.',
    topic: 'test',
  ),
  Vocab(
    korean: '다리',
    romanization: 'dari',
    german: 'lange Brücke',
    english: 'long bridge',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '다리를 건너요.',
    exampleGerman: 'Ich überquere die Brücke.',
    topic: 'test',
  ),
  Vocab(
    korean: '라디오',
    romanization: 'radio',
    german: 'kleines Radio',
    english: 'small radio',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '라디오를 들어요.',
    exampleGerman: 'Ich höre Radio.',
    topic: 'test',
  ),
];

const _mixedLevelVocab = <Vocab>[
  ..._vocab,
  Vocab(
    korean: '마음',
    romanization: 'maeum',
    german: 'Gefühl',
    english: 'feeling',
    level: 'B1',
    posDe: 'Nomen',
    exampleKorean: '마음이 편해요.',
    exampleGerman: 'Ich fühle mich wohl.',
    topic: 'test',
  ),
  Vocab(
    korean: '바라다',
    romanization: 'barada',
    german: 'hoffen',
    english: 'to hope',
    level: 'B1',
    posDe: 'Verb',
    exampleKorean: '잘되기를 바라요.',
    exampleGerman: 'Ich hoffe, dass es gut geht.',
    topic: 'test',
  ),
];

const _chainWords = <KkeunmariWord>[
  KkeunmariWord(
    word: '가나',
    first: '가',
    last: '나',
    level: 'A1',
    german: 'Ghana',
    topic: 'test',
    nextCount: 1,
    isDeadEnd: false,
  ),
  KkeunmariWord(
    word: '나다',
    first: '나',
    last: '다',
    level: 'A1',
    german: 'entstehen',
    topic: 'test',
    nextCount: 1,
    isDeadEnd: false,
  ),
  KkeunmariWord(
    word: '다가',
    first: '다',
    last: '가',
    level: 'A1',
    german: 'während',
    topic: 'test',
    nextCount: 1,
    isDeadEnd: false,
  ),
];

const _puzzle = SilbenPuzzle(
  id: 'uiux-a1',
  rows: 1,
  cols: 2,
  words: [
    SilbenWord(
      dir: 'h',
      row: 0,
      col: 0,
      answer: '가나',
      german: 'Ghana',
      exampleKo: '◯◯에 가요.',
      exampleDe: 'Ich fahre nach Ghana.',
    ),
  ],
  pool: ['가', '나', '다'],
);

const _puzzle2 = SilbenPuzzle(
  id: 'uiux-a1-next',
  rows: 1,
  cols: 2,
  words: [
    SilbenWord(
      dir: 'h',
      row: 0,
      col: 0,
      answer: '가나',
      german: 'Ghana',
      exampleKo: '◯◯에 가요.',
      exampleDe: 'Ich fahre nach Ghana.',
    ),
  ],
  pool: ['가', '나', '다'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _assetManifest = await rootBundle.load('AssetManifest.bin');
  });

  setUp(() async {
    Storage.resetForTesting();
    DataLoader.reset();
    KkeunmariEngine.reset();
    SilbenPuzzleLoader.reset();
    SharedPreferences.setMockInitialValues({
      'kl_tut_chosung': true,
      'kl_tut_kkeunmari': true,
      'kl_tut_silben_kreuz': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  tearDown(() {
    DataLoader.reset();
    KkeunmariEngine.reset();
    SilbenPuzzleLoader.reset();
  });

  testWidgets('timed games protect home escape only while the round is live', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      KkeunmariScreen(poolLoader: () async => _chainWords),
      locale: const Locale('de'),
      textScale: 1,
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(_homeEscape(tester).confirmWhen, isTrue);
    await tester.pump(const Duration(seconds: 31));
    expect(_homeEscape(tester).confirmWhen, isFalse);

    await _pumpPhone(
      tester,
      const SpeedMatchScreen(items: _vocab),
      locale: const Locale('en'),
      textScale: 1,
    );
    await _pumpUntil(tester, find.byKey(const ValueKey('speed-match-left-가방')));
    expect(_homeEscape(tester).confirmWhen, isTrue);
    await tester.pump(const Duration(seconds: 61));
    expect(_homeEscape(tester).confirmWhen, isFalse);
  });

  testWidgets('Speed Match defaults a fresh learner to A1, never all levels', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      SpeedMatchScreen(vocabLoader: () async => _mixedLevelVocab),
      locale: const Locale('en'),
      textScale: 1,
    );
    await _pumpUntil(tester, find.byType(SoriChromeRow));

    expect(find.text('A1 · 4'), findsOneWidget);
    expect(find.text('All levels · 6'), findsNothing);
  });

  testWidgets('Speed Match honors the shared browse-level precedence', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      Storage.browseLevelPreferenceKey: 'b1',
      'kl_user_level': 'a1',
      'kl_tut_wordbook': true,
    });
    await Storage.init();

    await _pumpPhone(
      tester,
      SpeedMatchScreen(vocabLoader: () async => _mixedLevelVocab),
      locale: const Locale('en'),
      textScale: 1,
    );
    await _pumpUntil(tester, find.byType(SoriChromeRow));

    expect(find.text('B1 · 2'), findsOneWidget);
    expect(find.text('A1 · 4'), findsNothing);
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in _viewports) {
      testWidgets('standalone games keep complete outer UI in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        final games = <({String name, Widget screen, Finder ready})>[
          (
            name: 'kkeunmari',
            screen: KkeunmariScreen(poolLoader: () async => _chainWords),
            ready: find.byType(SoriTextField),
          ),
          (
            name: 'chosung',
            screen: const ChosungQuizScreen(deck: _vocab),
            ready: find.byType(SoriTextField),
          ),
          (
            name: 'silben',
            screen: SilbenKreuzScreen(
              puzzleLoader: () async => const {
                'A1': [_puzzle],
              },
            ),
            ready: find.byType(SoriChromeRow),
          ),
          (
            name: 'speed',
            screen: const SpeedMatchScreen(items: _vocab),
            ready: find.byKey(const ValueKey('speed-match-left-가방')),
          ),
        ];

        for (final game in games) {
          await _pumpGame(
            tester,
            game.screen,
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, game.ready);

          expect(game.ready, findsOneWidget, reason: game.name);
          expect(find.byType(SoriStudyFrame), findsOneWidget);
          expect(
            find.byType(SoriHomeAction),
            findsOneWidget,
            reason: game.name,
          );
          final media = MediaQuery.of(
            tester.element(find.byType(SoriStudyFrame)),
          );
          final expectedScale =
              viewport.textScale * soriComfortScale(viewport.size.width);
          expect(
            media.textScaler.scale(16) / 16,
            closeTo(expectedScale, 0.001),
            reason: '${game.name} must compose OS and comfort scale',
          );

          final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
          if (game.name == 'speed') {
            expect(find.byIcon(Icons.close), findsOneWidget, reason: game.name);
          } else if (game.name == 'chosung' || game.name == 'silben') {
            expect(
              find.byIcon(Icons.arrow_back_ios_new),
              findsOneWidget,
              reason: game.name,
            );
          }
          if (game.name == 'chosung' && locale.languageCode == 'en') {
            expect(
              _vocab
                  .where(
                    (word) => find.text(word.english).evaluate().isNotEmpty,
                  )
                  .length,
              1,
            );
            for (final word in _vocab) {
              expect(find.text(word.german), findsNothing);
            }
          }
          final target = switch (game.name) {
            'kkeunmari' => find.bySemanticsLabel(t.kkeunmariSubmit),
            'chosung' => find.bySemanticsLabel(t.chosungSubmitBtn),
            'silben' => find.bySemanticsLabel('가'),
            'speed' => find.byKey(const ValueKey('speed-match-left-가방')),
            _ => throw StateError(game.name),
          };
          await tester.ensureVisible(target.first);
          await tester.pump();
          expect(target, findsWidgets, reason: game.name);
          await _tapWithFatalHitTest(tester, target.first);
          expect(tester.takeException(), isNull, reason: game.name);
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 250));
      });
    }
  }

  testWidgets('Kkeunmari separates loading, error, retry, and true empty', (
    tester,
  ) async {
    final first = Completer<List<KkeunmariWord>>();
    final second = Completer<List<KkeunmariWord>>();
    var calls = 0;
    Future<List<KkeunmariWord>> loader() {
      calls += 1;
      return calls == 1 ? first.future : second.future;
    }

    await _pumpPhone(
      tester,
      KkeunmariScreen(poolLoader: loader),
      locale: const Locale('de'),
    );
    final t = lookupAppL10n(const Locale('de'));
    _expectLiveLoading(tester, t.gameLoading);

    first.completeError(StateError('offline'));
    await _pumpUntil(tester, find.byType(AppError));
    _expectLiveError(tester, t.loadErrorTryAgain);
    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    _expectLiveLoading(tester, t.gameLoading);
    second.complete(_chainWords);
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(calls, 2);
    expect(find.byType(AppError), findsNothing);

    await _pumpPhone(
      tester,
      KkeunmariScreen(poolLoader: () async => const []),
      locale: const Locale('de'),
    );
    await _pumpUntil(tester, find.byType(SoriEmptyState));
    expect(find.text(t.kkeunmariEmptyBody), findsOneWidget);
    expect(find.byType(AppError), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('Chosung separates loading, error, retry, and true empty', (
    tester,
  ) async {
    final first = Completer<List<Vocab>>();
    final second = Completer<List<Vocab>>();
    var calls = 0;
    Future<List<Vocab>> loader() {
      calls += 1;
      return calls == 1 ? first.future : second.future;
    }

    await _pumpPhone(
      tester,
      ChosungQuizScreen(vocabLoader: loader),
      locale: const Locale('en'),
    );
    final t = lookupAppL10n(const Locale('en'));
    _expectLiveLoading(tester, t.gameLoading);

    first.completeError(StateError('offline'));
    await _pumpUntil(tester, find.byType(AppError));
    _expectLiveError(tester, t.loadErrorTryAgain);
    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    _expectLiveLoading(tester, t.gameLoading);
    second.complete(_vocab);
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(calls, 2);

    await _pumpPhone(
      tester,
      const ChosungQuizScreen(deck: []),
      locale: const Locale('en'),
    );
    await _pumpUntil(tester, find.byType(SoriEmptyState));
    expect(find.text(t.chosungEmptyBody), findsOneWidget);
    expect(find.byType(AppError), findsNothing);
  });

  testWidgets('Silben separates loading, error, retry, and true empty', (
    tester,
  ) async {
    final first = Completer<Map<String, List<SilbenPuzzle>>>();
    final second = Completer<Map<String, List<SilbenPuzzle>>>();
    var calls = 0;
    Future<Map<String, List<SilbenPuzzle>>> loader() {
      calls += 1;
      return calls == 1 ? first.future : second.future;
    }

    await _pumpPhone(
      tester,
      SilbenKreuzScreen(puzzleLoader: loader),
      locale: const Locale('de'),
    );
    final t = lookupAppL10n(const Locale('de'));
    _expectLiveLoading(tester, t.gameLoading);

    first.completeError(StateError('offline'));
    await _pumpUntil(tester, find.byType(AppError));
    _expectLiveError(tester, t.loadErrorTryAgain);
    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    _expectLiveLoading(tester, t.gameLoading);
    second.complete(const {
      'A1': [_puzzle],
    });
    await _pumpUntil(tester, find.byType(SoriChromeRow));
    expect(calls, 2);

    await _pumpPhone(
      tester,
      SilbenKreuzScreen(puzzleLoader: () async => const {}),
      locale: const Locale('de'),
    );
    await _pumpUntil(tester, find.byType(SoriEmptyState));
    expect(find.text(t.silbenEmptyBody), findsOneWidget);
    expect(find.byType(AppError), findsNothing);
  });

  testWidgets('Speed Match separates loading, error, retry, and true empty', (
    tester,
  ) async {
    final first = Completer<List<Vocab>>();
    final second = Completer<List<Vocab>>();
    var calls = 0;
    Future<List<Vocab>> loader() {
      calls += 1;
      return calls == 1 ? first.future : second.future;
    }

    await _pumpPhone(
      tester,
      SpeedMatchScreen(vocabLoader: loader),
      locale: const Locale('en'),
    );
    final t = lookupAppL10n(const Locale('en'));
    _expectLiveLoading(tester, t.gameLoading);

    first.completeError(StateError('offline'));
    await _pumpUntil(tester, find.byType(AppError));
    _expectLiveError(tester, t.loadErrorTryAgain);
    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    _expectLiveLoading(tester, t.gameLoading);
    second.complete(_vocab);
    await _pumpUntil(tester, find.byKey(const ValueKey('speed-match-left-가방')));
    expect(calls, 2);

    await _pumpPhone(
      tester,
      const SpeedMatchScreen(items: []),
      locale: const Locale('en'),
    );
    await _pumpUntil(tester, find.byType(SoriEmptyState));
    expect(find.text(t.speedMatchEmptyBody), findsOneWidget);
    expect(find.byType(AppError), findsNothing);
  });

  testWidgets('production cached vocabulary failure performs a second read', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var vocabReads = 0;
    rootBundle.clear();
    ByteData bytes(String raw) =>
        ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message)!;
      if (key == 'AssetManifest.bin') {
        return _assetManifest;
      }
      if (key == 'assets/data/grammar.csv') {
        return bytes(
          'pattern,level,type_de,explanation_de,example_korean,'
          'example_german,note\n은/는,A1,Partikel,Erklärung,저는 학생이에요.,'
          'Ich bin Student.,Hinweis\n',
        );
      }
      if (key == 'assets/data/media_phrases.json') {
        return bytes(
          jsonEncode({
            'phrases': [
              {
                'id': 'media-test',
                'level': 'A1',
                'korean': '괜찮아',
                'german': 'Alles gut.',
                'english': 'It is okay.',
                'source_type': 'drama',
                'source_style': 'test',
              },
            ],
          }),
        );
      }
      if (key != 'assets/data/korean_vocab.csv') {
        return null;
      }
      vocabReads += 1;
      if (vocabReads == 1) {
        throw StateError('first read fails');
      }
      const csv =
          'korean,romanization,german,level,pos_de,example_korean,'
          'example_german,topic,pack_id,pack_order,is_review_boss,english,'
          'pos_en,example_english,id\n'
          '가방,gabang,Tasche,A1,Nomen,가방이 있어요.,Da ist eine Tasche.,'
          'test,a1_test,1,false,bag,Noun,There is a bag.,test_a1_1\n';
      return bytes(csv);
    });
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.clear();
    });
    final grammar = await DataLoader.loadGrammar();
    final media = await DataLoader.loadMediaPhrases();

    await _pumpPhone(
      tester,
      const ChosungQuizScreen(),
      locale: const Locale('en'),
    );
    await _pumpUntil(tester, find.byType(AppError));
    final t = lookupAppL10n(const Locale('en'));
    expect(vocabReads, 1);
    expect(DataLoader.vocabError, isNotNull);

    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(vocabReads, 2);
    expect(DataLoader.vocabError, isNull);
    expect(identical(await DataLoader.loadGrammar(), grammar), isTrue);
    expect(identical(await DataLoader.loadMediaPhrases(), media), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('production cached word-chain failure performs a second read', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var poolReads = 0;
    rootBundle.clear();
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message)!;
      if (key == 'AssetManifest.bin') {
        return _assetManifest;
      }
      if (key != 'assets/data/kkeunmari_pool.json') {
        return null;
      }
      poolReads += 1;
      final raw = poolReads == 1
          ? '{'
          : jsonEncode({
              'words': [
                for (final word in _chainWords)
                  {
                    'word': word.word,
                    'first': word.first,
                    'last': word.last,
                    'level': word.level,
                    'german': word.german,
                    'topic': word.topic,
                    'next_count': word.nextCount,
                    'is_dead_end': word.isDeadEnd,
                  },
              ],
            });
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
    });
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.clear();
    });

    await _pumpPhone(
      tester,
      const KkeunmariScreen(),
      locale: const Locale('de'),
    );
    await _pumpUntil(tester, find.byType(AppError));
    final t = lookupAppL10n(const Locale('de'));
    expect(poolReads, 1);
    expect(KkeunmariEngine.lastError, isNotNull);

    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(poolReads, 2);
    expect(KkeunmariEngine.lastError, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('production cached syllable failure performs a second read', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var puzzleReads = 0;
    rootBundle.clear();
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message)!;
      if (key == 'AssetManifest.bin') {
        return _assetManifest;
      }
      if (key != 'assets/data/silben_puzzles.json') {
        return null;
      }
      puzzleReads += 1;
      final raw = puzzleReads == 1
          ? '{'
          : jsonEncode({
              'levels': {
                'A1': [
                  {
                    'id': _puzzle.id,
                    'rows': _puzzle.rows,
                    'cols': _puzzle.cols,
                    'words': [
                      for (final word in _puzzle.words)
                        {
                          'dir': word.dir,
                          'row': word.row,
                          'col': word.col,
                          'answer': word.answer,
                          'german': word.german,
                          'exampleKo': word.exampleKo,
                          'exampleDe': word.exampleDe,
                        },
                    ],
                    'pool': _puzzle.pool,
                  },
                ],
              },
            });
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
    });
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.clear();
    });

    await _pumpPhone(
      tester,
      const SilbenKreuzScreen(),
      locale: const Locale('de'),
    );
    await _pumpUntil(tester, find.byType(AppError));
    final t = lookupAppL10n(const Locale('de'));
    expect(puzzleReads, 1);

    await _tapVisible(tester, find.bySemanticsLabel(t.btnRetry));
    await _pumpUntil(tester, find.byType(SoriChromeRow));
    expect(puzzleReads, 2);
    expect(find.byType(AppError), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('standalone game assistive targets expose meaning and actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpPhone(
      tester,
      KkeunmariScreen(poolLoader: () async => _chainWords),
      locale: const Locale('de'),
      textScale: 1.3,
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    final de = lookupAppL10n(const Locale('de'));
    final listen = _chainWords
        .map((word) => find.bySemanticsLabel(de.ttsListenTarget(word.word)))
        .singleWhere((finder) => finder.evaluate().isNotEmpty);
    _expectButton(tester, listen, minHeight: 48);

    await _pumpPhone(
      tester,
      const ChosungQuizScreen(deck: _vocab),
      locale: const Locale('en'),
      textScale: 1.3,
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    final en = lookupAppL10n(const Locale('en'));
    final roundStatus = tester
        .getSemantics(find.byKey(const ValueKey('chosung-round-status')))
        .getSemanticsData()
        .label;
    expect(roundStatus, contains(en.chosungCorrectCount(0)));
    expect(roundStatus, contains(en.chosungWrongCount(0)));
    expect(roundStatus, contains(en.gameRoundProgress(1, 10)));
    _expectButton(tester, find.bySemanticsLabel(en.chosungBackspace));
    _expectButton(tester, find.bySemanticsLabel(en.filterLevel), minHeight: 48);
    final chosungLevelButton = find.byKey(const Key('chosung-level-selector'));
    // Autofocus can scroll the input into view after the chrome row is laid
    // out. Let that scroll finish, then reveal and fatally hit-test the chrome
    // control so a late focus scroll cannot move it back under the app bar.
    await tester.pumpAndSettle();
    await _tapVisibleFatal(tester, chosungLevelButton);
    await _pumpUntil(tester, find.byKey(const ValueKey('sori-level-sheet-A1')));
    _expectSelectedDisabledChoice(
      tester,
      find.byKey(const ValueKey('sori-level-sheet-A1')),
      minHeight: 48,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _tapVisibleFatal(
      tester,
      find.byKey(const Key('chosung-mode-selector')),
    );
    await _pumpUntil(tester, find.byKey(const Key('chosung-mode-with-vowels')));
    final selectedMode = find.byKey(const Key('chosung-mode-with-vowels'));
    _expectButton(
      tester,
      selectedMode,
      minHeight: 48,
      selected: ui.Tristate.isTrue,
    );

    await _pumpPhone(
      tester,
      SilbenKreuzScreen(
        puzzleLoader: () async => const {
          'A1': [_puzzle],
        },
      ),
      locale: const Locale('de'),
      textScale: 1.3,
    );
    final clue = find.bySemanticsLabel('Ghana. Ich fahre nach Ghana. ◯◯에 가요.');
    await _pumpUntil(tester, clue);
    _expectButton(tester, clue);
    _expectButton(tester, find.bySemanticsLabel(de.filterLevel), minHeight: 48);
    final silbenLevelButton = find.byIcon(Icons.tune_rounded);
    await tester.ensureVisible(silbenLevelButton);
    await tester.tap(silbenLevelButton);
    await _pumpUntil(tester, find.byKey(const ValueKey('sori-level-sheet-A1')));
    _expectSelectedDisabledChoice(
      tester,
      find.byKey(const ValueKey('sori-level-sheet-A1')),
      minHeight: 48,
    );
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    _expectButton(tester, find.byKey(const ValueKey('silben-cell-0-0')));
    final syllableTile = find.bySemanticsLabel('가');
    _expectButton(tester, syllableTile);
    expect(tester.getSize(syllableTile), const Size(46, 46));

    await _pumpPhone(
      tester,
      SpeedMatchScreen(vocabLoader: () async => _vocab),
      locale: const Locale('en'),
      textScale: 1.3,
    );
    final tile = find.bySemanticsLabel('가방');
    await _pumpUntil(tester, tile);
    _expectButton(tester, tile, minHeight: 44);
    expect(find.bySemanticsLabel(en.speedMatchInstruction), findsOneWidget);
    _expectButton(tester, find.bySemanticsLabel(en.filterLevel), minHeight: 48);
    final speedLevelButton = find.byIcon(Icons.tune_rounded);
    await tester.ensureVisible(speedLevelButton);
    await tester.tap(speedLevelButton);
    final defaultLevel = find.byKey(const ValueKey('sori-level-sheet-a1'));
    await _pumpUntil(tester, defaultLevel);
    _expectSelectedDisabledChoice(tester, defaultLevel, minHeight: 48);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));
    semantics.dispose();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      'standalone game feedback and results stay announced and actionable in '
      '${locale.languageCode}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final t = lookupAppL10n(locale);
        const viewport = (size: Size(390, 844), textScale: 1.3);

        await _pumpGame(
          tester,
          const ChosungQuizScreen(deck: _vocab),
          locale: locale,
          viewport: viewport,
        );
        await _pumpUntil(tester, find.byType(SoriTextField));
        final firstCard = _visibleVocab(tester, locale);
        if (locale.languageCode == 'en') {
          expect(find.text(firstCard.english), findsOneWidget);
          expect(find.text(firstCard.german), findsNothing);
        }
        await tester.enterText(find.byType(SoriTextField), '틀림');
        await _tapVisibleFatal(
          tester,
          find.bySemanticsLabel(t.chosungSubmitBtn),
        );
        _expectLiveRegion(
          tester,
          '${t.statsWrong}. ${t.chosungAnswerLabel(firstCard.korean)}',
        );
        _expectReducedMotion(tester);
        await tester.pump(const Duration(milliseconds: 1100));

        for (var attempt = 1; attempt < 10; attempt++) {
          final card = _visibleVocab(tester, locale);
          await tester.enterText(find.byType(SoriTextField), card.korean);
          await _tapVisibleFatal(
            tester,
            find.bySemanticsLabel(t.chosungSubmitBtn),
          );
          _expectLiveRegion(tester, t.chosungCorrect);
          await tester.pump(const Duration(milliseconds: 750));
        }
        _expectLiveRegion(tester, t.chosungRoundDoneTitle);
        _expectReducedMotion(tester);
        final continueRound = _soriButton(t.chosungRoundContinue);
        _expectButton(tester, continueRound);
        await _tapVisibleFatal(tester, continueRound);
        expect(find.byType(SoriTextField), findsOneWidget);

        await _pumpGame(
          tester,
          KkeunmariScreen(poolLoader: () async => _chainWords),
          locale: locale,
          viewport: viewport,
        );
        await _pumpUntil(tester, find.byType(SoriTextField));
        await tester.pump(const Duration(seconds: 31));
        _expectLiveRegion(
          tester,
          '${t.kkeunmariResultTitle}. ${t.kkeunmariTimeUp}',
        );
        _expectReducedMotion(tester);
        final playAgain = _soriButton(t.kkeunmariPlayAgain);
        _expectButton(tester, playAgain);
        await _tapVisibleFatal(tester, playAgain);
        await _pumpUntil(tester, find.byType(SoriTextField));
        expect(find.byType(SoriTextField), findsOneWidget);

        await _pumpGame(
          tester,
          SilbenKreuzScreen(
            puzzleLoader: () async => const {
              'A1': [_puzzle, _puzzle2],
            },
          ),
          locale: locale,
          viewport: viewport,
        );
        await _pumpUntil(tester, find.bySemanticsLabel('가'));
        await _tapVisibleFatal(tester, find.bySemanticsLabel('가'));
        await _tapVisibleFatal(tester, find.bySemanticsLabel('나'));
        _expectLiveRegion(tester, t.wordleResultWin);
        _expectReducedMotion(tester);
        final nextPuzzle = _soriButton(t.btnNext);
        _expectButton(tester, nextPuzzle);
        await _tapVisibleFatal(tester, nextPuzzle);
        final firstCell = find.byKey(const ValueKey('silben-cell-0-0'));
        await _pumpUntil(tester, firstCell);
        _expectButton(tester, firstCell);

        await _pumpGame(
          tester,
          const SpeedMatchScreen(items: _vocab),
          locale: locale,
          viewport: viewport,
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('speed-match-left-가방')),
        );
        await tester.pump(const Duration(seconds: 61));
        await _pumpUntil(tester, _liveRegionWidget(t.quizResultTitle));
        _expectLiveRegion(tester, t.quizResultTitle);
        _expectReducedMotion(tester);
        final again = _soriButton(t.quizAgain);
        _expectButton(tester, again);
        await _tapVisibleFatal(tester, again);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('speed-match-left-가방')),
        );
        expect(
          find.byKey(const ValueKey('speed-match-left-가방')),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

Future<void> _pumpGame(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required ({Size size, double textScale}) viewport,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _safeInsets,
            viewPadding: _safeInsets,
            textScaler: TextScaler.linear(viewport.textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: screen,
    ),
  );
  await tester.pump();
}

Future<void> _pumpPhone(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  double textScale = 2,
}) => _pumpGame(
  tester,
  screen,
  locale: locale,
  viewport: (size: const Size(320, 640), textScale: textScale),
);

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Finder did not appear after $attempts pumps: $finder');
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _tapWithFatalHitTest(WidgetTester tester, Finder finder) async {
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    await tester.tap(finder);
    await tester.pump();
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  }
}

Future<void> _tapVisibleFatal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await _tapWithFatalHitTest(tester, finder);
}

Vocab _visibleVocab(WidgetTester tester, Locale locale) => _vocab.singleWhere(
  (word) =>
      find.text(word.translationFor(locale.languageCode)).evaluate().isNotEmpty,
);

Finder _liveRegionWidget(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.liveRegion == true &&
      widget.properties.label == label,
);

Finder _soriButton(String label) => find.byWidgetPredicate(
  (widget) => widget is SoriButton && widget.label == label,
);

SoriHomeEscape _homeEscape(WidgetTester tester) =>
    tester.widget<SoriHomeAction>(find.byType(SoriHomeAction)).escape;

void _expectLiveRegion(WidgetTester tester, String label) {
  final finder = _liveRegionWidget(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, contains(label));
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectReducedMotion(WidgetTester tester) {
  final context = tester.element(find.byType(SoriStudyFrame));
  expect(MediaQuery.of(context).disableAnimations, isTrue);
}

void _expectLiveLoading(WidgetTester tester, String label) {
  expect(find.byType(AppLoading), findsOneWidget);
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectLiveError(WidgetTester tester, String label) {
  expect(find.byType(AppError), findsOneWidget);
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectButton(
  WidgetTester tester,
  Finder finder, {
  double? minHeight,
  ui.Tristate? selected,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  if (selected != null) {
    expect(data.flagsCollection.isSelected, selected);
  }
  if (minHeight != null) {
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
  }
}

void _expectSelectedDisabledChoice(
  WidgetTester tester,
  Finder finder, {
  required double minHeight,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isSelected, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
}
