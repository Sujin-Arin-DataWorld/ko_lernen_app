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

    expect(pubspec, isNot(contains('purchases_flutter:')));
    expect(iosBuild, isNot(contains('RC_IOS_KEY')));
    expect(iosBuild, isNot(contains('FREE_LAUNCH')));
    expect(ci, isNot(contains('BETA_UNLOCK_ALL')));
    expect(closed, isNot(contains('BETA_UNLOCK_ALL')));
    expect(closed, contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'));
    expect(closed, contains(r'--dart-define=GIT_COMMIT=${{ github.sha }}'));
    expect(closed, contains('tracks: alpha'));
  });
}
