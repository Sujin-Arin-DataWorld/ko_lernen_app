import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/age_gate_service.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'support/privacy_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PrivacyPreferencesPlatform native;
  late PrivacyFakeAnalytics analytics;
  late PrivacyFakeCrash crash;

  Future<void> start({required bool consent}) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = PrivacyPreferencesPlatform();
    native.values.addAll({
      'kl_birth_year': 0,
      'kl_analytics_consent': consent,
      'kl_crash_consent': consent,
    });
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    analytics = PrivacyFakeAnalytics();
    crash = PrivacyFakeCrash();
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    await PrivacyConsentService.applyStored();
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    expect(PrivacyConsentService.canCollectCrash, isFalse);
    expect(analytics.applied, isFalse);
    expect(crash.applied, isFalse);
  }

  tearDown(Storage.resetForTesting);

  test(
    'confirmed adult age reapplies existing local consent after startup',
    () async {
      await start(consent: true);
      final applied = Completer<void>();
      void changed() {
        if (PrivacyConsentService.canCollectAnalytics &&
            PrivacyConsentService.canCollectCrash &&
            !applied.isCompleted) {
          applied.complete();
        }
      }

      PrivacyConsentService.changes.addListener(changed);
      try {
        expect(
          await AgeGateService.saveBirthYear(DateTime.now().year - 25),
          isTrue,
        );
        // The age listener must apply the saved choice without a second call
        // from the UI to applyStored().
        await applied.future.timeout(const Duration(seconds: 1));
      } finally {
        PrivacyConsentService.changes.removeListener(changed);
      }
      expect(Storage.analyticsConsent, isTrue);
      expect(Storage.crashConsent, isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      expect(PrivacyConsentService.canCollectCrash, isTrue);
      expect(analytics.applied, isTrue);
      expect(crash.applied, isTrue);
    },
  );

  test('confirmed adult age does not manufacture optional consent', () async {
    await start(consent: false);
    expect(
      await AgeGateService.saveBirthYear(DateTime.now().year - 25),
      isTrue,
    );
    await PrivacyConsentService.applyStored();
    expect(Storage.analyticsConsent, isFalse);
    expect(Storage.crashConsent, isFalse);
    expect(analytics.applied, isFalse);
    expect(crash.applied, isFalse);
    expect(analytics.calls, isNot(contains(true)));
    expect(crash.calls, isNot(contains('collection:true')));
  });

  test('age confirmation waits for an outstanding startup disable', () async {
    await start(consent: true);
    final disable = Completer<void>();
    analytics.disable = disable;
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    final startup = PrivacyConsentService.applyStored();
    try {
      expect(
        await AgeGateService.saveBirthYear(DateTime.now().year - 25),
        isTrue,
      );
      final reapplied = PrivacyConsentService.applyStored();
      expect(analytics.applied, isFalse);
      disable.complete();
      await Future.wait([startup, reapplied]);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      expect(analytics.applied, isTrue);
    } finally {
      if (!disable.isCompleted) {
        disable.complete();
      }
      await startup;
    }
  });

  test('explicit withdrawal persists during a startup-only disable', () async {
    await start(consent: true);
    final disable = Completer<void>();
    analytics.disable = disable;
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    final startup = PrivacyConsentService.applyStored();
    final withdrawal = PrivacyConsentService.setAnalytics(false);
    try {
      expect(
        await AgeGateService.saveBirthYear(DateTime.now().year - 25),
        isTrue,
      );
      disable.complete();
      await Future.wait([startup, withdrawal]);
      await PrivacyConsentService.applyStored();
      expect(native.values['kl_analytics_consent'], isFalse);
      expect(Storage.analyticsConsent, isFalse);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      expect(analytics.calls, isNot(contains(true)));
    } finally {
      if (!disable.isCompleted) {
        disable.complete();
      }
      await Future.wait([startup, withdrawal]);
    }
  });

  test('ineligible age never reapplies a stored opt-in', () async {
    await start(consent: true);
    expect(
      await AgeGateService.saveBirthYear(DateTime.now().year - 12),
      isTrue,
    );
    await PrivacyConsentService.applyStored();
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    expect(PrivacyConsentService.canCollectCrash, isFalse);
    expect(analytics.calls, isNot(contains(true)));
    expect(crash.calls, isNot(contains('collection:true')));
  });
}
