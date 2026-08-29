import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/learning_data_export_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a2',
      'kl_placement_level_v1': 'a2',
      'kl_browse_level_v1': 'b1',
      'kl_course_unit_v1': 'a2_01_transport',
      'kl_daily_goal_minutes': 15,
      'kl_motivation': 'travel',
      'kl_preferred_mascot': 'magpie',
      'kl_interests': <String>['food', 'travel'],
      'kl_xp': 420,
      'kl_streak_days': 7,
      'kl_best_streak': 11,
      'kl_last_open_date': '2026-08-11',
      'kl_vok_correct': 31,
      'kl_vok_wrong': 4,
      'kl_vok_skipped': 2,
      'kl_vok_seen_ids': <String>['word_1', 'word_2'],
      'kl_vok_favorites': <String>['word_2'],
      'kl_gram_seen': <String>['-고 싶어요'],
      'kl_gram_hard': <String>['-(으)니까'],
      'kl_callig_dates': <String>['2026-08-10'],
      'kl_completed_scenarios': <String>['cafe_order'],
      'kl_scenario_stars': jsonEncode({'cafe_order': 3}),
      'kl_stamps_earned': <String>['lotus'],
      'kl_earned_badges': <String>['first_week'],
      'kl_owned_decor': <String>['moon_lamp'],
      'kl_pronunciation_pass_count_v1': 2,
      'kl_pronunciation_last_score_v1': 87.5,
      'kl_pronunciation_assessment_ids_v1': <String>['p-1', 'p-2'],
      'kl_quests_completed_v1': jsonEncode({
        'q_first': '2026-08-10T12:00:00.000Z',
      }),
      'kl_srs_v1': jsonEncode({
        'word_1': {'e': 2.6, 'i': 3, 'n': '2026-08-15', 'r': 2},
      }),
      'kl_study_log_v1_2026-08-10': <String>['word_1', 'word_2'],
      'kl_study_log_v1_2026-08-11': <String>['word_3'],
      'kl_gram_plan_v1': '{ "a2": {"day": 3} }',
      'kl_pack_progress_v1': jsonEncode({
        'travel_a2': {
          'level': 'A2',
          'status': 'inProgress',
          'wordsLearned': 8,
          'wordsTotal': 20,
          'bossAccuracy': 0.65,
          'attempts': 1,
          'clearedAt': null,
        },
      }),
      'kl_course_mastery_v2': jsonEncode({
        'version': 2,
        'placementLevel': 'a2',
        'currentCourseUnitId': 'a2_01_transport',
        'completedUnitIds': <String>['a1_01_greetings'],
        'bypassedPrerequisiteUnitIds': <String>[],
        'evidence': <Object>[],
        'scenarioCheckpoints': <Object>[],
      }),
      // These values prove the exporter is allowlisted, not a preferences dump.
      'kl_birth_year': 1990,
      Storage.accountDeletionCheckpointPreferenceKey:
          'account-secret-must-not-export',
      'kl_account_transition_journal_v1': 'auth-token-must-not-export',
      'account_deletion_terminal_status_receipt_v1':
          'secure-receipt-must-not-export',
      'firebase_refresh_token': 'refresh-token-must-not-export',
      'firebase_uid': 'uid-identity-must-not-export',
      'firebase_email': 'email-identity-must-not-export@example.test',
      'firebase_display_name': 'display-name-must-not-export',
      'firebase_photo_url': 'photo-url-must-not-export',
      'firebase_provider_id': 'provider-id-must-not-export',
      'firebase_fcm_token': 'fcm-token-must-not-export',
      'firebase_app_check_token': 'app-check-token-must-not-export',
      'device_installation_id': 'device-id-must-not-export',
      'kl_consent_accepted': true,
      'kl_analytics_consent': true,
      'kl_bookshelf_v1': r'C:\private\photo.jpg',
    });
    await Storage.init();
  });

  test('builds a deterministic allowlisted local-learning package', () async {
    final preferences = await SharedPreferences.getInstance();
    final before = _snapshot(preferences);

    final package = LearningDataExportService.buildPackage(
      exportedAt: DateTime.utc(2026, 8, 12, 9, 30, 5),
    );
    final decoded =
        jsonDecode(utf8.decode(package.bytes)) as Map<String, dynamic>;

    expect(package.fileName, 'hangul-sori-learning-data-20260812-093005Z.json');
    expect(package.mimeType, 'application/json');
    expect(decoded['schemaVersion'], 1);
    expect(decoded['exportedAt'], '2026-08-12T09:30:05.000Z');
    expect(decoded['learner'], {
      'level': 'a2',
      'coursePlacementLevel': 'a2',
      'browseLevel': 'b1',
      'dailyGoalMinutes': 15,
      'motivation': 'travel',
      'companion': 'magpie',
      'interests': ['food', 'travel'],
    });
    expect(decoded['progress']['xp'], 420);
    expect(decoded['progress']['vocabulary']['seenIds'], ['word_1', 'word_2']);
    expect(decoded['progress']['scenarios']['stars']['cafe_order'], 3);
    expect(decoded['course']['mastery']['completedUnitIds'], [
      'a1_01_greetings',
    ]);
    expect(decoded['review']['cards']['word_1']['reviewCount'], 2);
    expect(decoded['studyLog'], {
      '2026-08-10': ['word_1', 'word_2'],
      '2026-08-11': ['word_3'],
    });
    expect(decoded['grammarPlan'], {
      'a2': {'day': 3},
    });
    expect(decoded['packs']['travel_a2']['wordsLearned'], 8);
    expect(decoded['progress']['pronunciation'], {
      'passedAssessments': 2,
      'lastScore': 87.5,
      'assessmentIds': ['p-1', 'p-2'],
    });

    final encoded = utf8.decode(package.bytes);
    expect(encoded, isNot(contains('1990')));
    expect(encoded, isNot(contains('account-secret-must-not-export')));
    expect(encoded, isNot(contains('auth-token-must-not-export')));
    expect(encoded, isNot(contains('secure-receipt-must-not-export')));
    expect(encoded, isNot(contains('refresh-token-must-not-export')));
    for (final secret in const [
      'uid-identity-must-not-export',
      'email-identity-must-not-export@example.test',
      'display-name-must-not-export',
      'photo-url-must-not-export',
      'provider-id-must-not-export',
      'fcm-token-must-not-export',
      'app-check-token-must-not-export',
      'device-id-must-not-export',
    ]) {
      expect(encoded, isNot(contains(secret)));
    }
    expect(encoded, isNot(contains('private\\photo.jpg')));
    expect(encoded, isNot(contains('birthYear')));
    expect(encoded, isNot(contains('"consentAccepted"')));
    expect(encoded, isNot(contains('"analyticsConsent"')));
    expect(encoded, isNot(contains('"journal"')));
    final exportedKeys = _allKeys(decoded).map((key) => key.toLowerCase());
    for (final forbidden in const [
      'uid',
      'email',
      'token',
      'receipt',
      'journal',
      'deletion',
      'consent',
      'photo',
      'provider',
      'account',
      'device',
    ]) {
      expect(
        exportedKeys.where((key) => key.contains(forbidden)),
        isEmpty,
        reason: 'identity/security field fragment "$forbidden" is forbidden',
      );
    }

    await preferences.reload();
    expect(_snapshot(preferences), before);
  });

  test(
    'invalid raw progress is omitted without quarantine or writes',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('kl_srs_v1', '{not-json');
      await preferences.setString('kl_pack_progress_v1', '[]');
      await preferences.setString('kl_course_mastery_v2', '{broken');
      await preferences.setString('kl_gram_plan_v1', '[]');
      Storage.resetForTesting();
      await Storage.init();
      final before = _snapshot(preferences);

      final decoded = LearningDataExportService.buildPackage(
        exportedAt: DateTime.utc(2026, 8, 12),
      ).data;

      expect(decoded['review']['cards'], isEmpty);
      expect(decoded['packs'], isEmpty);
      expect(decoded['course']['mastery'], isNull);
      expect(decoded['grammarPlan'], isNull);
      await preferences.reload();
      expect(_snapshot(preferences), before);
      expect(
        preferences.containsKey(Storage.srsQuarantinePreferenceKey),
        isFalse,
      );
      expect(
        preferences.containsKey(Storage.packProgressQuarantinePreferenceKey),
        isFalse,
      );
    },
  );
}

Map<String, Object?> _snapshot(SharedPreferences preferences) => {
  for (final key in preferences.getKeys()) key: preferences.get(key),
};

Iterable<String> _allKeys(Object? value) sync* {
  if (value is Map) {
    for (final entry in value.entries) {
      yield entry.key.toString();
      yield* _allKeys(entry.value);
    }
  } else if (value is Iterable) {
    for (final item in value) {
      yield* _allKeys(item);
    }
  }
}
