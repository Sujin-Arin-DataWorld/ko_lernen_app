import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_home_tour': true,
    });
    await Storage.init();
    PrivacyConsentService.analyticsEnabled.value = false;
  });

  tearDown(() {
    PrivacyConsentService.analyticsEnabled.value = false;
    Storage.resetForTesting();
  });

  testWidgets(
    'AppShell retries a pending V2 completion once after analytics opt-in',
    (tester) async {
      final now = DateTime.utc(2026, 8, 26, 12);
      final repository = _MemoryJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.complete,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.peopleCulture,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.joy,
          commitStage: OnboardingCommitStage.completed,
          gateIntroAttempted: true,
          gateIntroConsumed: true,
          shellEntryEventSent: false,
        ),
      );
      final sink = _CompletionSink();
      final coordinator = FirstRunCoordinator(
        repository: repository,
        legacyStateReader: const _UnusedLegacyReader(),
        commitGateway: const _UnusedCommitGateway(),
        eventSink: sink,
        clock: () => now,
      );

      await tester.pumpWidget(_app(AppShell(firstRunCoordinator: coordinator)));
      await tester.pump();

      expect(sink.calls, 0);
      expect(repository.state!.shellEntryEventSent, isFalse);

      await Storage.setAnalyticsConsent(true);
      sink.allowed = true;
      PrivacyConsentService.analyticsEnabled.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(sink.calls, 1);
      expect(repository.state!.shellEntryEventSent, isTrue);

      PrivacyConsentService.analyticsEnabled.value = false;
      PrivacyConsentService.analyticsEnabled.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(sink.calls, 1);
    },
  );

  testWidgets(
    'a reset during AppShell journal load cannot recreate completed state',
    (tester) async {
      final now = DateTime.utc(2026, 8, 26, 12);
      final repository = _PausedLoadJourneyRepository(
        OnboardingJourneyState.initial(now).copyWith(
          phase: OnboardingPhase.complete,
          storyPage: StoryPageId.heritageJourney,
          purposeDraft: OnboardingPurpose.peopleCulture,
          levelDraft: LearnerLevel.b1,
          companionDraft: OnboardingCompanion.joy,
          commitStage: OnboardingCommitStage.completed,
          gateIntroAttempted: true,
          gateIntroConsumed: true,
          shellEntryEventSent: false,
        ),
      );
      final sink = _CompletionSink()..allowed = true;
      final coordinator = FirstRunCoordinator(
        repository: repository,
        legacyStateReader: const _UnusedLegacyReader(),
        commitGateway: const _UnusedCommitGateway(),
        eventSink: sink,
        clock: () => now,
      );

      await tester.pumpWidget(_app(AppShell(firstRunCoordinator: coordinator)));
      await repository.loadStarted.future;
      LocalDataLifetime.invalidate();
      await repository.clear();
      repository.releaseLoad.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(repository.state, isNull);
      expect(repository.saveCalls, 0);
      expect(sink.calls, 0);
    },
  );
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

class _MemoryJourneyRepository implements OnboardingJourneyRepository {
  _MemoryJourneyRepository(this.state);

  OnboardingJourneyState? state;

  @override
  Future<void> clear() async => state = null;

  @override
  Future<OnboardingJourneyState?> load() async => state;

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    this.state = state;
  }
}

class _PausedLoadJourneyRepository implements OnboardingJourneyRepository {
  _PausedLoadJourneyRepository(this.state);

  OnboardingJourneyState? state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<void> releaseLoad = Completer<void>();
  int saveCalls = 0;

  @override
  Future<void> clear() async => state = null;

  @override
  Future<OnboardingJourneyState?> load() async {
    final captured = state;
    loadStarted.complete();
    await releaseLoad.future;
    return captured;
  }

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    saveCalls++;
    this.state = state;
  }
}

class _CompletionSink implements OnboardingCompletionEventSink {
  bool allowed = false;
  int calls = 0;

  @override
  bool get canRecordOnboardingCompleted => allowed;

  @override
  Future<void> recordOnboardingCompleted(OnboardingJourneyState state) async {
    calls++;
  }
}

class _UnusedLegacyReader implements LegacyOnboardingStateReader {
  const _UnusedLegacyReader();

  @override
  Future<LegacyOnboardingSnapshot> read() {
    throw UnimplementedError('AppShell completion does not read legacy state.');
  }
}

class _UnusedCommitGateway implements OnboardingCommitGateway {
  const _UnusedCommitGateway();

  Never _unused() {
    throw UnimplementedError('AppShell completion does not commit onboarding.');
  }

  @override
  Future<bool> hasConsent() => _unused();

  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) => _unused();

  @override
  Future<bool> isLegacyOnboardingComplete() => _unused();

  @override
  Future<void> markLegacyOnboardingComplete() => _unused();

  @override
  Future<OnboardingCompanion?> readCompanion() => _unused();

  @override
  Future<OnboardingPlacementSnapshot> readPlacement() => _unused();

  @override
  Future<OnboardingPurpose?> readPurpose() => _unused();

  @override
  Future<void> saveCompanion(OnboardingCompanion companion) => _unused();

  @override
  Future<void> savePurpose(OnboardingPurpose purpose) => _unused();

  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) => _unused();
}
