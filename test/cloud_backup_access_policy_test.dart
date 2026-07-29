import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  group('CloudBackupAccessPolicy', () {
    const cases =
        <
          ({
            String name,
            String? uid,
            List<String> providerIds,
            String? expectedUid,
          })
        >[
          (
            name: 'anonymous-only identity',
            uid: 'anonymous-uid',
            providerIds: <String>['firebase'],
            expectedUid: null,
          ),
          (
            name: 'identity without provider metadata',
            uid: 'anonymous-uid',
            providerIds: <String>[],
            expectedUid: null,
          ),
          (
            name: 'Google-linked identity',
            uid: 'google-uid',
            providerIds: <String>['firebase', 'google.com'],
            expectedUid: 'google-uid',
          ),
          (
            name: 'Apple-linked identity',
            uid: 'apple-uid',
            providerIds: <String>['firebase', 'apple.com'],
            expectedUid: 'apple-uid',
          ),
          (
            name: 'mixed durable providers',
            uid: 'mixed-uid',
            providerIds: <String>['password', 'google.com', 'apple.com'],
            expectedUid: 'mixed-uid',
          ),
          (
            name: 'missing UID despite Google provider',
            uid: null,
            providerIds: <String>['google.com'],
            expectedUid: null,
          ),
          (
            name: 'empty UID despite Apple provider',
            uid: '   ',
            providerIds: <String>['apple.com'],
            expectedUid: null,
          ),
        ];

    for (final testCase in cases) {
      test(testCase.name, () {
        expect(
          CloudBackupAccessPolicy.uidFor(
            uid: testCase.uid,
            providerIds: testCase.providerIds,
          ),
          testCase.expectedUid,
        );
      });
    }
  });
}
