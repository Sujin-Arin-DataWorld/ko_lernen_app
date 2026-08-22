import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/intro_gate_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_level_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_preview_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/placement_diagnostic_screen.dart';
import 'package:ko_lernen_app/screens/quick_onboarding_screen.dart';
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

  testWidgets('splash preserves the complete startup destination table', (
    tester,
  ) async {
    final cases = <({Map<String, Object> preferences, Type destination})>[
      (preferences: const {}, destination: ConsentScreen),
      (
        preferences: const {'kl_consent_accepted': true},
        destination: OnboardingStartScreen,
      ),
      (
        preferences: const {
          'kl_onboarding_completed': true,
          'kl_session_count': 1,
          'kl_user_level': 'a1',
        },
        destination: IntroGateScreen,
      ),
      (
        preferences: const {
          'kl_onboarding_completed': true,
          'kl_session_count': 5,
          'kl_user_level': 'a1',
        },
        destination: AppShell,
      ),
    ];

    for (final entry in cases) {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(entry.preferences);
      await Storage.init();
      await _pumpEntry(
        tester,
        const SplashScreen(),
        locale: const Locale('en'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
      );
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byType(entry.destination), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
    }
  });

  testWidgets('intro preserves the complete post-gate destination table', (
    tester,
  ) async {
    final cases = <({Map<String, Object> preferences, Type destination})>[
      (preferences: const {}, destination: ConsentScreen),
      (
        preferences: const {'kl_consent_accepted': true},
        destination: OnboardingStartScreen,
      ),
      (
        preferences: const {
          'kl_consent_accepted': true,
          'kl_onboarding_completed': true,
          'kl_user_level': 'a1',
        },
        destination: AppShell,
      ),
    ];

    for (final entry in cases) {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(entry.preferences);
      await Storage.init();
      await _pumpEntry(
        tester,
        const IntroGateScreen(),
        locale: const Locale('en'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
      );

      await _tapPointerOwned(tester, find.byKey(const ValueKey('intro-skip')));
      await tester.pump();
      expect(find.byType(entry.destination), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
    }
  });

  testWidgets('onboarding choices announce their selected transition', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = lookupAppL10n(const Locale('en'));
    await _pumpEntry(
      tester,
      OnboardingStartScreen.preview(
        startNewLearner: (_) async {},
        openFirstScene: (_, __) async {},
        openPlacement: () async {},
      ),
      locale: const Locale('en'),
      viewport: (size: const Size(390, 844), textScale: 1.3),
    );

    final travel = _cardWithText(t.onboardingStartTravelTitle);
    final people = _cardWithText(t.onboardingStartPeopleTitle);
    _expectAction(tester, travel, minHeight: 48, selected: ui.Tristate.isTrue);
    _expectAction(tester, people, minHeight: 48, selected: ui.Tristate.isFalse);

    await _tapPointerOwned(tester, people);
    _expectAction(tester, travel, minHeight: 48, selected: ui.Tristate.isFalse);
    _expectAction(tester, people, minHeight: 48, selected: ui.Tristate.isTrue);
    expect(tester.takeException(), isNull);
    await _disposeEntry(tester);
    semantics.dispose();
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

  testWidgets(
    'intro skip is localized, actionable, and immediate when reduced',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = lookupAppL10n(const Locale('en'));
      await _pumpEntry(
        tester,
        const IntroGateScreen(),
        locale: const Locale('en'),
        viewport: (size: const Size(390, 844), textScale: 1.3),
      );

      final skip = find.byKey(const ValueKey('intro-skip'));
      final data = tester.getSemantics(skip).getSemanticsData();
      expect(data.label, t.introSkipHint);
      _expectAction(tester, skip, minHeight: 48);

      await _tapPointerOwned(tester, skip);
      await tester.pump();
      expect(find.byType(OnboardingStartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _disposeEntry(tester);
      semantics.dispose();
    },
  );

  testWidgets('video intro exposes the same localized executable skip action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = lookupAppL10n(const Locale('de'));
    TigerStageVideo.videoReady = true;
    await _pumpEntry(
      tester,
      const IntroGateScreen(deferVideoLeaseForTesting: true),
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
    await tester.pump();
    expect(find.byType(OnboardingStartScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    TigerStageVideo.videoReady = false;
    await _disposeEntry(tester);
    semantics.dispose();
  });

  testWidgets('level compare rows remain executable across the locked matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final locale in const [Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      for (final viewport in _viewports) {
        await _pumpEntry(
          tester,
          const OnboardingLevelScreen(),
          locale: locale,
          viewport: viewport,
        );

        final compare = find.bySemanticsLabel(t.onboardingCompareCta);
        await _tapPointerOwned(tester, compare);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(t.onboardingCompareTitle), findsOneWidget);

        final row = find.bySemanticsLabel(
          RegExp('^A1 ·.*${RegExp.escape(t.onboardingCompareColCan)}:'),
        );
        expect(row, findsOneWidget);
        await _centerInScrollable(tester, row);
        _expectAction(tester, row, minHeight: 48);
        _expectReachableInSafeArea(
          tester,
          row,
          viewport.size,
          reason:
              'compare row ${locale.languageCode} '
              '${viewport.size} @${viewport.textScale}',
        );
        _expectPointerOwned(tester, row);
        expect(tester.takeException(), isNull);
        await _disposeEntry(tester);
      }
    }
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
    name: 'quick onboarding',
    build: () => const QuickOnboardingScreen(),
    anchor: (_) => find.text(t.onboardingStartTitle),
    action: (_) => find.bySemanticsLabel(t.onboardingStartPrimary),
    safeVisual: null,
    actionUsesSafeArea: true,
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
    name: 'onboarding start',
    build: () => OnboardingStartScreen.preview(
      startNewLearner: (_) async {},
      openFirstScene: (_, __) async {},
      openPlacement: () async {},
    ),
    anchor: (_) => find.text(t.onboardingStartTitle),
    action: (_) => find.bySemanticsLabel(t.onboardingStartPrimary),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: false,
  ),
  (
    name: 'onboarding level',
    build: () => const OnboardingLevelScreen(),
    anchor: (_) => find.text(t.onboardingTitle),
    action: (_) => find.bySemanticsLabel(RegExp(r'^A1 ·')),
    safeVisual: null,
    actionUsesSafeArea: true,
    actionMayExceedViewport: true,
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
  (
    name: 'intro gate',
    build: () => const IntroGateScreen(),
    anchor: (_) => find.byKey(const ValueKey('intro-skip')),
    action: (_) => find.byKey(const ValueKey('intro-skip')),
    safeVisual: (_) => find.text(t.introSkipHint),
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
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    _host(
      locale: locale,
      viewport: viewport,
      disableAnimations: disableAnimations,
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
}) => MaterialApp(
  key: UniqueKey(),
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: _safeInsets,
        viewPadding: _safeInsets,
        textScaler: TextScaler.linear(viewport.textScale),
        disableAnimations: disableAnimations,
      ),
      child: SoriTypeScale(child: appChild!),
    );
  },
  home: child,
);

Future<void> _disposeEntry(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 4));
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

Finder _cardWithText(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(SoriCard)).first;

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
