import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/media_phrase.dart';
import 'package:ko_lernen_app/screens/media_phrase_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _firstPhrase = MediaPhrase(
  id: 'media-uiux-first',
  level: 'A1',
  korean: '오늘 하루도 정말 수고했어요.',
  romanization: 'oneul harudo jeongmal sugohaesseoyo',
  german: 'Du hast heute wirklich viel geleistet.',
  english: 'You really did a lot today.',
  sourceType: 'original',
  sourceStyle: 'Original · ausführliches Interviewregister',
  contextDe:
      'Eine Kollegin nach einem langen, anstrengenden Arbeitstag aufmuntern',
  contextEn: 'Encouraging a colleague after a long and demanding workday',
);

const _secondPhrase = MediaPhrase(
  id: 'media-uiux-second',
  level: 'A1',
  korean: '우리 천천히 다시 이야기해 봐요.',
  romanization: 'uri cheoncheonhi dasi iyagihae bwayo',
  german: 'Lass uns langsam noch einmal darüber sprechen.',
  english: 'Let us talk about it again, slowly.',
  sourceType: 'original',
  sourceStyle: 'Original · Podcastgespräch',
  contextDe: 'Ein Missverständnis in einem ruhigen Gespräch klären',
  contextEn: 'Resolving a misunderstanding in a calm conversation',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  testWidgets('populated media phrases reflow in the locked DE/EN matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const cases = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      final expectedMeaning = locale.languageCode == 'en'
          ? _firstPhrase.english
          : _firstPhrase.german;
      final expectedContext = locale.languageCode == 'en'
          ? _firstPhrase.contextEn
          : _firstPhrase.contextDe;
      for (final testCase in cases) {
        await _pumpMedia(
          tester,
          MediaPhraseScreen(
            loader: () async => const <MediaPhrase>[
              _firstPhrase,
              _secondPhrase,
            ],
            speaker: (_) async => true,
          ),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );
        await _finishAsyncLoad(tester);

        await _scrollTo(tester, find.text(expectedMeaning));
        expect(find.text(expectedMeaning), findsOneWidget);
        expect(find.text(expectedContext), findsOneWidget);
        await _scrollTo(tester, find.text('1 / 2'));
        _expectProgressSemantics(tester, t.mediaPhraseProgress(1, 2));

        final listen = find.byKey(const ValueKey('media-phrase-listen'));
        await _scrollTo(tester, listen);
        expect(listen.hitTestable(), findsOneWidget);
        expect(tester.getSize(listen).height, greaterThanOrEqualTo(48));
        final listenData = tester.getSemantics(listen).getSemanticsData();
        expect(
          listenData.label,
          t.mediaPhraseListenTarget(_firstPhrase.korean),
        );
        expect(listenData.flagsCollection.isButton, isTrue);
        expect(listenData.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(listenData.hasAction(ui.SemanticsAction.tap), isTrue);

        final next = find.byKey(const ValueKey('media-phrase-next'));
        await _scrollTo(tester, next);
        expect(next.hitTestable(), findsOneWidget);
        expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets(
    'loading, failure, retry, and recovery are distinct live states',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        final initialLoad = Completer<List<MediaPhrase>>();
        final recovery = Completer<List<MediaPhrase>>();
        var attempts = 0;
        Future<List<MediaPhrase>> load() {
          attempts += 1;
          if (attempts == 1) {
            return initialLoad.future;
          }
          return recovery.future;
        }

        await _pumpMedia(
          tester,
          MediaPhraseScreen(loader: load, speaker: (_) async => true),
          locale: locale,
          size: const Size(320, 640),
          textScale: 2,
        );
        await _scrollTo(tester, find.byType(AppLoading));
        expect(find.byType(AppLoading), findsOneWidget);
        _expectLiveSemantics(tester, t.mediaPhraseLoading);

        initialLoad.completeError(StateError('fixture load failure'));
        await _finishAsyncLoad(tester);

        await _scrollTo(tester, find.byType(AppError));
        expect(find.byType(AppError), findsOneWidget);
        _expectLiveSemantics(tester, t.mediaPhraseUnavailable);
        final retry = find.bySemanticsLabel(t.btnRetry);
        await _scrollTo(tester, retry);
        final retryData = tester.getSemantics(retry).getSemanticsData();
        expect(retryData.flagsCollection.isButton, isTrue);
        expect(retryData.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(retryData.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));

        await tester.tap(retry);
        await tester.pump();
        expect(attempts, 2);
        expect(find.byType(AppLoading), findsOneWidget);
        _expectLiveSemantics(tester, t.mediaPhraseLoading);

        recovery.complete(const <MediaPhrase>[_firstPhrase]);
        await _finishAsyncLoad(tester);
        expect(find.byType(AppError), findsNothing);
        expect(find.text(_firstPhrase.korean), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'production-shaped cached failure retries the media asset itself',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var mediaReads = 0;
      rootBundle.clear();
      DataLoader.reset();
      messenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        final key = const StringCodec().decodeMessage(message)!;
        if (key != 'assets/data/media_phrases.json') {
          return null;
        }
        mediaReads += 1;
        final raw = mediaReads == 1
            ? '{'
            : jsonEncode(<String, Object>{
                'phrases': <Object>[
                  <String, Object>{
                    'id': _firstPhrase.id,
                    'level': _firstPhrase.level,
                    'korean': _firstPhrase.korean,
                    'romanization': _firstPhrase.romanization,
                    'german': _firstPhrase.german,
                    'english': _firstPhrase.english,
                    'source_type': _firstPhrase.sourceType,
                    'source_style': _firstPhrase.sourceStyle,
                    'context_de': _firstPhrase.contextDe,
                    'context_en': _firstPhrase.contextEn,
                  },
                ],
              });
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.clear();
        DataLoader.reset();
      });

      const locale = Locale('en');
      final t = lookupAppL10n(locale);
      await _pumpMedia(
        tester,
        MediaPhraseScreen(speaker: (_) async => true),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await _finishAsyncLoad(tester);

      await _scrollTo(tester, find.byType(AppError));
      expect(mediaReads, 1);
      expect(DataLoader.mediaPhrasesError, isNotNull);
      _expectLiveSemantics(tester, t.mediaPhraseUnavailable);

      final retry = find.bySemanticsLabel(t.btnRetry);
      await _scrollTo(tester, retry);
      await tester.tap(retry);
      await _finishAsyncLoad(tester);

      expect(mediaReads, 2);
      expect(DataLoader.mediaPhrasesError, isNull);
      expect(find.byType(AppError), findsNothing);
      await _scrollTo(tester, find.text(_firstPhrase.korean));
      expect(find.text(_firstPhrase.korean), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('true empty is not presented as a loader failure', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      await _pumpMedia(
        tester,
        MediaPhraseScreen(
          loader: () async => const <MediaPhrase>[],
          speaker: (_) async => true,
        ),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await _finishAsyncLoad(tester);

      await _scrollTo(tester, find.byType(SoriEmptyState));
      expect(find.byType(AppError), findsNothing);
      expect(
        find.widgetWithText(SoriEmptyState, t.mediaPhraseEmptyTitle),
        findsOneWidget,
      );
      expect(find.text(t.mediaPhraseEmpty), findsOneWidget);
      final close = find.widgetWithText(SoriButton, t.btnClose);
      await tester.ensureVisible(close);
      await tester.pump();
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      final closeData = tester.getSemantics(close).getSemanticsData();
      expect(closeData.flagsCollection.isButton, isTrue);
      expect(closeData.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(closeData.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets('navigation and TTS keep exact payload and final semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('de');
    final t = lookupAppL10n(locale);
    final spoken = <String>[];
    await _pumpMedia(
      tester,
      MediaPhraseScreen(
        loader: () async => const <MediaPhrase>[_firstPhrase, _secondPhrase],
        speaker: (text) async {
          spoken.add(text);
          return true;
        },
      ),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _finishAsyncLoad(tester);

    final listen = find.byKey(const ValueKey('media-phrase-listen'));
    final previous = find.byKey(const ValueKey('media-phrase-previous'));
    final next = find.byKey(const ValueKey('media-phrase-next'));
    expect(
      tester.widget<SoriButton>(listen).variant,
      SoriButtonVariant.outlined,
    );
    expect(
      tester.widget<SoriButton>(previous).variant,
      SoriButtonVariant.outlined,
    );
    expect(tester.widget<SoriButton>(next).variant, SoriButtonVariant.filled);
    _expectOutlinedBoundary(
      tester,
      listen,
      SoriCard.resolvedBackground(tester.element(listen)),
    );

    _expectActionState(tester, previous, enabled: false);
    _expectActionState(tester, next, enabled: true);
    await _scrollTo(tester, next);
    await tester.tap(next);
    await tester.pump();

    expect(find.text(_secondPhrase.korean), findsOneWidget);
    await _jumpToStart(tester);
    _expectProgressSemantics(tester, t.mediaPhraseProgress(2, 2));
    _expectActionState(tester, previous, enabled: true);
    _expectActionState(tester, next, enabled: false);
    _expectOutlinedBoundary(tester, previous, SoriColors.lightBg);

    await _scrollTo(tester, listen);
    final listenData = tester.getSemantics(listen).getSemanticsData();
    expect(listenData.label, t.mediaPhraseListenTarget(_secondPhrase.korean));
    await tester.tap(listen);
    await tester.pump();
    expect(spoken, <String>[_secondPhrase.korean]);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _pumpMedia(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
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
            textScaler: TextScaler.linear(textScale),
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

Future<void> _finishAsyncLoad(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

void _resetViewAfterTest(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets);
    await tester.drag(scrollables.first, const Offset(0, -220));
    await tester.pump();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

Future<void> _jumpToStart(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  scrollable.position.jumpTo(scrollable.position.minScrollExtent);
  await tester.pump();
}

void _expectLiveSemantics(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectProgressSemantics(WidgetTester tester, String label) {
  final data = tester
      .getSemantics(find.byKey(const ValueKey('media-phrase-progress')))
      .getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

void _expectActionState(
  WidgetTester tester,
  Finder finder, {
  required bool enabled,
}) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(
    data.flagsCollection.isEnabled,
    enabled ? ui.Tristate.isTrue : ui.Tristate.isFalse,
  );
  expect(data.hasAction(ui.SemanticsAction.tap), enabled);
}

void _expectOutlinedBoundary(
  WidgetTester tester,
  Finder button,
  Color background,
) {
  final decorated = find.descendant(
    of: button,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
  expect(decorated, findsOneWidget);
  final box = tester.widget<Container>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final rendered = Color.alphaBlend(border.top.color, background);
  expect(
    SoriColors.contrastRatio(rendered, background),
    greaterThanOrEqualTo(3),
  );
}
