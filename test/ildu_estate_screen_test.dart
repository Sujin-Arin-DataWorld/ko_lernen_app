import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';
import 'package:ko_lernen_app/screens/ildu_estate_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/gye_hanok.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_r16_estate_artwork.dart';
import 'support/sori_stage_pump.dart';
import 'support/real_fonts.dart';
import 'support/r16_test_asset_bundle.dart';
import 'package:ko_lernen_app/widgets/sori/gye_dedication_layer.dart';

IlDuR16ArtCatalog catalog() => IlDuR16ArtCatalog.fromJson(
  jsonDecode(File(IlDuR16ArtCatalog.assetPath).readAsStringSync()),
);
Future<void> capture(GlobalKey key, String name) async {
  const folder = String.fromEnvironment('R16_CAPTURE_DIR');
  if (folder.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = Directory(folder)..createSync(recursive: true);
  File(
    '${directory.path}/$name.png',
  ).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

Widget app(Widget home, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
      routes: {
        '/hanok/estate': (_) => IlDuEstateScreen(loader: () async => catalog()),
        '/hanok/construction': (_) =>
            Scaffold(appBar: AppBar(), body: const Text('existing lessons')),
        '/hanok/practice': (_) => const Scaffold(body: Text('existing review')),
      },
    );

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });
  for (final locale in ['en', 'de']) {
    for (final width in [390.0, 320.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$locale estate reference $width at $scale text', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          final prefs = await SharedPreferences.getInstance();
          final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: app(
                IlDuEstateScreen(loader: () async => catalog()),
                locale: locale,
                scale: scale,
              ),
            ),
          );
          await pumpUntilFound(
            tester,
            find.text(lookupAppL10n(Locale(locale)).ilduR16Reference),
          );
          await pumpSoriStage(tester);
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            await precacheImage(
              const AssetImage(kIlDuR16EstateAsset),
              tester.element(find.byType(IlDuEstateScreen)),
            );
          });
          await tester.pump();
          await tester.runAsync(
            () => capture(
              boundary,
              '$locale-estate-${width.toInt()}-${scale.toInt()}x',
            ),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('ildu-r16-building-picker')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('ildu-r16-building-picker')),
          );
          await pumpSoriStage(tester);
          await tester.tap(
            find.byKey(const ValueKey('ildu-r16-building-picker')),
          );
          await pumpSoriStage(tester);
          final buildings = find.byWidgetPredicate(
            (widget) =>
                widget is ListTile &&
                widget.key.toString().contains('r16-building-'),
          );
          expect(buildings, findsNWidgets(11));
          expect(tester.takeException(), isNull);
          await tester.tap(buildings.first);
          await pumpSoriStage(tester);
          expect(
            {for (final k in prefs.getKeys()) k: prefs.get(k)},
            before,
            reason: 'Architecture reference cannot grant ownership',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'entry, enlargement, building selection and lessons return preserve state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      await tester.pumpWidget(app(const Scaffold(body: IlDuR16EstateEntry())));
      await tester.tap(find.byType(IlDuR16EstateEntry));
      await pumpUntilFound(tester, find.byType(IlDuEstateScreen));
      await pumpSoriStage(tester);
      final t = AppL10n.of(tester.element(find.byType(IlDuEstateScreen)));
      final enlarge = find.byKey(const ValueKey('ildu-r16-estate-enlarge'));
      await tester.scrollUntilVisible(enlarge, 200);
      await tester.ensureVisible(enlarge);
      await tester.tap(enlarge);
      await pumpSoriStage(tester);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byType(CloseButton));
      await pumpSoriStage(tester);
      final picker = find.byKey(const ValueKey('ildu-r16-building-picker'));
      await tester.scrollUntilVisible(picker, 200);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await pumpSoriStage(tester);
      await tester.tap(find.byKey(const ValueKey('r16-building-changgo')));
      await pumpSoriStage(tester);
      await tester.scrollUntilVisible(find.text(t.ilduConstructionTitle), 250);
      await tester.ensureVisible(find.text(t.ilduConstructionTitle));
      await tester.tap(find.text(t.ilduConstructionTitle));
      await pumpSoriStage(tester);
      expect(find.text('existing lessons'), findsOneWidget);
      await tester.pageBack();
      await pumpSoriStage(tester);
      await tester.scrollUntilVisible(picker, -250);
      expect(
        find.text('${t.ilduR16Building}: ${t.ilduR16Changgo}'),
        findsOneWidget,
      );
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('catalog failure retries without replacing learning state', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        IlDuEstateScreen(
          loader: () async {
            if (calls++ == 0) throw const FormatException('retry');
            return catalog();
          },
        ),
      ),
    );
    await pumpSoriStage(tester);
    final t = AppL10n.of(tester.element(find.byType(IlDuEstateScreen)));
    await tester.tap(find.text(t.btnRetry));
    await pumpUntilFound(tester, find.byType(IlDuR16EstateArtwork));
    expect(calls, 2);
    expect(find.byType(IlDuR16EstateArtwork), findsOneWidget);
  });
  testWidgets(
    'shared completion retains the original eight-element threshold',
    (tester) async {
      GyeMeta meta(int done) => GyeMeta(
        id: 'ABC234',
        name: 'Courtyard',
        code: 'ABC234',
        ownerId: 'owner',
        lifetimeGoalsAchieved: done,
      );
      expect(GyeHanok.elementCount, 8);
      expect(GyeHanok.isComplete(meta(6)), isFalse);
      expect(GyeHanok.isComplete(meta(7)), isTrue);
      await tester.pumpWidget(
        app(SizedBox(height: 240, child: GyeHanok(meta: meta(7)))),
      );
      await pumpSoriStage(tester);
      expect(find.byType(IlDuR16EstateArtwork), findsOneWidget);
      expect(
        tester.getRect(find.byType(IlDuR16EstateArtwork)),
        tester.getRect(find.byType(GyeDedicationLayer)),
      );
      expect(
        tester.getSize(find.byType(GyeDedicationLayer)).aspectRatio,
        closeTo(1600 / 1700, 0.001),
      );
    },
  );
  testWidgets('estate image failure can retry without replacing the route', (
    tester,
  ) async {
    final bundle = _FlakyEstateBundle();
    await tester.pumpWidget(
      app(
        DefaultAssetBundle(
          bundle: bundle,
          child: const Scaffold(body: IlDuR16EstateArtwork()),
        ),
      ),
    );
    final t = AppL10n.of(tester.element(find.byType(IlDuR16EstateArtwork)));
    await pumpUntilFound(tester, find.text(t.btnRetry));
    expect(find.text(t.btnRetry), findsOneWidget);
    bundle.fail = false;
    await tester.tap(find.text(t.btnRetry));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('r16-estate-image-1')),
    );
    await tester.runAsync(() async {
      await precacheImage(
        AssetImage(kIlDuR16EstateAsset, bundle: bundle),
        tester.element(find.byType(IlDuR16EstateArtwork)),
      );
    });
    await pumpSoriStage(tester);
    expect(find.text(t.btnRetry), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FlakyEstateBundle extends R16TestAssetBundle {
  bool fail = true;
  @override
  Future<ByteData> load(String key) {
    if (fail && key == kIlDuR16EstateAsset) {
      return Future.error(StateError('image unavailable'));
    }
    return super.load(key);
  }
}
