import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ko_lernen_app/services/app_version_service.dart';

void main() {
  test('formats the native version and build number for display', () {
    expect(
      formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.5',
          buildNumber: '11',
        ),
      ),
      '2.0.5 (11)',
    );
  });

  test('rejects an unavailable native version', () {
    expect(
      () => formatAppVersion(
        PackageInfo(
          appName: '',
          packageName: '',
          version: '',
          buildNumber: '11',
        ),
      ),
      throwsStateError,
    );
  });

  test('rejects an unavailable native build number', () {
    expect(
      () => formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.5',
          buildNumber: '   ',
        ),
      ),
      throwsStateError,
    );
  });
}
