import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/access_snapshot.dart';

const serverNow = 1788436800000;
const day = 86400000;

Map<String, Object?> payload() => {
  'schemaVersion': 2,
  'ownerUid': 'user-A',
  'environment': 'PRODUCTION',
  'revision': 'a' * 64,
  'source': 'universal',
  'contentAccess': 'all',
  'aiPolicyId': 'universal_v1',
  'bookDailyLimit': 20,
  'pronunciationDailyLimit': 50,
  'serverNow': serverNow,
  'nextResetAt': (serverNow ~/ day + 1) * day,
};

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/access_policy/v2.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('shared v2 wire fixture covers every server case', () {
    final expected = fixture['expectedSnapshots'] as Map<String, dynamic>;
    expect(expected.keys.toSet(), cases.map((entry) => entry['name']).toSet());
    expect(expected.length, cases.length);
  });

  for (final entry in cases) {
    test('shared universal snapshot parses exactly: ${entry['name']}', () {
      final expected = Map<String, dynamic>.from(
        (fixture['expectedSnapshots'] as Map)[entry['name']] as Map,
      );
      final snapshot = AccessSnapshot.fromJson(expected);
      expect(snapshot.toJson(), expected);
      expect(snapshot.ownerUid, entry['uid']);
      expect(snapshot.environment, entry['environment']);
      expect(snapshot.serverNow, entry['now']);
      expect(snapshot.source, 'universal');
      expect(snapshot.contentAccess, 'all');
      expect(snapshot.aiPolicyId, 'universal_v1');
      expect(snapshot.bookDailyLimit, 20);
      expect(snapshot.pronunciationDailyLimit, 50);
      expect(snapshot.revision, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(snapshot.nextResetAt, (snapshot.serverNow ~/ day + 1) * day);
    });
  }

  test('cache expires exactly at the next server UTC reset', () {
    final snapshot = AccessSnapshot.fromJson(payload());
    final lifetime = snapshot.nextResetAt - snapshot.serverNow;
    expect(snapshot.canUseCached(Duration(milliseconds: lifetime - 1)), isTrue);
    expect(snapshot.canUseCached(Duration(milliseconds: lifetime)), isFalse);
    expect(snapshot.canUseCached(const Duration(milliseconds: -1)), isFalse);
  });

  test('rejects v1 and non-universal policy combinations', () {
    for (final patch in <Map<String, Object?>>[
      {'schemaVersion': 1},
      {'ownerUid': ''},
      {'ownerUid': 'a/b'},
      {'environment': 'typo'},
      {'revision': ''},
      {'source': 'closed_tester_lifetime'},
      {'contentAccess': 'preview'},
      {'aiPolicyId': 'premium_v1'},
      {'bookDailyLimit': 999},
      {'pronunciationDailyLimit': 999},
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

  test(
    'serialization keeps v2 server fields and strips legacy authority data',
    () {
      final json = {
        ...payload(),
        'premium': true,
        'grant': {'status': 'active'},
        'accessUntil': serverNow + day,
        'offlineUntil': serverNow + day,
      };
      final snapshot = AccessSnapshot.fromJson(json);
      expect(snapshot.toJson(), payload());
    },
  );
}
