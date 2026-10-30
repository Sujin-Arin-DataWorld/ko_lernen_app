import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_wallet_card.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_wallet_notifier.dart';
import 'package:ko_lernen_app/widgets/sori/top_chrome.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';

import 'support/catalog_test_support.dart' as catalog;
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';
import 'support/sori_stage_capture_assets.dart';

const _captureEvidence = bool.fromEnvironment('CAPTURE_SORI_STAGE_EVIDENCE');
late LearningFocusController _focusController;
late YeopjeonWalletNotifier _walletNotifier;
late LearningFocus _bookCardFocus;

/// §LAYOUT-4 — five roots and DE/EN state evidence share one
/// pipeline. Flag OFF (default `flutter test`): every `skip:
/// !_captureEvidence` case is skipped, 0 failures. Flag ON *and*
/// `--update-goldens`: 22 PNGs regenerate under `docs/screenshots/`. Flag ON
/// *without* `--update-goldens` is a comparison run against whatever is
/// already on disk — not the capture command; see AGENTS.md's UI 루트 증거
/// bullet for the exact regeneration command.
void main() {
  for (final language in ['de', 'en']) {
    testWidgets(
      'capture confirmed Bojagi receipt $language',
      skip: !_captureEvidence,
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        DecorationRewardService.resetForTesting();
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(
              PaletteVariant.dancheong,
              locale: Locale(language),
            ),
            locale: Locale(language),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: const BojagiScreen(),
          ),
        );
        await _settleHanok(tester);
        await tester.tap(find.byKey(const Key('bojagi_knot')));
        await _settleHanok(tester);
        final candidate = find.byKey(
          const ValueKey('bojagi-candidate-decoration_sagunja_guk'),
        );
        await tester.ensureVisible(candidate);
        await tester.tap(candidate);
        await _settleHanok(tester);
        await tester.pump(const Duration(milliseconds: 1200));
        await _awaitImageDecode(tester);
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.ownedDecor, contains('decoration_sagunja_guk'));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            '../docs/screenshots/sori-bojagi-receipt-$language-390.png',
          ),
        );
      },
    );
  }
  for (final language in ['de', 'en']) {
    testWidgets(
      'capture yeopjeon construction wallet $language',
      skip: !_captureEvidence,
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final wallet = YeopjeonWallet(
          balance: 60,
          sarangchaeEligibleStage: 1,
          b2EligibleStage: 0,
          sarangchaeOwnedStage: 0,
          b2OwnedStage: 0,
          grandfatheredSarangchaeStage: 0,
          grandfatheredB2Stage: 0,
          claims: const {'milestone:s:1': 40, 'daily:2026-10-01:first': 20},
          completedSourceIds: const {'unit:a1_01'},
          reviewedSourceIds: const {},
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(
              PaletteVariant.dancheong,
              locale: Locale(language),
            ),
            locale: Locale(language),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: YeopjeonWalletCard(
                    loader: () async => wallet,
                    builder: (_) async => const YeopjeonTransactionResult(
                      status: YeopjeonTransactionStatus.locked,
                      amount: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await _settleHanok(tester);
        await _awaitImageDecode(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            '../docs/screenshots/sori-stage-hanok-390-wallet$language.png',
          ),
        );
      },
    );
  }

  late CulturalGlossary glossary;
  late SarangchaeConstruction construction;

  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUpAll(() async {
    await prepareSoriStageCaptureAssets();
    _bookCardFocus = await catalog.loadFirstCatalogFocus();
    // Wallet art uses the real bundle; warm it outside widget fake async.
    await SarangchaeConstruction.load();
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
    construction = SarangchaeConstruction.fromJson(
      jsonDecode(await File(SarangchaeConstruction.assetPath).readAsString()),
    );
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      // §W-J2(b): Today's post-onboarding guide card otherwise covers the
      // mission card/hero/"Deine Hanok jetzt"/"Als Nächstes" — this is the
      // steady-state screen the evidence PNG is meant to show, not a
      // first-run overlay. Key from guide_progress_service.dart.
      GuideProgressService.todayCardDismissedKey: true,
    });
    await Storage.init();
    // Production boot prepares the legacy ownership baseline before routes.
    // Capture the ordinary saved-wallet UI rather than a missing-ledger error.
    await YeopjeonService.loadCurrent(
      competenceLoader: () async => const HanokCompetenceProjection.empty(),
      evidenceScanner: () async => {},
    );
    _walletNotifier = YeopjeonWalletNotifier();
    await _walletNotifier.refresh();
    _focusController = LearningFocusController(
      loader: () =>
          LearningFocus.load(loadToday: () async => _snapshot().today),
    );
    await _focusController.refresh();
    // §W-J2(c): `CulturalHelpButton` gates on
    // `CulturalGlossaryRepository.load()` (a real rootBundle JSON read
    // cached process-wide) — inject a synchronous-after-one-await catalog
    // so every `?` button resolves on schedule instead of depending on
    // incidental cache-warming order between captures (this is why Hanok's
    // `?`, captured 4th, happened to render while Gye's, captured 6th/7th,
    // sometimes did not — see `sori_stage_gye_fold_test.dart`, which
    // reproduces and fixes the same root cause).
    CulturalGlossaryRepository.setLoaderForTesting(() async => glossary);
  });

  tearDown(CulturalGlossaryRepository.resetForTesting);
  tearDown(() => _focusController.dispose());
  tearDown(() => _walletNotifier.dispose());

  for (final largeText in [false, true]) {
    testWidgets(
      'capture illustrated book card largeText=$largeText',
      skip: !_captureEvidence,
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final controller = LearningFocusController()..value = _bookCardFocus;
        addTearDown(controller.dispose);
        const boundary = ValueKey('book-card-evidence');
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: catalog.catalogTestApp(
              locale: 'de',
              scale: largeText ? 2 : 1,
              controller: controller,
            ),
          ),
        );
        await pumpSoriStage(tester);
        final book = find.byKey(const ValueKey('catalog-card-book_capture'));
        await tester.scrollUntilVisible(
          book,
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(tester.element(book), alignment: .15);
        await pumpSoriStage(tester);
        await _awaitImageDecode(tester);
        await expectLater(
          find.byKey(boundary),
          matchesGoldenFile(
            '../docs/screenshots/sori-stage-learn-390-${largeText ? 'booklarge' : 'book'}.png',
          ),
        );
      },
    );
  }

  for (final language in ['de', 'en']) {
    testWidgets('capture Today at 390dp $language', skip: !_captureEvidence, (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          locale: Locale(language),
          home: SoriStageTodayScreen(loadSnapshot: () async => _snapshot()),
        ),
      );
      await pumpSoriStage(tester);
      await _awaitImageDecode(tester);

      await expectLater(
        find.byType(SoriStageTodayScreen),
        matchesGoldenFile(
          _rootEvidencePath(
            'sori-stage-today-390',
            language,
            originalLanguage: 'en',
          ),
        ),
      );
    });

    testWidgets('capture Learn at 1280dp $language', skip: !_captureEvidence, (
      tester,
    ) async {
      _setViewport(tester, const Size(1280, 900));
      await tester.pumpWidget(
        _app(
          locale: Locale(language),
          home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
        ),
      );
      await pumpSoriStage(tester);
      await _awaitImageDecode(tester);

      await expectLater(
        find.byType(SoriStageCatalogScreen),
        matchesGoldenFile(
          _rootEvidencePath(
            'sori-stage-learn-1280',
            language,
            originalLanguage: 'de',
          ),
        ),
      );
    });

    // §E7 (Fable 시각 심사, 2026-09-03): hero 40→36 근거 증거. 390dp 폰 폭에서
    // "Wähle, wie du lernen möchtest." 가 첫 화면을 얼마나 차지하는지 실제
    // MaruBuri 로 렌더해 남긴다.
    testWidgets('capture Learn at 390dp $language', skip: !_captureEvidence, (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          locale: Locale(language),
          home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
        ),
      );
      await pumpSoriStage(tester);
      await _awaitImageDecode(tester);

      await expectLater(
        find.byType(SoriStageCatalogScreen),
        matchesGoldenFile(
          _rootEvidencePath(
            'sori-stage-learn-390',
            language,
            originalLanguage: 'de',
          ),
        ),
      );
    });

    testWidgets('capture Hanok at 390dp $language', skip: !_captureEvidence, (
      tester,
    ) async {
      await Storage.writeYeopjeonRawJsonStrict(
        YeopjeonWallet.grandfather(sarangchaeStage: 8, b2Stage: 0).encode(),
      );
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          locale: Locale(language),
          home: SoriStageHanokScreen(
            loadSnapshot: () async => _snapshot(hanok: true),
            loadConstruction: () async => construction,
          ),
        ),
      );
      await _settleHanok(tester);
      await _awaitImageDecode(tester);

      await expectLater(
        find.byType(SoriStageHanokScreen),
        matchesGoldenFile(
          _rootEvidencePath(
            'sori-stage-hanok-390',
            language,
            originalLanguage: 'de',
          ),
        ),
      );
    });

    testWidgets('capture Games at 390dp $language', skip: !_captureEvidence, (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          locale: Locale(language),
          home: SoriStageCatalogScreen(
            tab: SoriStageTab.games,
            loadSnapshot: () async => _snapshot(),
          ),
        ),
      );
      await pumpSoriStage(tester);
      await _awaitImageDecode(tester);
      await expectLater(
        find.byType(SoriStageCatalogScreen),
        matchesGoldenFile(
          _rootEvidencePath(
            'sori-stage-games-390',
            language,
            originalLanguage: 'de',
          ),
        ),
      );
    });

    testWidgets(
      'capture Hanok at 390dp scrolled 600 $language',
      skip: !_captureEvidence,
      (tester) async {
        await Storage.writeYeopjeonRawJsonStrict(
          YeopjeonWallet.grandfather(sarangchaeStage: 8, b2Stage: 0).encode(),
        );
        _setViewport(tester, const Size(390, 844));
        await tester.pumpWidget(
          _app(
            locale: Locale(language),
            home: SoriStageHanokScreen(
              loadSnapshot: () async => _snapshot(hanok: true),
              loadConstruction: () async => construction,
            ),
          ),
        );
        await _settleHanok(tester);
        await _awaitImageDecode(tester);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        await _awaitImageDecode(tester);

        await expectLater(
          find.byType(SoriStageHanokScreen),
          matchesGoldenFile(
            _rootEvidencePath(
              'sori-stage-hanok-390-collapsed',
              language,
              originalLanguage: 'de',
            ),
          ),
        );
      },
    );

    testWidgets(
      'capture Gye empty at 390dp $language',
      skip: !_captureEvidence,
      (tester) async {
        _setViewport(tester, const Size(390, 844));
        await tester.pumpWidget(
          _app(
            locale: Locale(language),
            home: SoriStageGyeScreen(loadGyeMetas: () async => const []),
          ),
        );
        await pumpSoriStage(tester);
        await _awaitImageDecode(tester);

        await expectLater(
          find.byType(SoriStageGyeScreen),
          matchesGoldenFile(
            _rootEvidencePath(
              'sori-stage-gye-390-empty',
              language,
              originalLanguage: 'de',
            ),
          ),
        );
      },
    );

    testWidgets(
      'capture Gye one group at 390dp $language',
      skip: !_captureEvidence,
      (tester) async {
        _setViewport(tester, const Size(390, 844));
        await tester.pumpWidget(
          _app(
            locale: Locale(language),
            home: SoriStageGyeScreen(loadGyeMetas: () async => [_gyeMeta()]),
          ),
        );
        await pumpSoriStage(tester);
        await _awaitImageDecode(tester);

        await expectLater(
          find.byType(SoriStageGyeScreen),
          matchesGoldenFile(
            _rootEvidencePath(
              'sori-stage-gye-390',
              language,
              originalLanguage: 'de',
            ),
          ),
        );
      },
    );
  }
}

