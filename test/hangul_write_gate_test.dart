/// Real stroke grading and completion gates on the approved Atelier writing flow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/hangul_data.dart' as hangul;
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_tut_hangulWriteRules': true,
      'kl_hangul_auto_advance_v1': false,
    });
    Storage.resetForTesting();
    await Storage.init();
    SoundService.playImpl = (_) {};
  });
  tearDown(SoundService.resetForTesting);

  testWidgets(
    'wrong stroke order explains the expected stroke and blocks progress',
    (tester) async {
      await _openWriteTab(tester);
      await _goToLetter(tester, 'ㅂ');
      await _traceStroke(tester, 'ㅂ', 3);
      expect(
        find.text('That is stroke 4. Draw stroke 1 first.'),
        findsOneWidget,
      );
      expect(find.text('Stroke 0 / 4'), findsOneWidget);
      expect(_trace(tester).controller.snapshot.strokes, isEmpty);
      expect(_finishButton(tester).onTap, isNull);
      await tester.pump(const Duration(milliseconds: 600));
    },
  );

  testWidgets('accepted strokes complete the letter and advance after 900ms', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');
    await tester.tap(find.byKey(const Key('hangul-auto-advance')));
    await _settlePreferenceIO(tester);
    await tester.pumpAndSettle();
    await _traceStroke(tester, 'ㅂ', 0);
    expect(find.text('Stroke 1 / 4'), findsOneWidget);
    expect(find.text('Now draw stroke 2.'), findsOneWidget);
    await _traceStroke(tester, 'ㅂ', 1);
    await _traceStroke(tester, 'ㅂ', 2);
    expect(find.text('Stroke 3 / 4'), findsOneWidget);
    await _traceStroke(tester, 'ㅂ', 3);
    expect(find.text('Stroke 4 / 4'), findsOneWidget);
    expect(find.text('ㅂ is done! On to the next one.'), findsOneWidget);
    expect(_finishButton(tester).onTap, isNotNull);
    await tester.pump(const Duration(milliseconds: 899));
    expect(_selection(tester).label, startsWith('ㅂ'));
    await tester.pump(const Duration(milliseconds: 1));
    expect(_selection(tester).label, startsWith('ㅅ'));
    await tester.pumpAndSettle();
    await _finish(tester);
    expect(find.text('1 letter practised'), findsOneWidget);
    expect(find.text('4 stroke attempts · Strict'), findsOneWidget);
  });

  testWidgets('clear resets accepted strokes so the same letter can succeed', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');
    await _traceStroke(tester, 'ㅂ', 0);
    expect(find.text('Stroke 1 / 4'), findsOneWidget);
    await tester.tap(_button(_l10n(tester).hangulClearBtn));
    await tester.pumpAndSettle();
    expect(find.text('Stroke 0 / 4'), findsOneWidget);
    expect(_trace(tester).controller.snapshot.strokes, isEmpty);
    for (var i = 0; i < 4; i++) {
      await _traceStroke(tester, 'ㅂ', i);
    }
    expect(find.text('ㅂ is done! On to the next one.'), findsOneWidget);
    expect(_finishButton(tester).onTap, isNotNull);
    await _finish(tester);
    expect(find.text('1 letter practised'), findsOneWidget);
    expect(find.text('5 stroke attempts · Strict'), findsOneWidget);
  });

  testWidgets(
    'the faint guide and parked brush follow the next expected stroke',
    (tester) async {
      await _openWriteTab(tester);
      await _goToLetter(tester, 'ㅂ');
      expect(find.byKey(const Key('hangul-writing-guide')), findsOneWidget);
      final strokes = hangulStrokes['ㅂ']!;
      expect(
        _trace(tester).parkedBrush,
        (strokes[0] as LineStroke).points.first,
      );
      await _traceStroke(tester, 'ㅂ', 0);
      expect(
        _trace(tester).parkedBrush,
        (strokes[1] as LineStroke).points.first,
      );
      expect(find.text('Now draw stroke 2.'), findsOneWidget);
    },
  );

  testWidgets(
    'practice keeps wrong strokes and receipts count all real attempts',
    (tester) async {
      await _openWriteTab(tester);
      await _chooseCheckMode(tester, strict: false);
      await _goToLetter(tester, 'ㅂ');
      await _traceStroke(tester, 'ㅂ', 3);
      expect(
        find.text('That is stroke 4. Draw stroke 1 first.'),
        findsOneWidget,
      );
      expect(_trace(tester).controller.snapshot.strokes, hasLength(1));
      expect(_finishButton(tester).onTap, isNull);
      for (var i = 0; i < 4; i++) {
        await _traceStroke(tester, 'ㅂ', i);
      }
      expect(_trace(tester).controller.snapshot.strokes, hasLength(5));
      expect(_finishButton(tester).onTap, isNotNull);
      await _finish(tester);
      expect(find.text('1 letter practised'), findsOneWidget);
      final t = _l10n(tester);
      expect(
        find.text(t.cHangulWritingStrokesReceipt(5, t.hangulCheckModePractice)),
        findsOneWidget,
      );
    },
  );

  testWidgets('practice and strict choices persist immediately', (
    tester,
  ) async {
    await _openWriteTab(tester);
    expect(Storage.hangulStrictStrokes, isTrue);
    await _chooseCheckMode(tester, strict: false);
    expect(Storage.hangulStrictStrokes, isFalse);
    await _chooseCheckMode(tester, strict: true);
    expect(Storage.hangulStrictStrokes, isTrue);
  });

  testWidgets('reverse direction is rejected only in strict mode', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅡ');
    await _traceStroke(tester, 'ㅡ', 0, reversed: true);
    expect(
      find.text('Right line, wrong direction. Stroke 1 goes the other way.'),
      findsOneWidget,
    );
    expect(_finishButton(tester).onTap, isNull);
    await _chooseCheckMode(tester, strict: false);
    await _goToLetter(tester, 'ㅡ');
    await _traceStroke(tester, 'ㅡ', 0, reversed: true);
    expect(find.text('ㅡ is done! On to the next one.'), findsOneWidget);
    expect(_finishButton(tester).onTap, isNotNull);
  });
}

