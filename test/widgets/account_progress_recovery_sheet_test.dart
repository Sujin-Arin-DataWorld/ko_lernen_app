import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/account/account_switch_resolution.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_progress_recovery_sheet.dart';

import '../support/real_fonts.dart';

AccountSwitchResolutionPreview preview({
  bool device = true,
  bool cloud = true,
  String deviceLevel = 'a1',
}) => AccountSwitchResolutionPreview(
  devicePlacementLevel: deviceLevel,
  cloudPlacementLevel: 'a2',
  deviceCompletedUnitCount: 1,
  cloudCompletedUnitCount: 3,
  canChooseDevice: device,
  canChooseCloud: cloud,
  binding: 'PRIVATE_UID_TOKEN_CONTEXT_CANARY',
);

Future<void> openSheet(
  WidgetTester tester,
  AccountSwitchResolutionPreview value, {
  String language = 'de',
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = false,
  required ValueChanged<AccountSwitchResolutionSide?> onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: RepaintBoundary(
          key: const Key('recovery-render'),
          child: child!,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open-recovery'),
              onPressed: () async => onResult(
                await showAccountProgressRecoverySheet(
                  context: context,
                  preview: value,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-recovery')));
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('ACCOUNT_RECOVERY_CAPTURE_DIR');
  if (output.isEmpty) {
    return;
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('recovery-render')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('explicit choice is required and the selected side is returned', (
    tester,
  ) async {
    AccountSwitchResolutionSide? result;
    var completed = false;
    await openSheet(
      tester,
      preview(),
      onResult: (value) {
        completed = true;
        result = value;
      },
    );
    expect(find.text('Wo möchtest du weiterlernen?'), findsOneWidget);
    expect(find.text('1 Einheit geschafft'), findsOneWidget);
    expect(find.text('3 Einheiten geschafft'), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pump();
    expect(completed, isFalse);
    await tester.tap(find.byKey(const Key('account-recovery-cloud')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pumpAndSettle();
    expect(result, AccountSwitchResolutionSide.cloud);
  });

  testWidgets('an inadmissible side cannot be selected or confirmed', (
    tester,
  ) async {
    var completed = false;
    await openSheet(
      tester,
      preview(device: false),
      onResult: (_) => completed = true,
    );
    expect(
      find.text(
        'Dieser Startpunkt passt nicht zu deinen gespeicherten Abschlüssen.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('account-recovery-device')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pump();
    expect(completed, isFalse);
  });

  testWidgets('one admissible side still needs explicit selection', (
    tester,
  ) async {
    var completed = false;
    await openSheet(
      tester,
      preview(cloud: false),
      onResult: (_) => completed = true,
    );
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pump();
    expect(completed, isFalse);
    await tester.tap(find.byKey(const Key('account-recovery-device')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-recovery-confirm')));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets(
    'cancel returns no choice and private bindings are never rendered',
    (tester) async {
      AccountSwitchResolutionSide? result = AccountSwitchResolutionSide.device;
      await openSheet(tester, preview(), onResult: (value) => result = value);
      expect(
        find.textContaining('PRIVATE_UID_TOKEN_CONTEXT_CANARY'),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('account-recovery-cancel')));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );

  for (final language in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(900, 900),
      ]) {
        testWidgets(
          '${size.width}dp $language ${scale}x keeps text scale and actions reachable',
          (tester) async {
            await openSheet(
              tester,
              preview(),
              language: language,
              size: size,
              textScale: scale,
              reduceMotion: size.width >= 900,
              onResult: (_) {},
            );
            final name = '${size.width.toInt()}-$language-${scale.toInt()}x';
            await capture(tester, '$name-top');
            final choice = find.byKey(const Key('account-recovery-cloud'));
            expect(choice, findsOneWidget);
            expect(
              MediaQuery.textScalerOf(tester.element(choice)).scale(10),
              closeTo(10 * scale, .001),
            );
            await tester.ensureVisible(choice);
            await tester.tap(choice);
            await tester.pump();
            final confirm = find.byKey(const Key('account-recovery-confirm'));
            await tester.ensureVisible(confirm);
            await tester.pumpAndSettle();
            await capture(tester, '$name-actions');
            expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
            await tester.tap(confirm);
            await tester.pumpAndSettle();
            expect(find.byType(AccountProgressRecoverySheet), findsNothing);
          },
        );
      }
    }
  }
}
