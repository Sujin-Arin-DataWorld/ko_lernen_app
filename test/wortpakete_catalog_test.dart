import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/locale_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';
import 'support/viewport_pages.dart';

const _search = ValueKey('wortpakete-search');
const _capture = ValueKey('wortpakete-capture');
const _captureDirectory = String.fromEnvironment('WORTPAKETE_CAPTURE_DIR');
const _captureSize = bool.fromEnvironment('CAPTURE_402')
    ? Size(402, 874)
    : Size(430, 932);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(
    () => loadSoriRealFonts(materialIcons: _captureDirectory.isNotEmpty),
  );

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    DataLoader.reset();
    VocabPackService.reset();
  });

  test(
    'all shipped packs retain their exact route IDs and topic grouping',
    () async {
      final result = await VocabPackService.loadForDisplay();
      expect(result.isAvailable, isTrue);
      final groups = <String>{};
      final packs = <String>{};
      var words = 0;
      for (final pack in result.packs) {
        groups.add('${pack.level}/${VocabPackService.topicId(pack.id)}');
        expect(packs.add(pack.id), isTrue);
        expect(
          vocabPackIdFromRouteArguments(VocabCatalogPackArguments(pack.id)),
          pack.id,
        );
        words += pack.words.length;
      }
      // C3-T6 (2026-11-25): A2 Batches 32-34 add 13 new pack bases, 16 packs
      // and 192 words.
      // C3-T7 (2026-11-26): Batch 42 adds a2_daily_4 (existing base) and 14 words.
      expect([groups.length, packs.length, words], [236, 285, 3352]);
      expect(
        VocabPackService.topicId('b1_tech_society_1'),
        VocabPackService.topicId('b1_tech_society_2'),
      );
    },
  );

  testWidgets('global search and scoped search open the original pack', (
    tester,
  ) async {
    final opened = <String>[];
    await _open(tester, onPack: opened.add);
    await tester.enterText(find.byKey(_search), '커피');
    await tester.pumpAndSettle();
    final global = find.byKey(const ValueKey('wortpakete-search-a1_food_1'));
    expect(global, findsOneWidget);
    await showViewportSection(tester, global);
    await tester.pumpAndSettle();
    await tester.tap(global);
    await tester.pumpAndSettle();
    expect(opened, ['a1_food_1']);

    await tester.tap(find.text('Zurück'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_search), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erste Gespräche'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_search), 'U-Bahn');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('wortpakete-search-a1_transport')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('wortpakete-search-a2_subway_card_1')),
      findsNothing,
    );
    await tester.enterText(find.byKey(_search), '_____kein Thema_____');
    await tester.pumpAndSettle();
    expect(find.text('Keine passenden Themen oder Wörter'), findsOneWidget);
  });

  testWidgets('catalog retry recovers a failed corpus and shows real packs', (
    tester,
  ) async {
    const asset = 'assets/data/korean_vocab.csv';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    rootBundle.clear();
    addTearDown(rootBundle.clear);
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (const StringCodec().decodeMessage(message) == asset) {
        return null;
      }
      return messenger.delegate.send('flutter/assets', message);
    });

    await _open(tester);
    expect(find.byType(AppError), findsOneWidget);
    expect(find.text('Erste Gespräche'), findsNothing);

    messenger.setMockMessageHandler('flutter/assets', null);
    final error = tester.widget<AppError>(find.byType(AppError));
    await tester.runAsync(() async {
      error.onRetry!();
      await VocabPackService.loadForDisplay();
    });
    await tester.pumpAndSettle();
    expect(find.byType(AppError), findsNothing);
    expect(find.text('Erste Gespräche'), findsOneWidget);
  });

  testWidgets('a topic with multiple packs opens the chosen existing pack', (
    tester,
  ) async {
    final opened = <String>[];
    final a1 = await tester.runAsync(
      () => VocabPackService.packsForLevel('A1'),
    );
    final saved = a1!.firstWhere((pack) => pack.id == 'a1_greetings_2');
    await Storage.setPackProgressJson(
      saved.id,
      PackProgress.fresh(
            packId: saved.id,
            level: saved.level,
            wordsTotal: saved.words.length,
          )
          .copyWith(
            status: PackStatus.cleared,
            wordsLearned: saved.words.length,
          )
          .toJson(),
    );
    await _open(tester, onPack: opened.add);
    await tester.tap(find.text('Erste Gespräche'));
    await tester.pumpAndSettle();
    final allTopics = find.text('Alle 45 ansehen');
    await showViewportSection(tester, allTopics);
    await tester.tap(allTopics);
    await tester.pumpAndSettle();
    final l10n = AppL10n.of(tester.element(find.byType(VocabPacksScreen)));
    expect(
      find.text(l10n.vocabPacksProgressLabel(1, a1.length)),
      findsOneWidget,
    );
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Paket 1 · 12 Wörter'), findsOneWidget);
    final choose = find.byKey(
      const ValueKey('wortpakete-select-a1_greetings_2'),
    );
    await showViewportSection(tester, choose);
    await tester.pumpAndSettle();
    await tester.tap(choose);
    await tester.pumpAndSettle();
    expect(find.text('Paket 2 · 13 Wörter'), findsOneWidget);
    expect(opened, isEmpty);
    final open = find.byKey(const ValueKey('wortpakete-open-pack'));
    await showViewportSection(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(opened, ['a1_greetings_2']);
  });

  testWidgets('large text and reduced motion keep the pack action reachable', (
    tester,
  ) async {
    final opened = <String>[];
    await _open(
      tester,
      size: const Size(320, 600),
      scale: 2,
      onPack: opened.add,
    );
    final a1 = find.text('Erste Gespräche');
    await showViewportSection(tester, a1);
    await tester.pumpAndSettle();
    await tester.tap(a1);
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('wortpakete-open-pack'));
    await showViewportSection(tester, action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(opened, ['a1_greetings_1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production /vocab route opens the real pack player', (
    tester,
  ) async {
    tester.view.physicalSize = _captureSize;
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.localeTestValue = const Locale('de');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final previousLocale = localeNotifier.value;
    localeNotifier.value = const Locale('de');
    addTearDown(() => localeNotifier.value = previousLocale);
    await Storage.setTutVocabPackSeen();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(VocabPackService.loadAll);
    await _warmCaptureAssets(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _capture,
        child: KoLernenApp(
          splashDisplayDuration: Duration.zero,
          firstRunCoordinator: FirstRunRuntime.createCoordinator(),
        ),
      ),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed('/vocab');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final l10n = AppL10n.of(tester.element(find.byType(VocabPacksScreen)));
    await tester.tap(find.text(l10n.wortpaketeLevelGoalA1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final cta = find.byKey(const ValueKey('wortpakete-open-pack'));
    await showViewportSection(tester, cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final player = tester.widget<VocabPackScreen>(find.byType(VocabPackScreen));
    expect(player.packId, 'a1_greetings_1');
    expect(player.courseContext, isNull);
    final route = ModalRoute.of(tester.element(find.byType(VocabPackScreen)))!;
    expect(route.transitionDuration, const Duration(milliseconds: 220));
    await _save(tester, 'player');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('captures overview and all CEFR levels at the target viewport', (
    tester,
  ) async {
    await _open(tester, size: _captureSize);
    await _save(tester, 'overview');
    await tester.tap(find.text('Erste Gespräche'));
    await tester.pumpAndSettle();
    for (final level in LearnerLevel.values) {
      final tab = find.byKey(ValueKey('wortpakete-level-${level.code}'));
      await showViewportSection(tester, tab);
      if (level != LearnerLevel.a1) {
        await tester.tap(tab);
        await tester.pumpAndSettle();
      }
      expect(find.byType(CustomScrollView), findsNothing);
      if (level == LearnerLevel.a1) {
        final action = find.byKey(const ValueKey('wortpakete-open-pack'));
        if (_captureSize.height >= 900) {
          expect(action.hitTestable(), findsOneWidget);
        }
        await showViewportSection(tester, action);
        final cta = tester.getRect(action);
        final navigation = tester.getRect(
          find.byKey(const ValueKey('sori-image-navigation-bar')),
        );
        expect(navigation.top - cta.bottom, greaterThanOrEqualTo(16));
        final goal = tester.getRect(find.text('Essen und Getränke benennen'));
        final examples = tester.getRect(find.text('커피 · 물'));
        expect(goal.bottom, lessThanOrEqualTo(examples.top));
      }
      expect(Storage.browseLevelCode ?? 'a1', level.code);
      await _save(tester, level.code);
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  double scale = 1,
  ValueChanged<String>? onPack,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(VocabPackService.loadAll);
  await _warmCaptureAssets(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _capture, child: child),
      ),
      home: const VocabPacksScreen(),
      onGenerateRoute: (settings) {
        if (settings.name != '/vocab/pack') {
          return null;
        }
        onPack?.call(vocabPackIdFromRouteArguments(settings.arguments)!);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zurück'),
              ),
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _warmCaptureAssets(WidgetTester tester) async {
  if (_captureDirectory.isEmpty) return;
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  final context = tester.element(find.byType(SizedBox).first);
  final paths = <String>[
    'assets/illustrations/concept_c/material_atlas.png',
    'design_assets/hoeren/home-c-v1.png',
    for (final name in ['today', 'learn', 'games', 'hanok', 'gye'])
      'assets/icons/navigation/$name.png',
    for (final name in [
      'topic-fan',
      'topic-cup',
      'topic-home',
      'topic-transport',
      'jade-book',
      'folio-card',
      'folio-preview',
      'brass-button',
      'paper',
      'jade',
    ])
      'assets/illustrations/concept_c/lernen_20261110/$name.png',
    'design_assets/wortpakete/0-0.png',
    for (var level = 2; level <= 6; level++)
      for (var index = 0; index < 4; index++)
        'design_assets/wortpakete/$level-$index.png',
  ];
  await tester.runAsync(() async {
    await Future.wait([
      for (final path in paths) precacheImage(AssetImage(path), context),
      CImageCache.load('assets/illustrations/concept_c/material_atlas.png'),
    ]);
  });
  await tester.pump();
}

Future<void> _save(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) {
    return;
  }
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await tester.pump();
  await settleCNativeCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final anchors = <String, Finder>{
    'search': find.byKey(_search),
    'selectedLevel': find.byKey(ValueKey('wortpakete-level-$name')),
    if (name != 'overview' && name != 'player')
      'firstTopic': find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('wortpakete-topic-');
      }).first,
    'packCta': find.byKey(const ValueKey('wortpakete-open-pack')),
    'bottomNavigation': find.byKey(const ValueKey('sori-image-navigation-bar')),
  };
  final geometry = <String, List<double>>{};
  for (final entry in anchors.entries) {
    if (entry.value.evaluate().isNotEmpty) {
      final rect = tester.getRect(entry.value);
      geometry[entry.key] = [rect.left, rect.top, rect.width, rect.height];
    }
  }
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_captureDirectory/native-$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    await File(
      '$_captureDirectory/native-$name.geometry.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(geometry));
  });
}
