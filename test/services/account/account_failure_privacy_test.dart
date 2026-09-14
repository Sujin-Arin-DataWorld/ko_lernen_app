// ignore_for_file: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/account/account_failure_diagnostics.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import '../../support/privacy_preferences_platform.dart';

class _Core extends MockFirebaseApp {
  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    final apps = await super.initializeCore();
    apps.single.pluginConstants['plugins.flutter.io/firebase_crashlytics'] = {
      'isCrashlyticsCollectionEnabled': false,
    };
    return apps;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  late PrivacyPreferencesPlatform native;
  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_Core());
    await Firebase.initializeApp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_crashlytics'),
          (call) async {
            calls.add(call.method);
            return null;
          },
        );
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = PrivacyPreferencesPlatform();
    native.values['kl_birth_year'] = DateTime.now().year - 25;
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    PrivacyConsentService.configureForTesting(
      analytics: PrivacyFakeAnalytics(),
      crash: PrivacyFakeCrash(),
    );
    AccountFailureDiagnostics.resetSinkForTesting();
    calls.clear();
  });
  for (final state in [
    'absent',
    'failed-off',
    'unknown-age',
    'minor',
    'granted',
  ]) {
    test('review1 actual default account sink admission $state', () async {
      if (state != 'absent') {
        await PrivacyConsentService.setCrash(true);
      }
      if (state == 'failed-off') {
        native.rejectKey = 'kl_crash_consent';
        await PrivacyConsentService.setCrash(false).catchError((Object _) {});
      }
      if (state == 'unknown-age') {
        await Storage.setBirthYear(0);
      }
      if (state == 'minor') {
        await Storage.setBirthYear(DateTime.now().year - 10);
      }
      AccountFailureDiagnostics.log(
        'startup.failed',
        StateError('synthetic-private-payload'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        calls,
        state == 'granted'
            ? containsAll(['Crashlytics#log', 'Crashlytics#recordError'])
            : isEmpty,
      );
    });
  }
}
