import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_data.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/liked_content_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    final font = FontLoader('Paperlogy');
    for (final weight in ['Regular', 'SemiBold']) {
      font.addFont(
        rootBundle.load('assets/fonts/Paperlogy/Paperlogy-$weight.ttf'),
      );
    }
    await font.load();
  });
  setUp(() async {
    stubSoriSpeech();
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_hangul_auto_advance_v1': false,
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets(
    'all 285 combinations include wo and the final double consonant',
    (tester) async {
      await _pump(tester, HangulTarget.overview);
      await _tap(tester, find.byKey(const ValueKey('hangul-vowel-group-3')));
      expect(find.byKey(const ValueKey('hangul-syllable-궈')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('hangul-syllable-궈')));
      expect(find.text('ㄱ + ㅝ = 궈'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('hangul-full-syllable-chart')),
        const Offset(0, -1400),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hangul-syllable-훠')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('hangul-syllable-훠')));
      expect(find.text('ㅎ + ㅝ = 훠'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vertical browse never grades; double-tap adds only; judgments persist',
    (tester) async {
      await _pump(tester, HangulTarget.cards);
      final card = find.byType(FlipCard);
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        LikedContentService.isLiked(kind: LikedContentService.hangul, id: 'ㄱ'),
        isTrue,
      );
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        LikedContentService.isLiked(kind: LikedContentService.hangul, id: 'ㄱ'),
        isTrue,
      );
      await tester.drag(card, const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(find.text('2 / 19'), findsOneWidget);
      expect(Storage.hangulHard, isEmpty);
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CAtelierButton>(
              find.widgetWithText(CAtelierButton, 'Nicht gewusst'),
            )
            .onTap,
        isNotNull,
      );
      await _tap(tester, find.widgetWithText(CAtelierButton, 'Nicht gewusst'));
      expect(Storage.hangulHard, ['ㄴ']);
      expect(find.text('3 / 19'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '34 jamo and 16 syllable cards retain their original descriptions and words',
    (tester) async {
      await _pump(tester, HangulTarget.cards);
      for (final (mode, pool) in [
        (0, consonants),
        (1, vowels),
        (2, [for (final s in syllables) s.toHangulChar()]),
      ]) {
        if (mode != 0) {
          await _tap(tester, find.byKey(const Key('hangul-cards-selection')));
          await _tap(tester, find.byKey(ValueKey('hangul-cards-mode-$mode')));
        }
        for (final c in pool) {
          expect(
            find.byKey(ValueKey('hangul-card-${c.letter}')),
            findsOneWidget,
          );
          await tester.tap(find.byType(FlipCard));
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          expect(find.text(c.descriptionFor('de')), findsWidgets);
          expect(find.text(c.exampleWord), findsWidgets);
          await _tap(
            tester,
            find.widgetWithText(CAtelierButton, 'Überspringen'),
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all 98 native strokes grade in the uniform coordinate space', (
    tester,
  ) async {
    await _pump(tester, HangulTarget.write);
    var count = 0;
    for (final c in [...consonants, ...vowels]) {
      await tester.pumpAndSettle();
      expect(
        tester.widget<TraceCanvas>(find.byType(TraceCanvas)).ghost,
        c.letter,
      );
      for (final stroke in hangulStrokes[c.letter]!) {
        await _draw(tester, stroke);
        count++;
      }
      expect(
        _action(tester, 'hangul-finish-writing').onTap,
        isNotNull,
        reason: c.letter,
      );
      if (c.letter != vowels.last.letter) {
        await _tap(tester, find.widgetWithText(CAtelierButton, '›'));
      }
    }
    expect(count, 98);
    await _tap(tester, find.byKey(const Key('hangul-finish-writing')));
    expect(find.textContaining('34'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reversed strokes fail and reduced motion requires manual demonstration',
    (tester) async {
      await _pump(tester, HangulTarget.write, reduced: true);
      expect(find.byType(TraceCanvas), findsNothing);
      expect(_action(tester, 'hangul-finish-writing').onTap, isNull);
      await _tap(tester, find.byKey(const Key('hangul-demonstrate')));
      expect(find.byType(TraceCanvas), findsOneWidget);
      await _draw(tester, hangulStrokes['ㄱ']!.first, reverse: true);
      expect(_action(tester, 'hangul-finish-writing').onTap, isNull);
      await tester.pump(const Duration(milliseconds: 500));
      await _draw(tester, hangulStrokes['ㄱ']!.first);
      expect(_action(tester, 'hangul-finish-writing').onTap, isNotNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(402, 874),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final target in HangulTarget.values) {
        testWidgets(
          '${target.name} ${size.width}×${size.height} $scale font fits and is reachable',
          (tester) async {
            await _pump(tester, target, size: size, scale: scale);
            if (target != HangulTarget.overview) {
              final finish = find.byKey(
                Key(
                  target == HangulTarget.write
                      ? 'hangul-finish-writing'
                      : 'hangul-finish-cards',
                ),
              );
              await tester.ensureVisible(finish);
              await tester.pumpAndSettle();
              expect(tester.getSize(finish).height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);
            if (scale == 2) {
              expect(
                find.byKey(const Key('hangul-accessible-page-scroll')),
                findsOneWidget,
              );
            }
          },
        );
      }
    }
  }

  if (const bool.fromEnvironment('CAPTURE_C_HANGUL_EVIDENCE')) {
    for (final target in HangulTarget.values) {
      testWidgets('capture ${target.name} at approved 402×874', (tester) async {
        await _pump(tester, target);
        // Asset resolution can begin in the fake test zone. Alternate real
        // file/decoder I/O and frames instead of awaiting an already pending
        // ImageStream while the fake zone is suspended.
        for (var frame = 0; frame < 12; frame++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('atelier-evidence')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory(
            'C:/dev/hangulsori/_codex_artifacts/native-design-review-20261030/atelier-migration/captures',
          );
          dir.createSync(recursive: true);
          File(
            '${dir.path}/flutter-${target.name}-402x874.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
    for (final contact in [const Offset(180, 40), const Offset(180, 150)]) {
      testWidgets('capture brush contact $contact at the paper edge', (
        tester,
      ) async {
        await _pump(tester, HangulTarget.write);
        for (var frame = 0; frame < 12; frame++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        final rect = tester.getRect(find.byKey(const Key('trace-canvas')));
        final side = rect.shortestSide;
        Offset position(Offset p) =>
            rect.topLeft +
            Offset((rect.width - side) / 2, (rect.height - side) / 2) +
            p * side / 220;
        final gesture = await tester.startGesture(
          position(const Offset(40, 40)),
        );
        for (var i = 1; i <= 24; i++) {
          await gesture.moveTo(
            position(Offset.lerp(const Offset(40, 40), contact, i / 24)!),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(milliseconds: 250));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('atelier-evidence')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            'C:/dev/hangulsori/_codex_artifacts/native-design-review-20261030/atelier-migration/captures/flutter-brush-right-${contact.dy.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

CAtelierButton _action(WidgetTester tester, String key) =>
    tester.widget<CAtelierButton>(find.byKey(Key(key)));
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  HangulTarget target, {
  Size size = const Size(402, 874),
  double scale = 1,
  bool reduced = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: RepaintBoundary(
          key: const Key('atelier-evidence'),
          child: HangulScreen(
            initialTarget: target,
            speechPlayer: (_) async => true,
            textPrefetcher: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _draw(
  WidgetTester tester,
  Stroke stroke, {
  bool reverse = false,
}) async {
  final finder = find.byKey(const Key('trace-canvas'));
  await tester.ensureVisible(finder);
  await tester.pump();
  final rect = tester.getRect(finder),
      side = tester.getRect(finder).shortestSide;
  Offset location(Offset p) =>
      rect.topLeft +
      Offset((rect.width - side) / 2, (rect.height - side) / 2) +
      p * side / 220;
  final points = stroke is CircleStroke
      ? [
          for (var i = 0; i <= 72; i++)
            stroke.center +
                Offset(
                      math.cos(-math.pi / 2 + i * math.pi * 2 / 72),
                      math.sin(-math.pi / 2 + i * math.pi * 2 / 72),
                    ) *
                    stroke.radius,
        ]
      : (stroke as LineStroke).points;
  final path = reverse ? points.reversed.toList() : points;
  final gesture = await tester.startGesture(location(path.first));
  for (var i = 1; i < path.length; i++) {
    final steps = stroke is CircleStroke ? 1 : 12;
    for (var n = 1; n <= steps; n++) {
      await gesture.moveTo(
        location(Offset.lerp(path[i - 1], path[i], n / steps)!),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 16));
}
