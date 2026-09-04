import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/intro_gate_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_preview_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/placement_diagnostic_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _viewports = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

typedef _FinderForLocale = Finder Function(AppL10n t);

typedef _EntryFixture = ({
  String name,
  Widget Function() build,
  _FinderForLocale anchor,
  _FinderForLocale? action,
  _FinderForLocale? safeVisual,
  bool actionUsesSafeArea,
  bool actionMayExceedViewport,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TigerStageVideo.videoReady = false;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
    MascotPreference.load();
  });

  testWidgets('Phase 5C entry surfaces survive DE/EN locked viewport matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in const [Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      for (final viewport in _viewports) {
        for (final fixture in _fixtures(t)) {
          await _pumpEntry(
            tester,
            fixture.build(),
            locale: locale,
            viewport: viewport,
          );

          final anchor = fixture.anchor(t);
          expect(
            anchor,
            findsWidgets,
            reason:
                '${fixture.name} ${locale.languageCode} '
                '${viewport.size} @${viewport.textScale}',
          );

          final safeVisualForLocale = fixture.safeVisual;
          if (safeVisualForLocale != null) {
            final safeVisual = safeVisualForLocale(t);
            expect(safeVisual, findsOneWidget);
            _expectFullyVisible(
              tester,
              safeVisual,
              viewport.size,
              useSafeArea: true,
            );
          }

          final actionForLocale = fixture.action;
          if (actionForLocale != null) {
            final action = actionForLocale(t);
            final evidence =
                '${fixture.name} ${locale.languageCode} '
                '${viewport.size} @${viewport.textScale}';
            await _centerInScrollable(tester, action);
            _expectAction(tester, action, minHeight: 48);
            if (fixture.actionMayExceedViewport) {
              _expectReachableInSafeArea(
                tester,
                action,
                viewport.size,
                reason: evidence,
              );
            } else {
              _expectFullyVisible(
                tester,
                action,
                viewport.size,
                useSafeArea: fixture.actionUsesSafeArea,
                reason: evidence,
              );
            }
            _expectPointerOwned(tester, action);
          }

          expect(
            tester.takeException(),
            isNull,
            reason:
                '${fixture.name} ${locale.languageCode} '
                '${viewport.size} @${viewport.textScale}',
          );
          await _disposeEntry(tester);
        }
      }
    }
    semantics.dispose();
  });

  testWidgets('V2 loading state exposes one localized live status', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final blocker = Completer<void>();
    final repository = _MemoryJourneyRepository()..nextLoadBlocker = blocker;

    await _pumpEntry(
      tester,
      OnboardingV2JourneyScreen(
        firstRunCoordinator: _coordinator(repository: repository),
      ),
      locale: const Locale('en'),
      viewport: const (size: Size(390, 844), textScale: 1),
    );

    expect(find.text('Preparing your guide…'), findsOneWidget);
    expect(find.bySemanticsLabel('Preparing your guide…'), findsOneWidget);
    final status = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Preparing your guide…',
      ),
    );
    expect(status.properties.liveRegion, isTrue);

    blocker.complete();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('V2 final commit never exposes the generic guide loading state', (
    tester,
  ) async {
    final state = OnboardingJourneyState.initial(DateTime.utc(2026, 8, 26, 12))
        .copyWith(
          phase: OnboardingPhase.confirmation,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.dailyTravel,
          levelDraft: LearnerLevel.a1,
          companionDraft: OnboardingCompanion.taego,
        );
    final repository = _MemoryJourneyRepository(state);
    final coordinator = _coordinator(repository: repository);

    await _pumpEntry(
      tester,
      OnboardingV2JourneyScreen(
        firstRunCoordinator: coordinator,
        initialResolution: FirstRunResolution(
          entry: FirstRunEntry.confirmation,
          state: state,
          migratedLegacyState: false,
        ),
      ),
      locale: const Locale('de'),
      viewport: const (size: Size(390, 844), textScale: 1),
      disableAnimations: false,
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
    );

    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
    );
    var reachedGate = false;
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.text('Deine Anleitung wird vorbereitet …'),
        findsNothing,
        reason: 'The durable gate state must not reuse initial-load UI.',
      );
      if (find.byType(IntroGateScreen).evaluate().isNotEmpty) {
        reachedGate = true;
        break;
      }
    }
    expect(reachedGate, isTrue);
  });

  testWidgets(
    'V2 load failure announces the error and retry recovers into the story',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = lookupAppL10n(const Locale('en'));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _MemoryJourneyRepository()..failNextLoad = true;

      await _pumpEntry(
        tester,
        OnboardingV2JourneyScreen(
          firstRunCoordinator: _coordinator(repository: repository),
        ),
        locale: const Locale('en'),
        viewport: const (size: Size(320, 640), textScale: 2),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('onboarding-v2-load-error')),
      );

      final error = find.byKey(const ValueKey('onboarding-v2-load-error'));
      final errorWidget = tester.widget<Semantics>(error);
      final errorData = tester.getSemantics(error).getSemanticsData();
      expect(errorData.label, t.loadErrorTryAgain);
      expect(errorData.flagsCollection.isHeader, isTrue);
      expect(errorWidget.properties.liveRegion, isTrue);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'onboarding-v2-load-error-heading',
      );

      final retry = find.byKey(const ValueKey('onboarding-v2-load-retry'));
      _expectAction(tester, retry, minHeight: 48);
      expect(tester.getSemantics(retry).getSemanticsData().label, t.btnRetry);

      await _tapPointerOwned(tester, retry);
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('onboarding-v2-story-title')),
      );

      expect(error, findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding-v2-story-title')),
        findsOneWidget,
      );
      expect(repository.state?.phase, OnboardingPhase.story);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
      semantics.dispose();
    },
  );

  testWidgets('SoriCard exposes selected without changing default semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var selected = false;

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SoriCard(
                key: const ValueKey('selectable-card'),
                selectable: true,
                selected: selected,
                semanticLabel: 'Selectable choice',
                onTap: () => setState(() => selected = !selected),
                child: const Text('Choice'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final selectable = find.byKey(const ValueKey('selectable-card'));
    _expectAction(
      tester,
      selectable,
      minHeight: 48,
      selected: ui.Tristate.isFalse,
    );
    await tester.tap(selectable);
    await tester.pump();
    _expectAction(
      tester,
      selectable,
      minHeight: 48,
      selected: ui.Tristate.isTrue,
    );

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: Scaffold(
          body: Center(
            child: SoriCard(
              key: const ValueKey('plain-card'),
              semanticLabel: 'Plain action',
              onTap: () {},
              child: const Text('Action'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final plain = find.byKey(const ValueKey('plain-card'));
    _expectAction(tester, plain, minHeight: 48);
    expect(
      tester.getSemantics(plain).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.none,
    );

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: const Scaffold(
          body: Center(
            child: SoriCard(
              key: ValueKey('disabled-selected-card'),
              selectable: true,
              selected: true,
              semanticLabel: 'Unavailable selected choice',
              child: Text('Unavailable'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final disabled = find.byKey(const ValueKey('disabled-selected-card'));
    final disabledData = tester.getSemantics(disabled).getSemanticsData();
    expect(disabledData.flagsCollection.isButton, isFalse);
    expect(disabledData.flagsCollection.isEnabled, ui.Tristate.none);
    expect(disabledData.flagsCollection.isSelected, ui.Tristate.none);
    expect(disabledData.hasAction(ui.SemanticsAction.tap), isFalse);
    await _disposeEntry(tester);
    semantics.dispose();
  });

  testWidgets('splash resolves fresh and legacy V2 destinations', (
    tester,
  ) async {
    final cases = <({LegacyOnboardingSnapshot legacy, Type destination})>[
      (
        legacy: const LegacyOnboardingSnapshot(
          consentAccepted: false,
          hasCompletedOnboarding: false,
        ),
        destination: ConsentScreen,
      ),
      (
        legacy: const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: false,
        ),
        destination: OnboardingV2JourneyScreen,
      ),
      (
        legacy: const LegacyOnboardingSnapshot(
          consentAccepted: true,
          hasCompletedOnboarding: true,
          userLevel: LearnerLevel.a1,
        ),
        destination: AppShell,
      ),
    ];

    for (final entry in cases) {
      final coordinator = _coordinator(legacy: entry.legacy);
      await _pumpEntry(
        tester,
        SplashScreen(
          firstRunCoordinator: coordinator,
          displayDuration: Duration.zero,
        ),
        locale: const Locale('en'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
      );

      await _pumpUntilFound(tester, find.byType(entry.destination));
      expect(find.byType(entry.destination), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
    }
  });

  testWidgets('normal-motion gate skip consumes V2 gate and opens AppShell', (
    tester,
  ) async {
    final repository = _MemoryJourneyRepository(_gateState());
    final coordinator = _coordinator(repository: repository);
    await _pumpEntry(
      tester,
      IntroGateScreen(firstRunCoordinator: coordinator),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
      disableAnimations: false,
    );
    await _pumpUntilFound(tester, find.byKey(const ValueKey('intro-skip')));

    await _tapPointerOwned(tester, find.byKey(const ValueKey('intro-skip')));
    await _pumpUntilFound(tester, find.byType(AppShell));

    expect(find.byType(AppShell), findsOneWidget);
    expect(repository.state!.phase, OnboardingPhase.complete);
    expect(repository.state!.gateIntroAttempted, isTrue);
    expect(repository.state!.gateIntroConsumed, isTrue);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
  });

  testWidgets(
    'gate skip surface accepts Enter Space and Escape across presentation states',
    (tester) async {
      final cases =
          <
            ({
              String name,
              LogicalKeyboardKey key,
              bool videoReady,
              bool blockAttempt,
              ValueKey<String> surfaceKey,
            })
          >[
            (
              name: 'code scene',
              key: LogicalKeyboardKey.enter,
              videoReady: false,
              blockAttempt: false,
              surfaceKey: const ValueKey('intro-skip'),
            ),
            (
              name: 'video pending',
              key: LogicalKeyboardKey.space,
              videoReady: true,
              blockAttempt: false,
              surfaceKey: const ValueKey('intro-video-skip'),
            ),
            (
              name: 'attempt journal pending',
              key: LogicalKeyboardKey.escape,
              videoReady: false,
              blockAttempt: true,
              surfaceKey: const ValueKey('intro-skip'),
            ),
          ];

      for (final entry in cases) {
        TigerStageVideo.videoReady = entry.videoReady;
        final repository = _MemoryJourneyRepository(_gateState());
        final attemptBlocker = entry.blockAttempt ? Completer<void>() : null;
        repository.nextSaveBlocker = attemptBlocker;
        final coordinator = _coordinator(repository: repository);

        await _pumpEntry(
          tester,
          IntroGateScreen(
            deferVideoLeaseForTesting: entry.videoReady,
            firstRunCoordinator: coordinator,
          ),
          locale: const Locale('en'),
          viewport: (size: const Size(390, 844), textScale: 1.3),
          disableAnimations: false,
        );
        await _pumpUntilFound(tester, find.byKey(entry.surfaceKey));

        expect(
          tester.binding.focusManager.primaryFocus?.debugLabel,
          'intro-gate-skip-surface',
          reason: entry.name,
        );
        await tester.sendKeyEvent(entry.key);
        await tester.pump();

        if (attemptBlocker != null && !attemptBlocker.isCompleted) {
          attemptBlocker.complete();
        }
        await _pumpUntilFound(tester, find.byType(AppShell));

        expect(find.byType(AppShell), findsOneWidget, reason: entry.name);
        expect(repository.state!.phase, OnboardingPhase.complete);
        expect(repository.state!.gateIntroConsumed, isTrue);
        expect(tester.takeException(), isNull, reason: entry.name);
        await _disposeEntry(tester);
      }
      TigerStageVideo.videoReady = false;
    },
  );

  testWidgets('legacy introSeen write failure still opens AppShell', (
    tester,
  ) async {
    final repository = _MemoryJourneyRepository(_gateState());
    final coordinator = _coordinator(repository: repository);
    await _pumpEntry(
      tester,
      IntroGateScreen(
        firstRunCoordinator: coordinator,
        persistIntroSeenForTesting: () =>
            Future<void>.error(StateError('simulated preference failure')),
      ),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
      disableAnimations: false,
    );
    await _pumpUntilFound(tester, find.byKey(const ValueKey('intro-skip')));

    await _tapPointerOwned(tester, find.byKey(const ValueKey('intro-skip')));
    await _pumpUntilFound(tester, find.byType(AppShell));

    expect(find.byType(AppShell), findsOneWidget);
    expect(repository.state!.phase, OnboardingPhase.complete);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
  });

  testWidgets('failed attempted journal skips unjournaled gate media', (
    tester,
  ) async {
    final repository = _MemoryJourneyRepository(_gateState())
      ..failNextSave = true;
    final coordinator = _coordinator(repository: repository);
    await _pumpEntry(
      tester,
      IntroGateScreen(firstRunCoordinator: coordinator),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
      disableAnimations: false,
    );

    await _pumpUntilFound(tester, find.byType(AppShell));

    expect(find.byType(AppShell), findsOneWidget);
    expect(repository.state!.phase, OnboardingPhase.complete);
    expect(repository.state!.gateIntroConsumed, isTrue);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
  });

  testWidgets(
    'required character cards expose tap semantics and confirmation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = lookupAppL10n(const Locale('de'));
      await _pumpEntry(
        tester,
        const CharacterSelectionScreen(),
        locale: const Locale('de'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
      );

      final tiger = find.byKey(const ValueKey('character-option-tiger'));
      final data = tester.getSemantics(tiger).getSemanticsData();
      expect(data.label, contains(t.characterNameTiger));
      _expectAction(
        tester,
        tiger,
        minHeight: 48,
        selected: ui.Tristate.isFalse,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(t.characterNameTiger)}'),
        ),
        findsOneWidget,
      );

      await _tapPointerOwned(tester, tiger);
      await tester.pump();

      expect(find.text(t.characterSelectedTiger), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
      semantics.dispose();
    },
  );

  testWidgets('reduce-motion gate automatically consumes and opens AppShell', (
    tester,
  ) async {
    final repository = _MemoryJourneyRepository(_gateState());
    final coordinator = _coordinator(repository: repository);
    await _pumpEntry(
      tester,
      IntroGateScreen(firstRunCoordinator: coordinator),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
    );

    await _pumpUntilFound(tester, find.byType(AppShell));
    expect(find.byType(AppShell), findsOneWidget);
    expect(repository.state!.phase, OnboardingPhase.complete);
    expect(repository.state!.gateIntroConsumed, isTrue);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
  });

  testWidgets(
    'runtime reduce-motion change immediately stops video and consumes gate',
    (tester) async {
      final disableAnimations = ValueNotifier<bool>(false);
      addTearDown(disableAnimations.dispose);
      addTearDown(() => TigerStageVideo.videoReady = false);
      TigerStageVideo.videoReady = true;
      final repository = _MemoryJourneyRepository(_gateState());
      final coordinator = _coordinator(repository: repository);

      await _pumpEntry(
        tester,
        IntroGateScreen(
          deferVideoLeaseForTesting: true,
          firstRunCoordinator: coordinator,
        ),
        locale: const Locale('en'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
        disableAnimations: false,
        disableAnimationsListenable: disableAnimations,
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('intro-video-skip')),
      );
      expect(find.byKey(const ValueKey('intro-video-skip')), findsOneWidget);

      final consumeBlocker = Completer<void>();
      repository.nextSaveBlocker = consumeBlocker;
      disableAnimations.value = true;
      await tester.pump();

      expect(find.byKey(const ValueKey('intro-video-skip')), findsNothing);
      expect(find.byKey(const ValueKey('intro-skip')), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      consumeBlocker.complete();
      await _pumpUntilFound(tester, find.byType(AppShell));

      expect(find.byType(AppShell), findsOneWidget);
      expect(repository.state?.phase, OnboardingPhase.complete);
      expect(repository.state?.gateIntroConsumed, isTrue);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
    },
  );

  testWidgets('video intro exposes the same localized executable skip action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = lookupAppL10n(const Locale('de'));
    TigerStageVideo.videoReady = true;
    final repository = _MemoryJourneyRepository(_gateState());
    final coordinator = _coordinator(repository: repository);
    await _pumpEntry(
      tester,
      IntroGateScreen(
        deferVideoLeaseForTesting: true,
        firstRunCoordinator: coordinator,
      ),
      locale: const Locale('de'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
      disableAnimations: false,
    );

    final skip = find.byKey(const ValueKey('intro-video-skip'));
    final data = tester.getSemantics(skip).getSemanticsData();
    expect(data.label, t.introSkipHint);
    _expectAction(tester, skip, minHeight: 48);
    _expectPointerOwned(tester, skip);

    await _tapPointerOwned(tester, skip);
    await _pumpUntilFound(tester, find.byType(AppShell));
    expect(find.byType(AppShell), findsOneWidget);
    expect(repository.state!.phase, OnboardingPhase.complete);
    expect(repository.state!.gateIntroConsumed, isTrue);
    expect(tester.takeException(), isNull);
    TigerStageVideo.videoReady = false;
    await _disposeEntry(tester);
    semantics.dispose();
  });

  testWidgets('preview advances without an animated intermediate state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = lookupAppL10n(const Locale('de'));
    await _pumpEntry(
      tester,
      const OnboardingPreviewScreen(),
      locale: const Locale('de'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 0);
    final next = find.bySemanticsLabel(t.previewNext);
    _expectAction(tester, next, minHeight: 48);
    await _tapPointerOwned(tester, next);
    expect(pageView.controller!.page, 1);
    expect(find.text(t.previewPage2Title), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
    semantics.dispose();
  });

  testWidgets('preview retains the exact normal-motion advance duration', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = lookupAppL10n(const Locale('en'));
    await _pumpEntry(
      tester,
      const OnboardingPreviewScreen(),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
      disableAnimations: false,
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final next = find.bySemanticsLabel(t.previewNext);
    await _tapPointerOwned(tester, next);
    await tester.pump(const Duration(milliseconds: 359));
    expect(pageView.controller!.page, greaterThan(0));
    expect(pageView.controller!.page, lessThan(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(pageView.controller!.page, 1);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
    semantics.dispose();
  });
}

List<_EntryFixture> _fixtures(AppL10n t) => [
  (
    name: 'splash',
    build: () => const SplashScreen(),
    anchor: (_) => find.byType(Image),
    action: null,
    safeVisual: (_) => find.byType(Image),
    actionUsesSafeArea: false,
    actionMayExceedViewport: false,
  ),
  (
    name: 'consent',
    build: () => ConsentScreen.preview(onPreviewAccepted: () {}),
    anchor: (_) => find.text(t.consentTitle),
    action: (_) => find.bySemanticsLabel(t.consentContinueCta),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: false,
  ),
  (
    name: 'onboarding preview',
    build: () => const OnboardingPreviewScreen(),
    anchor: (_) => find.text(t.previewPage1Title),
    action: (_) => find.bySemanticsLabel(t.previewNext),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: false,
  ),
  (
    name: 'first voice success',
    build: () => FirstVoiceSuccessScreen(
      canDo: t.firstVoiceCanDo,
      phrase: '안녕하세요.',
      completedTasks: 1,
      totalTasks: 1,
      finishOverride: (_) async {},
      chooseCompanionOverride: () async {},
    ),
    anchor: (_) => find.text(t.firstVoiceTitle),
    action: (_) => find.bySemanticsLabel(t.onboardingCompanionChoose),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: false,
  ),
  (
    name: 'character selection',
    build: () => const CharacterSelectionScreen(),
    anchor: (_) => find.text(t.characterSelectionTitle),
    action: (_) => find.byKey(const ValueKey('character-option-tiger')),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: true,
  ),
  (
    name: 'placement diagnostic',
    build: () => PlacementDiagnosticScreen(onChooseLevel: (_) async {}),
    anchor: (_) => find.text(t.placementTitle),
    action: null,
    safeVisual: null,
    actionUsesSafeArea: false,
    actionMayExceedViewport: false,
  ),
];

Future<void> _pumpEntry(
  WidgetTester tester,
  Widget child, {
  required Locale locale,
  required ({Size size, double textScale}) viewport,
  bool disableAnimations = true,
  ValueListenable<bool>? disableAnimationsListenable,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    _host(
      locale: locale,
      viewport: viewport,
      disableAnimations: disableAnimations,
      disableAnimationsListenable: disableAnimationsListenable,
      child: child,
    ),
  );
  await tester.pump();
}

Widget _host({
  required Locale locale,
  required Widget child,
  ({Size size, double textScale}) viewport = const (
    size: Size(390, 844),
    textScale: 1,
  ),
  bool disableAnimations = true,
  ValueListenable<bool>? disableAnimationsListenable,
}) => MaterialApp(
  key: UniqueKey(),
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    Widget withMediaQuery(bool animationsDisabled) => MediaQuery(
      data: media.copyWith(
        padding: _safeInsets,
        viewPadding: _safeInsets,
        textScaler: TextScaler.linear(viewport.textScale),
        disableAnimations: animationsDisabled,
      ),
      child: SoriTypeScale(child: appChild!),
    );

    final listenable = disableAnimationsListenable;
    if (listenable == null) {
      return withMediaQuery(disableAnimations);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, animationsDisabled, child) =>
          withMediaQuery(animationsDisabled),
    );
  },
  home: child,
);

Future<void> _disposeEntry(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 4));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

FirstRunCoordinator _coordinator({
  _MemoryJourneyRepository? repository,
  LegacyOnboardingSnapshot legacy = const LegacyOnboardingSnapshot(
    consentAccepted: true,
    hasCompletedOnboarding: false,
  ),
}) {
  return FirstRunCoordinator(
    repository: repository ?? _MemoryJourneyRepository(),
    legacyStateReader: _LegacyReader(legacy),
    commitGateway: _CommitGateway(),
    clock: () => DateTime.utc(2026, 8, 26, 12),
  );
}

OnboardingJourneyState _gateState() {
  return OnboardingJourneyState.initial(DateTime.utc(2026, 8, 26, 12)).copyWith(
    phase: OnboardingPhase.gate,
    storyPage: StoryPageId.heritageJourney,
    purposeDraft: OnboardingPurpose.dailyTravel,
    levelDraft: LearnerLevel.a1,
    companionDraft: OnboardingCompanion.taego,
    commitStage: OnboardingCommitStage.completed,
  );
}

class _MemoryJourneyRepository implements OnboardingJourneyRepository {
  _MemoryJourneyRepository([this.state]);

  OnboardingJourneyState? state;
  bool failNextLoad = false;
  bool failNextSave = false;
  Completer<void>? nextLoadBlocker;
  Completer<void>? nextSaveBlocker;

  @override
  Future<void> clear() async {
    state = null;
  }

  @override
  Future<OnboardingJourneyState?> load() async {
    final blocker = nextLoadBlocker;
    nextLoadBlocker = null;
    if (blocker != null) {
      await blocker.future;
    }
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('simulated journey read failure');
    }
    return state;
  }

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    final blocker = nextSaveBlocker;
    nextSaveBlocker = null;
    if (blocker != null) {
      await blocker.future;
    }
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated journey write failure');
    }
    assertCurrentWrite?.call();
    this.state = state;
  }
}

class _LegacyReader implements LegacyOnboardingStateReader {
  _LegacyReader(this.snapshot);

  final LegacyOnboardingSnapshot snapshot;

  @override
  Future<LegacyOnboardingSnapshot> read() async => snapshot;
}

class _CommitGateway implements OnboardingCommitGateway {
  OnboardingPurpose? purpose;
  LearnerLevel? placement;
  LearnerLevel? browse;
  OnboardingCompanion? companion;

  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) async {
    placement = level;
  }

  @override
  Future<bool> isLegacyOnboardingComplete() async => true;

  @override
  Future<void> markLegacyOnboardingComplete() async {}

  @override
  Future<OnboardingCompanion?> readCompanion() async => companion;

  @override
  Future<OnboardingPlacementSnapshot> readPlacement() async {
    return OnboardingPlacementSnapshot(
      placementLevel: placement,
      browseLevel: browse,
    );
  }

  @override
  Future<OnboardingPurpose?> readPurpose() async => purpose;

  @override
  Future<void> saveCompanion(OnboardingCompanion companion) async {
    this.companion = companion;
  }

  @override
  Future<void> savePurpose(OnboardingPurpose purpose) async {
    this.purpose = purpose;
  }

  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) async {
    browse = level;
  }
}

Future<void> _centerInScrollable(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(
    finder.evaluate().single,
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
}

void _expectAction(
  WidgetTester tester,
  Finder finder, {
  required double minHeight,
  ui.Tristate? selected,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  if (selected != null) {
    expect(data.flagsCollection.isSelected, selected);
  }
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
}

void _expectFullyVisible(
  WidgetTester tester,
  Finder finder,
  Size viewport, {
  required bool useSafeArea,
  String? reason,
}) {
  final rect = tester.getRect(finder);
  final bounds = useSafeArea
      ? Rect.fromLTRB(
          0,
          _safeInsets.top,
          viewport.width,
          viewport.height - _safeInsets.bottom,
        )
      : Offset.zero & viewport;
  expect(rect.width, greaterThan(0), reason: reason);
  expect(rect.height, greaterThan(0), reason: reason);
  expect(rect.left, greaterThanOrEqualTo(bounds.left), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(bounds.top), reason: reason);
  expect(rect.right, lessThanOrEqualTo(bounds.right), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(bounds.bottom), reason: reason);
}

void _expectPointerOwned(WidgetTester tester, Finder finder) {
  final gesture = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final target = gesture.evaluate().length == 1 ? gesture : finder;
  final box = tester.renderObject<RenderBox>(target);
  expect(
    _ownedHitPoint(tester, box),
    isNotNull,
    reason: 'Control has no pointer-owned hit point.',
  );
}

void _expectReachableInSafeArea(
  WidgetTester tester,
  Finder finder,
  Size viewport, {
  String? reason,
}) {
  final bounds = Rect.fromLTRB(
    0,
    _safeInsets.top,
    viewport.width,
    viewport.height - _safeInsets.bottom,
  );
  final visible = tester.getRect(finder).intersect(bounds);
  expect(visible.width, greaterThanOrEqualTo(48), reason: reason);
  expect(visible.height, greaterThanOrEqualTo(48), reason: reason);
}

Future<void> _tapPointerOwned(WidgetTester tester, Finder finder) async {
  await _centerInScrollable(tester, finder);
  final gesture = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final target = gesture.evaluate().length == 1 ? gesture : finder;
  final box = tester.renderObject<RenderBox>(target);
  final point = _ownedHitPoint(tester, box);
  expect(point, isNotNull, reason: 'Control has no pointer-owned hit point.');
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    await tester.tapAt(point!);
    await tester.pump();
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  }
}

Offset? _ownedHitPoint(WidgetTester tester, RenderBox targetBox) {
  const candidates = <Offset>[
    Offset(0.5, 0.5),
    Offset(0.25, 0.5),
    Offset(0.75, 0.5),
    Offset(0.5, 0.25),
    Offset(0.5, 0.75),
  ];
  for (final fraction in candidates) {
    final point = targetBox.localToGlobal(
      Offset(
        targetBox.size.width * fraction.dx,
        targetBox.size.height * fraction.dy,
      ),
    );
    final result = HitTestResult();
    tester.binding.hitTestInView(result, point, tester.view.viewId);
    if (result.path.any((entry) => identical(entry.target, targetBox))) {
      return point;
    }
  }
  return null;
}
