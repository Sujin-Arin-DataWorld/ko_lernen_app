import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/c_stage_chrome.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/services/yeopjeon_wallet_notifier.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/gye_weekly_lanterns.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/top_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'yeopjeon_wallet_notifier_test.dart' show wallet;

const _promise = GyeMeta(
  id: 'actual-group-17',
  name: 'Mondhof',
  code: 'ABC234',
  ownerId: 'owner',
  memberCount: 3,
  weeklyPromiseSchemaVersion: 1,
  weeklyPromiseId: 'cafe_order',
  weeklyPromiseTarget: 3,
  weeklyPromiseProgress: 1,
);
const _today = TodayLearningSnapshot(
  pick: ReviewPick(dueCount: 3),
  dueCount: 3,
  destination: TodayLearningDestination(route: '/review'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const evidenceDir = String.fromEnvironment('C5_LIVE_EVIDENCE_DIR');
  final captures = <Map<String, Object?>>[];
  late SarangchaeConstruction construction;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    construction = SarangchaeConstruction.fromJson(
      jsonDecode(File(SarangchaeConstruction.assetPath).readAsStringSync()),
    );
    await CImageCache.load('assets/illustrations/concept_c/material_atlas.png');
    await CImageCache.load('assets/illustrations/concept_c/hero_atlas.png');
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      'kl_preferred_mascot': 'tiger',
      Storage.yeopjeonWalletPreferenceKey: wallet(spent: true).encode(),
    });
    await Storage.init();
    MascotPreference.load();
  });
  tearDownAll(() {
    if (evidenceDir.isNotEmpty) {
      Directory(evidenceDir).createSync(recursive: true);
      File('$evidenceDir/capture-manifest.json').writeAsStringSync(
        jsonEncode({
          'evidence':
              'Actual runtime body widgets, approved native fonts and navigation. Explicit local fixtures: owned stage 1, balance 0, promise 1/3; not a device account.',
          'captures': captures,
        }),
      );
    }
  });

  for (final language in ['de', 'en']) {
    for (final width in [320.0, 393.0]) {
      for (final safeInsets in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            '$language $width ${scale * 100}% safe=$safeInsets live C5 body, fold and route ownership',
            (tester) async {
              tester.view.physicalSize = Size(width, width == 320 ? 640 : 873);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final owner = YeopjeonWalletNotifier();
              await owner.refresh();
              addTearDown(owner.dispose);
              final focus = LearningFocusController();
              focus.value = const LearningFocus(
                today: _today,
                destination: TodayLearningDestination(route: '/review'),
              );
              addTearDown(focus.dispose);
              final opened = <String>[];
              final prefs = await SharedPreferences.getInstance();
              final ledgerBefore = prefs.getString(
                Storage.yeopjeonWalletPreferenceKey,
              );
              final snapshot = SoriStageProgressionSnapshot(
                today: _today,
                hanokCompetence: const HanokCompetenceProjection.empty(),
                quests: const [],
                pendingBojagiCount: 0,
                stampCount: 0,
                xp: 0,
                streakDays: 0,
                todayReward: null,
                wallet: wallet(spent: true),
              );
              for (final state in ['today', 'hanok', 'gye', 'gye-empty']) {
                final boundary = GlobalKey();
                Widget root = switch (state) {
                  'today' => SoriStageTodayScreen(
                    loadSnapshot: () async => snapshot,
                    now: () => DateTime(2026, 10, 30, 9),
                  ),
                  'hanok' => SoriStageHanokScreen(
                    loadSnapshot: () async => snapshot,
                    loadConstruction: () async => construction,
                  ),
                  _ => SoriStageGyeScreen(
                    loadGyeMetas: () async => state == 'gye' ? [_promise] : [],
                    onContinueSolo: () => opened.add('solo'),
                  ),
                };
                root = SoriWalletScope(
                  notifier: owner,
                  child: LearningFocusScope(
                    controller: focus,
                    open: (_, destination, {focus, activityId}) async =>
                        opened.add('${destination.route}:$activityId'),
                    child: root,
                  ),
                );
                await tester.pumpWidget(
                  MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightFor(
                      PaletteVariant.dancheong,
                      locale: Locale(language),
                    ),
                    locale: Locale(language),
                    supportedLocales: AppL10n.supportedLocales,
                    localizationsDelegates: AppL10n.localizationsDelegates,
                    onGenerateRoute: (settings) {
                      opened.add('${settings.name}:${settings.arguments}');
                      return MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: Text('destination')),
                      );
                    },
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: true,
                        padding: safeInsets
                            ? const EdgeInsets.symmetric(vertical: 24)
                            : EdgeInsets.zero,
                        viewPadding: safeInsets
                            ? const EdgeInsets.symmetric(vertical: 24)
                            : EdgeInsets.zero,
                      ),
                      child: child!,
                    ),
                    home: RepaintBoundary(
                      key: boundary,
                      child: Scaffold(
                        body: root,
                        bottomNavigationBar: SoriAdaptiveNavigation(
                          selectedIndex: state == 'today'
                              ? 0
                              : state == 'hanok'
                              ? 3
                              : 4,
                          onDestinationSelected: (_) {},
                          items: [
                            for (final asset in [
                              ApprovedChromeAssets.today,
                              ApprovedChromeAssets.learn,
                              ApprovedChromeAssets.games,
                              ApprovedChromeAssets.hanok,
                              ApprovedChromeAssets.gye,
                            ])
                              SoriAdaptiveNavigationItem(
                                label: asset,
                                imageAsset: asset,
                                icon: Icons.circle,
                                selectedIcon: Icons.circle,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                for (var i = 0; i < 8; i++) {
                  await tester.pump(const Duration(milliseconds: 100));
                }
                await settleEinleitungCaptureAssets(tester);
                final t = lookupAppL10n(Locale(language));
                expect(find.byType(CStageBackground), findsOneWidget);
                if (state == 'today') {
                  expect(
                    tester
                        .getSize(
                          find.byKey(
                            const ValueKey('learning-companion-ground'),
                          ),
                        )
                        .height,
                    greaterThanOrEqualTo(100),
                  );
                }
                if (state == 'gye') {
                  expect(
                    tester
                        .getSize(find.byKey(const ValueKey('c-gye-group-hero')))
                        .height,
                    width == 320 ? 80 : 152,
                  );
                }
                final action = switch (state) {
                  'today' => find.byKey(const ValueKey('learning-focus-start')),
                  'hanok' => find.byKey(
                    const ValueKey('hanok-construction-entry'),
                  ),
                  'gye' => find.text(t.gyeOpenCta),
                  _ => find.byKey(const ValueKey('gye-empty-start')),
                };
                expect(action, findsOneWidget);
                final actionBox = state == 'gye'
                    ? find.ancestor(
                        of: action,
                        matching: find.byType(CMaterialAction),
                      )
                    : action;
                expect(
                  tester.getSize(actionBox).height,
                  greaterThanOrEqualTo(48),
                );
                if (scale == 1) {
                  final nav = tester.getRect(
                    find.byType(SoriAdaptiveNavigation),
                  );
                  expect(
                    tester.getRect(actionBox).bottom,
                    lessThanOrEqualTo(nav.top),
                    reason: '$state main action must be in first fold',
                  );
                }
                if (state == 'hanok') {
                  expect(find.text('1 / 16'), findsOneWidget);
                  expect(
                    find.byKey(const ValueKey('hanok-owned-dot-16')),
                    findsOneWidget,
                  );
                  expect(
                    tester
                        .widget<DecoratedBox>(
                          find.byKey(const ValueKey('hanok-owned-dot-2')),
                        )
                        .decoration,
                    isNot(
                      tester
                          .widget<DecoratedBox>(
                            find.byKey(const ValueKey('hanok-owned-dot-1')),
                          )
                          .decoration,
                    ),
                  );
                }
                if (state == 'hanok' && scale == 1) {
                  final nav = tester.getRect(
                    find.byType(SoriAdaptiveNavigation),
                  );
                  for (final id in ['quests', 'dojang', 'bojagi', 'furnish']) {
                    final shortcut = find.byKey(ValueKey('hanok-shortcut-$id'));
                    expect(
                      tester.getSize(shortcut).height,
                      greaterThanOrEqualTo(48),
                    );
                    expect(
                      tester.getRect(shortcut).bottom,
                      lessThanOrEqualTo(nav.top),
                      reason: '$id stays in first fold',
                    );
                  }
                }
                if (state == 'gye') {
                  expect(find.byType(GyeWeeklyGoalProgress), findsOneWidget);
                  expect(find.text(t.gyePromiseProgress(1, 3)), findsOneWidget);
                  expect(
                    find.byKey(const ValueKey('gye-weekly-lantern-2')),
                    findsOneWidget,
                  );
                }
                expect(tester.takeException(), isNull);
                if (evidenceDir.isNotEmpty && !safeInsets) {
                  final path =
                      '$evidenceDir/$state-$language-${width.toInt()}-${(scale * 100).toInt()}.png';
                  await tester.runAsync(() async {
                    final render =
                        boundary.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary;
                    final image = await render.toImage(pixelRatio: 1);
                    final bytes = await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    await Directory(evidenceDir).create(recursive: true);
                    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
                    image.dispose();
                  });
                  captures.add({
                    'state': state,
                    'locale': language,
                    'width': width,
                    'scale': scale,
                    'actionBottom': tester.getRect(actionBox).bottom,
                    'path': path,
                  });
                }
                if (state != 'gye-empty') {
                  if (actionBox.hitTestable().evaluate().isEmpty) {
                    await Scrollable.ensureVisible(
                      tester.element(actionBox),
                      alignment: .6,
                    );
                    await tester.pump();
                  }
                  expect(actionBox.hitTestable(), findsOneWidget);
                  await tester.tap(actionBox);
                  await tester.pump();
                  if (state == 'today') {
                    expect(opened.last, '/review:srs');
                  }
                  if (state == 'hanok') {
                    expect(opened.last, '/hanok/construction:null');
                  }
                  if (state == 'gye') {
                    expect(opened.last, '/gye:actual-group-17');
                  }
                }
                expect(
                  prefs.getString(Storage.yeopjeonWalletPreferenceKey),
                  ledgerBefore,
                );
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.pump();
              }
            },
          );
        }
      }
    }
  }
}
