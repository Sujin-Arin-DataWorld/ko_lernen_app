import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/welcome_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';

const _capture = Key('welcome-native-capture');
const _output = String.fromEnvironment('EINLEITUNG_EVIDENCE_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(393, 873),
      const Size(402, 934),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'welcome full bleed and native text $language $size $scale',
          (tester) async {
            var starts = 0, later = 0;
            await _pump(
              tester,
              scale,
              WelcomeScreen(
                onStart: () async => starts++,
                onLater: () => later++,
              ),
              size: size,
              language: language,
            );
            await settleEinleitungCaptureAssets(tester);
            if (size.width == 393) {
              await _write(
                tester,
                'welcome-$language-393-873-${scale == 1 ? '100' : '200'}',
              );
            }
            final t = lookupAppL10n(Locale(language));
            expect(find.text(t.welcomeTitle), findsOneWidget);
            expect(find.text(t.welcomeBody), findsOneWidget);
            _expectCompleteParagraph(tester, find.text(t.welcomeTitle));
            _expectCompleteParagraph(tester, find.text(t.welcomeBody));
            final art = tester.widget<Image>(
              find.byKey(const ValueKey('welcome-whole-art')),
            );
            expect(art.fit, BoxFit.cover);
            final viewport = Offset.zero & size;
            expect(
              tester.getRect(find.byKey(const ValueKey('welcome-whole-art'))),
              viewport,
            );
            final renderedArt = tester.renderObject<RenderImage>(
              find.descendant(
                of: find.byKey(const ValueKey('welcome-whole-art')),
                matching: find.byType(RawImage),
              ),
            );
            expect(renderedArt.image, isNotNull);
            final fit = applyBoxFit(
              BoxFit.cover,
              Size(
                renderedArt.image!.width.toDouble(),
                renderedArt.image!.height.toDouble(),
              ),
              renderedArt.size,
            );
            expect(
              fit.destination,
              size,
              reason: 'The decoded front image must fill the entire Scaffold.',
            );
            if (scale == 1) {
              expect(find.byType(Scrollable), findsNothing);
              final safeViewport = Rect.fromLTWH(
                0,
                62,
                size.width,
                size.height - 96,
              );
              for (final target in [
                find.text(t.welcomeTitle),
                find.text(t.welcomeBody),
                find.byKey(const ValueKey('welcome-start')),
                find.byKey(const ValueKey('welcome-later')),
              ]) {
                final rect = tester.getRect(target);
                expect(safeViewport.contains(rect.topLeft), isTrue);
                expect(
                  safeViewport.contains(
                    rect.bottomRight - const Offset(.01, .01),
                  ),
                  isTrue,
                );
              }
            }
            await tester.ensureVisible(
              find.byKey(const ValueKey('welcome-start')),
            );
            await tester.tap(find.byKey(const ValueKey('welcome-start')));
            await tester.pump();
            expect(starts, 1);
            await tester.ensureVisible(
              find.byKey(const ValueKey('welcome-later')),
            );
            await tester.tap(find.byKey(const ValueKey('welcome-later')));
            expect(later, 1);
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('welcome-start')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('welcome-later')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getRect(find.byKey(const ValueKey('welcome-whole-art'))),
              viewport,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('welcome failed write keeps both actions and retries', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      1,
      WelcomeScreen(
        onStart: () async {
          if (++calls == 1) {
            throw StateError('fixture write failure');
          }
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pump();
    expect(
      find.text(lookupAppL10n(const Locale('de')).loadErrorTryAgain),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('welcome pending start disables both actions', (tester) async {
    final pending = Completer<void>();
    var starts = 0, later = 0;
    await _pump(
      tester,
      1,
      WelcomeScreen(
        onStart: () {
          starts++;
          return pending.future;
        },
        onLater: () => later++,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.tap(find.byKey(const ValueKey('welcome-later')));
    expect(starts, 1);
    expect(later, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  double scale,
  Widget home, {
  Size size = const Size(402, 934),
  String language = 'de',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 62, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}

void _expectCompleteParagraph(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final natural = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textHeightBehavior: paragraph.textHeightBehavior,
    textWidthBasis: paragraph.textWidthBasis,
  )..layout(maxWidth: paragraph.size.width);
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.size.height, greaterThanOrEqualTo(natural.height - .1));
  natural.dispose();
}

Future<void> _write(WidgetTester tester, String name) async {
  if (_output.isEmpty) {
    return;
  }
  await settleEinleitungCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(_output)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
