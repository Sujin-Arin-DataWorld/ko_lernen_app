import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DSGVO Art. 8: a self-attested under-16 user cannot give valid consent for
/// behavioural analytics/crash collection, so the facade must refuse to enable
/// it regardless of what the UI sends — and persist it as off (provable).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('under-16 cannot enable analytics or crash collection', () async {
    await Storage.setBirthYear(DateTime.now().year - 12); // 12 years old

    await PrivacyConsentService.setAnalytics(true);
    await PrivacyConsentService.setCrash(true);

    expect(Storage.analyticsConsent, isFalse);
    expect(Storage.crashConsent, isFalse);
  });

  test('16+ can enable analytics collection', () async {
    await Storage.setBirthYear(DateTime.now().year - 20); // 20 years old

    await PrivacyConsentService.setAnalytics(true);

    expect(Storage.analyticsConsent, isTrue);
  });
}
