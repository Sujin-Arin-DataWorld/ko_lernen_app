import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:ko_lernen_app/services/app_update_service.dart';

/// 설정 → "업데이트 확인" 의 판정 규칙.
///
/// Play 플러그인은 플랫폼 채널이라 테스트에서 부를 수 없다. 그래서 매핑
/// (`appUpdateStatusFrom`)과 "Play 에 물어볼 수 없는 자리" 판단을 분리해 두고,
/// 여기서는 그 둘만 검증한다.
AppUpdateInfo _info(
  UpdateAvailability availability, {
  bool immediate = true,
  bool flexible = true,
  int? versionCode = 4530,
}) {
  return AppUpdateInfo(
    updateAvailability: availability,
    immediateUpdateAllowed: immediate,
    immediateAllowedPreconditions: null,
    flexibleUpdateAllowed: flexible,
    flexibleAllowedPreconditions: null,
    availableVersionCode: versionCode,
    installStatus: InstallStatus.unknown,
    packageName: 'com.sujinarin.ko_lernen_app',
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );
}

void main() {
  test('새 빌드가 있으면 versionCode 와 허용된 설치 경로를 그대로 옮긴다', () {
    final status = appUpdateStatusFrom(
      _info(UpdateAvailability.updateAvailable, flexible: false),
    );

    expect(status.availability, AppUpdateAvailability.updateAvailable);
    expect(status.availableVersionCode, 4530);
    expect(status.immediateAllowed, isTrue);
    expect(status.flexibleAllowed, isFalse);
    expect(status.canStartInApp, isTrue);
  });

  test('이미 시작된 업데이트도 받을 게 있는 것으로 본다', () {
    final status = appUpdateStatusFrom(
      _info(UpdateAvailability.developerTriggeredUpdateInProgress),
    );

    expect(status.availability, AppUpdateAvailability.updateAvailable);
  });

  test('Play 가 없다고 하면 최신으로 본다', () {
    final status = appUpdateStatusFrom(
      _info(UpdateAvailability.updateNotAvailable),
    );

    expect(status.availability, AppUpdateAvailability.upToDate);
    expect(status.canStartInApp, isFalse);
  });

  test('Play 가 판단하지 못하면 최신이라 단정하지 않는다', () {
    // unknown 을 upToDate 로 접으면 낡은 빌드를 쥔 사용자에게 "최신입니다"라고
    // 거짓말을 하게 된다 — 그게 2026-09-06 사고의 사용자 쪽 증상이었다.
    final status = appUpdateStatusFrom(_info(UpdateAvailability.unknown));

    expect(status.availability, AppUpdateAvailability.unsupported);
  });

  test('Play 를 쓸 수 없는 자리에서는 플러그인을 부르지 않는다', () async {
    const checker = PlayStoreAppUpdateChecker(playSupported: false);

    final status = await checker.check();
    expect(status.availability, AppUpdateAvailability.unsupported);

    final started = await checker.start(
      const AppUpdateStatus(
        availability: AppUpdateAvailability.updateAvailable,
        immediateAllowed: true,
      ),
    );
    expect(started, AppUpdateStartResult.unsupported);
  });

  test('앱 안에서 받을 수 없는 업데이트는 시작하지 않는다', () async {
    const checker = PlayStoreAppUpdateChecker(playSupported: true);

    final started = await checker.start(
      const AppUpdateStatus(
        availability: AppUpdateAvailability.updateAvailable,
      ),
    );

    expect(started, AppUpdateStartResult.unsupported);
  });
}
