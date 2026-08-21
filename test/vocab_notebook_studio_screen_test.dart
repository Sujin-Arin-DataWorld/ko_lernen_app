import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_corpus_resolver.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('game buttons follow the words the learner keeps', (
    tester,
  ) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-studio',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
          ExtractedWord.manual(korean: '학생', translationDe: 'Schüler'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-studio'),
      ),
    );
    await tester.pump();

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Spiel aus diesen Wörtern bauen'), findsNothing);
    expect(find.text('Mein Wortspiel'), findsOneWidget);

    var cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Keine'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Alle nehmen'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);
  });

  testWidgets('duplicate Korean rows toggle independently', (tester) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-dup',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '시간', translationDe: 'Zeit'),
          ExtractedWord.manual(korean: '시간', translationDe: 'Stunde'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-dup'),
      ),
    );
    await tester.pump();

    expect(find.text('시간'), findsNWidgets(2));
    final firstCard = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(SoriCard),
      ),
    );
    expect(firstCard.accent, SoriColors.primary);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pump();

    final afterFirst = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(SoriCard),
      ),
    );
    final afterSecond = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-1')),
        matching: find.byType(SoriCard),
      ),
    );
    expect(afterFirst.accent, SoriColors.info);
    expect(afterSecond.accent, SoriColors.primary);
  });

  testWidgets('loader failure is not shown as no sentences', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-fail',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
          ExtractedWord.manual(korean: '친구', translationDe: 'Freund'),
        ],
      ),
    );

    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(
          packId: 'nb-fail',
          corpusLoader: (_) async {
            loads += 1;
            return const CustomPackCorpusLoadResult(
              match: CustomPackCorpusMatch.empty,
              failedSources: <String>['cloze'],
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.',
      ),
      findsNothing,
    );

    final speed = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Speed Match · 2 Wörter'),
    );
    expect(speed.onTap, isNotNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Erneut versuchen'));
    await tester.pump();
    await tester.pump();
    expect(loads, 2);
  });

  testWidgets('empty corpus after a good load is a real miss', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-empty',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '번데기', translationDe: 'Puppe'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(
          packId: 'nb-empty',
          corpusLoader: (_) async => const CustomPackCorpusLoadResult(
            match: CustomPackCorpusMatch.empty,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.',
      ),
      findsNothing,
    );
  });

  testWidgets('loading is live and leaves own-meaning games available', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());
    final load = Completer<CustomPackCorpusLoadResult>();

    await _pumpStudio(
      tester,
      key: const ValueKey('loading'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      corpusLoader: (_) => load.future,
    );

    final loadingText = find.text('Loading available games…');
    await _makeStudioHitTestable(tester, loadingText);
    expect(find.byType(AppLoading), findsOneWidget);
    expect(
      tester
          .getSemantics(loadingText)
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    final cards = find.widgetWithText(SoriButton, 'Study cards');
    await _makeStudioHitTestable(tester, cards);
    expect(tester.widget<SoriButton>(cards).onTap, isNotNull);

    load.complete(
      const CustomPackCorpusLoadResult(match: CustomPackCorpusMatch.empty),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppLoading), findsNothing);
    final noCorpus = find.text(
      'We do not have a ready sentence for these words yet. '
      'Use your own meanings above.',
    );
    await _makeStudioHitTestable(tester, noCorpus);
    expect(
      tester
          .getSemantics(noCorpus)
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets(
    'DE and EN layouts keep controls reachable in the locked matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await CustomPackService.save(_pack());
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];
      const cases =
          <
            ({
              Locale locale,
              String title,
              String all,
              String none,
              String drop,
            })
          >[
            (
              locale: Locale('de'),
              title: 'Mein Wortspiel',
              all: 'Alle nehmen',
              none: 'Keine',
              drop: 'Wort weglassen',
            ),
            (
              locale: Locale('en'),
              title: 'My word game',
              all: 'Take all',
              none: 'None',
              drop: 'Leave this word out',
            ),
          ];

      for (final testCase in cases) {
        for (final viewport in viewports) {
          await _pumpStudio(
            tester,
            key: ValueKey(
              'matrix-${testCase.locale.languageCode}-'
              '${viewport.size}-${viewport.textScale}',
            ),
            locale: testCase.locale,
            size: viewport.size,
            textScale: viewport.textScale,
            corpusLoader: (_) async => const CustomPackCorpusLoadResult(
              match: CustomPackCorpusMatch.empty,
            ),
          );
          await tester.pump();

          expect(find.byType(SoriStandardPage), findsOneWidget);
          expect(find.text(testCase.title), findsOneWidget);
          for (final label in [testCase.all, testCase.none]) {
            final action = find.widgetWithText(SoriButton, label);
            await _makeStudioHitTestable(tester, action);
            _expectEnabledButton(tester, action, label);
          }

          final toggle = find.byKey(
            const ValueKey<String>('notebook-word-toggle-0'),
          );
          await _makeStudioHitTestable(tester, toggle);
          expect(tester.getSize(toggle).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
          final toggleData = tester.getSemantics(toggle).getSemanticsData();
          expect(toggleData.label, testCase.drop);
          expect(toggleData.flagsCollection.isButton, isTrue);
          expect(toggleData.flagsCollection.isSelected, Tristate.isTrue);
          expect(toggleData.hasAction(SemanticsAction.tap), isTrue);

          final corpusState = find.byIcon(Icons.info_outline_rounded);
          await _makeStudioHitTestable(tester, corpusState);
          expect(corpusState, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('missing packs use the standard frame in DE and EN', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const cases = <({Locale locale, String title, String body})>[
      (
        locale: Locale('de'),
        title: 'Paket nicht gefunden',
        body: 'Möglicherweise wurde es gelöscht.',
      ),
      (
        locale: Locale('en'),
        title: 'Pack not found',
        body: 'It may have been deleted.',
      ),
    ];

    for (final testCase in cases) {
      await _pumpStudio(
        tester,
        key: ValueKey('missing-${testCase.locale.languageCode}'),
        locale: testCase.locale,
        size: const Size(320, 640),
        textScale: 2,
        packId: 'missing',
      );

      expect(find.byType(SoriStandardFrame), findsOneWidget);
      expect(find.text(testCase.title), findsOneWidget);
      expect(find.text(testCase.body), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('semantic word activation keeps duplicate rows independent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-semantic-duplicates',
        name: 'Duplicates',
        words: <ExtractedWord>[
          ExtractedWord.manual(
            korean: '시간',
            translationDe: 'Zeit',
            translationEn: 'time',
          ),
          ExtractedWord.manual(
            korean: '시간',
            translationDe: 'Stunde',
            translationEn: 'hour',
          ),
        ],
      ),
    );
    await _pumpStudio(
      tester,
      key: const ValueKey('semantic-duplicates'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      packId: 'nb-semantic-duplicates',
      corpusLoader: (_) async =>
          const CustomPackCorpusLoadResult(match: CustomPackCorpusMatch.empty),
    );

    final first = find.byKey(const ValueKey<String>('notebook-word-toggle-0'));
    await _makeStudioHitTestable(tester, first);
    final node = tester.getSemantics(first);
    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => candidate.id == node.id),
    );
    await tester.pump();

    final firstData = tester.getSemantics(first).getSemanticsData();
    final secondData = tester
        .getSemantics(
          find.byKey(const ValueKey<String>('notebook-word-toggle-1')),
        )
        .getSemanticsData();
    expect(firstData.label, 'Keep this word');
    expect(firstData.flagsCollection.isSelected, Tristate.isFalse);
    expect(secondData.label, 'Leave this word out');
    expect(secondData.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('own and corpus destinations receive the exact selected subset', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());
    const cloze = ClozeItem(
      id: 'studio-cloze',
      level: 'a1',
      sentenceKo: '나는 ＿＿＿에 가요.',
      answer: '학교',
      fullKo: '나는 학교에 가요.',
      de: 'Ich gehe zur Schule.',
      en: 'I go to school.',
      distractors: <String>['집', '가게'],
    );
    await _pumpStudio(
      tester,
      key: const ValueKey('destinations'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      corpusLoader: (_) async => const CustomPackCorpusLoadResult(
        match: CustomPackCorpusMatch(
          cloze: <ClozeItem>[cloze],
          satz: <SatzSentence>[],
          vocab: <Vocab>[],
        ),
      ),
    );
    await tester.pump();

    final dropped = find.byKey(
      const ValueKey<String>('notebook-word-toggle-1'),
    );
    await _makeStudioHitTestable(tester, dropped);
    await tester.tap(dropped);
    await tester.pump();

    final cards = find.widgetWithText(SoriButton, 'Study cards');
    await _makeStudioHitTestable(tester, cards);
    await tester.tap(cards);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final play = tester.widget<CustomPackPlayScreen>(
      find.byType(CustomPackPlayScreen),
    );
    expect(play.packId, 'nb-studio-matrix');
    expect(play.words!.map((word) => word.korean), <String>['학교', '시작', '개시']);

    await _pumpStudio(
      tester,
      key: const ValueKey('corpus-destination'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      corpusLoader: (_) async => const CustomPackCorpusLoadResult(
        match: CustomPackCorpusMatch(
          cloze: <ClozeItem>[cloze],
          satz: <SatzSentence>[],
          vocab: <Vocab>[],
        ),
      ),
    );
    await tester.pump();

    final clozeAction = find.widgetWithText(SoriButton, 'Cloze · 1 sentence');
    await _makeStudioHitTestable(tester, clozeAction);
    await tester.tap(clozeAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final clozeScreen = tester.widget<ClozeGameScreen>(
      find.byType(ClozeGameScreen),
    );
    expect(clozeScreen.items, <ClozeItem>[cloze]);
  });
}

const _safeInsets = EdgeInsets.only(top: 24, bottom: 16);

CustomPack _pack() => CustomPack.manual(
  id: 'nb-studio-matrix',
  name: 'Notebook words',
  words: <ExtractedWord>[
    ExtractedWord.manual(
      korean: '학교',
      translationDe: 'Schule',
      translationEn: 'school',
    ),
    ExtractedWord.manual(
      korean: '학생',
      translationDe: 'Schüler',
      translationEn: 'student',
    ),
    ExtractedWord.manual(
      korean: '시작',
      translationDe: 'Anfang',
      translationEn: 'start',
    ),
    ExtractedWord.manual(
      korean: '개시',
      translationDe: 'Beginn',
      translationEn: 'commencement',
    ),
  ],
);

Future<void> _pumpStudio(
  WidgetTester tester, {
  required Key key,
  required Locale locale,
  required Size size,
  required double textScale,
  String packId = 'nb-studio-matrix',
  Future<CustomPackCorpusLoadResult> Function(CustomPack pack)? corpusLoader,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey<Key>(key),
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: _safeInsets,
          viewPadding: _safeInsets,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: VocabNotebookStudioScreen(
        key: key,
        packId: packId,
        corpusLoader: corpusLoader,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _makeStudioHitTestable(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: find.byType(SoriStandardPage),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(0);
    await tester.pump();
    for (
      var attempt = 0;
      target.evaluate().isEmpty && attempt < 40;
      attempt++
    ) {
      if (position.pixels >= position.maxScrollExtent) {
        break;
      }
      position.jumpTo(
        (position.pixels + 160).clamp(0, position.maxScrollExtent),
      );
      await tester.pump();
    }
    expect(target, findsOneWidget);
    if (target.hitTestable().evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
      await tester.pump();
    }
  }
  expect(target.hitTestable(), findsOneWidget);
}

void _expectEnabledButton(WidgetTester tester, Finder action, String label) {
  expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(action).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, Tristate.isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}
