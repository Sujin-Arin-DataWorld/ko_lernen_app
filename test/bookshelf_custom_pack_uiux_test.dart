import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/bookshelf_page_screen.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_edit_screen.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/shared_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _pageId = 'uiux-bookshelf-page';
const _packId = 'uiux-custom-pack';
const _packName =
    'A complete personal Korean vocabulary pack for travel and conversations';
const _word = ExtractedWord(
  korean: '사랑',
  romanization: 'sarang',
  posDe: 'Nomen',
  translationDe: 'a detailed meaning that remains fully readable',
  translationEn: 'love',
  translationLanguage: 'en',
  exampleKorean: '사랑은 오래 참아요.',
  exampleDe: 'Love is patient.',
  savedToPackId: null,
);
const _page = BookPage(
  id: _pageId,
  localThumbnailPath: null,
  extractedText: '사랑은 오래 참아요. 안녕하세요. 반갑습니다. 한국어를 함께 공부해요.',
  note: 'Conversation notes',
  words: <ExtractedWord>[_word],
  grammar: <GrammarHit>[
    GrammarHit(
      patternId: 'g_topic',
      nameDe: 'Topic marker',
      matchedText: '사랑은',
      level: 'A1',
      explanationDe: 'Marks the topic.',
    ),
  ],
  sentences: <TranslatedSentence>[
    TranslatedSentence(
      korean: '안녕하세요.',
      translationDe: 'Hello.',
      translationLanguage: 'en',
    ),
  ],
  capturedAtIso: '2026-08-22T00:00:00.000Z',
  customPackId: _packId,
  analysisLanguage: 'en',
);

CustomPack get _pack => CustomPack.manual(
  id: _packId,
  name: _packName,
  words: const <ExtractedWord>[_word],
  createdAt: DateTime.utc(2026, 8, 22),
);

