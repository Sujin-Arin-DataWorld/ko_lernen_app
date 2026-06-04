import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/age_gate_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// AgeGateService — GDPR-K (16세) 계 게이트 로직.
/// DateTime.now()를 mock하지 않고 현재 연도 기준 상대 계산으로 검증.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final int nowYear = DateTime.now().year;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Storage.init()이 이미 초기화 시 no-op일 수 있어(캐시된 _prefs) 명시적 리셋.
    await Storage.setBirthYear(0);
  });

  test('생년 미상 → 게이트 통과(차단 아님) + needsBirthYear', () {
    expect(AgeGateService.needsBirthYear, isTrue);
    expect(AgeGateService.ageEstimate, isNull);
    expect(AgeGateService.isUnderMinAge, isFalse);
    expect(AgeGateService.isGyeAllowed, isTrue);
  });

  test('10세 → 차단', () async {
    await Storage.setBirthYear(nowYear - 10);
    expect(AgeGateService.ageEstimate, 10);
    expect(AgeGateService.isUnderMinAge, isTrue);
    expect(AgeGateService.isGyeAllowed, isFalse);
    expect(AgeGateService.needsBirthYear, isFalse);
  });

  test('정확히 16세 → 허용(경계)', () async {
    await Storage.setBirthYear(nowYear - 16);
    expect(AgeGateService.ageEstimate, 16);
    expect(AgeGateService.isUnderMinAge, isFalse);
    expect(AgeGateService.isGyeAllowed, isTrue);
  });

  test('15세 → 차단(경계 바로 아래)', () async {
    await Storage.setBirthYear(nowYear - 15);
    expect(AgeGateService.isUnderMinAge, isTrue);
  });

  test('20세 → 허용', () async {
    await Storage.setBirthYear(nowYear - 20);
    expect(AgeGateService.isUnderMinAge, isFalse);
    expect(AgeGateService.ageEstimate, 20);
  });

  test('비현실 연도 → 미상 취급(차단 안 함)', () async {
    await Storage.setBirthYear(1700);
    expect(AgeGateService.ageEstimate, isNull);
    expect(AgeGateService.isUnderMinAge, isFalse);
    expect(AgeGateService.isPlausibleYear(1700), isFalse);
  });

  test('saveBirthYear: 미래 거부 / 유효 저장', () async {
    expect(await AgeGateService.saveBirthYear(nowYear + 5), isFalse);
    expect(Storage.birthYear, 0);
    expect(await AgeGateService.saveBirthYear(nowYear - 25), isTrue);
    expect(Storage.birthYear, nowYear - 25);
  });
}
