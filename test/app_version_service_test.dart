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

  test('empty commit omits the SHA suffix entirely', () {
    expect(
      formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.8',
          buildNumber: '2224',
        ),
        commit: '',
      ),
      '2.0.8 (2224)',
    );
  });

  // §RELEASE-2(J13): a manual Closed build injects a 7-char short SHA
  // (`git rev-parse --short HEAD`, BETA_INSTALL_GUIDE.md /
  // closed-testing-checklist-v2.md) — `substring(0, 8)` would throw
  // RangeError on exactly this input if the clamp were missing.
  test('7-char short SHA (manual Closed build) is used as-is', () {
    expect(
      formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.8',
          buildNumber: '2224',
        ),
        commit: 'e35ea78',
      ),
      '2.0.8 (2224) · e35ea78',
    );
  });

  test('8-char SHA is used as-is (no truncation)', () {
    expect(
      formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.8',
          buildNumber: '2224',
        ),
        commit: 'e35ea785',
      ),
      '2.0.8 (2224) · e35ea785',
    );
  });

  test('40-char full SHA (CI GIT_COMMIT) is clamped to 8 characters', () {
    expect(
      formatAppVersion(
        PackageInfo(
          appName: 'Hangul Sori',
          packageName: 'x',
          version: '2.0.8',
          buildNumber: '2224',
        ),
        commit: 'e35ea785c4d3b2a1908f7e6d5c4b3a2918f7e6d5',
      ),
      '2.0.8 (2224) · e35ea785',
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
