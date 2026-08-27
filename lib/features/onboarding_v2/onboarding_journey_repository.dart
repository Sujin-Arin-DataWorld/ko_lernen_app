import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/local_data_lifetime.dart';
import 'onboarding_journey_state.dart';

abstract interface class OnboardingJourneyRepository {
  Future<OnboardingJourneyState?> load();

  /// Persists one complete journey snapshot.
  ///
  /// [assertCurrentWrite] is evaluated at the last local-write boundary. It
  /// lets callers admitted in an earlier local-data lifetime fail closed
  /// instead of recreating a journal after an explicit reset.
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  });

  Future<void> clear();
}

/// Stores the V2 journey as one atomic JSON value, independent from legacy
/// onboarding, session-count, intro-preview, and screen-coach keys.
class SharedPreferencesOnboardingJourneyRepository
    implements OnboardingJourneyRepository {
  SharedPreferencesOnboardingJourneyRepository({
    Future<SharedPreferences> Function()? preferencesLoader,
    this.beforeRewriteForTesting,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       assert(
         beforeRewriteForTesting == null || preferencesLoader != null,
         'The rewrite barrier is a test seam and requires an injected loader.',
       );

  static const String preferenceKey = 'kl_onboarding_journey_v2';
  static const String quarantinePreferenceKey =
      'kl_onboarding_journey_v2_quarantine';

  final Future<SharedPreferences> Function() _preferencesLoader;

  /// Test-only pause point between decoding and rewriting durable bytes.
  final Future<void> Function()? beforeRewriteForTesting;

  @override
  Future<OnboardingJourneyState?> load() async {
    final localLifetime = LocalDataLifetime.capture();
    final preferences = await _preferencesLoader();
    localLifetime.assertCurrent();
    final raw = preferences.getString(preferenceKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException(
          'Onboarding journey must be a JSON object.',
        );
      }
      final state = OnboardingJourneyState.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      final needsMigration =
          decoded['schemaVersion'] !=
              OnboardingJourneyState.currentSchemaVersion ||
          decoded['rolloutMode'] != state.rolloutMode.name;
      if (needsMigration) {
        await beforeRewriteForTesting?.call();
        localLifetime.assertCurrent();
        final migrated = await preferences.setString(
          preferenceKey,
          jsonEncode(state.toJson()),
        );
        localLifetime.assertCurrent();
        if (!migrated) {
          throw StateError('Could not migrate onboarding journey.');
        }
      }
      return state;
    } on FormatException {
      await beforeRewriteForTesting?.call();
      await _quarantine(
        preferences,
        raw,
        assertCurrentWrite: localLifetime.assertCurrent,
      );
      return null;
    }
  }

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    final preferences = await _preferencesLoader();
    assertCurrentWrite?.call();
    final saved = await preferences.setString(
      preferenceKey,
      jsonEncode(state.toJson()),
    );
    assertCurrentWrite?.call();
    if (!saved) {
      throw StateError('Could not persist onboarding journey.');
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferencesLoader();
    final removed = await preferences.remove(preferenceKey);
    if (!removed && preferences.containsKey(preferenceKey)) {
      throw StateError('Could not remove onboarding journey.');
    }
  }

  Future<void> _quarantine(
    SharedPreferences preferences,
    String raw, {
    required void Function() assertCurrentWrite,
  }) async {
    assertCurrentWrite();
    final preserved = await preferences.setString(quarantinePreferenceKey, raw);
    assertCurrentWrite();
    if (!preserved || preferences.getString(quarantinePreferenceKey) != raw) {
      throw StateError('Could not quarantine invalid onboarding journey.');
    }

    assertCurrentWrite();
    final removed = await preferences.remove(preferenceKey);
    assertCurrentWrite();
    if (!removed && preferences.containsKey(preferenceKey)) {
      throw StateError('Could not remove invalid onboarding journey.');
    }
  }
}
