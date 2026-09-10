import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_character_media.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);

  testWidgets('companion choices wire Taego to tiger and Joy to magpie media', (
    tester,
  ) async {
    await _pump(tester, const _CompanionHarness(selectedCompanionId: null));
    await _pumpFinite(tester);

    final media = tester
        .widgetList<OnboardingCharacterMedia>(
          find.byType(OnboardingCharacterMedia),
        )
        .toList(growable: false);
    expect(media, hasLength(2));
    expect(media.map((item) => item.characterId), ['tiger', 'magpie']);
    expect(
      media.map((item) => item.motion),
      everyElement(OnboardingCharacterMotion.idle),
    );
    expect(media.map((item) => item.active), everyElement(isFalse));
    expect(media.map((item) => item.resolvedPosterAsset), [
      'assets/illustrations/onboarding/companions/taego_idle.png',
      'assets/illustrations/onboarding/companions/joy_idle.png',
    ]);
    expect(
      find.byKey(const ValueKey('onboarding-character-neutral-fallback')),
      findsNothing,
      reason: 'The bundled transparent posters must load for both companions.',
    );
    _expectNoLegacyMediaOrTint();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected companion alone receives select motion', (
    tester,
  ) async {
    await _pump(
      tester,
      const _CompanionHarness(
        selectedCompanionId: OnboardingV2Ids.companionJoy,
      ),
    );
    await _pumpFinite(tester);

    final media = tester
        .widgetList<OnboardingCharacterMedia>(
          find.byType(OnboardingCharacterMedia),
        )
        .toList(growable: false);
    expect(media, hasLength(2));
    expect(media[0].characterId, 'tiger');
    expect(media[0].motion, OnboardingCharacterMotion.idle);
    expect(media[0].active, isFalse);
    expect(media[1].characterId, 'magpie');
    expect(media[1].motion, OnboardingCharacterMotion.select);
    expect(media[1].active, isTrue);
    _expectNoLegacyMediaOrTint();
  });

  testWidgets(
    'journey keeps the 30th rapid choice while delayed saves serialize',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
      await Storage.init();
      final initialState =
          OnboardingJourneyState.initial(
            DateTime.utc(2026, 9, 10, 12),
          ).copyWith(
            phase: OnboardingPhase.companion,
            storyPage: StoryPageId.heritageJourney,
            purposeDraft: OnboardingPurpose.dailyTravel,
            levelDraft: LearnerLevel.a1,
          );
      final repository = _DelayedJourneyRepository(initialState);
      final coordinator = FirstRunCoordinator(
        repository: repository,
        legacyStateReader: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        commitGateway: _CommitGateway(),
        clock: () => DateTime.utc(2026, 9, 10, 12),
      );

      await _pump(
        tester,
        OnboardingV2JourneyScreen(
          firstRunCoordinator: coordinator,
          initialResolution: FirstRunResolution(
            entry: FirstRunEntry.companion,
            state: initialState,
            migratedLegacyState: false,
          ),
        ),
      );
      await tester.pump();

      final taego = find.byKey(const ValueKey('onboarding-v2-companion-taego'));
      final joy = find.byKey(const ValueKey('onboarding-v2-companion-joy'));
      for (var index = 0; index < 30; index++) {
        await tester.tap(index.isEven ? joy : taego);
      }
      await tester.pump();

      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey('onboarding-v2-companion-semantics-taego'),
              ),
            )
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      final media = tester
          .widgetList<OnboardingCharacterMedia>(
            find.byType(OnboardingCharacterMedia),
          )
          .toList(growable: false);
      expect(
        media.singleWhere((item) => item.characterId == 'tiger').motion,
        OnboardingCharacterMotion.select,
      );

      await _releaseSaves(tester, repository, count: 29, failAt: 9);
      expect(
        repository.attemptedStates,
        hasLength(29),
        reason:
            'The choice immediately after the failed Taego write is Joy, '
            'which still matches durable state and needs no duplicate write.',
      );
      expect(repository.state?.companionDraft, OnboardingCompanion.taego);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('onboarding-v2-companion-continue')),
      );
      await tester.pump();
      await _releaseSaves(tester, repository, count: 1);
      await tester.pump();

      expect(repository.state?.phase, OnboardingPhase.confirmation);
      expect(repository.state?.companionDraft, OnboardingCompanion.taego);
      expect(
        find.byType(OnboardingCompanionConfirmationScreen),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'latest failed choice restores durable companion and retry continues',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
      await Storage.init();
      final initialState =
          OnboardingJourneyState.initial(
            DateTime.utc(2026, 9, 10, 12),
          ).copyWith(
            phase: OnboardingPhase.companion,
            storyPage: StoryPageId.heritageJourney,
            purposeDraft: OnboardingPurpose.dailyTravel,
            levelDraft: LearnerLevel.a1,
          );
      final repository = _DelayedJourneyRepository(initialState);
      final coordinator = FirstRunCoordinator(
        repository: repository,
        legacyStateReader: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        commitGateway: _CommitGateway(),
        clock: () => DateTime.utc(2026, 9, 10, 12),
      );

      await _pump(
        tester,
        OnboardingV2JourneyScreen(
          firstRunCoordinator: coordinator,
          initialResolution: FirstRunResolution(
            entry: FirstRunEntry.companion,
            state: initialState,
            migratedLegacyState: false,
          ),
        ),
      );
      await tester.pump();

      final taego = find.byKey(const ValueKey('onboarding-v2-companion-taego'));
      final joy = find.byKey(const ValueKey('onboarding-v2-companion-joy'));
      final continueButton = find.byKey(
        const ValueKey('onboarding-v2-companion-continue'),
      );

      await tester.tap(taego);
      await tester.pump();
      await _releaseSaves(tester, repository, count: 1);
      expect(repository.state?.companionDraft, OnboardingCompanion.taego);

      await tester.tap(joy);
      await tester.pump();
      expect(_isSelected(tester, OnboardingV2Ids.companionJoy), isTrue);
      await tester.tap(continueButton);
      await tester.pump();
      await _releaseSaves(tester, repository, count: 1, failAt: 1);
      await _pumpFinite(tester);

      expect(repository.state?.phase, OnboardingPhase.companion);
      expect(repository.state?.companionDraft, OnboardingCompanion.taego);
      expect(_isSelected(tester, OnboardingV2Ids.companionTaego), isTrue);
      expect(
        find.byType(OnboardingCompanionConfirmationScreen),
        findsNothing,
        reason: 'Continue must not confirm an unpersisted failed choice.',
      );
      expect(tester.takeException(), isNull);

      await tester.tap(continueButton);
      await tester.pump();
      await _releaseSaves(tester, repository, count: 1);
      await tester.pump();

      expect(repository.state?.phase, OnboardingPhase.confirmation);
      expect(repository.state?.companionDraft, OnboardingCompanion.taego);
      expect(
        find.byType(OnboardingCompanionConfirmationScreen),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  for (final testCase in const <({String companionId, String characterId})>[
    (companionId: OnboardingV2Ids.companionTaego, characterId: 'tiger'),
    (companionId: OnboardingV2Ids.companionJoy, characterId: 'magpie'),
  ]) {
    testWidgets('${testCase.companionId} confirmation uses one-shot '
        '${testCase.characterId} media', (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => OnboardingCompanionConfirmationScreen(
            copy: onboardingV2Copy(AppL10n.of(context)),
            companionId: testCase.companionId,
            onStart: () {},
            onChange: () {},
          ),
        ),
      );
      await _pumpFinite(tester);

      final media = tester.widget<OnboardingCharacterMedia>(
        find.byType(OnboardingCharacterMedia),
      );
      expect(media.characterId, testCase.characterId);
      expect(media.motion, OnboardingCharacterMotion.confirm);
      expect(media.active, isTrue);
      expect(media.resolvedAnimationAsset, contains('_choose.webp'));
      expect(media.resolvedAnimationAsset, isNot(contains('/video/')));
      expect(
        find.byKey(const ValueKey('onboarding-character-neutral-fallback')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('onboarding-character-poster-${media.resolvedPosterAsset}'),
        ),
        findsOneWidget,
      );
      _expectNoLegacyMediaOrTint();
      expect(tester.takeException(), isNull);
    });
  }
}

