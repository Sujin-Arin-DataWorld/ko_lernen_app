import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/home_navigation_art.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/c_stage_chrome.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/sori_stage_progression_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

// Opt-in local evidence only. No matchesGoldenFile, baseline replacement or
// docs/screenshots write occurs in this file. An ordinary CI run skips all ten.
const _outputDirectory = String.fromEnvironment('C_CONTENT_SHELL_EVIDENCE_DIR');
const _capture = _outputDirectory != '';
const _viewport = Size(390, 844);
const _frameKey = ValueKey('c-content-shell-evidence-frame');
const _decodeLimit = Duration(seconds: 15);
const _navigationAssets = [
  HomeNavigationArt.today,
  HomeNavigationArt.learn,
  HomeNavigationArt.games,
  HomeNavigationArt.hanok,
  HomeNavigationArt.gye,
];

OnboardingJourneyState _completedBeginner() =>
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

/// The visual fixture owns an isolated native preference store. Actual public
/// placement, wallet bootstrap, Foundation, Today, focus and aggregate services
/// assemble its values before the shell mounts. Returning this immutable local
/// snapshot through the shell seams disables optional celebration presentation
/// and avoids a wallet read/write race during image decoding. No progress,
/// currency, reward receipt, member count or ready focus is hand-constructed.
final class _LocalFixture {
  const _LocalFixture(
    this.snapshot,
    this.focus,
    this.courseRaw,
    this.walletRaw,
  );

  final SoriStageProgressionSnapshot snapshot;
  final LearningFocus focus;
  final String courseRaw;
  final String? walletRaw;

  static Future<_LocalFixture> create() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    LearningJourneyObserver.shared.cancel();
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_consent_accepted': true,
      'kl_onboarding_completed': true,
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      'kl_reduced_motion': true,
      Storage.selectedCompanionPreferenceKey: 'tiger',
      Storage.companionVisiblePreferenceKey: true,
      SharedPreferencesOnboardingJourneyRepository.preferenceKey: jsonEncode(
        _completedBeginner().toJson(),
      ),
    });
    await Storage.init();
    MascotPreference.load();
    expect(AuthService.current, isNull);

    final catalog = await CurriculumCatalog.load();
    final course = await CourseProgressService.shared.initializeForPlacement(
      LearnerLevel.a1.code,
    );
    final firstA1 = catalog.courseUnits.firstWhere(
      (unit) => unit.level.toLowerCase() == LearnerLevel.a1.code,
    );
    expect(course.currentCourseUnitId, firstA1.id);
    expect(course.completedUnitIds, isEmpty);
    expect(course.evidence, isEmpty);
    expect(course.phaseTaskEvidence, isEmpty);

    final foundation = await FoundationProgressService.shared.load();
    expect(foundation.openedSteps, isEmpty);
    expect(foundation.practicedCount, 0);
    expect(foundation.currentStep, isNull);
    expect(foundation.continuedToA1, isFalse);

    // Production bootstrap creates its validated empty ledger; this fixture
    // never calls an award API or seeds a balance/claim document.
    final wallet = await YeopjeonService.loadCurrent();
    expect(wallet.isPristineZero, isTrue);
    expect(wallet.sarangchaeOwnedStage, 0);
    expect(wallet.b2OwnedStage, 0);
    final snapshot = await SoriStageProgressionService.load();
    final focus = await LearningFocus.load();
    expect(snapshot.today.isUnavailable, isFalse);
    expect(snapshot.today.pick, isA<HangulIntroPick>());
    expect(snapshot.xp, 0);
    expect(snapshot.pendingBojagiCount, 0);
    expect(snapshot.hasPendingDecorationReceipt, isFalse);
    expect(snapshot.walletUnavailable, isFalse);
    expect(snapshot.wallet?.balance, wallet.balance);
    expect(snapshot.gyeLanternCount, 0);
    expect(focus.ready, isTrue);
    expect(focus.today.pick, isA<HangulIntroPick>());
    expect(focus.destination?.route, '/foundation');
    return _LocalFixture(
      snapshot,
      focus,
      Storage.courseMasterySnapshotRawJson,
      await YeopjeonService.captureBackupJson(),
    );
  }

  Future<SoriStageProgressionSnapshot> loadSnapshot() async => snapshot;
  Future<LearningFocus> loadFocus() async => focus;

  // Explicit signed-out seam. These captures do not claim a live Firebase Gye
  // membership, remote promise/lantern count or a network receipt response.
  Future<List<GyeMeta>> loadSignedOutGye() async {
    expect(AuthService.current, isNull);
    return const [];
  }

  Future<void> assertLearningAndRewardsUnchanged() async {
    expect(Storage.courseMasterySnapshotRawJson, courseRaw);
    expect(await YeopjeonService.captureBackupJson(), walletRaw);
    expect(Storage.xp, 0);
    expect(Storage.pendingBoxes, isEmpty);
    expect(Storage.ownedDecor, isEmpty);
    final foundation = await FoundationProgressService.shared.load();
    expect(foundation.openedSteps, isEmpty);
    expect(foundation.practicedCount, 0);
    expect(foundation.currentStep, isNull);
    expect(foundation.continuedToA1, isFalse);
  }
}

