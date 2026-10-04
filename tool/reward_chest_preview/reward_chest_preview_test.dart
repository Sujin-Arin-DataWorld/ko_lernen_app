import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'reward_chest_screen.dart';
import 'reward_chest_prelude.dart';
import 'reward_chest_guide.dart';
import '../../test/support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  Future<void> warmup(WidgetTester tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(key: key, builder: (_) => const SizedBox.expand()),
      ),
    );
    final context = key.currentContext;
    if (context == null) {
      throw StateError('Warmup context missing');
    }
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          'assets/illustrations/reward/najeon_chest_closed.png',
          'assets/illustrations/reward/najeon_chest_open.png',
          'assets/illustrations/decorations/decoration_jagae_mungap.png',
        ])
          precacheImage(AssetImage(asset), context),
      ]),
    );
  }

  Future<void> mount(
    WidgetTester tester, {
    String lang = 'de',
    double? second,
    bool reduceMotion = false,
    VoidCallback? onContinue,
    bool guide = false,
    String? name,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(lang),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) {
            final t = AppL10n.of(context);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduceMotion,
                textScaler: TextScaler.linear(textScale),
              ),
              child: RepaintBoundary(
                key: const Key('reward-frame'),
                child: RewardChestScreen(
                  itemAsset:
                      'assets/illustrations/decorations/decoration_jagae_mungap.png',
                  itemName: name ?? t.decorNameJagaeMungap,
                  subtitle: t.decorTermJagaeMungap,
                  itemDescription: lang == 'de'
                      ? 'Ein Jagae-mungap ist ein niedriger Schrank, dessen lackierte Oberfläche mit dünn geschliffenen Muschelschalen verziert ist.'
                      : 'A jagae mungap is a low cabinet with a lacquered surface decorated using thinly polished pieces of shell.',
                  totalXp: 1280,
                  xpLevel: 13,
                  xpToNext: 20,
                  continueLabel: t.rewardChestPlaceSarangbang,
                  onLearnMore: () {},
                  enableAudio: false,
                  showBlueMagic: guide,
                  previewSecond: second,
                  onContinue: onContinue ?? () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
  }

  const frames = <(String, double)>[
    ('00a_pearl_wake', 0.28),
    ('00b_pearl_gather', 0.62),
    ('01_charge', 0.90),
    ('01a_pearl_handoff', 1.06),
    ('02_open', 1.38),
    ('03_item_above_lid', 1.72),
    ('03a_chest_gone', 2.08),
    ('03b_cascade', 2.12),
    ('03c_glow_settled', 2.32),
    ('04_receipt', 2.48),
    ('05_reward', 4.0),
  ];

  for (final lang in ['de', 'en']) {
    for (final frame in frames) {
      testWidgets('$lang renders ${frame.$1}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await warmup(tester);
        await mount(tester, lang: lang, second: frame.$2);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (frame.$2 >= 1.18) {
          expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
        }
        if (frame.$2 == 4) {
          expect(find.byKey(const Key('reward-chest-open')), findsNothing);
          expect(
            find.text(lang == 'de' ? 'Neue Dekoration' : 'New decoration'),
            findsOneWidget,
          );
          expect(
            find.text(lang == 'de' ? '1.280 XP' : '1,280 XP'),
            findsOneWidget,
          );
          expect(find.text('현재 학습 XP'), findsNothing);
          final meter = find.byType(LinearProgressIndicator);
          expect(meter, findsOneWidget);
          expect(tester.getSize(meter).height, greaterThanOrEqualTo(6));
          expect(
            find.text(
              lang == 'de' ? 'Im Sarangbang platzieren' : 'Place in Sarangbang',
            ),
            findsOneWidget,
          );
        }
        if (const bool.fromEnvironment('CAPTURE_REWARD_FRAMES')) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('reward-frame')),
          );
          await tester.runAsync(() async {
            final pixels = await boundary.toImage(pixelRatio: 1);
            final bytes = await pixels.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (bytes == null) {
              throw StateError('PNG capture failed');
            }
            final file = File(
              'tool/reward_chest_preview/frames/${lang}_${frame.$1}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
            pixels.dispose();
          });
        }
      });
    }
  }

  RewardChestPreludePainter prelude(double second, {double lift = 1}) =>
      RewardChestPreludePainter(
        second: second,
        origin: const Offset(215, 530),
        floor: const Offset(215, 730),
        chestWidth: 344,
        lift: lift,
      );

  test('blue accent warms smoothly and is gone before the chest exit', () {
    RewardChestBlueLightPainter light(double second) =>
        RewardChestBlueLightPainter(
          second: second,
          origin: Offset.zero,
          chestWidth: 344,
        );
    expect(light(0).opacity, 0);
    expect(light(0.90).opacity, greaterThan(0.9));
    expect(light(1.10).warmth, greaterThan(light(0.90).warmth));
    expect(light(1.46).opacity, 0);
  });

  for (final lang in ['de', 'en']) {
    for (final second in [0.76, 1.10, 1.72, 2.48, 4.0]) {
      testWidgets('guide $lang frame $second', (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await warmup(tester);
        await mount(tester, lang: lang, guide: true, second: second);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('reward-dokkaebi-guide')), findsNothing);
        expect(
          find.byKey(const Key('reward-blue-light')),
          second < 1.46 ? findsOneWidget : findsNothing,
        );
        if (second == 4) {
          expect(find.byKey(const Key('reward-dokkaebi-guide')), findsNothing);
          final titleRect = tester.getRect(
            find.byKey(const Key('reward-guide-title')),
          );
          expect(titleRect.width, greaterThan(200));
        }
        if (const bool.fromEnvironment('CAPTURE_GUIDE_FRAMES')) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('reward-frame')),
          );
          await tester.runAsync(() async {
            final pixels = await boundary.toImage(pixelRatio: 1);
            final bytes = await pixels.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (bytes == null) {
              throw StateError('PNG capture failed');
            }
            final file = File(
              'tool/reward_chest_preview/frames/blue_${lang}_$second.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
            pixels.dispose();
          });
        }
      });
    }
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(430, 900),
    const Size(568, 320),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final lang in ['de', 'en']) {
      testWidgets('guide receipt fits $size $lang without scrolling', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await warmup(tester);
        await mount(tester, guide: true, lang: lang, second: 4);
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('reward-guide-viewport')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scroll.position.maxScrollExtent, 0);
        final action = tester.getRect(
          find.byKey(const Key('reward-guide-action')),
        );
        expect(action.bottom, lessThanOrEqualTo(size.height));
        expect(action.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('guide yields to long names and enlarged system text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await warmup(tester);
    await mount(
      tester,
      guide: true,
      second: 4,
      name:
          'Ein außergewöhnlich langer Name für einen kulturellen Belohnungsgegenstand',
      textScale: 1.6,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reward-dokkaebi-guide')), findsNothing);
    expect(find.byKey(const Key('reward-guide-title')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('reward-guide-action')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('blue receipt reduced motion skips accent and has no mascot', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await warmup(tester);
    await mount(tester, guide: true, reduceMotion: true);
    expect(find.byKey(const Key('reward-blue-light')), findsNothing);
    expect(find.byKey(const Key('reward-dokkaebi-guide')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('pearl prelude has eight deterministic inward-moving light points', () {
    final early = prelude(0.40);
    final gathered = prelude(0.99);
    expect(early.moteCount, 8);
    for (var i = 0; i < early.moteCount; i++) {
      final start = early.motePosition(i);
      final end = gathered.motePosition(i);
      expect(end.distance, lessThan(start.distance));
      expect(end, prelude(0.99).motePosition(i));
    }
  });

  test('pearl prelude overlaps opening without resetting its light points', () {
    expect(prelude(0).opacity, 0);
    expect(prelude(1.06).opacity, greaterThan(0));
    expect(prelude(1.42).opacity, 0);
    for (var i = 0; i < prelude(1).moteCount; i++) {
      final before = prelude(1.039).motePosition(i);
      final after = prelude(1.041).motePosition(i);
      expect((after - before).distance, lessThan(1));
    }
    expect(prelude(0.60).warmth, 0);
    expect(prelude(1.06).warmth, greaterThan(prelude(0.90).warmth));
  });

  test('pearl prelude ground shadow softens as the chest floats', () {
    expect(
      prelude(0.60).shadowOpacity,
      lessThan(prelude(0.60, lift: 0).shadowOpacity),
    );
  });

  testWidgets('pearl prelude is present early and absent in reduced motion', (
    tester,
  ) async {
    await warmup(tester);
    await mount(tester, second: 0.62);
    final painting = find.byKey(const Key('reward-chest-prelude'));
    expect(painting, findsOneWidget);
    final painter = tester.widget<CustomPaint>(painting).painter;
    expect(painter, isA<RewardChestPreludePainter>());
    // Start a fresh route: a frozen previewSecond fixture deliberately does
    // not subscribe to the live reduced-motion lifecycle.
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, reduceMotion: true);
    expect(painting, findsNothing);
    expect(find.text('Neue Dekoration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closed chest starts at the lower 83 percent baseline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await warmup(tester);
    await mount(tester, second: 0.05);
    expect(
      tester.getBottomLeft(find.byKey(const Key('reward-chest-closed'))).dy,
      closeTo(900 * 0.83, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chest uses its original fade curve 0.30 seconds earlier', (
    tester,
  ) async {
    await warmup(tester);
    await mount(tester, second: 1.84);
    final opacities = tester
        .widgetList<Opacity>(
          find.ancestor(
            of: find.byKey(const Key('reward-chest-open')).first,
            matching: find.byType(Opacity),
          ),
        )
        .map((opacity) => opacity.opacity);
    final expectedOpacity =
        1 - Curves.easeInOutCubic.transform((1.84 - 1.60) / 0.48);
    expect(opacities, anyElement(closeTo(expectedOpacity, 0.001)));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chest is gone at 2.08 seconds while the reward keeps its flight',
    (tester) async {
      await warmup(tester);
      await mount(tester, second: 2.08);
      expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
      expect(find.byKey(const Key('reward-chest-open')), findsNothing);
      expect(find.byKey(const Key('reward-item')), findsOneWidget);
      expect(find.text('Neue Dekoration'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('receipt action is ready before three seconds and fires once', (
    tester,
  ) async {
    var calls = 0;
    await warmup(tester);
    await mount(tester, second: 2.90, onContinue: () => calls++);
    final button = find.widgetWithText(SoriButton, 'Im Sarangbang platzieren');
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion immediately shows the final reward', (
    tester,
  ) async {
    await warmup(tester);
    await mount(tester, reduceMotion: true);
    expect(find.text('Neue Dekoration'), findsOneWidget);
    expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
    expect(find.byKey(const Key('reward-chest-open')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Neue Dekoration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping while images warm up cannot restart the reveal', (
    tester,
  ) async {
    await mount(tester);
    await tester.tapAt(const Offset(10, 80));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Neue Dekoration'), findsOneWidget);
    expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
