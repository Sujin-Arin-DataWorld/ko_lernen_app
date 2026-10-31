import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/canonical_companion_art.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_widgets.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/features/guide/today_guide_section.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/ildu_r16_layers.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/services/yeopjeon_wallet_notifier.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/image_navigation_bar.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/today_subject_art.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_r16_layer_artwork.dart';
import 'package:ko_lernen_app/widgets/sori/top_chrome.dart';
import 'package:ko_lernen_app/widgets/sori/week_progress.dart';

import 'support/catalog_test_support.dart' as catalog;
import 'support/real_fonts.dart';

// Real bundled curriculum and fonts, seeded account state; not a live account.
const _captureRoot = String.fromEnvironment('TODAY_DASHBOARD_CAPTURE_DIR');
late List<String> _previewCaptureAssets;

YeopjeonWallet _confirmedWallet({bool spent = false}) => YeopjeonWallet(
  balance: spent ? 0 : 40,
  sarangchaeEligibleStage: 1,
  b2EligibleStage: 0,
  sarangchaeOwnedStage: spent ? 1 : 0,
  b2OwnedStage: 0,
  grandfatheredSarangchaeStage: 0,
  grandfatheredB2Stage: 0,
  claims: const {'milestone:s:1': 40},
  completedSourceIds: const {},
  reviewedSourceIds: const {},
);