Future<void> _frames(WidgetTester tester) async {
  // Bounded frames: shell/catalog idle animations must not use pumpAndSettle.
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<Set<String>> _preloadAtlasPaint(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    // CImageCache stores its first Future for each path. That Future must be
    // created in the real event loop before any CAtlasArt builds in FakeAsync.
    // Discover the actual bundled top-level C image family, so source additions
    // are covered without a duplicated list of atlas filenames or sample art.
    final manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).timeout(_decodeLimit);
    const prefix = 'assets/illustrations/concept_c/';
    final paths = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith(prefix) &&
              !path.substring(prefix.length).contains('/') &&
              path.endsWith('.png'),
        )
        .toSet();
    expect(
      paths,
      containsAll([
        CReferenceArt.path,
        CGameReferenceArt.path,
        CGameReferenceArt.labelRepairPath,
      ]),
    );
    for (final path in paths.toList()..sort()) {
      final image = await CImageCache.load(path).timeout(
        _decodeLimit,
        onTimeout: () => throw TimeoutException(
          'C shell evidence: pre-render atlas decode did not complete: $path',
          _decodeLimit,
        ),
      );
      expect(image.width, greaterThan(0), reason: path);
      expect(image.height, greaterThan(0), reason: path);
    }
    return paths;
  }))!;
}

Future<void> _decodeNativeImages(
  WidgetTester tester,
  List<Image> images,
  BuildContext context,
) async {
  final pending = images.map((image) => image.image).toSet();
  final failures = <Object>[];
  await tester.runAsync(() async {
    // An ImageProvider may already have started in a widget's fake clock.
    // Register actual precaches here, then return so both real I/O and fake
    // continuations receive frames; awaiting that pending cache here can block
    // the very pump that completes it.
    for (final provider in pending.toList()) {
      unawaited(
        precacheImage(
          provider,
          context,
          onError: (error, _) => failures.add(error),
        ).then<void>(
          (_) => pending.remove(provider),
          onError: (Object error, StackTrace _) {
            failures.add(error);
            pending.remove(provider);
          },
        ),
      );
    }
  });
  final deadline = DateTime.now().add(_decodeLimit);
  while (pending.isNotEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  }
  expect(
    pending,
    isEmpty,
    reason: 'Actual ImageProviders still pending after $_decodeLimit: $pending',
  );
  expect(failures, isEmpty, reason: 'Every real Image asset must decode.');
}

Future<Set<String>> _decodeActualPaint(
  WidgetTester tester,
  Set<String> preloadedPaths,
) async {
  final decoded = <String>{};
  // Snapshot/entry futures can expose additional art after the first frame.
  for (var pass = 0; pass < 2; pass++) {
    final atlases = tester.widgetList<CAtlasArt>(
      find.byType(CAtlasArt, skipOffstage: false),
    );
    final paths = atlases.map((art) => art.path).toSet();
    expect(paths, isNotEmpty);
    expect(
      preloadedPaths,
      containsAll(paths),
      reason: 'Every actual CAtlasArt path must decode before its first build.',
    );
    final images = tester
        .widgetList<Image>(find.byType(Image, skipOffstage: false))
        .toList();
    final context = tester.element(find.byType(SoriStageShell));
    await tester.runAsync(() async {
      for (final path in paths) {
        // CAtlasArt paints CustomPaint, so precacheImage(Image.asset(...))
        // alone cannot make its private atlas FutureBuilder ready.
        final image = await CImageCache.load(path).timeout(
          _decodeLimit,
          onTimeout: () => throw TimeoutException(
            'C shell evidence: preloaded atlas is still pending: $path',
            _decodeLimit,
          ),
        );
        expect(image.width, greaterThan(0), reason: path);
        expect(image.height, greaterThan(0), reason: path);
        decoded.add(path);
      }
    });
    await _decodeNativeImages(tester, images, context);
    await _frames(tester);
  }

  final allArt = find.byType(CAtlasArt, skipOffstage: false);
  for (var index = 0; index < allArt.evaluate().length; index++) {
    final art = allArt.at(index);
    final path = tester.widget<CAtlasArt>(art).path;
    expect(decoded, contains(path));
    final paint = find.descendant(
      of: art,
      matching: find.byType(CustomPaint, skipOffstage: false),
      skipOffstage: false,
    );
    expect(
      paint,
      findsOneWidget,
      reason: '$path must reach its actual painter.',
    );
    final render = tester.renderObject<RenderCustomPaint>(paint);
    expect(render.painter, isNotNull, reason: path);
  }
  for (final image in find.byType(Image).evaluate()) {
    final raw = find.descendant(
      of: find.byWidget(image.widget),
      matching: find.byType(RawImage),
    );
    expect(raw, findsOneWidget);
    expect(tester.widget<RawImage>(raw).image, isNotNull);
  }
  expect(tester.takeException(), isNull);
  return decoded;
}

