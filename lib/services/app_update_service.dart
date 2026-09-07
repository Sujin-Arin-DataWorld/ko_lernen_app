import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// 설정 → "업데이트 확인"(`settingsUpdateTitle`)의 뒷단.
///
/// **왜 Play 에 직접 묻나.** 2026-09-06~09-07 에 기기에 깔린 빌드가 main 보다
/// 낡았는데(내부 테스트 트랙이 멈춰 있었다) 앱 안에서는 알 방법이 없었다.
/// "최신 버전 번호"를 Remote Config 나 문서에 수기로 적어 두면 그 값이 또 낡는다
/// — 트랙별 최신 빌드를 아는 정본은 Play 뿐이므로 Play 에 직접 묻는다.
///
/// Play 가 답할 수 없는 자리(웹·iOS·디버그·사이드로드 설치)에서는 확인 자체가
/// 불가능하다. 그 경우 [AppUpdateAvailability.unsupported] 로 내려 UI 가 스토어
/// 페이지로 안내하게 한다 — 틀린 "최신입니다"를 말하지 않는다.
enum AppUpdateAvailability {
  /// Play 가 이 기기의 트랙에서 더 새 빌드를 갖고 있지 않다.
  upToDate,

  /// 더 새 빌드가 있다(또는 이미 시작된 업데이트가 진행 중이다).
  updateAvailable,

  /// 여기서는 Play 에 물어볼 수 없다 — 스토어로 안내한다.
  unsupported,
}

/// 업데이트 시작 결과.
enum AppUpdateStartResult {
  /// Play 가 다운로드·설치를 넘겨받았다(즉시 업데이트는 앱이 재시작된다).
  started,

  /// 사용자가 Play 의 확인 화면에서 취소했다.
  declined,

  /// Play 흐름이 실패했다 — 스토어로 안내한다.
  failed,

  /// 인앱 업데이트를 쓸 수 없는 자리다 — 스토어로 안내한다.
  unsupported,
}

@immutable
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.availability,
    this.availableVersionCode,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
  });

  static const AppUpdateStatus upToDate = AppUpdateStatus(
    availability: AppUpdateAvailability.upToDate,
  );
  static const AppUpdateStatus unsupported = AppUpdateStatus(
    availability: AppUpdateAvailability.unsupported,
  );

  final AppUpdateAvailability availability;

  /// Play 가 제공하는 새 빌드의 versionCode. 업데이트가 없으면 의미 없는 값이라
  /// [AppUpdateAvailability.updateAvailable] 일 때만 읽는다.
  final int? availableVersionCode;

  final bool immediateAllowed;
  final bool flexibleAllowed;

  /// 앱 안에서 바로 받을 수 있는가. 둘 다 막혀 있으면 스토어로 보낸다.
  bool get canStartInApp => immediateAllowed || flexibleAllowed;
}

/// 화면이 의존하는 계약. 위젯 테스트는 이걸 가짜로 갈아 끼운다.
abstract interface class AppUpdateChecker {
  Future<AppUpdateStatus> check();

  Future<AppUpdateStartResult> start(AppUpdateStatus status);
}

/// Play 응답 → [AppUpdateStatus] 매핑. 플러그인 호출과 분리해 둬야 단위
/// 테스트가 플랫폼 채널 없이 이 규칙을 검증할 수 있다.
@visibleForTesting
AppUpdateStatus appUpdateStatusFrom(AppUpdateInfo info) {
  return switch (info.updateAvailability) {
    // 이미 시작된 업데이트도 "받을 게 있다"로 본다 — 다시 누르면 이어서 끝난다.
    UpdateAvailability.updateAvailable ||
    UpdateAvailability.developerTriggeredUpdateInProgress => AppUpdateStatus(
      availability: AppUpdateAvailability.updateAvailable,
      availableVersionCode: info.availableVersionCode,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
    ),
    UpdateAvailability.updateNotAvailable => AppUpdateStatus.upToDate,
    // Play 가 판단하지 못했다. "최신"이라고 단정하지 않는다.
    UpdateAvailability.unknown => AppUpdateStatus.unsupported,
  };
}

class PlayStoreAppUpdateChecker implements AppUpdateChecker {
  const PlayStoreAppUpdateChecker({bool? playSupported})
    : _playSupportedOverride = playSupported;

  /// 테스트 전용 주입. 프로덕션에서는 null 이라 실제 플랫폼을 본다.
  final bool? _playSupportedOverride;

  bool get _playSupported =>
      _playSupportedOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<AppUpdateStatus> check() async {
    if (!_playSupported) {
      return AppUpdateStatus.unsupported;
    }
    try {
      return appUpdateStatusFrom(await InAppUpdate.checkForUpdate());
    } catch (_) {
      // Play 로 설치되지 않은 빌드·Play 서비스 없음·네트워크 실패. 확인만 못
      // 할 뿐 앱은 계속 쓸 수 있어야 하므로 삼키고 스토어로 안내한다.
      return AppUpdateStatus.unsupported;
    }
  }

  @override
  Future<AppUpdateStartResult> start(AppUpdateStatus status) async {
    if (!_playSupported || !status.canStartInApp) {
      return AppUpdateStartResult.unsupported;
    }
    try {
      final result = status.immediateAllowed
          ? await InAppUpdate.performImmediateUpdate()
          : await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success && !status.immediateAllowed) {
        // flexible 은 다운로드까지만 한다 — 설치는 여기서 마무리한다.
        await InAppUpdate.completeFlexibleUpdate();
      }
      return switch (result) {
        AppUpdateResult.success => AppUpdateStartResult.started,
        AppUpdateResult.userDeniedUpdate => AppUpdateStartResult.declined,
        AppUpdateResult.inAppUpdateFailed => AppUpdateStartResult.failed,
      };
    } catch (_) {
      return AppUpdateStartResult.failed;
    }
  }
}
