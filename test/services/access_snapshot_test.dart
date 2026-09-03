import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/access_snapshot.dart';

const serverNow = 1788436800000;
const day = 86400000;

Map<String, Object?> payload({String source = 'subscription'}) => {
  'schemaVersion': 1,
  'ownerUid': 'user-A',
  'environment': 'PRODUCTION',
  'revision': 'a' * 64,
  'source': source,
  'contentAccess': 'all',
  'aiPolicyId': 'premium_v1',
  'bookDailyLimit': 20,
  'pronunciationDailyLimit': 50,
  'serverNow': serverNow,
  'accessUntil': serverNow + 5 * day,
  'offlineUntil': serverNow + 3 * day,
  'nextResetAt': serverNow + day ~/ 2,
};

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/access_policy/v1.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('shared wire snapshot fixture covers all server cases', () {
    final expected = fixture['expectedSnapshots'] as Map<String, dynamic>;
    expect(expected.keys.toSet(), cases.map((entry) => entry['name']).toSet());
    expect(expected.length, cases.length);
  });

  for (final entry in cases) {
    test(
      'shared server snapshot parses and enforces bounds: ${entry['name']}',
      () {
        final expected = Map<String, dynamic>.from(
          (fixture['expectedSnapshots'] as Map)[entry['name']] as Map,
        );
        final snapshot = AccessSnapshot.fromJson(expected);
        // These are server-generated snapshots, not a Dart grant resolver.
        expect(snapshot.toJson(), expected);
        expect(snapshot.ownerUid, fixture['uid']);
        expect(snapshot.environment, entry['environment'] ?? 'PRODUCTION');
        expect(snapshot.serverNow, fixture['now']);
        expect(snapshot.source, entry['wantSource']);
        expect(snapshot.contentAccess, entry['wantContent']);
        expect(snapshot.bookDailyLimit, entry['wantBook']);
        expect(snapshot.pronunciationDailyLimit, entry['wantPronunciation']);
        expect(snapshot.hasAllContent, entry['wantContent'] == 'all');
        expect(snapshot.hasPremium, entry['wantBook'] == 20);
        expect(snapshot.revision, matches(RegExp(r'^[a-f0-9]{64}$')));
        expect(snapshot.nextResetAt, (snapshot.serverNow ~/ day + 1) * day);
        final lease = snapshot.offlineUntil - snapshot.serverNow;
        expect(
          snapshot.canUseOffline(const Duration(milliseconds: -1)),
          isFalse,
        );
        expect(snapshot.canUseOffline(Duration(milliseconds: lease)), isFalse);
        if (snapshot.hasPremium) {
          expect(snapshot.aiPolicyId, 'premium_v1');
          expect(
            snapshot.canUseOffline(Duration(milliseconds: lease - 1)),
            isTrue,
          );
          if (snapshot.source == 'subscription') {
            expect(lease, lessThanOrEqualTo(3 * day));
            expect(
              snapshot.offlineUntil,
              lessThanOrEqualTo(snapshot.accessUntil!),
            );
          } else {
            expect(lease, lessThanOrEqualTo(30 * day));
            expect(snapshot.accessUntil, isNull);
          }
        } else {
          expect(snapshot.aiPolicyId, 'free_v1');
          expect(lease, 0);
          expect(snapshot.accessUntil, isNull);
        }
      },
    );
  }

  test('snapshot separates free content from premium AI authority', () {
    final free = AccessSnapshot.fromJson({
      ...payload(source: 'free_launch'),
      'aiPolicyId': 'free_v1',
      'bookDailyLimit': 3,
      'pronunciationDailyLimit': 5,
      'accessUntil': null,
      'offlineUntil': serverNow,
    });
    expect(free.hasAllContent, isTrue);
    expect(free.hasPremium, isFalse);
    expect(free.bookDailyLimit, 3);
    expect(free.pronunciationDailyLimit, 5);
  });

  test('subscription cache expires at exactly its verified offline bound', () {
    final snapshot = AccessSnapshot.fromJson(payload());
    expect(
      snapshot.canUseOffline(
        const Duration(days: 3) - const Duration(milliseconds: 1),
      ),
      isTrue,
    );
    expect(snapshot.canUseOffline(const Duration(days: 3)), isFalse);
    expect(snapshot.canUseOffline(const Duration(milliseconds: -1)), isFalse);
  });

  test(
    'lifetime grant is permanent but cached verification lasts at most30days',
    () {
      final tester = AccessSnapshot.fromJson({
        ...payload(source: 'closed_tester_lifetime'),
        'accessUntil': null,
        'offlineUntil': serverNow + 30 * day,
      });
      expect(tester.hasPremium, isTrue);
      expect(tester.canUseOffline(const Duration(days: 29)), isTrue);
      expect(tester.canUseOffline(const Duration(days: 30)), isFalse);
    },
  );

  test('rejects unknown schema and invalid authority combinations', () {
    for (final patch in <Map<String, Object?>>[
      {'schemaVersion': 2},
      {'ownerUid': ''},
      {'ownerUid': 'a/b'},
      {'environment': 'typo'},
      {'revision': ''},
      {'source': 'beta_build'},
      {'source': 'free', 'aiPolicyId': 'premium_v1'},
      {'bookDailyLimit': 999},
      {'pronunciationDailyLimit': 999},
      {'offlineUntil': serverNow + 4 * day},
      {'accessUntil': serverNow - 1},
      {'serverNow': 'yesterday'},
      {'nextResetAt': serverNow},
    ]) {
      expect(
        () => AccessSnapshot.fromJson({...payload(), ...patch}),
        throwsFormatException,
        reason: '$patch',
      );
    }
  });

  test('snapshot serialization preserves server-owned fields only', () {
    final json = {...payload(), 'approvalRef': 'must-not-be-cached'};
    final snapshot = AccessSnapshot.fromJson(json);
    expect(snapshot.toJson(), payload());
  });
}
