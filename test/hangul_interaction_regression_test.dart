import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_calligraphy_ink.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sori_speech_stubs.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  setUp(() async {
    stubSoriSpeech();
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

  // The approved catalog opens the detail first; its Listen action must still
  // speak the jamo sound rather than the example word '빵'.
  testWidgets(
    'overview jamo Listen immediately speaks its single-syllable sound',
    (tester) async {
      final spoken = <String>[];
      await tester.pumpWidget(
        _host(
          HangulScreen(
            speechPlayer: (text) async {
              spoken.add(text);
              return true;
            },
            textPrefetcher: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = _l10n(tester);
      await _tap(tester, _button('${t.hangulChipConsonants} · 19'));
      await _tap(tester, find.byKey(const ValueKey('hangul-catalog-ㅃ')));
      expect(spoken, isEmpty);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(Dialog),
          matching: _button(t.cHangulListen),
        ),
      );

      expect(spoken, ['쁘']);
      expect(find.text('ㅃ'), findsWidgets);
    },
  );

  testWidgets('typed guide destination opens the requested Hangeul tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HangulScreen(
          initialTarget: HangulTarget.write,
          speechPlayer: (_) async => true,
          textPrefetcher: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final target in HangulTarget.values) {
      expect(
        tester
            .widget<CAtelierButton>(
              find.byKey(ValueKey('hangul-tab-${target.index}')),
            )
            .selected,
        target == HangulTarget.write,
      );
    }
    expect(find.byKey(const Key('trace-canvas')), findsOneWidget);
    expect(_trace(tester).ghost, 'ㄱ');
  });

  testWidgets('writing canvas owns drags, paints immediately, and includes ㄴ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        HangulScreen(
          initialTarget: HangulTarget.write,
          speechPlayer: (_) async => true,
          textPrefetcher: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = _l10n(tester);
    await _tap(tester, _button(t.btnNext));

    expect(_trace(tester).ghost, 'ㄴ');
    expect(_trace(tester).enabled, isTrue);
    expect(find.text('2 / 34'), findsOneWidget);
    final canvas = find.byKey(const Key('trace-canvas'));
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    final box = tester.getRect(canvas);
    final scale = box.shortestSide / 220;
    final origin = box.center - Offset(110 * scale, 110 * scale);
    Offset at(Offset point) => origin + point * scale;
    final points = (hangulStrokes['ㄴ']!.single as LineStroke).points;
    final gesture = await tester.startGesture(at(points.first));
    for (var step = 1; step <= 12; step++) {
      await gesture.moveTo(at(Offset.lerp(points[0], points[1], step / 12)!));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      _trace(tester).controller.snapshot.strokes.single.length,
      greaterThan(1),
    );
    final paintedCanvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('trace-canvas-ghost-ㄴ')),
    );
    final painter = paintedCanvas.painter as dynamic;
    final shapes = painter.shapes as List<CInkShape>;
    expect(shapes.single.stroke.points.length, greaterThan(1));
    expect(shapes.single.stamps, isNotEmpty);
    expect(find.text('2 / 34'), findsOneWidget);

    for (var step = 1; step <= 12; step++) {
      await gesture.moveTo(at(Offset.lerp(points[1], points[2], step / 12)!));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    expect(find.text(t.hangulStrokeProgress(1, 1)), findsOneWidget);
    expect(find.text(t.hangulStrokeLetterDone('ㄴ')), findsOneWidget);
    expect(_trace(tester).controller.snapshot.strokes, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

AppL10n _l10n(WidgetTester tester) =>
    AppL10n.of(tester.element(find.byType(HangulScreen)));

TraceCanvas _trace(WidgetTester tester) =>
    tester.widget<TraceCanvas>(find.byType(TraceCanvas));

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is CAtelierButton && widget.label == label,
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
