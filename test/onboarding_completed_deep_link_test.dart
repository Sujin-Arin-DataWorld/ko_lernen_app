import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/foundation_learning_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/locale_service.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

OnboardingJourneyState _completed() =>
    OnboardingJourneyState.initial(DateTime.utc(2026, 10, 5)).copyWith(
      phase: OnboardingPhase.complete,
      levelDraft: LearnerLevel.a1,
      beginnerDraft: true,
      companionDraft: OnboardingCompanion.taego,
      commitStage: OnboardingCommitStage.completed,
      gateIntroAttempted: true,
      gateIntroConsumed: true,
      shellEntryEventSent: true,
    );

Future<void> _seed({bool consentAccepted = true}) async {
  Storage.resetForTesting();
  CourseProgressService.shared.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'kl_consent_accepted': consentAccepted,
    'kl_onboarding_completed': true,
    'kl_user_level': 'a1',
    'kl_tut_home_tour': true,
    'kl_reduced_motion': true,
    SharedPreferencesOnboardingJourneyRepository.preferenceKey: jsonEncode(
      _completed().toJson(),
    ),
  });
  await Storage.init();
}

/// Only delays the first native journal read, so the real initial route stack
/// exists before the production coordinator resolves the persisted account.
final class _PausedFirstRun {
  final release = Completer<void>();
  bool readStarted = false;

  late final coordinator = FirstRunCoordinator(
    repository: SharedPreferencesOnboardingJourneyRepository(
      preferencesLoader: () async {
        if (!readStarted) {
          readStarted = true;
          await release.future;
        }
        return SharedPreferences.getInstance();
      },
    ),
    legacyStateReader: const StorageLegacyOnboardingStateReader(),
    commitGateway: StorageOnboardingCommitGateway(),
  );

  void resume() {
    if (!release.isCompleted) {
      release.complete();
    }
  }
}

