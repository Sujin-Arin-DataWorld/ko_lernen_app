import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/screens/smalltalk_context_screen.dart';
import 'package:ko_lernen_app/services/smalltalk_context_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';
import 'support/sori_viewport_page.dart';

const _nav = 'sori-image-navigation-bar';
const _navRect = Rect.fromLTWH(10, 800, 382, 69);
const _headerRect = Rect.fromLTWH(0, 0, 402, 80);
const _captureKey = ValueKey('lernen-folio-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.speakImpl = (_, _) async => true;
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_hangul_auto_advance_v1': false,
    });
    await Storage.init();
  });
  tearDown(SoriSpeech.resetForTesting);

  testWidgets('daily letter · Figma 280:937 at 402×874', (tester) async {
    await _mount(tester, const DailyCalligraphyRouteScreen(character: 'ㅘ'));
    await tester.pump(const Duration(seconds: 8));
    await _compare(tester, 'daily-letter', {
      '280:938': (find.byType(SoriAppBar), _headerRect),
      '280:945': (_key(_nav), _navRect),
      '280:957': (
        _key('daily-folio-desk'),
        const Rect.fromLTWH(16, 145, 370, 457),
      ),
      '280:958': (
        _key('daily-character-stroke-guide'),
        const Rect.fromLTWH(74, 293, 247, 247),
      ),
      '280:971': (
        _key('daily-folio-brush'),
        const Rect.fromLTWH(272, 305, 99, 220),
      ),
      '280:974': (
        _key('daily-folio-listen'),
        const Rect.fromLTWH(16, 727, 118, 51),
      ),
      '280:976': (
        _key('daily-folio-finish'),
        const Rect.fromLTWH(148, 727, 238, 51),
      ),
    });
  });

  testWidgets('Small Talk C1 action · Figma 280:807 at 402×874', (
    tester,
  ) async {
    final cases = (await tester.runAsync(SmalltalkContextCatalog.load))!;
    await _mount(
      tester,
      SmalltalkContextScreen(
        request: const SmalltalkContextRequest(caseId: 'invite_low_pressure'),
        loadCases: () async => cases,
      ),
    );
    for (final action in [
      'context-intent-invite',
      'context-expression-welcome',
    ]) {
      final button = _key(action);
      await showSoriViewportSection(tester, button);
      await tester.tap(button);
      await pumpSoriStage(tester);
    }
    await _compare(tester, 'smalltalk-c1', {
      '280:808': (find.byType(SoriAppBar), _headerRect),
      '280:815': (_key(_nav), _navRect),
      '280:843': (_key('context-check'), const Rect.fromLTWH(16, 728, 370, 51)),
    });
  });
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(WidgetTester tester, Widget screen) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: RepaintBoundary(key: _captureKey, child: screen),
    ),
  );
  await pumpSoriStage(tester);
}

Future<void> _compare(
  WidgetTester tester,
  String name,
  Map<String, (Finder, Rect)> anchors,
) async {
  final rows = <Map<String, Object>>[];
  List<double> edges(Rect rect) => [
    rect.left,
    rect.top,
    rect.right,
    rect.bottom,
  ];
  for (final entry in anchors.entries) {
    final (finder, reference) = entry.value;
    expect(finder, findsOneWidget, reason: entry.key);
    final actualEdges = edges(tester.getRect(finder));
    final referenceEdges = edges(reference);
    rows.add({
      'node': entry.key,
      'figma': referenceEdges,
      'flutter': actualEdges,
      'maxEdgeDelta': [
        for (var i = 0; i < 4; i++) (actualEdges[i] - referenceEdges[i]).abs(),
      ].reduce((a, b) => a > b ? a : b),
    });
  }
  const path = String.fromEnvironment('LERNEN_FOLIO_CAPTURE_DIR');
  if (path.isNotEmpty) {
    await settleCNativeCaptureAssets(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$path/$name.png').writeAsBytes(png!.buffer.asUint8List());
      await File(
        '$path/$name.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
      image.dispose();
    });
  }
  for (final row in rows) {
    expect(row['maxEdgeDelta'], lessThanOrEqualTo(2), reason: '$name $row');
  }
  expect(tester.takeException(), isNull);
}