void _expectNoLegacyMediaOrTint() {
  expect(find.byType(CharacterClipPlayer), findsNothing);
  expect(find.byType(TigerStageVideo), findsNothing);
  expect(find.byType(ColorFiltered), findsNothing);
}

bool _isSelected(WidgetTester tester, String companionId) =>
    tester
        .getSemantics(
          find.byKey(
            ValueKey('onboarding-v2-companion-semantics-$companionId'),
          ),
        )
        .getSemanticsData()
        .flagsCollection
        .isSelected ==
    Tristate.isTrue;

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(720, 1152);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    ),
  );
}

Future<void> _pumpFinite(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _releaseSaves(
  WidgetTester tester,
  _DelayedJourneyRepository repository, {
  required int count,
  int? failAt,
}) async {
  final target = repository.completedSaves + count;
  final maxPumps = 100 + count * 32;
  for (
    var attempt = 0;
    attempt < maxPumps && repository.completedSaves < target;
    attempt++
  ) {
    await tester.pump();
    if (repository.hasPendingSave) {
      final next = repository.completedSaves;
      repository.completeNext(fail: failAt == next);
    }
  }
  expect(repository.completedSaves, target);
  await tester.pump();
}

class _CompanionHarness extends StatefulWidget {
  const _CompanionHarness({required this.selectedCompanionId});

  final String? selectedCompanionId;

  @override
  State<_CompanionHarness> createState() => _CompanionHarnessState();
}

class _CompanionHarnessState extends State<_CompanionHarness> {
  late String? selectedCompanionId = widget.selectedCompanionId;

  @override
  Widget build(BuildContext context) => OnboardingCompanionScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedCompanionId: selectedCompanionId,
    onCompanionChanged: (value) {
      setState(() => selectedCompanionId = value);
    },
    onContinue: (_) {},
  );
}

class _DelayedJourneyRepository implements OnboardingJourneyRepository {
  _DelayedJourneyRepository(this.state);

  OnboardingJourneyState? state;
  final List<OnboardingJourneyState> attemptedStates = [];
  final List<Completer<void>> _gates = [];
  int completedSaves = 0;

  bool get hasPendingSave =>
      _gates.length > completedSaves && !_gates[completedSaves].isCompleted;

  void completeNext({bool fail = false}) {
    final gate = _gates[completedSaves];
    if (fail) {
      gate.completeError(StateError('synthetic delayed-save failure'));
    } else {
      state = attemptedStates[completedSaves];
      gate.complete();
    }
    completedSaves += 1;
  }

  @override
  Future<void> clear() async {
    state = null;
  }

  @override
  Future<OnboardingJourneyState?> load() async => state;

  @override
  Future<void> save(
    OnboardingJourneyState next, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    attemptedStates.add(next);
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
  }
}

class _LegacyReader implements LegacyOnboardingStateReader {
  const _LegacyReader(this.snapshot);

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