Future<void> _frames(WidgetTester tester, {int count = 8}) async {
  // AppShell can host a repeating idle animation, so never pumpAndSettle.
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _mount(
  WidgetTester tester,
  _PausedFirstRun firstRun, {
  String route = FoundationLearningScreen.route,
  String language = 'de',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(firstRun.resume);
  localeNotifier.value = Locale(language);
  await tester.pumpWidget(
    KoLernenApp(
      startRoute: route,
      splashDisplayDuration: Duration.zero,
      firstRunCoordinator: firstRun.coordinator,
    ),
  );
  await tester.pump();
  expect(firstRun.readStarted, isTrue);
}

void _expectInitialDeepLink(WidgetTester tester) {
  final detail = find.byType(FoundationLearningScreen);
  final onboarding = find.byType(
    OnboardingV2JourneyScreen,
    skipOffstage: false,
  );
  expect(detail, findsOneWidget);
  expect(onboarding, findsOneWidget);
  final parentRoute = ModalRoute.of(tester.element(onboarding))!;
  final detailRoute = ModalRoute.of(tester.element(detail))!;
  expect(parentRoute.settings.name, '/');
  expect(parentRoute.isFirst, isTrue);
  expect(parentRoute.isCurrent, isFalse);
  expect(detailRoute.settings.name, FoundationLearningScreen.route);
  expect(detailRoute.isCurrent, isTrue);
  expect(detailRoute.isFirst, isFalse);
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadCFonts();
    await loadSoriRealFonts(materialIcons: true);
    await CImageCache.load('assets/illustrations/concept_c/material_atlas.png');
    // Keep bundle reads and parser isolates outside the widget fake clock.
    await CurriculumCatalog.load();
    await ScenarioLoader.load();
    await DataLoader.loadVocab();
    for (final kind in LearningContentKind.values) {
      await ContentLearningCatalog.load(kind);
    }
  });

  setUp(() async {
    stubSoriSpeech();
    LearningJourneyObserver.shared.cancel();
    cloudWriteSessionController.clear();
    AppShell.requestedStageTab.value = -1;
    await _seed();
  });

  tearDown(() {
    LearningJourneyObserver.shared.cancel();
    cloudWriteSessionController.clear();
    CourseProgressService.shared.resetForTesting();
    Storage.resetForTesting();
    localeNotifier.value = null;
  });

  testWidgets(
    'completed onboarding preserves initial Foundation and Back opens real AppShell',
    (tester) async {
      final firstRun = _PausedFirstRun();
      await _mount(tester, firstRun);
      _expectInitialDeepLink(tester);
      final detailState = tester.state(find.byType(FoundationLearningScreen));
      final initialXp = Storage.xp;

      firstRun.resume();
      await _frames(tester);

      expect(find.byType(FoundationLearningScreen), findsOneWidget);
      expect(
        tester.state(find.byType(FoundationLearningScreen)),
        same(detailState),
      );
      expect(find.byType(AppShell), findsNothing);
      final detailContext = tester.element(
        find.byType(FoundationLearningScreen),
      );
      expect(ModalRoute.of(detailContext)!.isCurrent, isTrue);
      expect(
        find.text(AppL10n.of(detailContext).foundationTitle),
        findsOneWidget,
      );
      expect(
        find.byType(OnboardingV2JourneyScreen, skipOffstage: false),
        findsNothing,
      );

      await tester.tap(
        find.byTooltip(
          MaterialLocalizations.of(detailContext).backButtonTooltip,
        ),
      );
      await _frames(tester);

      expect(find.byType(FoundationLearningScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(SoriStageShell), findsOneWidget);
      final shellContext = tester.element(find.byType(AppShell));
      expect(ModalRoute.of(shellContext)!.isCurrent, isTrue);
      expect(ModalRoute.of(shellContext)!.isFirst, isTrue);
      expect(Navigator.of(shellContext).canPop(), isFalse);
      final progress = await FoundationProgressService.shared.load();
      expect(progress.practicedCount, 0);
      expect(progress.openedSteps, isEmpty);
      expect(progress.continuedToA1, isFalse);
      expect(Storage.xp, initialXp);
      expect(tester.takeException(), isNull);
      await _disposeApp(tester);
    },
  );

  testWidgets(
    'missing consent still replaces initial Foundation with consent',
    (tester) async {
      await tester.runAsync(() => _seed(consentAccepted: false));
      final firstRun = _PausedFirstRun();
      await _mount(tester, firstRun, language: 'en');
      _expectInitialDeepLink(tester);

      firstRun.resume();
      await _frames(tester, count: 12);

      expect(find.byType(FoundationLearningScreen), findsNothing);
      expect(find.byType(AppShell, skipOffstage: false), findsNothing);
      expect(find.byType(ConsentScreen), findsOneWidget);
      final consentContext = tester.element(find.byType(ConsentScreen));
      expect(ModalRoute.of(consentContext)!.isCurrent, isTrue);
      expect(
        find.text(AppL10n.of(consentContext).consentTitle),
        findsOneWidget,
      );
      expect(Storage.consentAccepted, isFalse);
      final progress = await FoundationProgressService.shared.load();
      expect(progress.practicedCount, 0);
      expect(progress.continuedToA1, isFalse);
      expect(tester.takeException(), isNull);
      await _disposeApp(tester);
    },
  );

  testWidgets('completed current root still replaces itself with AppShell', (
    tester,
  ) async {
    final firstRun = _PausedFirstRun();
    await _mount(tester, firstRun, route: '/', language: 'en');
    final rootContext = tester.element(find.byType(OnboardingV2JourneyScreen));
    expect(ModalRoute.of(rootContext)!.isFirst, isTrue);
    expect(ModalRoute.of(rootContext)!.isCurrent, isTrue);

    firstRun.resume();
    await _frames(tester);

    expect(find.byType(OnboardingV2JourneyScreen), findsNothing);
    expect(find.byType(FoundationLearningScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(SoriStageShell), findsOneWidget);
    final shellContext = tester.element(find.byType(AppShell));
    expect(ModalRoute.of(shellContext)!.isCurrent, isTrue);
    expect(ModalRoute.of(shellContext)!.isFirst, isTrue);
    expect(Navigator.of(shellContext).canPop(), isFalse);
    expect(tester.takeException(), isNull);
    await _disposeApp(tester);
  });
}
