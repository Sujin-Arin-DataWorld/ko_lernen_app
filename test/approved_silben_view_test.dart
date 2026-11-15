import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_silben_art.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';
import 'support/sori_stage_pump.dart';
import 'support/viewport_pages.dart';

const _captureDir = String.fromEnvironment('CAPTURE_APPROVED_SILBEN');
const _captureKey = ValueKey('silben-capture');

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _tap(WidgetTester tester, String name) async {
  final target = _key(name);
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await pumpSoriStage(tester);
}

Semantics _semantics(WidgetTester tester, String name) =>
    tester.widget<Semantics>(_key(name));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, List<SilbenPuzzle>> puzzles;
  late SoriSpeechStub speech;

  setUpAll(() async {
    puzzles = await SilbenPuzzleLoader.load();
    await loadSoriRealFonts(materialIcons: true);
    for (final entry in {
      'SilbenPlex': 'assets/fonts/IBMPlexSans/IBMPlexSans-Variable.ttf',
      'MaruBuriOTF': 'assets/fonts/MaruBuri/MaruBuri-Bold.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_silben_kreuz': true,
      'kl_tts_speed_v1': 1.0,
    });
    Storage.resetForTesting();
    await Storage.init();
    speech = stubSoriSpeech();
  });

  Future<SilbenPuzzle> open(
    WidgetTester tester,
    String id, {
    Size size = const Size(402, 874),
    double scale = 1,
    String language = 'de',
    bool safeArea = false,
    bool reducedMotion = true,
    bool pushRoute = false,
    bool includeAllLevels = false,
    GlobalKey<NavigatorState>? navigator,
  }) async {
    final level = id.substring(4, 6).toUpperCase();
    final puzzle = puzzles[level]!.firstWhere((p) => p.id == id);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final screen = SilbenKreuzScreen(
      puzzleLoader: includeAllLevels
          ? () async => puzzles
          : () async => {
              level: [puzzle],
            },
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        navigatorKey: navigator,
        navigatorObservers: [soriRouteObserver],
        builder: (context, child) {
          final media = MediaQuery.of(context);
          const insets = EdgeInsets.only(top: 42, bottom: 28);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
              padding: safeArea ? insets : media.padding,
              viewPadding: safeArea ? insets : media.viewPadding,
            ),
            child: RepaintBoundary(key: _captureKey, child: child!),
          );
        },
        home: pushRoute ? const Scaffold() : screen,
      ),
    );
    if (pushRoute) {
      navigator!.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
    }
    await pumpSoriStage(tester);
    expect(tester.takeException(), isNull);
    return puzzle;
  }

  testWidgets('A1 uses real clues, 5 cells and 8 tiles in the 402×874 fold', (
    tester,
  ) async {
    final puzzle = await open(tester, 'skz_a1_001');
    final clues = List.generate(3, (i) => _key('silben-clue-$i'));
    final cells = [
      for (final (row, col) in puzzle.solution.keys)
        _key('silben-cell-$row-$col'),
    ];
    final pool = List.generate(8, (i) => _key('silben-pool-$i'));
    final hint = _key('dokkaebi-hint');
    for (final target in [...clues, ...cells, ...pool, hint]) {
      expect(target.hitTestable(), findsOneWidget);
      final size = tester.getSize(target);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
    expect(cells, hasLength(5));
    expect(
      tester.getRect(find.byType(ApprovedGameNavigation)),
      const Rect.fromLTWH(0, 792, 402, 82),
    );
    expect(tester.getRect(hint).bottom, lessThanOrEqualTo(776));
    for (final (target, reference) in [
      (_key('dokkaebi-arena-fire'), const Rect.fromLTWH(7, 264, 388, 279)),
      (_key('silben-cell-0-0'), const Rect.fromLTWH(184, 295, 86, 66)),
      (_key('silben-pool-0'), const Rect.fromLTWH(18, 581, 84, 57)),
      (hint, const Rect.fromLTWH(14, 716, 374, 52)),
    ]) {
      final actual = tester.getRect(target);
      expect(actual.left, closeTo(reference.left, 1), reason: '$target left');
      expect(actual.top, closeTo(reference.top, 1), reason: '$target top');
      expect(
        actual.width,
        closeTo(reference.width, 1),
        reason: '$target width',
      );
      expect(
        actual.height,
        closeTo(reference.height, 1),
        reason: '$target height',
      );
    }
    expect(_semantics(tester, 'silben-cell-0-0').properties.selected, isTrue);
    await _tap(tester, 'silben-pool-0');
    expect(_semantics(tester, 'silben-pool-0').properties.enabled, isTrue);
    await _tap(tester, 'silben-pool-4');
    expect(_semantics(tester, 'silben-cell-0-0').properties.enabled, isFalse);
    expect(_semantics(tester, 'silben-pool-4').properties.enabled, isFalse);
  });

  testWidgets('B1 only consumes the tapped copy of 임', (tester) async {
    await open(tester, 'skz_b1_005');
    await _tap(tester, 'silben-clue-0');
    await _tap(tester, 'silben-pool-2');
    await _tap(tester, 'silben-pool-7');
    expect(_semantics(tester, 'silben-pool-7').properties.enabled, isFalse);
    expect(_semantics(tester, 'silben-pool-9').properties.enabled, isTrue);
    expect(speech.spoken.single, startsWith('책임'));
  });

  testWidgets('C2 help gives sentence, crossing, and reveal without placing', (
    tester,
  ) async {
    await open(tester, 'skz_c2_007');
    await _tap(tester, 'silben-clue-0');
    await _tap(tester, 'dokkaebi-hint');
    expect(_key('dokkaebi-cross-2-2'), findsNothing);
    await _tap(tester, 'dokkaebi-hint');
    await _tap(tester, 'dokkaebi-cross-2-2');
    expect(_semantics(tester, 'silben-cell-2-2').properties.selected, isTrue);
    await _tap(tester, 'dokkaebi-hint');
    expect(_key('dokkaebi-revealed'), findsOneWidget);
    expect(_semantics(tester, 'silben-cell-2-2').properties.enabled, isTrue);
    await _tap(tester, 'silben-pool-0');
    expect(_semantics(tester, 'silben-cell-2-2').properties.enabled, isFalse);
  });

  for (final id in ['skz_a1_004', 'skz_a2_009', 'skz_c2_007']) {
    testWidgets(
      '$id keeps the board, tiles and help reachable without scroll',
      (tester) async {
        final puzzle = await open(
          tester,
          id,
          size: const Size(320, 640),
          scale: 2,
          language: 'en',
          safeArea: true,
        );
        expect(find.text('Choose a cell · tap a syllable'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing);
        final hint = _key('dokkaebi-hint');
        expect(hint.hitTestable(), findsOneWidget);
        expect(tester.getSize(hint).height, greaterThanOrEqualTo(48));
        for (final (row, col) in puzzle.solution.keys) {
          final cell = _key('silben-cell-$row-$col');
          await showViewportSection(tester, cell);
          final rect = tester.getRect(cell);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        final last = _key('silben-pool-${puzzle.pool.length - 1}');
        await showViewportSection(tester, last);
        expect(last.hitTestable(), findsOneWidget);
        expect(hint.hitTestable(), findsOneWidget);
        await tester.tap(hint);
        await pumpSoriStage(tester);
        expect(_key('dokkaebi-word-path').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A1 respects safe areas and preserves game state on return', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await open(
      tester,
      'skz_a1_001',
      safeArea: true,
      navigator: navigator,
      reducedMotion: false,
    );
    final nav = find.byType(ApprovedGameNavigation);
    expect(tester.getRect(nav).bottom, 846);
    expect(tester.getRect(find.byType(SilbenHeader)).top, 42);
    expect(_key('dokkaebi-hint').hitTestable(), findsOneWidget);
    expect(
      tester.getRect(nav).top - tester.getRect(_key('dokkaebi-hint')).bottom,
      greaterThanOrEqualTo(16),
    );
    await _tap(tester, 'silben-pool-4');
    await _tap(tester, 'silben-pool-0');
    final stopped = speech.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(speech.stops, greaterThan(stopped));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpSoriStage(tester);
    final state = tester.state(find.byType(SilbenKreuzScreen));
    final stopsBeforeVisit = speech.stops;
    await tester.tap(find.byTooltip('Lernen'));
    await pumpSoriStage(tester);
    expect(find.byType(SilbenKreuzScreen), findsNothing);
    expect(speech.stops, greaterThan(stopsBeforeVisit));
    await _tap(tester, 'sori-image-destination-${ApprovedChromeAssets.games}');
    expect(tester.state(find.byType(SilbenKreuzScreen)), same(state));
    expect(_semantics(tester, 'silben-cell-0-0').properties.enabled, isFalse);
    expect(Storage.xp, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('level and speed controls use persisted game settings', (
    tester,
  ) async {
    await open(tester, 'skz_a1_001', includeAllLevels: true);
    await tester.tap(find.text('A1'));
    await pumpSoriStage(tester);
    expect(find.text('A1 · 0/20'), findsOneWidget);
    await _tap(tester, 'sori-level-sheet-C2');
    expect(find.text('C2'), findsOneWidget);
    await tester.tap(find.text('1×'));
    await pumpSoriStage(tester);
    final preset = TtsService.speedPresets.first;
    final t = AppL10n.of(tester.element(find.byType(SilbenHeader)));
    await tester.tap(find.text(t.ttsSpeedChip(preset.toString())));
    await pumpSoriStage(tester);
    expect(TtsService.speedNotifier.value, preset);
    expect(Storage.ttsSpeed, preset);
    await TtsService.setSpeed(1);
  });

  testWidgets('system back from the solved puzzle stops its speech', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await open(tester, 'skz_a1_001', navigator: navigator, pushRoute: true);
    for (final i in [4, 0, 1, 7, 3]) {
      await _tap(tester, 'silben-pool-$i');
    }
    expect(speech.spoken, isNotEmpty);
    expect(Storage.xp, 30);
    final before = speech.stops;
    expect(await navigator.currentState!.maybePop(), isTrue);
    await pumpSoriStage(tester);
    expect(speech.stops, greaterThan(before));
    expect(find.byType(SilbenKreuzScreen), findsNothing);
    expect(Storage.xp, 30);
  });

  testWidgets(
    'capture the live A1 Flutter surface',
    skip: _captureDir.isEmpty,
    (tester) async {
      await open(tester, 'skz_a1_001');
      final context = tester.element(find.byType(SilbenHeader));
      await tester.runAsync(() async {
        const dir = 'assets/illustrations/approved_games';
        await Future.wait([
          for (final path in [
            silbenWoodAsset,
            silbenTileAsset,
            silbenFlowerAsset,
            PracticeDokkaebiPose.ready.asset,
            'assets/illustrations/decorations/decoration_dokkaebi_fire.png',
            for (final name in [
              'word_chain_jade_borderless',
              'paper',
              'cloud',
              'nav_heute',
              'nav_open_book',
              'nav_spiele',
              'nav_hanok',
              'nav_gye',
              'word_chain_syllable_jade',
              'jade_control_approved',
            ])
              '$dir/$name.png',
          ])
            precacheImage(AssetImage(path), context),
        ]);
        // PracticeDokkaebiArt and the introduction use sized decode caches.
        await Future.wait([
          precacheImage(
            ResizeImage(
              AssetImage(PracticeDokkaebiPose.ready.asset),
              width: 512,
            ),
            context,
          ),
          precacheImage(
            const ResizeImage(
              AssetImage(
                'assets/illustrations/decorations/decoration_dokkaebi_fire.png',
              ),
              width: 128,
            ),
            context,
          ),
        ]);
      });
      await pumpSoriStage(tester);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_captureKey),
        );
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$_captureDir/silben-a1-flutter.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
}