Future<void> _decodeCaptureAsset(String asset, {AssetBundle? bundle}) async {
  final ready = Completer<void>();
  final stream = AssetImage(
    asset,
    bundle: bundle,
  ).resolve(const ImageConfiguration(devicePixelRatio: 2));
  final listener = ImageStreamListener(
    (info, _) {
      info.dispose();
      if (!ready.isCompleted) ready.complete();
    },
    onError: (Object error, StackTrace? trace) {
      if (!ready.isCompleted) ready.completeError(error, trace);
    },
  );
  stream.addListener(listener);
  try {
    await ready.future;
  } finally {
    stream.removeListener(listener);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LearningFocus course;
  late List<ContentLesson> listening;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Keep the process-wide guide service's initial future outside the first
    // widget test's disposable FakeAsync zone.
    await GuideRuntime.progress.load();
    final construction = await SarangchaeConstruction.load();
    final layers = await IlDuR16LayerCatalog.load();
    final preview = layers
        .stagesByProcessId['ildu.${construction.stage(SarangchaeConstruction.stageCount).stageId}']!;
    _previewCaptureAssets = [preview.foreground.asset, preview.shadow.asset];
    await Future.wait([
      _decodeCaptureAsset(preview.foreground.asset),
      _decodeCaptureAsset(preview.shadow.asset),
    ]);
    await loadSoriRealFonts(materialIcons: true);
    course = await catalog.loadFirstCatalogFocus();
    listening = (await ContentLearningCatalog.load(
      LearningContentKind.listening,
    )).where((lesson) => lesson.level == 'a1').toList();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_preferred_mascot': 'tiger',
      'kl_tut_home_tour': true,
      Storage.yeopjeonWalletPreferenceKey: _confirmedWallet().encode(),
    });
    await Storage.init();
    MascotPreference.load();
  });

  for (final size in [
    const Size(320, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(393, 873),
    const Size(430, 932),
  ]) {
    for (final lang in ['de', 'en']) {
      for (final state in ['course', 'hangul', 'review']) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'approved Today $state $lang ${size.width.toInt()}x${size.height.toInt()} ${scale}x',
            (tester) async {
              tester.view.physicalSize = Size(size.width * 2, size.height * 2);
              tester.view.devicePixelRatio = 2;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final focus = switch (state) {
                'course' => course,
                'hangul' => const LearningFocus(
                  today: TodayLearningSnapshot(
                    pick: HangulIntroPick(),
                    destination: TodayLearningDestination(route: '/hangul'),
                  ),
                  destination: TodayLearningDestination(route: '/hangul'),
                ),
                _ => const LearningFocus(
                  today: TodayLearningSnapshot(
                    pick: ReviewPick(dueCount: 12),
                    dueCount: 12,
                    destination: TodayLearningDestination(route: '/review'),
                  ),
                  destination: TodayLearningDestination(route: '/review'),
                ),
              };
              final controller = LearningFocusController(
                loader: () async => focus,
              )..value = focus;
              if (size.width == 390 && scale == 1 && state == 'course') {
                await ContentLearningService.setGoal(
                  LearningContentKind.listening,
                  'a1',
                  1,
                );
                await ContentLearningService.startLesson(
                  listening.first,
                  listening,
                );
              }
              addTearDown(controller.dispose);
              final walletOwner = YeopjeonWalletNotifier();
              addTearDown(walletOwner.dispose);
              await walletOwner.refresh();
              expect(walletOwner.value.wallet!.balance, 40);
              MascotPreference.preference.value = state == 'hangul'
                  ? CompanionPreference.magpie
                  : CompanionPreference.tiger;
              final base = catalog.catalogSnapshot();
              var pendingBojagi = state == 'review' ? 3 : 0;
              SoriStageProgressionSnapshot snapshot() =>
                  SoriStageProgressionSnapshot(
                    today: focus.today,
                    hanokCompetence: base.hanokCompetence,
                    quests: const [
                      QuestProgress(
                        questId: 'q_jangdokdae',
                        current: 11,
                        target: 15,
                        active: true,
                        completed: false,
                        completedAtIso: null,
                      ),
                    ],
                    pendingBojagiCount: pendingBojagi,
                    stampCount: base.stampCount,
                    xp: base.xp,
                    streakDays: base.streakDays,
                    todayReward: base.todayReward,
                    wallet: walletOwner.value.wallet,
                  );
              TodayLearningDestination? opened;
              LearningFocus? openedFocus;
              String? openedActivity;
              var games = 0;
              final routes = <String>[];
              final capture = GlobalKey();
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: Locale(lang),
                  supportedLocales: AppL10n.supportedLocales,
                  localizationsDelegates: AppL10n.localizationsDelegates,
                  theme: AppTheme.lightFor(
                    PaletteVariant.dancheong,
                    locale: Locale(lang),
                  ),
                  onGenerateRoute: (settings) {
                    routes.add(settings.name!);
                    return MaterialPageRoute<void>(
                      settings: settings,
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(settings.name!)),
                        body: Text(
                          settings.name!,
                          key: const ValueKey('route-probe'),
                        ),
                      ),
                    );
                  },
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 24),
                      viewPadding: const EdgeInsets.only(top: 24),
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: SoriWalletScope(
                    notifier: walletOwner,
                    child: RepaintBoundary(
                      key: capture,
                      child: Builder(
                        builder: (context) {
                          final t = AppL10n.of(context);
                          return Scaffold(
                            body: LearningFocusScope(
                              controller: controller,
                              open:
                                  (_, destination, {focus, activityId}) async {
                                    opened = destination;
                                    openedFocus = focus;
                                    openedActivity = activityId;
                                  },
                              child: SoriStageTodayScreen(
                                loadSnapshot: () async => snapshot(),
                                now: () => DateTime(2026, 10, 31, 9),
                                forceStaticHero: true,
                                enableMilestoneCelebrations: false,
                                onOpenGames: () => games++,
                              ),
                            ),
                            bottomNavigationBar: SoriImageNavigationBar(
                              selectedIndex: 0,
                              onDestinationSelected: (_) {},
                              labels: [
                                t.soriStageNavToday,
                                t.soriStageNavLearn,
                                t.soriStageNavGames,
                                t.soriStageNavHanok,
                                t.soriStageNavGye,
                              ],
                              assets: const [
                                ApprovedChromeAssets.today,
                                ApprovedChromeAssets.learn,
                                ApprovedChromeAssets.games,
                                ApprovedChromeAssets.hanok,
                                ApprovedChromeAssets.gye,
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 500));
              // Allow actual PNG decoding before capturing; no live services used.
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 120));
              });
              await tester.pump();
              final captureBundle = DefaultAssetBundle.of(
                tester.element(find.byType(SoriStageTodayScreen)),
              );
              await tester.runAsync(
                () => Future.wait(
                  _previewCaptureAssets.map(
                    (asset) =>
                        _decodeCaptureAsset(asset, bundle: captureBundle),
                  ),
                ),
              );
              await tester.pump();
              await tester.pump();
              final scroll = find
                  .descendant(
                    of: find.byKey(const ValueKey('today-dashboard-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final position = tester.state<ScrollableState>(scroll).position;
              final cta = find.byKey(const ValueKey('learning-focus-start'));
              final card = find.byKey(const ValueKey('today-learning-card'));
              final hanokLayers = find.byWidgetPredicate(
                (widget) =>
                    widget is CustomPaint &&
                    widget.painter is IlDuR16LayerPainter,
              );
              if (size.width == 390 && scale == 1) {
                expect(
                  hanokLayers,
                  findsOneWidget,
                  reason:
                      'The explicit R16 preview must paint architecture, not a blank loading surface.',
                );
              }
              final metrics = {
                'state': state,
                'locale': lang,
                'scale': scale,
                'viewport': '${size.width.toInt()}x${size.height.toInt()}',
                'devicePixelRatio': tester.view.devicePixelRatio,
                'capturePixelRatio': 2,
                'hanokPreviewLayerPainters': hanokLayers.evaluate().length,
                'confirmedBalance': walletOwner.value.wallet!.balance,
                'pendingBojagiCount': pendingBojagi,
                'fixture': 'bundled_content_seeded_account_not_live',
                'maxScrollExtent': position.maxScrollExtent,
                'cta': tester.getRect(cta).toString(),
                'card': tester.getRect(card).toString(),
                'destination': focus.destination?.route,
                'activityId': focus.activityId,
              };
              debugPrint(metrics.toString());
              if (_captureRoot.isNotEmpty && size.width == 390) {
                await tester.runAsync(() async {
                  final dir = Directory(_captureRoot)
                    ..createSync(recursive: true);
                  final boundary =
                      capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary;
                  final image = await boundary.toImage(pixelRatio: 2);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '${dir.path}/today-$state-$lang-${scale}x.png',
                  ).writeAsBytes(bytes!.buffer.asUint8List());
                  image.dispose();
                  await File(
                    '${dir.path}/today-$state-$lang-${scale}x.txt',
                  ).writeAsString(metrics.toString());
                });
              }
              expect(tester.takeException(), isNull);
              if (scale == 1 && size.width == 390) {
                expect(position.maxScrollExtent, lessThanOrEqualTo(1));
              }
              expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
              final t = AppL10n.of(tester.element(card));
              final balance = find.byKey(
                const ValueKey('yeopjeon-header-balance'),
              );
              expect(
                find.descendant(of: balance, matching: find.text('40')),
                findsOneWidget,
              );
              if (state == 'review') {
                expect(find.text(t.homeReviewDue(12)), findsOneWidget);
              } else {
                expect(focus.today.dueCount, 0);
                expect(find.text(t.homeReviewDue(12)), findsNothing);
              }
              final portrait = find.descendant(
                of: find.byKey(const ValueKey('learning-companion-ground')),
                matching: find.byType(Image),
              );
              expect(
                (tester.widget<Image>(portrait).image as AssetImage).assetName,
                state == 'hangul'
                    ? CanonicalCompanionArt.magpiePortrait
                    : CanonicalCompanionArt.baekhoPortrait,
              );
              Future<void> reveal(Finder target) async {
                await tester.scrollUntilVisible(
                  target,
                  160,
                  scrollable: scroll,
                  maxScrolls: 30,
                );
                await tester.pumpAndSettle();
              }

              await reveal(cta);
              await tester.pumpAndSettle();
              await tester.tap(cta);
              await tester.pump();
              expect(opened, same(focus.destination));
              expect(openedFocus, same(focus));
              expect(openedActivity, focus.activityId);
              await reveal(find.text(t.todayQuickPlay));
              await tester.pumpAndSettle();
              await tester.tap(find.text(t.todayQuickPlay));
              await tester.pump();
              expect(games, 1);
              // Both live pending-reward routing and the empty-state furnishing
              // destination stay reachable even at the small/large-text viewports.
              Future<void> openRoute(Finder target, String expected) async {
                position.jumpTo(0);
                await tester.pump();
                await reveal(target);
                await tester.tap(target);
                await tester.pumpAndSettle();
                expect(routes.last, expected);
                expect(
                  find.byKey(const ValueKey('route-probe')),
                  findsOneWidget,
                );
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
              }

              final finds = find.byKey(const ValueKey('today-finds'));
              if (pendingBojagi == 3) {
                position.jumpTo(0);
                await tester.pump();
                await reveal(finds);
                expect(
                  find.descendant(
                    of: finds,
                    matching: find.textContaining('3'),
                  ),
                  findsWidgets,
                );
                pendingBojagi = 0;
                await openRoute(finds, '/bojagi');
              }
              await openRoute(finds, '/sarangbang/furnish');
              await openRoute(find.text(t.todayYourHanok), '/hanok');
              position.jumpTo(0);
              await tester.pump();
              await Storage.writeYeopjeonRawJsonStrict(
                _confirmedWallet(spent: true).encode(),
              );
              await walletOwner.refresh();
              await tester.pumpAndSettle();
              expect(walletOwner.value.wallet!.balance, 0);
              expect(walletOwner.value.wallet!.sarangchaeOwnedStage, 1);
              expect(
                find.descendant(of: balance, matching: find.text('0')),
                findsOneWidget,
              );
              expect(
                find.descendant(of: balance, matching: find.text('40')),
                findsNothing,
              );
              if (size.width == 390 && scale == 1 && state == 'course') {
                await tester.tap(find.byTooltip(t.soriStageProfileTooltip));
                await tester.pumpAndSettle();
                expect(routes.last, '/profile');
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
                await tester.tap(find.byKey(const ValueKey('today-details')));
                await tester.pumpAndSettle();
                // The optional guide loads SharedPreferences asynchronously;
                // route animation settling does not await that I/O turn.
                await tester.runAsync(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                });
                await tester.pumpAndSettle();
                expect(find.text(t.todayDetails), findsOneWidget);
                final detailsScroll = find.byType(Scrollable).last;
                await tester.scrollUntilVisible(
                  find.byType(TodayGuideChecklistSection),
                  180,
                  scrollable: detailsScroll,
                  maxScrolls: 30,
                );
                expect(find.byType(TodayGuideChecklistSection), findsOneWidget);
                expect(find.byType(ContentDailyGoals), findsOneWidget);
                final guideExpand = find.byKey(
                  const ValueKey('today-guide-expand'),
                );
                await tester.scrollUntilVisible(
                  guideExpand,
                  180,
                  scrollable: detailsScroll,
                  maxScrolls: 30,
                );
                await tester.pumpAndSettle();
                await tester.tap(guideExpand);
                await tester.pumpAndSettle();
                final guideHub = find.byKey(
                  const ValueKey('today-guide-open-hub'),
                );
                await tester.scrollUntilVisible(
                  guideHub,
                  180,
                  scrollable: detailsScroll,
                  maxScrolls: 30,
                );
                await tester.pumpAndSettle();
                await tester.tap(guideHub);
                await tester.pumpAndSettle();
                expect(routes.last, '/guide');
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
                final goal = find
                    .descendant(
                      of: find.byType(ContentDailyGoals),
                      matching: find.byType(ListTile),
                    )
                    .first;
                await tester.scrollUntilVisible(
                  goal,
                  180,
                  scrollable: detailsScroll,
                  maxScrolls: 30,
                );
                await tester.pumpAndSettle();
                expect(
                  ContentLearningService.daily(
                    LearningContentKind.listening,
                    'a1',
                  ).completedCount,
                  0,
                );
                await tester.tap(goal);
                await tester.pumpAndSettle();
                expect(routes.last, '/listening');
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
                final quest = kQuestCatalog.firstWhere(
                  (q) => q.id == 'q_jangdokdae',
                );
                final questTitle = lang == 'de' ? quest.name.de : quest.name.en;
                await tester.scrollUntilVisible(
                  find.text(questTitle),
                  220,
                  scrollable: detailsScroll,
                  maxScrolls: 30,
                );
                await tester.pumpAndSettle();
                await tester.tap(find.text(questTitle));
                await tester.pumpAndSettle();
                expect(routes.last, '/quests');
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
                tester.state<ScrollableState>(detailsScroll).position.jumpTo(0);
                await tester.pumpAndSettle();
                await tester.tap(find.text(t.statsThisWeek));
                await tester.pumpAndSettle();
                expect(find.byType(DailyGoalCard), findsOneWidget);
                expect(find.byType(WeekSteppingStonesRow), findsOneWidget);
                Navigator.of(tester.element(find.byType(DailyGoalCard))).pop();
                await tester.pumpAndSettle();
                await tester.tap(find.text(t.todayProgress));
                await tester.pumpAndSettle();
                expect(routes.last, '/stats');
                Navigator.of(
                  tester.element(find.byKey(const ValueKey('route-probe'))),
                ).pop();
                await tester.pumpAndSettle();
                Navigator.of(tester.element(find.text(t.todayDetails))).pop();
                await tester.pumpAndSettle();
              }
              MascotPreference.preference.value = CompanionPreference.none;
              await tester.pump();
              expect(
                find.byKey(const ValueKey('sori-today-companion-hidden')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('learning-companion-ground')),
                findsNothing,
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  test('Today topics use exact semantic pack identities', () {
    expect(TodaySubjectArt.packAssets, {
      'a1_sorry_thanks_1': '${TodaySubjectArt.root}sorry-thanks.png',
      'a1_repair_language_1': '${TodaySubjectArt.root}repair-language.png',
      'a1_transport': '${TodaySubjectArt.root}transport.png',
      'a2_restaurant_1': '${TodaySubjectArt.root}restaurant.png',
      'a2_partner_chuseok_basic_1': '${TodaySubjectArt.root}chuseok.png',
    });
    expect(
      TodaySubjectArt.packAssets.containsKey('a1_body'),
      isFalse,
      reason: 'Listening a1_body art means apology; never body anatomy.',
    );
    expect(
      TodaySubjectArt.packAssets.containsKey('a1_numbers'),
      isFalse,
      reason: 'Listening a1_numbers art means hair salon; never numbers.',
    );
  });
}
