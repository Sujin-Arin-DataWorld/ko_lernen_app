import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'first_run_coordinator.dart';

/// Remote release control for fresh-install onboarding only.
///
/// `minimal` is the kill-switch path: consent -> setup -> companion -> home.
/// It can never restore the removed forced quiz. Existing completed learners
/// are already resolved to AppShell by [FirstRunCoordinator].
abstract final class OnboardingRolloutService {
  static const remoteKey = 'onboarding_v2_mode';
  // The five-page story is the product default, including offline startup.
  // Only an explicit remote kill value may select the minimal-safe path;
  // delayed Firebase startup or a malformed value must never silently make a
  // mandatory first-run explanation disappear.
  static const defaultRaw = 'full';

  static OnboardingRolloutMode _mode = OnboardingRolloutMode.full;
  static Completer<void>? _initialFetch;

  static OnboardingRolloutMode get currentMode => _mode;

  static Future<void> fetchAndApply() {
    final existing = _initialFetch;
    if (existing != null) {
      return existing.future;
    }
    final completer = Completer<void>();
    _initialFetch = completer;
    unawaited(_fetch(completer));
    return completer.future;
  }

  static Future<void> _fetch(Completer<void> completer) async {
    try {
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(milliseconds: 1500),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remote.setDefaults(const {remoteKey: defaultRaw});
      await remote.fetchAndActivate();
      _mode = parseMode(remote.getString(remoteKey));
    } catch (error) {
      debugPrint(
        'OnboardingRolloutService: fetch failed, using $defaultRaw — $error',
      );
      _mode = parseMode(defaultRaw);
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Splash calls this after its normal display duration. If cloud startup was
  /// not started (widget tests/offline composition), the local default is
  /// immediately available. A slow network may add at most [timeout].
  static Future<void> waitForInitialMode({
    Duration timeout = const Duration(milliseconds: 750),
  }) async {
    final fetch = _initialFetch;
    if (fetch == null || fetch.isCompleted) {
      return;
    }
    await fetch.future.timeout(timeout, onTimeout: () {});
  }

  @visibleForTesting
  static OnboardingRolloutMode parseMode(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'full' || 'enabled' || 'on' => OnboardingRolloutMode.full,
      'minimal' ||
      'off' ||
      'disabled' ||
      'kill' => OnboardingRolloutMode.minimalSafe,
      // Unknown values are not authorization to bypass the mandatory story.
      _ => OnboardingRolloutMode.full,
    };
  }
}
