import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release paths cannot re-enable subscription billing', () async {
    final pubspec = await File('pubspec.yaml').readAsString();
    final iosBuild = await File('scripts/build_ios_ipa.sh').readAsString();
    final ci = await File('.github/workflows/ci.yml').readAsString();
    final closed = await File(
      '.github/workflows/play_closed.yml',
    ).readAsString();
    final accessSnapshotService = File(
      'lib/services/access_snapshot_service.dart',
    );
    final accessSnapshotSource = await accessSnapshotService.readAsString();
    final accessRuntime = await File(
      'functions/gye/access_runtime.js',
    ).readAsString();
    final gyeIndex = await File('functions/gye/index.js').readAsString();
    final gyePackage = await File('functions/gye/package.json').readAsString();
    final playwright = await File('tests/example.spec.ts').readAsString();
    final proguard = await File(
      'android/app/proguard-rules.pro',
    ).readAsString();

    expect(pubspec, isNot(contains('purchases_flutter:')));
    expect(
      File('assets/illustrations/reward/paywall_hero.webp').existsSync(),
      isFalse,
    );
    expect(File('lib/services/premium_service.dart').existsSync(), isFalse);
    expect(accessSnapshotService.existsSync(), isTrue);
    expect(accessSnapshotSource, isNot(contains('class PremiumService')));
    expect(accessSnapshotSource, contains("'getUniversalAccessSnapshot'"));
    expect(accessSnapshotSource, isNot(contains("'getAccessSnapshot'")));
    expect(gyeIndex, contains('exports.getAccessSnapshot ='));
    expect(gyeIndex, contains('exports.getUniversalAccessSnapshot ='));
    expect(accessRuntime, contains('Compatibility wire format'));
    expect(gyePackage, contains('functions:gye-firebase-functions'));
    for (final retiredGrantTool in [
      'functions/gye/manage_premium_grants.js',
      'functions/gye/premium_grants.js',
      'functions/gye/premium_grants.test.js',
    ]) {
      expect(File(retiredGrantTool).existsSync(), isFalse);
    }
    expect(gyePackage, isNot(contains('premium_grants.test.js')));
    expect(playwright, isNot(contains('api.revenuecat.com')));
    expect(proguard, isNot(contains('com.android.billingclient')));
    expect(iosBuild, isNot(contains('RC_IOS_KEY')));
    expect(iosBuild, isNot(contains('FREE_LAUNCH')));
    expect(ci, isNot(contains('BETA_UNLOCK_ALL')));
    expect(closed, isNot(contains('BETA_UNLOCK_ALL')));
    expect(closed, contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'));
    expect(closed, contains(r'--dart-define=GIT_COMMIT=${{ github.sha }}'));
    expect(closed, contains('tracks: alpha'));
  });
}
