import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flashcard_romanization_action.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/image_navigation_bar.dart';

import 'support/sori_speech_stubs.dart';
import 'support/real_fonts.dart';

// The Karten candidates titled Meine Wörter map to /custom_pack/play, not
// the search/shelf hub. Optional captures use a seeded review pack rendered by
// the production card screen; they do not claim device or full-mockup parity.
const _packId = 'karten-navigation-review';
const _captureDirectory = String.fromEnvironment('CAPTURE_KARTEN_NAVIGATION');
const _captureKey = ValueKey('karten-navigation-capture');
final _words = [
  for (final pair in [
    ('도서관', 'Bibliothek', 'Library'),
    ('의자', 'Stuhl', 'Chair'),
  ])
    ExtractedWord(
      korean: pair.$1,
      romanization: '',
      posDe: 'Nomen',
      translationDe: pair.$2,
      translationEn: pair.$3,
      exampleKorean: '',
      exampleDe: '',
      savedToPackId: null,
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await DataLoader.loadVocab();
  });
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpPlay': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
      'kl_snd_speech': false,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(id: _packId, name: 'Meine Wörter', words: _words),
    );
  });
  tearDown(Storage.resetForTesting);

  testWidgets('Karten reuses the exact Quiz footer without a second bar', (
    tester,
  ) async {
    await _pump(tester, const Size(402, 874));
    final navigation = find.byType(ApprovedGameNavigation);
    expect(navigation, findsOneWidget);
    expect(find.byType(SoriImageNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.getRect(navigation), const Rect.fromLTWH(0, 792, 402, 82));
    final arts = [
      'nav_heute',
      'nav_open_book',
      'nav_spiele',
      'nav_hanok',
      'nav_gye',
    ];
    final widths = [56.0, 58.0, 52.0, 56.0, 56.0];
    for (var i = 0; i < arts.length; i++) {
      final rect = tester.getRect(
        find.byWidgetPredicate((w) => w is GameArtwork && w.art == arts[i]),
      );
      expect(rect.width, widths[i]);
      expect(rect.center.dx, 47 + i * 77);
      expect(rect.center.dy, 830);
    }
    final t = AppL10n.of(tester.element(navigation));
    for (final label in _labels(t)) {
      expect(
        tester.getSize(find.byTooltip(label)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.widget<FlipCard>(find.byType(FlipCard)).flipped, isFalse);
    expect(_feed(tester).judgmentsEnabled, isFalse);
    expect(_feed(tester).onShare, isNotNull);
    expect(_feed(tester).onSkip, isNotNull);
    expect(tester.takeException(), isNull);
    if (_captureDirectory.isNotEmpty) {
      await _capture(tester, 'karten-front-footer.png');
      _feed(tester).onFlip!();
      await _settle(tester);
      await _capture(tester, 'karten-back-footer.png');
    }
  });

  testWidgets('footer stays above SafeArea with full targets at small size', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await _pump(tester, const Size(320, 640), textScale: 2);
    final navigation = find.byType(ApprovedGameNavigation);
    expect(tester.getRect(navigation), const Rect.fromLTWH(0, 524, 320, 82));
    final t = AppL10n.of(tester.element(navigation));
    for (final label in _labels(t)) {
      expect(find.byTooltip(label).hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip(label)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab visits retain card face, romanization and grading state', (
    tester,
  ) async {
    final routes = _RouteLog();
    final navigator = GlobalKey<NavigatorState>();
    await _pump(
      tester,
      const Size(402, 874),
      routes: routes,
      navigator: navigator,
    );
    final originalState = tester.state(find.byType(CustomPackPlayScreen));
    tester
        .widget<FlashcardRomanizationAction>(
          find.byType(FlashcardRomanizationAction),
        )
        .onChanged(true);
    _feed(tester).onFlip!();
    await _settle(tester);
    final navigation = find.byType(ApprovedGameNavigation);
    final labels = _labels(AppL10n.of(tester.element(navigation)));
    final pushes = routes.pushes;
    await tester.tap(find.byTooltip(labels[2]));
    expect(routes.pushes, pushes);

    for (final index in [0, 1, 3, 4]) {
      final originalRoute = routes.stack.last;
      final before = _feed(tester);
      final pushes = routes.pushes;
      await tester.tap(find.byTooltip(labels[index]));
      expect(routes.pushes, pushes + 1);
      expect(routes.stack.last, isA<MaterialPageRoute<void>>());
      expect(originalRoute.isActive, isTrue);
      expect(originalRoute.isCurrent, isFalse);
      // A queued callback from the covered card may not grade or flip it.
      before.onNext!();
      before.onFlip!();
      before.onSkip!();
      navigator.currentState!.pop();
      await _settle(tester);
      expect(routes.stack.last, same(originalRoute));
      expect(
        tester.state(find.byType(CustomPackPlayScreen)),
        same(originalState),
      );
      expect(tester.widget<FlipCard>(find.byType(FlipCard)).flipped, isTrue);
      expect(
        tester
            .widget<FlashcardRomanizationAction>(
              find.byType(FlashcardRomanizationAction),
            )
            .onFront,
        isTrue,
      );
      expect(_feed(tester).judgmentsEnabled, isTrue);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(Storage.srsTotalReviewed(), 0);
      expect(Storage.xp, 0);
    }
    _feed(tester).onNext!();
    await _settle(tester);
    expect(Storage.srsCard('도서관')?.reviewCount, 1);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(_feed(tester).judgmentsEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an accepted judgment finishes during a tab visit exactly once', (
    tester,
  ) async {
    final routes = _RouteLog();
    final navigator = GlobalKey<NavigatorState>();
    await _pump(
      tester,
      const Size(402, 874),
      routes: routes,
      navigator: navigator,
    );
    _feed(tester).onFlip!();
    await _settle(tester);
    final acceptedAnswer = _feed(tester).onNext!;
    final cardRoute = routes.stack.last;
    acceptedAnswer();
    tester
        .widget<ApprovedGameNavigation>(find.byType(ApprovedGameNavigation))
        .onSelected(0);
    expect(cardRoute.isCurrent, isFalse);
    // Drain the accepted preference writes without building the tab visit's
    // unrelated root loaders. Completion may advance the covered source.
    await tester.idle();
    expect(Storage.srsCard('도서관')?.reviewCount, 1);
    expect(Storage.vokSeenIds, contains('도서관'));
    navigator.currentState!.pop();
    await _settle(tester);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(_feed(tester).judgmentsEnabled, isFalse);
    acceptedAnswer();
    await tester.idle();
    expect(Storage.srsCard('도서관')?.reviewCount, 1);
    expect(Storage.srsTotalReviewed(), 1);
    expect(tester.takeException(), isNull);
  });
}

List<String> _labels(AppL10n t) => [
  t.soriStageNavToday,
  t.soriStageNavLearn,
  t.soriStageNavGames,
  t.soriStageNavHanok,
  t.soriStageNavGye,
];
SoriContentFeed _feed(WidgetTester tester) =>
    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  _RouteLog? routes,
  GlobalKey<NavigatorState>? navigator,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigator,
      navigatorObservers: [if (routes != null) routes],
      theme: AppTheme.light,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: const CustomPackPlayScreen(packId: _packId),
    ),
  );
  await _settle(tester);
}

// Bounded route/state proof: pop before building unrelated tab-root loaders.
// This exercises real Navigator push/pop and the same return used by Games;
// it is not a full Shell or physical-device end-to-end test.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final context = tester.element(find.byType(CustomPackPlayScreen));
  await tester.runAsync(() async {
    final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
    await Future.wait([
      for (final path in assets.listAssets())
        if (path.startsWith('assets/illustrations/approved_games/') &&
            path.endsWith('.png'))
          precacheImage(AssetImage(path), context),
    ]);
  });
  await _settle(tester);
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(_captureKey))
        .toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('$_captureDirectory/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png.buffer.asUint8List());
    image.dispose();
  });
}

class _RouteLog extends NavigatorObserver {
  final stack = <Route<dynamic>>[];
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
  }
}
