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
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';

const _search = ValueKey('wortpakete-search');
const _capture = ValueKey('wortpakete-capture');
const _captureDirectory = String.fromEnvironment('WORTPAKETE_CAPTURE_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(
    () => loadSoriRealFonts(materialIcons: _captureDirectory.isNotEmpty),
  );

  setUp(() async {
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
      expect([groups.length, packs.length, words], [222, 254, 2968]);
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
    await tester.ensureVisible(global);
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
    final allTopics = find.text('Alle Themen anzeigen');
    await tester.ensureVisible(allTopics);
    await tester.tap(allTopics);
    await tester.pumpAndSettle();
    final l10n = AppL10n.of(tester.element(find.byType(VocabPacksScreen)));
    expect(
      find.text(l10n.vocabPacksProgressLabel(1, a1.length)),
      findsOneWidget,
    );
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    final choose = find.byTooltip('2 Pakete');
    await tester.ensureVisible(choose);
    await tester.pumpAndSettle();
    await tester.tap(choose);
    await tester.pumpAndSettle();
    expect(
      find.text(
        '${saved.words.length} / ${saved.words.length} · ${l10n.packStateCleared}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Begrüßung & Höflichkeit (2)'));
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
    await tester.ensureVisible(a1);
    await tester.pumpAndSettle();
    await tester.tap(a1);
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('wortpakete-open-pack'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(opened, ['a1_greetings_1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production /vocab route opens the real pack player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(VocabPackService.loadAll);
    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
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
    await tester.tap(find.text(l10n.wortpaketeLevelGoal('a1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final cta = find.byKey(const ValueKey('wortpakete-open-pack'));
    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final player = tester.widget<VocabPackScreen>(find.byType(VocabPackScreen));
    expect(player.packId, 'a1_greetings_1');
    expect(player.courseContext, isNull);
    final route = ModalRoute.of(tester.element(find.byType(VocabPackScreen)))!;
    expect(route.transitionDuration, const Duration(milliseconds: 220));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('captures overview and all CEFR levels at 430 × 932', (
    tester,
  ) async {
    await _open(tester);
    await _save(tester, 'overview');
    await tester.tap(find.text('Erste Gespräche'));
    await tester.pumpAndSettle();
    for (final level in LearnerLevel.values) {
      final tab = find.byKey(ValueKey('wortpakete-level-${level.code}'));
      await tester.ensureVisible(tab);
      if (level != LearnerLevel.a1) {
        await tester.tap(tab);
        await tester.pumpAndSettle();
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

Future<void> _save(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) {
    return;
  }
  await settleCNativeCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final anchors = <String, Finder>{
    'search': find.byKey(_search),
    'selectedLevel': find.byKey(ValueKey('wortpakete-level-$name')),
    if (name != 'overview')
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
