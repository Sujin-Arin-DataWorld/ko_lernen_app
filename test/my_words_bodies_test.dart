import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/my_words_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';

const _savedWord = ExtractedWord(
  korean: '사랑',
  romanization: 'sarang',
  posDe: 'Nomen',
  translationDe: 'Liebe',
  translationEn: 'love',
  translationLanguage: 'en',
  exampleKorean: '',
  exampleDe: '',
  savedToPackId: null,
);

const _hardWord = Vocab(
  id: 'my-words-body-hard',
  korean: '그리움',
  romanization: 'geurium',
  german: 'Sehnsucht',
  english: 'longing',
  level: 'B2',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_custom_packs_v1': '{}',
      'kl_tut_bookshelf': true,
      'kl_tut_hardWords': true,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: 'my-words-body-pack',
        name: 'Meine Testwörter',
        words: const <ExtractedWord>[_savedWord],
      ),
    );
    for (var attempt = 0; attempt < 3; attempt += 1) {
      await Storage.incrementWrongCount(_hardWord.korean);
    }
  });

  testWidgets(
    'public word-tool bodies embed in one supplied TabBarView without route chrome',
    (tester) async {
      await tester.pumpWidget(
        _host(
          DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'Search'),
                  Tab(text: 'Shelf'),
                  Tab(text: 'Difficult'),
                ],
              ),
              body: TabBarView(
                children: <Widget>[
                  const WordbookSearchBody(),
                  const BookshelfBody(),
                  HardWordsBody(
                    deckLoader: () async => const <Vocab>[_hardWord],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SoriStandardFrame), findsNothing);
      expect(find.text(_savedWord.korean), findsOneWidget);

      await tester.tap(find.text('Shelf'));
      await tester.pumpAndSettle();
      expect(find.text('Meine Testwörter'), findsOneWidget);
      expect(find.byType(SoriStandardFrame), findsNothing);

      await tester.tap(find.text('Difficult'));
      await tester.pumpAndSettle();
      expect(find.text(_hardWord.korean), findsOneWidget);
      expect(find.byType(SoriStandardFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved-word pages retain search and filters when the keyboard opens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await CustomPackService.save(
        CustomPack.manual(
          id: 'my-words-body-pack',
          name: 'Viele Wörter',
          words: [
            for (var index = 1; index <= 20; index++)
              ExtractedWord(
                korean: '연습 $index',
                romanization: '',
                posDe: 'Nomen',
                translationDe: 'Lernkarte $index',
                translationEn: '',
                exampleKorean: '',
                exampleDe: '',
                savedToPackId: null,
              ),
          ],
        ),
      );
      await tester.pumpWidget(_host(const MyWordsScreen()));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MyWordsScreen));
      final nextLabel = MaterialLocalizations.of(context).nextPageTooltip;
      final next = find.byTooltip(nextLabel).hitTestable();
      expect(find.text('연습 1').hitTestable(), findsOneWidget);
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('연습 1').hitTestable(), findsNothing);

      final field = find.byType(TextField).hitTestable();
      await tester.tap(field);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Lernkarte 20');
      await tester.pumpAndSettle();
      expect(find.text('연습 20').hitTestable(), findsOneWidget);
      expect(
        find.byTooltip(AppL10n.of(context).filterOpenBtn).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Regal actions remain reachable on subsequent pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (var index = 0; index < 8; index++) {
      await CustomPackService.save(
        CustomPack.manual(
          id: 'shelf-pack-$index',
          name: 'Wortliste $index',
          words: const [_savedWord],
        ),
      );
    }
    await tester.pumpWidget(
      _host(const MyWordsScreen(initialTab: MyWordsTab.shelf), textScale: 2),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(BookshelfBody));
    final t = AppL10n.of(context);
    final next = find
        .byTooltip(MaterialLocalizations.of(context).nextPageTooltip)
        .hitTestable();
    expect(next, findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.byTooltip(t.createWordbookCta).hitTestable(), findsOneWidget);
    expect(find.byTooltip(t.redeemTooltip).hitTestable(), findsOneWidget);
    expect(find.byTooltip(t.studyLibraryRefresh).hitTestable(), findsOneWidget);
    final practice = find
        .byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              (widget.tooltip?.startsWith('${t.btnPlay}: ') ?? false),
        )
        .hitTestable();
    expect(practice, findsWidgets);
    expect(
      tester.getSize(practice.first).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schwierig keeps both practice buttons in the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final words = [
      for (var index = 1; index <= 12; index++)
        Vocab(
          id: 'difficult-word-$index',
          korean: '반복 $index',
          romanization: '',
          german: 'Wiederholung $index',
          english: '',
          level: 'B2',
          posDe: 'Nomen',
          exampleKorean: '',
          exampleGerman: '',
          topic: 'test',
        ),
    ];
    for (final word in words) {
      for (var attempt = 0; attempt < 3; attempt++) {
        await Storage.incrementWrongCount(word.korean);
      }
    }
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: HardWordsBody(paged: true, deckLoader: () async => words),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HardWordsBody));
    final t = AppL10n.of(context);
    final next = find
        .byTooltip(MaterialLocalizations.of(context).nextPageTooltip)
        .hitTestable();
    expect(next, findsOneWidget);
    for (final label in [t.hardWordsHardQuizCta, t.hardWordsStudyCta]) {
      expect(
        find.widgetWithText(SoriButton, label).hitTestable(),
        findsOneWidget,
      );
    }
    await tester.tap(next);
    await tester.pumpAndSettle();
    for (final label in [t.hardWordsHardQuizCta, t.hardWordsStudyCta]) {
      expect(
        find.widgetWithText(SoriButton, label).hitTestable(),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved words show their actual source examples and canonical tabs',
    (tester) async {
      final size = const bool.fromEnvironment('CAPTURE_402')
          ? const Size(402, 874)
          : const Size(430, 932);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final examples = [
        ('경험', 'Erfahrung', '그게 저한테는 정말 좋은 경험이었어요.'),
        ('문화', 'Kultur', '한국 문화가 정말 매력적이에요.'),
        ('목표', 'Ziel / Vorhaben', '올해 목표는 한국어 자격증 따는 거예요.'),
      ];
      await CustomPackService.save(
        CustomPack.manual(
          id: 'my-words-body-pack',
          name: 'Meine Testwörter',
          words: [
            for (final (ko, de, example) in examples)
              ExtractedWord(
                korean: ko,
                romanization: '',
                posDe: '',
                translationDe: de,
                translationEn: '',
                exampleKorean: example,
                exampleDe: '',
                savedToPackId: null,
              ),
          ],
        ),
      );
      const key = ValueKey('my-words-capture');
      await tester.pumpWidget(
        _host(const RepaintBoundary(key: key, child: MyWordsScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text(examples.first.$3).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sori-image-navigation-bar')),
        findsOneWidget,
      );
      const output = String.fromEnvironment('MY_WORDS_CAPTURE_DIR');
      if (output.isNotEmpty) {
        final context = tester.element(find.byType(MyWordsScreen));
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('design_assets/scenarios/open-book.png'),
            context,
          ),
        );
        await settleCNativeCaptureAssets(tester);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        boundary.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await File(
            '$output/native-meine-woerter.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}

Widget _host(Widget child, {double textScale = 1}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: SoriTypeScale(child: appChild!),
    ),
    home: child,
  );
}