void _expectRealProportionalFonts() {
  for (final family in ['Paperlogy', 'NotoSansKR']) {
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: family, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final result = painter.width;
      painter.dispose();
      return result;
    }

    expect(width('WWWW'), greaterThan(width('iiii') * 2), reason: family);
  }
}

Finder _primaryAction(SoriStageTab tab, AppL10n t) => switch (tab) {
  SoriStageTab.today ||
  SoriStageTab.learn => find.byKey(const ValueKey('learning-focus-start')),
  SoriStageTab.games => find.byWidgetPredicate(
    (widget) => widget is CMaterialAction && widget.label == t.catalogViewGame,
  ),
  SoriStageTab.hanok => find.byKey(const ValueKey('hanok-construction-entry')),
  SoriStageTab.gye => find.byKey(const ValueKey('gye-empty-start')),
};

void _assertVisibleShell(WidgetTester tester, SoriStageTab tab, AppL10n t) {
  expect(find.byType(SoriStageShell), findsOneWidget);
  expect(find.byType(SoriAdaptiveNavigation), findsOneWidget);
  final navigation = tester.widget<SoriAdaptiveNavigation>(
    find.byType(SoriAdaptiveNavigation),
  );
  expect(navigation.imageOnly, isTrue);
  expect(navigation.selectedIndex, tab.index);
  expect(navigation.items.map((item) => item.artworkAsset), _navigationAssets);
  expect(find.byType(NavigationDestination), findsNWidgets(5));
  expect(find.byType(NavigationRail), findsNothing);
  for (var index = 0; index < 5; index++) {
    final destination = find.byType(NavigationDestination).at(index);
    expect(destination.hitTestable(), findsOneWidget);
    final size = tester.getSize(destination);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    final data = tester.getSemantics(destination).getSemanticsData();
    expect(data.label, contains(navigation.items[index].label));
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(
      data.flagsCollection.isSelected,
      index == tab.index ? ui.Tristate.isTrue : ui.Tristate.isFalse,
    );
  }

  final title = switch (tab) {
    SoriStageTab.today => t.soriStageNavToday,
    SoriStageTab.learn => t.onboardingJourneyPathShort,
    SoriStageTab.games => t.soriStageNavGames,
    SoriStageTab.hanok => t.onboardingJourneyHanokShort,
    SoriStageTab.gye => t.coachGyeTabTitle.replaceFirst(' ', '\n'),
  };
  expect(find.byType(CStageHeader), findsOneWidget);
  expect(find.text(title).hitTestable(), findsOneWidget);
  if (tab == SoriStageTab.today || tab == SoriStageTab.learn) {
    expect(find.text(t.foundationTitle).hitTestable(), findsOneWidget);
  }
  if (tab == SoriStageTab.gye) {
    expect(find.text(t.gyeRootPurpose).hitTestable(), findsOneWidget);
  }
  final action = _primaryAction(tab, t);
  expect(action.hitTestable(), findsOneWidget);
  final actionSize = tester.getSize(action);
  expect(actionSize.width, greaterThanOrEqualTo(48));
  expect(actionSize.height, greaterThanOrEqualTo(48));
  final actionData = tester.getSemantics(action).getSemanticsData();
  expect(actionData.flagsCollection.isButton, isTrue);
  expect(actionData.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(find.byType(AppLoading), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  // Saved progress bars are content. An indeterminate bar would mean that
  // the capture still contains a loading state; never confuse the two.
  for (final progress in tester.widgetList<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  )) {
    expect(progress.value, isNotNull);
    expect(progress.value!.isFinite, isTrue);
    expect(progress.value, inInclusiveRange(0, 1));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _export(
  WidgetTester tester,
  String language,
  SoriStageTab tab,
  _LocalFixture fixture,
  Set<String> atlasPaths,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frameKey),
  );
  expect(boundary.size, _viewport);
  expect(boundary.debugNeedsPaint, isFalse);
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      expect(image.width, 390);
      expect(image.height, 844);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      expect(bytes!.lengthInBytes, greaterThan(20000));
      final name = 'c-content-shell-${tab.name}-$language-390x844';
      final directory = Directory(_outputDirectory);
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      await File('${directory.path}/$name.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'locale': language,
          'viewport': {'width': 390, 'height': 844, 'pixelRatio': 1},
          'selectedTab': tab.name,
          'nativeNavigationAssets': _navigationAssets,
          'decodedActualAtlasPaths': atlasPaths.toList()..sort(),
          'verifiedProportionalFonts': ['Paperlogy', 'NotoSansKR'],
          'stateSource':
              'Isolated signed-out preferences; actual first A1 placement, '
              'Foundation service, production Today/focus/aggregate loaders '
              'and validated empty Yeopjeon bootstrap. Optional home and Gye '
              'tutorials are marked already seen for unobscured comparison.',
          'foundationPracticedTasks': 0,
          'xp': fixture.snapshot.xp,
          'walletBalance': fixture.snapshot.wallet?.balance,
          'pendingBojagiCount': fixture.snapshot.pendingBojagiCount,
          'hasPendingDecorationReceipt':
              fixture.snapshot.hasPendingDecorationReceipt,
          'remoteBoundary':
              'Gye membership uses an explicit signed-out empty-list seam. '
              'No Firebase initialization, live membership/receipt response '
              'or learning activity launch is part of this capture.',
        }),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!_capture) {
      return;
    }
    await loadCFonts();
    await loadSoriRealFonts(materialIcons: true);
    _expectRealProportionalFonts();
    await CurriculumCatalog.load();
    await DataLoader.loadVocab();
    await ScenarioLoader.load();
    for (final kind in LearningContentKind.values) {
      await ContentLearningCatalog.load(kind);
    }
  });

  for (final language in ['de', 'en']) {
    for (final tab in SoriStageTab.values) {
      testWidgets(
        'actual C content shell ${tab.name} $language 390x844',
        skip: !_capture,
        (tester) async {
          tester.view.physicalSize = _viewport;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final replay = ValueNotifier<int>(0);
          try {
            final frame = '$language/${tab.name}';
            debugPrint('C shell evidence $frame: preloading actual atlases');
            final preloadedPaths = await _preloadAtlasPaint(tester);
            debugPrint(
              'C shell evidence $frame: ${preloadedPaths.length} atlases ready; '
              'reading actual local fixture',
            );
            final fixture = (await tester.runAsync(_LocalFixture.create))!;
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                locale: Locale(language),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                navigatorObservers: [soriRouteObserver],
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.noScaling,
                  ),
                  child: RepaintBoundary(key: _frameKey, child: child!),
                ),
                home: SoriStageShell(
                  replayHomeTour: replay,
                  loadTodaySnapshot: fixture.loadSnapshot,
                  loadProgressionSnapshot: fixture.loadSnapshot,
                  loadLearningFocus: fixture.loadFocus,
                  loadGyeMetas: fixture.loadSignedOutGye,
                ),
              ),
            );
            await _frames(tester);
            debugPrint('C shell evidence $frame: shell mounted');
            if (tab != SoriStageTab.today) {
              await tester.tap(
                find.byType(NavigationDestination).at(tab.index),
              );
              await _frames(tester);
            }
            // Compare the same initial viewport for every tab. A navigation
            // focus/scroll restoration must not crop the real header capture.
            await tester.ensureVisible(find.byType(CStageHeader));
            await _frames(tester);
            debugPrint('C shell evidence $frame: decoding actual mounted art');
            final atlasPaths = await _decodeActualPaint(tester, preloadedPaths);
            final t = AppL10n.of(tester.element(find.byType(SoriStageShell)));
            expect(
              tester.getRect(find.byType(CStageHeader)).top,
              greaterThanOrEqualTo(0),
            );
            _assertVisibleShell(tester, tab, t);
            debugPrint('C shell evidence $frame: paint and controls ready');
            await tester.runAsync(fixture.assertLearningAndRewardsUnchanged);
            await _frames(tester);
            await _export(tester, language, tab, fixture, atlasPaths);
            debugPrint('C shell evidence $frame: PNG exported');
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            semantics.dispose();
            replay.dispose();
            await tester.runAsync(() async {
              await DecorationRewardService.packCompletionDrain;
              LearningJourneyObserver.shared.cancel();
              CourseProgressService.shared.resetForTesting();
              Storage.resetForTesting();
              cloudWriteSessionController.clear();
              LocalDataLifetime.invalidate();
            });
          }
        },
      );
    }
  }
}
