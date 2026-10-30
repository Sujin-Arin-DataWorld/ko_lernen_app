import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_wallet_notifier.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/settings_button.dart';
import 'package:ko_lernen_app/widgets/sori/top_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';
import 'yeopjeon_wallet_notifier_test.dart' show wallet;

void main() {
  const evidenceDir = String.fromEnvironment('TOP_CHROME_EVIDENCE_DIR');
  final captures = <Map<String, Object>>[];
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });
  tearDownAll(() {
    if (evidenceDir.isNotEmpty) {
      File('$evidenceDir/capture-manifest.json').writeAsStringSync(
        jsonEncode({
          'source':
              'Actual AppShell route widgets with a confirmed local test ledger; not a device account capture',
          'captures': captures,
        }),
      );
    }
  });
  setUp(() async {
    LearningJourneyObserver.shared.cancel();
    CourseProgressService.shared.resetForTesting();
    Storage.resetForTesting();
    AppShell.requestedStageTab.value = -1;
    SharedPreferences.setMockInitialValues({
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      Storage.yeopjeonWalletPreferenceKey: wallet().encode(),
    });
    await Storage.init();
  });

  for (final language in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 393.0]) {
        testWidgets(
          '$language $width ${scale * 100}% all five actual roots share chrome and real money',
          (tester) async {
            tester.view.physicalSize = Size(width, width == 320 ? 640 : 873);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                locale: Locale(language),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: RepaintBoundary(key: boundary, child: const AppShell()),
              ),
            );
            await pumpSoriStage(tester);
            final t = lookupAppL10n(Locale(language));
            final names = [
              t.soriStageNavToday,
              t.soriStageNavLearn,
              t.soriStageNavGames,
              t.soriStageNavHanok,
              t.soriStageNavGye,
            ];
            final owners = <YeopjeonWalletNotifier>{};
            for (var index = 0; index < 5; index++) {
              if (index > 0) {
                await tester.tap(find.byTooltip(names[index]).last);
                await pumpSoriStage(tester);
              }
              final gear = find.byType(SoriSettingsButton);
              expect(gear, findsOneWidget);
              expect(
                tester.getSize(gear).shortestSide,
                greaterThanOrEqualTo(48),
              );
              final cloud = find.byWidgetPredicate(
                (w) =>
                    w is ApprovedChromeImage &&
                    w.asset == ApprovedChromeAssets.cloud,
              );
              expect(cloud, findsOneWidget);
              final badge = find.byKey(
                const ValueKey('yeopjeon-header-balance'),
              );
              expect(badge, findsOneWidget, reason: names[index]);
              expect(
                find.descendant(of: badge, matching: find.text('40')),
                findsOneWidget,
              );
              expect(tester.getSize(badge).height, greaterThanOrEqualTo(48));
              owners.add(SoriWalletScope.maybeOf(tester.element(gear))!);
              expect(
                find.byKey(const ValueKey('sori-root-top-chrome')),
                index == 0 ? findsNothing : findsOneWidget,
              );
              if (evidenceDir.isNotEmpty) {
                await settleEinleitungCaptureAssets(tester);
                final repaint =
                    boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final path =
                    '$evidenceDir/$index-$language-${width.toInt()}-${(scale * 100).toInt()}.png';
                await tester.runAsync(() async {
                  final shot = await repaint
                      .toImage(pixelRatio: 1)
                      .timeout(const Duration(seconds: 30));
                  final bytes = await shot
                      .toByteData(format: ui.ImageByteFormat.png)
                      .timeout(const Duration(seconds: 30));
                  await Directory(evidenceDir).create(recursive: true);
                  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
                  shot.dispose();
                });
                captures.add({
                  'tab': names[index],
                  'language': language,
                  'width': width,
                  'textScale': scale,
                  'ledgerBalance': 40,
                  'path': path,
                });
              }
              if (index > 0) {
                final viewport = find.byType(CustomScrollView).first;
                await tester.drag(viewport, const Offset(0, -220));
                await pumpSoriStage(tester);
                expect(gear.hitTestable(), findsOneWidget);
                expect(badge.hitTestable(), findsOneWidget);
              }
              for (final paragraph in tester.renderObjectList<RenderParagraph>(
                find.byType(RichText),
              )) {
                if (paragraph.text.toPlainText() == names[index]) {
                  expect(paragraph.didExceedMaxLines, isFalse);
                }
              }
              expect(tester.takeException(), isNull);
            }
            expect(owners, hasLength(1));
            await Storage.writeYeopjeonRawJsonStrict(
              wallet(spent: true).encode(),
            );
            await tester.tap(find.byTooltip(names.first).last);
            await pumpSoriStage(tester);
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('yeopjeon-header-balance')),
                matching: find.text('0'),
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
}
