import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

const _captureEvidence = bool.fromEnvironment('CAPTURE_SORI_STAGE_EVIDENCE');

/// §LAYOUT-4(J14) — 5 root evidence PNGs (today/learn/hanok/gye) share one
/// pipeline. Flag OFF (default `flutter test`): every `skip:
/// !_captureEvidence` case is skipped, 0 failures. Flag ON *and*
/// `--update-goldens`: 7 PNGs regenerate under `docs/screenshots/`. Flag ON
/// *without* `--update-goldens` is a comparison run against whatever is
/// already on disk — not the capture command; see AGENTS.md's UI 루트 증거
/// bullet for the exact regeneration command.
void main() {
  late CulturalGlossary glossary;

  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUpAll(() async {
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
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

  testWidgets('capture Today at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        home: SoriStageTodayScreen(loadSnapshot: () async => _snapshot()),
      ),
    );
    await pumpSoriStage(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageTodayScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-today-390.png'),
    );
  });

  testWidgets('capture Learn at 1280dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
      ),
    );
    await pumpSoriStage(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageCatalogScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-learn-1280.png'),
    );
  });

  // §E7 (Fable 시각 심사, 2026-09-03): hero 40→36 근거 증거. 390dp 폰 폭에서
  // "Wähle, wie du lernen möchtest." 가 첫 화면을 얼마나 차지하는지 실제
  // MaruBuri 로 렌더해 남긴다.
  testWidgets('capture Learn at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
      ),
    );
    await pumpSoriStage(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageCatalogScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-learn-390.png'),
    );
  });

  testWidgets('capture Hanok at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: SoriStageHanokScreen(
          loadSnapshot: () async => _snapshot(),
          worldLoadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: .5, b2: 0),
          worldLoadProjection: (ratios) async =>
              PersonalHanokProjection.from(ratios),
        ),
      ),
    );
    await _settleHanok(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageHanokScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-hanok-390.png'),
    );
  });

  testWidgets(
    'capture Hanok at 390dp scrolled 600',
    skip: !_captureEvidence,
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          locale: const Locale('de'),
          home: SoriStageHanokScreen(
            loadSnapshot: () async => _snapshot(),
            worldLoadRatios: () async =>
                const LevelRatios(a1: 1, a2: 1, b1: .5, b2: 0),
            worldLoadProjection: (ratios) async =>
                PersonalHanokProjection.from(ratios),
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
          '../docs/screenshots/sori-stage-hanok-390-collapsed.png',
        ),
      );
    },
  );

  testWidgets('capture Gye empty at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(locale: const Locale('de'), home: const SoriStageGyeScreen()),
    );
    await pumpSoriStage(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageGyeScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-gye-390-empty.png'),
    );
  });

  testWidgets('capture Gye one group at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: SoriStageGyeScreen(loadGyeMetas: () async => [_gyeMeta()]),
      ),
    );
    await pumpSoriStage(tester);
    await _awaitImageDecode(tester);

    await expectLater(
      find.byType(SoriStageGyeScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-gye-390.png'),
    );
  });
}

/// Real `dart:ui.Image` decode/codec work (`Image.asset`'s `RawImage` leaf)
/// does not advance inside `flutter_test`'s fake-async zone — `runAsync`
/// steps into the real event loop so any image already resolving actually
/// finishes decoding and paints before the frame under test is captured.
/// §W-J2: unifies the fix originally found for Gye's 8-layer `GyeHanok`
/// composite across every capture (Today's mascot art, Hanok's map, etc.).
Future<void> _awaitImageDecode(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Two independent async chains gate Hanok's first real frame: the tab's
/// own `SoriStageProgressionSnapshot` future and `HanokWorldScreen`'s
/// internal load (ratios -> projection -> narrative -> reveal check, each a
/// separate microtask hop) — a single pump only resolves the first hop.
/// Mirrors `sori_stage_hanok_fold_test.dart`'s `settle()`.
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

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: 1, b1: .5, b2: 0),
  ),
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
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: home,
  ),
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
