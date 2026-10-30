import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/dure_weekly_heading.dart';
import 'package:ko_lernen_app/widgets/sori/gye_weekly_lanterns.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() => SharedPreferences.setMockInitialValues({'kl_xp': 42}));

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    String lang = 'de',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        theme: AppTheme.light,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, body) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: body!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  GyeMeta promise(int progress) => GyeMeta(
    id: 'ABC234',
    name: 'Moon courtyard',
    code: 'ABC234',
    ownerId: 'owner',
    weeklyPromiseSchemaVersion: 1,
    weeklyPromiseId: 'cafe_order',
    weeklyPromiseTarget: 3,
    weeklyPromiseProgress: progress,
  );

  String assetPath(Image image) {
    final provider = image.image;
    final original = provider is ResizeImage
        ? provider.imageProvider
        : provider;
    return (original as AssetImage).assetName;
  }

  testWidgets(
    'only confirmed promise contributions light their source lantern',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      for (var done = 0; done <= 3; done++) {
        await show(
          tester,
          GyeWeeklyGoalProgress(meta: promise(done)),
          lang: 'en',
        );
        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        expect(images, hasLength(3));
        expect(
          images.where(
            (image) => assetPath(image) == GyeWeeklyLanternAssets.lit,
          ),
          hasLength(done),
        );
        expect(
          images.where(
            (image) => assetPath(image) == GyeWeeklyLanternAssets.off,
          ),
          hasLength(3 - done),
        );
        expect(find.byType(ColorFiltered), findsNothing);
      }
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  testWidgets('legacy packs earn one weekly lantern at the actual goal only', (
    tester,
  ) async {
    for (final done in [0, 3, 5]) {
      await show(
        tester,
        GyeWeeklyGoalProgress(
          meta: GyeMeta(
            id: 'ABC234',
            name: 'Moon courtyard',
            code: 'ABC234',
            ownerId: 'owner',
            weeklyGoalPacks: 5,
            weeklyGoalProgress: done,
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        assetPath(image),
        done >= 5 ? GyeWeeklyLanternAssets.lit : GyeWeeklyLanternAssets.off,
      );
      expect(find.text('$done / 5'), findsOneWidget);
    }
  });

  for (final lang in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$lang 320dp at ${scale * 100}% keeps weekly headings outside progress',
        (tester) async {
          await show(
            tester,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GyeWeeklyGoalProgress(meta: promise(2)),
                const SizedBox(height: 16),
                const DureWeeklyHeading(total: 1234, goal: 5678, done: false),
              ],
            ),
            lang: lang,
            scale: scale,
          );
          final t = lookupAppL10n(Locale(lang));
          expect(find.text(t.statsThisWeek), findsOneWidget);
          expect(find.text(t.gyePromiseProgress(2, 3)), findsOneWidget);
          final heading = tester.getRect(
            find.byKey(const ValueKey('gye-weekly-heading')),
          );
          final label = tester.getRect(
            find.byKey(const ValueKey('gye-weekly-progress-label')),
          );
          expect(heading.overlaps(label), isFalse);
          expect(label.top, greaterThanOrEqualTo(heading.bottom + 4));
          final title = tester.getRect(
            find.byKey(const ValueKey('gye-dure-week-heading')),
          );
          final amount = tester.getRect(
            find.byKey(const ValueKey('gye-dure-week-amount')),
          );
          expect(title.overlaps(amount), isFalse);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.byKey(const ValueKey('gye-dure-week-heading')),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        },
      );
    }
  }

  if (const bool.fromEnvironment('CAPTURE_GYE_LANTERN_EVIDENCE')) {
    testWidgets('capture weekly lantern source state in both languages', (
      tester,
    ) async {
      final directory = Directory(
        'C:/dev/hangulsori/_codex_artifacts/gye-lantern-20261030/captures',
      )..createSync(recursive: true);
      for (final lang in ['de', 'en']) {
        for (final scale in [1.0, 2.0]) {
          final boundary = GlobalKey();
          await show(
            tester,
            RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: AppTheme.light.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GyeWeeklyGoalProgress(meta: promise(2)),
                      const SizedBox(height: 16),
                      const DureWeeklyHeading(total: 2, goal: 3, done: false),
                    ],
                  ),
                ),
              ),
            ),
            lang: lang,
            scale: scale,
          );
          final context = boundary.currentContext!;
          await tester.runAsync(() async {
            for (final image in tester.widgetList<Image>(find.byType(Image))) {
              await precacheImage(image.image, context);
            }
          });
          await tester.pump();
          await tester.runAsync(() async {
            final render = context.findRenderObject() as RenderRepaintBoundary;
            final picture = await render.toImage(pixelRatio: 1);
            final bytes = (await picture.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            File(
              '${directory.path}/weekly-$lang-${scale.toInt()}x.png',
            ).writeAsBytesSync(bytes.buffer.asUint8List());
            picture.dispose();
          });
        }
      }
    });
  }
}
