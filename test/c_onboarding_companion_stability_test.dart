import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_onboarding.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _scrollKey = ValueKey('onboarding-v2-companion-scroll');
const _continueKey = ValueKey('onboarding-v2-companion-continue');
const _cases = [
  (size: Size(402, 934), scale: 1.0, reduced: false),
  (size: Size(402, 640), scale: 1.0, reduced: false),
  (size: Size(320, 640), scale: 2.0, reduced: true),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    for (final family in ['Roboto', 'RobotoCondensed', 'Lora', 'NotoSerif']) {
      final loader = FontLoader(family);
      loader.addFont(
        rootBundle.load('assets/fonts/$family/$family-Variable.ttf'),
      );
      await loader.load();
    }
  });
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
  });

  for (final config in _cases) {
    testWidgets('companion selection retains identity, scroll and bounds '
        '${config.size} text ${config.scale}', (tester) async {
      final fixture = await _pumpJourney(
        tester,
        size: config.size,
        textScale: config.scale,
        reducedMotion: config.reduced,
      );
      expect(_action(tester).onTap, isNull);
      final initial = _Layout.read(tester);

      for (final fraction in [0.0, .5, 1.0]) {
        final position = _position(tester);
        // This is intentional user scrolling before the measurement. Do not
        // ensureVisible after a selection: it would hide a scroll regression.
        position.jumpTo(position.maxScrollExtent * fraction);
        await tester.pumpAndSettle();
        final before = _Layout.read(tester);
        var previous = _selected(tester);
        for (final id in ['joy', 'taego', 'joy', 'joy']) {
          final writes = fixture.repository.saved.length;
          // Use the real JourneyScreen callback even when the other card is
          // outside a 200% single-column viewport. Pointer/keyboard activation
          // is exercised separately below; no test-owned selection state.
          _choose(tester, id);
          await tester.pump(const Duration(milliseconds: 16));
          before.expectUnchanged(tester, 'optimistic $id at $fraction');
          await tester.pumpAndSettle();
          before.expectUnchanged(tester, 'saved $id at $fraction');
          _expectSelection(tester, id);
          _expectCtaTextFits(tester);
          expect(fixture.repository.state!.companionDraft!.name, id);
          if (id == previous) {
            expect(fixture.repository.saved.length, writes);
          }
          previous = id;
        }
        // Empty -> selected must reserve the same footer height, including
        // differently wrapped German labels at 200% text scale.
        expect(tester.getRect(find.byKey(_continueKey)), initial.cta);
      }
      expect(fixture.gateway.calls, 0);
      expect(fixture.repository.state!.phase, OnboardingPhase.companion);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rapid pointer choices preserve the latest serialized intent', (
    tester,
  ) async {
    final fixture = await _pumpJourney(tester, size: const Size(402, 934));
    final joy = _card('joy');
    await tester.ensureVisible(joy);
    await tester.pumpAndSettle();
    expect(joy.hitTestable(), findsOneWidget);
    expect(_card('taego').hitTestable(), findsOneWidget);
    final before = _Layout.read(tester);
    final blocker = Completer<void>();
    fixture.repository.nextSaveBlocker = blocker;

    for (final id in ['joy', 'taego', 'joy']) {
      await tester.tap(_card(id));
      await tester.pump(const Duration(milliseconds: 16));
      _expectSelection(tester, id);
      before.expectUnchanged(tester, 'pending pointer $id');
    }
    expect(fixture.repository.state!.companionDraft, isNull);
    blocker.complete();
    await tester.pumpAndSettle();
    before.expectUnchanged(tester, 'all serialized saves resolved');
    _expectSelection(tester, 'joy');
    expect(fixture.repository.saved.map((state) => state.companionDraft), [
      OnboardingCompanion.joy,
      OnboardingCompanion.taego,
      OnboardingCompanion.joy,
    ]);
    expect(fixture.repository.state!.companionDraft, OnboardingCompanion.joy);
    expect(fixture.gateway.calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed companion save restores durable choice without movement',
    (tester) async {
      final fixture = await _pumpJourney(
        tester,
        size: const Size(402, 640),
        selected: OnboardingCompanion.taego,
      );
      final position = _position(tester);
      position.jumpTo(position.maxScrollExtent * .5);
      await tester.pumpAndSettle();
      final before = _Layout.read(tester);
      final blocker = Completer<void>();
      fixture.repository.nextSaveBlocker = blocker;
      fixture.repository.failNextSave = true;
      _choose(tester, 'joy');
      await tester.pump(const Duration(milliseconds: 16));
      _expectSelection(tester, 'joy');
      before.expectUnchanged(tester, 'optimistic failed-save choice');
      blocker.complete();
      await tester.pumpAndSettle();
      _expectSelection(tester, 'taego');
      before.expectUnchanged(tester, 'durable choice restored');
      expect(
        fixture.repository.state!.companionDraft,
        OnboardingCompanion.taego,
      );
      expect(fixture.repository.saved, isEmpty);
      expect(fixture.gateway.calls, 0);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard selection retains focus and selected semantics at 200%',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpJourney(
          tester,
          size: const Size(320, 640),
          textScale: 2,
          reducedMotion: true,
        );
        for (final id in ['joy', 'taego']) {
          final card = _card(id);
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          final context = tester.element(
            find.descendant(of: card, matching: find.byType(MouseRegion)).first,
          );
          final focus = Focus.of(context);
          focus.requestFocus();
          await tester.pumpAndSettle();
          final before = _Layout.read(tester);
          expect(focus.hasFocus, isTrue);
          await tester.sendKeyEvent(
            id == 'joy' ? LogicalKeyboardKey.enter : LogicalKeyboardKey.space,
          );
          await tester.pumpAndSettle();
          before.expectUnchanged(tester, 'keyboard $id');
          expect(Focus.of(context), same(focus));
          expect(focus.hasFocus, isTrue);
          _expectSelection(tester, id);
          final data = tester.getSemantics(_semantics(id)).getSemanticsData();
          expect(data.flagsCollection.isSelected, Tristate.isTrue);
          expect(data.flagsCollection.isFocused, Tristate.isTrue);
          expect(tester.getSize(card).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
          _expectCtaTextFits(tester);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}

Finder _card(String id) => find.byKey(ValueKey('onboarding-v2-companion-$id'));
Finder _semantics(String id) =>
    find.byKey(ValueKey('onboarding-v2-companion-semantics-$id'));
Finder get _screen => find.byType(OnboardingCompanionScreen);
Finder get _scrollable => find
    .descendant(of: find.byKey(_scrollKey), matching: find.byType(Scrollable))
    .first;
ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(_scrollable).position;
IntroAction _action(WidgetTester tester) =>
    tester.widget<IntroAction>(find.byKey(_continueKey));
String? _selected(WidgetTester tester) =>
    tester.widget<OnboardingCompanionScreen>(_screen).selectedCompanionId;
void _choose(WidgetTester tester, String id) =>
    tester.widget<OnboardingCompanionScreen>(_screen).onCompanionChanged(id);

void _expectSelection(WidgetTester tester, String id) {
  expect(_selected(tester), id);
  for (final companion in ['joy', 'taego']) {
    expect(
      tester.widget<Semantics>(_semantics(companion)).properties.selected,
      companion == id,
    );
  }
  final t = lookupAppL10n(const Locale('de'));
  expect(
    _action(tester).label,
    t.onboardingJourneyStartWith(id == 'joy' ? 'Joy' : 'Taego'),
  );
  expect(_action(tester).onTap, isNotNull);
}

void _expectCtaTextFits(WidgetTester tester) {
  final action = find.byKey(_continueKey);
  final bounds = tester.getRect(action);
  expect(bounds.height, greaterThanOrEqualTo(48));
  for (final element
      in find
          .descendant(of: action, matching: find.byType(RichText))
          .evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(paragraph.didExceedMaxLines, isFalse);
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    expect(rect.left, greaterThanOrEqualTo(bounds.left - .1));
    expect(rect.right, lessThanOrEqualTo(bounds.right + .1));
    expect(rect.top, greaterThanOrEqualTo(bounds.top - .1));
    expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + .1));
  }
}

class _Layout {
  _Layout.read(WidgetTester tester)
    : screen = tester.element(_screen),
      scrollState = tester.state<ScrollableState>(_scrollable),
      position = _position(tester),
      pixels = _position(tester).pixels,
      extent = _position(tester).maxScrollExtent,
      viewport = _position(tester).viewportDimension,
      hero = tester.getRect(
        find.text(lookupAppL10n(const Locale('de')).onboardingCCompanionTitle),
      ),
      taego = tester.getRect(_card('taego')),
      joy = tester.getRect(_card('joy')),
      cta = tester.getRect(find.byKey(_continueKey));

  final Element screen;
  final ScrollableState scrollState;
  final ScrollPosition position;
  final double pixels, extent, viewport;
  final Rect hero, taego, joy, cta;

  void expectUnchanged(WidgetTester tester, String reason) {
    final now = _Layout.read(tester);
    expect(now.screen, same(screen), reason: '$reason: screen identity');
    expect(
      now.scrollState,
      same(scrollState),
      reason: '$reason: scroll identity',
    );
    expect(now.position, same(position), reason: '$reason: position identity');
    expect(now.pixels, closeTo(pixels, .1), reason: '$reason: scroll offset');
    expect(now.extent, closeTo(extent, .1), reason: '$reason: content extent');
    expect(
      now.viewport,
      closeTo(viewport, .1),
      reason: '$reason: viewport height',
    );
    for (final pair in [
      (name: 'hero', before: hero, after: now.hero),
      (name: 'Taego', before: taego, after: now.taego),
      (name: 'Joy', before: joy, after: now.joy),
      (name: 'CTA', before: cta, after: now.cta),
    ]) {
      expect(pair.after, pair.before, reason: '$reason: ${pair.name} bounds');
    }
  }
}

Future<({_DraftRepository repository, _NoCommitGateway gateway})> _pumpJourney(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  bool reducedMotion = false,
  OnboardingCompanion? selected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = OnboardingJourneyState.initial(DateTime.utc(2026, 10, 18))
      .copyWith(
        phase: OnboardingPhase.companion,
        storyPage: StoryPageId.heritageJourney,
        purposeDraft: OnboardingPurpose.dailyTravel,
        levelDraft: LearnerLevel.a1,
        companionDraft: selected,
      );
  final repository = _DraftRepository(state);
  final gateway = _NoCommitGateway();
  final coordinator = FirstRunCoordinator(
    repository: repository,
    legacyStateReader: _UnusedLegacyReader(),
    commitGateway: gateway,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: OnboardingV2JourneyScreen(
        firstRunCoordinator: coordinator,
        initialResolution: FirstRunResolution(
          entry: FirstRunEntry.companion,
          state: state,
          migratedLegacyState: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await settleEinleitungCaptureAssets(tester);
  expect(_screen, findsOneWidget);
  expect(tester.takeException(), isNull);
  return (repository: repository, gateway: gateway);
}

class _DraftRepository implements OnboardingJourneyRepository {
  _DraftRepository(this.state);
  OnboardingJourneyState? state;
  final saved = <OnboardingJourneyState>[];
  Completer<void>? nextSaveBlocker;
  bool failNextSave = false;
  @override
  Future<OnboardingJourneyState?> load() async => state;
  @override
  Future<void> clear() async => state = null;
  @override
  Future<void> save(
    OnboardingJourneyState next, {
    void Function()? assertCurrentWrite,
  }) async {
    final blocker = nextSaveBlocker;
    nextSaveBlocker = null;
    if (blocker != null) {
      await blocker.future;
    }
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated companion draft failure');
    }
    assertCurrentWrite?.call();
    state = next;
    saved.add(next);
  }
}

class _UnusedLegacyReader implements LegacyOnboardingStateReader {
  @override
  Future<LegacyOnboardingSnapshot> read() =>
      throw StateError('The test supplies an existing companion resolution.');
}

// No final CTA is pressed in these tests. A selection must never cross the
// product-write boundary; the real coordinator's serialized draft path is used.
class _NoCommitGateway implements OnboardingCommitGateway {
  int calls = 0;
  Never _unexpected() {
    calls++;
    throw StateError('Companion selection attempted a product commit.');
  }

  @override
  Future<bool> hasConsent() async => _unexpected();
  @override
  Future<OnboardingPurpose?> readPurpose() async => _unexpected();
  @override
  Future<void> savePurpose(OnboardingPurpose purpose) async => _unexpected();
  @override
  Future<OnboardingPlacementSnapshot> readPlacement() async => _unexpected();
  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) async => _unexpected();
  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) async =>
      _unexpected();
  @override
  Future<OnboardingCompanion?> readCompanion() async => _unexpected();
  @override
  Future<void> saveCompanion(OnboardingCompanion companion) async =>
      _unexpected();
  @override
  Future<bool> isLegacyOnboardingComplete() async => _unexpected();
  @override
  Future<void> markLegacyOnboardingComplete() async => _unexpected();
}
