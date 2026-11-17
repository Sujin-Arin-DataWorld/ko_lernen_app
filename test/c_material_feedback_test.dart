import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_objects.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_wallet_card.dart';

void main() {
  testWidgets('selection changes only the rim, including rapid reversal', (
    tester,
  ) async {
    Widget panel(bool selected, {bool reduced = false, bool active = true}) =>
        _app(
          IntroPanel(
            selected: selected,
            child: const SizedBox(
              key: ValueKey('panel-content'),
              width: 180,
              height: 80,
            ),
          ),
          reduced: reduced,
          active: active,
        );
    BoxBorder border() =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byType(IntroPanel),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .border!;
    await tester.pumpWidget(panel(false));
    final content = find.byKey(const ValueKey('panel-content'));
    final bounds = tester.getRect(content);
    final idle = border();
    await tester.pumpWidget(panel(true));
    await tester.pump(const Duration(milliseconds: 70));
    expect(border(), isNot(idle));
    expect(tester.getRect(content), bounds);
    await tester.pumpWidget(panel(false));
    await tester.pumpAndSettle();
    expect(border(), idle);
    expect(tester.getRect(content), bounds);
    await tester.pumpWidget(panel(true, reduced: true));
    final selected = border();
    await tester.pumpWidget(panel(false, active: false));
    expect(border(), idle);
    await tester.pumpWidget(panel(true, active: false));
    expect(border(), selected);
    expect(tester.getRect(content), bounds);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'CTA contact keeps bounds and accepts exactly one native action',
    (tester) async {
      var taps = 0;
      Widget button({bool disabled = false, bool reduced = false}) => _app(
        SizedBox(
          width: 280,
          child: CMaterialAction(
            label: 'Weiter',
            onTap: disabled ? null : () => taps++,
          ),
        ),
        reduced: reduced,
      );
      await tester.pumpWidget(button());
      final action = find.byType(CMaterialAction);
      final bounds = tester.getRect(action);
      final arrow = find.byType(CArrow);
      final rest = tester.getCenter(arrow);
      final gesture = await tester.startGesture(tester.getCenter(action));
      await tester.pump();
      await tester.pump(SoriMotion.fast);
      expect(tester.getRect(action), bounds);
      expect(tester.getCenter(arrow).dx, greaterThan(rest.dx));
      await gesture.up();
      expect(taps, 1);
      await tester.pumpAndSettle();
      expect(tester.getCenter(arrow), rest);
      final held = await tester.startGesture(tester.getCenter(action));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('c-material-cta-direction')),
            )
            .transform
            .getTranslation()
            .x,
        0,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await held.cancel();
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.pumpWidget(button(disabled: true, reduced: true));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.getRect(action), bounds);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmed balance changes immediately and only its rim animates',
    (tester) async {
      await tester.pumpWidget(_badge(0));
      final badge = find.byKey(const ValueKey('yeopjeon-header-balance'));
      final bounds = tester.getRect(badge);
      expect(await _rimPixelCount(tester), 0, reason: 'No entrance animation.');
      await tester.pumpWidget(_badge(40));
      expect(find.text('40'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await _rimPixelCount(tester), greaterThan(0));
      expect(tester.getRect(badge).height, bounds.height);
      await tester.pumpWidget(_badge(0));
      expect(find.text('0'), findsOneWidget);
      expect(find.text('40'), findsNothing);
      await tester.pumpAndSettle();
      expect(await _rimPixelCount(tester), 0);
      await tester.pumpWidget(_badge(0));
      expect(
        await _rimPixelCount(tester),
        0,
        reason: 'Same snapshot stays quiet.',
      );
    },
  );

  for (final mode in ['reduced', 'hidden', 'background']) {
    testWidgets('$mode settles balance feedback without delayed replay', (
      tester,
    ) async {
      await tester.pumpWidget(_badge(0));
      await tester.pumpWidget(_badge(40));
      await tester.pump(const Duration(milliseconds: 60));
      expect(await _rimPixelCount(tester), greaterThan(0));
      if (mode == 'background') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
      } else {
        await tester.pumpWidget(
          _badge(40, reduced: mode == 'reduced', active: mode != 'hidden'),
        );
      }
      expect(await _rimPixelCount(tester), 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(_badge(40));
      await tester.pump(const Duration(milliseconds: 100));
      expect(await _rimPixelCount(tester), 0);
      expect(find.text('40'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }
}

Widget _app(Widget child, {bool reduced = false, bool active = true}) =>
    MaterialApp(
      theme: AppTheme.light,
      themeAnimationDuration: Duration.zero,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: active,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

Widget _badge(int balance, {bool reduced = false, bool active = true}) => _app(
  YeopjeonWalletBadge(
    wallet: YeopjeonWallet(
      balance: balance,
      sarangchaeEligibleStage: balance == 40 ? 1 : 0,
      b2EligibleStage: 0,
      sarangchaeOwnedStage: 0,
      b2OwnedStage: 0,
      grandfatheredSarangchaeStage: 0,
      grandfatheredB2Stage: 0,
      claims: balance == 40 ? const {'milestone:s:1': 40} : const {},
      completedSourceIds: const {},
      reviewedSourceIds: const {},
    ),
  ),
  reduced: reduced,
  active: active,
);

/// Inspect the actual foreground paint separately from async artwork decoding.
Future<int> _rimPixelCount(WidgetTester tester) async {
  final paint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey('yeopjeon-confirmed-balance-feedback')),
  );
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    paint.foregroundPainter!.paint(Canvas(recorder), const Size(180, 48));
    final picture = recorder.endRecording();
    final image = await picture.toImage(180, 48);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    final bytes = data!.buffer.asUint8List();
    var count = 0;
    for (var index = 3; index < bytes.length; index += 4) {
      if (bytes[index] > 0) count++;
    }
    return count;
  }))!;
}