CustomPack _packWithWordCount(int count) => CustomPack.manual(
  id: 'uiux-custom-pack-$count',
  name: 'Threshold pack $count',
  words: List<ExtractedWord>.generate(
    count,
    (index) => index == 0
        ? _word
        : _word.copyWithEditable(
            korean: '단어$index',
            translationDe: 'Detailed meaning $index',
            translationEn: 'English meaning $index',
          ),
  ),
  createdAt: DateTime.utc(2026, 8, 22),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_bookshelf_v1': '{}',
      'kl_custom_packs_v1': '{}',
      'kl_tut_bookshelf': true,
      'kl_tut_cpEdit': true,
    });
    await Storage.init();
    await BookshelfService.save(_page);
    await CustomPackService.save(_pack);
  });

  testWidgets(
    'bookshelf, saved page, and pack editor stay reachable in the locked DE/EN matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        for (final viewport in viewports) {
          await _pumpScreen(
            tester,
            const BookshelfScreen(),
            locale: locale,
            size: viewport.size,
            textScale: viewport.textScale,
          );
          expect(find.text(t.bookshelfTitle), findsWidgets);
          await _scrollTo(tester, find.text(_packName));
          await _scrollTo(tester, find.textContaining('사랑은 오래'));
          expect(tester.takeException(), isNull);

          await _pumpScreen(
            tester,
            const BookshelfPageScreen(pageId: _pageId),
            locale: locale,
            size: viewport.size,
            textScale: viewport.textScale,
          );
          expect(find.text(t.bookshelfPageTitle), findsWidgets);
          await _scrollTo(tester, find.text('사랑'));
          await _scrollTo(tester, find.text('안녕하세요.'));
          expect(tester.takeException(), isNull);

          await _pumpScreen(
            tester,
            const CustomPackEditScreen(packId: _packId),
            locale: locale,
            size: viewport.size,
            textScale: viewport.textScale,
          );
          expect(find.text(_packName), findsOneWidget);
          await _scrollTo(
            tester,
            find.text(_word.translationFor(locale.languageCode)),
          );
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('saved-page and pack-row actions expose final 48dp semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('en');
    final t = lookupAppL10n(locale);

    await _pumpScreen(
      tester,
      const BookshelfPageScreen(pageId: _pageId),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _expectEnabledSemantics(tester, '${t.ttsListen}: 사랑');
    await _expectEnabledSemantics(tester, '${t.ttsListen}: 안녕하세요.');

    await _pumpScreen(
      tester,
      const CustomPackEditScreen(packId: _packId),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _scrollTo(
      tester,
      find.text(_word.translationFor(locale.languageCode)),
    );
    await _expectEnabledSemantics(tester, '${t.wbEditWordTitle}: 사랑');
    await _expectEnabledSemantics(tester, '${t.ttsListen}: 사랑');
    await _expectEnabledSemantics(tester, '${t.btnDelete}: 사랑');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'cards keep one interactive owner and mode actions keep one primary hierarchy',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const locale = Locale('en');
      final t = lookupAppL10n(locale);
      final secondPack = _packWithWordCount(2);
      await CustomPackService.save(secondPack);

      await _pumpScreen(
        tester,
        const BookshelfScreen(),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );
      final packCard = find.ancestor(
        of: find.text(_packName),
        matching: find.byType(SoriCard),
      );
      expect(packCard, findsOneWidget);
      expect(tester.widget<SoriCard>(packCard).onTap, isNull);
      for (final pack in <CustomPack>[_pack, secondPack]) {
        await _scrollTo(tester, find.text(pack.displayName()));
        _expectStaticSemantics(
          tester,
          '${pack.displayName()}. ${t.bookshelfPackMeta(pack.totalWords)} · '
          '${t.bookshelfPackLearnedMeta(0, pack.totalWords)}',
        );
        for (final action in <String>[
          t.btnPlay,
          t.wbEditTooltip,
          t.shareTooltip,
          t.btnDelete,
        ]) {
          await _expectActionSemantics(
            tester,
            '$action: ${pack.displayName()}',
          );
        }
      }

      final fourWordPack = _packWithWordCount(4);
      await CustomPackService.save(fourWordPack);
      await _pumpScreen(
        tester,
        CustomPackEditScreen(packId: fourWordPack.id),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );
      expect(
        tester.widget<SoriButton>(_soriButton(t.wbAddWord)).variant,
        SoriButtonVariant.filled,
      );
      for (final label in <String>[
        t.wbStudyCards,
        t.wbMatching,
        t.wbTyping,
        t.wbQuiz,
        t.vocabNotebookNuanceCta,
        t.vocabNotebookStudioCta,
      ]) {
        final action = _soriButton(label);
        await tester.ensureVisible(action);
        await tester.pump();
        expect(
          tester.widget<SoriButton>(action).variant,
          SoriButtonVariant.outlined,
        );
        _expectOutlinedBoundaryContrast(tester, action);
      }

      for (final word in fourWordPack.words.take(2)) {
        await _scrollTo(
          tester,
          find.text(word.translationFor(locale.languageCode)),
        );
        final wordCard = find.ancestor(
          of: find.text(word.translationFor(locale.languageCode)),
          matching: find.byType(SoriCard),
        );
        expect(wordCard, findsOneWidget);
        expect(tester.widget<SoriCard>(wordCard).onTap, isNull);
        _expectStaticSemantics(
          tester,
          '${word.korean}. ${word.translationFor(locale.languageCode)}',
        );
        await _expectActionSemantics(
          tester,
          '${t.wbEditWordTitle}: ${word.korean}',
        );
        await _expectActionSemantics(tester, '${t.ttsListen}: ${word.korean}');
        await _expectActionSemantics(tester, '${t.btnDelete}: ${word.korean}');
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('0, 1, 2, and 4 words preserve every exact mode threshold', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('de');
    final t = lookupAppL10n(locale);
    const thresholds =
        <
          ({
            int count,
            bool play,
            bool matching,
            bool typing,
            bool quiz,
            bool nuance,
            bool studio,
          })
        >[
          (
            count: 0,
            play: false,
            matching: false,
            typing: false,
            quiz: false,
            nuance: false,
            studio: false,
          ),
          (
            count: 1,
            play: true,
            matching: false,
            typing: true,
            quiz: false,
            nuance: false,
            studio: true,
          ),
          (
            count: 2,
            play: true,
            matching: true,
            typing: true,
            quiz: false,
            nuance: true,
            studio: true,
          ),
          (
            count: 4,
            play: true,
            matching: true,
            typing: true,
            quiz: true,
            nuance: true,
            studio: true,
          ),
        ];

    for (final threshold in thresholds) {
      final pack = _packWithWordCount(threshold.count);
      await CustomPackService.save(pack);
      await _pumpScreen(
        tester,
        CustomPackEditScreen(packId: pack.id),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );

      _expectModeEnabled(tester, t.wbStudyCards, enabled: threshold.play);
      _expectModeEnabled(tester, t.wbMatching, enabled: threshold.matching);
      _expectModeEnabled(tester, t.wbTyping, enabled: threshold.typing);
      _expectModeEnabled(tester, t.wbQuiz, enabled: threshold.quiz);
      _expectModeEnabled(
        tester,
        t.vocabNotebookNuanceCta,
        enabled: threshold.nuance,
      );
      _expectModeEnabled(
        tester,
        t.vocabNotebookStudioCta,
        enabled: threshold.studio,
      );
      _expectModeEnabled(tester, t.vocabNotebookAddPhoto, enabled: true);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets(
    'bookshelf and editor preserve exact named routes and arguments',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const locale = Locale('en');
      final t = lookupAppL10n(locale);
      final pushedRoutes = <RouteSettings>[];

      await _pumpScreen(
        tester,
        const BookshelfScreen(),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
        pushedRoutes: pushedRoutes,
      );
      await _tapAndExpectRoute(
        tester,
        find.byTooltip(t.wbSearchTitle),
        pushedRoutes,
        name: '/wordbook/search',
      );
      await _tapAndExpectRoute(
        tester,
        find.byTooltip(t.bookshelfAddPage),
        pushedRoutes,
        name: '/book',
      );
      await _tapAndExpectRoute(
        tester,
        find.byWidgetPredicate(
          (widget) => widget is SoriButton && widget.label == t.btnPlay,
        ),
        pushedRoutes,
        name: '/custom_pack/play',
        arguments: _packId,
      );
      await _tapAndExpectRoute(
        tester,
        find.byTooltip('${t.wbEditTooltip}: $_packName'),
        pushedRoutes,
        name: '/custom_pack/edit',
        arguments: _packId,
      );
      // The custom-pack tile now carries a second "learned" line (Task 5),
      // so the page card below it can sit outside the initial cache extent.
      await _scrollTo(tester, find.textContaining('사랑은 오래 참아요'));
      await _tapAndExpectRoute(
        tester,
        find.textContaining('사랑은 오래 참아요'),
        pushedRoutes,
        name: '/bookshelf/page',
        arguments: _pageId,
      );

      final fourWordPack = _packWithWordCount(4);
      await CustomPackService.save(fourWordPack);
      await _pumpScreen(
        tester,
        CustomPackEditScreen(packId: fourWordPack.id),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
        pushedRoutes: pushedRoutes,
      );
      final destinations = <({String label, String route, Object? arguments})>[
        (
          label: t.wbStudyCards,
          route: '/custom_pack/play',
          arguments: fourWordPack.id,
        ),
        (
          label: t.wbMatching,
          route: '/custom_pack/matching',
          arguments: fourWordPack.id,
        ),
        (
          label: t.wbTyping,
          route: '/custom_pack/typing',
          arguments: fourWordPack.id,
        ),
        (
          label: t.wbQuiz,
          route: '/custom_pack/quiz',
          arguments: fourWordPack.id,
        ),
        (
          label: t.vocabNotebookNuanceCta,
          route: '/vocab_notebook/nuance',
          arguments: fourWordPack.id,
        ),
        (
          label: t.vocabNotebookStudioCta,
          route: '/vocab_notebook/studio',
          arguments: fourWordPack.id,
        ),
        (
          label: t.vocabNotebookAddPhoto,
          route: '/vocab_notebook',
          arguments: <String, dynamic>{'existingPackId': fourWordPack.id},
        ),
      ];
      for (final destination in destinations) {
        await _tapAndExpectRoute(
          tester,
          find.byWidgetPredicate(
            (widget) =>
                widget is SoriButton && widget.label == destination.label,
          ),
          pushedRoutes,
          name: destination.route,
          arguments: destination.arguments,
        );
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'name and CSV dialogs own standard fields and survive dismissal',
    (tester) async {
      _resetViewAfterTest(tester);
      const locale = Locale('de');
      final t = lookupAppL10n(locale);

      await _pumpScreen(
        tester,
        const BookshelfScreen(),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.tap(find.byTooltip(t.createWordbookCta));
      await tester.pumpAndSettle();
      expect(find.byType(SoriTextField), findsOneWidget);
      _expectMaterialActionHeight(tester, t.btnCancel);
      _expectMaterialActionHeight(tester, t.btnConfirm);
      await tester.tap(find.text(t.btnCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _pumpScreen(
        tester,
        const BookshelfPageScreen(pageId: _pageId),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await _scrollTo(tester, find.text(t.bookshelfCreatePackCta));
      await tester.tap(find.text(t.bookshelfCreatePackCta));
      await tester.pumpAndSettle();
      final pageName = tester.widget<SoriTextField>(find.byType(SoriTextField));
      expect(pageName.controller?.text, 'Conversation notes');
      await tester.tap(find.text(t.btnCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _pumpScreen(
        tester,
        const CustomPackEditScreen(packId: _packId),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.tap(find.byTooltip(t.wbRenameTitle));
      await tester.pumpAndSettle();
      expect(find.byType(SoriTextField), findsOneWidget);
      await tester.tap(find.text(t.btnCancel));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(t.csvImportTitle));
      await tester.pumpAndSettle();
      expect(find.byType(SoriTextField), findsOneWidget);
      await tester.tap(find.text(t.btnCancel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'share and redeem expose live progress, error, retry, and success',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const locale = Locale('en');
      final t = lookupAppL10n(locale);
      final firstShare = Completer<String>();
      var shareCalls = 0;

      Future<String> generateCode(CustomPack _) {
        shareCalls += 1;
        if (shareCalls == 1) return firstShare.future;
        return Future<String>.value('ABC234');
      }

      await _pumpScreen(
        tester,
        BookshelfScreen(shareCodeGenerator: generateCode),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );
      final shareLabel = '${t.shareTooltip}: $_packName';
      await _scrollTo(tester, find.byTooltip(shareLabel));
      await tester.tap(find.byTooltip(shareLabel));
      await tester.pumpAndSettle();
      expect(find.byType(AppLoading), findsOneWidget);
      _expectLiveSemantics(tester, t.shareGenerating);

      firstShare.completeError(
        const SharedPackException(SharedPackError.network),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppError), findsOneWidget);
      _expectLiveSemantics(tester, t.shareError);
      await tester.ensureVisible(find.text(t.btnRetry));
      await tester.pump();
      await tester.tap(find.text(t.btnRetry));
      await tester.pumpAndSettle();
      expect(find.text('ABC234'), findsOneWidget);
      _expectLiveSemantics(tester, '${t.shareCodeLabel}: ABC234');
      expect(shareCalls, 2);

      final redeemCompleter = Completer<CustomPack>();
      await _pumpScreen(
        tester,
        BookshelfScreen(sharedPackRedeemer: (_) => redeemCompleter.future),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );
      await tester.tap(find.byTooltip(t.redeemTooltip));
      await tester.pumpAndSettle();
      final codeField = tester.widget<SoriTextField>(
        find.byType(SoriTextField),
      );
      expect(codeField.maxLength, 6);
      await tester.enterText(find.byType(SoriTextField), 'ABC234');
      await tester.tap(find.text(t.redeemAction));
      await tester.pump();
      _expectLiveSemantics(tester, t.redeemLoading);
      redeemCompleter.complete(_pack);
      await tester.pumpAndSettle();
      expect(find.text(t.redeemTitle), findsNothing);
      _expectLiveSemantics(
        tester,
        t.redeemSuccess(_pack.displayName(), _pack.totalWords),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'missing saved page and missing pack use the shared empty state',
    (tester) async {
      _resetViewAfterTest(tester);
      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        await _pumpScreen(
          tester,
          const BookshelfPageScreen(pageId: 'missing'),
          locale: locale,
          size: const Size(320, 640),
          textScale: 2,
        );
        expect(find.byType(SoriEmptyState), findsOneWidget);
        expect(find.text(t.bookshelfPageNotFoundTitle), findsOneWidget);

        await _pumpScreen(
          tester,
          const CustomPackEditScreen(packId: 'missing'),
          locale: locale,
          size: const Size(320, 640),
          textScale: 2,
        );
        expect(find.byType(SoriEmptyState), findsOneWidget);
        expect(find.text(t.customPackNotFoundTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('word editor announces validation and keeps listen action 48dp', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('de');
    final t = lookupAppL10n(locale);
    await _pumpScreen(
      tester,
      const CustomPackEditScreen(packId: _packId),
      locale: locale,
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.tap(find.text(t.wbAddWord));
    await tester.pumpAndSettle();
    expect(find.byType(SoriTextField), findsNWidgets(3));
    _expectDisabledSemantics(tester, t.ttsListen);
    await tester.enterText(find.byType(SoriTextField).first, '사랑');
    await tester.pump();
    await _expectEnabledSemantics(tester, '${t.ttsListen}: 사랑');
    await tester.enterText(find.byType(SoriTextField).first, '');
    await tester.pump();
    final autoFill = _soriButton(t.wbAutoFill);
    await tester.ensureVisible(autoFill);
    await tester.pump();
    await tester.tap(autoFill);
    await tester.pump();
    _expectLiveSemantics(tester, t.wbNeedKorean);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget home, {
  required Locale locale,
  required Size size,
  required double textScale,
  List<RouteSettings>? pushedRoutes,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(
    MaterialApp(
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
        child: SoriTypeScale(child: child!),
      ),
      navigatorObservers: pushedRoutes == null
          ? const <NavigatorObserver>[]
          : <NavigatorObserver>[_RouteRecorder(pushedRoutes)],
      onGenerateRoute: pushedRoutes == null
          ? null
          : (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Route target')),
            ),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump();
  pushedRoutes?.clear();
}

class _RouteRecorder extends NavigatorObserver {
  _RouteRecorder(this.routes);

  final List<RouteSettings> routes;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route.settings);
    super.didPush(route, previousRoute);
  }
}

Future<void> _tapAndExpectRoute(
  WidgetTester tester,
  Finder action,
  List<RouteSettings> pushedRoutes, {
  required String name,
  Object? arguments,
}) async {
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.pump();
  pushedRoutes.clear();
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(pushedRoutes, isNotEmpty);
  expect(pushedRoutes.last.name, name);
  expect(pushedRoutes.last.arguments, arguments);
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

void _resetViewAfterTest(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pump();
  }
  expect(finder, findsWidgets);
  await tester.scrollUntilVisible(finder, 260, scrollable: scrollable);
  await tester.pump();
}

Future<void> _expectEnabledSemantics(WidgetTester tester, String label) async {
  final icon = find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == label,
  );
  expect(icon, findsOneWidget);
  await tester.scrollUntilVisible(
    icon,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

Future<void> _expectActionSemantics(WidgetTester tester, String label) async {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectStaticSemantics(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
}

void _expectDisabledSemantics(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
}

Finder _soriButton(String label) => find.byWidgetPredicate(
  (widget) => widget is SoriButton && widget.label == label,
);

void _expectOutlinedBoundaryContrast(WidgetTester tester, Finder action) {
  final decorated = find.descendant(
    of: action,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
  expect(decorated, findsOneWidget);
  final box = tester.widget<Container>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final renderedBorder = Color.alphaBlend(border.top.color, SoriColors.lightBg);
  expect(
    SoriColors.contrastRatio(renderedBorder, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}

void _expectModeEnabled(
  WidgetTester tester,
  String label, {
  required bool enabled,
}) {
  final button = find.byWidgetPredicate(
    (widget) => widget is SoriButton && widget.label == label,
  );
  expect(button, findsOneWidget);
  expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  expect(tester.widget<SoriButton>(button).onTap, enabled ? isNotNull : isNull);
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(
    data.flagsCollection.isEnabled,
    enabled ? ui.Tristate.isTrue : ui.Tristate.isFalse,
  );
  expect(data.hasAction(ui.SemanticsAction.tap), enabled);
}

void _expectMaterialActionHeight(WidgetTester tester, String label) {
  final action = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is TextButton || widget is FilledButton,
    ),
  );
  expect(action, findsOneWidget);
  expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
}

void _expectLiveSemantics(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isLiveRegion, isTrue);
}
