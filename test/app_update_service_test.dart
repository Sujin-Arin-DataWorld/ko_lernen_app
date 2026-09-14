import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:ko_lernen_app/services/app_update_service.dart';

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
  test('available and in-progress Play states preserve install routes', () {
    for (final availability in [
      UpdateAvailability.updateAvailable,
      UpdateAvailability.developerTriggeredUpdateInProgress,
    ]) {
      final status = appUpdateStatusFrom(_info(availability, immediate: false));
      expect(status.availability, AppUpdateAvailability.updateAvailable);
      expect(status.availableVersionCode, 4530);
      expect(status.immediateAllowed, isFalse);
      expect(status.flexibleAllowed, isTrue);
      expect(status.canStartInApp, isTrue);
    }
  });

  test('up-to-date and unknown Play states remain distinct', () {
    expect(
      appUpdateStatusFrom(
        _info(UpdateAvailability.updateNotAvailable),
      ).availability,
      AppUpdateAvailability.upToDate,
    );
    expect(
      appUpdateStatusFrom(_info(UpdateAvailability.unknown)).availability,
      AppUpdateAvailability.unsupported,
    );
  });

  test('unsupported platform never calls the Play gateway', () async {
    final gateway = _FakeGateway();
    final checker = PlayStoreAppUpdateChecker(
      playSupported: false,
      gateway: gateway,
    );

    expect(await checker.check(), same(AppUpdateStatus.unsupported));
    expect(
      await checker.start(
        const AppUpdateStatus(
          availability: AppUpdateAvailability.updateAvailable,
          immediateAllowed: true,
        ),
      ),
      AppUpdateStartResult.unsupported,
    );
    expect(gateway.calls, isEmpty);
  });

  test('Play check errors fall back to unsupported', () async {
    final gateway = _FakeGateway(checkError: StateError('network'));
    final checker = PlayStoreAppUpdateChecker(
      playSupported: true,
      gateway: gateway,
    );

    expect(await checker.check(), same(AppUpdateStatus.unsupported));
    expect(gateway.calls, ['check']);
  });

  test('immediate user denial is reported as declined', () async {
    final gateway = _FakeGateway(
      immediateResult: AppUpdateResult.userDeniedUpdate,
    );
    final checker = PlayStoreAppUpdateChecker(
      playSupported: true,
      gateway: gateway,
    );

    expect(
      await checker.start(
        const AppUpdateStatus(
          availability: AppUpdateAvailability.updateAvailable,
          immediateAllowed: true,
        ),
      ),
      AppUpdateStartResult.declined,
    );
    expect(gateway.calls, ['immediate']);
  });

  test(
    'successful flexible update is completed before reporting started',
    () async {
      final gateway = _FakeGateway();
      final checker = PlayStoreAppUpdateChecker(
        playSupported: true,
        gateway: gateway,
      );

      expect(
        await checker.start(
          const AppUpdateStatus(
            availability: AppUpdateAvailability.updateAvailable,
            flexibleAllowed: true,
          ),
        ),
        AppUpdateStartResult.started,
      );
      expect(gateway.calls, ['flexible', 'complete']);
    },
  );

  test('Play start and completion failures are reported as failed', () async {
    for (final gateway in [
      _FakeGateway(flexibleResult: AppUpdateResult.inAppUpdateFailed),
      _FakeGateway(completeError: StateError('install failed')),
    ]) {
      final checker = PlayStoreAppUpdateChecker(
        playSupported: true,
        gateway: gateway,
      );
      expect(
        await checker.start(
          const AppUpdateStatus(
            availability: AppUpdateAvailability.updateAvailable,
            flexibleAllowed: true,
          ),
        ),
        AppUpdateStartResult.failed,
      );
    }
  });

  test(
    'non-update statuses cannot start even with stale route flags',
    () async {
      final gateway = _FakeGateway();
      final checker = PlayStoreAppUpdateChecker(
        playSupported: true,
        gateway: gateway,
      );

      expect(
        await checker.start(
          const AppUpdateStatus(
            availability: AppUpdateAvailability.upToDate,
            immediateAllowed: true,
          ),
        ),
        AppUpdateStartResult.unsupported,
      );
      expect(gateway.calls, isEmpty);
    },
  );
}

class _FakeGateway implements AppUpdateGateway {
  _FakeGateway({
    this.checkError,
    this.immediateResult = AppUpdateResult.success,
    this.flexibleResult = AppUpdateResult.success,
    this.completeError,
  });

  final Object? checkError;
  final AppUpdateResult immediateResult;
  final AppUpdateResult flexibleResult;
  final Object? completeError;
  final calls = <String>[];

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    calls.add('check');
    if (checkError case final error?) throw error;
    return _info(UpdateAvailability.updateAvailable);
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    calls.add('complete');
    if (completeError case final error?) throw error;
  }

  @override
  Future<AppUpdateResult> performImmediateUpdate() async {
    calls.add('immediate');
    return immediateResult;
  }

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async {
    calls.add('flexible');
    return flexibleResult;
  }
}
