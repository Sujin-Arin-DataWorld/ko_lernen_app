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

const _capture = Key('welcome-native-capture');
const _output = String.fromEnvironment('EINLEITUNG_EVIDENCE_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadEinleitungFonts);
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('welcome native actions and full text $scale', (tester) async {
      var starts = 0, later = 0;
      await _pump(
        tester,
        scale,
        WelcomeScreen(onStart: () async => starts++, onLater: () => later++),
      );
      await settleEinleitungCaptureAssets(tester);
      await _write(tester, 'welcome-${scale == 1 ? '402-100' : '320-200'}');
      final art = tester.widget<Image>(
        find.byKey(const ValueKey('welcome-whole-art')),
      );
      expect(art.fit, BoxFit.contain);
      if (scale == 1) {
        final scene = tester.getRect(
          find.byKey(const ValueKey('welcome-reference-scene')),
        );
        final start = tester.getRect(
          find.byKey(const ValueKey('welcome-start')),
        );
        expect(scene.width, 402);
        expect(scene.height, closeTo(402 * 1672 / 941, .001));
        expect(scene.center.dy, 467);
        expect(start.left, closeTo(84.5, .001));
        expect(start.top - scene.top, closeTo(601.5, .001));
        expect(start.size, const Size(233, 50));
      }
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-start')));
      await tester.tap(find.byKey(const ValueKey('welcome-start')));
      await tester.pump();
      expect(starts, 1);
      await tester.ensureVisible(find.byKey(const ValueKey('welcome-later')));
      if (scale == 2) {
        await _write(tester, 'welcome-320-200-actions');
      }
      await tester.tap(find.byKey(const ValueKey('welcome-later')));
      expect(later, 1);
      expect(
        tester.getSize(find.byKey(const ValueKey('welcome-start'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });
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

Future<void> _pump(WidgetTester tester, double scale, Widget home) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = scale == 1
      ? const Size(402, 934)
      : const Size(320, 740);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
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
