import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_session_srs_ledger.dart';
import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  late PackRecallSession session;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    session = PackRecallSession.forPack(packId: 'pack');
  });
  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final logFailure in [false, true]) {
    for (final committed in [false, true]) {
      test(
        'pending evidence recovers before a later negative log=$logFailure native=$committed',
        () async {
          final attempt = session.evidenceAttempt(
            expectedPackId: 'pack',
            wordId: '학교',
            gotIt: true,
          );
          final key = logFailure
              ? 'kl_study_log_v1_${Storage.todayIso()}'
              : 'kl_srs_v1';
          platform
            ..rejectKey = key
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;
          await expectLater(attempt.save(), throwsA(isA<StateError>()));
          expect(session.ledger.stateFor('학교'), PackSessionSrsState.unrated);
          final writes = platform.writes[key];
          await expectLater(attempt.save(), throwsA(isA<StateError>()));
          expect(platform.writes[key], writes);
          platform
            ..unavailable = false
            ..rejectKey = null;
          final negative = session.evidenceAttempt(
            expectedPackId: 'pack',
            wordId: '학교',
            gotIt: false,
          );
          await Future.wait([negative.save(), negative.save(), attempt.save()]);
          expect(session.ledger.stateFor('학교'), PackSessionSrsState.negative);
          expect(Storage.srsCard('학교')?.reviewCount, 2);
          await session
              .evidenceAttempt(
                expectedPackId: 'pack',
                wordId: '학교',
                gotIt: true,
              )
              .save();
          expect(Storage.srsCard('학교')?.reviewCount, 2);
          expect(Storage.studyLogIdsFor(Storage.todayIso()), ['학교']);
        },
      );
    }
  }

  test('practice-only or mismatched sessions never write evidence', () async {
    await session
        .evidenceAttempt(expectedPackId: 'other', wordId: '학교', gotIt: true)
        .save();
    await PackRecallSession.practiceOnly()
        .evidenceAttempt(expectedPackId: 'pack', wordId: '학교', gotIt: false)
        .save();
    expect(Storage.srsCard('학교'), isNull);
    expect(platform.writes['kl_srs_v1'] ?? 0, 0);
  });

  test('reset invalidates pending and reused session evidence', () async {
    final attempt = session.evidenceAttempt(
      expectedPackId: 'pack',
      wordId: '학교',
      gotIt: true,
    );
    platform.rejectKey = 'kl_srs_v1';
    await expectLater(attempt.save(), throwsA(isA<StateError>()));
    platform.rejectKey = null;
    await Storage.resetAllStrict();
    await expectLater(
      attempt.save(),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    await expectLater(
      session
          .evidenceAttempt(expectedPackId: 'pack', wordId: '학교', gotIt: false)
          .save(),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(Storage.srsCard('학교'), isNull);
  });
}
