import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdateAvailability { upToDate, updateAvailable, unsupported }

enum AppUpdateStartResult { started, declined, failed, unsupported }

@immutable
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.availability,
    this.availableVersionCode,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
  });

  static const upToDate = AppUpdateStatus(
    availability: AppUpdateAvailability.upToDate,
  );
  static const unsupported = AppUpdateStatus(
    availability: AppUpdateAvailability.unsupported,
  );

  final AppUpdateAvailability availability;
  final int? availableVersionCode;
  final bool immediateAllowed;
  final bool flexibleAllowed;

  bool get canStartInApp => immediateAllowed || flexibleAllowed;
}

abstract interface class AppUpdateChecker {
  Future<AppUpdateStatus> check();

  Future<AppUpdateStartResult> start(AppUpdateStatus status);
}

/// Narrow wrapper around the static plugin API so every Play result can be
/// exercised without a platform channel in unit tests.
abstract interface class AppUpdateGateway {
  Future<AppUpdateInfo> checkForUpdate();

  Future<AppUpdateResult> performImmediateUpdate();

  Future<AppUpdateResult> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();
}

class _PluginAppUpdateGateway implements AppUpdateGateway {
  const _PluginAppUpdateGateway();

  @override
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  @override
  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();

  @override
  Future<AppUpdateResult> performImmediateUpdate() =>
      InAppUpdate.performImmediateUpdate();

  @override
  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();
}

@visibleForTesting
AppUpdateStatus appUpdateStatusFrom(AppUpdateInfo info) {
  return switch (info.updateAvailability) {
    UpdateAvailability.updateAvailable ||
    UpdateAvailability.developerTriggeredUpdateInProgress => AppUpdateStatus(
      availability: AppUpdateAvailability.updateAvailable,
      availableVersionCode: info.availableVersionCode,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
    ),
    UpdateAvailability.updateNotAvailable => AppUpdateStatus.upToDate,
    UpdateAvailability.unknown => AppUpdateStatus.unsupported,
  };
}

class PlayStoreAppUpdateChecker implements AppUpdateChecker {
  const PlayStoreAppUpdateChecker({
    bool? playSupported,
    this.gateway = const _PluginAppUpdateGateway(),
  }) : _playSupportedOverride = playSupported,
       super();

  final bool? _playSupportedOverride;
  final AppUpdateGateway gateway;

  bool get _playSupported =>
      _playSupportedOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<AppUpdateStatus> check() async {
    if (!_playSupported) {
      return AppUpdateStatus.unsupported;
    }
    try {
      return appUpdateStatusFrom(await gateway.checkForUpdate());
    } catch (_) {
      return AppUpdateStatus.unsupported;
    }
  }

  @override
  Future<AppUpdateStartResult> start(AppUpdateStatus status) async {
    if (!_playSupported ||
        status.availability != AppUpdateAvailability.updateAvailable ||
        !status.canStartInApp) {
      return AppUpdateStartResult.unsupported;
    }
    try {
      final result = status.immediateAllowed
          ? await gateway.performImmediateUpdate()
          : await gateway.startFlexibleUpdate();
      if (result == AppUpdateResult.success && !status.immediateAllowed) {
        await gateway.completeFlexibleUpdate();
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
