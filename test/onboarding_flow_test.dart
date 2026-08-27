import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    Storage.unlockLearningWrites();
  });

  testWidgets('fresh startup reaches consent before any onboarding choice', (
    tester,
  ) async {
    await _launch(tester, const {});

    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.byType(OnboardingV2JourneyScreen), findsNothing);
  });

  testWidgets('consented learner without placement reaches mandatory story', (
    tester,
  ) async {
    await _launch(tester, const {'kl_consent_accepted': true});

    expect(find.byType(OnboardingV2JourneyScreen), findsOneWidget);
    expect(find.byType(OnboardingStoryScreen), findsOneWidget);
    expect(find.byType(ConsentScreen), findsNothing);
    expect(find.byType(ScenarioPlayerScreen), findsNothing);
    expect(find.byType(FirstVoiceSuccessScreen), findsNothing);
  });

  testWidgets('splash hands one resolved journey decision to the V2 screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
    final repository = _CountingRepository(
      SharedPreferencesOnboardingJourneyRepository(),
    );
    final coordinator = FirstRunCoordinator(
      repository: repository,
      legacyStateReader: const StorageLegacyOnboardingStateReader(),
      commitGateway: StorageOnboardingCommitGateway(
        courseProgress: CourseProgressService.app(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: SplashScreen(
          firstRunCoordinator: coordinator,
          displayDuration: Duration.zero,
        ),
      ),
    );
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(OnboardingStoryScreen).evaluate().isNotEmpty) break;
    }

    expect(find.byType(OnboardingStoryScreen), findsOneWidget);
    expect(repository.loadCalls, 1);
  });

  test('legacy public first-run routes construct only the V2 journey', () {
    final source = File('lib/main.dart').readAsStringSync();
    const routes = {
      '/quick_onboarding': 'QuickOnboardingScreen',
      '/character_selection': 'CharacterSelectionScreen',
      '/intro': 'IntroGateScreen',
      '/onboarding/legacy-level': 'OnboardingLevelScreen',
      '/onboarding/start': 'OnboardingStartScreen',
    };

    for (final entry in routes.entries) {
      final marker = "case '${entry.key}':";
      final start = source.indexOf(marker);
      expect(
        start,
        greaterThanOrEqualTo(0),
        reason: 'Missing route ${entry.key}',
      );
      final nextCase = source.indexOf(
        '\n            case ',
        start + marker.length,
      );
      expect(
        nextCase,
        greaterThanOrEqualTo(0),
        reason: 'Unbounded route ${entry.key}',
      );
      final routeBody = source.substring(start, nextCase);
      expect(
        routeBody,
        contains('OnboardingV2JourneyScreen'),
        reason: '${entry.key} must redirect to first-run V2.',
      );
      expect(
        routeBody,
        isNot(contains(entry.value)),
        reason: '${entry.key} must not expose ${entry.value}.',
      );
    }
  });

  test('root, canonical onboarding, and fallback routes cannot bypass V2', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final route in <String>['/', '/onboarding']) {
      final marker = "case '$route':";
      final start = source.indexOf(marker);
      expect(start, greaterThanOrEqualTo(0), reason: 'Missing route $route');
      final nextCase = source.indexOf(
        '\n            case ',
        start + marker.length,
      );
      expect(nextCase, greaterThanOrEqualTo(0));
      final routeBody = source.substring(start, nextCase);
      expect(routeBody, contains('OnboardingV2JourneyScreen'));
      expect(routeBody, isNot(contains('const AppShell()')));
    }

    final fallbackStart = source.indexOf('\n            default:');
    final routerEnd = source.indexOf('\n        },', fallbackStart);
    expect(fallbackStart, greaterThanOrEqualTo(0));
    expect(routerEnd, greaterThan(fallbackStart));
    final fallbackBody = source.substring(fallbackStart, routerEnd);
    expect(fallbackBody, contains('OnboardingV2JourneyScreen'));
    expect(fallbackBody, isNot(contains('const AppShell()')));
  });
}

Future<void> _launch(
  WidgetTester tester,
  Map<String, Object> preferences,
) async {
  SharedPreferences.setMockInitialValues(preferences);
  await Storage.init();

  final coordinator = FirstRunCoordinator(
    repository: SharedPreferencesOnboardingJourneyRepository(),
    legacyStateReader: const StorageLegacyOnboardingStateReader(),
    // Widget tests run in a fresh fake-async zone. Do not retain the app-scoped
    // serialization tail from an earlier test zone.
    commitGateway: StorageOnboardingCommitGateway(
      courseProgress: CourseProgressService.app(),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: SplashScreen(
        firstRunCoordinator: coordinator,
        displayDuration: Duration.zero,
      ),
    ),
  );

  final expectedDestination = preferences['kl_consent_accepted'] == true
      ? find.byType(OnboardingV2JourneyScreen)
      : find.byType(ConsentScreen);
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (expectedDestination.evaluate().isNotEmpty) {
      break;
    }
  }

  expect(
    expectedDestination,
    findsOneWidget,
    reason:
        'The first-run destination must appear within 2 seconds after the '
        'zero-duration test splash.',
  );
}

class _CountingRepository implements OnboardingJourneyRepository {
  _CountingRepository(this.delegate);

  final OnboardingJourneyRepository delegate;
  int loadCalls = 0;

  @override
  Future<void> clear() => delegate.clear();

  @override
  Future<OnboardingJourneyState?> load() {
    loadCalls++;
    return delegate.load();
  }

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) => delegate.save(state, assertCurrentWrite: assertCurrentWrite);
}