AppL10n _l10n(WidgetTester tester) =>
    AppL10n.of(tester.element(find.byType(HangulScreen)));

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is CAtelierButton && w.label == label);

TraceCanvas _trace(WidgetTester tester) =>
    tester.widget<TraceCanvas>(find.byType(TraceCanvas));

CAtelierButton _selection(WidgetTester tester) => tester.widget<CAtelierButton>(
  find.byKey(const Key('hangul-writing-selection')),
);

CAtelierButton _finishButton(WidgetTester tester) => tester
    .widget<CAtelierButton>(find.byKey(const Key('hangul-finish-writing')));

Future<void> _finish(WidgetTester tester) async {
  final finish = find.byKey(const Key('hangul-finish-writing'));
  await tester.ensureVisible(finish);
  await tester.pumpAndSettle();
  await tester.tap(finish);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('hangul-completion-receipt')), findsOneWidget);
}

Future<void> _chooseCheckMode(
  WidgetTester tester, {
  required bool strict,
}) async {
  await tester.tap(_button(_l10n(tester).atelierMore));
  await tester.pumpAndSettle();
  final t = _l10n(tester);
  await tester.tap(
    _button(strict ? t.hangulCheckModeExam : t.hangulCheckModePractice),
  );
  await _settlePreferenceIO(tester);
  await tester.pumpAndSettle();
}

Future<void> _settlePreferenceIO(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
}

Future<void> _openWriteTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: HangulScreen(
        initialTarget: HangulTarget.write,
        speechPlayer: (_) async => true,
        textPrefetcher: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToLetter(WidgetTester tester, String letter) async {
  await tester.tap(find.byKey(const Key('hangul-writing-selection')));
  await tester.pumpAndSettle();
  final choice = find.byKey(ValueKey('hangul-writing-letter-$letter'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
  final pool = [...hangul.consonants, ...hangul.vowels];
  final target = pool.indexWhere((c) => c.letter == letter);
  expect(target, isNonNegative);
  expect(find.text('${target + 1} / 34'), findsOneWidget);
  expect(_trace(tester).ghost, letter);
}

/// Real pointer samples use the centered, uniform 220x220 grading plane.
Future<void> _traceStroke(
  WidgetTester tester,
  String letter,
  int index, {
  bool reversed = false,
}) async {
  final canvas = find.byKey(const Key('trace-canvas'));
  await tester.ensureVisible(canvas);
  await tester.pumpAndSettle();
  final bounds = tester.getRect(canvas);
  final scale = bounds.shortestSide / 220;
  final origin = bounds.center - Offset(110 * scale, 110 * scale);
  Offset at(Offset p) => origin + p * scale;
  final stroke = hangulStrokes[letter]![index];
  var points = switch (stroke) {
    LineStroke(:final points) => points,
    CircleStroke(:final center, :final radius) => [
      for (var i = 0; i <= 72; i++)
        Offset(
          center.dx + radius * math.cos(-math.pi / 2 + i / 72 * 2 * math.pi),
          center.dy + radius * math.sin(-math.pi / 2 + i / 72 * 2 * math.pi),
        ),
    ],
  };
  if (reversed) points = points.reversed.toList();
  final gesture = await tester.startGesture(at(points.first));
  for (var i = 1; i < points.length; i++) {
    for (var step = 1; step <= 12; step++) {
      await gesture.moveTo(
        at(Offset.lerp(points[i - 1], points[i], step / 12)!),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  await gesture.up();
  await tester.pump();
}