/// Refresh from the saved fixture ledger, then await all native image layers.
Future<void> _awaitImageDecode(WidgetTester tester) async {
  await _walletNotifier.refresh();
  expect(_walletNotifier.value.failed, isFalse);
  expect(_walletNotifier.value.wallet, isNotNull);
  await settleSoriStageCaptureAssets(tester);
  expect(tester.takeException(), isNull);
}

String _rootEvidencePath(
  String stem,
  String language, {
  required String originalLanguage,
}) =>
    '../docs/screenshots/$stem${language == originalLanguage ? '' : '-$language'}.png';

/// The Hanok tab resolves its competency snapshot asynchronously before
/// showing the approved construction stage. A few pumps keep this harness aligned
/// with `sori_stage_hanok_fold_test.dart`'s `settle()` helper.
Future<void> _settleHanok(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A weekly-promise goal fully met -> `GyeLanternProgress.currentStepFor`
/// returns 1 ("lantern earned"), highlighting the stepper's 2nd of 3 steps
/// (`gye_tab_screen.dart`'s `SoriStepper`) instead of its step-0 default.
GyeMeta _gyeMeta() => const GyeMeta(
  id: 'ABC234',
  name: 'Mondhof',
  code: 'ABC234',
  ownerId: 'owner',
  memberCount: 4,
  lifetimeGoalsAchieved: 2,
  weeklyPromiseSchemaVersion: 1,
  weeklyPromiseId: 'promise_daily_streak',
  weeklyPromiseTarget: 5,
  weeklyPromiseProgress: 5,
  weeklyPromiseWeekKey: '2026-W36',
);

SoriStageProgressionSnapshot _snapshot({bool hanok = false}) =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanokCompetence: hanok
          ? HanokCompetenceProjection.fromSnapshot(
              snapshot: CourseMasterySnapshot(
                completedUnitIds: [for (var i = 1; i <= 8; i++) 'a1_$i'],
              ),
              courseUnits: [
                for (var i = 1; i <= 16; i++)
                  CourseUnit(
                    id: 'a1_$i',
                    level: 'a1',
                    order: i,
                    title: const CurriculumText(
                      ko: '학습',
                      de: 'Lernen',
                      en: 'Learn',
                    ),
                    canDo: const CurriculumText(
                      ko: '학습',
                      de: 'Lernen',
                      en: 'Learn',
                    ),
                  ),
              ],
            )
          : const HanokCompetenceProjection.empty(),
      quests: const [],
      pendingBojagiCount: 1,
      stampCount: 4,
      xp: 320,
      streakDays: 6,
      todayReward: const RewardContract(
        activityId: 'srs',
        condition: SoriLocalizedCopy(
          key: SoriCopyKey.finishSession,
          de: 'Wenn du die Runde abschließt',
          en: 'When you finish the session',
        ),
        items: <RewardContractItem>[
          RewardContractItem(
            kind: SoriRewardKind.xp,
            amount: 15,
            label: SoriLocalizedCopy(
              key: SoriCopyKey.rewardXp,
              de: 'Lern-XP',
              en: 'XP',
            ),
          ),
          RewardContractItem(
            kind: SoriRewardKind.questProgress,
            label: SoriLocalizedCopy(
              key: SoriCopyKey.rewardQuest,
              de: 'Quest',
              en: 'Quest',
            ),
          ),
          RewardContractItem(
            kind: SoriRewardKind.hanokProgress,
            label: SoriLocalizedCopy(
              key: SoriCopyKey.rewardHanok,
              de: 'Hanok-Bauteil',
              en: 'Hanok piece',
            ),
          ),
        ],
      ),
    );

Widget _app({required Locale locale, required Widget home}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightFor(PaletteVariant.dancheong, locale: locale),
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: SoriWalletScope(
      notifier: _walletNotifier,
      child: LearningFocusScope(
        controller: _focusController,
        open: (_, destination, {focus, activityId}) async {},
        child: child!,
      ),
    ),
  ),
  home: home,
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
